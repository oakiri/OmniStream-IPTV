'''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../bloc/epg_bloc.dart';
import '../bloc/epg_event.dart';
import '../bloc/epg_state.dart';

class EpgPage extends StatelessWidget {
  final String epgUrl;

  const EpgPage({Key? key, required this.epgUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPG'),
      ),
      body: BlocProvider(
        create: (_) => sl<EpgBloc>()..add(FetchEpgData(epgUrl)),
        child: BlocBuilder<EpgBloc, EpgState>(
          builder: (context, state) {
            if (state is EpgLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is EpgLoaded) {
              return ListView.builder(
                itemCount: state.programs.length,
                itemBuilder: (context, index) {
                  final program = state.programs[index];
                  return ListTile(
                    title: Text(program.title),
                    subtitle: Text(
                        '${program.start.toLocal()} - ${program.stop.toLocal()}\n${program.desc ?? ''}'),
                    isThreeLine: true,
                  );
                },
              );
            } else if (state is EpgError) {
              return Center(
                child: Text(state.message),
              );
            }
            return const Center(
              child: Text('Enter an EPG URL to begin.'),
            );
          },
        ),
      ),
    );
  }
}
'''
