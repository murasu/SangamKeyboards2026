# Android Theme Implementation Guide

**Project:** Sangam Keyboards - Cross-Platform Theme System  
**Version:** 1.0  
**Date:** October 17, 2025  
**Platform:** Android 7.0+ (API 24+)  
**Approach:** GradientDrawable-based (Minimal Refactoring)  
**Document:** 5 of 5

## Table of Contents
1. Overview
2. Implementation Strategy
3. Theme Configuration Class
4. JSON Parser Implementation
5. Drawable Factory
6. KeyboardView Integration
7. Theme Application Flow
8. Storage & Persistence
9. Theme Editor (Android)
10. Theme Store (Android)
11. Migration from Existing Code
12. Testing Strategy
13. Performance Optimization
14. Troubleshooting Guide

---

## 1. Overview

### Purpose
This guide provides a detailed implementation plan for adding dynamic theme support to the Android keyboard using the existing Latin IME codebase. The approach minimizes code changes by leveraging `GradientDrawable` to generate key backgrounds programmatically from JSON theme files.

### Implementation Philosophy
- **Preserve Existing Architecture:** Keep keyboard input handling, touch detection, and gesture support unchanged
- **Minimal Refactoring:** Replace only the drawable generation logic
- **90% Feature Parity:** Support most theme properties from iOS, excluding gradients initially
- **Low Risk:** Incremental implementation with fallback to defaults

### What Will Be Supported

✅ **Fully Supported:**
- Solid background colors
- Key colors (regular, modifier, pressed states)
- Text colors
- Border colors and widths
- Corner radius
- Font sizes and weights
- Spacing (key gaps, row spacing)
- Candidate bar styling

⚠️ **Partially Supported:**
- Text shadows (using `Paint.setShadowLayer()`)
- Elevation (Material Design shadow instead of custom shadows)

❌ **Not Initially Supported (Phase 2):**
- Keyboard background gradients
- Key shadow colors/offsets (will use elevation)
- Key preview popup customization (uses system defaults)
- Long press popup customization (uses system defaults)
- Pressed key scale animation

### Timeline Estimate
- **Phase 1 (Core Implementation):** 1-2 weeks
- **Phase 2 (Theme Editor):** 1 week
- **Phase 3 (Theme Store Integration):** 3-4 days
- **Phase 4 (Testing & Polish):** 3-4 days
- **Total:** ~3-4 weeks

---

## 2. Implementation Strategy

### High-Level Approach

```
┌─────────────────────────────────────────┐
│          JSON Theme File                │
│   (Same format as iOS, 90% compatible) │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       ThemeJsonParser.java              │
│   Parse JSON → ThemeConfig object       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│    KeyboardThemeConfig.java             │
│   Java object with all theme properties │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   KeyboardThemeDrawableFactory.java     │
│   Generate GradientDrawable from theme  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       KeyboardView.java                 │
│   Apply drawables & theme to keyboard   │
└─────────────────────────────────────────┘
```

### File Structure

```
app/src/main/java/com/sangam/
├── theme/
│   ├── KeyboardThemeConfig.java          // Theme data model
│   ├── ThemeVariant.java                 // Light/dark variant
│   ├── ThemeJsonParser.java              // JSON parsing
│   ├── KeyboardThemeDrawableFactory.java // Drawable generation
│   ├── ThemeStorage.java                 // Save/load themes
│   └── ThemeManager.java                 // Apply themes to keyboard
│
├── keyboard/
│   ├── KeyboardView.java                 // Modified to use themes
│   └── MainKeyboardView.java             // Modified for theme support
│
└── settings/
    ├── ThemeEditorActivity.java          // Theme creation/editing
    ├── ThemeStoreActivity.java           // Browse/download themes
    └── ThemeListActivity.java            // User's themes list
```

### Dependencies

Add to `build.gradle`:
```gradle
dependencies {
    // JSON parsing (if not already present)
    implementation 'com.google.code.gson:gson:2.10.1'
    
    // Material Design for elevation shadows
    implementation 'com.google.android.material:material:1.10.0'
    
    // Existing dependencies...
}
```

---

## 3. Theme Configuration Class

### KeyboardThemeConfig.java

```java
package com.sangam.theme;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Main theme configuration containing both light and dark variants.
 * Maps directly to the JSON theme file structure.
 */
public class KeyboardThemeConfig {
    @NonNull private String id;
    @NonNull private String name;
    @NonNull private String version;
    @NonNull private String author;
    @Nullable private String description;
    @Nullable private String[] tags;
    @NonNull private ThemeVariant light;
    @NonNull private ThemeVariant dark;
    
    // Metadata (managed by server)
    @Nullable private String authorId;
    @Nullable private Integer downloadCount;
    @Nullable private String createdAt;
    @Nullable private String updatedAt;
    
    public KeyboardThemeConfig(
            @NonNull String id,
            @NonNull String name,
            @NonNull String version,
            @NonNull String author,
            @NonNull ThemeVariant light,
            @NonNull ThemeVariant dark) {
        this.id = id;
        this.name = name;
        this.version = version;
        this.author = author;
        this.light = light;
        this.dark = dark;
    }
    
    /**
     * Get the appropriate theme variant based on system dark mode.
     */
    @NonNull
    public ThemeVariant getCurrentVariant(boolean isDarkMode) {
        return isDarkMode ? dark : light;
    }
    
    // Getters and setters
    @NonNull public String getId() { return id; }
    @NonNull public String getName() { return name; }
    @NonNull public String getVersion() { return version; }
    @NonNull public String getAuthor() { return author; }
    @Nullable public String getDescription() { return description; }
    @Nullable public String[] getTags() { return tags; }
    @NonNull public ThemeVariant getLight() { return light; }
    @NonNull public ThemeVariant getDark() { return dark; }
    
    public void setDescription(@Nullable String description) {
        this.description = description;
    }
    
    public void setTags(@Nullable String[] tags) {
        this.tags = tags;
    }
    
    @Override
    public String toString() {
        return "ThemeConfig{" +
                "id='" + id + '\'' +
                ", name='" + name + '\'' +
                ", version='" + version + '\'' +
                '}';
    }
}
```

### ThemeVariant.java

```java
package com.sangam.theme;

import android.graphics.Color;
import android.graphics.Typeface;
import androidx.annotation.ColorInt;
import androidx.annotation.NonNull;

/**
 * Theme variant (light or dark mode).
 * Contains all visual properties for keyboard appearance.
 */
public class ThemeVariant {
    
    // Keyboard background
    @ColorInt private int keyboardBackground;
    
    // Regular keys (letter keys)
    @ColorInt private int regularKeyBackground;
    @ColorInt private int regularKeyText;
    @ColorInt private int regularKeyBorder;
    private float regularKeyBorderWidth;
    private float regularKeyCornerRadius;
    
    // Modifier keys (Shift, Delete, Return, etc.)
    @ColorInt private int modifierKeyBackground;
    @ColorInt private int modifierKeyText;
    @ColorInt private int modifierKeyBorder;
    private float modifierKeyBorderWidth;
    private float modifierKeyCornerRadius;
    
    // Pressed state
    @ColorInt private int pressedKeyBackground;
    @ColorInt private int pressedKeyText;
    
    // Candidate bar (suggestions)
    @ColorInt private int candidateBarBackground;
    @ColorInt private int candidateBarBorder;
    private float candidateBarBorderWidth;
    @ColorInt private int candidateText;
    @ColorInt private int candidateAnnotationText;
    @ColorInt private int candidateSelectedBackground;
    @ColorInt private int candidateSelectedText;
    @ColorInt private int candidateSelectedBorder;
    private float candidateSelectedBorderWidth;
    @ColorInt private int candidateSeparator;
    
    // Typography
    private float keyFontSize;
    @NonNull private FontWeight keyFontWeight;
    private float modifierKeyFontSize;
    @NonNull private FontWeight modifierKeyFontWeight;
    private float candidateFontSize;
    @NonNull private FontWeight candidateFontWeight;
    private float candidateAnnotationFontSize;
    
    // Spacing
    private float keySpacing;
    private float rowSpacing;
    
    /**
     * Font weight enum matching the JSON schema.
     */
    public enum FontWeight {
        LIGHT(Typeface.NORMAL),      // Android doesn't have ultra-light/thin
        REGULAR(Typeface.NORMAL),
        MEDIUM(Typeface.NORMAL),      // API 28+ has MEDIUM, fallback to NORMAL
        SEMIBOLD(Typeface.BOLD),
        BOLD(Typeface.BOLD),
        BLACK(Typeface.BOLD);         // Android doesn't have black weight
        
        private final int typefaceStyle;
        
        FontWeight(int typefaceStyle) {
            this.typefaceStyle = typefaceStyle;
        }
        
        public int getTypefaceStyle() {
            return typefaceStyle;
        }
        
        public static FontWeight fromString(String weight) {
            if (weight == null) return REGULAR;
            
            switch (weight.toLowerCase()) {
                case "ultralight":
                case "thin":
                case "light":
                    return LIGHT;
                case "regular":
                    return REGULAR;
                case "medium":
                    return MEDIUM;
                case "semibold":
                    return SEMIBOLD;
                case "bold":
                    return BOLD;
                case "heavy":
                case "black":
                    return BLACK;
                default:
                    return REGULAR;
            }
        }
    }
    
    // Constructor with all required fields
    public ThemeVariant(
            @ColorInt int keyboardBackground,
            @ColorInt int regularKeyBackground,
            @ColorInt int regularKeyText,
            @ColorInt int regularKeyBorder,
            float regularKeyBorderWidth,
            float regularKeyCornerRadius,
            @ColorInt int modifierKeyBackground,
            @ColorInt int modifierKeyText,
            @ColorInt int modifierKeyBorder,
            float modifierKeyBorderWidth,
            float modifierKeyCornerRadius,
            @ColorInt int pressedKeyBackground,
            @ColorInt int pressedKeyText,
            float keyFontSize,
            @NonNull FontWeight keyFontWeight,
            float modifierKeyFontSize,
            @NonNull FontWeight modifierKeyFontWeight,
            float keySpacing,
            float rowSpacing) {
        
        this.keyboardBackground = keyboardBackground;
        this.regularKeyBackground = regularKeyBackground;
        this.regularKeyText = regularKeyText;
        this.regularKeyBorder = regularKeyBorder;
        this.regularKeyBorderWidth = regularKeyBorderWidth;
        this.regularKeyCornerRadius = regularKeyCornerRadius;
        this.modifierKeyBackground = modifierKeyBackground;
        this.modifierKeyText = modifierKeyText;
        this.modifierKeyBorder = modifierKeyBorder;
        this.modifierKeyBorderWidth = modifierKeyBorderWidth;
        this.modifierKeyCornerRadius = modifierKeyCornerRadius;
        this.pressedKeyBackground = pressedKeyBackground;
        this.pressedKeyText = pressedKeyText;
        this.keyFontSize = keyFontSize;
        this.keyFontWeight = keyFontWeight;
        this.modifierKeyFontSize = modifierKeyFontSize;
        this.modifierKeyFontWeight = modifierKeyFontWeight;
        this.keySpacing = keySpacing;
        this.rowSpacing = rowSpacing;
        
        // Set defaults for optional candidate bar properties
        this.candidateBarBackground = keyboardBackground;
        this.candidateBarBorder = Color.TRANSPARENT;
        this.candidateBarBorderWidth = 0f;
        this.candidateText = regularKeyText;
        this.candidateAnnotationText = adjustAlpha(regularKeyText, 0.6f);
        this.candidateSelectedBackground = pressedKeyBackground;
        this.candidateSelectedText = pressedKeyText;
        this.candidateSelectedBorder = Color.TRANSPARENT;
        this.candidateSelectedBorderWidth = 0f;
        this.candidateSeparator = adjustAlpha(regularKeyBorder, 0.3f);
        this.candidateFontSize = keyFontSize;
        this.candidateFontWeight = FontWeight.REGULAR;
        this.candidateAnnotationFontSize = keyFontSize * 0.8f;
    }
    
    /**
     * Helper to adjust alpha channel of a color.
     */
    private static int adjustAlpha(@ColorInt int color, float factor) {
        int alpha = Math.round(Color.alpha(color) * factor);
        int red = Color.red(color);
        int green = Color.green(color);
        int blue = Color.blue(color);
        return Color.argb(alpha, red, green, blue);
    }
    
    // Getters for all properties
    @ColorInt public int getKeyboardBackground() { return keyboardBackground; }
    @ColorInt public int getRegularKeyBackground() { return regularKeyBackground; }
    @ColorInt public int getRegularKeyText() { return regularKeyText; }
    @ColorInt public int getRegularKeyBorder() { return regularKeyBorder; }
    public float getRegularKeyBorderWidth() { return regularKeyBorderWidth; }
    public float getRegularKeyCornerRadius() { return regularKeyCornerRadius; }
    
    @ColorInt public int getModifierKeyBackground() { return modifierKeyBackground; }
    @ColorInt public int getModifierKeyText() { return modifierKeyText; }
    @ColorInt public int getModifierKeyBorder() { return modifierKeyBorder; }
    public float getModifierKeyBorderWidth() { return modifierKeyBorderWidth; }
    public float getModifierKeyCornerRadius() { return modifierKeyCornerRadius; }
    
    @ColorInt public int getPressedKeyBackground() { return pressedKeyBackground; }
    @ColorInt public int getPressedKeyText() { return pressedKeyText; }
    
    @ColorInt public int getCandidateBarBackground() { return candidateBarBackground; }
    @ColorInt public int getCandidateBarBorder() { return candidateBarBorder; }
    public float getCandidateBarBorderWidth() { return candidateBarBorderWidth; }
    @ColorInt public int getCandidateText() { return candidateText; }
    @ColorInt public int getCandidateAnnotationText() { return candidateAnnotationText; }
    @ColorInt public int getCandidateSelectedBackground() { return candidateSelectedBackground; }
    @ColorInt public int getCandidateSelectedText() { return candidateSelectedText; }
    @ColorInt public int getCandidateSelectedBorder() { return candidateSelectedBorder; }
    public float getCandidateSelectedBorderWidth() { return candidateSelectedBorderWidth; }
    @ColorInt public int getCandidateSeparator() { return candidateSeparator; }
    
    public float getKeyFontSize() { return keyFontSize; }
    @NonNull public FontWeight getKeyFontWeight() { return keyFontWeight; }
    public float getModifierKeyFontSize() { return modifierKeyFontSize; }
    @NonNull public FontWeight getModifierKeyFontWeight() { return modifierKeyFontWeight; }
    public float getCandidateFontSize() { return candidateFontSize; }
    @NonNull public FontWeight getCandidateFontWeight() { return candidateFontWeight; }
    public float getCandidateAnnotationFontSize() { return candidateAnnotationFontSize; }
    
    public float getKeySpacing() { return keySpacing; }
    public float getRowSpacing() { return rowSpacing; }
    
    // Setters for candidate bar (optional properties)
    public void setCandidateBarBackground(@ColorInt int candidateBarBackground) {
        this.candidateBarBackground = candidateBarBackground;
    }
    
    public void setCandidateBarBorder(@ColorInt int candidateBarBorder) {
        this.candidateBarBorder = candidateBarBorder;
    }
    
    public void setCandidateBarBorderWidth(float candidateBarBorderWidth) {
        this.candidateBarBorderWidth = candidateBarBorderWidth;
    }
    
    public void setCandidateText(@ColorInt int candidateText) {
        this.candidateText = candidateText;
    }
    
    public void setCandidateAnnotationText(@ColorInt int candidateAnnotationText) {
        this.candidateAnnotationText = candidateAnnotationText;
    }
    
    public void setCandidateSelectedBackground(@ColorInt int candidateSelectedBackground) {
        this.candidateSelectedBackground = candidateSelectedBackground;
    }
    
    public void setCandidateSelectedText(@ColorInt int candidateSelectedText) {
        this.candidateSelectedText = candidateSelectedText;
    }
    
    public void setCandidateSelectedBorder(@ColorInt int candidateSelectedBorder) {
        this.candidateSelectedBorder = candidateSelectedBorder;
    }
    
    public void setCandidateSelectedBorderWidth(float candidateSelectedBorderWidth) {
        this.candidateSelectedBorderWidth = candidateSelectedBorderWidth;
    }
    
    public void setCandidateSeparator(@ColorInt int candidateSeparator) {
        this.candidateSeparator = candidateSeparator;
    }
    
    public void setCandidateFontSize(float candidateFontSize) {
        this.candidateFontSize = candidateFontSize;
    }
    
    public void setCandidateFontWeight(@NonNull FontWeight candidateFontWeight) {
        this.candidateFontWeight = candidateFontWeight;
    }
    
    public void setCandidateAnnotationFontSize(float candidateAnnotationFontSize) {
        this.candidateAnnotationFontSize = candidateAnnotationFontSize;
    }
}
```

---

## 4. JSON Parser Implementation

### ThemeJsonParser.java

```java
package com.sangam.theme;

import android.graphics.Color;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Parses JSON theme files into KeyboardThemeConfig objects.
 * Handles both complete themes and validates required fields.
 */
public class ThemeJsonParser {
    private static final String TAG = "ThemeJsonParser";
    
    /**
     * Parse a JSON string into a KeyboardThemeConfig.
     * 
     * @param jsonString The JSON theme file content
     * @return KeyboardThemeConfig object or null if parsing fails
     */
    @Nullable
    public static KeyboardThemeConfig parseTheme(@NonNull String jsonString) {
        try {
            JsonObject root = JsonParser.parseString(jsonString).getAsJsonObject();
            
            // Parse root metadata
            String id = getRequiredString(root, "id");
            String name = getRequiredString(root, "name");
            String version = getRequiredString(root, "version");
            String author = getRequiredString(root, "author");
            
            if (id == null || name == null || version == null || author == null) {
                Log.e(TAG, "Missing required metadata fields");
                return null;
            }
            
            // Parse light variant
            JsonObject lightJson = root.getAsJsonObject("light");
            if (lightJson == null) {
                Log.e(TAG, "Missing light theme variant");
                return null;
            }
            ThemeVariant lightVariant = parseThemeVariant(lightJson);
            if (lightVariant == null) {
                return null;
            }
            
            // Parse dark variant
            JsonObject darkJson = root.getAsJsonObject("dark");
            if (darkJson == null) {
                Log.e(TAG, "Missing dark theme variant");
                return null;
            }
            ThemeVariant darkVariant = parseThemeVariant(darkJson);
            if (darkVariant == null) {
                return null;
            }
            
            // Create theme config
            KeyboardThemeConfig config = new KeyboardThemeConfig(
                    id, name, version, author, lightVariant, darkVariant
            );
            
            // Parse optional fields
            if (root.has("description")) {
                config.setDescription(root.get("description").getAsString());
            }
            
            if (root.has("tags") && root.get("tags").isJsonArray()) {
                String[] tags = new Gson().fromJson(root.get("tags"), String[].class);
                config.setTags(tags);
            }
            
            return config;
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to parse theme JSON", e);
            return null;
        }
    }
    
    /**
     * Parse a theme variant (light or dark).
     */
    @Nullable
    private static ThemeVariant parseThemeVariant(@NonNull JsonObject json) {
        try {
            // Parse required color fields
            int keyboardBackground = parseColor(json, "keyboardBackground");
            int regularKeyBackground = parseColor(json, "regularKeyBackground");
            int regularKeyText = parseColor(json, "regularKeyText");
            int regularKeyBorder = parseColor(json, "regularKeyBorder");
            float regularKeyBorderWidth = getRequiredFloat(json, "regularKeyBorderWidth");
            float regularKeyCornerRadius = getRequiredFloat(json, "regularKeyCornerRadius");
            
            int modifierKeyBackground = parseColor(json, "modifierKeyBackground");
            int modifierKeyText = parseColor(json, "modifierKeyText");
            int modifierKeyBorder = parseColor(json, "modifierKeyBorder");
            float modifierKeyBorderWidth = getRequiredFloat(json, "modifierKeyBorderWidth");
            float modifierKeyCornerRadius = getRequiredFloat(json, "modifierKeyCornerRadius");
            
            int pressedKeyBackground = parseColor(json, "pressedKeyBackground");
            int pressedKeyText = parseColor(json, "pressedKeyText");
            
            // Parse typography
            float keyFontSize = getRequiredFloat(json, "keyFontSize");
            String keyFontWeightStr = getRequiredString(json, "keyFontWeight");
            ThemeVariant.FontWeight keyFontWeight = ThemeVariant.FontWeight.fromString(keyFontWeightStr);
            
            float modifierKeyFontSize = getRequiredFloat(json, "modifierKeyFontSize");
            String modifierKeyFontWeightStr = getRequiredString(json, "modifierKeyFontWeight");
            ThemeVariant.FontWeight modifierKeyFontWeight = ThemeVariant.FontWeight.fromString(modifierKeyFontWeightStr);
            
            // Parse spacing
            float keySpacing = getRequiredFloat(json, "keySpacing");
            float rowSpacing = getRequiredFloat(json, "rowSpacing");
            
            // Create variant
            ThemeVariant variant = new ThemeVariant(
                    keyboardBackground,
                    regularKeyBackground,
                    regularKeyText,
                    regularKeyBorder,
                    regularKeyBorderWidth,
                    regularKeyCornerRadius,
                    modifierKeyBackground,
                    modifierKeyText,
                    modifierKeyBorder,
                    modifierKeyBorderWidth,
                    modifierKeyCornerRadius,
                    pressedKeyBackground,
                    pressedKeyText,
                    keyFontSize,
                    keyFontWeight,
                    modifierKeyFontSize,
                    modifierKeyFontWeight,
                    keySpacing,
                    rowSpacing
            );
            
            // Parse optional candidate bar properties
            if (json.has("candidateBarBackground")) {
                variant.setCandidateBarBackground(parseColor(json, "candidateBarBackground"));
            }
            if (json.has("candidateBarBorder")) {
                variant.setCandidateBarBorder(parseColor(json, "candidateBarBorder"));
            }
            if (json.has("candidateBarBorderWidth")) {
                variant.setCandidateBarBorderWidth(json.get("candidateBarBorderWidth").getAsFloat());
            }
            if (json.has("candidateText")) {
                variant.setCandidateText(parseColor(json, "candidateText"));
            }
            if (json.has("candidateAnnotationText")) {
                variant.setCandidateAnnotationText(parseColor(json, "candidateAnnotationText"));
            }
            if (json.has("candidateSelectedBackground")) {
                variant.setCandidateSelectedBackground(parseColor(json, "candidateSelectedBackground"));
            }
            if (json.has("candidateSelectedText")) {
                variant.setCandidateSelectedText(parseColor(json, "candidateSelectedText"));
            }
            if (json.has("candidateSelectedBorder")) {
                variant.setCandidateSelectedBorder(parseColor(json, "candidateSelectedBorder"));
            }
            if (json.has("candidateSelectedBorderWidth")) {
                variant.setCandidateSelectedBorderWidth(json.get("candidateSelectedBorderWidth").getAsFloat());
            }
            if (json.has("candidateSeparator")) {
                variant.setCandidateSeparator(parseColor(json, "candidateSeparator"));
            }
            if (json.has("candidateFontSize")) {
                variant.setCandidateFontSize(json.get("candidateFontSize").getAsFloat());
            }
            if (json.has("candidateFontWeight")) {
                String weightStr = json.get("candidateFontWeight").getAsString();
                variant.setCandidateFontWeight(ThemeVariant.FontWeight.fromString(weightStr));
            }
            if (json.has("candidateAnnotationFontSize")) {
                variant.setCandidateAnnotationFontSize(json.get("candidateAnnotationFontSize").getAsFloat());
            }
            
            return variant;
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to parse theme variant", e);
            return null;
        }
    }
    
    /**
     * Parse a hex color string to Android color int.
     * Supports both #RRGGBB and #AARRGGBB formats.
     */
    private static int parseColor(@NonNull JsonObject json, @NonNull String key) {
        if (!json.has(key)) {
            throw new IllegalArgumentException("Missing required color field: " + key);
        }
        
        String hexColor = json.get(key).getAsString();
        
        try {
            return Color.parseColor(hexColor);
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "Invalid color format for " + key + ": " + hexColor);
            throw e;
        }
    }
    
    /**
     * Get a required string field.
     */
    @Nullable
    private static String getRequiredString(@NonNull JsonObject json, @NonNull String key) {
        if (!json.has(key)) {
            Log.e(TAG, "Missing required field: " + key);
            return null;
        }
        return json.get(key).getAsString();
    }
    
    /**
     * Get a required float field.
     */
    private static float getRequiredFloat(@NonNull JsonObject json, @NonNull String key) {
        if (!json.has(key)) {
            throw new IllegalArgumentException("Missing required field: " + key);
        }
        
        JsonElement element = json.get(key);
        
        // Handle both integers and floats
        if (element.isJsonPrimitive()) {
            return element.getAsFloat();
        }
        
        throw new IllegalArgumentException("Invalid numeric value for " + key);
    }
}
```

---

## 5. Drawable Factory

### KeyboardThemeDrawableFactory.java

```java
package com.sangam.theme;

import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;

import androidx.annotation.NonNull;

/**
 * Factory class to create Android Drawables from theme configuration.
 * Uses GradientDrawable to generate key backgrounds programmatically.
 */
public class KeyboardThemeDrawableFactory {
    
    /**
     * Create a drawable for regular (letter) keys.
     */
    @NonNull
    public static Drawable createRegularKeyDrawable(@NonNull ThemeVariant theme) {
        return createKeyDrawable(
                theme.getRegularKeyBackground(),
                theme.getRegularKeyBorder(),
                theme.getRegularKeyBorderWidth(),
                theme.getRegularKeyCornerRadius()
        );
    }
    
    /**
     * Create a drawable for modifier keys (Shift, Delete, Return, etc.).
     */
    @NonNull
    public static Drawable createModifierKeyDrawable(@NonNull ThemeVariant theme) {
        return createKeyDrawable(
                theme.getModifierKeyBackground(),
                theme.getModifierKeyBorder(),
                theme.getModifierKeyBorderWidth(),
                theme.getModifierKeyCornerRadius()
        );
    }
    
    /**
     * Create a drawable for spacebar key.
     * Uses regular key styling by default.
     */
    @NonNull
    public static Drawable createSpacebarDrawable(@NonNull ThemeVariant theme) {
        return createRegularKeyDrawable(theme);
    }
    
    /**
     * Create a state list drawable that handles normal and pressed states.
     */
    @NonNull
    public static StateListDrawable createKeyStateDrawable(
            @NonNull ThemeVariant theme,
            boolean isModifierKey) {
        
        StateListDrawable stateList = new StateListDrawable();
        
        // Pressed state
        Drawable pressedDrawable = createPressedKeyDrawable(theme, isModifierKey);
        stateList.addState(new int[]{android.R.attr.state_pressed}, pressedDrawable);
        
        // Normal state
        Drawable normalDrawable = isModifierKey ?
                createModifierKeyDrawable(theme) :
                createRegularKeyDrawable(theme);
        stateList.addState(new int[]{}, normalDrawable);
        
        return stateList;
    }
    
    /**
     * Create a drawable for pressed key state.
     */
    @NonNull
    private static Drawable createPressedKeyDrawable(
            @NonNull ThemeVariant theme,
            boolean isModifierKey) {
        
        float cornerRadius = isModifierKey ?
                theme.getModifierKeyCornerRadius() :
                theme.getRegularKeyCornerRadius();
        
        return createKeyDrawable(
                theme.getPressedKeyBackground(),
                theme.getPressedKeyBackground(), // Use same color for border
                0f, // No border in pressed state
                cornerRadius
        );
    }
    
    /**
     * Create a basic key drawable with specified properties.
     */
    @NonNull
    private static GradientDrawable createKeyDrawable(
            int backgroundColor,
            int borderColor,
            float borderWidth,
            float cornerRadius) {
        
        GradientDrawable drawable = new GradientDrawable();
        drawable.setShape(GradientDrawable.RECTANGLE);
        drawable.setColor(backgroundColor);
        drawable.setCornerRadius(cornerRadius);
        
        if (borderWidth > 0) {
            drawable.setStroke((int) borderWidth, borderColor);
        }
        
        return drawable;
    }
    
    /**
     * Create a drawable for candidate bar background.
     */
    @NonNull
    public static Drawable createCandidateBarDrawable(@NonNull ThemeVariant theme) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setShape(GradientDrawable.RECTANGLE);
        drawable.setColor(theme.getCandidateBarBackground());
        
        float borderWidth = theme.getCandidateBarBorderWidth();
        if (borderWidth > 0) {
            drawable.setStroke((int) borderWidth, theme.getCandidateBarBorder());
        }
        
        return drawable;
    }
    
    /**
     * Create a drawable for selected candidate background.
     */
    @NonNull
    public static Drawable createSelectedCandidateDrawable(@NonNull ThemeVariant theme) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setShape(GradientDrawable.RECTANGLE);
        drawable.setColor(theme.getCandidateSelectedBackground());
        drawable.setCornerRadius(4f); // Small corner radius for candidates
        
        float borderWidth = theme.getCandidateSelectedBorderWidth();
        if (borderWidth > 0) {
            drawable.setStroke((int) borderWidth, theme.getCandidateSelectedBorder());
        }
        
        return drawable;
    }
}
```

---

## 6. KeyboardView Integration

### Modifications to KeyboardView.java

Add theme support to the existing `KeyboardView` class:

```java
// In KeyboardView.java

package com.android.inputmethod.keyboard;

import com.sangam.theme.KeyboardThemeConfig;
import com.sangam.theme.ThemeVariant;
import com.sangam.theme.KeyboardThemeDrawableFactory;

public class KeyboardView extends View {
    // ... existing code ...
    
    // Add theme-related fields
    private KeyboardThemeConfig mThemeConfig;
    private ThemeVariant mCurrentThemeVariant;
    
    // Theme-generated drawables
    private Drawable mThemedKeyBackground;
    private Drawable mThemedFunctionalKeyBackground;
    private Drawable mThemedSpacebarBackground;
    
    /**
     * Apply a theme to this keyboard view.
     * Generates new drawables and updates the keyboard appearance.
     */
    public void applyTheme(@NonNull KeyboardThemeConfig themeConfig) {
        mThemeConfig = themeConfig;
        
        // Determine if dark mode
        boolean isDarkMode = (getResources().getConfiguration().uiMode 
                & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
        
        mCurrentThemeVariant = themeConfig.getCurrentVariant(isDarkMode);
        
        // Generate drawables from theme
        mThemedKeyBackground = KeyboardThemeDrawableFactory.createKeyStateDrawable(
                mCurrentThemeVariant, false);
        mThemedFunctionalKeyBackground = KeyboardThemeDrawableFactory.createKeyStateDrawable(
                mCurrentThemeVariant, true);
        mThemedSpacebarBackground = KeyboardThemeDrawableFactory.createSpacebarDrawable(
                mCurrentThemeVariant);
        
        // Update keyboard background color
        setBackgroundColor(mCurrentThemeVariant.getKeyboardBackground());
        
        // Update key draw parameters with theme colors
        updateKeyDrawParamsWithTheme();
        
        // Force redraw
        invalidateAllKeys();
    }
    
    /**
     * Update KeyDrawParams with theme typography and colors.
     */
    private void updateKeyDrawParamsWithTheme() {
        if (mCurrentThemeVariant == null) return;
        
        // Update text colors
        mKeyDrawParams.mKeyTextColor = mCurrentThemeVariant.getRegularKeyText();
        mKeyDrawParams.mFunctionalTextColor = mCurrentThemeVariant.getModifierKeyText();
        
        // Update font sizes (convert from pt to px)
        float density = getResources().getDisplayMetrics().density;
        mKeyDrawParams.mLetterSize = mCurrentThemeVariant.getKeyFontSize() * density;
        mKeyDrawParams.mLabelSize = mCurrentThemeVariant.getModifierKeyFontSize() * density;
        
        // Update font weights
        mKeyDrawParams.mTypeface = getTypefaceForWeight(
                mCurrentThemeVariant.getKeyFontWeight());
        mKeyDrawParams.mFunctionalTypeface = getTypefaceForWeight(
                mCurrentThemeVariant.getModifierKeyFontWeight());
    }
    
    /**
     * Get Android Typeface for a given font weight.
     */
    private Typeface getTypefaceForWeight(@NonNull ThemeVariant.FontWeight weight) {
        return Typeface.defaultFromStyle(weight.getTypefaceStyle());
    }
    
    /**
     * Override key background selection to use themed drawables.
     */
    @Override
    protected void onDrawKeyBackground(@NonNull final Key key, @NonNull final Canvas canvas,
            @NonNull final Drawable background) {
        
        // Use themed drawable if available
        Drawable themedBackground = null;
        if (mCurrentThemeVariant != null) {
            if (key.isSpacebar()) {
                themedBackground = mThemedSpacebarBackground;
            } else if (key.isFunctional()) {
                themedBackground = mThemedFunctionalKeyBackground;
            } else {
                themedBackground = mThemedKeyBackground;
            }
        }
        
        // Fall back to original drawable if no theme
        Drawable drawableToUse = (themedBackground != null) ? themedBackground : background;
        
        // Call original draw logic with themed drawable
        super.onDrawKeyBackground(key, canvas, drawableToUse);
    }
    
    /**
     * Update text paint with theme colors when drawing key text.
     */
    @Override
    protected void onDrawKeyTopVisuals(@NonNull final Key key, @NonNull final Canvas canvas,
            @NonNull final Paint paint, @NonNull final KeyDrawParams params) {
        
        if (mCurrentThemeVariant != null) {
            // Set text color based on key type
            int textColor = key.isFunctional() ?
                    mCurrentThemeVariant.getModifierKeyText() :
                    mCurrentThemeVariant.getRegularKeyText();
            paint.setColor(textColor);
            
            // Set font size
            float fontSize = key.isFunctional() ?
                    mCurrentThemeVariant.getModifierKeyFontSize() :
                    mCurrentThemeVariant.getKeyFontSize();
            paint.setTextSize(fontSize * getResources().getDisplayMetrics().density);
            
            // Set font weight
            ThemeVariant.FontWeight weight = key.isFunctional() ?
                    mCurrentThemeVariant.getModifierKeyFontWeight() :
                    mCurrentThemeVariant.getKeyFontWeight();
            paint.setTypeface(getTypefaceForWeight(weight));
        }
        
        // Call original drawing logic
        super.onDrawKeyTopVisuals(key, canvas, paint, params);
    }
    
    /**
     * Apply theme spacing to keyboard layout.
     * Called when keyboard is set or theme changes.
     */
    public void applyThemeSpacing() {
        if (mKeyboard == null || mCurrentThemeVariant == null) return;
        
        // Update keyboard gaps with theme spacing
        float density = getResources().getDisplayMetrics().density;
        mKeyboard.mHorizontalGap = (int) (mCurrentThemeVariant.getKeySpacing() * density);
        mKeyboard.mVerticalGap = (int) (mCurrentThemeVariant.getRowSpacing() * density);
        
        // Request layout to apply spacing changes
        requestLayout();
    }
    
    // ... rest of existing code ...
}
```

---

## 7. Theme Application Flow

### ThemeManager.java

```java
package com.sangam.theme;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.android.inputmethod.keyboard.KeyboardView;
import com.android.inputmethod.keyboard.MainKeyboardView;

/**
 * Manages theme selection, loading, and application to keyboard views.
 * Singleton pattern for app-wide theme management.
 */
public class ThemeManager {
    private static final String TAG = "ThemeManager";
    private static final String PREFS_NAME = "keyboard_themes";
    private static final String PREF_CURRENT_THEME_ID = "current_theme_id";
    private static final String DEFAULT_THEME_ID = "default_light";
    
    private static ThemeManager sInstance;
    
    private final Context mContext;
    private final SharedPreferences mPrefs;
    private final ThemeStorage mStorage;
    
    private KeyboardThemeConfig mCurrentTheme;
    private String mCurrentThemeId;
    
    private ThemeManager(@NonNull Context context) {
        mContext = context.getApplicationContext();
        mPrefs = mContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        mStorage = new ThemeStorage(mContext);
        
        // Load current theme ID from preferences
        mCurrentThemeId = mPrefs.getString(PREF_CURRENT_THEME_ID, DEFAULT_THEME_ID);
        
        // Load the theme
        loadCurrentTheme();
    }
    
    /**
     * Get the singleton instance.
     */
    @NonNull
    public static synchronized ThemeManager getInstance(@NonNull Context context) {
        if (sInstance == null) {
            sInstance = new ThemeManager(context);
        }
        return sInstance;
    }
    
    /**
     * Get the currently active theme.
     */
    @Nullable
    public KeyboardThemeConfig getCurrentTheme() {
        return mCurrentTheme;
    }
    
    /**
     * Set and apply a new theme.
     */
    public void setTheme(@NonNull String themeId) {
        KeyboardThemeConfig theme = mStorage.loadTheme(themeId);
        if (theme == null) {
            Log.e(TAG, "Failed to load theme: " + themeId);
            return;
        }
        
        mCurrentTheme = theme;
        mCurrentThemeId = themeId;
        
        // Save preference
        mPrefs.edit()
                .putString(PREF_CURRENT_THEME_ID, themeId)
                .apply();
        
        Log.i(TAG, "Theme set to: " + theme.getName());
    }
    
    /**
     * Apply the current theme to a keyboard view.
     */
    public void applyThemeToKeyboard(@NonNull KeyboardView keyboardView) {
        if (mCurrentTheme == null) {
            Log.w(TAG, "No theme loaded, using defaults");
            return;
        }
        
        keyboardView.applyTheme(mCurrentTheme);
        keyboardView.applyThemeSpacing();
    }
    
    /**
     * Apply the current theme to a main keyboard view.
     */
    public void applyThemeToKeyboard(@NonNull MainKeyboardView keyboardView) {
        if (mCurrentTheme == null) {
            Log.w(TAG, "No theme loaded, using defaults");
            return;
        }
        
        keyboardView.applyTheme(mCurrentTheme);
        keyboardView.applyThemeSpacing();
    }
    
    /**
     * Load the current theme from storage.
     */
    private void loadCurrentTheme() {
        mCurrentTheme = mStorage.loadTheme(mCurrentThemeId);
        
        if (mCurrentTheme == null) {
            Log.w(TAG, "Failed to load theme " + mCurrentThemeId + ", loading default");
            mCurrentTheme = mStorage.loadDefaultTheme();
            mCurrentThemeId = DEFAULT_THEME_ID;
        }
    }
    
    /**
     * Reload theme (useful after editing or downloading).
     */
    public void reloadTheme(@NonNull String themeId) {
        if (themeId.equals(mCurrentThemeId)) {
            loadCurrentTheme();
        }
    }
    
    /**
     * Get list of available theme IDs.
     */
    @NonNull
    public String[] getAvailableThemeIds() {
        return mStorage.listThemes();
    }
    
    /**
     * Get theme metadata without loading full theme.
     */
    @Nullable
    public KeyboardThemeConfig getThemeMetadata(@NonNull String themeId) {
        return mStorage.loadTheme(themeId);
    }
}
```

---

## 8. Storage & Persistence

### ThemeStorage.java

```java
package com.sangam.theme;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Handles loading and saving theme files.
 * Themes are stored in app's private files directory.
 */
public class ThemeStorage {
    private static final String TAG = "ThemeStorage";
    private static final String THEMES_DIR = "themes";
    private static final String THEME_FILE_EXTENSION = ".json";
    
    private final Context mContext;
    private final File mThemesDirectory;
    
    public ThemeStorage(@NonNull Context context) {
        mContext = context.getApplicationContext();
        mThemesDirectory = new File(mContext.getFilesDir(), THEMES_DIR);
        
        // Create themes directory if it doesn't exist
        if (!mThemesDirectory.exists()) {
            mThemesDirectory.mkdirs();
        }
        
        // Copy bundled default themes on first run
        copyDefaultThemesIfNeeded();
    }
    
    /**
     * Load a theme by ID.
     */
    @Nullable
    public KeyboardThemeConfig loadTheme(@NonNull String themeId) {
        File themeFile = new File(mThemesDirectory, themeId + THEME_FILE_EXTENSION);
        
        if (!themeFile.exists()) {
            Log.w(TAG, "Theme file not found: " + themeId);
            return null;
        }
        
        try {
            String json = readFile(themeFile);
            return ThemeJsonParser.parseTheme(json);
        } catch (IOException e) {
            Log.e(TAG, "Failed to read theme file: " + themeId, e);
            return null;
        }
    }
    
    /**
     * Save a theme.
     */
    public boolean saveTheme(@NonNull KeyboardThemeConfig theme) {
        File themeFile = new File(mThemesDirectory, theme.getId() + THEME_FILE_EXTENSION);
        
        try {
            // Convert theme to JSON
            String json = themeToJson(theme);
            
            // Write to file
            writeFile(themeFile, json);
            
            Log.i(TAG, "Theme saved: " + theme.getId());
            return true;
        } catch (IOException e) {
            Log.e(TAG, "Failed to save theme: " + theme.getId(), e);
            return false;
        }
    }
    
    /**
     * Delete a theme.
     */
    public boolean deleteTheme(@NonNull String themeId) {
        File themeFile = new File(mThemesDirectory, themeId + THEME_FILE_EXTENSION);
        
        if (themeFile.exists()) {
            boolean deleted = themeFile.delete();
            if (deleted) {
                Log.i(TAG, "Theme deleted: " + themeId);
            }
            return deleted;
        }
        
        return false;
    }
    
    /**
     * List all available theme IDs.
     */
    @NonNull
    public String[] listThemes() {
        File[] files = mThemesDirectory.listFiles((dir, name) ->
                name.endsWith(THEME_FILE_EXTENSION));
        
        if (files == null || files.length == 0) {
            return new String[0];
        }
        
        List<String> themeIds = new ArrayList<>();
        for (File file : files) {
            String name = file.getName();
            String themeId = name.substring(0, name.length() - THEME_FILE_EXTENSION.length());
            themeIds.add(themeId);
        }
        
        return themeIds.toArray(new String[0]);
    }
    
    /**
     * Load the default theme.
     */
    @Nullable
    public KeyboardThemeConfig loadDefaultTheme() {
        try {
            // Load default theme from assets
            InputStream is = mContext.getAssets().open("themes/default_light.json");
            String json = readInputStream(is);
            is.close();
            
            return ThemeJsonParser.parseTheme(json);
        } catch (IOException e) {
            Log.e(TAG, "Failed to load default theme", e);
            return createFallbackTheme();
        }
    }
    
    /**
     * Copy bundled default themes to storage on first run.
     */
    private void copyDefaultThemesIfNeeded() {
        String[] bundledThemes = {"default_light.json", "default_dark.json"};
        
        for (String themeName : bundledThemes) {
            String themeId = themeName.replace(THEME_FILE_EXTENSION, "");
            File themeFile = new File(mThemesDirectory, themeName);
            
            // Skip if already exists
            if (themeFile.exists()) {
                continue;
            }
            
            try {
                // Copy from assets
                InputStream is = mContext.getAssets().open("themes/" + themeName);
                String json = readInputStream(is);
                is.close();
                
                writeFile(themeFile, json);
                Log.i(TAG, "Copied bundled theme: " + themeId);
            } catch (IOException e) {
                Log.e(TAG, "Failed to copy bundled theme: " + themeId, e);
            }
        }
    }
    
    /**
     * Create a hardcoded fallback theme if all else fails.
     */
    @NonNull
    private KeyboardThemeConfig createFallbackTheme() {
        // Create simple light theme
        ThemeVariant lightVariant = new ThemeVariant(
                0xFFF5F5F5, // keyboardBackground
                0xFFFFFFFF, // regularKeyBackground
                0xFF000000, // regularKeyText
                0xFFCCCCCC, // regularKeyBorder
                1.0f,       // regularKeyBorderWidth
                6.0f,       // regularKeyCornerRadius
                0xFFE0E0E0, // modifierKeyBackground
                0xFF000000, // modifierKeyText
                0xFFBBBBBB, // modifierKeyBorder
                1.0f,       // modifierKeyBorderWidth
                6.0f,       // modifierKeyCornerRadius
                0xFF999999, // pressedKeyBackground
                0xFFFFFFFF, // pressedKeyText
                18.0f,      // keyFontSize
                ThemeVariant.FontWeight.REGULAR,
                16.0f,      // modifierKeyFontSize
                ThemeVariant.FontWeight.MEDIUM,
                3.0f,       // keySpacing
                6.0f        // rowSpacing
        );
        
        // Use same variant for both light and dark (simple fallback)
        return new KeyboardThemeConfig(
                "fallback",
                "Fallback Theme",
                "1.0",
                "System",
                lightVariant,
                lightVariant
        );
    }
    
    /**
     * Convert theme to JSON string.
     */
    @NonNull
    private String themeToJson(@NonNull KeyboardThemeConfig theme) {
        // Use Gson to serialize
        return new com.google.gson.Gson().toJson(theme);
    }
    
    /**
     * Read file contents as string.
     */
    @NonNull
    private String readFile(@NonNull File file) throws IOException {
        FileInputStream fis = new FileInputStream(file);
        byte[] buffer = new byte[(int) file.length()];
        fis.read(buffer);
        fis.close();
        return new String(buffer, StandardCharsets.UTF_8);
    }
    
    /**
     * Read InputStream as string.
     */
    @NonNull
    private String readInputStream(@NonNull InputStream is) throws IOException {
        byte[] buffer = new byte[is.available()];
        is.read(buffer);
        return new String(buffer, StandardCharsets.UTF_8);
    }
    
    /**
     * Write string to file.
     */
    private void writeFile(@NonNull File file, @NonNull String content) throws IOException {
        FileOutputStream fos = new FileOutputStream(file);
        fos.write(content.getBytes(StandardCharsets.UTF_8));
        fos.close();
    }
}
```

---

## 9. Theme Editor (Android)

### ThemeEditorActivity.java (Simplified)

```java
package com.sangam.settings;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.SeekBar;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.sangam.theme.KeyboardThemeConfig;
import com.sangam.theme.ThemeManager;
import com.sangam.theme.ThemeStorage;
import com.sangam.theme.ThemeVariant;

/**
 * Activity for creating and editing keyboard themes.
 * Provides UI controls for customizing theme properties.
 */
public class ThemeEditorActivity extends AppCompatActivity {
    
    private KeyboardThemeConfig mTheme;
    private ThemeVariant mCurrentVariant;
    private boolean mEditingLightMode = true;
    
    private ThemeStorage mStorage;
    private ThemeManager mThemeManager;
    
    // UI components
    private EditText mThemeNameInput;
    private EditText mThemeDescriptionInput;
    private RecyclerView mPropertiesRecyclerView;
    private Button mSaveButton;
    private Button mModeToggleButton;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_theme_editor);
        
        mStorage = new ThemeStorage(this);
        mThemeManager = ThemeManager.getInstance(this);
        
        // Initialize UI
        initializeViews();
        
        // Load theme for editing or create new
        String themeId = getIntent().getStringExtra("theme_id");
        if (themeId != null) {
            loadTheme(themeId);
        } else {
            createNewTheme();
        }
        
        setupListeners();
    }
    
    private void initializeViews() {
        mThemeNameInput = findViewById(R.id.theme_name_input);
        mThemeDescriptionInput = findViewById(R.id.theme_description_input);
        mPropertiesRecyclerView = findViewById(R.id.properties_recycler);
        mSaveButton = findViewById(R.id.save_button);
        mModeToggleButton = findViewById(R.id.mode_toggle_button);
        
        // Setup RecyclerView for property editors
        mPropertiesRecyclerView.setLayoutManager(new LinearLayoutManager(this));
    }
    
    private void setupListeners() {
        mSaveButton.setOnClickListener(v -> saveTheme());
        
        mModeToggleButton.setOnClickListener(v -> {
            mEditingLightMode = !mEditingLightMode;
            mModeToggleButton.setText(mEditingLightMode ? "Light Mode" : "Dark Mode");
            mCurrentVariant = mEditingLightMode ? mTheme.getLight() : mTheme.getDark();
            updateUI();
        });
    }
    
    private void loadTheme(String themeId) {
        mTheme = mStorage.loadTheme(themeId);
        if (mTheme == null) {
            Toast.makeText(this, "Failed to load theme", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }
        
        mCurrentVariant = mTheme.getLight();
        updateUI();
    }
    
    private void createNewTheme() {
        // Create a new theme with default values
        ThemeVariant defaultVariant = createDefaultVariant();
        mTheme = new KeyboardThemeConfig(
                "custom_" + System.currentTimeMillis(),
                "My Theme",
                "1.0",
                "Me",
                defaultVariant,
                defaultVariant // Use same for both initially
        );
        
        mCurrentVariant = mTheme.getLight();
        updateUI();
    }
    
    private ThemeVariant createDefaultVariant() {
        return new ThemeVariant(
                0xFFF5F5F5, // keyboardBackground
                0xFFFFFFFF, // regularKeyBackground
                0xFF000000, // regularKeyText
                0xFFCCCCCC, // regularKeyBorder
                1.0f,       // regularKeyBorderWidth
                6.0f,       // regularKeyCornerRadius
                0xFFE0E0E0, // modifierKeyBackground
                0xFF000000, // modifierKeyText
                0xFFBBBBBB, // modifierKeyBorder
                1.0f,       // modifierKeyBorderWidth
                6.0f,       // modifierKeyCornerRadius
                0xFF999999, // pressedKeyBackground
                0xFFFFFFFF, // pressedKeyText
                18.0f,      // keyFontSize
                ThemeVariant.FontWeight.REGULAR,
                16.0f,      // modifierKeyFontSize
                ThemeVariant.FontWeight.MEDIUM,
                3.0f,       // keySpacing
                6.0f        // rowSpacing
        );
    }
    
    private void updateUI() {
        // Update text fields
        mThemeNameInput.setText(mTheme.getName());
        mThemeDescriptionInput.setText(mTheme.getDescription());
        
        // Update property editors
        // (Implementation would use RecyclerView adapter with various property editors)
    }
    
    private void saveTheme() {
        // Get values from UI
        String name = mThemeNameInput.getText().toString().trim();
        String description = mThemeDescriptionInput.getText().toString().trim();
        
        // Validate
        if (name.isEmpty()) {
            Toast.makeText(this, "Theme name is required", Toast.LENGTH_SHORT).show();
            return;
        }
        
        // Update theme
        // (Implementation would update theme properties from UI controls)
        
        // Save to storage
        boolean saved = mStorage.saveTheme(mTheme);
        
        if (saved) {
            Toast.makeText(this, "Theme saved successfully", Toast.LENGTH_SHORT).show();
            
            // Optionally apply the theme
            mThemeManager.setTheme(mTheme.getId());
            
            finish();
        } else {
            Toast.makeText(this, "Failed to save theme", Toast.LENGTH_SHORT).show();
        }
    }
}
```

**Note:** A full theme editor implementation would require:
- Color picker dialogs
- Slider components for numeric values
- Font weight selector
- Preview pane showing keyboard with current theme
- Proper RecyclerView adapters for property sections

Due to length constraints, this is a simplified skeleton. The complete implementation would follow the same patterns as the iOS version but using Android UI components.

---

## 10. Theme Store (Android)

The Android Theme Store would reuse the same backend API specified in Document 4. The implementation would include:

### Activities Needed:
1. **ThemeStoreActivity** - Browse and search themes
2. **ThemeDetailActivity** - View theme details and download
3. **MyThemesActivity** - Manage uploaded and downloaded themes

### Key Components:

```java
// API Client for theme store
public class ThemeStoreAPI {
    private static final String BASE_URL = "https://api.sangamkeyboards.com/v1";
    
    public List<ThemeMetadata> getThemes(int page, String sort) {
        // HTTP request to /themes endpoint
    }
    
    public ThemeMetadata getThemeDetail(String themeId) {
        // HTTP request to /themes/:id
    }
    
    public String downloadTheme(String themeId) {
        // HTTP request to /themes/:id/download
    }
    
    public boolean uploadTheme(KeyboardThemeConfig theme) {
        // HTTP request to POST /themes
    }
}
```

**Pro User Check:**
```java
public class UserManager {
    public boolean isPro(Context context) {
        // Check subscription status
        // (Implementation depends on your billing system)
    }
    
    public void showProUpgradeDialog(Context context) {
        // Show upgrade prompt
    }
}
```

---

## 11. Migration from Existing Code

### Step-by-Step Migration Plan

**Phase 1: Add Theme Classes (No Breaking Changes)**
1. Add all theme-related classes to project
2. Add bundled default themes to assets
3. Test theme loading and parsing
4. Verify no impact on existing keyboard

**Phase 2: Integrate with KeyboardView**
1. Modify `KeyboardView.java` to support themes
2. Add theme application methods
3. Keep existing drawable system as fallback
4. Test with default theme

**Phase 3: Apply Theme on Keyboard Creation**
1. Modify keyboard initialization to load theme
2. Apply theme when keyboard view is created
3. Test all keyboard layouts (Tamil, Malayalam, English, etc.)

**Phase 4: Settings Integration**
1. Add theme selector to settings
2. Allow users to switch themes
3. Persist theme selection

**Phase 5: Theme Editor**
1. Build theme editor activity
2. Allow theme creation and editing
3. Test theme saving and loading

**Phase 6: Theme Store**
1. Integrate theme store API
2. Build browse and download UI
3. Implement upload functionality (Pro only)

### Backwards Compatibility

```java
// In KeyboardView.java
@Override
protected void onDrawKeyBackground(Key key, Canvas canvas, Drawable background) {
    // Check if theme is available
    if (mCurrentThemeVariant != null && mThemedKeyBackground != null) {
        // Use themed drawable
        super.onDrawKeyBackground(key, canvas, getThemedDrawable(key));
    } else {
        // Fall back to original drawable
        super.onDrawKeyBackground(key, canvas, background);
    }
}

private Drawable getThemedDrawable(Key key) {
    if (key.isSpacebar()) {
        return mThemedSpacebarBackground;
    } else if (key.isFunctional()) {
        return mThemedFunctionalKeyBackground;
    } else {
        return mThemedKeyBackground;
    }
}
```

## 12. Testing Strategy

### Unit Tests

#### ThemeJsonParserTest.java

```java
package com.sangam.theme;

import android.graphics.Color;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
public class ThemeJsonParserTest {
    
    @Test
    public void testParseValidTheme() {
        String json = "{\n" +
                "  \"schemaVersion\": \"1.0\",\n" +
                "  \"id\": \"test_theme\",\n" +
                "  \"name\": \"Test Theme\",\n" +
                "  \"version\": \"1.0\",\n" +
                "  \"author\": \"Test Author\",\n" +
                "  \"light\": {\n" +
                "    \"keyboardBackground\": \"#ffffff\",\n" +
                "    \"regularKeyBackground\": \"#f0f0f0\",\n" +
                "    \"regularKeyText\": \"#000000\",\n" +
                "    \"regularKeyBorder\": \"#cccccc\",\n" +
                "    \"regularKeyBorderWidth\": 1.0,\n" +
                "    \"regularKeyCornerRadius\": 6.0,\n" +
                "    \"modifierKeyBackground\": \"#e0e0e0\",\n" +
                "    \"modifierKeyText\": \"#000000\",\n" +
                "    \"modifierKeyBorder\": \"#bbbbbb\",\n" +
                "    \"modifierKeyBorderWidth\": 1.0,\n" +
                "    \"modifierKeyCornerRadius\": 6.0,\n" +
                "    \"pressedKeyBackground\": \"#999999\",\n" +
                "    \"pressedKeyText\": \"#ffffff\",\n" +
                "    \"keyFontSize\": 18.0,\n" +
                "    \"keyFontWeight\": \"regular\",\n" +
                "    \"modifierKeyFontSize\": 16.0,\n" +
                "    \"modifierKeyFontWeight\": \"medium\",\n" +
                "    \"keySpacing\": 3.0,\n" +
                "    \"rowSpacing\": 6.0\n" +
                "  },\n" +
                "  \"dark\": {\n" +
                "    \"keyboardBackground\": \"#000000\",\n" +
                "    \"regularKeyBackground\": \"#2a2a2a\",\n" +
                "    \"regularKeyText\": \"#ffffff\",\n" +
                "    \"regularKeyBorder\": \"#444444\",\n" +
                "    \"regularKeyBorderWidth\": 1.0,\n" +
                "    \"regularKeyCornerRadius\": 6.0,\n" +
                "    \"modifierKeyBackground\": \"#3a3a3a\",\n" +
                "    \"modifierKeyText\": \"#ffffff\",\n" +
                "    \"modifierKeyBorder\": \"#555555\",\n" +
                "    \"modifierKeyBorderWidth\": 1.0,\n" +
                "    \"modifierKeyCornerRadius\": 6.0,\n" +
                "    \"pressedKeyBackground\": \"#555555\",\n" +
                "    \"pressedKeyText\": \"#ffffff\",\n" +
                "    \"keyFontSize\": 18.0,\n" +
                "    \"keyFontWeight\": \"regular\",\n" +
                "    \"modifierKeyFontSize\": 16.0,\n" +
                "    \"modifierKeyFontWeight\": \"medium\",\n" +
                "    \"keySpacing\": 3.0,\n" +
                "    \"rowSpacing\": 6.0\n" +
                "  }\n" +
                "}";
        
        KeyboardThemeConfig theme = ThemeJsonParser.parseTheme(json);
        
        assertNotNull("Theme should not be null", theme);
        assertEquals("test_theme", theme.getId());
        assertEquals("Test Theme", theme.getName());
        assertEquals("1.0", theme.getVersion());
        assertEquals("Test Author", theme.getAuthor());
        
        // Verify light variant
        ThemeVariant light = theme.getLight();
        assertNotNull(light);
        assertEquals(Color.WHITE, light.getKeyboardBackground());
        assertEquals(Color.parseColor("#f0f0f0"), light.getRegularKeyBackground());
        assertEquals(18.0f, light.getKeyFontSize(), 0.01f);
        
        // Verify dark variant
        ThemeVariant dark = theme.getDark();
        assertNotNull(dark);
        assertEquals(Color.BLACK, dark.getKeyboardBackground());
        assertEquals(Color.parseColor("#2a2a2a"), dark.getRegularKeyBackground());
    }
    
    @Test
    public void testParseMissingRequiredField() {
        String json = "{\n" +
                "  \"id\": \"test_theme\",\n" +
                "  \"name\": \"Test Theme\"\n" +
                "}";
        
        KeyboardThemeConfig theme = ThemeJsonParser.parseTheme(json);
        assertNull("Theme should be null when required fields are missing", theme);
    }
    
    @Test
    public void testParseInvalidColorFormat() {
        String json = "{\n" +
                "  \"schemaVersion\": \"1.0\",\n" +
                "  \"id\": \"test_theme\",\n" +
                "  \"name\": \"Test Theme\",\n" +
                "  \"version\": \"1.0\",\n" +
                "  \"author\": \"Test Author\",\n" +
                "  \"light\": {\n" +
                "    \"keyboardBackground\": \"not-a-color\",\n" +
                "    \"regularKeyBackground\": \"#f0f0f0\"\n" +
                "  }\n" +
                "}";
        
        KeyboardThemeConfig theme = ThemeJsonParser.parseTheme(json);
        assertNull("Theme should be null when color format is invalid", theme);
    }
    
    @Test
    public void testParseFontWeight() {
        assertEquals(ThemeVariant.FontWeight.REGULAR, 
                ThemeVariant.FontWeight.fromString("regular"));
        assertEquals(ThemeVariant.FontWeight.BOLD, 
                ThemeVariant.FontWeight.fromString("bold"));
        assertEquals(ThemeVariant.FontWeight.LIGHT, 
                ThemeVariant.FontWeight.fromString("light"));
        assertEquals(ThemeVariant.FontWeight.REGULAR, 
                ThemeVariant.FontWeight.fromString("invalid"));
    }
    
    @Test
    public void testParseOptionalCandidateBarProperties() {
        String json = "{\n" +
                "  \"schemaVersion\": \"1.0\",\n" +
                "  \"id\": \"test_theme\",\n" +
                "  \"name\": \"Test Theme\",\n" +
                "  \"version\": \"1.0\",\n" +
                "  \"author\": \"Test Author\",\n" +
                "  \"light\": {\n" +
                "    \"keyboardBackground\": \"#ffffff\",\n" +
                "    \"regularKeyBackground\": \"#f0f0f0\",\n" +
                "    \"regularKeyText\": \"#000000\",\n" +
                "    \"regularKeyBorder\": \"#cccccc\",\n" +
                "    \"regularKeyBorderWidth\": 1.0,\n" +
                "    \"regularKeyCornerRadius\": 6.0,\n" +
                "    \"modifierKeyBackground\": \"#e0e0e0\",\n" +
                "    \"modifierKeyText\": \"#000000\",\n" +
                "    \"modifierKeyBorder\": \"#bbbbbb\",\n" +
                "    \"modifierKeyBorderWidth\": 1.0,\n" +
                "    \"modifierKeyCornerRadius\": 6.0,\n" +
                "    \"pressedKeyBackground\": \"#999999\",\n" +
                "    \"pressedKeyText\": \"#ffffff\",\n" +
                "    \"keyFontSize\": 18.0,\n" +
                "    \"keyFontWeight\": \"regular\",\n" +
                "    \"modifierKeyFontSize\": 16.0,\n" +
                "    \"modifierKeyFontWeight\": \"medium\",\n" +
                "    \"keySpacing\": 3.0,\n" +
                "    \"rowSpacing\": 6.0,\n" +
                "    \"candidateBarBackground\": \"#f5f5f5\",\n" +
                "    \"candidateText\": \"#333333\"\n" +
                "  },\n" +
                "  \"dark\": {\n" +
                "    \"keyboardBackground\": \"#000000\",\n" +
                "    \"regularKeyBackground\": \"#2a2a2a\",\n" +
                "    \"regularKeyText\": \"#ffffff\",\n" +
                "    \"regularKeyBorder\": \"#444444\",\n" +
                "    \"regularKeyBorderWidth\": 1.0,\n" +
                "    \"regularKeyCornerRadius\": 6.0,\n" +
                "    \"modifierKeyBackground\": \"#3a3a3a\",\n" +
                "    \"modifierKeyText\": \"#ffffff\",\n" +
                "    \"modifierKeyBorder\": \"#555555\",\n" +
                "    \"modifierKeyBorderWidth\": 1.0,\n" +
                "    \"modifierKeyCornerRadius\": 6.0,\n" +
                "    \"pressedKeyBackground\": \"#555555\",\n" +
                "    \"pressedKeyText\": \"#ffffff\",\n" +
                "    \"keyFontSize\": 18.0,\n" +
                "    \"keyFontWeight\": \"regular\",\n" +
                "    \"modifierKeyFontSize\": 16.0,\n" +
                "    \"modifierKeyFontWeight\": \"medium\",\n" +
                "    \"keySpacing\": 3.0,\n" +
                "    \"rowSpacing\": 6.0\n" +
                "  }\n" +
                "}";
        
        KeyboardThemeConfig theme = ThemeJsonParser.parseTheme(json);
        assertNotNull(theme);
        
        ThemeVariant light = theme.getLight();
        assertEquals(Color.parseColor("#f5f5f5"), light.getCandidateBarBackground());
        assertEquals(Color.parseColor("#333333"), light.getCandidateText());
    }
}
```

#### KeyboardThemeDrawableFactoryTest.java

```java
package com.sangam.theme;

import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
public class KeyboardThemeDrawableFactoryTest {
    
    private ThemeVariant testTheme;
    
    @Before
    public void setUp() {
        testTheme = new ThemeVariant(
                Color.WHITE,
                Color.parseColor("#f0f0f0"),
                Color.BLACK,
                Color.parseColor("#cccccc"),
                1.0f,
                6.0f,
                Color.parseColor("#e0e0e0"),
                Color.BLACK,
                Color.parseColor("#bbbbbb"),
                1.0f,
                6.0f,
                Color.parseColor("#999999"),
                Color.WHITE,
                18.0f,
                ThemeVariant.FontWeight.REGULAR,
                16.0f,
                ThemeVariant.FontWeight.MEDIUM,
                3.0f,
                6.0f
        );
    }
    
    @Test
    public void testCreateRegularKeyDrawable() {
        Drawable drawable = KeyboardThemeDrawableFactory.createRegularKeyDrawable(testTheme);
        
        assertNotNull("Drawable should not be null", drawable);
        assertTrue("Should be GradientDrawable", drawable instanceof GradientDrawable);
    }
    
    @Test
    public void testCreateModifierKeyDrawable() {
        Drawable drawable = KeyboardThemeDrawableFactory.createModifierKeyDrawable(testTheme);
        
        assertNotNull("Drawable should not be null", drawable);
        assertTrue("Should be GradientDrawable", drawable instanceof GradientDrawable);
    }
    
    @Test
    public void testCreateKeyStateDrawable() {
        StateListDrawable drawable = KeyboardThemeDrawableFactory.createKeyStateDrawable(
                testTheme, false);
        
        assertNotNull("Drawable should not be null", drawable);
        assertTrue("Should be StateListDrawable", drawable instanceof StateListDrawable);
    }
    
    @Test
    public void testCreateSpacebarDrawable() {
        Drawable drawable = KeyboardThemeDrawableFactory.createSpacebarDrawable(testTheme);
        
        assertNotNull("Drawable should not be null", drawable);
        assertTrue("Should be GradientDrawable", drawable instanceof GradientDrawable);
    }
    
    @Test
    public void testCreateCandidateBarDrawable() {
        Drawable drawable = KeyboardThemeDrawableFactory.createCandidateBarDrawable(testTheme);
        
        assertNotNull("Drawable should not be null", drawable);
        assertTrue("Should be GradientDrawable", drawable instanceof GradientDrawable);
    }
}
```

### Integration Tests

#### ThemeIntegrationTest.java

```java
package com.sangam.theme;

import android.content.Context;

import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class ThemeIntegrationTest {
    
    private Context context;
    private ThemeStorage storage;
    private ThemeManager manager;
    
    @Before
    public void setUp() {
        context = ApplicationProvider.getApplicationContext();
        storage = new ThemeStorage(context);
        manager = ThemeManager.getInstance(context);
    }
    
    @Test
    public void testSaveAndLoadTheme() {
        // Create a test theme
        ThemeVariant variant = createTestVariant();
        KeyboardThemeConfig theme = new KeyboardThemeConfig(
                "test_save_load",
                "Test Save Load",
                "1.0",
                "Test",
                variant,
                variant
        );
        
        // Save theme
        boolean saved = storage.saveTheme(theme);
        assertTrue("Theme should be saved successfully", saved);
        
        // Load theme
        KeyboardThemeConfig loaded = storage.loadTheme("test_save_load");
        assertNotNull("Loaded theme should not be null", loaded);
        assertEquals("test_save_load", loaded.getId());
        assertEquals("Test Save Load", loaded.getName());
        
        // Clean up
        storage.deleteTheme("test_save_load");
    }
    
    @Test
    public void testThemeManagerSetAndGet() {
        // Create and save a test theme
        ThemeVariant variant = createTestVariant();
        KeyboardThemeConfig theme = new KeyboardThemeConfig(
                "test_manager",
                "Test Manager",
                "1.0",
                "Test",
                variant,
                variant
        );
        storage.saveTheme(theme);
        
        // Set theme via manager
        manager.setTheme("test_manager");
        
        // Get current theme
        KeyboardThemeConfig current = manager.getCurrentTheme();
        assertNotNull("Current theme should not be null", current);
        assertEquals("test_manager", current.getId());
        
        // Clean up
        storage.deleteTheme("test_manager");
    }
    
    @Test
    public void testListThemes() {
        // Create and save test themes
        ThemeVariant variant = createTestVariant();
        
        KeyboardThemeConfig theme1 = new KeyboardThemeConfig(
                "test_list_1", "Theme 1", "1.0", "Test", variant, variant);
        KeyboardThemeConfig theme2 = new KeyboardThemeConfig(
                "test_list_2", "Theme 2", "1.0", "Test", variant, variant);
        
        storage.saveTheme(theme1);
        storage.saveTheme(theme2);
        
        // List themes
        String[] themes = storage.listThemes();
        
        assertTrue("Should have at least 2 themes", themes.length >= 2);
        
        // Clean up
        storage.deleteTheme("test_list_1");
        storage.deleteTheme("test_list_2");
    }
    
    @Test
    public void testDeleteTheme() {
        // Create and save test theme
        ThemeVariant variant = createTestVariant();
        KeyboardThemeConfig theme = new KeyboardThemeConfig(
                "test_delete",
                "Test Delete",
                "1.0",
                "Test",
                variant,
                variant
        );
        storage.saveTheme(theme);
        
        // Verify it exists
        KeyboardThemeConfig loaded = storage.loadTheme("test_delete");
        assertNotNull("Theme should exist before deletion", loaded);
        
        // Delete theme
        boolean deleted = storage.deleteTheme("test_delete");
        assertTrue("Theme should be deleted successfully", deleted);
        
        // Verify it's gone
        KeyboardThemeConfig afterDelete = storage.loadTheme("test_delete");
        assertNull("Theme should not exist after deletion", afterDelete);
    }
    
    @Test
    public void testDefaultThemeLoads() {
        KeyboardThemeConfig defaultTheme = storage.loadDefaultTheme();
        
        assertNotNull("Default theme should load", defaultTheme);
        assertNotNull("Light variant should exist", defaultTheme.getLight());
        assertNotNull("Dark variant should exist", defaultTheme.getDark());
    }
    
    private ThemeVariant createTestVariant() {
        return new ThemeVariant(
                0xFFFFFFFF,
                0xFFF0F0F0,
                0xFF000000,
                0xFFCCCCCC,
                1.0f,
                6.0f,
                0xFFE0E0E0,
                0xFF000000,
                0xFFBBBBBB,
                1.0f,
                6.0f,
                0xFF999999,
                0xFFFFFFFF,
                18.0f,
                ThemeVariant.FontWeight.REGULAR,
                16.0f,
                ThemeVariant.FontWeight.MEDIUM,
                3.0f,
                6.0f
        );
    }
}
```

### Manual Testing Checklist

**Theme Loading:**
- [ ] Default theme loads on first run
- [ ] Theme persists across app restarts
- [ ] Light/dark mode switching works correctly
- [ ] Invalid theme JSON falls back gracefully

**Visual Appearance:**
- [ ] Key colors match theme exactly
- [ ] Text is readable (good contrast)
- [ ] Borders appear with correct width and color
- [ ] Corner radius is applied correctly
- [ ] Spacing between keys matches theme
- [ ] Pressed state shows correct colors

**Typography:**
- [ ] Font sizes render correctly
- [ ] Font weights apply (as much as Android supports)
- [ ] Text is properly centered on keys
- [ ] Candidate bar text is readable

**Multiple Languages:**
- [ ] Tamil keyboard with custom theme
- [ ] Malayalam keyboard with custom theme
- [ ] English keyboard with custom theme
- [ ] Theme applies consistently across layouts

**Performance:**
- [ ] No lag when typing
- [ ] Theme changes apply smoothly
- [ ] Memory usage is acceptable
- [ ] No ANR (Application Not Responding) errors

**Edge Cases:**
- [ ] Very large font sizes
- [ ] Very small font sizes
- [ ] Zero border width
- [ ] Very large border width
- [ ] Extreme corner radius values
- [ ] Similar colors for text/background (should warn)

---

## 13. Performance Optimization

### Caching Strategy

```java
package com.sangam.theme;

import android.graphics.drawable.Drawable;
import android.util.LruCache;

import androidx.annotation.NonNull;

/**
 * Cache for theme-generated drawables to avoid recreation.
 */
public class DrawableCache {
    private static DrawableCache sInstance;
    
    // Cache up to 50 drawables in memory
    private final LruCache<String, Drawable> mCache;
    
    private DrawableCache() {
        // Calculate cache size (10% of max memory)
        final int maxMemory = (int) (Runtime.getRuntime().maxMemory() / 1024);
        final int cacheSize = maxMemory / 10;
        
        mCache = new LruCache<String, Drawable>(cacheSize) {
            @Override
            protected int sizeOf(String key, Drawable drawable) {
                // Estimate drawable size (simplified)
                return 1; // 1 KB per drawable
            }
        };
    }
    
    @NonNull
    public static synchronized DrawableCache getInstance() {
        if (sInstance == null) {
            sInstance = new DrawableCache();
        }
        return sInstance;
    }
    
    /**
     * Get a drawable from cache or create it.
     */
    @NonNull
    public Drawable getOrCreate(
            @NonNull String key,
            @NonNull DrawableFactory factory) {
        
        Drawable cached = mCache.get(key);
        if (cached != null) {
            return cached;
        }
        
        Drawable drawable = factory.create();
        mCache.put(key, drawable);
        return drawable;
    }
    
    /**
     * Clear the cache (e.g., when theme changes).
     */
    public void clear() {
        mCache.evictAll();
    }
    
    /**
     * Interface for creating drawables.
     */
    public interface DrawableFactory {
        Drawable create();
    }
}
```

**Usage in KeyboardThemeDrawableFactory:**

```java
public class KeyboardThemeDrawableFactory {
    
    @NonNull
    public static Drawable createRegularKeyDrawable(@NonNull ThemeVariant theme) {
        String cacheKey = String.format("regular_%d_%d_%f_%f",
                theme.getRegularKeyBackground(),
                theme.getRegularKeyBorder(),
                theme.getRegularKeyBorderWidth(),
                theme.getRegularKeyCornerRadius());
        
        return DrawableCache.getInstance().getOrCreate(cacheKey, () ->
                createKeyDrawable(
                        theme.getRegularKeyBackground(),
                        theme.getRegularKeyBorder(),
                        theme.getRegularKeyBorderWidth(),
                        theme.getRegularKeyCornerRadius()
                )
        );
    }
    
    // Similar for other drawable types...
}
```

### Lazy Initialization

```java
public class ThemeManager {
    // ... existing code ...
    
    // Lazy-load themes only when needed
    private KeyboardThemeConfig mCurrentTheme;
    private boolean mThemeLoaded = false;
    
    @Nullable
    public KeyboardThemeConfig getCurrentTheme() {
        if (!mThemeLoaded) {
            loadCurrentTheme();
            mThemeLoaded = true;
        }
        return mCurrentTheme;
    }
    
    // ... rest of code ...
}
```

### Async Theme Loading

```java
public class ThemeManager {
    // ... existing code ...
    
    /**
     * Load theme asynchronously to avoid blocking UI thread.
     */
    public void loadThemeAsync(@NonNull String themeId, @NonNull ThemeLoadCallback callback) {
        new Thread(() -> {
            KeyboardThemeConfig theme = mStorage.loadTheme(themeId);
            
            // Callback on main thread
            Handler mainHandler = new Handler(Looper.getMainLooper());
            mainHandler.post(() -> {
                if (theme != null) {
                    mCurrentTheme = theme;
                    mCurrentThemeId = themeId;
                    callback.onThemeLoaded(theme);
                } else {
                    callback.onThemeLoadFailed(themeId);
                }
            });
        }).start();
    }
    
    public interface ThemeLoadCallback {
        void onThemeLoaded(@NonNull KeyboardThemeConfig theme);
        void onThemeLoadFailed(@NonNull String themeId);
    }
}
```

### Minimize Re-draws

```java
public class KeyboardView extends View {
    // ... existing code ...
    
    private String mLastAppliedThemeId;
    
    public void applyTheme(@NonNull KeyboardThemeConfig themeConfig) {
        // Skip if same theme is already applied
        if (themeConfig.getId().equals(mLastAppliedThemeId)) {
            return;
        }
        
        mLastAppliedThemeId = themeConfig.getId();
        
        // ... rest of theme application logic ...
    }
}
```

### Memory Management

```java
public class ThemeStorage {
    // ... existing code ...
    
    // Keep only the most recent themes in memory
    private final LruCache<String, KeyboardThemeConfig> mThemeCache;
    
    public ThemeStorage(@NonNull Context context) {
        // ... existing initialization ...
        
        mThemeCache = new LruCache<>(10); // Cache 10 themes
    }
    
    @Nullable
    public KeyboardThemeConfig loadTheme(@NonNull String themeId) {
        // Check cache first
        KeyboardThemeConfig cached = mThemeCache.get(themeId);
        if (cached != null) {
            return cached;
        }
        
        // Load from file
        File themeFile = new File(mThemesDirectory, themeId + THEME_FILE_EXTENSION);
        if (!themeFile.exists()) {
            return null;
        }
        
        try {
            String json = readFile(themeFile);
            KeyboardThemeConfig theme = ThemeJsonParser.parseTheme(json);
            
            if (theme != null) {
                mThemeCache.put(themeId, theme);
            }
            
            return theme;
        } catch (IOException e) {
            Log.e(TAG, "Failed to read theme file: " + themeId, e);
            return null;
        }
    }
    
    public void clearCache() {
        mThemeCache.evictAll();
    }
}
```

---

## 14. Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Theme Not Applying

**Symptoms:**
- Keyboard still shows default appearance
- No visual changes after theme selection

**Debugging Steps:**
```java
// Add logging to ThemeManager
public void applyThemeToKeyboard(@NonNull KeyboardView keyboardView) {
    Log.d(TAG, "Applying theme: " + (mCurrentTheme != null ? mCurrentTheme.getName() : "null"));
    
    if (mCurrentTheme == null) {
        Log.w(TAG, "No theme loaded, using defaults");
        return;
    }
    
    keyboardView.applyTheme(mCurrentTheme);
    Log.d(TAG, "Theme applied successfully");
}
```

**Solutions:**
1. Verify theme is loaded: Check `ThemeManager.getCurrentTheme()` is not null
2. Check theme is saved: Use `ThemeStorage.listThemes()` to verify
3. Verify `applyTheme()` is called when keyboard is created
4. Check for exceptions in logcat during theme parsing

#### Issue 2: Colors Not Matching Theme

**Symptoms:**
- Colors appear different from theme JSON
- Wrong colors on some keys

**Debugging Steps:**
```java
// In KeyboardView.onDrawKeyTopVisuals()
Log.d(TAG, "Drawing key " + key.getLabel() + 
        " with color: " + Integer.toHexString(textColor));
```

**Solutions:**
1. Verify color parsing: Check if hex colors are parsed correctly
2. Check color format: Ensure colors are in `#RRGGBB` or `#AARRGGBB` format
3. Verify drawable generation: Inspect generated `GradientDrawable` properties
4. Check for color blending: Ensure no alpha compositing issues

#### Issue 3: Theme JSON Parse Error

**Symptoms:**
- Theme fails to load
- Parser returns null

**Debugging Steps:**
```java
// Add detailed logging to ThemeJsonParser
public static KeyboardThemeConfig parseTheme(@NonNull String jsonString) {
    try {
        Log.d(TAG, "Parsing theme JSON of length: " + jsonString.length());
        JsonObject root = JsonParser.parseString(jsonString).getAsJsonObject();
        
        // Log each step
        Log.d(TAG, "Root object parsed successfully");
        
        String id = getRequiredString(root, "id");
        Log.d(TAG, "Theme ID: " + id);
        
        // ... continue with detailed logging ...
        
    } catch (Exception e) {
        Log.e(TAG, "Parse error", e);
        Log.e(TAG, "JSON content: " + jsonString);
        return null;
    }
}
```

**Solutions:**
1. Validate JSON syntax: Use online JSON validator
2. Check required fields: Ensure all required properties are present
3. Verify color formats: All colors must be valid hex strings
4. Check numeric values: Ensure floats have decimal points
5. Verify schema version: Must be "1.0"

#### Issue 4: Performance Degradation

**Symptoms:**
- Keyboard lag when typing
- Slow theme switching
- High memory usage

**Debugging Steps:**
```java
// Add performance logging
long startTime = System.currentTimeMillis();
applyTheme(themeConfig);
long endTime = System.currentTimeMillis();
Log.d(TAG, "Theme application took: " + (endTime - startTime) + "ms");
```

**Solutions:**
1. Enable drawable caching (see Performance Optimization section)
2. Reduce theme file size: Remove unnecessary properties
3. Use ProGuard: Optimize and shrink APK
4. Profile with Android Studio: Use CPU and Memory profilers
5. Check for memory leaks: Use LeakCanary

#### Issue 5: Crash on Theme Load

**Symptoms:**
- App crashes when loading theme
- `NullPointerException` or `OutOfMemoryError`

**Debugging Steps:**
```java
// Wrap theme loading in try-catch
try {
    KeyboardThemeConfig theme = mStorage.loadTheme(themeId);
    if (theme != null) {
        applyTheme(theme);
    } else {
        Log.e(TAG, "Theme is null: " + themeId);
        // Fall back to default
        applyTheme(mStorage.loadDefaultTheme());
    }
} catch (Exception e) {
    Log.e(TAG, "Failed to load theme", e);
    // Show error to user
    Toast.makeText(context, "Failed to load theme", Toast.LENGTH_SHORT).show();
}
```

**Solutions:**
1. Add null checks: Verify theme is not null before using
2. Validate theme data: Check all required fields exist
3. Reduce memory usage: Implement caching and cleanup
4. Catch and handle exceptions: Graceful fallback to default theme
5. Test on low-end devices: Ensure compatibility

#### Issue 6: Dark Mode Not Working

**Symptoms:**
- Dark mode theme not applied
- Always shows light theme

**Debugging Steps:**
```java
// Check dark mode detection
int nightMode = context.getResources().getConfiguration().uiMode 
        & Configuration.UI_MODE_NIGHT_MASK;
boolean isDarkMode = (nightMode == Configuration.UI_MODE_NIGHT_YES);
Log.d(TAG, "Is dark mode: " + isDarkMode);

ThemeVariant variant = themeConfig.getCurrentVariant(isDarkMode);
Log.d(TAG, "Using variant with background: " + 
        Integer.toHexString(variant.getKeyboardBackground()));
```

**Solutions:**
1. Register configuration change listener
2. Reload theme when night mode changes
3. Verify both light and dark variants are in JSON
4. Test with system dark mode toggle

#### Issue 7: Font Size Not Applying

**Symptoms:**
- Text size doesn't match theme
- All keys have same font size

**Debugging Steps:**
```java
// Check font size conversion
float fontSize = theme.getKeyFontSize();
float density = context.getResources().getDisplayMetrics().density;
float sizeInPx = fontSize * density;
Log.d(TAG, "Font size: " + fontSize + "pt = " + sizeInPx + "px");
```

**Solutions:**
1. Convert pt to px: Multiply by screen density
2. Check paint text size: Verify `paint.setTextSize()` is called
3. Verify font size range: Should be between 10-30pt
4. Test on different screen densities

### Diagnostic Tool

```java
public class ThemeDiagnostics {
    
    /**
     * Run diagnostics on a theme and return a report.
     */
    public static String diagnoseTheme(@NonNull KeyboardThemeConfig theme) {
        StringBuilder report = new StringBuilder();
        
        report.append("=== Theme Diagnostics ===\n\n");
        report.append("ID: ").append(theme.getId()).append("\n");
        report.append("Name: ").append(theme.getName()).append("\n");
        report.append("Version: ").append(theme.getVersion()).append("\n");
        report.append("Author: ").append(theme.getAuthor()).append("\n\n");
        
        // Check light variant
        report.append("--- Light Variant ---\n");
        report.append(diagnoseVariant(theme.getLight()));
        
        // Check dark variant
        report.append("\n--- Dark Variant ---\n");
        report.append(diagnoseVariant(theme.getDark()));
        
        return report.toString();
    }
    
    private static String diagnoseVariant(@NonNull ThemeVariant variant) {
        StringBuilder report = new StringBuilder();
        
        // Check contrast ratios
        double textBgRatio = calculateContrastRatio(
                variant.getRegularKeyText(),
                variant.getRegularKeyBackground()
        );
        report.append("Text/Background Contrast: ").append(String.format("%.2f", textBgRatio))
                .append(":1 ");
        if (textBgRatio < 4.5) {
            report.append("⚠️ WARNING: Below WCAG minimum (4.5:1)\n");
        } else {
            report.append("✓ OK\n");
        }
        
        // Check font sizes
        float keyFontSize = variant.getKeyFontSize();
        report.append("Key Font Size: ").append(keyFontSize).append("pt ");
        if (keyFontSize < 10 || keyFontSize > 30) {
            report.append("⚠️ WARNING: Outside recommended range (10-30pt)\n");
        } else {
            report.append("✓ OK\n");
        }
        
        // Check border width
        float borderWidth = variant.getRegularKeyBorderWidth();
        report.append("Border Width: ").append(borderWidth).append("px ");
        if (borderWidth < 0 || borderWidth > 5) {
            report.append("⚠️ WARNING: Outside recommended range (0-5px)\n");
        } else {
            report.append("✓ OK\n");
        }
        
        // Check corner radius
        float cornerRadius = variant.getRegularKeyCornerRadius();
        report.append("Corner Radius: ").append(cornerRadius).append("px ");
        if (cornerRadius < 0 || cornerRadius > 20) {
            report.append("⚠️ WARNING: Outside recommended range (0-20px)\n");
        } else {
            report.append("✓ OK\n");
        }
        
        return report.toString();
    }
    
    /**
     * Calculate WCAG contrast ratio between two colors.
     */
    private static double calculateContrastRatio(int color1, int color2) {
        double l1 = calculateRelativeLuminance(color1);
        double l2 = calculateRelativeLuminance(color2);
        
        double lighter = Math.max(l1, l2);
        double darker = Math.min(l1, l2);
        
        return (lighter + 0.05) / (darker + 0.05);
    }
    
    private static double calculateRelativeLuminance(int color) {
        double r = linearize(Color.red(color) / 255.0);
        double g = linearize(Color.green(color) / 255.0);
        double b = linearize(Color.blue(color) / 255.0);
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }
    
    private static double linearize(double channel) {
        if (channel <= 0.03928) {
            return channel / 12.92;
        } else {
            return Math.pow((channel + 0.055) / 1.055, 2.4);
        }
    }
}
```

**Usage:**
```java
// In theme editor or settings
String diagnostics = ThemeDiagnostics.diagnoseTheme(theme);
Log.d(TAG, diagnostics);

// Or show in UI
AlertDialog.Builder builder = new AlertDialog.Builder(context);
builder.setTitle("Theme Diagnostics");
builder.setMessage(diagnostics);
builder.setPositiveButton("OK", null);
builder.show();
```

---

## Appendix A: Complete File Structure

```
app/src/main/
├── java/com/sangam/
│   ├── theme/
│   │   ├── KeyboardThemeConfig.java
│   │   ├── ThemeVariant.java
│   │   ├── ThemeJsonParser.java
│   │   ├── KeyboardThemeDrawableFactory.java
│   │   ├── ThemeStorage.java
│   │   ├── ThemeManager.java
│   │   ├── DrawableCache.java
│   │   └── ThemeDiagnostics.java
│   │
│   ├── keyboard/
│   │   ├── KeyboardView.java (modified)
│   │   └── MainKeyboardView.java (modified)
│   │
│   ├── settings/
│   │   ├── ThemeEditorActivity.java
│   │   ├── ThemeStoreActivity.java
│   │   ├── ThemeListActivity.java
│   │   └── ThemeDetailActivity.java
│   │
│   └── api/
│       └── ThemeStoreAPI.java
│
├── assets/
│   └── themes/
│       ├── default_light.json
│       └── default_dark.json
│
└── res/
    ├── layout/
    │   ├── activity_theme_editor.xml
    │   ├── activity_theme_store.xml
    │   ├── activity_theme_list.xml
    │   └── item_theme.xml
    │
    └── values/
        └── strings.xml
```

---

## Appendix B: Sample Default Theme

**assets/themes/default_light.json:**

```json
{
  "schemaVersion": "1.0",
  "id": "default_light",
  "name": "Default Light",
  "version": "1.0",
  "author": "Sangam Keyboards",
  "description": "Clean and simple light theme",
  "tags": ["light", "default", "simple"],
  
  "light": {
    "keyboardBackground": "#f5f5f5",
    "regularKeyBackground": "#ffffff",
    "regularKeyText": "#000000",
    "regularKeyBorder": "#cccccc",
    "regularKeyBorderWidth": 1.0,
    "regularKeyCornerRadius": 6.0,
    
    "modifierKeyBackground": "#e0e0e0",
    "modifierKeyText": "#000000",
    "modifierKeyBorder": "#bbbbbb",
    "modifierKeyBorderWidth": 1.0,
    "modifierKeyCornerRadius": 6.0,
    
    "pressedKeyBackground": "#999999",
    "pressedKeyText": "#ffffff",
    
    "candidateBarBackground": "#ffffff",
    "candidateBarBorder": "#dddddd",
    "candidateBarBorderWidth": 0.5,
    "candidateText": "#000000",
    "candidateAnnotationText": "#666666",
    "candidateSelectedBackground": "#007bff",
    "candidateSelectedText": "#ffffff",
    "candidateSelectedBorder": "#0056b3",
    "candidateSelectedBorderWidth": 1.0,
    "candidateSeparator": "#eeeeee",
    
    "keyFontSize": 18.0,
    "keyFontWeight": "regular",
    "modifierKeyFontSize": 16.0,
    "modifierKeyFontWeight": "medium",
    "candidateFontSize": 18.0,
    "candidateFontWeight": "regular",
    "candidateAnnotationFontSize": 14.0,
    
    "keySpacing": 3.0,
    "rowSpacing": 6.0
  },
  
  "dark": {
    "keyboardBackground": "#000000",
    "regularKeyBackground": "#2a2a2a",
    "regularKeyText": "#ffffff",
    "regularKeyBorder": "#444444",
    "regularKeyBorderWidth": 1.0,
    "regularKeyCornerRadius": 6.0,
    
    "modifierKeyBackground": "#3a3a3a",
    "modifierKeyText": "#ffffff",
    "modifierKeyBorder": "#555555",
    "modifierKeyBorderWidth": 1.0,
    "modifierKeyCornerRadius": 6.0,
    
    "pressedKeyBackground": "#555555",
    "pressedKeyText": "#ffffff",
    
    "candidateBarBackground": "#1a1a1a",
    "candidateBarBorder": "#333333",
    "candidateBarBorderWidth": 0.5,
    "candidateText": "#ffffff",
    "candidateAnnotationText": "#999999",
    "candidateSelectedBackground": "#007bff",
    "candidateSelectedText": "#ffffff",
    "candidateSelectedBorder": "#0056b3",
    "candidateSelectedBorderWidth": 1.0,
    "candidateSeparator": "#333333",
    
    "keyFontSize": 18.0,
    "keyFontWeight": "regular",
    "modifierKeyFontSize": 16.0,
    "modifierKeyFontWeight": "medium",
    "candidateFontSize": 18.0,
    "candidateFontWeight": "regular",
    "candidateAnnotationFontSize": 14.0,
    
    "keySpacing": 3.0,
    "rowSpacing": 6.0
  }
}
```

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 17, 2025 | Android Development Team | Initial implementation guide |

---

**End of Document 5: Android Theme Implementation Guide**

---

## Summary of All 5 Documents

You now have complete documentation for:

1. **Theme System Architecture & Overview** - High-level design, user flows, business rules
2. **Theme JSON Schema Specification** - Complete JSON format and field definitions
3. **iOS Theme Editor Specification** - Detailed SwiftUI editor implementation
4. **iOS Theme Store & Backend API Specification** - Store UI and PHP/MySQL backend
5. **Android Theme Implementation Guide** - GradientDrawable approach with minimal refactoring

These documents provide a complete blueprint for implementing the cross-platform keyboard theme system for both iOS and Android, with a shared JSON format, curated theme store, and clear separation between free and Pro user features.
---