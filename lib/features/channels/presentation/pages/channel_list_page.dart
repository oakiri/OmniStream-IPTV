import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/injection_container.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

class ChannelListPage extends StatefulWidget {
  final String url;

  const ChannelListPage({Key? key, required this.url}) : super(key: key);

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (_) => sl<ChannelBloc>()..add(LoadChannels(widget.url)),
        child: BlocBuilder<ChannelBloc, ChannelState>(
          builder: (context, state) {
            if (state is ChannelLoading) {
              return _buildLoading();
            } else if (state is ChannelLoaded) {
              final groups = state.channels.map((c) => c.group).toSet().toList();
              final filteredChannels = _selectedGroup == null
                  ? state.channels
                  : state.channels.where((c) => c.group == _selectedGroup).toList();

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Channels'),
                    floating: true,
                    pinned: true,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(50.0),
                      child: SizedBox(
                        height: 50.0,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(group ?? 'Other'),
                                selected: _selectedGroup == group,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedGroup = selected ? group : null;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final channel = filteredChannels[index];
                        return ListTile(
                          leading: CachedNetworkImage(
                            imageUrl: channel.logoUrl ?? '',
                            width: 50,
                            height: 50,
                            memCacheHeight: 100,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(
                                color: Colors.black,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: Text(
                                  channel.name.isNotEmpty ? channel.name[0] : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          title: Text(channel.name),
                          onTap: () {
                            print('Playing: ${channel.url}');
                          },
                        );
                      },
                      childCount: filteredChannels.length,
                    ),
                  ),
                ],
              );
            } else if (state is ChannelError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              color: Colors.black,
            ),
            title: Container(
              height: 16,
              color: Colors.black,
            ),
          );
        },
      ),
    );
  }
}
