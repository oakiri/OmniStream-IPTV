import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_bloc.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_event.dart';
import 'package:omnistream_iptv/features/channels/presentation/bloc/channel_state.dart';
import 'package:omnistream_iptv/injection_container.dart';

class ChannelListPage extends StatelessWidget {
  final String url;

  const ChannelListPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
      ),
      body: BlocProvider(
        create: (_) => sl<ChannelBloc>()..add(LoadChannels(url)),
        child: BlocBuilder<ChannelBloc, ChannelState>(
          builder: (context, state) {
            if (state is ChannelLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ChannelLoaded) {
              return ListView.builder(
                itemCount: state.channels.length,
                itemBuilder: (context, index) {
                  final channel = state.channels[index];
                  return ListTile(
                    leading: channel.logoUrl != null
                        ? Image.network(channel.logoUrl!)
                        : const Icon(Icons.tv),
                    title: Text(channel.name),
                    onTap: () {
                      // ignore: avoid_print
                      print('Playing: ${channel.url}');
                    },
                  );
                },
              );
            } else if (state is ChannelError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: Text('No channels loaded.'));
          },
        ),
      ),
    );
  }
}
