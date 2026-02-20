import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/holographic_display.dart';

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
        title: const Text("OMNIMIND TERMINAL"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (state.isLoading)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
             )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Holographic Display Area
            Expanded(
              flex: 2,
               child: Center(
                 child: HolographicDisplay(
                   videoUrl: state.currentAssetUrl ?? "https://assets.runwayml.com/example_output.webm", 
                   assetId: state.currentAssetId,
                   width: 350,
                   height: 350,
                 ),
               ),
            ),
            const SizedBox(height: 20),
            
            // Console / Text Area
            Expanded(
              flex: 1,
              child: Container(
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
                      // Options Chips
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
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Interaction Area
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[850],
                      hintText: "Enter manual override command...",
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
            ),
          ],
        ),
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
}
