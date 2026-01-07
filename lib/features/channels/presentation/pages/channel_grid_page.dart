import 'package:flutter/material.dart';
import 'package:omnistream_iptv/features/channels/domain/entities/channel.dart';

class ChannelGridPage extends StatelessWidget {
  final List<Channel> channels;

  const ChannelGridPage({Key? key, required this.channels}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return Card(
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  channel.logoUrl ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) => const Icon(Icons.tv, size: 48),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  channel.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
