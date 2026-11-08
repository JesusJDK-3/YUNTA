import 'package:flutter/material.dart';

import '../app_state.dart';
import '../domain/boards.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/yunta_exception.dart';
import 'detail_page.dart';
import '../widgets/account_sheet.dart';
import '../widgets/chrome.dart';
import '../widgets/publish_sheet.dart';
import '../widgets/tutorial.dart';

/// Muro con tres pestañas. La búsqueda filtra la lista ya cargada (máximo 40).
class WallPage extends StatefulWidget {
  const WallPage({super.key, required this.app});
  final AppState app;

  @override
  State<WallPage> createState() => _WallPageState();
}

class _WallPageState extends State<WallPage> {
  String _tab = 'ayuda';
  List<FeedItem> _items = const [];
  bool _needsLocation = false;
  bool _offline = false;
  bool _loading = true;
  String? _error;
  int _pending = 0;
  List<BlockView> _blocks = const [];
  String _query = '';
  ViewerPoint? _loadedPoint;
  String _chrome = '';
  final Map<String, _FeedSnapshot> _feedCache = {};

  @override
  void initState() {
    super.initState();
    widget.app.addListener(_onApp);
    _load();
  }

  @override
  void dispose() {
    widget.app.removeListener(_onApp);
    super.dispose();
  }

  void _onApp() {
    final point = widget.app.point;
    if (point?.lat != _loadedPoint?.lat || point?.lng != _loadedPoint?.lng) {
      _load();
      return;
    }
    final chrome = _chromeStamp();
    if (!mounted || chrome == _chrome) return;
    setState(() => _chrome = chrome);
  }

  String _feedKey() {
    final point = widget.app.point;
    final zone = widget.app.session?.zoneId ?? '';
    return '$_tab|$zone|${point?.lat ?? ''}|${point?.lng ?? ''}';
  }

  String _chromeStamp() {
    final session = widget.app.session;
    return '${session?.userId}|${session?.displayName}|${session?.zoneId}|${widget.app.notice}|${widget.app.showTutorial}|${widget.app.placeStatus.name}';
  }

  Future<void> _load() async {
    _loadedPoint = widget.app.point;
    _chrome = _chromeStamp();
    final key = _feedKey();
    final cached = _feedCache[key];
    if (cached != null && mounted) {
      setState(() {
        _items = cached.items;
        _needsLocation = cached.needsLocation;
        _offline = cached.offline;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final result = await widget.app.api.feed(_tab, widget.app.point);
      final posts = await widget.app.api.pendingPublishes();
      final messages = await widget.app.api.pendingMessages();
      final blocks = await widget.app.api.blocks();
      if (!mounted) return;
      _feedCache[key] = _FeedSnapshot(result.items, result.needsLocation, result.offline);
      setState(() {
        if (!_sameFeed(_items, result.items)) _items = result.items;
        _needsLocation = result.needsLocation;
        _offline = result.offline;
        _pending = posts + messages;
        _blocks = blocks;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = asYunta(error).text;
        _loading = false;
      });
    }
  }

  void _open(BuildContext context, String id) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DetailPage(app: widget.app, id: id),
    ));
  }

  void _selectTab(String tab) {
    setState(() => _tab = tab);
    if (tab == 'emergencias' && widget.app.placeStatus == PlaceStatus.idle) {
      widget.app.askPlace();
    }
    _load();
  }

  List<FeedItem> get _shown {
    final needle = parseSearch(_query);
    if (needle.isEmpty) return _items;
    return _items
        .where((item) => '${item.title} ${item.description} ${item.authorName}'.toLowerCase().contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.app.session;
    final shown = _shown;
    final boards = splitEmergencyBoard(shown);
    final initial = (session?.displayName.trim().isNotEmpty ?? false) ? session!.displayName.trim()[0].toUpperCase() : 'Y';
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Row(
                  children: [
                    const Wordmark(compact: true),
                    const Spacer(),
                    Semantics(
                      label: 'Mis datos, ${session?.displayName ?? ''}',
                      button: true,
                      child: IconButton.filledTonal(
                        onPressed: () => showAccountSheet(context, widget.app, _blocks),
                        icon: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    TextButton(onPressed: widget.app.signOut, child: const Text('Salir')),
                  ],
                ),
                Text('Cerca de ti · ${session?.zoneName ?? ''}'),
                const SizedBox(height: 8),
                if (widget.app.notice != null)
                  NoticeBanner(widget.app.notice!),
                if (_pending > 0)
                  NoticeBanner(_pending == 1 ? '1 pendiente de envío.' : '$_pending pendientes de envío.'),
                if (_offline)
                  const NoticeBanner('Sin conexión. Esta es la última lista guardada. La búsqueda funciona sobre ella.'),
                if (_error != null) NoticeBanner(_error!, alert: true),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ayuda', label: Text('Ayuda')),
                    ButtonSegment(value: 'servicios', label: Text('Oficios'), tooltip: 'Productos y servicios'),
                    ButtonSegment(value: 'emergencias', label: Text('Emergencias')),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (value) => _selectTab(value.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Buscar en esta lista', hintText: 'Gasfiter, muleta, baldes'),
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (_needsLocation) ...[
                  const SizedBox(height: 12),
                  const Text('Sin ubicación solo ves los grupos de apoyo de tu zona.'),
                  OutlinedButton(
                    onPressed: widget.app.placeStatus == PlaceStatus.loading ? null : widget.app.askPlace,
                    child: const Text('Usar mi ubicación'),
                  ),
                ],
                if (_loading) const Padding(padding: EdgeInsets.only(top: 16), child: Text('Cargando el muro…')),
                if (!_loading && _tab != 'emergencias' && shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('No hay avisos con ese filtro. Puedes publicar el primero.'),
                  ),
                if (!_loading && _tab == 'servicios')
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Productos y oficios de tu zona, con visto bueno de vecinos.'),
                  ),
                if (!_loading && _tab != 'emergencias')
                  for (final item in shown) _FeedCard(item: item, onOpen: (id) => _open(context, id)),
                if (!_loading && _tab == 'emergencias') ...[
                  _Board(
                    title: 'Tablero de ayuda humanitaria',
                    hint: 'Vecinos y cuadras que piden apoyo cerca de ti.',
                    empty: _needsLocation ? 'Con la ubicación aparecen los reportes a 500 m.' : 'Todavía no hay reportes cerca.',
                    items: boards.humanitario,
                    onOpen: (id) => _open(context, id),
                  ),
                  _Board(
                    title: 'Economía solidaria',
                    hint: 'Espacio para coordinar y compartir recursos críticos, sin dinero.',
                    empty: _needsLocation ? 'Con la ubicación aparecen los recursos a 500 m.' : 'Todavía no hay recursos críticos.',
                    items: boards.solidaria,
                    onOpen: (id) => _open(context, id),
                  ),
                  _Board(
                    title: 'Grupos de apoyo',
                    hint: 'Servicios y grupos disponibles en tu zona durante la emergencia.',
                    empty: 'Todavía no hay grupos de apoyo en tu zona.',
                    items: boards.apoyo,
                    onOpen: (id) => _open(context, id),
                  ),
                ],
              ],
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: FilledButton(
                onPressed: () async {
                  final id = await showPublishSheet(context, widget.app);
                  if (id != null && context.mounted) _open(context, id);
                },
                child: const Text('Publicar'),
              ),
            ),
            if (widget.app.showTutorial)
              Positioned.fill(child: TutorialCard(onDone: widget.app.finishTutorial)),
          ],
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.title,
    required this.hint,
    required this.empty,
    required this.items,
    required this.onOpen,
  });

  final String title;
  final String hint;
  final String empty;
  final List<FeedItem> items;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(hint),
          if (items.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(empty)),
          for (final item in items) _FeedCard(item: item, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item, required this.onOpen});
  final FeedItem item;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final mode = modeLabel(item.coordinationMode);
    final bits = <String>[
      if (mode != null) mode,
      statusLabel(item.status),
      if (item.recommendationCount > 0) 'Recomendado por ${item.recommendationCount} vecinos',
      if (item.ratingAverage != null) 'Valoración ${item.ratingAverage}',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: ListTile(
          title: Text(item.title),
          subtitle: Text(
            '${item.authorName} · ${item.areaLabel}'
            '${item.distanceLabel == null ? '' : ' · ${item.distanceLabel}'}\n${bits.join(' · ')}',
          ),
          isThreeLine: true,
          trailing: item.category == 'emergencia' ? const Icon(Icons.warning_amber_rounded) : null,
          onTap: () => onOpen(item.id),
        ),
      ),
    );
  }
}

class _FeedSnapshot {
  const _FeedSnapshot(this.items, this.needsLocation, this.offline);
  final List<FeedItem> items;
  final bool needsLocation;
  final bool offline;
}

bool _sameFeed(List<FeedItem> current, List<FeedItem> next) {
  if (current.length != next.length) return false;
  for (var i = 0; i < current.length; i++) {
    final item = current[i];
    final other = next[i];
    if (item.id != other.id ||
        item.title != other.title ||
        item.status != other.status ||
        item.recommendationCount != other.recommendationCount ||
        item.ratingAverage != other.ratingAverage) {
      return false;
    }
  }
  return true;
}
