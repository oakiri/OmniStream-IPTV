import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class PlayerPage extends StatefulWidget {
  final Channel channel;

  const PlayerPage({
    Key? key,
    required this.channel,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final player = Player();
  late final videoController = VideoController(player);
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await player.open(
        Media(widget.channel.url),
        play: true,
      );
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stream: $e')),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    videoController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.channel.name,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Video(controller: videoController),
            ),
          ),
          _buildPlayerControls(),
          _buildChannelInfo(),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: () {
              // Volume control can be implemented here
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              // Fullscreen can be implemented here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelInfo() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Channel Information',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Name: ${widget.channel.name}',
            style: GoogleFonts.roboto(fontSize: 12),
          ),
          if (widget.channel.group != null)
            Text(
              'Category: ${widget.channel.group}',
              style: GoogleFonts.roboto(fontSize: 12),
            ),
          Text(
            'URL: ${widget.channel.url}',
            style: GoogleFonts.roboto(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
