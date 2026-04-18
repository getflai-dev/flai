import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers.dart';
import '../../providers/brain_provider.dart';

/// The Brain screen — Documents and Memory tabs.
///
/// Pulls data from the [BrainProvider] registered on [FlaiProviders].
/// If no provider is configured, an explanatory placeholder is shown.
///
/// Mirrors the CMMD web `/brain` route: a top tab bar with `Documents` and
/// `Memory`, search/filter chips, and a floating action button for new
/// uploads / notes / memories.
class FlaiBrainScreen extends StatefulWidget {
  /// Creates a [FlaiBrainScreen].
  const FlaiBrainScreen({super.key});

  @override
  State<FlaiBrainScreen> createState() => _FlaiBrainScreenState();
}

class _FlaiBrainScreenState extends State<FlaiBrainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final brain = FlaiProviders.of(context).brainProvider;

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Brain',
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colors.foreground),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colors.foreground,
          unselectedLabelColor: theme.colors.mutedForeground,
          indicatorColor: theme.colors.primary,
          indicatorWeight: 2,
          labelStyle: theme.typography.base.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.typography.base,
          tabs: const [
            Tab(text: 'Documents'),
            Tab(text: 'Memory'),
          ],
        ),
      ),
      body: brain == null
          ? const _BrainEmptyConfig()
          : TabBarView(
              controller: _tabController,
              children: [
                _DocumentsTab(provider: brain),
                _MemoryTab(provider: brain),
              ],
            ),
    );
  }
}

class _BrainEmptyConfig extends StatelessWidget {
  const _BrainEmptyConfig();

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: theme.colors.mutedForeground,
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              'Brain not configured',
              style: theme.typography.lg.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              'Pass a BrainProvider via AppScaffoldConfig.brainProvider '
              'to enable Documents and Memory.',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Documents Tab ───────────────────────────────────────────────────────────

class _DocumentsTab extends StatefulWidget {
  final BrainProvider provider;

  const _DocumentsTab({required this.provider});

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  late Future<List<BrainDocument>> _future;
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = widget.provider.loadDocuments();
  }

  void _reload() {
    setState(() {
      _future = widget.provider.loadDocuments();
    });
  }

  Future<void> _showNewMenu() async {
    final theme = FlaiTheme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FlaiTheme(
        data: theme,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.upload_file_rounded,
                  color: theme.colors.foreground,
                ),
                title: Text(
                  'Upload file',
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('upload'),
              ),
              ListTile(
                leading: Icon(
                  Icons.note_add_outlined,
                  color: theme.colors.foreground,
                ),
                title: Text(
                  'New note',
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('note'),
              ),
              SizedBox(height: theme.spacing.sm),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'upload') {
      await _pickAndUpload();
    } else if (action == 'note') {
      await _composeNote();
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      withData: true,
      allowMultiple: false,
    );
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    final f = files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    try {
      await widget.provider.uploadDocument(
        fileName: f.name,
        mimeType: 'application/octet-stream',
        bytes: bytes,
      );
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _composeNote() async {
    final titleCtl = TextEditingController();
    final bodyCtl = TextEditingController();
    final theme = FlaiTheme.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colors.background,
        title: Text(
          'New note',
          style: TextStyle(color: theme.colors.foreground),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Body'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    if (titleCtl.text.trim().isEmpty) return;
    try {
      await widget.provider.createNote(
        title: titleCtl.text.trim(),
        body: bodyCtl.text.trim(),
      );
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Stack(
      children: [
        FutureBuilder<List<BrainDocument>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(theme.spacing.xl),
                  child: Text(
                    'Could not load documents.\n${snapshot.error}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final docs = snapshot.data ?? [];
            final filtered = docs.where((d) {
              if (_filter != 'all' && d.source.toLowerCase() != _filter) {
                return false;
              }
              if (_search.isEmpty) return true;
              final q = _search.toLowerCase();
              return d.title.toLowerCase().contains(q) ||
                  (d.preview?.toLowerCase().contains(q) ?? false);
            }).toList();

            return Column(
              children: [
                _SearchField(
                  hint: 'Search documents',
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
                _FilterChipsRow(
                  current: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                  options: const [
                    ('all', 'All'),
                    ('upload', 'Uploads'),
                    ('note', 'Notes'),
                    ('slack', 'Slack'),
                    ('github', 'GitHub'),
                  ],
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyDocs(onAdd: _showNewMenu)
                      : RefreshIndicator(
                          onRefresh: () async => _reload(),
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.md,
                              vertical: theme.spacing.sm,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: theme.spacing.xs),
                            itemBuilder: (_, i) =>
                                _DocumentRow(doc: filtered[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
        Positioned(
          right: theme.spacing.md,
          bottom: theme.spacing.md,
          child: FloatingActionButton(
            backgroundColor: theme.colors.primary,
            foregroundColor: theme.colors.primaryForeground,
            onPressed: _showNewMenu,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final BrainDocument doc;

  const _DocumentRow({required this.doc});

  IconData get _icon {
    switch (doc.source.toLowerCase()) {
      case 'note':
        return Icons.sticky_note_2_outlined;
      case 'slack':
        return Icons.tag_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'upload':
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(theme.radius.lg),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 20, color: theme.colors.foreground),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (doc.preview != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    doc.preview!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MetaTag(label: doc.source),
                    if (doc.folder != null) ...[
                      const SizedBox(width: 6),
                      _MetaTag(label: doc.folder!),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      _relativeTime(doc.updatedAt),
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final String label;
  const _MetaTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colors.border),
      ),
      child: Text(
        label,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyDocs extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDocs({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: theme.colors.mutedForeground,
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              'No documents yet',
              style: theme.typography.lg.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              'Upload files or write notes to give Nova more context.',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.spacing.md),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Memory Tab ──────────────────────────────────────────────────────────────

class _MemoryTab extends StatefulWidget {
  final BrainProvider provider;

  const _MemoryTab({required this.provider});

  @override
  State<_MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<_MemoryTab> {
  late Future<List<BrainMemory>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.provider.loadMemories();
  }

  void _reload() {
    setState(() {
      _future = widget.provider.loadMemories();
    });
  }

  Future<void> _addMemory() async {
    final ctl = TextEditingController();
    final theme = FlaiTheme.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colors.background,
        title: Text(
          'Add memory',
          style: TextStyle(color: theme.colors.foreground),
        ),
        content: TextField(
          controller: ctl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Lives in NYC. Prefers concise answers.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    if (ctl.text.trim().isEmpty) return;
    try {
      await widget.provider.addMemory(text: ctl.text.trim());
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _delete(BrainMemory m) async {
    try {
      await widget.provider.deleteMemory(m.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Stack(
      children: [
        FutureBuilder<List<BrainMemory>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(theme.spacing.xl),
                  child: Text(
                    'Could not load memories.\n${snapshot.error}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final memories = snapshot.data ?? [];
            if (memories.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(theme.spacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 48,
                        color: theme.colors.mutedForeground,
                      ),
                      SizedBox(height: theme.spacing.md),
                      Text(
                        'No memories yet',
                        style: theme.typography.lg.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        "Nova will remember durable facts about you over time.",
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            final grouped = <String, List<BrainMemory>>{};
            for (final m in memories) {
              grouped.putIfAbsent(m.category, () => []).add(m);
            }
            final keys = grouped.keys.toList();
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.md,
                  vertical: theme.spacing.sm,
                ),
                itemCount: keys.length,
                itemBuilder: (_, gi) {
                  final cat = keys[gi];
                  final items = grouped[cat]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: theme.spacing.xs,
                        ),
                        child: Text(
                          cat.toUpperCase(),
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      ...items.map(
                        (m) => Dismissible(
                          key: ValueKey(m.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.md,
                            ),
                            color: const Color(0xFFFF3B30).withValues(
                              alpha: 0.15,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                          onDismissed: (_) => _delete(m),
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: theme.spacing.xs,
                            ),
                            padding: EdgeInsets.all(theme.spacing.md),
                            decoration: BoxDecoration(
                              color: theme.colors.muted,
                              borderRadius: BorderRadius.circular(
                                theme.radius.lg,
                              ),
                              border: Border.all(color: theme.colors.border),
                            ),
                            child: Text(
                              m.text,
                              style: theme.typography.base.copyWith(
                                color: theme.colors.foreground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: theme.spacing.sm),
                    ],
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          right: theme.spacing.md,
          bottom: theme.spacing.md,
          child: FloatingActionButton(
            backgroundColor: theme.colors.primary,
            foregroundColor: theme.colors.primaryForeground,
            onPressed: _addMemory,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

// ── Shared chrome ───────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.md,
        theme.spacing.sm,
        theme.spacing.md,
        theme.spacing.xs,
      ),
      child: TextField(
        onChanged: onChanged,
        style: theme.typography.base.copyWith(color: theme.colors.foreground),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.typography.base.copyWith(
            color: theme.colors.mutedForeground,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colors.mutedForeground,
            size: 20,
          ),
          filled: true,
          fillColor: theme.colors.muted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radius.md),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  final List<(String, String)> options;

  const _FilterChipsRow({
    required this.current,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.xs,
        ),
        itemCount: options.length,
        separatorBuilder: (_, _) => SizedBox(width: theme.spacing.xs),
        itemBuilder: (_, i) {
          final (id, label) = options[i];
          final selected = id == current;
          return InkWell(
            borderRadius: BorderRadius.circular(theme.radius.full),
            onTap: () => onChanged(id),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: selected ? theme.colors.primary : theme.colors.muted,
                borderRadius: BorderRadius.circular(theme.radius.full),
                border: Border.all(
                  color: selected ? theme.colors.primary : theme.colors.border,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.typography.sm.copyWith(
                    color: selected
                        ? theme.colors.primaryForeground
                        : theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

