/// VitalSync — Dashboard Layout Provider.
///
/// Manages dashboard card order with persistence via SharedPreferences.
/// Supports drag & drop reordering and layout reset.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dashboard_layout_provider.g.dart';

const _kDashboardOrderKey = 'dashboard_card_order';
const _defaultOrder = [0, 1, 2, 3, 4, 5, 6];

/// Notifier for dashboard layout card ordering.
@Riverpod(keepAlive: true)
class DashboardLayout extends _$DashboardLayout {
  @override
  List<int> build() {
    _loadOrder();
    return List.of(_defaultOrder);
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kDashboardOrderKey);
    if (saved != null && saved.length == _defaultOrder.length) {
      final order = saved.map(int.parse).toList();
      if (_isValidOrder(order)) {
        state = order;
      }
    }
  }

  bool _isValidOrder(List<int> order) {
    final sorted = order.toList()..sort();
    for (var i = 0; i < _defaultOrder.length; i++) {
      if (sorted[i] != i) return false;
    }
    return true;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final newOrder = state.toList();
    if (oldIndex < newIndex) newIndex -= 1;
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    state = newOrder;
    await _saveOrder();
  }

  Future<void> resetLayout() async {
    state = List.of(_defaultOrder);
    await _saveOrder();
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kDashboardOrderKey,
      state.map((e) => e.toString()).toList(),
    );
  }
}
