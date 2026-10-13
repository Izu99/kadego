import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Override with: flutter run --dart-define=API_URL=http://192.168.1.10:5000
const _envUrl = String.fromEnvironment('API_URL');
final String apiUrl = _envUrl.isNotEmpty
    ? _envUrl
    : (kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000'); // 10.0.2.2 = PC from Android emulator

class Item {
  final String id, name, shop, category, description, image, stockStatus;
  final List<String> brands;
  final num price;
  final int stock;

  Item.fromJson(Map<String, dynamic> j)
      : id = j['_id'],
        name = j['name'],
        shop = j['shop'] ?? 'Perera Stores',
        category = j['category'] ?? 'Other',
        description = j['description'] ?? '',
        image = j['image'] ?? 'other',
        stockStatus = j['stockStatus'] ?? 'in_stock',
        brands = List<String>.from(j['brands'] ?? const []),
        price = j['price'] ?? 0,
        stock = j['stock'] ?? 0;

  bool get soldOut => stockStatus == 'sold_out';
}

class CartLine {
  final String id, brand;
  final int quantity;
  final Item item;
  CartLine.fromJson(Map<String, dynamic> j)
      : id = j['_id'],
        brand = j['brand'] ?? '',
        quantity = j['quantity'],
        item = Item.fromJson(j['item']);
}

class Cart {
  final List<CartLine> lines;
  final num subtotal, total;
  Cart.fromJson(Map<String, dynamic> j)
      : lines = (j['items'] as List).map((e) => CartLine.fromJson(e)).toList(),
        subtotal = j['subtotal'],
        total = j['total'];
  int get count => lines.fold(0, (s, l) => s + l.quantity);
}

class User {
  final String id, name, phone, role, shop;
  User.fromJson(Map<String, dynamic> j)
      : id = j['_id'],
        name = j['name'],
        phone = j['phone'],
        role = j['role'],
        shop = j['shop'] ?? '';
  bool get isStore => role == 'store';
  String get initials => name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
}

class OrderLine {
  final String name, brand, image;
  final num price;
  final int quantity;
  OrderLine.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        brand = j['brand'] ?? '',
        image = j['image'] ?? 'other',
        price = j['price'] ?? 0,
        quantity = j['quantity'] ?? 1;
}

class Order {
  final String id, number, code, shop, customerName, pickupDay, pickupSlot, payment, status;
  final List<OrderLine> lines;
  final num total;
  final DateTime createdAt;
  final Map<String, DateTime> reachedAt; // status -> time it was reached

  Order.fromJson(Map<String, dynamic> j)
      : id = j['_id'],
        number = j['number'],
        code = j['code'],
        shop = j['shop'] ?? '',
        customerName = j['customerName'] ?? '',
        pickupDay = j['pickupDay'] ?? 'today',
        pickupSlot = j['pickupSlot'] ?? '',
        payment = j['payment'] ?? '',
        status = j['status'],
        lines = (j['lines'] as List).map((e) => OrderLine.fromJson(e)).toList(),
        total = j['total'] ?? 0,
        createdAt = DateTime.parse(j['createdAt']).toLocal(),
        reachedAt = {
          for (final h in (j['history'] as List? ?? const [])) h['status'] as String: DateTime.parse(h['at']).toLocal()
        };

  bool get active => !['collected', 'cancelled'].contains(status);
  int get itemCount => lines.fold(0, (s, l) => s + l.quantity);
}

class AppNotification {
  final String id, type, title, body, image;
  final String? orderId, itemId;
  final bool read;
  final DateTime createdAt;
  AppNotification.fromJson(Map<String, dynamic> j)
      : id = j['_id'],
        type = j['type'],
        title = j['title'],
        body = j['body'] ?? '',
        image = j['image'] ?? 'bags',
        orderId = j['order'],
        itemId = j['item'],
        read = j['read'] ?? false,
        createdAt = DateTime.parse(j['createdAt']).toLocal();
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static final cartCount = ValueNotifier<int>(0);

  /// Ticks every few seconds; open screens listen and quietly re-fetch (see LiveReload).
  static final tick = ValueNotifier<int>(0);
  static Timer? _ticker;
  static void startLiveUpdates({Duration every = const Duration(seconds: 4)}) {
    _ticker ??= Timer.periodic(every, (_) {
      tick.value++;
      if (_token != null) notifications().catchError((_) => <AppNotification>[]); // keeps the bell badge fresh
    });
  }

  /// Unread notifications for the bell badges.
  static final unread = ValueNotifier<int>(0);
  static String? _token;
  static User? user;

  // ---- Auth ----
  static Future<User> _saveSession(Map<String, dynamic> data) async {
    _token = data['token'];
    user = User.fromJson(data['user']);
    (await SharedPreferences.getInstance()).setString('token', _token!);
    return user!;
  }

  static Future<User> login(String phone, String password) async =>
      _saveSession(await _send('POST', '/auth/login', {'phone': phone, 'password': password}));

  static Future<User> register(String name, String phone, String password) async =>
      _saveSession(await _send('POST', '/auth/register', {'name': name, 'phone': phone, 'password': password}));

  /// Restores the last login on app start. Returns null if there is none or it expired.
  static Future<User?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) return null;
    try {
      return user = User.fromJson(await _send('GET', '/auth/me'));
    } catch (_) {
      await logout();
      return null;
    }
  }

  static Future<void> logout() async {
    _token = null;
    user = null;
    cartCount.value = 0;
    unread.value = 0;
    (await SharedPreferences.getInstance()).remove('token');
  }

  static Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    var uri = Uri.parse('$apiUrl/api$path');
    // Never let the browser/phone serve an old cached copy of a list
    if (method == 'GET') uri = uri.replace(queryParameters: {...uri.queryParameters, '_t': '${DateTime.now().millisecondsSinceEpoch}'});
    final headers = {'Content-Type': 'application/json', if (_token != null) 'Authorization': 'Bearer $_token'};
    final encoded = body == null ? null : jsonEncode(body);
    late http.Response r;
    try {
      r = switch (method) {
        'POST' => await http.post(uri, headers: headers, body: encoded),
        'PUT' => await http.put(uri, headers: headers, body: encoded),
        'DELETE' => await http.delete(uri, headers: headers),
        _ => await http.get(uri, headers: headers),
      };
    } catch (_) {
      throw ApiException('Can\'t reach the server. Is it running?');
    }
    dynamic data;
    try {
      data = r.body.isEmpty ? null : jsonDecode(r.body);
    } on FormatException {
      // Got a web page instead of JSON: the route doesn't exist on this server (old version?)
      throw ApiException('The server is out of date. Restart it and try again.');
    }
    if (r.statusCode >= 400) throw ApiException(data?['message'] ?? 'Something went wrong');
    return data;
  }

  // ---- Items (store side) ----
  static Future<List<Item>> items({String category = 'All'}) async {
    final q = category == 'All' ? '' : '?category=${Uri.encodeQueryComponent(category)}';
    return (await _send('GET', '/items$q') as List).map((e) => Item.fromJson(e)).toList();
  }

  static Future<Item> item(String id) async => Item.fromJson(await _send('GET', '/items/$id'));
  static Future<void> createItem(Map<String, dynamic> data) => _send('POST', '/items', data);
  static Future<void> updateItem(String id, Map<String, dynamic> data) => _send('PUT', '/items/$id', data);
  static Future<void> deleteItem(String id) => _send('DELETE', '/items/$id');

  // ---- Cart (customer side) ----
  static Future<Cart> cart() async {
    final c = Cart.fromJson(await _send('GET', '/cart'));
    cartCount.value = c.count;
    return c;
  }

  static Future<void> addToCart(String itemId, {String brand = '', int quantity = 1}) async {
    await _send('POST', '/cart', {'itemId': itemId, 'brand': brand, 'quantity': quantity});
    await cart();
  }

  static Future<void> setQuantity(String lineId, int quantity) => _send('PUT', '/cart/$lineId', {'quantity': quantity});
  static Future<void> removeFromCart(String lineId) => _send('DELETE', '/cart/$lineId');
  static Future<void> clearCart() async {
    await _send('DELETE', '/cart');
    cartCount.value = 0;
  }

  // ---- Orders ----
  static Future<Order> placeOrder({required String day, required String slot, required String payment}) async {
    final o = Order.fromJson(await _send('POST', '/orders', {'pickupDay': day, 'pickupSlot': slot, 'payment': payment}));
    cartCount.value = 0;
    return o;
  }

  static Future<List<Order>> orders() async =>
      (await _send('GET', '/orders') as List).map((e) => Order.fromJson(e)).toList();
  static Future<Order> order(String id) async => Order.fromJson(await _send('GET', '/orders/$id'));
  static Future<Order> setOrderStatus(String id, String status) async =>
      Order.fromJson(await _send('PUT', '/orders/$id/status', {'status': status}));

  // ---- Notifications ----
  static Future<List<AppNotification>> notifications() async {
    final d = await _send('GET', '/notifications');
    unread.value = d['unread'];
    return (d['items'] as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<void> markAllRead() async {
    await _send('PUT', '/notifications/read-all');
    unread.value = 0;
  }

  static Future<void> notifyMe(String itemId) => _send('POST', '/items/$itemId/notify-me');
}
