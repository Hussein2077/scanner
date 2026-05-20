import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: InlineEditor());
  }
}

/// ================= MODEL =================

class EditorItem {
  final String type; // "text" | "tag"
  final String value;
  EditorItem(this.type, this.value);

  Map<String, dynamic> toJson() => {"type": type, "value": value};
}

/// ================= TAG COLOR =================

Color tagColor(String value) {
  final colors = [
    const Color(0xFF2DA44E),
    const Color(0xFF0969DA),
    const Color(0xFF8250DF),
    const Color(0xFFCF222E),
    const Color(0xFFBF8700),
    const Color(0xFF1B7C83),
  ];
  return colors[value.hashCode.abs() % colors.length];
}

Color tagFg(Color bg) =>
    bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

/// ================= INLINE TAG CHIP =================

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const TagChip({super.key, required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final bg = tagColor(label);
    final fg = tagFg(bg);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 11, color: fg),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ================= EDITOR =================

class InlineEditor extends StatefulWidget {
  const InlineEditor({super.key});

  @override
  State<InlineEditor> createState() => _InlineEditorState();
}

class _InlineEditorState extends State<InlineEditor> {
  final List<EditorItem> items = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Commit any pending typed text, then insert the tag
  void addTag(String value) {
    final pending = _textController.text.trim();
    setState(() {
      if (pending.isNotEmpty) {
        items.add(EditorItem("text", pending));
        _textController.clear();
      }
      items.add(EditorItem("tag", value));
    });
    _focusNode.requestFocus();
  }

  /// Commit typed text on submit/enter
  void commitText(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    setState(() {
      items.add(EditorItem("text", text));
      _textController.clear();
    });
  }

  /// Backspace on empty input removes the last item
  void handleBackspace() {
    if (_textController.text.isEmpty && items.isNotEmpty) {
      setState(() => items.removeLast());
    }
  }

  void removeItem(int index) {
    setState(() => items.removeAt(index));
  }

  List<Map<String, dynamic>> toJson() => items.map((e) => e.toJson()).toList();

  Widget _buildItem(int index, EditorItem item) {
    if (item.type == "tag") {
      return TagChip(
        key: ValueKey('tag_$index'),
        label: item.value,
        onRemove: () => removeItem(index),
      );
    }
    // plain text node
    return Padding(
      key: ValueKey('text_$index'),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Text(
        item.value,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _draggableChip(String label) {
    final bg = tagColor(label);
    final fg = tagFg(bg);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Draggable<String>(
      data: label,
      feedback: Material(color: Colors.transparent, child: pill),
      childWhenDragging: Opacity(opacity: 0.3, child: pill),
      child: pill,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text("🏷️ Inline Tag Editor"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Input Field",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            /// ===== DROP ZONE =====
            DragTarget<String>(
              onAccept: addTag,
              builder: (context, candidateData, __) {
                return GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? const Color(0xFFDDF4FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? const Color(0xFF0969DA)
                            : const Color(0xFFD0D7DE),
                        width: candidateData.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Render committed items
                        ...items.asMap().entries.map(
                              (e) => _buildItem(e.key, e.value),
                        ),

                        // Inline text input at the end
                        IntrinsicWidth(
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.backspace) {
                                handleBackspace();
                              }
                            },
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              onSubmitted: commitText,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: items.isEmpty
                                    ? "Type or drag a tag…"
                                    : null,
                                hintStyle:
                                TextStyle(color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              "Available Labels",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _draggableChip("bug"),
                _draggableChip("feature"),
                _draggableChip("urgent"),
                _draggableChip("design"),
                _draggableChip("backend"),
                _draggableChip("docs"),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => debugPrint(toJson().toString()),
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text("Print JSON"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DA44E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}