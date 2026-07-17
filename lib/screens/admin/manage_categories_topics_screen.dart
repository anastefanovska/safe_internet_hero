import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/topic_model.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';

class CategoryTopicManagerScreen extends StatefulWidget {
  const CategoryTopicManagerScreen({super.key});

  @override
  State<CategoryTopicManagerScreen> createState() =>
      _CategoryTopicManagerScreenState();
}

class _CategoryTopicManagerScreenState
    extends State<CategoryTopicManagerScreen> {
  final _topicsService = TopicsService();

  List<CategoryModel> _categories = [];

  // Converts a display name to a stable, human-readable document ID.
  // "Strong Passwords" -> "strong_passwords"
  static String _slugify(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  // Topics loaded lazily per category: categoryId â†’ list
  final Map<String, List<TopicModel>> _topicsCache = {};
  final Set<String> _loadingTopics = {};
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // â”€â”€ Data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final cats = await _topicsService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loadingCategories = false;
    });
  }

  Future<void> _loadTopics(String categoryId) async {
    if (_loadingTopics.contains(categoryId)) return;
    setState(() => _loadingTopics.add(categoryId));
    final topics = await _topicsService.getTopicsByCategory(categoryId);
    if (!mounted) return;
    setState(() {
      _topicsCache[categoryId] = topics;
      _loadingTopics.remove(categoryId);
    });
  }

  Future<void> _reloadTopics(String categoryId) async {
    _topicsCache.remove(categoryId);
    await _loadTopics(categoryId);
  }

  // â”€â”€ Sheets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showCategorySheet({CategoryModel? cat}) async {
    final l10n = AppLocalizations.of(context);
    final titleCtrl = TextEditingController(text: cat?.title ?? '');
    var order = cat?.order ?? (_categories.length + 1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AdminBottomSheet(
          title: cat == null ? l10n.ctAddCategory : l10n.ctEditCategory,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminLabel(l10n.ctCategoryName),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (_, ss) {
              final slug = _slugify(titleCtrl.text);
              titleCtrl.addListener(() => ss(() {}));
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AdminField(controller: titleCtrl, hint: l10n.ctEnterCategoryName),
                if (cat == null && slug.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(l10n.ctIdLabel(slug),
                      style: GoogleFonts.nunito(
                          color: AppColors.blue, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ]);
            }),
            const SizedBox(height: 14),
            AdminLabel(l10n.ctDisplayOrder),
            const SizedBox(height: 8),
            _OrderStepper(
                value: order, onChanged: (v) => setS(() => order = v)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: AdminSecondaryButton(
                      label: l10n.commonCancel,
                      onTap: () => Navigator.pop(ctx))),
              const SizedBox(width: 12),
              Expanded(
                child: AdminPrimaryButton(
                  label: cat == null ? l10n.commonSave : l10n.ctUpdate,
                  onTap: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    await _topicsService.saveCategory(CategoryModel(
                      id: cat?.id ?? _slugify(title),
                      title: title,
                      order: order,
                    ));
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _loadCategories();
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showTopicSheet(
      {required String categoryId, TopicModel? topic}) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: topic?.nameEn ?? '');
    final descCtrl = TextEditingController(text: topic?.descEn ?? '');
    final nameMkCtrl = TextEditingController(text: topic?.nameMk ?? '');
    final descMkCtrl = TextEditingController(text: topic?.descMk ?? '');
    var order = topic?.order ?? ((_topicsCache[categoryId]?.length ?? 0) + 1);
    var isNew = topic?.isNew ?? true;
    var isUpdated = topic?.isUpdated ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AdminBottomSheet(
          title: topic == null ? l10n.ctAddTopic : l10n.ctEditTopic,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminLabel(l10n.ctTopicName),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (_, ss) {
              final slug = _slugify(nameCtrl.text);
              nameCtrl.addListener(() => ss(() {}));
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AdminField(controller: nameCtrl, hint: l10n.ctEnterTopicName),
                if (topic == null && slug.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(l10n.ctIdLabel(slug),
                      style: GoogleFonts.nunito(
                          color: AppColors.blue, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ]);
            }),
            const SizedBox(height: 12),
            AdminLabel(l10n.lcDescription),
            const SizedBox(height: 8),
            AdminField(
                controller: descCtrl,
                hint: l10n.ctShortDescription,
                maxLines: 2),
            const SizedBox(height: 12),
            AdminLabel(l10n.ctNameMkLabel),
            const SizedBox(height: 8),
            AdminField(controller: nameMkCtrl, hint: l10n.ctEnterTopicName),
            const SizedBox(height: 12),
            AdminLabel(l10n.ctDescMkLabel),
            const SizedBox(height: 8),
            AdminField(
                controller: descMkCtrl,
                hint: l10n.ctShortDescription,
                maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: AdminToggle(
                  label: l10n.ctToggleNew,
                  value: isNew,
                  color: AppColors.pink,
                  onChanged: (v) => setS(() => isNew = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminToggle(
                  label: l10n.ctToggleUpdated,
                  value: isUpdated,
                  color: AppColors.orange,
                  onChanged: (v) => setS(() => isUpdated = v),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            AdminLabel(l10n.ctDisplayOrder),
            const SizedBox(height: 8),
            _OrderStepper(
                value: order, onChanged: (v) => setS(() => order = v)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: AdminSecondaryButton(
                      label: l10n.commonCancel,
                      onTap: () => Navigator.pop(ctx))),
              const SizedBox(width: 12),
              Expanded(
                child: AdminPrimaryButton(
                  label: topic == null ? l10n.commonSave : l10n.ctUpdate,
                  onTap: () async {
                    final name = nameCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    final nameMk = nameMkCtrl.text.trim();
                    final descMk = descMkCtrl.text.trim();
                    if (name.isEmpty || desc.isEmpty) return;
                    await _topicsService.saveTopic(TopicModel(
                      id: topic?.id ?? _slugify(name),
                      categoryId: categoryId,
                      // Store an {en, mk} map when a Macedonian copy is given,
                      // otherwise a plain English string.
                      name: nameMk.isEmpty ? name : {'en': name, 'mk': nameMk},
                      desc: descMk.isEmpty ? desc : {'en': desc, 'mk': descMk},
                      isNew: isNew,
                      isUpdated: isUpdated,
                      order: order,
                      createdAt: topic?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    ));
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _reloadTopics(categoryId);
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // â”€â”€ Delete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _deleteTopic(TopicModel topic) async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
        l10n.ctDeleteTopicTitle(topic.name),
        l10n.ctDeleteTopicBody)) {
      return;
    }
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final col in ['questions', 'learning_content']) {
      final snap =
          await db.collection(col).where('topicId', isEqualTo: topic.id).get();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
    }
    batch.delete(db.collection('topics').doc(topic.id));
    await batch.commit();
    if (!mounted) return;
    await _reloadTopics(topic.categoryId);
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.ctDeleteCategoryTitle(cat.title),
        l10n.ctDeleteCategoryBody)) {
      return;
    }
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final topics = await _topicsService.getTopicsByCategory(cat.id);
    for (final t in topics) {
      for (final col in ['questions', 'learning_content']) {
        final snap =
            await db.collection(col).where('topicId', isEqualTo: t.id).get();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
      }
      batch.delete(db.collection('topics').doc(t.id));
    }
    batch.delete(db.collection('categories').doc(cat.id));
    await batch.commit();
    if (!mounted) return;
    _topicsCache.remove(cat.id);
    await _loadCategories();
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(message,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).commonCancel,
                  style:
                      GoogleFonts.nunito(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).commonDelete,
                  style: GoogleFonts.nunito(
                      color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    return result ?? false;
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminHeader(
          title: AppLocalizations.of(context).adminCategoriesTopics,
          trailing: IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 20),
            ),
            onPressed: _showCategorySheet,
            tooltip: AppLocalizations.of(context).ctAddCategoryTooltip,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _loadingCategories
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.blue))
                  : _categories.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.category_rounded,
                          title: AppLocalizations.of(context).ctNoCategories,
                          subtitle: AppLocalizations.of(context).ctNoCategoriesSub,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      itemCount: _categories.length,
                      itemBuilder: (context, i) =>
                          _CategoryTile(
                            category: _categories[i],
                            topics: _topicsCache[_categories[i].id],
                            isLoadingTopics: _loadingTopics
                                .contains(_categories[i].id),
                            onExpand: () =>
                                _loadTopics(_categories[i].id),
                            onEditCategory: () =>
                                _showCategorySheet(cat: _categories[i]),
                            onDeleteCategory: () =>
                                _deleteCategory(_categories[i]),
                            onAddTopic: () => _showTopicSheet(
                                categoryId: _categories[i].id),
                            onEditTopic: (t) => _showTopicSheet(
                                categoryId: _categories[i].id,
                                topic: t),
                            onDeleteTopic: _deleteTopic,
                          ),
                      ),
              ),
            ),
          ),
      ]),
    );
  }
}

// â”€â”€â”€ Category expandable tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryTile extends StatefulWidget {
  final CategoryModel category;
  final List<TopicModel>? topics;
  final bool isLoadingTopics;
  final VoidCallback onExpand;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onAddTopic;
  final void Function(TopicModel) onEditTopic;
  final void Function(TopicModel) onDeleteTopic;

  const _CategoryTile({
    required this.category,
    required this.topics,
    required this.isLoadingTopics,
    required this.onExpand,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddTopic,
    required this.onEditTopic,
    required this.onDeleteTopic,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded && widget.topics == null) {
      widget.onExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicCount = widget.topics?.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _expanded ? AppColors.blue : AppColors.border,
            width: _expanded ? 2 : 1.5),
      ),
      child: Column(children: [
        // â”€â”€ Category row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(children: [
              AnimatedRotation(
                turns: _expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.chevron_right_rounded,
                    color: _expanded
                        ? AppColors.blue
                        : AppColors.textSecondary,
                    size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(widget.category.title,
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  if (topicCount != null)
                    Text(
                      AppLocalizations.of(context).ctTopicCount(topicCount),
                      style: GoogleFonts.nunito(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.blue, size: 18),
                onPressed: widget.onEditCategory,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                tooltip: AppLocalizations.of(context).ctEditCategory,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.red, size: 18),
                onPressed: widget.onDeleteCategory,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                tooltip: AppLocalizations.of(context).ctDeleteCategory,
              ),
            ]),
          ),
        ),

        // â”€â”€ Topics list (animated) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _expanded
              ? Column(children: [
                  Container(height: 1, color: AppColors.border),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(children: [
                      if (widget.isLoadingTopics)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                              color: AppColors.blue, strokeWidth: 2),
                        )
                      else if (widget.topics == null ||
                          widget.topics!.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            AppLocalizations.of(context).ctNoTopics,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        )
                      else
                        ...widget.topics!.map((t) => _TopicRow(
                              topic: t,
                              onEdit: () => widget.onEditTopic(t),
                              onDelete: () => widget.onDeleteTopic(t),
                            )),
                      const SizedBox(height: 6),
                      // Add topic button
                      GestureDetector(
                        onTap: widget.onAddTopic,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.blue
                                    .withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: AppColors.blue, size: 16),
                                const SizedBox(width: 6),
                                Text(AppLocalizations.of(context).ctAddTopic,
                                    style: GoogleFonts.nunito(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ]),
                        ),
                      ),
                    ]),
                  ),
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

// â”€â”€â”€ Topic row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TopicRow extends StatelessWidget {
  final TopicModel topic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicRow({
    required this.topic,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(topic.name,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
              if (topic.isNew) ...[
                const SizedBox(width: 4),
                AdminBadge(text: AppLocalizations.of(context).topicsBadgeNew, color: AppColors.pink),
              ],
              if (topic.isUpdated) ...[
                const SizedBox(width: 4),
                AdminBadge(text: AppLocalizations.of(context).topicsBadgeUpd, color: AppColors.orange),
              ],
            ]),
            if (topic.desc.isNotEmpty)
              Text(topic.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary, fontSize: 11)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined,
              color: AppColors.blue, size: 16),
          onPressed: onEdit,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.red, size: 16),
          onPressed: onDelete,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// â”€â”€â”€ Order stepper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrderStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _OrderStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5)),
      child: Row(children: [
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
          color: AppColors.blue,
          disabledColor: AppColors.textLight,
        ),
        Expanded(
            child: Center(
                child: Text('$value',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800, fontSize: 16)))),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
          color: AppColors.blue,
        ),
      ]),
    );
  }
}

