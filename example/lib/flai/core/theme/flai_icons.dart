import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Semantic icon set for FlAI components.
///
/// Each theme preset provides its own icon mapping, allowing
/// components to render with a consistent icon style per theme.
class FlaiIconData {
  /// The icon for tool/function call indicators.
  final IconData toolCall;

  /// The icon for AI thinking/reasoning indicators.
  final IconData thinking;

  /// The icon for citation or source attribution.
  final IconData citation;

  /// The icon for image content.
  final IconData image;

  /// The icon for broken or failed image loads.
  final IconData brokenImage;

  /// The icon for code blocks.
  final IconData code;

  /// The icon for copy-to-clipboard actions.
  final IconData copy;

  /// The icon for success/check confirmation.
  final IconData check;

  /// The icon for close or dismiss actions.
  final IconData close;

  /// The icon for sending a message.
  final IconData send;

  /// The icon for attaching files.
  final IconData attach;

  /// The icon for search actions.
  final IconData search;

  /// The icon for delete actions.
  final IconData delete;

  /// The icon for add/create actions.
  final IconData add;

  /// The icon for expanding collapsed content.
  final IconData expand;

  /// The icon for collapsing expanded content.
  final IconData collapse;

  /// The icon for chat or conversation.
  final IconData chat;

  /// The icon for AI model selection.
  final IconData model;

  /// The icon for refresh or retry actions.
  final IconData refresh;

  /// The icon for error states.
  final IconData error;

  const FlaiIconData({
    required this.toolCall,
    required this.thinking,
    required this.citation,
    required this.image,
    required this.brokenImage,
    required this.code,
    required this.copy,
    required this.check,
    required this.close,
    required this.send,
    required this.attach,
    required this.search,
    required this.delete,
    required this.add,
    required this.expand,
    required this.collapse,
    required this.chat,
    required this.model,
    required this.refresh,
    required this.error,
  });

  /// Material Design rounded icons — default for light and dark themes.
  factory FlaiIconData.material() => const FlaiIconData(
    toolCall: Icons.build_rounded,
    thinking: Icons.psychology_rounded,
    citation: Icons.format_quote_rounded,
    image: Icons.image_rounded,
    brokenImage: Icons.broken_image_rounded,
    code: Icons.code_rounded,
    copy: Icons.content_copy_rounded,
    check: Icons.check_rounded,
    close: Icons.close_rounded,
    send: Icons.send_rounded,
    attach: Icons.attach_file_rounded,
    search: Icons.search_rounded,
    delete: Icons.delete_rounded,
    add: Icons.add_rounded,
    expand: Icons.expand_more_rounded,
    collapse: Icons.expand_less_rounded,
    chat: Icons.chat_bubble_outline_rounded,
    model: Icons.smart_toy_rounded,
    refresh: Icons.refresh_rounded,
    error: Icons.error_outline_rounded,
  );

  /// Apple SF Symbols style — used by the iOS theme.
  factory FlaiIconData.cupertino() => const FlaiIconData(
    toolCall: CupertinoIcons.wrench,
    thinking: CupertinoIcons.lightbulb,
    citation: CupertinoIcons.quote_bubble,
    image: CupertinoIcons.photo,
    brokenImage: CupertinoIcons.exclamationmark_triangle,
    code: CupertinoIcons.chevron_left_slash_chevron_right,
    copy: CupertinoIcons.doc_on_doc,
    check: CupertinoIcons.check_mark,
    close: CupertinoIcons.xmark,
    send: CupertinoIcons.arrow_up_circle_fill,
    attach: CupertinoIcons.paperclip,
    search: CupertinoIcons.search,
    delete: CupertinoIcons.trash,
    add: CupertinoIcons.plus,
    expand: CupertinoIcons.chevron_down,
    collapse: CupertinoIcons.chevron_up,
    chat: CupertinoIcons.chat_bubble_2,
    model: CupertinoIcons.desktopcomputer,
    refresh: CupertinoIcons.arrow_clockwise,
    error: CupertinoIcons.exclamationmark_circle,
  );

  /// Material Design sharp icons — used by the premium theme.
  factory FlaiIconData.sharp() => const FlaiIconData(
    toolCall: Icons.build_sharp,
    thinking: Icons.psychology_sharp,
    citation: Icons.format_quote_sharp,
    image: Icons.image_sharp,
    brokenImage: Icons.broken_image_sharp,
    code: Icons.code_sharp,
    copy: Icons.content_copy_sharp,
    check: Icons.check_sharp,
    close: Icons.close_sharp,
    send: Icons.send_sharp,
    attach: Icons.attach_file_sharp,
    search: Icons.search_sharp,
    delete: Icons.delete_sharp,
    add: Icons.add_sharp,
    expand: Icons.expand_more_sharp,
    collapse: Icons.expand_less_sharp,
    chat: Icons.chat_bubble_outline_sharp,
    model: Icons.smart_toy_sharp,
    refresh: Icons.refresh_sharp,
    error: Icons.error_outline_sharp,
  );

  FlaiIconData copyWith({
    IconData? toolCall,
    IconData? thinking,
    IconData? citation,
    IconData? image,
    IconData? brokenImage,
    IconData? code,
    IconData? copy,
    IconData? check,
    IconData? close,
    IconData? send,
    IconData? attach,
    IconData? search,
    IconData? delete,
    IconData? add,
    IconData? expand,
    IconData? collapse,
    IconData? chat,
    IconData? model,
    IconData? refresh,
    IconData? error,
  }) {
    return FlaiIconData(
      toolCall: toolCall ?? this.toolCall,
      thinking: thinking ?? this.thinking,
      citation: citation ?? this.citation,
      image: image ?? this.image,
      brokenImage: brokenImage ?? this.brokenImage,
      code: code ?? this.code,
      copy: copy ?? this.copy,
      check: check ?? this.check,
      close: close ?? this.close,
      send: send ?? this.send,
      attach: attach ?? this.attach,
      search: search ?? this.search,
      delete: delete ?? this.delete,
      add: add ?? this.add,
      expand: expand ?? this.expand,
      collapse: collapse ?? this.collapse,
      chat: chat ?? this.chat,
      model: model ?? this.model,
      refresh: refresh ?? this.refresh,
      error: error ?? this.error,
    );
  }
}
