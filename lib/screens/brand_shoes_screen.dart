import 'package:flutter/material.dart';
import '../data/shoe_data.dart';
import '../models/shoe_model.dart';

class BrandShoesScreen extends StatefulWidget {
  final Function(String name) onShoeSelected;

  const BrandShoesScreen({Key? key, required this.onShoeSelected}) : super(key: key);

  @override
  State<BrandShoesScreen> createState() => _BrandShoesScreenState();
}

class _BrandShoesScreenState extends State<BrandShoesScreen> {
  String _selectedCategory = 'all'; // 'all', 'sneaker', 'boot'

  @override
  Widget build(BuildContext context) {
    // 1. Lấy dữ liệu đã được group theo brand và lọc theo category
    final groupedData = ShoeData.getShoesGroupedByBrand(filterCategory: _selectedCategory);
    final brands = groupedData.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Danh mục Hãng & Mẫu giày', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: ListView.builder(
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final shoes = groupedData[brand] ?? [];

                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    iconColor: Colors.blue,
                    collapsedIconColor: Colors.grey,
                    title: Text(
                      brand,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    children: shoes.map((shoe) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            shoe.category == 'sneaker' ? Icons.directions_run : Icons.hiking,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: Text(shoe.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(shoe.category == 'sneaker' ? 'Sneakers' : 'Boots', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          // Bắn event trả về cho CustomerHomeScreen để lọc
                          widget.onShoeSelected(shoe.name);
                          Navigator.pop(context); 
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Lọc loại:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 12),
            _buildFilterChip('Tất cả', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Sneakers', 'sneaker'),
            const SizedBox(width: 8),
            _buildFilterChip('Boots', 'boot'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = value);
      },
    );
  }
}
