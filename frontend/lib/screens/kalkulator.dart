import 'package:flutter/material.dart';
import '../../config.dart';

class KalkulatorScreen extends StatefulWidget {
  const KalkulatorScreen({super.key});

  @override
  State<KalkulatorScreen> createState() => _KalkulatorScreenState();
}

class _KalkulatorScreenState extends State<KalkulatorScreen> {
  String _display = '0';
  double _currentValue = 0;
  String _operator = '';
  bool _newNumber = true;
  List<String> _history = [];
  bool _showHistory = false;

  void _press(String val) {
    setState(() {
      switch (val) {
        case 'C':
          _display = '0';
          _currentValue = 0;
          _operator = '';
          _newNumber = true;
          break;
        case '⌫':
          if (_display.length > 1) {
            _display = _display.substring(0, _display.length - 1);
          } else {
            _display = '0';
          }
          break;
        case '+':
        case '-':
        case '×':
        case '÷':
          _currentValue = double.parse(_display);
          _operator = val;
          _newNumber = true;
          break;
        case '=':
          double second = double.parse(_display);
          double result = 0;
          switch (_operator) {
            case '+':
              result = _currentValue + second;
              break;
            case '-':
              result = _currentValue - second;
              break;
            case '×':
              result = _currentValue * second;
              break;
            case '÷':
              result = second != 0 ? _currentValue / second : 0;
              break;
            default:
              result = second;
          }
          String history = '$_currentValue $_operator $second = $result';
          _history.insert(0, history);
          if (_history.length > 20) _history.removeLast();
          _display = result.toString().replaceAll(RegExp(r'\.0$'), '');
          _operator = '';
          _newNumber = true;
          break;
        case '.':
          if (!_display.contains('.')) _display += '.';
          break;
        default:
          if (_newNumber) {
            _display = val;
            _newNumber = false;
          } else {
            _display += val;
          }
      }
    });
  }

  Widget _btn(String label, {Color? bg, Color? fg, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ElevatedButton(
          onPressed: label.isEmpty ? null : () => _press(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? Colors.white,
            foregroundColor: fg ?? AppConfig.textDark,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundWhite,
      appBar: AppBar(
        title: const Text('Kalkulator'),
        backgroundColor: AppConfig.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showHistory ? Icons.history : Icons.history_toggle_off,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () => setState(() => _history.clear()),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _operator.isNotEmpty ? '$_currentValue $_operator' : '',
                    style: const TextStyle(
                        fontSize: 14, color: AppConfig.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Riwayat
            if (_showHistory && _history.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _history.length,
                  itemBuilder: (_, i) => Text(
                    _history[i],
                    style: const TextStyle(
                        fontSize: 13, color: AppConfig.textLight),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Tombol
            Row(children: [
              _btn('C', bg: AppConfig.errorRed, fg: Colors.white),
              _btn('÷', bg: Colors.grey.shade100),
              _btn('×', bg: Colors.grey.shade100),
              _btn('⌫', bg: Colors.grey.shade100),
            ]),
            Row(children: [
              _btn('7'),
              _btn('8'),
              _btn('9'),
              _btn('-', bg: Colors.grey.shade100),
            ]),
            Row(children: [
              _btn('4'),
              _btn('5'),
              _btn('6'),
              _btn('+', bg: Colors.grey.shade100),
            ]),
            Row(children: [
              _btn('1'),
              _btn('2'),
              _btn('3'),
              _btn('=', bg: AppConfig.primaryGreen, fg: Colors.white),
            ]),
            // Baris terakhir: 0 (lebar 2), ., (tanpa =)
            Row(children: [
              _btn('0', flex: 2),
              _btn('00'),
              _btn('.'),
            ]),
          ],
        ),
      ),
    );
  }
}
