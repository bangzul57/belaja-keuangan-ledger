import 'package:flutter/foundation.dart';

import '../core/database/db_helper.dart';
import '../core/database/db_migration.dart';
import '../models/inventory_item.dart';

/// Provider untuk mengelola data Inventaris/Stok Barang
class InventoryProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper.instance;

  List<InventoryItem> _items = [];
  InventoryItem? _selectedItem;
  bool _isLoading = false;
  String? _errorMessage;
  int _lowStockThreshold = 5;

  // ===== GETTERS =====

  List<InventoryItem> get items => List.unmodifiable(_items);

  List<InventoryItem> get activeItems =>
      _items.where((i) => i.isActive).toList();

  InventoryItem? get selectedItem => _selectedItem;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get lowStockThreshold => _lowStockThreshold;

  /// Items dengan stok rendah
  List<InventoryItem> get lowStockItems =>
      activeItems.where((i) => i.stock <= _lowStockThreshold).toList();

  /// Items yang stoknya habis
  List<InventoryItem> get outOfStockItems =>
      activeItems.where((i) => i.stock <= 0).toList();

  /// Items yang masih ada stok
  List<InventoryItem> get inStockItems =>
      activeItems.where((i) => i.stock > 0).toList();

  /// Total nilai stok (berdasarkan harga beli/modal)
  double get totalStockValueBuy =>
      activeItems.fold(0.0, (sum, item) => sum + item.stockValueBuy);

  /// Total nilai stok (berdasarkan harga jual)
  double get totalStockValueSell =>
      activeItems.fold(0.0, (sum, item) => sum + item.stockValueSell);

  /// Total potensi profit dari stok
  double get totalPotentialProfit =>
      activeItems.fold(0.0, (sum, item) => sum + item.potentialProfit);

  /// Jumlah total item
  int get totalItemCount => activeItems.length;

  /// Jumlah total stok (semua item)
  int get totalStockCount =>
      activeItems.fold(0, (sum, item) => sum + item.stock);

  /// Daftar kategori unik
  List<String> get categories {
    final cats = activeItems
        .where((i) => i.category != null && i.category!.isNotEmpty)
        .map((i) => i.category!)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  // ===== CRUD OPERATIONS =====

  /// Load semua item dari database
  Future<void> loadItems() async {
    _setLoading(true);
    _clearError();

    try {
      final maps = await _dbHelper.queryAll(
        DBMigration.tableInventoryItems,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );

      _items = maps.map((map) => InventoryItem.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat data inventaris: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Tambah item baru
  Future<bool> addItem(InventoryItem item) async {
    _clearError();

    try {
      // Validasi nama tidak duplikat
      final existing = _items.where(
        (i) => i.name.toLowerCase() == item.name.toLowerCase() && i.isActive,
      );
      if (existing.isNotEmpty) {
        _setError('Barang dengan nama "${item.name}" sudah ada');
        return false;
      }

      // Validasi SKU tidak duplikat (jika ada)
      if (item.sku != null && item.sku!.isNotEmpty) {
        final existingSku = _items.where(
          (i) => i.sku?.toLowerCase() == item.sku?.toLowerCase() && i.isActive,
        );
        if (existingSku.isNotEmpty) {
          _setError('SKU "${item.sku}" sudah digunakan');
          return false;
        }
      }

      final id = await _dbHelper.insert(
        DBMigration.tableInventoryItems,
        item.toMap(),
      );

      final newItem = item.copyWith(id: id);
      _items.add(newItem);
      _sortItems();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Gagal menambah barang: $e');
      return false;
    }
  }

  /// Update item
  Future<bool> updateItem(InventoryItem item) async {
    _clearError();

    if (item.id == null) {
      _setError('ID barang tidak valid');
      return false;
    }

    try {
      final updatedItem = item.copyWith(updatedAt: DateTime.now());

      await _dbHelper.updateById(
        DBMigration.tableInventoryItems,
        item.id!,
        updatedItem.toMap(),
      );

      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
        _sortItems();
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Gagal mengupdate barang: $e');
      return false;
    }
  }

  /// Update stok item
  Future<bool> updateStock(int itemId, int newStock) async {
    _clearError();

    if (newStock < 0) {
      _setError('Stok tidak boleh negatif');
      return false;
    }

    try {
      final item = getItemById(itemId);
      if (item == null) {
        _setError('Barang tidak ditemukan');
        return false;
      }

      await _dbHelper.updateById(
        DBMigration.tableInventoryItems,
        itemId,
        {
          'stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = item.copyWith(
          stock: newStock,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Gagal mengupdate stok: $e');
      return false;
    }
  }

  /// Kurangi stok (untuk penjualan)
  Future<bool> decreaseStock(int itemId, int quantity) async {
    final item = getItemById(itemId);
    if (item == null) {
      _setError('Barang tidak ditemukan');
      return false;
    }

    if (item.stock < quantity) {
      _setError('Stok tidak mencukupi (tersedia: ${item.stock})');
      return false;
    }

    return updateStock(itemId, item.stock - quantity);
  }

  /// Tambah stok (untuk restock)
  Future<bool> increaseStock(
    int itemId,
    int quantity, {
    double? restockPrice,
  }) async {
    _clearError();

    final item = getItemById(itemId);
    if (item == null) {
      _setError('Barang tidak ditemukan');
      return false;
    }

    try {
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'stock': item.stock + quantity,
        'last_restock_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      if (restockPrice != null) {
        updates['last_restock_price'] = restockPrice;
        updates['buy_price'] = restockPrice; // Update harga beli
      }

      await _dbHelper.updateById(
        DBMigration.tableInventoryItems,
        itemId,
        updates,
      );

      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = item.copyWith(
          stock: item.stock + quantity,
          lastRestockDate: now,
          lastRestockPrice: restockPrice ?? item.lastRestockPrice,
          buyPrice: restockPrice ?? item.buyPrice,
          updatedAt: now,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Gagal menambah stok: $e');
      return false;
    }
  }

  /// Soft delete item
  Future<bool> deleteItem(int itemId) async {
    _clearError();

    try {
      await _dbHelper.softDelete(DBMigration.tableInventoryItems, itemId);

      _items.removeWhere((i) => i.id == itemId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Gagal menghapus barang: $e');
      return false;
    }
  }

  // ===== HELPER METHODS =====

  /// Cari item berdasarkan ID
  InventoryItem? getItemById(int id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Cari item berdasarkan nama
  InventoryItem? getItemByName(String name) {
    try {
      return _items.firstWhere(
        (i) => i.name.toLowerCase() == name.toLowerCase() && i.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  /// Cari item berdasarkan SKU
  InventoryItem? getItemBySku(String sku) {
    try {
      return _items.firstWhere(
        (i) => i.sku?.toLowerCase() == sku.toLowerCase() && i.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  /// Filter items berdasarkan kategori
  List<InventoryItem> getItemsByCategory(String category) {
    return activeItems
        .where((i) => i.category?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Search items
  List<InventoryItem> searchItems(String query) {
    if (query.isEmpty) return activeItems;

    final lowerQuery = query.toLowerCase();
    return activeItems.where((i) {
      return i.name.toLowerCase().contains(lowerQuery) ||
          (i.sku?.toLowerCase().contains(lowerQuery) ?? false) ||
          (i.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Set item yang dipilih
  void selectItem(InventoryItem? item) {
    _selectedItem = item;
    notifyListeners();
  }

  /// Set low stock threshold
  void setLowStockThreshold(int threshold) {
    _lowStockThreshold = threshold;
    notifyListeners();
  }

  /// Cek apakah stok mencukupi
  bool hasSufficientStock(int itemId, int quantity) {
    final item = getItemById(itemId);
    return item != null && item.stock >= quantity;
  }

  /// Refresh data dari database
  Future<void> refresh() async {
    await loadItems();
  }

  // ===== PRIVATE METHODS =====

  void _sortItems() {
    _items.sort((a, b) => a.name.compareTo(b.name));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
