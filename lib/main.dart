import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const EarCoachApp());
}

class EarCoachApp extends StatelessWidget {
  const EarCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ear Coach',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class CommandCategory {
  final String name;
  final List<String> commands;
  const CommandCategory(this.name, this.commands);
}

const defaultCategories = <CommandCategory>[
  CommandCategory('Ball Control', [
    'Dribble',
    'Turn',
    'Keep up juggling',
    'Trap and move',
    'Feint right, go left',
    'Step over',
  ]),
  CommandCategory('Passing', [
    'Short pass',
    'One two',
    'Wall pass',
    'Switch play',
    'Through ball',
  ]),
  CommandCategory('Shooting', [
    'Shoot',
    'Low shot',
    'Chip',
    'Volley',
    'Far post',
  ]),
  CommandCategory('Defensive', [
    'Man on',
    'Jockey',
    'Intercept',
    'Press',
    'Recover',
  ]),
  CommandCategory('Physical', [
    'Sprint',
    'Change direction',
    'Backpedal',
    'Jump',
    'Slide shuffle',
  ]),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Settings
  double minutes = 10;
  double minGap = 3; // seconds
  double maxGap = 6; // seconds
  bool vibration = true;
  bool comboMode = false;
  final FlutterTts tts = FlutterTts();
  final random = Random();
  final Set<String> selected = defaultCategories.map((c) => c.name).toSet();
  List<String> customCommands = [];
  bool speaking = false;

  // Session
  Timer? _timer;
  DateTime? _endTime;
  Duration elapsed = Duration.zero;
  int commandCount = 0;
  String lastCommand = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _initTts();
  }

  Future<void> _initTts() async {
    await tts.setSpeechRate(0.9);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    // Prefer offline voices if available
    try {
      final voices = await tts.getVoices;
      // Try to pick an English or Hindi offline voice if present
      final preferred = (voices as List)
          .cast<Map>()
          .firstWhere(
              (v) =>
                  (v['locale']?.toString().startsWith('en') == true ||
                      v['locale']?.toString().startsWith('hi') == true ||
                      v['locale']?.toString().startsWith('ur') == true) &&
                  (v['isNetworkConnectionRequired'] == false ||
                      v['isNetworkConnectionRequired'] == null),
              orElse: () => {});
      if (preferred.isNotEmpty) {
        await tts.setVoice({
          'name': preferred['name'],
          'locale': preferred['locale'],
        });
      }
    } catch (_) {
      // Safe fallback
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      minutes = prefs.getDouble('minutes') ?? 10;
      minGap = prefs.getDouble('minGap') ?? 3;
      maxGap = prefs.getDouble('maxGap') ?? 6;
      vibration = prefs.getBool('vibration') ?? true;
      comboMode = prefs.getBool('comboMode') ?? false;
      final savedSel = prefs.getStringList('selected');
      if (savedSel != null) {
        selected
          ..clear()
          ..addAll(savedSel);
      }
      customCommands = prefs.getStringList('customCommands') ?? [];
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('minutes', minutes);
    await prefs.setDouble('minGap', minGap);
    await prefs.setDouble('maxGap', maxGap);
    await prefs.setBool('vibration', vibration);
    await prefs.setBool('comboMode', comboMode);
    await prefs.setStringList('selected', selected.toList());
    await prefs.setStringList('customCommands', customCommands);
  }

  List<String> _activeCommands() {
    final cmds = <String>[];
    for (final cat in defaultCategories) {
      if (selected.contains(cat.name)) cmds.addAll(cat.commands);
    }
    cmds.addAll(customCommands);
    return cmds;
  }

  String _nextCommand() {
    final cmds = _activeCommands();
    if (cmds.isEmpty) return 'Run';
    if (comboMode && cmds.length >= 2 && random.nextDouble() < 0.25) {
      final a = cmds[random.nextInt(cmds.length)];
      var b = cmds[random.nextInt(cmds.length)];
      int guard = 0;
      while (b == a && guard++ < 5) {
        b = cmds[random.nextInt(cmds.length)];
      }
      return '$a then $b';
    }
    return cmds[random.nextInt(cmds.length)];
  }

  Future<void> _speak(String text) async {
    setState(() => speaking = true);
    await tts.stop();
    await tts.speak(text);
    setState(() => speaking = false);
  }

  void _startSession() async {
    await _savePrefs();
    _endTime = DateTime.now().add(Duration(minutes: minutes.round()));
    elapsed = Duration.zero;
    commandCount = 0;
    lastCommand = '';
    _timer?.cancel();

    void scheduleNext() {
      if (_endTime == null) return;
      final now = DateTime.now();
      if (now.isAfter(_endTime!)) {
        setState(() {});
        _timer?.cancel();
        _speak('Session complete. Great work!');
        return;
      }
      final gap =
          minGap + random.nextDouble() * (max(0.1, maxGap) - max(0.1, minGap));
      _timer = Timer(Duration(milliseconds: (gap * 1000).toInt()), () async {
        if (vibration) {
          try {
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 60);
            }
          } catch (_) {}
        }
        final cmd = _nextCommand();
        setState(() {
          lastCommand = cmd;
          commandCount += 1;
          elapsed = now.difference(_endTime!.subtract(Duration(minutes: minutes.round()))).abs();
        });
        await _speak(cmd);
        scheduleNext();
      });
    }

    scheduleNext();
    setState(() {});
  }

  void _stopSession() {
    _timer?.cancel();
    _endTime = null;
    setState(() {});
    _speak('Stopped');
  }

  @override
  void dispose() {
    _timer?.cancel();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _endTime != null && DateTime.now().isBefore(_endTime!);
    final active = _activeCommands();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Ear Coach (Offline)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Duration (min)'),
                      Expanded(
                        child: Slider(
                          value: minutes,
                          min: 3, max: 60, divisions: 57,
                          label: minutes.round().toString(),
                          onChanged: running ? null : (v) => setState(() => minutes = v),
                        ),
                      ),
                      Text('${minutes.round()}'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Min gap (s)'),
                      Expanded(
                        child: Slider(
                          value: minGap,
                          min: 0.5, max: 15, divisions: 58,
                          label: minGap.toStringAsFixed(1),
                          onChanged: running ? null : (v) => setState(() => minGap = v),
                        ),
                      ),
                      Text(minGap.toStringAsFixed(1)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Max gap (s)'),
                      Expanded(
                        child: Slider(
                          value: maxGap,
                          min: 1, max: 20, divisions: 76,
                          label: maxGap.toStringAsFixed(1),
                          onChanged: running ? null : (v) => setState(() => maxGap = v),
                        ),
                      ),
                      Text(maxGap.toStringAsFixed(1)),
                    ],
                  ),
                  SwitchListTile(
                    value: vibration,
                    onChanged: running ? null : (v) => setState(() => vibration = v),
                    title: const Text('Vibration cue'),
                  ),
                  SwitchListTile(
                    value: comboMode,
                    onChanged: running ? null : (v) => setState(() => comboMode = v),
                    title: const Text('Combo commands (25% chance)'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: running ? null : _startSession,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: running ? _stopSession : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (running) ...[
                    const Divider(),
                    Text('Last command: ${lastCommand.isEmpty ? "—" : lastCommand}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Commands given: $commandCount'),
                    const SizedBox(height: 4),
                    Text('Time left: ${_endTime!.difference(DateTime.now()).inSeconds}s'),
                    const SizedBox(height: 4),
                    if (speaking) const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...defaultCategories.map((c) => CheckboxListTile(
                        value: selected.contains(c.name),
                        onChanged: (_endTime != null) ? null : (v) {
                          setState(() {
                            if (v == true) {
                              selected.add(c.name);
                            } else {
                              selected.remove(c.name);
                            }
                          });
                        },
                        title: Text(c.name),
                        subtitle: Text('${c.commands.length} commands'),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom Commands', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final cmd in customCommands)
                        Chip(
                          label: Text(cmd),
                          onDeleted: _endTime != null ? null : () {
                            setState(() => customCommands.remove(cmd));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AddCommandField(
                    onAdd: (value) {
                      setState(() => customCommands.add(value));
                    },
                    enabled: _endTime == null,
                  ),
                  const SizedBox(height: 8),
                  Text('Active commands: ${_activeCommands().length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Tip: For offline voice, ensure your Android has an offline T T S voice installed (Settings → System → Languages & input → Text to speech).',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCommandField extends StatefulWidget {
  final void Function(String) onAdd;
  final bool enabled;
  const _AddCommandField({required this.onAdd, required this.enabled});

  @override
  State<_AddCommandField> createState() => _AddCommandFieldState();
}

class _AddCommandFieldState extends State<_AddCommandField> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            enabled: widget.enabled,
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Add command (e.g., "Cross to near post")',
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: widget.enabled
              ? () {
                  final v = controller.text.trim();
                  if (v.isNotEmpty) {
                    widget.onAdd(v);
                    controller.clear();
                  }
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
