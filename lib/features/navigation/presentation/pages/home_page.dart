import 'package:flutter/material.dart';
import 'package:omnistream_iptv/features/navigation/presentation/widgets/top_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _items = ['En Directo', 'Películas', 'Series', 'Catch Up'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TopNavigationBar(
          items: _items,
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      body: Center(
        child: Text('Página de ${_items[_selectedIndex]}'),
      ),
    );
  }
}
