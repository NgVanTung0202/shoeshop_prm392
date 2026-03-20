import '../models/shoe_model.dart';

class ShoeData {
  static final List<Shoe> allShoes = [
    Shoe(id: '1', name: 'Air Force 1', brand: 'Nike', category: 'sneaker'),
    Shoe(id: '2', name: 'Air Max 270', brand: 'Nike', category: 'sneaker'),
    Shoe(id: '3', name: 'Dunk Low', brand: 'Nike', category: 'sneaker'),
    Shoe(id: '4', name: 'Pegasus', brand: 'Nike', category: 'sneaker'),
    Shoe(id: '5', name: 'Air Force 1 Boot', brand: 'Nike', category: 'boot'),
    Shoe(id: '6', name: 'Samba', brand: 'Adidas', category: 'sneaker'),
    Shoe(id: '7', name: 'Superstar', brand: 'Adidas', category: 'sneaker'),
    Shoe(id: '8', name: 'Stan Smith', brand: 'Adidas', category: 'sneaker'),
    Shoe(id: '9', name: 'Ultraboost', brand: 'Adidas', category: 'sneaker'),
    Shoe(id: '10', name: 'RS-X', brand: 'Puma', category: 'sneaker'),
    Shoe(id: '11', name: 'Suede', brand: 'Puma', category: 'sneaker'),
    Shoe(id: '12', name: 'Future Rider', brand: 'Puma', category: 'sneaker'),
    Shoe(id: '13', name: 'Chuck Taylor All Star', brand: 'Converse', category: 'sneaker'),
    Shoe(id: '14', name: 'Run Star Motion', brand: 'Converse', category: 'sneaker'),
    Shoe(id: '15', name: 'One Star', brand: 'Converse', category: 'sneaker'),
    Shoe(id: '16', name: 'Old Skool', brand: 'Vans', category: 'sneaker'),
    Shoe(id: '17', name: 'Authentic', brand: 'Vans', category: 'sneaker'),
    Shoe(id: '18', name: 'Slip-On', brand: 'Vans', category: 'sneaker'),
    Shoe(id: '19', name: '6 Inch Premium Boot', brand: 'Timberland', category: 'boot'),
    Shoe(id: '20', name: 'Waterproof Boot', brand: 'Timberland', category: 'boot'),
    Shoe(id: '21', name: '1460', brand: 'Dr Martens', category: 'boot'),
    Shoe(id: '22', name: 'Jadon', brand: 'Dr Martens', category: 'boot'),
    Shoe(id: '23', name: '2976 Chelsea Boot', brand: 'Dr Martens', category: 'boot'),
    Shoe(id: '24', name: 'Colorado', brand: 'CAT', category: 'boot'),
    Shoe(id: '25', name: 'Intruder', brand: 'CAT', category: 'sneaker'),
  ];

  /// Get a unique list of all brands
  static List<String> getAllBrands() {
    return allShoes.map((e) => e.brand).toSet().toList();
  }

  /// Get all shoes for a specific brand
  static List<Shoe> getShoesByBrand(String brand) {
    return allShoes.where((e) => e.brand == brand).toList();
  }

  /// Returns shoes grouped by brand. Optionally filter by category.
  static Map<String, List<Shoe>> getShoesGroupedByBrand({String? filterCategory}) {
    List<Shoe> filtered = allShoes;
    
    // Filter out shoes if a category is specified
    if (filterCategory != null && filterCategory.isNotEmpty && filterCategory != 'all') {
      filtered = filtered.where((e) => e.category == filterCategory).toList();
    }
    
    // Grouping logic
    Map<String, List<Shoe>> grouped = {};
    for (var shoe in filtered) {
      if (!grouped.containsKey(shoe.brand)) {
        grouped[shoe.brand] = [];
      }
      grouped[shoe.brand]!.add(shoe);
    }
    return grouped;
  }
}
