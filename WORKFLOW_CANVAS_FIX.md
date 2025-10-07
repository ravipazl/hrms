# URGENT FIXES for Workflow Canvas Issues

## Issue 1: Nodes Disappearing When Dragging ❌

**Problem:** Nodes go outside canvas bounds and disappear

**Root Cause:** Canvas size is fixed at 2200x1400, but nodes can be dragged beyond these bounds

**Solution:** Clamp node positions to stay within canvas bounds

### Fix in `workflow_canvas.dart`:

Find this section (around line 90):
```dart
void _handlePointerMove(PointerEvent event) {
  if (widget.readonly) return;
  
  setState(() {
    _mousePosition = event.localPosition;
  });

  if (_draggedNodeId != null && _dragStartPosition != null) {
    final distance = (event.localPosition - _dragStartPosition!).distance;
    
    if (distance > _dragThreshold) {
      if (!_dragMode) {
        setState(() {
          _dragMode = true;
        });
      }
      
      final rawX = math.max(0.0, event.localPosition.dx - _dragOffset.dx);
      final rawY = math.max(0.0, event.localPosition.dy - _dragOffset.dy);
      final snappedPos = _snapToGrid(Offset(rawX, rawY));
      
      widget.onNodeDrag(_draggedNodeId!, snappedPos);
    }
  }
}
```

**REPLACE WITH:**
```dart
void _handlePointerMove(PointerEvent event) {
  if (widget.readonly) return;
  
  setState(() {
    _mousePosition = event.localPosition;
  });

  if (_draggedNodeId != null && _dragStartPosition != null) {
    final distance = (event.localPosition - _dragStartPosition!).distance;
    
    if (distance > _dragThreshold) {
      if (!_dragMode) {
        setState(() {
          _dragMode = true;
        });
      }
      
      // ✅ FIX: Clamp position to canvas bounds
      final rawX = event.localPosition.dx - _dragOffset.dx;
      final rawY = event.localPosition.dy - _dragOffset.dy;
      
      // Clamp to canvas bounds (leave margin for node visibility)
      final clampedX = rawX.clamp(0.0, 2200.0 - nodeWidth);
      final clampedY = rawY.clamp(0.0, 1400.0 - nodeHeight);
      
      final snappedPos = _snapToGrid(Offset(clampedX, clampedY));
      
      widget.onNodeDrag(_draggedNodeId!, snappedPos);
    }
  }
}
```

### Also update the onPanUpdate handler (around line 190):

Find:
```dart
onPanUpdate: widget.connectionMode || widget.readonly ? null : (details) {
  if (_draggedNodeId == node.id && _dragStartPosition != null) {
    final distance = (details.globalPosition - _dragStartPosition!).distance;
    
    if (distance > _dragThreshold) {
      if (!_dragMode) {
        setState(() {
          _dragMode = true;
        });
      }
      
      final rawPos = Offset(
        node.position.dx + details.delta.dx,
        node.position.dy + details.delta.dy,
      );
      final snappedPos = _snapToGrid(rawPos);
      
      widget.onNodeDrag(node.id, snappedPos);
    }
  }
},
```

**REPLACE WITH:**
```dart
onPanUpdate: widget.connectionMode || widget.readonly ? null : (details) {
  if (_draggedNodeId == node.id && _dragStartPosition != null) {
    final distance = (details.globalPosition - _dragStartPosition!).distance;
    
    if (distance > _dragThreshold) {
      if (!_dragMode) {
        setState(() {
          _dragMode = true;
        });
      }
      
      // ✅ FIX: Clamp position to canvas bounds
      final rawX = node.position.dx + details.delta.dx;
      final rawY = node.position.dy + details.delta.dy;
      
      final clampedX = rawX.clamp(0.0, 2200.0 - nodeWidth);
      final clampedY = rawY.clamp(0.0, 1400.0 - nodeHeight);
      
      final snappedPos = _snapToGrid(Offset(clampedX, clampedY));
      
      widget.onNodeDrag(node.id, snappedPos);
    }
  }
},
```

---

## Issue 2: Dropdown Overflow Error ❌

**Problem:** Department dropdown text too long for 320px sidebar

**Error:** `A RenderFlex overflowed by 63 pixels on the right`

**Solution:** Wrap dropdown text in Flexible/Expanded widgets

### Fix in `workflow_creation_screen.dart`:

Find the Department dropdown (around line 280):
```dart
DropdownButtonFormField<int>(
  value: provider.template.department,
  decoration: const InputDecoration(
    labelText: 'Department',
    border: OutlineInputBorder(),
    hintText: 'Optional - leave empty for global template',
  ),
  items: [
    const DropdownMenuItem<int>(
      value: null,
      child: Text('-- Global (All Departments) --'),
    ),
    ..._availableDepartments.map((dept) {
      return DropdownMenuItem<int>(
        value: dept.id,
        child: Text(dept.name),
      );
    }).toList(),
  ],
  onChanged: widget.mode == 'view'
      ? null
      : (value) {
          provider.updateTemplateInfo(department: value);
        },
)
```

**REPLACE WITH:**
```dart
DropdownButtonFormField<int>(
  value: provider.template.department,
  isExpanded: true, // ✅ FIX: Allow dropdown to use full width
  decoration: const InputDecoration(
    labelText: 'Department',
    border: OutlineInputBorder(),
    hintText: 'Optional',
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
  items: [
    const DropdownMenuItem<int>(
      value: null,
      child: Text(
        '-- Global --',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    ..._availableDepartments.map((dept) {
      return DropdownMenuItem<int>(
        value: dept.id,
        child: Text(
          dept.name,
          overflow: TextOverflow.ellipsis, // ✅ FIX: Handle long text
          maxLines: 1,
        ),
      );
    }).toList(),
  ],
  onChanged: widget.mode == 'view'
      ? null
      : (value) {
          provider.updateTemplateInfo(department: value);
        },
)
```

### Also fix the Stage dropdown (around line 250):

```dart
DropdownButtonFormField<WorkflowStage>(
  value: provider.selectedStage,
  isExpanded: true, // ✅ ADD THIS
  decoration: const InputDecoration(
    labelText: 'Workflow Stage *',
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
  items: provider.availableStages.map((stage) {
    return DropdownMenuItem(
      value: stage,
      child: Text(
        stage.description,
        overflow: TextOverflow.ellipsis, // ✅ ADD THIS
        maxLines: 1, // ✅ ADD THIS
      ),
    );
  }).toList(),
  // ... rest of code
)
```

---

## Quick Apply Instructions

### Method 1: Manual Edit

1. Open `D:\hrms\lib\widgets\workflow_canvas.dart`
2. Find `_handlePointerMove` function
3. Replace the position calculation with clamped version
4. Find `onPanUpdate` handler  
5. Replace the position calculation with clamped version

6. Open `D:\hrms\lib\screens\workflow_creation_screen.dart`
7. Find both dropdowns (Stage and Department)
8. Add `isExpanded: true` to both
9. Add `overflow: TextOverflow.ellipsis` and `maxLines: 1` to child Text widgets

### Method 2: Complete File Replacement

I can provide complete fixed files if needed.

---

## Test After Fix

1. **Drag Test:**
   - Drag node to right edge → should stop at canvas boundary
   - Drag node to bottom edge → should stop at canvas boundary
   - Node should NEVER disappear

2. **Dropdown Test:**
   - Open Stage dropdown → should not overflow
   - Open Department dropdown → should not overflow
   - Long text should show ellipsis (