import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/market_item.dart';
import '../services/market_service.dart';
import 'create_market_item_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final MarketService _marketService = MarketService();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  List<MarketItem> _items = [];
  bool _isLoading = true;

  final Map<String, String> _categories = {
    'all': 'Barchasi',
    'books': 'Kitoblar',
    'tech': 'Texnika',
    'housing': 'Kvartira',
    'jobs': 'Ish',
    'lost': 'Yo\'qolgan',
    'other': 'Boshqa',
  };

  final Map<String, IconData> _categoryIcons = {
    'all': Icons.grid_view,
    'books': Icons.menu_book,
    'tech': Icons.devices,
    'housing': Icons.home,
    'jobs': Icons.work,
    'lost': Icons.search,
    'other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _marketService.getItems(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      search: _searchQuery,
    );
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Talaba Bozori", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryBlue),
            onPressed: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const CreateMarketItemScreen())
              );
              if (result == true) _loadItems();
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty 
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) => _buildItemCard(_items[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final key = _categories.keys.elementAt(index);
          final label = _categories.values.elementAt(index);
          final isSelected = _selectedCategory == key;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              avatar: Icon(_categoryIcons[key], size: 16, color: isSelected ? Colors.white : Colors.grey),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedCategory = key;
                });
                _loadItems();
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
                side: BorderSide(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300)
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: "E'lonlardan qidirish...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        onSubmitted: (value) {
          _searchQuery = value;
          _loadItems();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "E'lonlar topilmadi",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(MarketItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: item.imageUrl != null 
                    ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: item.imageUrl == null
                  ? Center(child: Icon(_categoryIcons[item.category] ?? Icons.shopping_bag, size: 40, color: Colors.grey[400]))
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price ?? "Kelishilgan",
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      "${item.viewsCount}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(item.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "Bugun";
    if (diff.inDays == 1) return "Kecha";
    return "${date.day}.${date.month}.${date.year}";
  }
}
