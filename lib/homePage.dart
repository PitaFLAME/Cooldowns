import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'cooldownObject.dart';
import 'createCooldown.dart';

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

// Main Display Stack
class TimerDisplay extends StatelessWidget {
  final TimerObject timer;
  final VoidCallback onTimerTap;
  final VoidCallback onTimerLongPress;

  const TimerDisplay(
      {super.key,
      required this.timer,
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
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
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
