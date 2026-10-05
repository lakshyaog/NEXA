import 'package:flutter/material.dart';

/// Colour for each lead status, used by chips and filters.
Color leadStatusColor(String status) => switch (status) {
      'New' => Colors.blueGrey,
      'Contacted' => Colors.indigo,
      'Interested' => Colors.orange,
      'Converted' => Colors.green,
      'Rejected' => Colors.redAccent,
      _ => Colors.grey,
    };
