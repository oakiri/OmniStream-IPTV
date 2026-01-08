import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
import 'package:omnistream_iptv/features/navigation/presentation/widgets/top_navigation_bar.dart';
import 'package:omnistream_iptv/injection_container.dart';

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
      body: BlocProvider(
        create: (context) => sl<ChannelBloc>(),
        child: const ChannelGridPage(playlistUrl: '
(ModalRoute.of(context)!.settings.arguments as String? ?? 
'http://example.com/playlist.m3u'
)
      ),
    );
  }
}
