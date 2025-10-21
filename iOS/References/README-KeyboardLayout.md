# Keyboard Layout JSON Structure Guide

## Overview

This guide explains how to create JSON layout files for custom iOS keyboards. Each keyboard requires separate JSON files for different states (unshifted, shifted, symbols, etc.).

## File Naming Convention

```
{language}_{state}.json

Examples:
- mn_qwerty.json          (unshifted)
- mn_qwerty_shift.json    (shifted)
- mn_tamil99.json         (unshifted)
- mn_tamil99_shift.json   (shifted)
```

## Root Structure

```json
{
  "keyWidth": "8.3%",
  "horizontalGap": "1.7%",
  "rows": [...]
}
```

**Properties:**
- `keyWidth`: Default width for all keys (percentage of keyboard width)
- `horizontalGap`: Default horizontal spacing between keys
- `rows`: Array of keyboard rows (typically 4 rows for phone layouts)

## Row Structure

Each row defines a horizontal line of keys:

```json
{
  "verticalGap": "6.5%",
  "keyHeight": "18%",
  "rowId": "centered",
  "keys": [...]
}
```

**Properties:**
- `verticalGap`: Space above this row
- `keyHeight`: Height of keys in this row (percentage)
- `rowId`: Special identifier for layout behavior (optional)
- `keys`: Array of key definitions

### Row ID Options

- `null`: Standard row, keys sized proportionally
- `"centered"`: Keys maintain fixed width, row is centered with equal padding on sides
- `"fixed-width"`: Keys maintain fixed width, extra space distributed after first key and before last key
- `"phone"`: Bottom row for phone layout
- `"pad"`: Bottom row for iPad layout

## Key Structure

### Standard Character Key

```json
{
  "unichar": "a",
  "keyLabel": "a",
  "keyWidth": "8.3%",
  "popupCharacters": "\\u0101\\u00e0\\u00e1"
}
```

**Properties:**
- `unichar`: Character to insert when pressed
- `keyLabel`: Text displayed on key
- `keyWidth`: Width override (optional, uses row default if omitted)
- `popupCharacters`: Long-press popup options (optional, Unicode escapes)

### Special Key Codes

Special keys use `codes` instead of `unichar`:

```json
{
  "codes": "-1",
  "keyLabel": "",
  "keyWidth": "11.875%",
  "horizontalGap": "0.9375%",
  "isModifier": true,
  "isShifted": false
}
```

**Common Special Codes:**
- `-1`: Shift key
- `-2`: Mode switch (123/ABC)
- `-5`: Delete/backspace key
- `-6`: Globe key (keyboard switcher)
- `32`: Space bar
- `10`: Return/enter key

**Special Key Properties:**
- `codes`: Numeric code (string format)
- `keyLabel`: Display text (empty for icon-based keys like shift/delete)
- `isModifier`: Mark as modifier key for styling (optional)
- `isShifted`: For shift key state (optional)
- `isRepeatable`: Enable key repeat (delete, space)

### Layout Properties

**Positioning:**
- `horizontalGap`: Space to left of this key (overrides default)
- `keyEdgeFlags`: "left" or "right" for row edge keys

**Example Edge Key:**
```json
{
  "unichar": "q",
  "keyLabel": "q",
  "horizontalGap": "0.85%",
  "keyEdgeFlags": "left"
}
```

## Complete Row Examples

### Row 1: Standard Row (10 keys)

```json
{
  "verticalGap": "5%",
  "keyHeight": "18%",
  "rowId": null,
  "keys": [
    {
      "unichar": "q",
      "keyLabel": "q",
      "horizontalGap": "0.85%",
      "keyEdgeFlags": "left"
    },
    {
      "unichar": "w",
      "keyLabel": "w"
    },
    // ... more keys ...
    {
      "unichar": "p",
      "keyLabel": "p",
      "keyEdgeFlags": "right"
    }
  ]
}
```

### Row 2: Centered Row (9 keys)

```json
{
  "verticalGap": "6.5%",
  "keyHeight": "18%",
  "rowId": "centered",
  "keys": [
    {
      "unichar": "a",
      "keyLabel": "a",
      "keyWidth": "8.3%",
      "horizontalGap": "5.85%",
      "keyEdgeFlags": "left"
    },
    {
      "unichar": "s",
      "keyLabel": "s",
      "keyWidth": "8.3%"
    },
    // ... all keys need explicit keyWidth: "8.3%" ...
    {
      "unichar": "l",
      "keyLabel": "l",
      "keyWidth": "8.3%",
      "keyEdgeFlags": "right"
    }
  ]
}
```

**Important:** All keys in centered rows must have explicit `keyWidth` matching the default.

### Row 3: Fixed-Width Row with Shift/Delete

```json
{
  "verticalGap": "6.5%",
  "keyHeight": "18%",
  "rowId": "fixed-width",
  "keys": [
    {
      "codes": "-1",
      "keyLabel": "",
      "keyWidth": "11.875%",
      "horizontalGap": "0.9375%",
      "keyEdgeFlags": "left",
      "isModifier": true,
      "isShifted": false
    },
    {
      "unichar": "z",
      "keyLabel": "z",
      "keyWidth": "8.3%"
    },
    // ... more letter keys with explicit keyWidth: "8.3%" ...
    {
      "codes": "-5",
      "keyLabel": "",
      "keyWidth": "11.875%",
      "keyEdgeFlags": "right",
      "isModifier": true,
      "isRepeatable": true
    }
  ]
}
```

**Important:** All letter keys between shift and delete need explicit `keyWidth: "8.3%"`.

### Row 4: Bottom Row (Phone Layout)

```json
{
  "verticalGap": "6.5%",
  "keyHeight": "18%",
  "rowId": "phone",
  "keys": [
    {
      "codes": "-2",
      "keyLabel": "123",
      "keyWidth": "11.875%",
      "horizontalGap": "0.9375%",
      "isModifier": true
    },
    {
      "codes": "-6",
      "keyLabel": "⌘",
      "keyWidth": "11.875%",
      "isModifier": true
    },
    {
      "codes": "32",
      "keyLabel": "#space",
      "keyWidth": "45.6235%",
      "isRepeatable": true
    },
    {
      "codes": "10",
      "keyLabel": "#return",
      "keyWidth": "23.6515%",
      "keyEdgeFlags": "right",
      "isModifier": true
    }
  ]
}
```

## Width Calculations

Key widths should sum to approximately 100% per row:

```
Row 1 (10 keys): 10 × 8.3% + 9 × 1.7% (gaps) = 98.3%
Row 2 (9 keys):  9 × 8.3% + padding = 74.7% + ~25% padding = ~100%
Row 3: 11.875% + 7 × 8.3% + 11.875% + spacers = ~100%
Row 4: 11.875% + 11.875% + 45.6235% + 23.6515% = ~93% + margins
```

## Unicode Characters

For non-ASCII characters, use Unicode escapes:

```json
"unichar": "\\u0bb0",      // Tamil ர
"keyLabel": "ர",
"popupCharacters": "\\u0bb0\\u0bb1"
```

**Format:** `\\u` followed by 4-digit hex code

## Special Key Labels

System-rendered keys use empty `keyLabel`:
- Shift: `"keyLabel": ""`
- Delete: `"keyLabel": ""`
- Globe: `"keyLabel": "⌘"` (placeholder, will use SF Symbol)

Text-based special keys:
- Mode: `"keyLabel": "123"` or `"keyLabel": "ABC"`
- Space: `"keyLabel": "#space"`
- Return: `"keyLabel": "#return"`

## Tips for Creating Layouts

1. **Start with a template**: Copy an existing working layout (like mn_qwerty.json)
2. **Consistent widths**: Use same width values across similar layouts
3. **Test both states**: Create both unshifted and shifted versions
4. **Row IDs matter**: Use correct rowId for each row type
5. **Explicit widths for special rows**: Always specify keyWidth for centered and fixed-width rows
6. **Globe key required**: Include `-6` globe key in all layouts for keyboard switching
7. **Maintain proportions**: Keep key width ratios consistent with standard layouts

## Common Mistakes

❌ **Missing explicit widths in centered rows:**
```json
{"unichar": "a", "keyLabel": "a"}  // Wrong - no keyWidth
```

✓ **Correct:**
```json
{"unichar": "a", "keyLabel": "a", "keyWidth": "8.3%"}
```

❌ **Wrong rowId for centered rows:**
```json
"rowId": null  // Will stretch keys
```

✓ **Correct:**
```json
"rowId": "centered"
```

❌ **Missing globe key:**
Bottom row without `-6` code prevents keyboard switching.

✓ **Include globe key in every layout's bottom row**
