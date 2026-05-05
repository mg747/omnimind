import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../widgets/holographic_display.dart';
import '../widgets/language_selector_dialog.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start simulation on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SimulationState>().startSimulation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SimulationState>();

    return Scaffold(
      appBar: AppBar(
        title: Text("simulation.title".tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.cyanAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return LanguageSelectorDialog();
                },
              );
            },
          ),
          if (state.isLoading)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
             )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return _buildWideLayout(state);
          } else {
            return _buildNarrowLayout(state);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        onPressed: () {
           context.read<SimulationState>().unlockDevice();
        },
        child: const Icon(Icons.lock_open),
      ),
    );
  }

  Widget _buildHolographicDisplay(SimulationState state) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: HolographicDisplay(
          videoUrl: state.currentAssetUrl ?? "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", 
          assetId: state.currentAssetId,
          isStream: state.isStream,
          subtitleUrl: state.subtitleUrl,
        ),
      ),
    );
  }

  Widget _buildConsoleArea(SimulationState state) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.currentMessage,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Colors.cyanAccent,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              children: state.options.map((option) {
                return ActionChip(
                  label: Text(option),
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  side: const BorderSide(color: Colors.cyanAccent),
                  labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                  onPressed: state.isLoading ? null : () {
                    context.read<SimulationState>().submitAction(option);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionArea(SimulationState state) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[850],
              hintText: "simulation.hint".tr(),
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
            onSubmitted: (value) {
               if (value.isNotEmpty) {
                 context.read<SimulationState>().submitAction(value);
                 _textController.clear();
               }
            },
            enabled: !state.isLoading,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.cyanAccent),
          onPressed: state.isLoading ? null : () {
             if (_textController.text.isNotEmpty) {
                context.read<SimulationState>().submitAction(_textController.text);
                _textController.clear();
             }
          },
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(SimulationState state) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _buildHolographicDisplay(state),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 1,
            child: _buildConsoleArea(state),
          ),
          const SizedBox(height: 10),
          _buildInteractionArea(state),
        ],
      ),
    );
  }

  Widget _buildWideLayout(SimulationState state) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: _buildHolographicDisplay(state),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildConsoleArea(state),
                ),
                const SizedBox(height: 10),
                _buildInteractionArea(state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
