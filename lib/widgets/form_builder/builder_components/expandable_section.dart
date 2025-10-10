import 'package:flutter/material.dart';

/// Expandable section widget for organizing field settings
class ExpandableSection extends StatefulWidget {
  final String title;
  final IconData? icon;
  final bool initiallyExpanded;
  final Widget child;
  final Color? headerColor;

  const ExpandableSection({
    super.key,
    required this.title,
    this.icon,
    this.initiallyExpanded = true,
    required this.child,
    this.headerColor,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: widget.headerColor ?? Colors.grey[50],
              child: Row(
                children: <Widget>[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isExpanded ? Colors.blue[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: widget.child,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
