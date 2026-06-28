import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/learning_content_model.dart';
import '../../models/topic_model.dart';
import '../../services/learning_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';

class ManageLearningContentScreen extends StatefulWidget {
  const ManageLearningContentScreen({super.key});

  @override
  State<ManageLearningContentScreen> createState() =>
      _ManageLearningContentScreenState();
}

class _ManageLearningContentScreenState
    extends State<ManageLearningContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<_AddContentFormState>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(
            title: 'Learning Content',
            tabController: _tabs,
            tabs: const ['Add Content', 'All Content'],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _AddContentForm(key: _formKey),
                    _ContentBrowser(onEdit: (item) {
                      _formKey.currentState?.loadForEdit(item);
                      _tabs.animateTo(0);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Add / Edit form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddContentForm extends StatefulWidget {
  const _AddContentForm({super.key});

  @override
  State<_AddContentForm> createState() => _AddContentFormState();
}

class _AddContentFormState extends State<_AddContentForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _readTimeCtrl = TextEditingController();

  final _topicsService = TopicsService();
  final _learningService = LearningService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _categoryId;
  String? _topicId;
  bool _loading = true;
  bool _saving = false;
  // Only Article and Video - Image type removed.
  ContentType _type = ContentType.article;
  LearningContentModel? _editing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _readTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await _topicsService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _categoryId = cats.isNotEmpty ? cats.first.id : null;
      });
      if (_categoryId != null) {
        await _loadTopics(_categoryId!);
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTopics(String catId) async {
    if (mounted) setState(() => _loading = true);
    try {
      final topics = await _topicsService.getTopicsByCategory(catId);
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _topicId = topics.isNotEmpty ? topics.first.id : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void loadForEdit(LearningContentModel item) {
    setState(() {
      _editing = item;
      _titleCtrl.text = item.title;
      _descCtrl.text = item.description;
      _contentCtrl.text = item.content;
      _readTimeCtrl.text =
          item.readTimeMinutes > 0 ? '${item.readTimeMinutes}' : '';
      // Treat infographic as article when editing (image type removed)
      _type = item.type == ContentType.infographic
          ? ContentType.article
          : item.type;
      _categoryId = item.categoryId;
      _topicId = item.topicId;
    });
    _loadTopics(item.categoryId);
  }

  void _clearForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _contentCtrl.clear();
    _readTimeCtrl.clear();
    setState(() {
      _editing = null;
      _type = ContentType.article;
    });
  }

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) {
      _snack('Select category and topic', isError: true);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      _snack('Title and content are required', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = LearningContentModel(
        id: _editing?.id ?? '',
        categoryId: _categoryId!,
        topicId: _topicId!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _type,
        content: _contentCtrl.text.trim(),
        readTimeMinutes: int.tryParse(_readTimeCtrl.text.trim()) ?? 0,
        createdAt: _editing?.createdAt ?? DateTime.now(),
      );
      _editing != null
          ? await _learningService.updateContent(model)
          : await _learningService.saveContent(model);
      _clearForm();
      setState(() => _saving = false);
      _snack(_editing != null ? 'Content updated!' : 'Content saved!');
    } catch (e) {
      setState(() => _saving = false);
      _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? AppColors.red : AppColors.blue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.blue));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (_editing != null)
          AdminEditBanner(title: _editing!.title, onClear: _clearForm),

        // â”€â”€ Location â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        AdminCard(
          title: 'Location',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AdminLabel('Category'),
            const SizedBox(height: 8),
            AdminDropdown<String>(
              value: _categoryId,
              hint: 'Select category',
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.title)))
                  .toList(),
              onChanged: (val) async {
                if (val == null) return;
                setState(() {
                  _categoryId = val;
                  _topicId = null;
                });
                await _loadTopics(val);
              },
            ),
            const SizedBox(height: 12),
            const AdminLabel('Topic'),
            const SizedBox(height: 8),
            AdminDropdown<String>(
              value: _topicId,
              hint: 'Select topic',
              items: _topics
                  .map((t) =>
                      DropdownMenuItem(value: t.id, child: Text(t.name)))
                  .toList(),
              onChanged: (val) => setState(() => _topicId = val),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // â”€â”€ Type â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        AdminCard(
          title: 'Content type',
          child: Row(children: [
            Expanded(
              child: AdminTypeButton(
                label: 'Article',
                icon: Icons.article_rounded,
                selected: _type == ContentType.article,
                onTap: () => setState(() => _type = ContentType.article),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminTypeButton(
                label: 'Video',
                icon: Icons.play_circle_rounded,
                selected: _type == ContentType.video,
                onTap: () => setState(() => _type = ContentType.video),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // â”€â”€ Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        AdminCard(
          title: 'Details',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AdminLabel('Title'),
            const SizedBox(height: 8),
            AdminField(controller: _titleCtrl, hint: 'Content title'),
            const SizedBox(height: 12),
            const AdminLabel('Description'),
            const SizedBox(height: 8),
            AdminField(
              controller: _descCtrl,
              hint: 'Short description shown on card',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AdminLabel(_type == ContentType.video
                ? 'YouTube Video ID'
                : 'Article text'),
            const SizedBox(height: 8),
            AdminField(
              controller: _contentCtrl,
              maxLines: _type == ContentType.article ? 8 : 1,
              hint: _type == ContentType.video
                  ? 'e.g. https://www.youtube.com/watch?v=dQw4w9WgXcQ'
                  : 'Write your article here...',
            ),
            if (_type == ContentType.article) ...[
              const SizedBox(height: 12),
              const AdminLabel('Read time (minutes)'),
              const SizedBox(height: 8),
              AdminField(
                controller: _readTimeCtrl,
                hint: 'e.g. 3',
                keyboardType: TextInputType.number,
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        AdminPrimaryButton(
          label: _saving
              ? 'Saving...'
              : (_editing != null ? 'Update Content' : 'Save Content'),
          onTap: _saving ? () {} : _save,
        ),
      ],
    );
  }
}

// â”€â”€â”€ Content list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// "All Content" with the same browse model as the questions tab: search, then
/// narrow by category → topic, with inline edit + delete on each row.
class _ContentBrowser extends StatefulWidget {
  final void Function(LearningContentModel) onEdit;
  const _ContentBrowser({required this.onEdit});

  @override
  State<_ContentBrowser> createState() => _ContentBrowserState();
}

class _ContentBrowserState extends State<_ContentBrowser> {
  final _searchCtrl = TextEditingController();
  final _topicsService = TopicsService();

  String _search = '';
  String? _categoryId;
  String? _topicId;

  List<CategoryModel> _categories = [];
  List<TopicModel> _allTopics = [];
  bool _loadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final cats = await _topicsService.getCategories();
      final topics = await _topicsService.getAllTopics();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _allTopics = topics;
        _loadingFilters = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  String _categoryTitle(String id) {
    for (final c in _categories) {
      if (c.id == id) return c.title;
    }
    return id;
  }

  String _topicName(String id) {
    for (final t in _allTopics) {
      if (t.id == id) return t.name;
    }
    return id;
  }

  List<TopicModel> get _topicsForCategory => _categoryId == null
      ? const []
      : _allTopics.where((t) => t.categoryId == _categoryId).toList();

  List<LearningContentModel> _applyFilters(List<LearningContentModel> all) {
    final query = _search.trim().toLowerCase();
    return all.where((c) {
      if (_categoryId != null && c.categoryId != _categoryId) return false;
      if (_topicId != null && c.topicId != _topicId) return false;
      if (query.isNotEmpty) {
        final inTitle = c.title.toLowerCase().contains(query);
        final inDesc = c.description.toLowerCase().contains(query);
        if (!inTitle && !inDesc) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _delete(
      BuildContext context, LearningContentModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete content?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('Delete "${item.title}"?',
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style:
                      GoogleFonts.nunito(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: GoogleFonts.nunito(
                      color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await LearningService().deleteContent(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Deleted',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: AppColors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AdminSearchField(
            controller: _searchCtrl,
            hint: 'Search content...',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        if (!_loadingFilters && _categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Expanded(
                child: AdminFilterDropdown(
                  icon: Icons.category_outlined,
                  value: _categoryId ?? 'all',
                  options: [
                    (value: 'all', label: 'All categories'),
                    for (final c in _categories) (value: c.id, label: c.title),
                  ],
                  onChanged: (v) => setState(() {
                    _categoryId = v == 'all' ? null : v;
                    _topicId = null;
                  }),
                ),
              ),
              if (_categoryId != null && _topicsForCategory.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AdminFilterDropdown(
                    icon: Icons.tag_rounded,
                    value: _topicId ?? 'all',
                    options: [
                      (value: 'all', label: 'All topics'),
                      for (final t in _topicsForCategory)
                        (value: t.id, label: t.name),
                    ],
                    onChanged: (v) =>
                        setState(() => _topicId = v == 'all' ? null : v),
                  ),
                ),
              ],
            ]),
          ),
        Expanded(
          child: StreamBuilder<List<LearningContentModel>>(
            stream: LearningService().getAllContent(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.blue));
              }
              if (snap.data!.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.library_books_rounded,
                  title: 'No content yet',
                  subtitle: 'Add some from the "Add Content" tab',
                );
              }
              final items = _applyFilters(snap.data!);
              if (items.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  subtitle: 'Try a different search or filter',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 16, 6),
                    child: Text(
                      '${items.length} item${items.length == 1 ? '' : 's'}',
                      style: GoogleFonts.nunito(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _ContentRow(
                        item: items[i],
                        location:
                            '${_categoryTitle(items[i].categoryId)} • ${_topicName(items[i].topicId)}',
                        onEdit: () => widget.onEdit(items[i]),
                        onDelete: () => _delete(context, items[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One compact learning-content row with inline edit + delete.
class _ContentRow extends StatelessWidget {
  final LearningContentModel item;
  final String location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ContentRow({
    required this.item,
    required this.location,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == ContentType.video;
    final typeColor = isVideo ? AppColors.red : AppColors.blue;
    final typeLabel = isVideo ? 'VIDEO' : 'ARTICLE';
    final typeIcon =
        isVideo ? Icons.play_circle_rounded : Icons.article_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [AdminBadge(text: typeLabel, color: typeColor)]),
            const SizedBox(height: 4),
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.folder_outlined,
                  color: AppColors.textLight, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        color: AppColors.textLight, fontSize: 11.5)),
              ),
            ]),
          ]),
        ),
        IconButton(
          tooltip: 'Edit',
          icon:
              const Icon(Icons.edit_outlined, color: AppColors.blue, size: 19),
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.red, size: 19),
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

