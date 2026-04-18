import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'brain_provider.dart';
import 'cmmd_client_base.dart';
import 'cmmd_config.dart';

/// CMMD API implementation of [BrainProvider].
///
/// Endpoint shapes are based on the CMMD web client's `/brain` route:
///
///   * `GET    /api/ai/brain/documents`       — list documents
///   * `POST   /api/ai/brain/documents`       — create note
///   * `POST   /api/ai/brain/documents/upload`— multipart upload
///   * `DELETE /api/ai/brain/documents/{id}`  — delete document
///   * `GET    /api/ai/brain/folders`         — list folders
///   * `GET    /api/ai/memories`              — list memories
///   * `POST   /api/ai/memories`              — add memory
///   * `DELETE /api/ai/memories/{id}`         — delete memory
///
/// On 404 / server errors, methods throw [CmmdApiException] which the UI
/// surfaces as a friendly message — endpoints can be retuned in one place
/// here without changing the screen code.
class CmmdBrainProvider with CmmdClientBase implements BrainProvider {
  CmmdBrainProvider({
    required this.config,
    required this.accessTokenProvider,
    this.organizationIdProvider,
    this.csrfHeadersProvider,
  });

  @override
  final CmmdConfig config;

  @override
  final String Function() accessTokenProvider;

  @override
  final String? Function()? organizationIdProvider;

  @override
  final Map<String, String> Function()? csrfHeadersProvider;

  // ── Folders ────────────────────────────────────────────────────────────

  @override
  Future<List<BrainFolder>> loadFolders() async {
    final response = await cmmdGet('/api/ai/brain/folders');
    final json = jsonDecode(response.body);
    final list = _extractList(json);
    return list
        .map((e) => _parseFolder(e as Map<String, dynamic>))
        .toList();
  }

  // ── Documents ──────────────────────────────────────────────────────────

  @override
  Future<List<BrainDocument>> loadDocuments({String? folderId}) async {
    final qs = folderId == null ? '' : '?folderId=$folderId';
    final response = await cmmdGet('/api/ai/brain/documents$qs');
    final json = jsonDecode(response.body);
    final list = _extractList(json);
    return list
        .map((e) => _parseDocument(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BrainDocument> uploadDocument({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    String? folderId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/ai/brain/documents/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(cmmdHeaders()..remove('Content-Type'))
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
    if (folderId != null) {
      request.fields['folderId'] = folderId;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseDocument(_extractObject(json));
  }

  @override
  Future<BrainDocument> createNote({
    required String title,
    required String body,
    String? folderId,
  }) async {
    final response = await cmmdPost(
      '/api/ai/brain/documents',
      body: {
        'title': title,
        'body': body,
        'source': 'note',
        'folderId': ?folderId,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseDocument(_extractObject(json));
  }

  @override
  Future<void> deleteDocument(String id) async {
    await cmmdDelete('/api/ai/brain/documents/$id');
  }

  // ── Memories ───────────────────────────────────────────────────────────

  @override
  Future<List<BrainMemory>> loadMemories() async {
    final response = await cmmdGet('/api/ai/memories');
    final json = jsonDecode(response.body);
    final list = _extractList(json);
    return list
        .map((e) => _parseMemory(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BrainMemory> addMemory({
    required String text,
    String category = 'About you',
  }) async {
    final response = await cmmdPost(
      '/api/ai/memories',
      body: {'text': text, 'category': category},
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseMemory(_extractObject(json));
  }

  @override
  Future<void> deleteMemory(String id) async {
    await cmmdDelete('/api/ai/memories/$id');
  }

  // ── Parsers ────────────────────────────────────────────────────────────

  /// Extract a list from common server envelope shapes:
  ///   * `[...]`
  ///   * `{ "data": [...] }`
  ///   * `{ "items": [...] }`
  static List _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map<String, dynamic>) {
      return (json['data'] as List? ?? json['items'] as List? ?? const []);
    }
    return const [];
  }

  /// Extract the inner object from common server envelope shapes:
  ///   * `{...the object...}`
  ///   * `{ "data": {...} }`
  static Map<String, dynamic> _extractObject(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map<String, dynamic>) return inner;
    return json;
  }

  static BrainDocument _parseDocument(Map<String, dynamic> j) {
    return BrainDocument(
      id: (j['id'] ?? j['_id']).toString(),
      title: (j['title'] ?? j['name'] ?? 'Untitled').toString(),
      preview: j['preview'] as String? ?? j['summary'] as String?,
      source: (j['source'] ?? j['type'] ?? 'upload').toString(),
      folder: j['folderName'] as String? ?? j['folder'] as String?,
      updatedAt: CmmdClientBase.parseDateTime(
        j['updatedAt'] ?? j['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      sizeBytes: (j['sizeBytes'] as num?)?.toInt(),
    );
  }

  static BrainFolder _parseFolder(Map<String, dynamic> j) {
    return BrainFolder(
      id: (j['id'] ?? j['_id']).toString(),
      name: (j['name'] ?? 'Folder').toString(),
      isShared:
          (j['isShared'] as bool?) ??
          (j['scope'] == 'workspace' || j['scope'] == 'shared'),
      documentCount: (j['count'] as num?)?.toInt(),
    );
  }

  static BrainMemory _parseMemory(Map<String, dynamic> j) {
    return BrainMemory(
      id: (j['id'] ?? j['_id']).toString(),
      text: (j['text'] ?? j['content'] ?? '').toString(),
      category: (j['category'] ?? j['group'] ?? 'About you').toString(),
      createdAt: CmmdClientBase.parseDateTime(
        j['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
