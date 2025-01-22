import 'package:flutter/material.dart';
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  final List<T> items;
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> with TickerProviderStateMixin {
  late final List<T> _items = widget.items.toList();
  int? _draggedIndex;
  double? _dragPosition;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _dragPosition = event.localPosition.dx;
        });
      },
      onExit: (event) {
        setState(() {
          _dragPosition = null;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return DragTarget<int>(
                  onWillAccept: (data) => data != null,
                  onAccept: (draggedIndex) {
                    setState(() {
                      final draggedItem = _items[draggedIndex];
                      _items.removeAt(draggedIndex);
                      _items.insert(index, draggedItem);
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Draggable<int>(
                      data: index,
                      feedback: Material(
                        color: Colors.transparent,
                        child: widget.builder(item),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.2,
                        child: widget.builder(item),
                      ),
                      onDragStarted: () {
                        setState(() {
                          _draggedIndex = index;
                        });
                      },
                      onDragEnd: (details) {
                        setState(() {
                          _draggedIndex = null;
                        });
                      },
                      child: AnimatedScale(
                        scale: _getScale(index),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutQuart,
                        child: widget.builder(item),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  double _getScale(int index) {
    if (_dragPosition == null || _draggedIndex != null) return 1.0;

    final itemWidth = 60.0; // Approximate width of each item including margin
    final centerPosition = index * itemWidth + itemWidth / 2;
    final distance = (_dragPosition! - centerPosition).abs();

    // Max scale when hovering directly over an icon
    const maxScale = 1.5;
    // Distance at which scaling starts to take effect
    const scaleRadius = 70.0;

    if (distance >= scaleRadius) return 1.0;

    // Calculate scale based on distance from mouse
    return 1.0 + (maxScale - 1.0) * (1 - (distance / scaleRadius));
  }
}
