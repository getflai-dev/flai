import 'dart:typed_data';

/// A document stored in the user's Brain (Knowledge Base).
///
/// Documents may be uploaded files, captured notes, or extracted
/// pages from connected sources (Slack, GitHub, etc.). They are
/// scoped to either the personal Account or a Workspace folder.
class BrainDocument {
  /// Unique server-side identifier.
  final String id;

  /// Display name (e.g. `Q3 strategy notes`).
  final String title;

  /// Optional one-line preview (first ~120 chars of body).
  final String? preview;

  /// Source label (e.g. `Upload`, `Note`, `Slack`, `GitHub`).
  final String source;

  /// Folder label (e.g. `Account`, `Workspace`, `Engineering`).
  final String? folder;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Server-reported byte size of the underlying file, when known.
  final int? sizeBytes;

  /// Creates a [BrainDocument].
  const BrainDocument({
    required this.id,
    required this.title,
    this.preview,
    required this.source,
    this.folder,
    required this.updatedAt,
    this.sizeBytes,
  });
}

/// A single fact stored in long-term Memory (e.g. `Lives in NYC`).
///
/// Memories are grouped by [category] in the UI. Each is a short
/// declarative sentence written by the assistant when it learns
/// something durable about the user.
class BrainMemory {
  /// Unique server-side identifier.
  final String id;

  /// The remembered fact, in the user's voice.
  final String text;

  /// High-level group (e.g. `About you`, `Work`, `Preferences`).
  final String category;

  /// When this memory was first stored.
  final DateTime createdAt;

  /// Creates a [BrainMemory].
  const BrainMemory({
    required this.id,
    required this.text,
    required this.category,
    required this.createdAt,
  });
}

/// A logical container for documents (e.g. `Account`, `Engineering`).
class BrainFolder {
  /// Unique server-side identifier.
  final String id;

  /// Folder name.
  final String name;

  /// Whether this folder is workspace-shared (vs personal Account).
  final bool isShared;

  /// Document count, when known.
  final int? documentCount;

  /// Creates a [BrainFolder].
  const BrainFolder({
    required this.id,
    required this.name,
    this.isShared = false,
    this.documentCount,
  });
}

/// Source of truth for the user's Brain.
///
/// Implement this to back the [FlaiBrainScreen] with documents,
/// memories, and folder operations from any backend (CMMD, custom
/// REST, in-memory, etc.).
abstract class BrainProvider {
  /// Lists all available folders (Account + Workspace + custom).
  Future<List<BrainFolder>> loadFolders();

  /// Lists documents, optionally scoped to [folderId].
  Future<List<BrainDocument>> loadDocuments({String? folderId});

  /// Uploads a binary file to the Brain. Returns the new document
  /// once the server has accepted it. The mime type is required
  /// because backends typically dispatch processing on it.
  Future<BrainDocument> uploadDocument({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    String? folderId,
  });

  /// Saves a free-form note as a document.
  Future<BrainDocument> createNote({
    required String title,
    required String body,
    String? folderId,
  });

  /// Removes a document (server-side).
  Future<void> deleteDocument(String id);

  /// Lists memories, grouped by [BrainMemory.category] in the UI.
  Future<List<BrainMemory>> loadMemories();

  /// Adds a new memory.
  Future<BrainMemory> addMemory({
    required String text,
    String category = 'About you',
  });

  /// Removes a memory (server-side).
  Future<void> deleteMemory(String id);
}
