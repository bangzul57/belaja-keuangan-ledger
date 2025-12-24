/// Model untuk item inventaris (barang dagangan)
class InventoryItem {
  final int? id;
  final String name;
  final String? sku;
  final String? category;
  final int stock;
  final int minStock;
  final String unit;
  final double buyPrice;
  final double sellPrice;
  final String? description;
  final String? supplierName;
  final DateTime? lastRestockDate;
  final double? lastRestockPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    this.id,
    required this.name,
    this.sku,
    this.category,
    this.stock = 0,
    this.minStock = 5,
    this.unit = 'pcs',
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.description,
    this.supplierName,
    this.lastRestockDate,
    this.lastRestockPrice,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Hitung profit per item
  double get profitPerItem => sellPrice - buyPrice;

  /// Hitung margin profit dalam persen
  double get profitMargin {
    if (buyPrice <= 0) return 0;
    return ((sellPrice - buyPrice) / buyPrice) * 100;
  }

  /// Hitung total nilai stok berdasarkan harga beli (modal)
  double get stockValueBuy => stock * buyPrice;

  /// Hitung total nilai stok berdasarkan harga jual
  double get stockValueSell => stock * sellPrice;

  /// Hitung potensi profit dari stok saat ini
  double get potentialProfit => stock * profitPerItem;

  /// Cek apakah stok rendah (di bawah minimum)
  bool get isLowStock => stock <= minStock;

  /// Cek apakah stok habis
  bool get isOutOfStock => stock <= 0;

  /// Cek apakah stok mencukupi untuk quantity tertentu
  bool hasSufficientStock(int quantity) => stock >= quantity;

  /// Copy with untuk immutability
  InventoryItem copyWith({
    int? id,
    String? name,
    String? sku,
    String? category,
    int? stock,
    int? minStock,
    String? unit,
    double? buyPrice,
    double? sellPrice,
    String? description,
    String? supplierName,
    DateTime? lastRestockDate,
    double? lastRestockPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      description: description ?? this.description,
      supplierName: supplierName ?? this.supplierName,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      lastRestockPrice: lastRestockPrice ?? this.lastRestockPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert ke Map untuk database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'stock': stock,
      'min_stock': minStock,
      'unit': unit,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'description': description,
      'supplier_name': supplierName,
      'last_restock_date': lastRestockDate?.toIso8601String(),
      'last_restock_price': lastRestockPrice,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert dari Map database
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      sku: map['sku'] as String?,
      category: map['category'] as String?,
      stock: (map['stock'] as int?) ?? 0,
      minStock: (map['min_stock'] as int?) ?? 5,
      unit: (map['unit'] as String?) ?? 'pcs',
      buyPrice: (map['buy_price'] as num?)?.toDouble() ?? 0,
      sellPrice: (map['sell_price'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      supplierName: map['supplier_name'] as String?,
      lastRestockDate: map['last_restock_date'] != null
          ? DateTime.parse(map['last_restock_date'] as String)
          : null,
      lastRestockPrice: (map['last_restock_price'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Factory untuk membuat item baru
  factory InventoryItem.create({
    required String name,
    String? sku,
    String? category,
    int stock = 0,
    int minStock = 5,
    String unit = 'pcs',
    required double buyPrice,
    required double sellPrice,
    String? description,
    String? supplierName,
  }) {
    final now = DateTime.now();
    return InventoryItem(
      name: name,
      sku: sku,
      category: category,
      stock: stock,
      minStock: minStock,
      unit: unit,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      description: description,
      supplierName: supplierName,
      lastRestockDate: stock > 0 ? now : null,
      lastRestockPrice: stock > 0 ? buyPrice : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, stock: $stock, buyPrice: $buyPrice, sellPrice: $sellPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum untuk kategori barang umum
enum ItemCategory {
  food('food', 'Makanan'),
  beverage('beverage', 'Minuman'),
  cigarette('cigarette', 'Rokok'),
  toiletries('toiletries', 'Perlengkapan Mandi'),
  stationery('stationery', 'Alat Tulis'),
  electronics('electronics', 'Elektronik'),
  pulsa('pulsa', 'Pulsa & Paket Data'),
  voucher('voucher', 'Voucher'),
  other('other', 'Lainnya');

  final String value;
  final String label;

  const ItemCategory(this.value, this.label);

  static ItemCategory fromValue(String value) {
    return ItemCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ItemCategory.other,
    );
  }
}
