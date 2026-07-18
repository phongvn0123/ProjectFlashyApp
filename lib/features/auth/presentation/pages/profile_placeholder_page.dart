import 'package:flutter/material.dart';

/// Placeholder for the "Cá nhân" (Profile) tab.
///
/// Replaced by Phase 2 (Auth/Profile/Admin) — see SKELETON.md Subsequent
/// Slice Plan.
///
/// This is also the Wave 1 canonical reference implementation of the
/// Phase 0 code-review finding: never call `setState()` after an `await`
/// without checking `mounted` first. Copy this pattern in Phases 2-6
/// whenever a widget's `initState` kicks off async work.
class ProfilePlaceholderPage extends StatefulWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  State<ProfilePlaceholderPage> createState() =>
      _ProfilePlaceholderPageState();
}

class _ProfilePlaceholderPageState extends State<ProfilePlaceholderPage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _simulateLoad();
  }

  Future<void> _simulateLoad() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Canonical pattern: never call setState() after an await without
    // checking mounted first. See DEVELOPER_GUIDE.md.
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: Center(
        child: Text(
          _ready ? 'Cá nhân — sắp ra mắt' : 'Đang tải...',
        ),
      ),
    );
  }
}
