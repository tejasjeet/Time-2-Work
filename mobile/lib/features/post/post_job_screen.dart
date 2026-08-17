import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'post_draft.dart';

final jobDraftProvider = StateProvider<JobDraft>((ref) => const JobDraft());

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _pay;
  late final TextEditingController _address;
  late final TextEditingController _workers;
  DateTime? _date;
  String? _category;
  String? _categoryId;
  String? _error;

  static const _fallbackCategories = ['Labour', 'Delivery', 'Cleaning', 'Electrical', 'Plumbing', 'Event', 'Other'];

  @override
  void initState() {
    super.initState();
    final d = ref.read(jobDraftProvider);
    _title = TextEditingController(text: d.title);
    _desc = TextEditingController(text: d.description);
    _pay = TextEditingController(text: d.pay > 0 ? d.pay.toStringAsFixed(0) : '');
    _address = TextEditingController(text: d.address);
    _workers = TextEditingController(text: '${d.workersRequired}');
    _date = d.date;
    _category = d.category.isEmpty ? null : d.category;
    _categoryId = d.categoryId.isEmpty ? null : d.categoryId;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _pay.dispose();
    _address.dispose();
    _workers.dispose();
    super.dispose();
  }

  void _preview() {
    if (_title.text.trim().length < 3) {
      setState(() => _error = 'Add a short job title');
      return;
    }
    if (_category == null || _category!.isEmpty) {
      setState(() => _error = 'Pick a category');
      return;
    }
    final pay = double.tryParse(_pay.text.trim()) ?? 0;
    if (pay <= 0) {
      setState(() => _error = 'Enter pay amount');
      return;
    }
    setState(() => _error = null);
    ref.read(jobDraftProvider.notifier).state = JobDraft(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      category: _category ?? '',
      categoryId: _categoryId ?? '',
      pay: pay,
      workersRequired: int.tryParse(_workers.text.trim()) ?? 1,
      date: _date,
      address: _address.text.trim(),
    );
    context.push('/post/preview');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final muted = AppColors.hint(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.work_outline_rounded, color: AppColors.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Post work',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            Text('Kaam post karein · nearby workers dekhenge', style: TextStyle(color: muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _InfoBanner(
                    icon: Icons.bolt_rounded,
                    text: 'Small posting fee before your job goes live. Workers within 5 KM get notified.',
                  ),
                  const SizedBox(height: 22),
                  _SectionCard(
                    title: 'What do you need?',
                    child: Column(
                      children: [
                        _ModernField(
                          controller: _title,
                          hint: 'Need 2 helpers for shop shifting',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _ModernField(
                          controller: _desc,
                          hint: 'Time, tools, what to bring…',
                          maxLines: 4,
                          minHeight: 110,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Category',
                    child: cats.when(
                      loading: () => const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                      ),
                      error: (_, __) => _CategoryChips(
                        categories: _fallbackCategories,
                        selected: _category,
                        onSelect: (name) => setState(() {
                          _category = name;
                          _categoryId = name;
                        }),
                      ),
                      data: (list) => _CategoryChips(
                        categories: list.isEmpty ? _fallbackCategories : list.map((c) => c.name).toList(),
                        selected: _category,
                        onSelect: (name) {
                          final match = list.where((c) => c.name == name).toList();
                          setState(() {
                            _category = name;
                            _categoryId = match.isEmpty ? name : (match.first.id.isNotEmpty ? match.first.id : name);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Budget & team',
                    child: Row(
                      children: [
                        Expanded(
                          child: _CompactField(
                            controller: _pay,
                            label: 'Pay',
                            suffix: '₹',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CompactField(
                            controller: _workers,
                            label: 'Workers',
                            suffix: 'people',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'When & where',
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.calendar_today_rounded,
                          title: _date == null ? 'Add work date' : 'Work date',
                          subtitle: _date == null ? 'Optional — tap to pick' : '${_date!.day}/${_date!.month}/${_date!.year}',
                          trailing: _date == null ? null : IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: muted),
                            onPressed: () => setState(() => _date = null),
                          ),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 10),
                        _ModernField(
                          controller: _address,
                          hint: 'Area / landmark (e.g. Near City Market)',
                          prefix: Icon(Icons.location_on_outlined, size: 20, color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: AppColors.canvas(context),
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.6))),
              ),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: 'Preview job',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _preview,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final double? minHeight;
  final Widget? prefix;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _ModernField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.minHeight,
    this.prefix,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        filled: true,
        fillColor: AppColors.inputFill(context),
        contentPadding: EdgeInsets.symmetric(horizontal: prefix == null ? 16 : 12, vertical: minHeight != null ? 14 : 16),
        constraints: minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _CompactField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.hint(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(suffix, style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((name) {
        final active = selected == name;
        return FilterChip(
          label: Text(name),
          selected: active,
          onSelected: (_) => onSelect(name),
          showCheckmark: false,
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.inputFill(context),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: active ? AppColors.white : Theme.of(context).colorScheme.onSurface,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.hint(context);
    return Material(
      color: AppColors.inputFill(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.hint(context), fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
