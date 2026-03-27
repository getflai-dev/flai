import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// A picked attachment from the device.
class PickedAttachment {
  /// The file path on disk.
  final String path;

  /// The file name.
  final String name;

  /// The MIME type, if known.
  final String? mimeType;

  /// The file size in bytes.
  final int? sizeBytes;

  /// Creates a [PickedAttachment].
  const PickedAttachment({
    required this.path,
    required this.name,
    this.mimeType,
    this.sizeBytes,
  });

  /// The [File] handle for this attachment.
  File get file => File(path);
}

/// Built-in device pickers for Camera, Photos, and Files.
///
/// These are the standard iOS/Android attachment options and work
/// out of the box — no developer configuration required.
class FlaiAttachmentPicker {
  FlaiAttachmentPicker._();

  static final _imagePicker = ImagePicker();

  /// Open the device camera and return the captured photo.
  static Future<PickedAttachment?> openCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return null;
    return PickedAttachment(
      path: image.path,
      name: image.name,
      mimeType: image.mimeType,
      sizeBytes: await image.length(),
    );
  }

  /// Open the photo library and return the selected image.
  static Future<PickedAttachment?> openPhotos() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return null;
    return PickedAttachment(
      path: image.path,
      name: image.name,
      mimeType: image.mimeType,
      sizeBytes: await image.length(),
    );
  }

  /// Open the file picker and return the selected file.
  static Future<PickedAttachment?> openFiles() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.path == null) return null;
    return PickedAttachment(
      path: file.path!,
      name: file.name,
      sizeBytes: file.size,
    );
  }
}
