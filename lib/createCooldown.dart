import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

import 'cooldownObject.dart';

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
