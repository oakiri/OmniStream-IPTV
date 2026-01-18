import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/pages/channel_grid_page.dart';
import 'package:omnistream_iptv/features/navigation/presentation/widgets/top_navigation_bar.dart';
import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_background.dart';

class HomePage extends StatefulWidget {
  final String playlistUrl;

  const HomePage({Key? key, required this.playlistUrl}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _items = ['En Directo', 'Películas', 'Series', 'Catch Up'];
  late ChannelBloc _channelBloc;

  @override
  void initState() {
    super.initState();
    _channelBloc = sl<ChannelBloc>()
      ..add(LoadChannels(
          url: widget.playlistUrl, playlistId: widget.playlistUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CinematicBackground(
        child: SafeArea(
          child: Column(
            children: [
              TopNavigationBar(
                items: _items,
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                onSearchChanged: (value) {
                  _channelBloc.add(SearchChannels(value));
                },
              ),
              Expanded(
                child: BlocProvider.value(
                  value: _channelBloc,
                  child: ChannelGridPage(
                    playlistUrl: widget.playlistUrl,
                    showAppBar: false,
                    showBackground: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channelBloc.close();
    super.dispose();
  }
}
