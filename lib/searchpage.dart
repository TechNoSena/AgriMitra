import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A simple class to hold our searchable items. Now stores a destination index.
class SearchableItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final int destinationIndex; // Instead of a widget, we use the tab index

  SearchableItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.destinationIndex,
  });
}

class SearchPage extends StatefulWidget {
  // It now requires a function to be passed to it
  final Function(int) onNavigate;

  const SearchPage({super.key, required this.onNavigate});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // MODIFIED: The list now points to tab indexes (0=Home, 1=Rover, etc.)
  final List<SearchableItem> _allItems = [
    SearchableItem(
      title: 'Home',
      subtitle: 'View weather and your main stats',
      icon: Icons.home_outlined,
      destinationIndex: 0,
    ),
    SearchableItem(
      title: 'Rover',
      subtitle: 'Manage farm areas and check battery',
      icon: Icons.agriculture_outlined,
      destinationIndex: 1,
    ),
    SearchableItem(
      title: 'Market Prices',
      subtitle: 'See live crop market data',
      icon: Icons.storefront_outlined,
      destinationIndex: 2,
    ),
    // You can add Control Panel later if it becomes a main tab
  ];

  List<SearchableItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where(
              (item) =>
                  item.title.toLowerCase().contains(query.toLowerCase()) ||
                  item.subtitle.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search features...",
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return ListTile(
            leading: Icon(item.icon, color: Colors.grey.shade600),
            title: Text(
              item.title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(item.subtitle, style: GoogleFonts.poppins()),
            onTap: () {
              // 1. Tell the MainScreen to switch to the correct tab
              widget.onNavigate(item.destinationIndex);
              // 2. Close the search page
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
