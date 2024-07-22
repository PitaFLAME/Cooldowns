import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
