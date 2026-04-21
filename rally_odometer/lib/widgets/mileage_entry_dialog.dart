import 'package:flutter/material.dart';

class MileageEntryDialog extends StatefulWidget {
  final String initialValue;
  final String title;
  final int decimalPlaces;
  final int maxDigitsBeforeDecimal;

  const MileageEntryDialog({
    super.key,
    required this.initialValue,
    required this.title,
    this.decimalPlaces = 3,
    this.maxDigitsBeforeDecimal = 8,
  });

  @override
  State<MileageEntryDialog> createState() => _MileageEntryDialogState();
}

class _MileageEntryDialogState extends State<MileageEntryDialog> {
  late String _currentValue;
  bool _hasStartedTyping = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _onKeyPress(String key) {
    setState(() {
      if (!_hasStartedTyping) {
        _currentValue = "";
        _hasStartedTyping = true;
      }

      if (key == "⌫") {
        if (_currentValue.isNotEmpty) {
          _currentValue = _currentValue.substring(0, _currentValue.length - 1);
        }
      } else if (key == ".") {
        if (!_currentValue.contains(".")) {
          if (_currentValue.isEmpty) {
            _currentValue = "0.";
          } else {
            _currentValue += ".";
          }
        }
      } else {
        if (_currentValue.contains(".")) {
          final parts = _currentValue.split(".");
          if (parts[1].length < widget.decimalPlaces) {
            _currentValue += key;
          }
        } else {
          if (_currentValue.length < widget.maxDigitsBeforeDecimal) {
            _currentValue += key;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = ((screenSize.width - 80).clamp(
      360.0,
      640.0,
    )).toDouble();
    final dialogHeight = ((screenSize.height - 40).clamp(
      320.0,
      560.0,
    )).toDouble();

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const contentPadding = 16.0;
            const sectionSpacing = 12.0;
            const keypadSpacing = 8.0;
            const actionSpacing = 12.0;
            final titleFontSize = (constraints.maxHeight * 0.045)
                .clamp(16.0, 20.0)
                .toDouble();
            final titleHeight = titleFontSize * 1.4;
            final displayHeight = (constraints.maxHeight * 0.16)
                .clamp(58.0, 84.0)
                .toDouble();
            final bodyHeight =
                (constraints.maxHeight -
                        (contentPadding * 2) -
                        titleHeight -
                        displayHeight -
                        (sectionSpacing * 2))
                    .clamp(180.0, 360.0)
                    .toDouble();
            final actionColumnWidth = (constraints.maxWidth * 0.24)
                .clamp(92.0, 124.0)
                .toDouble();
            final keypadWidth =
                constraints.maxWidth -
                (contentPadding * 2) -
                actionColumnWidth -
                actionSpacing;
            final tileWidth = (keypadWidth - (keypadSpacing * 2)) / 3;
            final tileHeight = (bodyHeight - (keypadSpacing * 3)) / 4;
            final keypadAspectRatio = tileWidth / tileHeight;
            final keypadFontSize = (tileHeight * 0.44)
                .clamp(22.0, 32.0)
                .toDouble();
            final actionButtonHeight = ((bodyHeight - actionSpacing) / 2)
                .clamp(72.0, 160.0)
                .toDouble();
            final actionFontSize = (actionButtonHeight * 0.18)
                .clamp(14.0, 20.0)
                .toDouble();
            final displayFontSize = (displayHeight * 0.55)
                .clamp(28.0, 40.0)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.all(contentPadding),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    height: titleHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: sectionSpacing),
                  Container(
                    height: displayHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currentValue.isEmpty ? "0" : _currentValue,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: const Color(0xFF00FF00),
                            fontSize: displayFontSize,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: sectionSpacing),
                  SizedBox(
                    height: bodyHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: keypadSpacing,
                            crossAxisSpacing: keypadSpacing,
                            childAspectRatio: keypadAspectRatio,
                            children: [
                              ...[
                                "1",
                                "2",
                                "3",
                                "4",
                                "5",
                                "6",
                                "7",
                                "8",
                                "9",
                                ".",
                                "0",
                                "⌫",
                              ].map((key) {
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[850],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => _onKeyPress(key),
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: keypadFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: actionSpacing),
                        SizedBox(
                          width: actionColumnWidth,
                          child: Column(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  height: actionButtonHeight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[900],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      final val = double.tryParse(
                                        _currentValue,
                                      );
                                      if (val != null) {
                                        Navigator.pop(context, val);
                                      }
                                    },
                                    child: Text(
                                      "SET",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: actionFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: actionSpacing),
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  height: actionButtonHeight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[900],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      "CANCEL",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: actionFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
