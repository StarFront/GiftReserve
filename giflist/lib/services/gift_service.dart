import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:giflist/models/gift_model.dart';

class GiftService {
  // Simulación en memoria
  final List<Gift> _gifts = [];

  static const String _prefsKey = 'giflist_gifts_v1';

  GiftService() {
    // Kick off an async load (fire-and-forget). The list will populate when done.
    _loadFromPrefs();
  }

  // Singleton-like usage via new instance is fine for now
  List<Gift> getAll() => List.unmodifiable(_gifts);

  void add(Gift gift) {
    // generar id simple
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final newGift = Gift(
      id: id,
      name: gift.name,
      description: gift.description,
      imageUrl: gift.imageUrl,
      imageData: gift.imageData,
      productLink: gift.productLink,
      price: gift.price,
      quantity: gift.quantity,
      isReserved: gift.isReserved,
      reservedBy: gift.reservedBy,
      createdAt: gift.createdAt,
    );
    _gifts.insert(0, newGift);
    _saveToPrefs();
  }

  void update(String id, Gift updated) {
    final idx = _gifts.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _gifts[idx] = Gift(
        id: id,
        name: updated.name,
        description: updated.description,
        imageUrl: updated.imageUrl,
        imageData: updated.imageData,
        productLink: updated.productLink,
        price: updated.price,
        quantity: updated.quantity,
        isReserved: updated.isReserved,
        reservedBy: updated.reservedBy,
        createdAt: updated.createdAt,
      );
      _saveToPrefs();
    }
  }

  void delete(String id) {
    _gifts.removeWhere((g) => g.id == id);
    _saveToPrefs();
  }

  // Helper to seed some sample data
  void seed(List<Gift> sample) {
    _gifts.clear();
    _gifts.addAll(sample);
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _gifts.map((g) => g.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(jsonList));
    } catch (e) {
      // ignore save errors for now
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final parsed = jsonDecode(raw) as List<dynamic>;
        _gifts.clear();
        for (final item in parsed) {
          try {
            _gifts.add(Gift.fromJson(Map<String, dynamic>.from(item as Map)));
          } catch (_) {}
        }
      }
    } catch (e) {
      // ignore load errors
    }
  }
}

// Shared instance (simple singleton for in-memory demo)
final GiftService giftService = GiftService();
