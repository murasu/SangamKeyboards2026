# iOS Theme Editor Specification

**Project:** Sangam Keyboards - Cross-Platform Theme System  
**Version:** 1.0  
**Date:** October 17, 2025  
**Platform:** iOS 14.0+  
**Framework:** SwiftUI  
**Document:** 3 of 5

## Table of Contents
1. Overview
2. User Experience Flow
3. Screen Layout & Components
4. Theme Editor UI Specification
5. Live Preview Implementation
6. Color Picker Design
7. Metadata Editor
8. Theme Management
9. State Management
10. Accessibility
11. Error Handling
12. Performance Considerations

---

## 1. Overview

### Purpose
The Theme Editor is a SwiftUI-based interface that allows users to create and customize keyboard themes with real-time preview. The editor must be intuitive, delightful to use, and work seamlessly on iPhone in portrait orientation.

### Key Features
- **Live Preview:** Changes reflected immediately in keyboard preview
- **Single-Screen Design:** All editing on one screen, no master-detail navigation
- **Accordion Expansion:** Sections expand inline when tapped
- **Color Presets:** Quick color selection with custom picker option
- **Undo/Redo Support:** Track changes for easy reversal
- **Pro Features Gated:** Export/upload restricted to Pro users
- **Metadata Management:** Theme name, description, author info

### Design Principles
- **Immediate Feedback:** No delay between adjustment and preview update
- **Progressive Disclosure:** Show controls only when needed (accordion style)
- **Visual Hierarchy:** Clear separation between preview and editor
- **Touch-Friendly:** All controls easily tappable (44pt minimum)
- **Consistent Styling:** Follow iOS Human Interface Guidelines

---

## 2. User Experience Flow

### Entry Points

```
┌─────────────────────────────────────┐
│     Main App Navigation             │
├─────────────────────────────────────┤
│  • Settings > Themes > Create New   │
│  • Themes List > + Button           │
│  • Theme Store > Duplicate Theme    │
│  • Quick Action: Create Theme       │
└─────────────────────────────────────┘
```

### Flow Diagram

```
Start
  │
  ├─ Create New Theme
  │   └─> Template Selection (System, Blank, Duplicate)
  │        └─> Theme Editor
  │
  ├─ Edit Existing Theme
  │   └─> Theme Editor (pre-loaded)
  │
  └─> Theme Editor
       │
       ├─ Edit Properties
       │   └─> Live Preview Updates
       │
       ├─ Save Locally (All Users)
       │   └─> Success Message
       │
       ├─ Share (Pro Only)
       │   └─> iOS Share Sheet
       │        └─> AirDrop, Messages, Files, etc.
       │
       └─ Upload to Store (Pro Only)
           └─> Metadata Validation
                └─> Upload to Server
                     └─> Pending Approval Message
```

### User Journey

**New User (Free):**
1. Opens app, navigates to Themes
2. Taps "Create New Theme"
3. Selects starting template
4. Edits colors, fonts, spacing
5. Sees live preview of changes
6. Taps "Save" → Theme saved locally
7. Can use theme in keyboard
8. Sees disabled "Share" and "Upload" buttons (with Pro badge)

**Pro User:**
1-6. Same as Free User
7. Can tap "Share" → Export theme file
8. Can tap "Upload to Store" → Submit for approval
9. Receives notification when approved/rejected

---

## 3. Screen Layout & Components

### Overall Layout (iPhone Portrait)

```
┌─────────────────────────────────────────┐
│  ← Theme Editor        Save    ⋮ (Menu) │ ← Navigation Bar
├─────────────────────────────────────────┤
│                                         │
│         Live Keyboard Preview           │ ← 35% of screen
│      (Shows current theme applied)      │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ▼ Theme Info                    │   │ ← Accordion Section
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ ▶ Regular Keys                  │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ ▶ Modifier Keys                 │   │ ← Scrollable Editor
│  └─────────────────────────────────┘   │   (65% of screen)
│  ┌─────────────────────────────────┐   │
│  │ ▶ Pressed State                 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ ▶ Keyboard Background           │   │
│  └─────────────────────────────────┘   │
│                  ⋮                      │
│                                         │
└─────────────────────────────────────────┘
```

### Navigation Bar Actions

**Left Side:**
- Back button ("← Theme Editor" or "← Themes")

**Right Side:**
- "Save" button (always visible)
- "⋮" Menu button:
  - Save & Apply
  - Share (Pro only, dimmed if Free)
  - Upload to Store (Pro only, dimmed if Free)
  - Duplicate Theme
  - Reset to Defaults
  - Delete Theme (if editing existing)

**Title:**
- "Theme Editor" or theme name if editing existing

### Preview Section (Top 35%)

**Fixed Area (Non-scrollable):**
```
┌───────────────────────────────────────┐
│  ┌─────────────────────────────────┐ │
│  │   [Candidate Bar Preview]       │ │
│  ├─────────────────────────────────┤ │
│  │  Q  W  E  R  T  Y  U  I  O  P  │ │
│  │   A  S  D  F  G  H  J  K  L    │ │
│  │    Z  X  C  V  B  N  M   ⌫     │ │
│  │  123  🌐  [____space____]  ↵   │ │
│  └─────────────────────────────────┘ │
│                                       │
│  Light │ Dark     (Mode Toggle)      │
└───────────────────────────────────────┘
```

**Features:**
- Real-time theme preview
- Functional keyboard (can tap keys to see pressed state)
- Toggle between light/dark mode
- Shows all key types (regular, modifier, spacebar)
- Shows candidate bar if enabled
- Scaled to fit (maintains aspect ratio)

### Editor Section (Bottom 65%)

**Scrollable List of Accordion Sections:**

1. **Theme Info** (Default expanded on new theme)
2. **Regular Keys**
3. **Modifier Keys**
4. **Pressed State**
5. **Keyboard Background**
6. **Key Preview Popup** (iOS only features)
7. **Long Press Popup** (iOS only features)
8. **Candidate Bar**
9. **Typography**
10. **Spacing & Layout**

---

## 4. Theme Editor UI Specification

### Accordion Section Component

**Collapsed State:**
```
┌─────────────────────────────────────┐
│ ▶ Regular Keys              [⚪]    │ ← Color preview circle
└─────────────────────────────────────┘
```

**Expanded State:**
```
┌─────────────────────────────────────┐
│ ▼ Regular Keys                      │
├─────────────────────────────────────┤
│                                     │
│  Background Color                   │
│  [Color Picker UI]                  │
│                                     │
│  Text Color                         │
│  [Color Picker UI]                  │
│                                     │
│  Border                             │
│  [Color Picker UI]                  │
│  [Border Width Slider]              │
│                                     │
│  Corner Radius                      │
│  [Slider with value]                │
│                                     │
└─────────────────────────────────────┘
```

**SwiftUI Structure:**
```swift
struct AccordionSection: View {
    let title: String
    let icon: String?
    @Binding var isExpanded: Bool
    let content: () -> AnyView
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { 
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            
            // Content
            if isExpanded {
                content()
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

**Behavior:**
- Tap header to expand/collapse
- Smooth spring animation
- Only one section expanded at a time (optional: allow multiple)
- Scroll to section when expanded to ensure it's visible
- Haptic feedback on tap

### Section 1: Theme Info

**Fields:**
```
Theme Name *
┌─────────────────────────────────────┐
│ Neon Dreams                         │
└─────────────────────────────────────┘

Description
┌─────────────────────────────────────┐
│ A vibrant neon-inspired keyboard   │
│ theme with glowing effects          │
│                                     │
└─────────────────────────────────────┘
Character count: 58/200

Author
┌─────────────────────────────────────┐
│ Murasu Systems                      │
└─────────────────────────────────────┘

Tags (tap to add)
┌─────────────────────────────────────┐
│ [ neon ] [ colorful ] [ modern ]    │
│ [ + Add Tag ]                       │
└─────────────────────────────────────┘
```

**Validation:**
- Name: Required, 3-50 characters
- Description: Optional, 10-200 characters
- Author: Auto-filled from user profile, editable
- Tags: Max 10, each max 20 characters
- Real-time character count
- Error states for invalid input

**SwiftUI Component:**
```swift
struct ThemeInfoSection: View {
    @Binding var theme: ThemeConfig
    @State private var nameError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Theme Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Theme Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter theme name", text: $theme.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: theme.name) { newValue in
                        validateName(newValue)
                    }
                
                if let error = nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(theme.description.count)/200")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                TextEditor(text: $theme.description)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Author
            VStack(alignment: .leading, spacing: 4) {
                Text("Author")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Author name", text: $theme.author)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Tags
            TagsEditor(tags: $theme.tags)
        }
    }
    
    private func validateName(_ name: String) {
        if name.count < 3 {
            nameError = "Name must be at least 3 characters"
        } else if name.count > 50 {
            nameError = "Name must be 50 characters or less"
        } else {
            nameError = nil
        }
    }
}
```

### Section 2-4: Key Styling Sections

**Example: Regular Keys Section**

```
Background Color
┌─────────────────────────────────────┐
│ [Horizontal scrolling color chips]  │
│ ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ [+]           │
└─────────────────────────────────────┘

Text Color
┌─────────────────────────────────────┐
│ [Horizontal scrolling color chips]  │
│ ⚫ ⚪ 🔴 🟠 🟡 🟢 🔵 [+]           │
└─────────────────────────────────────┘

Border
┌─────────────────────────────────────┐
│ Color: [color chips]                │
│ Width: ─────●──── 1.0 pt           │
└─────────────────────────────────────┘

Corner Radius
─────────●──────── 6.0 pt
[Preview of rounded corners]

Shadow (iOS only)
┌─────────────────────────────────────┐
│ Color: [color chips with alpha]     │
│ Blur:   ──────●─── 2.0 pt          │
│ Offset: ───●────── (0, 1)          │
└─────────────────────────────────────┘
```

**Features:**
- Horizontal scrolling color palette
- Preset colors (common + recent + custom)
- "+" button opens full color picker
- Sliders show current value
- Real-time preview updates
- Grouped related properties

### Section 5: Keyboard Background

**With Gradient Support:**

```
Background Type
( ) Solid Color    (●) Gradient

Gradient Colors
┌─────────────────────────────────────┐
│  ⚪────⚪────⚪  [+ Add Stop]        │
│  Tap to edit • Drag to reorder      │
└─────────────────────────────────────┘

Direction
┌─────────────────────────────────────┐
│  [↓]  [→]  [↘]  [↙]               │
│ Vert. Horiz. Diag1 Diag2            │
└─────────────────────────────────────┘

Preview
┌─────────────────────────────────────┐
│  [Live gradient preview bar]        │
└─────────────────────────────────────┘
```

**Gradient Editor Features:**
- Visual gradient bar showing current gradient
- Tap color stop to edit color
- Drag color stop to reposition
- Tap between stops to add new stop
- Long press stop to delete (min 2 stops)
- Direction selector with visual icons
- Live preview updates

**SwiftUI Component:**
```swift
struct GradientEditor: View {
    @Binding var colors: [Color]
    @Binding var direction: GradientDirection
    @State private var selectedStopIndex: Int?
    
    var body: some View {
        VStack(spacing: 16) {
            // Background Type Toggle
            Picker("Background Type", selection: $backgroundType) {
                Text("Solid Color").tag(BackgroundType.solid)
                Text("Gradient").tag(BackgroundType.gradient)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if backgroundType == .gradient {
                // Gradient stops editor
                GradientStopsEditor(
                    colors: $colors,
                    selectedIndex: $selectedStopIndex
                )
                
                // Direction picker
                GradientDirectionPicker(direction: $direction)
                
                // Live preview
                GradientPreview(colors: colors, direction: direction)
                    .frame(height: 60)
                    .cornerRadius(8)
            } else {
                // Single color picker
                ColorPickerRow(
                    title: "Background Color",
                    color: $solidColor
                )
            }
        }
    }
}
```

### Section 6-7: Preview & Popup (iOS Only)

**Clearly Marked as iOS-Only:**

```
┌─────────────────────────────────────┐
│ ▶ Key Preview Popup                 │
│                           [iOS Only] │
└─────────────────────────────────────┘
```

**When Expanded:**
```
Key Preview Popup                iOS Only
─────────────────────────────────────

These settings only affect iOS keyboards.
Android uses system-default popups.

Background Color
[Color picker]

Text Color
[Color picker]

Border
[Color picker + width slider]

Corner Radius
[Slider]

Shadow
[Color + blur + offset]
```

**Badge Component:**
```swift
struct PlatformBadge: View {
    let platform: String
    
    var body: some View {
        Text(platform)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}
```

### Section 8: Candidate Bar

```
Enable Candidate Bar
[Toggle Switch] ─ ON

Background Color
[Color picker]

Border
[Color picker + width slider]

Text Color
[Color picker]

Selected Background
[Color picker]

Selected Text Color
[Color picker]

Separator Color
[Color picker]

Annotation Text (for languages like Tamil)
[Color picker]
[Font size slider]
```

### Section 9: Typography

```
Key Font Size
─────────●──────── 18.0 pt
Preview: Aa

Key Font Weight
[● Regular]  [ Medium ]  [ Bold ]

Modifier Key Font Size
─────────●──────── 16.0 pt
Preview: 123

Modifier Font Weight
[ Regular ]  [● Medium ]  [ Bold ]

Candidate Font Size
─────────●──────── 18.0 pt
```

**Font Weight Picker:**
```swift
struct FontWeightPicker: View {
    @Binding var weight: Font.Weight
    let weights: [Font.Weight] = [
        .light, .regular, .medium, .semibold, .bold
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(weights, id: \.self) { w in
                    FontWeightChip(
                        weight: w,
                        isSelected: weight == w,
                        action: { weight = w }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}
```

### Section 10: Spacing & Layout

```
Key Spacing
─────●───────────── 3.0 pt
Gap between keys

Row Spacing
──────●──────────── 6.0 pt
Gap between rows

Visual Preview
┌────┐  ┌────┐  ┌────┐  ← Key Spacing
│ Q  │  │ W  │  │ E  │
└────┘  └────┘  └────┘
  ↕ Row Spacing
┌────┐  ┌────┐  ┌────┐
│ A  │  │ S  │  │ D  │
└────┘  └────┘  └────┘
```

**Interactive Visual:**
- Drag spacing to adjust visually
- Slider shows numeric value
- Diagram updates in real-time

---

## 5. Live Preview Implementation

### Preview Component Architecture

```swift
struct LiveKeyboardPreview: View {
    @ObservedObject var themeManager: ThemeManager
    @State private var mode: ColorScheme = .light
    @State private var pressedKey: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle
            Picker("Mode", selection: $mode) {
                Text("Light").tag(ColorScheme.light)
                Text("Dark").tag(ColorScheme.dark)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Keyboard preview
            KeyboardPreviewView(
                theme: currentTheme,
                pressedKey: $pressedKey
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(contentMode: .fit)
            .padding()
        }
        .background(currentTheme.keyboardBackground)
        .environment(\.colorScheme, mode)
    }
    
    var currentTheme: ThemeVariant {
        mode == .light ? themeManager.theme.light : themeManager.theme.dark
    }
}
```

### Preview Update Strategy

**Debouncing for Performance:**
```swift
class ThemeManager: ObservableObject {
    @Published var theme: ThemeConfig {
        didSet {
            // Debounce preview updates
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: false
            ) { [weak self] _ in
                self?.updatePreview()
            }
        }
    }
    
    private var debounceTimer: Timer?
    
    private func updatePreview() {
        // Update preview with current theme
        NotificationCenter.default.post(
            name: .themeDidUpdate,
            object: theme
        )
    }
}
```

**Update Only Changed Properties:**
```swift
struct KeyView: View {
    let key: KeyModel
    let theme: ThemeVariant
    @State private var isPressed = false
    
    var body: some View {
        Text(key.label)
            .font(.system(size: theme.keyFontSize, weight: theme.keyFontWeight))
            .foregroundColor(isPressed ? theme.pressedKeyText : theme.regularKeyText)
            .frame(width: key.width, height: key.height)
            .background(
                RoundedRectangle(cornerRadius: theme.regularKeyCornerRadius)
                    .fill(isPressed ? theme.pressedKeyBackground : theme.regularKeyBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.regularKeyCornerRadius)
                    .stroke(theme.regularKeyBorder, lineWidth: theme.regularKeyBorderWidth)
            )
            .scaleEffect(isPressed ? theme.pressedKeyScale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}
```

### Interactive Preview

**Allow Key Presses in Preview:**
```swift
struct InteractiveKeyboardPreview: View {
    @Binding var pressedKey: String?
    let theme: ThemeVariant
    
    var body: some View {
        // Keyboard layout
        VStack(spacing: theme.rowSpacing) {
            ForEach(keyboardRows) { row in
                HStack(spacing: theme.keySpacing) {
                    ForEach(row.keys) { key in
                        KeyButton(
                            key: key,
                            theme: theme,
                            isPressed: pressedKey == key.id,
                            onPress: { pressedKey = key.id },
                            onRelease: { pressedKey = nil }
                        )
                    }
                }
            }
        }
    }
}
```

**Benefits:**
- User can test pressed state
- See animations and transitions
- Verify touch targets
- Check color contrast in action

---

## 6. Color Picker Design

### Horizontal Color Palette

```
┌──────────────────────────────────────────┐
│  ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ [+]          │
│ ←                                    →   │
└──────────────────────────────────────────┘
```

**Features:**
- Horizontal scroll view
- 30-40pt color circles
- Checkmark on selected color
- Preset colors (black, white, grays, primary colors)
- Recent colors (auto-populated)
- "+" button for custom color picker
- Smooth scrolling with haptic feedback

**SwiftUI Implementation:**
```swift
struct ColorPaletteRow: View {
    @Binding var selectedColor: Color
    let presetColors: [Color]
    @State private var recentColors: [Color] = []
    @State private var showingCustomPicker = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Preset colors
                ForEach(presetColors, id: \.self) { color in
                    ColorCircle(
                        color: color,
                        isSelected: color == selectedColor,
                        action: {
                            selectedColor = color
                            addToRecents(color)
                            hapticFeedback()
                        }
                    )
                }
                
                // Recent colors
                if !recentColors.isEmpty {
                    Divider()
                        .frame(height: 30)
                    
                    ForEach(recentColors, id: \.self) { color in
                        ColorCircle(
                            color: color,
                            isSelected: color == selectedColor,
                            action: {
                                selectedColor = color
                                hapticFeedback()
                            }
                        )
                    }
                }
                
                // Custom picker button
                Button(action: { showingCustomPicker = true }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.gray, lineWidth: 2)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingCustomPicker) {
            CustomColorPicker(selectedColor: $selectedColor)
        }
    }
    
    private func addToRecents(_ color: Color) {
        recentColors.removeAll { $0 == color }
        recentColors.insert(color, at: 0)
        if recentColors.count > 8 {
            recentColors.removeLast()
        }
        // Save to UserDefaults
        saveRecentColors()
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
```

### Color Circle Component

```swift
struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                
                // Border for light colors
                Circle()
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 40, height: 40)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### Custom Color Picker Modal

```
┌──────────────────────────────────────┐
│  Custom Color                    Done │
├──────────────────────────────────────┤
│                                      │
│      [iOS Native ColorPicker]        │
│                                      │
│  Hex Input                           │
│  ┌──────────────────────────────┐   │
│  │ #FF5733                      │   │
│  └──────────────────────────────┘   │
│                                      │
│  Recently Used                       │
│  ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ ⚪ ⚪           │
│                                      │
└──────────────────────────────────────┘
```

**SwiftUI Implementation:**
```swift
struct CustomColorPicker: View {
    @Binding var selectedColor: Color
    @State private var hexInput: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Native color picker
                ColorPicker("Select Color", selection: $selectedColor)
                    .padding()
                
                // Hex input
                VStack(alignment: .leading) {
                    Text("Hex Color")
                        .font(.headline)
                    
                    HStack {
                        TextField("#RRGGBB", text: $hexInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .onChange(of: hexInput) { newValue in
                                if let color = Color(hex: newValue) {
                                    selectedColor = color
                                }
                            }
                        
                        Button("Apply") {
                            if let color = Color(hex: hexInput) {
                                selectedColor = color
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                hexInput = selectedColor.toHex()
            }
        }
    }
}
```

### Preset Color Palettes

**Predefined Color Sets:**
```swift
struct ColorPresets {
    static let basics: [Color] = [
        .black, .white,
        Color(hex: "#333333"), Color(hex: "#666666"),
        Color(hex: "#999999"), Color(hex: "#CCCCCC")
    ]
    
    static let vibrant: [Color] = [
        .red, .orange, .yellow, .green,
        .blue, .purple, .pink
    ]
    
    static let pastels: [Color] = [
        Color(hex: "#FFB3BA"), Color(hex: "#FFDFBA"),
        Color(hex: "#FFFFBA"), Color(hex: "#BAFFC9"),
        Color(hex: "#BAE1FF"), Color(hex: "#D4BAFF")
    ]
    
    static let neon: [Color] = [
        Color(hex: "#FF00FF"), Color(hex: "#00FFFF"),
        Color(hex: "#FF00AA"), Color(hex: "#00FF88"),
        Color(hex: "#FF6600"), Color(hex: "#8800FF")
    ]
}
```

---

## 7. Metadata Editor

### Tags Editor Component

```
Tags
┌──────────────────────────────────────┐
│  [  neon  ×] [colorful ×] [modern ×] │
│                                      │
│  + Add Tag                           │
└──────────────────────────────────────┘

Popular Tags (tap to add)
[ dark ] [ light ] [ minimal ] [ colorful ]
[ professional ] [ playful ] [ elegant ]
```

**SwiftUI Implementation:**
```swift
struct TagsEditor: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""
    @State private var showingAddTag: Bool = false
    
    let maxTags = 10
    let popularTags = [
        "dark", "light", "minimal", "colorful",
        "professional", "playful", "elegant", "modern",
        "classic", "bold", "subtle", "vibrant"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags (\(tags.count)/\(maxTags))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Current tags
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(
                        text: tag,
                        onRemove: { removeTag(tag) }
                    )
                }
                
                // Add tag button
                if tags.count < maxTags {
                    Button(action: { showingAddTag = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Tag")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Popular tags
            if tags.count < maxTags {
                Text("Popular Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                FlowLayout(spacing: 8) {
                    ForEach(popularTags.filter { !tags.contains($0) }, id: \.self) { tag in
                        Button(action: { addTag(tag) }) {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .alert("Add Tag", isPresented: $showingAddTag) {
            TextField("Tag name", text: $newTag)
                .autocapitalization(.none)
            
            Button("Cancel", role: .cancel) {
                newTag = ""
            }
            
            Button("Add") {
                addTag(newTag)
                newTag = ""
            }
        }
    }
    
    private func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty,
              !tags.contains(trimmed),
              tags.count < maxTags,
              trimmed.count <= 20 else { return }
        tags.append(trimmed)
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

struct TagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}
```

---

## 8. Theme Management

### Save Actions

**Save Button (Always Visible):**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Save") {
            saveTheme()
        }
        .disabled(!isValid)
    }
}

private func saveTheme() {
    do {
        try themeManager.saveTheme(theme)
        showSuccessMessage("Theme saved successfully")
        
        // Optional: Apply immediately
        if applyOnSave {
            themeManager.applyTheme(theme)
        }
    } catch {
        showErrorAlert(error)
    }
}
```

### Menu Actions

**SwiftUI Menu:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button(action: saveAndApply) {
                Label("Save & Apply", systemImage: "checkmark.circle")
            }
            
            Divider()
            
            Button(action: shareTheme) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(!userManager.isPro)
            
            Button(action: uploadToStore) {
                Label("Upload to Store", systemImage: "arrow.up.doc")
            }
            .disabled(!userManager.isPro)
            
            Divider()
            
            Button(action: duplicateTheme) {
                Label("Duplicate Theme", systemImage: "doc.on.doc")
            }
            
            Button(action: resetToDefaults) {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
            }
            
            if isEditingExisting {
                Divider()
                
                Button(role: .destructive, action: deleteTheme) {
                    Label("Delete Theme", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

### Share Theme (Pro Only)

```swift
private func shareTheme() {
    guard userManager.isPro else {
        showProUpgradeAlert(feature: "Share themes")
        return
    }
    
    do {
        let themeJSON = try theme.toJSON()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(theme.id).theme")
        
        try themeJSON.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        // Present share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    } catch {
        showErrorAlert(error)
    }
}
```

### Upload to Store (Pro Only)

```swift
private func uploadToStore() {
    guard userManager.isPro else {
        showProUpgradeAlert(feature: "Upload themes to store")
        return
    }
    
    // Validate theme
    let validation = theme.validate()
    guard validation.isValid else {
        showValidationErrors(validation.errors)
        return
    }
    
    // Show confirmation
    showUploadConfirmation { confirmed in
        guard confirmed else { return }
        
        Task {
            do {
                isUploading = true
                try await apiClient.uploadTheme(theme)
                showSuccessMessage(
                    "Theme uploaded successfully! " +
                    "It will be reviewed and published soon."
                )
            } catch {
                showErrorAlert(error)
            }
            isUploading = false
        }
    }
}
```

### Duplicate Theme

```swift
private func duplicateTheme() {
    var duplicate = theme
    duplicate.id = "\(theme.id)_copy_\(UUID().uuidString.prefix(8))"
    duplicate.name = "\(theme.name) (Copy)"
    duplicate.version = "1.0"
    duplicate.createdAt = Date()
    
    // Navigate to editor with duplicate
    coordinator.push(.themeEditor(theme: duplicate, mode: .create))
}
```

### Delete Theme

```swift
private func deleteTheme() {
    showDeleteConfirmation { confirmed in
        guard confirmed else { return }
        
        do {
            try themeManager.deleteTheme(theme.id)
            coordinator.pop()
            showSuccessMessage("Theme deleted")
        } catch {
            showErrorAlert(error)
        }
    }
}
```

---

## 9. State Management

### Theme Manager (ObservableObject)

```swift
@MainActor
class ThemeManager: ObservableObject {
    @Published var theme: ThemeConfig
    @Published var isDirty: Bool = false
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    private var undoStack: [ThemeConfig] = []
    private var redoStack: [ThemeConfig] = []
    private let maxUndoSteps = 50
    
    init(theme: ThemeConfig) {
        self.theme = theme
    }
    
    func updateTheme(_ newTheme: ThemeConfig) {
        // Push current state to undo stack
        undoStack.append(theme)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        // Clear redo stack on new change
        redoStack.removeAll()
        
        // Update theme
        theme = newTheme
        isDirty = true
        canUndo = !undoStack.isEmpty
        canRedo = false
    }
    
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(theme)
        theme = previous
        canUndo = !undoStack.isEmpty
        canRedo = true
    }
    
    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(theme)
        theme = next
        canUndo = true
        canRedo = !redoStack.isEmpty
    }
    
    func saveTheme() throws {
        try ThemeStorage.shared.save(theme)
        isDirty = false
    }
    
    func resetDirtyFlag() {
        isDirty = false
    }
}
```

### Unsaved Changes Warning

```swift
struct ThemeEditorView: View {
    @StateObject private var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingUnsavedChangesAlert = false
    
    var body: some View {
        // ... editor content
        .navigationBarBackButtonHidden(themeManager.isDirty)
        .toolbar {
            if themeManager.isDirty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        showingUnsavedChangesAlert = true
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Discard", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
            
            Button("Save") {
                saveTheme()
                presentationMode.wrappedValue.dismiss()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Do you want to save before leaving?")
        }
    }
}
```

### Auto-Save Draft

```swift
class DraftManager {
    private let draftKey = "theme_editor_draft"
    private var saveTimer: Timer?
    
    func startAutoSave(themeManager: ThemeManager) {
        saveTimer = Timer.scheduledTimer(
            withTimeInterval: 30.0,
            repeats: true
        ) { [weak self, weak themeManager] _ in
            guard let theme = themeManager?.theme else { return }
            self?.saveDraft(theme)
        }
    }
    
    func stopAutoSave() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
    
    private func saveDraft(_ theme: ThemeConfig) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(theme)
            UserDefaults.standard.set(data, forKey: draftKey)
        } catch {
            print("Failed to save draft: \(error)")
        }
    }
    
    func loadDraft() -> ThemeConfig? {
        guard let data = UserDefaults.standard.data(forKey: draftKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ThemeConfig.self, from: data)
        } catch {
            print("Failed to load draft: \(error)")
            return nil
        }
    }
    
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
    }
}
```

---

## 10. Accessibility

### VoiceOver Support

```swift
struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let colorName: String
    
    var body: some View {
        Button(action: action) {
            // ... visual content
        }
        .accessibilityLabel(colorName)
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

### Dynamic Type Support

```swift
struct ThemeEditorView: View {
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        ScrollView {
            VStack(spacing: dynamicSpacing) {
                // Content adapts to text size
            }
        }
    }
    
    var dynamicSpacing: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            return 12
        case .large, .extraLarge:
            return 16
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 20
        default:
            return 16
        }
    }
}
```

### Reduce Motion

```swift
struct KeyView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        // ... key content
        .animation(
            reduceMotion ? .none : .spring(),
            value: isPressed
        )
    }
}
```

### Contrast Validation

```swift
func validateContrast() -> [String] {
    var warnings: [String] = []
    
    let textBgRatio = calculateContrastRatio(
        theme.regularKeyText,
        theme.regularKeyBackground
    )
    
    if textBgRatio < 4.5 {
        warnings.append(
            "Text and background contrast is too low (\(String(format: "%.1f", textBgRatio)):1). " +
            "Minimum recommended is 4.5:1 for accessibility."
        )
    }
    
    return warnings
}
```

---

## 11. Error Handling

### Validation Errors

```swift
struct ValidationError: Identifiable {
    let id = UUID()
    let field: String
    let message: String
}

class ThemeValidator {
    func validate(_ theme: ThemeConfig) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Name validation
        if theme.name.count < 3 {
            errors.append(ValidationError(
                field: "name",
                message: "Theme name must be at least 3 characters"
            ))
        }
        
        // Description validation
        if let desc = theme.description, desc.count < 10 {
            errors.append(ValidationError(
                field: "description",
                message: "Description must be at least 10 characters"
            ))
        }
        
        // Color validation
        if !isValidHex(theme.light.regularKeyBackground) {
            errors.append(ValidationError(
                field: "regularKeyBackground",
                message: "Invalid color format"
            ))
        }
        
        // Contrast validation
        let ratio = calculateContrastRatio(
            theme.light.regularKeyText,
            theme.light.regularKeyBackground
        )
        if ratio < 3.0 {
            errors.append(ValidationError(
                field: "regularKeyText",
                message: "Insufficient contrast ratio: \(String(format: "%.1f", ratio)):1"
            ))
        }
        
        return errors
    }
}
```

### Error Display

```swift
struct ThemeEditorView: View {
    @State private var validationErrors: [ValidationError] = []
    
    var body: some View {
        VStack {
            if !validationErrors.isEmpty {
                ValidationErrorBanner(errors: validationErrors)
            }
            
            // ... rest of content
        }
    }
}

struct ValidationErrorBanner: View {
    let errors: [ValidationError]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Please fix the following issues:")
                    .font(.headline)
            }
            
            ForEach(errors) { error in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.field)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(error.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
}
```

### Network Errors

```swift
enum ThemeUploadError: LocalizedError {
    case networkError
    case serverError(String)
    case validationError([String])
    case unauthorized
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to server. Please check your internet connection."
        case .serverError(let message):
            return "Server error: \(message)"
        case .validationError(let errors):
            return "Theme validation failed:\n" + errors.joined(separator: "\n")
        case .unauthorized:
            return "You must be a Pro user to upload themes."
        case .fileTooLarge:
            return "Theme file exceeds 50KB limit."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please try again when you have a stable internet connection."
        case .unauthorized:
            return "Upgrade to Pro to unlock theme uploading."
        case .fileTooLarge:
            return "Try reducing the number of gradient stops or removing unused properties."
        default:
            return nil
        }
    }
}
```

---

## 12. Performance Considerations

### Lazy Loading

```swift
struct ThemeEditorView: View {
    @State private var expandedSection: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sections) { section in
                    AccordionSection(
                        title: section.title,
                        isExpanded: expandedSection == section.id
                    ) {
                        // Content only rendered when expanded
                        section.content()
                    }
                }
            }
        }
    }
}
```

### Preview Optimization

```swift
class PreviewRenderer {
    private var renderCache: [String: UIImage] = [:]
    
    func render(theme: ThemeVariant) -> UIImage {
        let cacheKey = theme.cacheKey
        
        if let cached = renderCache[cacheKey] {
            return cached
        }
        
        let image = generateKeyboardImage(theme: theme)
        renderCache[cacheKey] = image
        
        // Limit cache size
        if renderCache.count > 10 {
            renderCache.removeValue(forKey: renderCache.keys.first!)
        }
        
        return image
    }
}
```

### Debouncing Updates

```swift
class ThemeUpdateDebouncer {
    private var updateTimer: Timer?
    private let delay: TimeInterval = 0.15
    
    func debounce(action: @escaping () -> Void) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false
        ) { _ in
            action()
        }
    }
}

// Usage
struct ColorSlider: View {
    @Binding var value: Double
    let onUpdate: (Double) -> Void
    private let debouncer = ThemeUpdateDebouncer()
    
    var body: some View {
        Slider(value: $value, in: 0...1)
            .onChange(of: value) { newValue in
                debouncer.debounce {
                    onUpdate(newValue)
                }
            }
    }
}
```

### Memory Management

```swift
class ThemeEditorCoordinator: ObservableObject {
    @Published var currentTheme: ThemeConfig?
    
    func cleanup() {
        currentTheme = nil
        // Clear caches
        ImageCache.shared.clear()
        PreviewRenderer.shared.clearCache()
    }
    
    deinit {
        cleanup()
    }
}
```

---

## Appendix A: SwiftUI Component Library

### Reusable Components

**SliderWithValue:**
```swift
struct SliderWithValue: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(
                value: $value,
                in: range,
                step: step
            )
            .accentColor(.blue)
        }
    }
}
```

**ColorPickerRow:**
```swift
struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    let presets: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ColorPaletteRow(
                selectedColor: $color,
                presetColors: presets
            )
        }
    }
}
```

**SectionHeader:**
```swift
struct SectionHeader: View {
    let title: String
    let badge: String?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            if let badge = badge {
                PlatformBadge(platform: badge)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
```

---

## Appendix B: Animation Guidelines

### Standard Animations

```swift
extension Animation {
    static let themeEditor = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0
    )
    
    static let accordionExpand = Animation.easeInOut(duration: 0.25)
    
    static let colorChange = Animation.easeOut(duration: 0.2)
}
```

### Usage

```swift
.animation(.themeEditor, value: isExpanded)
.animation(.colorChange, value: selectedColor)
```

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 17, 2025 | UX Team | Initial specification |

---

**End of Document 3: iOS Theme Editor Specification**

---

This is document 3 of 5. Should I proceed with document 4 (iOS Theme Store & Backend API Specification)?