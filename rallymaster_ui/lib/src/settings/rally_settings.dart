import 'package:flutter/material.dart';

/// RallyMaster settings section title and the divider that separates sections.
class RallySettingsSectionTitle extends StatelessWidget {
  const RallySettingsSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
  );
}

class RallySettingsSectionDivider extends StatelessWidget {
  const RallySettingsSectionDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 20, bottom: 10),
    child: Divider(),
  );
}

/// Standard RallyMaster settings-page body layout.
class RallySettingsBody extends StatelessWidget {
  const RallySettingsBody({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    ),
  );
}
