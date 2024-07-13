import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const TimerApp());
  });
}

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cooldown Timer',
      theme: ThemeData.dark(),
      home: const TimerHomePage(),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  _TimerHomePageState createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> {
  List<TimerObject> _timers = [];

  @override
  void initState() {
    super.initState();
    _loadTimers();
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _checkTimers();
    });
  }

  Future<void> _loadTimers() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/timers.json');
    if (await file.exists()) {
      final String timersString = await file.readAsString();
      final List<dynamic> timersJson = jsonDecode(timersString);
      setState(() {
        _timers = timersJson.map((json) {
          TimerObject timer = TimerObject.fromJson(json);
          timer.fixEndTimeOrder();
          return timer;
        }).toList();
      });
    }
  }

  Future<void> _saveTimers() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/timers.json');
    final String timersString =
        jsonEncode(_timers.map((timer) => timer.toJson()).toList());
    await file.writeAsString(timersString);
  }

  void _addTimer(TimerObject timer) {
    setState(() {
      _timers.add(timer);
    });
    _saveTimers();
  }

  void _editTimer(int index, TimerObject updatedTimer) {
    setState(() {
      _timers[index] = updatedTimer;
    });
    _saveTimers();
  }

  void _deleteTimer(int index) {
    setState(() {
      _timers.removeAt(index);
    });
    _saveTimers();
  }

  void _checkTimers() {
    setState(() {
      for (var timer in _timers) {
        timer.fixEndTimeOrder();
      }
    });
  }

  void _startTimer(TimerObject timer) {
    setState(() {
      timer.setTimer();
    });
    _saveTimers();
  }

  void _showEditMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                final TimerObject? updatedTimer = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateTimerPage(timer: _timers[index]),
                  ),
                );
                if (updatedTimer != null) {
                  _editTimer(index, updatedTimer);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteTimer(index);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooldowns'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: _timers.length,
        itemBuilder: (context, index) {
          return TimerDisplay(
            timer: _timers[index],
            onTimerTap: () => _startTimer(_timers[index]),
            onTimerLongPress: () => _showEditMenu(index),
          );
        },
        padding: const EdgeInsets.all(10),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final TimerObject? newTimer = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTimerPage()),
          );
          if (newTimer != null) {
            _addTimer(newTimer);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum RechargeType {
  parallel,
  series,
}

class TimerObject {
  final String name;
  List<DateTime?> endTime;
  final int charges;
  int remainingCharges;
  final String iconPath;
  final Duration duration;
  final RechargeType rechargeType;

  TimerObject({
    required this.name,
    required this.endTime,
    required this.charges,
    required this.iconPath,
    required this.duration,
    required this.rechargeType,
    required this.remainingCharges,
  });

  bool get isAvailable => endTime.any((endTime) => endTime == null);

  void setTimer() {
    for (int i = 0; i < endTime.length; i++) {
      if (endTime[i] == null) {
        endTime[i] = DateTime.now().add(duration);
        if (rechargeType == RechargeType.series && i > 0) {
          endTime[i] =
              endTime[i]!.add(endTime[i - 1]!.difference(DateTime.now()));
        }
        remainingCharges--;
        break;
      }
    }
  }

  void clear() {
    for (int i = 0; i < endTime.length; i++) {
      endTime[i] = null;
    }
    remainingCharges = charges;
  }

  void fixEndTimeOrder() {
    if (endTime.length == 1 && endTime[0] != null) {
      if (DateTime.now().isAfter(endTime[0]!)) {
        endTime[0] = null;
      }
    }
    for (int i = 0; i < endTime.length - 1; i++) {
      if (endTime[i] != null && DateTime.now().isAfter(endTime[i]!)) {
        endTime[i] = endTime[i + 1];
        endTime[i + 1] = null;
      }
    }

    endTime.sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    });

    remainingCharges = endTime.length - endTime.nonNulls.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'endTime': endTime.map((e) => e?.toIso8601String()).toList(),
      'charges': charges,
      'remainingCharges': remainingCharges,
      'iconPath': iconPath,
      'duration': duration.inMilliseconds,
      'rechargeType': rechargeType.index,
    };
  }

  factory TimerObject.fromJson(Map<String, dynamic> json) {
    return TimerObject(
      name: json['name'],
      endTime: (json['endTime'] as List)
          .map((e) => e == null ? null : DateTime.parse(e))
          .toList(),
      charges: json['charges'],
      remainingCharges: json['remainingCharges'],
      iconPath: json['iconPath'],
      duration: Duration(milliseconds: json['duration']),
      rechargeType: RechargeType.values[json['rechargeType']],
    );
  }
}

class TimerDisplay extends StatelessWidget {
  final TimerObject timer;
  final VoidCallback onTimerTap;
  final VoidCallback onTimerLongPress;

  const TimerDisplay(
      {super.key, required this.timer,
      required this.onTimerTap,
      required this.onTimerLongPress});

  @override
  Widget build(BuildContext context) {
    final timeLeft = timer.endTime.first != null
        ? timer.endTime.first!.difference(DateTime.now())
        : Duration.zero;
    final formattedTimeLeft = formatDuration(timeLeft);

    double elapsedPercentage = timer.isAvailable
        ? 0
        : (timer.endTime.first!.difference(DateTime.now())).inMilliseconds /
            timer.duration.inMilliseconds;

    return Container(
      child: InkWell(
        onTap: timer.isAvailable ? onTimerTap : null,
        onLongPress: onTimerLongPress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32.0),
              child: Stack(
                children: [
                  Image.asset(
                    timer.iconPath,
                    width: 140,
                    height: 140,
                  ),
                  if (!timer.isAvailable)
                    Positioned(
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 140,
                        height: 140 * elapsedPercentage,
                        color: Colors.white70.withOpacity(0.15),
                      ),
                    ),
                  if (timer.charges > 1 && timer.remainingCharges > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white70,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF3e3e3e),
                          child: Text(
                            timer.remainingCharges.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(timer.name,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 5),
            Text(timer.isAvailable ? '' : formattedTimeLeft,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays} ${duration.inDays > 1 ? 'days' : 'day'}";
    } else if (duration.inHours > 0) {
      return "${duration.inHours} ${duration.inHours > 1 ? 'hours' : 'hour'}";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes} ${duration.inMinutes > 1 ? 'minutes' : 'minute'}";
    } else if (duration.inSeconds > 0) {
      return "${duration.inSeconds} ${duration.inSeconds > 1 ? 'seconds' : 'second'}";
    } else {
      return "less than a second";
    }
  }
}

class CreateTimerPage extends StatefulWidget {
  final TimerObject? timer;

  const CreateTimerPage({super.key, this.timer});

  @override
  _CreateTimerPageState createState() => _CreateTimerPageState();
}

class _CreateTimerPageState extends State<CreateTimerPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  String _iconPath = 'assets/icons/icon_1.png';
  int _numCharges = 1;
  RechargeType _chargeType = RechargeType.parallel;
  bool _isChargeSectionExpanded = false;

  final List<String> _customIconPaths = [
    'assets/icons/icon_1.png',
    'assets/icons/icon_2.png',
    'assets/icons/icon_3.png',
    'assets/icons/icon_4.png',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.timer != null) {
      _name = widget.timer!.name;
      _days = widget.timer!.duration.inDays;
      _hours = widget.timer!.duration.inHours % 24;
      _minutes = widget.timer!.duration.inMinutes % 60;
      _seconds = widget.timer!.duration.inSeconds % 60;
      _iconPath = widget.timer!.iconPath;
      _numCharges = widget.timer!.charges;
      _chargeType = widget.timer!.rechargeType;
    }
  }

  void _createTimer() {
    final duration = Duration(
        days: _days, hours: _hours, minutes: _minutes, seconds: _seconds);
    final endTimeNulls = List<DateTime?>.filled(_numCharges, null);
    final newTimer = TimerObject(
      name: _name,
      endTime: endTimeNulls,
      charges: _numCharges,
      iconPath: _iconPath,
      duration: duration,
      rechargeType: _chargeType,
      remainingCharges: _numCharges,
    );

    Navigator.pop(context, newTimer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.timer == null ? 'Create a new Cooldown' : 'Edit Cooldown'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                initialValue: _name,
                style: const TextStyle(fontSize: 28),
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Days',
                              style: TextStyle(color: Color(0xFFe3e3e3))),
                          const SizedBox(height: 5),
                          Text('$_days',
                              style: const TextStyle(color: Color(0xFFe3e3e3))),
                        ],
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 250,
                              child: CupertinoPicker(
                                itemExtent: 32,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _days = value;
                                  });
                                },
                                children:
                                    List<Widget>.generate(91, (int index) {
                                  return Text(index.toString());
                                }),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Hours',
                              style: TextStyle(color: Color(0xFFe3e3e3))),
                          const SizedBox(height: 5),
                          Text('$_hours',
                              style: const TextStyle(color: Color(0xFFe3e3e3))),
                        ],
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 250,
                              child: CupertinoPicker(
                                itemExtent: 32,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _hours = value;
                                  });
                                },
                                children:
                                    List<Widget>.generate(25, (int index) {
                                  return Text(index.toString());
                                }),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Minutes',
                              style: TextStyle(color: Color(0xFFe3e3e3))),
                          const SizedBox(height: 5),
                          Text('$_minutes',
                              style: const TextStyle(color: Color(0xFFe3e3e3))),
                        ],
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 250,
                              child: CupertinoPicker(
                                itemExtent: 32,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _minutes = value;
                                  });
                                },
                                children:
                                    List<Widget>.generate(61, (int index) {
                                  return Text(index.toString());
                                }),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Seconds',
                              style: TextStyle(color: Color(0xFFe3e3e3))),
                          const SizedBox(height: 5),
                          Text('$_seconds',
                              style: const TextStyle(color: Color(0xFFe3e3e3))),
                        ],
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 250,
                              child: CupertinoPicker(
                                itemExtent: 32,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _seconds = value;
                                  });
                                },
                                children:
                                    List<Widget>.generate(61, (int index) {
                                  return Text(index.toString());
                                }),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ExpansionTile(
                title: const Text('Advanced'),
                initiallyExpanded: _isChargeSectionExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isChargeSectionExpanded = expanded;
                  });
                },
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      const Text('Charges:',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 110,
                          height: 60,
                          color: const Color(0xFF3E3E3E),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (_numCharges > 1) {
                                      _numCharges--;
                                    }
                                  });
                                },
                              ),
                              Text('$_numCharges',
                                  style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _numCharges++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      const SizedBox(
                        width: double.infinity,
                        child: Text('Recharge Style:',
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 16)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: ListTile(
                              title: const Text('Parallel'),
                              leading: Radio<RechargeType>(
                                value: RechargeType.parallel,
                                groupValue: _chargeType,
                                onChanged: (RechargeType? value) {
                                  setState(() {
                                    _chargeType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Series'),
                              leading: Radio<RechargeType>(
                                value: RechargeType.series,
                                groupValue: _chargeType,
                                onChanged: (RechargeType? value) {
                                  setState(() {
                                    _chargeType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Select an Icon'),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _customIconPaths.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _iconPath = _customIconPaths[index];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _iconPath == _customIconPaths[index]
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Image.asset(_customIconPaths[index],
                            width: 40, height: 40),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _createTimer();
                  }
                },
                child: const Text('Create Cooldown'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
