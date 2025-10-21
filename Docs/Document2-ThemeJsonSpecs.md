# Theme JSON Schema Specification

**Project:** Sangam Keyboards - Cross-Platform Theme System  
**Version:** 1.0  
**Date:** October 17, 2025  
**Schema Version:** 1.0  
**Document:** 2 of 5

## Table of Contents
1. Overview
2. File Format
3. Root Object Schema
4. Theme Variant Schema
5. Color Specifications
6. Typography Specifications
7. Spacing & Layout
8. Platform Compatibility
9. Validation Rules
10. Example Themes
11. Migration & Versioning

---

## 1. Overview

### Purpose
This document defines the complete JSON schema for Sangam Keyboard themes. The schema is designed to be platform-agnostic, with clear documentation of which properties are supported on each platform.

### Design Principles
- **Human Readable:** JSON format, descriptive property names
- **Platform Agnostic:** Core properties work on both iOS and Android
- **Extensible:** Platform-specific properties prefixed with underscore
- **Versioned:** Schema version included for future compatibility
- **Self-Contained:** All theme data in a single file

### File Naming Convention
- **Format:** `{language}_{theme_id}.json`
- **Examples:** 
  - `en_neon_dreams.json`
  - `ta_classic_blue.json`
  - `ml_dark_elegant.json`
- **Shared themes:** `th_{theme_id}.json` (language-agnostic)

---

## 2. File Format

### Basic Structure
```json
{
  "schemaVersion": "1.0",
  "id": "unique_theme_identifier",
  "name": "Display Name",
  "version": "1.0",
  "author": "Creator Name",
  "description": "Theme description",
  "tags": ["tag1", "tag2"],
  "light": { ... },
  "dark": { ... }
}
```

### File Constraints
- **Encoding:** UTF-8
- **Size Limit:** 50 KB maximum
- **Line Endings:** LF or CRLF (normalized on server)
- **Compression:** None (JSON is human-readable)
- **Validation:** Must pass JSON schema validation

---

## 3. Root Object Schema

### Required Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `schemaVersion` | string | Schema version for compatibility | `"1.0"` |
| `id` | string | Unique theme identifier (a-z, 0-9, underscore) | `"neon_dreams"` |
| `name` | string | Display name (3-50 chars) | `"Neon Dreams"` |
| `version` | string | Theme version (semver) | `"1.0"` or `"1.2.3"` |
| `author` | string | Creator's name (2-50 chars) | `"Murasu Systems"` |
| `light` | object | Light mode theme variant | See Theme Variant Schema |
| `dark` | object | Dark mode theme variant | See Theme Variant Schema |

### Optional Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `description` | string | Theme description (10-200 chars) | `"A vibrant neon-inspired keyboard theme"` |
| `tags` | array[string] | Search tags (max 10) | `["neon", "colorful", "modern"]` |
| `createdAt` | string | ISO 8601 timestamp | `"2025-10-17T10:30:00Z"` |
| `updatedAt` | string | ISO 8601 timestamp | `"2025-10-17T10:30:00Z"` |
| `authorId` | string | Server-assigned author ID | `"user_12345"` |
| `downloadCount` | number | Download count (server-managed) | `1523` |
| `previewImageUrl` | string | URL to preview image | `"https://cdn.example.com/preview.png"` |

### Metadata Validation Rules

```javascript
{
  "id": {
    "pattern": "^[a-z0-9_]+$",
    "minLength": 3,
    "maxLength": 50
  },
  "name": {
    "minLength": 3,
    "maxLength": 50,
    "required": true
  },
  "author": {
    "minLength": 2,
    "maxLength": 50,
    "required": true
  },
  "description": {
    "minLength": 10,
    "maxLength": 200,
    "required": false
  },
  "version": {
    "pattern": "^\\d+\\.\\d+(\\.\\d+)?$",
    "required": true
  },
  "tags": {
    "type": "array",
    "maxItems": 10,
    "items": {
      "type": "string",
      "maxLength": 20
    }
  }
}
```

---

## 4. Theme Variant Schema

Each theme must define both `light` and `dark` variants. The structure is identical for both.

### Complete Theme Variant Object

```json
{
  "keyboardBackground": "#f8f9fa",
  "_keyboardBackgroundGradient": ["#f8f9fa", "#e9ecef"],
  "_keyboardBackgroundGradientDirection": "vertical",
  
  "regularKeyBackground": "#ffffff",
  "regularKeyText": "#212529",
  "regularKeyBorder": "#dee2e6",
  "regularKeyBorderWidth": 1.0,
  "_regularKeyShadowColor": "#00000026",
  "_regularKeyShadowOffset": [0, 1],
  "_regularKeyShadowBlur": 2.0,
  "regularKeyCornerRadius": 6.0,
  
  "modifierKeyBackground": "#e9ecef",
  "modifierKeyText": "#495057",
  "modifierKeyBorder": "#ced4da",
  "modifierKeyBorderWidth": 1.0,
  "_modifierKeyShadowColor": "#00000026",
  "_modifierKeyShadowOffset": [0, 1],
  "_modifierKeyShadowBlur": 2.0,
  "modifierKeyCornerRadius": 6.0,
  
  "pressedKeyBackground": "#6c757d",
  "pressedKeyText": "#ffffff",
  "_pressedKeyScale": 0.95,
  "_pressedKeyShadowColor": "#00000050",
  "_pressedKeyShadowOffset": [0, 2],
  "_pressedKeyShadowBlur": 4.0,
  
  "_previewBackground": "#343a40",
  "_previewText": "#ffffff",
  "_previewBorder": "#6c757d",
  "_previewBorderWidth": 2.0,
  "_previewCornerRadius": 8.0,
  "_previewShadowColor": "#00000066",
  "_previewShadowOffset": [0, 4],
  "_previewShadowBlur": 8.0,
  
  "_popupBackground": "#ffffff",
  "_popupBorder": "#dee2e6",
  "_popupBorderWidth": 1.0,
  "_popupCornerRadius": 8.0,
  "_popupShadowColor": "#00000050",
  "_popupShadowOffset": [0, 4],
  "_popupShadowBlur": 12.0,
  "_popupKeyText": "#212529",
  "_popupKeyBackground": "#ffffff",
  "_popupKeySelectedBackground": "#007bff",
  "_popupKeySelectedText": "#ffffff",
  "_popupKeyCornerRadius": 4.0,
  
  "candidateBarBackground": "#ffffff",
  "candidateBarBorder": "#dee2e6",
  "candidateBarBorderWidth": 0.5,
  "candidateText": "#212529",
  "candidateAnnotationText": "#6c757d",
  "candidateSelectedBackground": "#007bff",
  "candidateSelectedText": "#ffffff",
  "candidateSelectedBorder": "#0056b3",
  "candidateSelectedBorderWidth": 1.0,
  "candidateSeparator": "#dee2e6",
  
  "keyFontSize": 18.0,
  "keyFontWeight": "regular",
  "modifierKeyFontSize": 16.0,
  "modifierKeyFontWeight": "medium",
  "_previewFontSize": 32.0,
  "_previewFontWeight": "regular",
  "_popupKeyFontSize": 28.0,
  "_popupKeyFontWeight": "regular",
  "candidateFontSize": 18.0,
  "candidateFontWeight": "regular",
  "candidateAnnotationFontSize": 14.0,
  
  "_customFontName": null,
  
  "keySpacing": 3.0,
  "rowSpacing": 6.0
}
```

---

## 5. Color Specifications

### Color Format

All colors must be specified as hex strings in one of two formats:

| Format | Pattern | Example | Description |
|--------|---------|---------|-------------|
| RGB | `#RRGGBB` | `#ff0000` | Red=FF, Green=00, Blue=00 |
| RGBA | `#AARRGGBB` | `#80ff0000` | Alpha=80, Red=FF, Green=00, Blue=00 |

### Color Properties Reference

#### Keyboard Background
| Property | Platforms | Required | Description |
|----------|-----------|----------|-------------|
| `keyboardBackground` | iOS, Android | Yes | Solid background color |
| `_keyboardBackgroundGradient` | iOS only | No | Array of 2+ colors for gradient |
| `_keyboardBackgroundGradientDirection` | iOS only | No | `"vertical"`, `"horizontal"`, `"diagonalTopLeftToBottomRight"`, `"diagonalTopRightToBottomLeft"` |

**Gradient Example:**
```json
{
  "keyboardBackground": "#f8f9fa",
  "_keyboardBackgroundGradient": ["#f8f9fa", "#e9ecef", "#dee2e6"],
  "_keyboardBackgroundGradientDirection": "vertical"
}
```

#### Regular Keys (Letter Keys)
| Property | Platforms | Required | Default |
|----------|-----------|----------|---------|
| `regularKeyBackground` | iOS, Android | Yes | n/a |
| `regularKeyText` | iOS, Android | Yes | n/a |
| `regularKeyBorder` | iOS, Android | Yes | n/a |
| `_regularKeyShadowColor` | iOS only | No | `null` |

#### Modifier Keys (Shift, Delete, Return, etc.)
| Property | Platforms | Required | Default |
|----------|-----------|----------|---------|
| `modifierKeyBackground` | iOS, Android | Yes | n/a |
| `modifierKeyText` | iOS, Android | Yes | n/a |
| `modifierKeyBorder` | iOS, Android | Yes | n/a |
| `_modifierKeyShadowColor` | iOS only | No | `null` |

#### Pressed State
| Property | Platforms | Required | Default |
|----------|-----------|----------|---------|
| `pressedKeyBackground` | iOS, Android | Yes | n/a |
| `pressedKeyText` | iOS, Android | Yes | n/a |
| `_pressedKeyShadowColor` | iOS only | No | `null` |

#### Key Preview Popup (iOS Only)
| Property | Platforms | Required | Default |
|----------|-----------|----------|---------|
| `_previewBackground` | iOS only | No | Derived from key colors |
| `_previewText` | iOS only | No | Derived from key colors |
| `_previewBorder` | iOS only | No | Derived from key colors |
| `_previewShadowColor` | iOS only | No | `null` |

#### Long Press Popup (iOS Only)
| Property | Platforms | Required | Default |
|----------|-----------|----------|---------|
| `_popupBackground` | iOS only | No | Derived from key colors |
| `_popupBorder` | iOS only | No | Derived from key colors |
| `_popupKeyText` | iOS only | No | Derived from regular key |
| `_popupKeyBackground` | iOS only | No | Derived from regular key |
| `_popupKeySelectedBackground` | iOS only | No | Derived from pressed key |
| `_popupKeySelectedText` | iOS only | No | Derived from pressed key |
| `_popupShadowColor` | iOS only | No | `null` |

#### Candidate Bar (Suggestions)
| Property | Platforms | Required | Default |
|----------|-----------|----------|---------|
| `candidateBarBackground` | iOS, Android | No | System default |
| `candidateBarBorder` | iOS, Android | No | Transparent |
| `candidateText` | iOS, Android | No | System default |
| `candidateAnnotationText` | iOS, Android | No | Muted version of candidateText |
| `candidateSelectedBackground` | iOS, Android | No | System accent |
| `candidateSelectedText` | iOS, Android | No | Contrast to selected bg |
| `candidateSelectedBorder` | iOS, Android | No | Transparent |
| `candidateSeparator` | iOS, Android | No | Subtle divider |

### Color Accessibility Guidelines

**Contrast Ratios (WCAG 2.1):**
- Normal text: Minimum 4.5:1
- Large text (18pt+): Minimum 3:1
- UI components: Minimum 3:1

**Validation:**
```javascript
function validateContrast(textColor, backgroundColor) {
  const ratio = calculateContrastRatio(textColor, backgroundColor);
  return ratio >= 4.5; // For normal text
}
```

**Recommended Color Combinations:**
```json
{
  "goodContrast": {
    "regularKeyBackground": "#ffffff",
    "regularKeyText": "#000000"
  },
  "poorContrast": {
    "regularKeyBackground": "#eeeeee",
    "regularKeyText": "#cccccc"
  }
}
```

---

## 6. Typography Specifications

### Font Size Properties

| Property | Platforms | Type | Range | Default | Description |
|----------|-----------|------|-------|---------|-------------|
| `keyFontSize` | iOS, Android | float | 10.0-30.0 | 18.0 | Letter key font size (pt/sp) |
| `modifierKeyFontSize` | iOS, Android | float | 8.0-28.0 | 16.0 | Modifier key font size |
| `candidateFontSize` | iOS, Android | float | 10.0-24.0 | 18.0 | Candidate bar text size |
| `candidateAnnotationFontSize` | iOS, Android | float | 8.0-20.0 | 14.0 | Candidate annotation size |
| `_previewFontSize` | iOS only | float | 20.0-48.0 | 32.0 | Key preview popup size |
| `_popupKeyFontSize` | iOS only | float | 18.0-36.0 | 28.0 | Long press popup size |

### Font Weight Properties

| Property | Platforms | Type | Values | Default |
|----------|-----------|------|--------|---------|
| `keyFontWeight` | iOS, Android | string | See table below | `"regular"` |
| `modifierKeyFontWeight` | iOS, Android | string | See table below | `"medium"` |
| `candidateFontWeight` | iOS, Android | string | See table below | `"regular"` |
| `_previewFontWeight` | iOS only | string | See table below | `"regular"` |
| `_popupKeyFontWeight` | iOS only | string | See table below | `"regular"` |

### Font Weight Values

| Value | iOS UIFont.Weight | Android Typeface | Numeric Weight |
|-------|-------------------|------------------|----------------|
| `"ultraLight"` | `.ultraLight` | N/A (use light) | 100 |
| `"thin"` | `.thin` | N/A (use light) | 200 |
| `"light"` | `.light` | `LIGHT` | 300 |
| `"regular"` | `.regular` | `NORMAL` | 400 |
| `"medium"` | `.medium` | `MEDIUM` | 500 |
| `"semibold"` | `.semibold` | `SEMIBOLD` | 600 |
| `"bold"` | `.bold` | `BOLD` | 700 |
| `"heavy"` | `.heavy` | `BOLD` | 800 |
| `"black"` | `.black` | `BOLD` | 900 |

**Note:** Android has limited font weight support. Weights map as follows:
- 100-300 → `Typeface.LIGHT` (if available, else NORMAL)
- 400 → `Typeface.NORMAL`
- 500-600 → `Typeface.MEDIUM` (API 28+, else NORMAL)
- 700-900 → `Typeface.BOLD`

### Custom Font Support

| Property | Platforms | Type | Description |
|----------|-----------|------|-------------|
| `_customFontName` | iOS only (future) | string or null | Custom font name from app bundle |

**Example:**
```json
{
  "_customFontName": "TamilSangam-Regular",
  "keyFontSize": 18.0,
  "keyFontWeight": "regular"
}
```

**Notes:**
- Custom fonts must be included in app bundle
- Font name must match exactly (case-sensitive)
- Fallback to system font if not found
- Android support planned for Phase 2

---

## 7. Spacing & Layout

### Border Width Properties

| Property | Platforms | Type | Range | Default | Description |
|----------|-----------|------|-------|---------|-------------|
| `regularKeyBorderWidth` | iOS, Android | float | 0.0-5.0 | 1.0 | Regular key border thickness |
| `modifierKeyBorderWidth` | iOS, Android | float | 0.0-5.0 | 1.0 | Modifier key border thickness |
| `candidateBarBorderWidth` | iOS, Android | float | 0.0-3.0 | 0.5 | Candidate bar border thickness |
| `candidateSelectedBorderWidth` | iOS, Android | float | 0.0-3.0 | 1.0 | Selected candidate border |
| `_previewBorderWidth` | iOS only | float | 0.0-5.0 | 2.0 | Preview popup border |
| `_popupBorderWidth` | iOS only | float | 0.0-5.0 | 1.0 | Long press popup border |

### Corner Radius Properties

| Property | Platforms | Type | Range | Default | Description |
|----------|-----------|------|-------|---------|-------------|
| `regularKeyCornerRadius` | iOS, Android | float | 0.0-20.0 | 6.0 | Regular key corner rounding |
| `modifierKeyCornerRadius` | iOS, Android | float | 0.0-20.0 | 6.0 | Modifier key corner rounding |
| `_previewCornerRadius` | iOS only | float | 0.0-20.0 | 8.0 | Preview popup corner rounding |
| `_popupCornerRadius` | iOS only | float | 0.0-20.0 | 8.0 | Long press popup corner rounding |
| `_popupKeyCornerRadius` | iOS only | float | 0.0-20.0 | 4.0 | Keys within popup corner rounding |

### Key Spacing Properties

| Property | Platforms | Type | Range | Default | Description |
|----------|-----------|------|-------|---------|-------------|
| `keySpacing` | iOS, Android | float | 1.0-10.0 | 3.0 | Horizontal gap between keys (pt/dp) |
| `rowSpacing` | iOS, Android | float | 2.0-15.0 | 6.0 | Vertical gap between rows (pt/dp) |

**Visual Example:**
```
┌────┐  ┌────┐  ┌────┐  ← keySpacing (3.0)
│ Q  │  │ W  │  │ E  │
└────┘  └────┘  └────┘
  ↕ rowSpacing (6.0)
┌────┐  ┌────┐  ┌────┐
│ A  │  │ S  │  │ D  │
└────┘  └────┘  └────┘
```

---

## 8. Platform Compatibility

### Property Support Matrix

| Category | Property Prefix | iOS | Android | Notes |
|----------|----------------|-----|---------|-------|
| Core Colors | (no prefix) | ✅ | ✅ | Full support |
| Gradients | `_keyboard...Gradient` | ✅ | ❌ | iOS only in Phase 1 |
| Shadows | `_...Shadow...` | ✅ | ⚠️ | Android uses elevation |
| Preview Popup | `_preview...` | ✅ | ❌ | Different system on Android |
| Long Press Popup | `_popup...` | ✅ | ❌ | Different system on Android |
| Pressed State | `_pressedKeyScale` | ✅ | ⚠️ | Android approximates |
| Typography | (no prefix) | ✅ | ✅ | Full support |
| Spacing | (no prefix) | ✅ | ✅ | Full support |
| Custom Fonts | `_customFontName` | ⚠️ | ❌ | Planned feature |

**Legend:**
- ✅ Fully supported
- ⚠️ Partially supported or different implementation
- ❌ Not supported

### Platform-Specific Properties

Properties prefixed with `_` are platform-specific or optional:

**iOS-Only Properties:**
```json
{
  "_keyboardBackgroundGradient": [...],
  "_keyboardBackgroundGradientDirection": "...",
  "_regularKeyShadowColor": "...",
  "_regularKeyShadowOffset": [...],
  "_regularKeyShadowBlur": 0.0,
  "_modifierKeyShadowColor": "...",
  "_modifierKeyShadowOffset": [...],
  "_modifierKeyShadowBlur": 0.0,
  "_pressedKeyScale": 0.95,
  "_pressedKeyShadowColor": "...",
  "_pressedKeyShadowOffset": [...],
  "_pressedKeyShadowBlur": 0.0,
  "_previewBackground": "...",
  "_previewText": "...",
  "_previewBorder": "...",
  "_previewBorderWidth": 0.0,
  "_previewCornerRadius": 0.0,
  "_previewShadowColor": "...",
  "_previewShadowOffset": [...],
  "_previewShadowBlur": 0.0,
  "_previewFontSize": 0.0,
  "_previewFontWeight": "...",
  "_popupBackground": "...",
  "_popupBorder": "...",
  "_popupBorderWidth": 0.0,
  "_popupCornerRadius": 0.0,
  "_popupShadowColor": "...",
  "_popupShadowOffset": [...],
  "_popupShadowBlur": 0.0,
  "_popupKeyText": "...",
  "_popupKeyBackground": "...",
  "_popupKeySelectedBackground": "...",
  "_popupKeySelectedText": "...",
  "_popupKeyCornerRadius": 0.0,
  "_popupKeyFontSize": 0.0,
  "_popupKeyFontWeight": "...",
  "_customFontName": null
}
```

### Cross-Platform Theme Best Practices

**For Theme Creators:**
1. Always define core properties (no underscore prefix)
2. Test theme on both platforms if possible
3. Use conservative values for maximum compatibility
4. Avoid relying on iOS-only features for core appearance
5. Provide good contrast regardless of gradient support

**For Developers:**
1. Parse all properties, ignore unknown ones
2. Validate required properties exist
3. Provide sensible defaults for optional properties
4. Log warnings for unsupported properties (don't error)
5. Gracefully degrade iOS-specific features on Android

---

## 9. Validation Rules

### Schema Validation (JSON Schema Draft 7)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["schemaVersion", "id", "name", "version", "author", "light", "dark"],
  "properties": {
    "schemaVersion": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$"
    },
    "id": {
      "type": "string",
      "pattern": "^[a-z0-9_]+$",
      "minLength": 3,
      "maxLength": 50
    },
    "name": {
      "type": "string",
      "minLength": 3,
      "maxLength": 50
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+(\\.\\d+)?$"
    },
    "author": {
      "type": "string",
      "minLength": 2,
      "maxLength": 50
    },
    "description": {
      "type": "string",
      "minLength": 10,
      "maxLength": 200
    },
    "tags": {
      "type": "array",
      "maxItems": 10,
      "items": {
        "type": "string",
        "maxLength": 20
      }
    },
    "light": {
      "$ref": "#/definitions/themeVariant"
    },
    "dark": {
      "$ref": "#/definitions/themeVariant"
    }
  },
  "definitions": {
    "themeVariant": {
      "type": "object",
      "required": [
        "keyboardBackground",
        "regularKeyBackground",
        "regularKeyText",
        "regularKeyBorder",
        "regularKeyBorderWidth",
        "regularKeyCornerRadius",
        "modifierKeyBackground",
        "modifierKeyText",
        "modifierKeyBorder",
        "modifierKeyBorderWidth",
        "modifierKeyCornerRadius",
        "pressedKeyBackground",
        "pressedKeyText",
        "keyFontSize",
        "keyFontWeight",
        "modifierKeyFontSize",
        "modifierKeyFontWeight",
        "keySpacing",
        "rowSpacing"
      ],
      "properties": {
        "keyboardBackground": {
          "$ref": "#/definitions/color"
        },
        "regularKeyBackground": {
          "$ref": "#/definitions/color"
        },
        "regularKeyText": {
          "$ref": "#/definitions/color"
        },
        "keyFontSize": {
          "type": "number",
          "minimum": 10.0,
          "maximum": 30.0
        },
        "keyFontWeight": {
          "$ref": "#/definitions/fontWeight"
        },
        "keySpacing": {
          "type": "number",
          "minimum": 1.0,
          "maximum": 10.0
        },
        "rowSpacing": {
          "type": "number",
          "minimum": 2.0,
          "maximum": 15.0
        }
      }
    },
    "color": {
      "type": "string",
      "pattern": "^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"
    },
    "fontWeight": {
      "type": "string",
      "enum": [
        "ultraLight",
        "thin",
        "light",
        "regular",
        "medium",
        "semibold",
        "bold",
        "heavy",
        "black"
      ]
    }
  }
}
```

### Client-Side Validation (Pseudocode)

```javascript
function validateTheme(themeJson) {
  const errors = [];
  
  // 1. Validate required root properties
  if (!themeJson.id || !themeJson.name || !themeJson.author) {
    errors.push("Missing required metadata");
  }
  
  // 2. Validate ID format
  if (!/^[a-z0-9_]+$/.test(themeJson.id)) {
    errors.push("Invalid theme ID format");
  }
  
  // 3. Validate version format
  if (!/^\d+\.\d+(\.\d+)?$/.test(themeJson.version)) {
    errors.push("Invalid version format");
  }
  
  // 4. Validate light and dark variants exist
  if (!themeJson.light || !themeJson.dark) {
    errors.push("Both light and dark variants required");
  }
  
  // 5. Validate each variant
  ['light', 'dark'].forEach(variant => {
    const v = themeJson[variant];
    
    // Check required color properties
    const requiredColors = [
      'keyboardBackground',
      'regularKeyBackground',
      'regularKeyText',
      'regularKeyBorder',
      'modifierKeyBackground',
      'modifierKeyText',
      'modifierKeyBorder',
      'pressedKeyBackground',
      'pressedKeyText'
    ];
    
    requiredColors.forEach(prop => {
      if (!v[prop]) {
        errors.push(`Missing ${variant}.${prop}`);
      } else if (!isValidColor(v[prop])) {
        errors.push(`Invalid color format for ${variant}.${prop}`);
      }
    });
    
    // Check numeric ranges
    if (v.keyFontSize < 10 || v.keyFontSize > 30) {
      errors.push(`${variant}.keyFontSize out of range`);
    }
    
    if (v.keySpacing < 1 || v.keySpacing > 10) {
      errors.push(`${variant}.keySpacing out of range`);
    }
    
    // Check contrast ratios
    const ratio = calculateContrastRatio(v.regularKeyText, v.regularKeyBackground);
    if (ratio < 4.5) {
      errors.push(`${variant}: Insufficient contrast between text and background`);
    }
  });
  
  // 6. Check file size
  const jsonString = JSON.stringify(themeJson);
  if (jsonString.length > 50 * 1024) {
    errors.push("Theme file exceeds 50KB limit");
  }
  
  return {
    valid: errors.length === 0,
    errors: errors
  };
}

function isValidColor(color) {
  return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(color);
}

function calculateContrastRatio(color1, color2) {
  // Implementation of WCAG contrast ratio calculation
  // Returns value between 1 and 21
}
```

### Server-Side Validation

Additional checks performed on the server:

1. **Profanity Filter:** Check name and description
2. **Duplicate Detection:** Check if theme ID already exists
3. **Author Verification:** Ensure author matches authenticated user
4. **Malicious Content:** Scan for script injection attempts
5. **Rate Limiting:** Max 10 uploads per hour per user

---

## 10. Example Themes

### Minimal Valid Theme

```json
{
  "schemaVersion": "1.0",
  "id": "simple_light",
  "name": "Simple Light",
  "version": "1.0",
  "author": "Example Author",
  "light": {
    "keyboardBackground": "#ffffff",
    "regularKeyBackground": "#f0f0f0",
    "regularKeyText": "#000000",
    "regularKeyBorder": "#cccccc",
    "regularKeyBorderWidth": 1.0,
    "regularKeyCornerRadius": 5.0,
    "modifierKeyBackground": "#e0e0e0",
    "modifierKeyText": "#000000",
    "modifierKeyBorder": "#bbbbbb",
    "modifierKeyBorderWidth": 1.0,
    "modifierKeyCornerRadius": 5.0,
    "pressedKeyBackground": "#cccccc",
    "pressedKeyText": "#000000",
    "keyFontSize": 18.0,
    "keyFontWeight": "regular",
    "modifierKeyFontSize": 16.0,
    "modifierKeyFontWeight": "medium",
    "keySpacing": 3.0,
    "rowSpacing": 6.0
  },
  "dark": {
    "keyboardBackground": "#000000",
    "regularKeyBackground": "#2a2a2a",
    "regularKeyText": "#ffffff",
    "regularKeyBorder": "#444444",
    "regularKeyBorderWidth": 1.0,
    "regularKeyCornerRadius": 5.0,
    "modifierKeyBackground": "#3a3a3a",
    "modifierKeyText": "#ffffff",
    "modifierKeyBorder": "#555555",
    "modifierKeyBorderWidth": 1.0,
    "modifierKeyCornerRadius": 5.0,
    "pressedKeyBackground": "#555555",
    "pressedKeyText": "#ffffff",
    "keyFontSize": 18.0,
    "keyFontWeight": "regular",
    "modifierKeyFontSize": 16.0,
    "modifierKeyFontWeight": "medium",
    "keySpacing": 3.0,
    "rowSpacing": 6.0
  }
}
```

### Complete Theme with All Properties

(See `th_neon_dreams.json` provided earlier in the conversation - includes all optional iOS-specific properties)

### High Contrast Theme (Accessibility)

```json
{
  "schemaVersion": "1.0",
  "id": "high_contrast",
  "name": "High Contrast",
  "version": "1.0",
  "author": "Accessibility Team",
  "description": "Maximum contrast theme for better readability",
  "tags": ["accessibility", "high-contrast", "readable"],
  "light": {
    "keyboardBackground": "#ffffff",
    "regularKeyBackground": "#ffffff",
    "regularKeyText": "#000000",
    "regularKeyBorder": "#000000",
    "regularKeyBorderWidth": 2.0,
    "regularKeyCornerRadius": 4.0,
    "modifierKeyBackground": "#000000",
    "modifierKeyText": "#ffffff",
    "modifierKeyBorder": "#000000",
    "modifierKeyBorderWidth": 2.0,
    "modifierKeyCornerRadius": 4.0,
    "pressedKeyBackground": "#000000",
    "pressedKeyText": "#ffffff",
    "keyFontSize": 20.0,
    "keyFontWeight": "bold",
    "modifierKeyFontSize": 18.0,
    "modifierKeyFontWeight": "bold",
    "keySpacing": 4.0,
    "rowSpacing": 8.0
  },
  "dark": {
    "keyboardBackground": "#000000",
    "regularKeyBackground": "#000000",
    "regularKeyText": "#ffffff",
    "regularKeyBorder": "#ffffff",
    "regularKeyBorderWidth": 2.0,
    "regularKeyCornerRadius": 4.0,
    "modifierKeyBackground": "#ffffff",
    "modifierKeyText": "#000000",
    "modifierKeyBorder": "#ffffff",
    "modifierKeyBorderWidth": 2.0,
    "modifierKeyCornerRadius": 4.0,
    "pressedKeyBackground": "#ffffff",
    "pressedKeyText": "#000000",
    "keyFontSize": 20.0,
    "keyFontWeight": "bold",
    "modifierKeyFontSize": 18.0,
    "modifierKeyFontWeight": "bold",
    "keySpacing": 4.0,
    "rowSpacing": 8.0
  }
}
```

---

## 11. Migration & Versioning

### Schema Versioning Strategy

**Current Version:** 1.0

**Version Format:** `MAJOR.MINOR`
- **MAJOR:** Breaking changes, incompatible with previous versions
- **MINOR:** Backward-compatible additions

### Future Version Compatibility

When schema is updated, apps should:

1. **Check schema version** in theme file
2. **Support multiple versions** simultaneously
3. **Migrate old themes** to new format if possible
4. **Warn users** if theme is too old/new

**Example Version Check:**
```javascript
function loadTheme(themeJson) {
  const schemaVersion = themeJson.schemaVersion || "1.0";
  
  switch(schemaVersion) {
    case "1.0":
      return parseV1Theme(themeJson);
    case "2.0":
      return parseV2Theme(themeJson);
    default:
      console.warn(`Unknown schema version: ${schemaVersion}`);
      return parseV1Theme(themeJson); // Attempt fallback
  }
}
```

### Planned Future Additions (Schema 2.0)

Potential additions without breaking compatibility:

- **Animation properties:** Key press animations, transition effects
- **Sound properties:** Custom key press sounds per theme
- **Haptic properties:** Custom haptic feedback patterns
- **Accessibility properties:** Screen reader hints, labels
- **Layout variations:** Different key sizes, keyboard layouts
- **Custom icons:** Replace system icons with theme-specific ones
- **Particle effects:** Confetti, sparkles on key press

### Deprecation Policy

When properties are deprecated:

1. **Mark as deprecated** in documentation (add `_deprecated_` prefix)
2. **Continue support** for at least 2 schema versions
3. **Provide migration guide** for theme creators
4. **Auto-migrate** where possible in theme editor

**Example:**
```json
{
  "_deprecated_oldProperty": "value",
  "newProperty": "value"
}
```

---

## 12. Testing Themes

### Validation Checklist

Before uploading a theme, verify:

- [ ] JSON is valid (no syntax errors)
- [ ] All required properties present
- [ ] All colors in valid hex format
- [ ] Numeric values within valid ranges
- [ ] Light and dark variants defined
- [ ] Contrast ratios meet WCAG guidelines
- [ ] Theme name and description filled
- [ ] Author name correct
- [ ] File size under 50KB
- [ ] Tested on both light and dark system modes
- [ ] Tested with different text (English, Tamil, Malayalam, etc.)

### Testing Tools

**Online JSON Validator:**
- https://jsonlint.com/

**Contrast Checker:**
- https://webaim.org/resources/contrastchecker/

**Theme Preview:**
- Use iOS/Android app theme editor with live preview
- Test all keyboard states (normal, pressed, shifted)
- Test candidate bar with suggestions
- Test long press popups (iOS)

### Common Validation Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Invalid JSON syntax | Missing comma, bracket, quote | Use JSON validator |
| Invalid color format | Wrong hex format | Use `#RRGGBB` or `#AARRGGBB` |
| Missing required property | Incomplete theme variant | Add missing properties |
| Poor contrast | Text/background too similar | Adjust colors for 4.5:1 ratio |
| Font size out of range | Value too small/large | Keep within specified ranges |
| File too large | Too many properties/comments | Remove comments, simplify |

---

## Appendix A: Quick Reference

### Required Properties (Minimum)

```json
{
  "schemaVersion": "1.0",
  "id": "theme_id",
  "name": "Theme Name",
  "version": "1.0",
  "author": "Author Name",
  "light": {
    "keyboardBackground": "#......",
    "regularKeyBackground": "#......",
    "regularKeyText": "#......",
    "regularKeyBorder": "#......",
    "regularKeyBorderWidth": 1.0,
    "regularKeyCornerRadius": 6.0,
    "modifierKeyBackground": "#......",
    "modifierKeyText": "#......",
    "modifierKeyBorder": "#......",
    "modifierKeyBorderWidth": 1.0,
    "modifierKeyCornerRadius": 6.0,
    "pressedKeyBackground": "#......",
    "pressedKeyText": "#......",
    "keyFontSize": 18.0,
    "keyFontWeight": "regular",
    "modifierKeyFontSize": 16.0,
    "modifierKeyFontWeight": "medium",
    "keySpacing": 3.0,
    "rowSpacing": 6.0
  },
  "dark": { /* same as light */ }
}
```

### Color Property Index

**Both Platforms:**
- `keyboardBackground`
- `regularKeyBackground`, `regularKeyText`, `regularKeyBorder`
- `modifierKeyBackground`, `modifierKeyText`, `modifierKeyBorder`
- `pressedKeyBackground`, `pressedKeyText`
- `candidateBarBackground`, `candidateBarBorder`
- `candidateText`, `candidateAnnotationText`
- `candidateSelectedBackground`, `candidateSelectedText`, `candidateSelectedBorder`
- `candidateSeparator`

**iOS Only:**
- `_keyboardBackgroundGradient` (array)
- `_regularKeyShadowColor`, `_modifierKeyShadowColor`, `_pressedKeyShadowColor`
- `_previewBackground`, `_previewText`, `_previewBorder`, `_previewShadowColor`
- `_popupBackground`, `_popupBorder`, `_popupKeyText`, `_popupKeyBackground`
- `_popupKeySelectedBackground`, `_popupKeySelectedText`, `_popupShadowColor`

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 17, 2025 | Documentation Team | Initial schema specification |

---

**End of Document 2: Theme JSON Schema Specification**

---

This is document 2 of 5. Should I proceed with document 3 (iOS Theme Editor Specification)?