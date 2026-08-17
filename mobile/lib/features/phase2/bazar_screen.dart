import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../models/phase2.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

const _categories = [
  ('all', 'All'),
  ('tools', 'Tools'),
  ('furniture', 'Furniture'),
  ('electronics', 'Electronics'),
  ('vehicles', 'Vehicles'),
  ('other', 'Other'),
];

class BazarScreen extends ConsumerStatefulWidget {
  const BazarScreen({super.key});

  @override
  ConsumerState<BazarScreen> createState() => _BazarScreenState();
}

class _BazarScreenState extends ConsumerState<BazarScreen> {
  final _search = TextEditingController();
  String _category = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MarketplaceItem> _filter(List<MarketplaceItem> items) {
    final q = _search.text.trim().toLowerCase();
    return items.where((item) {
      final catOk = _category == 'all' || (item.category ?? 'other') == _category;
      if (!catOk) return false;
      if (q.isEmpty) return true;
      return item.title.toLowerCase().contains(q) ||
          (item.description ?? '').toLowerCase().contains(q) ||
          (item.address ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _sellItem() async {
    final user = ref.read(authProvider).user;
    final title = TextEditingController();
    final desc = TextEditingController();
    final price = TextEditingController();
    var category = 'other';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: StatefulBuilder(
            builder: (context, setSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sell in Local Bazar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('List items for neighbours to buy nearby.', style: TextStyle(color: AppColors.hint(context))),
                  const SizedBox(height: 16),
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Item title')),
                  const SizedBox(height: 10),
                  TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 10),
                  TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.where((c) => c.$1 != 'all').map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                    onChanged: (v) => setSheet(() => category = v ?? 'other'),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Publish listing',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true || title.text.trim().isEmpty) {
      title.dispose();
      desc.dispose();
      price.dispose();
      return;
    }

    try {
      await ref.read(phase2RepositoryProvider).createListing(
            title: title.text.trim(),
            description: desc.text.trim(),
            price: double.tryParse(price.text.trim()),
            category: category,
            lat: user?.lat,
            lng: user?.lng,
            address: user?.areaLabel?.split(',').first,
          );
      ref.invalidate(marketplaceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing published')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      title.dispose();
      desc.dispose();
      price.dispose();
    }
  }

  void _openItem(MarketplaceItem item) {
    final price = item.price == null
        ? 'Price on request'
        : NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(item.price);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(price, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 18)),
            if (item.address != null && item.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.hint(ctx)),
                const SizedBox(width: 4),
                Expanded(child: Text(item.address!, style: TextStyle(color: AppColors.hint(ctx)))),
              ]),
            ],
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.description!, style: const TextStyle(height: 1.4)),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Message seller',
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open Chat tab to talk with sellers safely in-app.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(marketplaceProvider);
    final muted = AppColors.hint(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Bazar'),
        actions: [
          IconButton(onPressed: () => ref.invalidate(marketplaceProvider), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sellItem,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell item'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buy & sell near you', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('Tools, furniture, electronics and more from your mohalla.', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search listings…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _category == cat.$1;
                return FilterChip(
                  label: Text(cat.$2),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat.$1),
                  selectedColor: AppColors.accent,
                  checkmarkColor: AppColors.white,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => ref.invalidate(marketplaceProvider),
              child: list.when(
                loading: () => const LoadingView(label: 'Loading listings…'),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(marketplaceProvider)),
                data: (items) {
                  final filtered = _filter(items);
                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyState(
                          icon: Icons.storefront_outlined,
                          title: items.isEmpty ? 'No listings yet' : 'No matches',
                          subtitle: items.isEmpty
                              ? 'Be the first to sell something in your area.'
                              : 'Try another search or category.',
                        ),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ListingCard(item: filtered[i], currency: currency, onTap: () => _openItem(filtered[i])),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item, required this.currency, required this.onTap});

  final MarketplaceItem item;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = item.images.isNotEmpty ? item.images.first : null;
    return Material(
      color: AppColors.panel(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: image != null
                  ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: AppColors.inputFill(context),
                      child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.accent)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.price == null ? 'Ask price' : currency.format(item.price),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                  ),
                  if (item.address != null && item.address!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.hint(context), fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
