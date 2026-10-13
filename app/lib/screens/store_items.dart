import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'login.dart';
import 'shop.dart' show categories;

/// Store side (home screen for shop-owner accounts): list / add / edit / delete items.
class StoreItemsScreen extends StatefulWidget {
  final bool isHome;
  const StoreItemsScreen({super.key, this.isHome = false});
  @override
  State<StoreItemsScreen> createState() => _StoreItemsScreenState();
}

class _StoreItemsScreenState extends State<StoreItemsScreen> with LiveReload {
  late Future<List<Item>> _items = Api.items();

  void _reload() => setState(() { _items = Api.items(); });

  @override
  Future<void> liveReload() async {
    final items = await Api.items();
    if (mounted) setState(() { _items = Future.value(items); });
  }

  Future<void> _logout() async {
    await Api.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  Future<void> _edit([Item? item]) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));
    if (saved == true) _reload();
  }

  Future<void> _delete(Item item) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Delete ${item.name}?', style: t(18, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Customers will no longer see this item.', style: t(13, c: C.muted)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: C.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: t(15, w: FontWeight.w600, c: Colors.white)),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: t(15, c: C.muted))),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteItem(item.id);
      if (mounted) toast(context, '${item.name} deleted');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar('Manage items',
          backIcon: widget.isHome ? Icons.logout_rounded : Icons.chevron_left_rounded,
          onBack: widget.isHome ? _logout : null),
      body: FutureBuilder<List<Item>>(
        future: _items,
        builder: (context, snap) {
          if (snap.hasError) return ErrorRetry(snap.error!, _reload);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: C.orangeSoft, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const ProductThumb('store', size: 48, bg: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Api.user?.shop.isNotEmpty == true ? Api.user!.shop : 'Perera Stores', style: t(16, w: FontWeight.w600)),
                      Text('${items.length} items  •  ${items.where((i) => i.soldOut).length} sold out',
                          style: t(12, c: C.muted)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No items yet. Tap + to add one.', textAlign: TextAlign.center, style: t(14, c: C.muted)),
                ),
              for (final i in items)
                InkWell(
                  onTap: () => _edit(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      ProductThumb(i.image, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.name, style: t(15, w: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('${rs(i.price)}  •  ${i.stock} in stock', style: t(12, c: C.muted)),
                          const SizedBox(height: 5),
                          StockBadge(i.stockStatus),
                        ]),
                      ),
                      IconButton(
                          onPressed: () => _edit(i), icon: const Icon(Icons.edit_outlined, color: C.ink, size: 20)),
                      IconButton(
                          onPressed: () => _delete(i),
                          icon: const Icon(Icons.delete_outline_rounded, color: C.red, size: 20)),
                    ]),
                  ),
                ),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: C.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add item', style: t(15, w: FontWeight.w600, c: Colors.white)),
      ),
    );
  }
}

/// Add / edit form.
class ItemFormScreen extends StatefulWidget {
  final Item? item;
  const ItemFormScreen({super.key, this.item});
  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _desc = TextEditingController(text: widget.item?.description);
  late final _brands = TextEditingController(text: widget.item?.brands.join(', '));
  late final _price = TextEditingController(text: widget.item?.price.toString());
  late final _stock = TextEditingController(text: widget.item?.stock.toString() ?? '10');
  late String _category = widget.item?.category ?? 'Rice & Grains';
  late String _image = widget.item?.image ?? 'rice';
  bool _busy = false;

  static const _images = ['rice', 'milk', 'bread', 'eggs', 'other'];

  @override
  void dispose() {
    for (final c in [_name, _desc, _brands, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; });
    final data = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'brands': _brands.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'price': num.parse(_price.text.trim()),
      'stock': int.parse(_stock.text.trim()),
      'category': _category,
      'image': _image,
    };
    try {
      if (widget.item == null) {
        await Api.createItem(data);
      } else {
        await Api.updateItem(widget.item!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() { _busy = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Scaffold(
      appBar: TopBar(editing ? 'Edit item' : 'Add item'),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
          _label('Picture'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final k in _images)
              GestureDetector(
                  onTap: () => setState(() { _image = k; }),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _image == k ? C.orangeSoft : C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _image == k ? C.orange : Colors.transparent, width: 1.6),
                    ),
                    alignment: Alignment.center,
                    child: img(k, 32),
                  ),
              ),
          ]),
          _label('Item name'),
          _field(_name, 'e.g. Samba rice 5 kg', validator: (v) => v!.trim().isEmpty ? 'Enter a name' : null),
          _label('Category'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in [...categories.skip(1), 'Other'])
              ChoiceChipX(c, selected: _category == c, onTap: () => setState(() { _category = c; })),
          ]),
          _label('Short description'),
          _field(_desc, 'e.g. Farm fresh'),
          _label('Brands (comma separated, optional)'),
          _field(_brands, 'e.g. Anchor, Highland'),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Price (Rs.)'),
                _field(_price, '0',
                    number: true, validator: (v) => num.tryParse(v!.trim()) == null ? 'Enter a price' : null),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Stock'),
                _field(_stock, '0',
                    number: true, validator: (v) => int.tryParse(v!.trim()) == null ? 'Whole number' : null),
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          Text('Stock 0 shows as "Sold out", 1–3 as "Low stock".', style: t(12, c: C.faint)),
        ]),
      ),
      bottomNavigationBar: BottomCta(child: PrimaryButton(editing ? 'Save changes' : 'Add item', loading: _busy, onTap: _save)),
    );
  }

  Widget _label(String s) =>
      Padding(padding: const EdgeInsets.only(top: 18, bottom: 8), child: Text(s, style: t(14, w: FontWeight.w500)));

  Widget _field(TextEditingController c, String hint, {bool number = false, String? Function(String?)? validator}) =>
      TextFormField(
        controller: c,
        validator: validator,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: t(15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: t(15, c: C.faint),
          filled: true,
          fillColor: C.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.orange, width: 1.5)),
        ),
      );
}
