import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/playlist/domain/usecases/toggle_favorite.dart';
import 'package:omnistream_iptv/injection_container.dart';

class ToggleFavoriteButton extends StatefulWidget {
  final Channel channel;

  const ToggleFavoriteButton({super.key, required this.channel});

  @override
  State<ToggleFavoriteButton> createState() => _ToggleFavoriteButtonState();
}

class _ToggleFavoriteButtonState extends State<ToggleFavoriteButton> {
  bool _isFavorite = false;
  final ToggleFavorite _toggleFavorite = sl<ToggleFavorite>();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    // TODO: Implement a use case to check if a channel is favorite
    // For now, we'll assume it's not favorite and update on toggle
    setState(() {
      _isFavorite = false;
    });
  }

  void _toggle() async {
    final result = await _toggleFavorite(widget.channel);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error toggling favorite: ${failure.message}')),
        );
      },
      (_) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isFavorite
                  ? 'Added to favorites'
                  : 'Removed from favorites')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white70,
      ),
      onPressed: _toggle,
    );
  }
}
