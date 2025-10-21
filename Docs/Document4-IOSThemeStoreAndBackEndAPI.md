# iOS Theme Store & Backend API Specification

**Project:** Sangam Keyboards - Cross-Platform Theme System  
**Version:** 1.0  
**Date:** October 17, 2025  
**Platform:** iOS 14.0+ | Backend: PHP + MySQL  
**Document:** 4 of 5

## Table of Contents
1. Overview
2. Theme Store UI Specification
3. Store Navigation & Flow
4. Theme Browse Interface
5. Theme Detail View
6. My Themes Section
7. Search & Filters
8. Backend API Specification
9. Database Schema
10. Admin Panel
11. Authentication & Authorization
12. Error Handling & Edge Cases

---

## 1. Overview

### Purpose
The Theme Store is a curated marketplace where Pro users can browse, download, and manage keyboard themes. All themes are manually approved to ensure quality. The backend API provides theme storage, retrieval, and management capabilities.

### Key Features
- **Pro-Only Access:** Only Pro subscribers can access the store
- **Curated Content:** All themes manually approved by admin
- **Download Tracking:** Track theme popularity via download counts
- **Creator Dashboard:** "My Themes" section for theme creators
- **Search & Filter:** Find themes by name, tags, popularity
- **Seamless Integration:** Direct download and apply to keyboard

### User Roles
- **Free Users:** Cannot access store at all
- **Pro Users:** Browse, download, upload themes
- **Admin:** Review and approve/reject themes

---

## 2. Theme Store UI Specification

### Store Entry Points

```
Main App Navigation
├─ Settings
│  └─ Themes
│     ├─ Theme Store (Pro badge)
│     ├─ My Themes
│     └─ Downloaded Themes
│
├─ Tab Bar (if applicable)
│  └─ Store Tab (Pro badge)
│
└─ Quick Actions
   └─ Browse Themes
```

### Overall Store Layout

```
┌─────────────────────────────────────┐
│  ← Store                  🔍  ⋮     │ ← Navigation
├─────────────────────────────────────┤
│                                     │
│  Featured Themes (Horizontal)       │ ← Scrollable
│  [Theme 1] [Theme 2] [Theme 3] ... │   Carousel
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ┌─ All Themes ─── Most Popular ▼ │ ← Section
│  │                                  │   Header
│  ├─────────────────────────────────┤
│  │ [Theme Card]                    │
│  │ Neon Dreams                     │ ← Scrollable
│  │ by Murasu • 1.2K downloads      │   Grid/List
│  ├─────────────────────────────────┤
│  │ [Theme Card]                    │
│  │ Classic Blue                    │
│  │ by John Doe • 856 downloads     │
│  ├─────────────────────────────────┤
│                  ⋮                  │
│                                     │
└─────────────────────────────────────┘
```

### Pro Gate for Free Users

**When Free User Taps Store:**
```
┌─────────────────────────────────────┐
│                                     │
│         🔒 Theme Store              │
│                                     │
│   Unlock hundreds of beautiful      │
│   keyboard themes created by        │
│   the community                     │
│                                     │
│   ✓ Browse curated themes           │
│   ✓ Download unlimited themes       │
│   ✓ Upload your own themes          │
│   ✓ Support theme creators          │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    Upgrade to Pro           │   │
│  └─────────────────────────────┘   │
│                                     │
│         [ Maybe Later ]             │
│                                     │
└─────────────────────────────────────┘
```

**SwiftUI Implementation:**
```swift
struct ThemeStoreView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        Group {
            if userManager.isPro {
                ThemeStoreContent()
            } else {
                ProUpgradePrompt(feature: .themeStore)
            }
        }
    }
}

struct ProUpgradePrompt: View {
    let feature: ProFeature
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Theme Store")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Unlock hundreds of beautiful keyboard themes created by the community")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureBullet(text: "Browse curated themes")
                FeatureBullet(text: "Download unlimited themes")
                FeatureBullet(text: "Upload your own themes")
                FeatureBullet(text: "Support theme creators")
            }
            .padding()
            
            Button(action: { userManager.showProUpgrade() }) {
                Text("Upgrade to Pro")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button("Maybe Later") {
                // Dismiss
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}
```

---

## 3. Store Navigation & Flow

### Navigation Structure

```
Store Home
├─ Featured Section (Carousel)
│  └─ Tap → Theme Detail
│
├─ All Themes (Grid/List)
│  └─ Tap → Theme Detail
│
├─ Search
│  └─ Results → Theme Detail
│
└─ My Themes
   ├─ My Uploaded Themes
   │  └─ Tap → Theme Detail (with Edit option)
   └─ My Downloaded Themes
      └─ Tap → Theme Detail
```

### User Flow Diagram

```
Store Home
   │
   ├─ Browse Themes
   │   └─> Theme Detail
   │        ├─> Download
   │        │    └─> Apply to Keyboard
   │        │         └─> Success!
   │        │
   │        └─> Already Downloaded
   │             └─> Apply or Re-download
   │
   ├─ Search Themes
   │   └─> Search Results
   │        └─> Theme Detail
   │
   └─ My Themes
       ├─> Uploaded Themes
       │    └─> Theme Detail (with Edit)
       │         ├─> Edit in Editor
       │         ├─> View Stats
       │         └─> Delete
       │
       └─> Downloaded Themes
            └─> Theme Detail
                 ├─> Apply
                 └─> Delete
```

---

## 4. Theme Browse Interface

### Featured Section (Horizontal Carousel)

```
Featured Themes
┌────────────────────────────────────────────┐
│ ← [       Preview       ] [     Preview    │
│   [ Neon Dreams ]         [ Dark Elegant ] │
│   ★★★★☆ 1.2K              ★★★★★ 2.5K      │
└────────────────────────────────────────────┘
```

**Features:**
- Horizontal page-style scrolling
- Large preview images
- Theme name and stats
- Auto-scroll every 5 seconds (optional)
- Page indicator dots

**SwiftUI Implementation:**
```swift
struct FeaturedThemesCarousel: View {
    let themes: [ThemeMetadata]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Themes")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            TabView(selection: $currentIndex) {
                ForEach(Array(themes.enumerated()), id: \.element.id) { index, theme in
                    FeaturedThemeCard(theme: theme)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
        }
    }
}

struct FeaturedThemeCard: View {
    let theme: ThemeMetadata
    
    var body: some View {
        NavigationLink(destination: ThemeDetailView(themeId: theme.id)) {
            VStack {
                // Theme preview image
                AsyncImage(url: theme.previewImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    KeyboardPreviewPlaceholder()
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text("\(theme.downloadCount.formatted()) downloads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}
```

### All Themes Grid/List

**Grid View:**
```
┌─────────────────────────────────────┐
│ All Themes        [Grid] List   ▼  │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐          │
│  │[Preview]│  │[Preview]│          │
│  │  Neon   │  │ Classic │          │
│  │ Dreams  │  │  Blue   │          │
│  │ 1.2K ⬇  │  │ 856 ⬇   │          │
│  └─────────┘  └─────────┘          │
│  ┌─────────┐  ┌─────────┐          │
│  │[Preview]│  │[Preview]│          │
│  │ Pastel  │  │  Dark   │          │
│  │ Rainbow │  │ Elegant │          │
│  │ 654 ⬇   │  │ 2.5K ⬇  │          │
│  └─────────┘  └─────────┘          │
└─────────────────────────────────────┘
```

**List View:**
```
┌─────────────────────────────────────┐
│ All Themes         Grid [List]  ▼  │
├─────────────────────────────────────┤
│  ┌──┐ Neon Dreams                  │
│  │[]│ by Murasu Systems             │
│  └──┘ 1.2K downloads • Updated 2d  │
├─────────────────────────────────────┤
│  ┌──┐ Classic Blue                 │
│  │[]│ by John Doe                   │
│  └──┘ 856 downloads • Updated 1w   │
├─────────────────────────────────────┤
│  ┌──┐ Pastel Rainbow               │
│  │[]│ by Jane Smith                 │
│  └──┘ 654 downloads • Updated 3d   │
└─────────────────────────────────────┘
```

**SwiftUI Implementation:**
```swift
struct ThemeBrowserView: View {
    @StateObject private var viewModel = ThemeBrowserViewModel()
    @State private var viewStyle: ViewStyle = .grid
    @State private var sortOption: SortOption = .mostPopular
    
    enum ViewStyle {
        case grid, list
    }
    
    enum SortOption: String, CaseIterable {
        case mostPopular = "Most Popular"
        case newest = "Newest"
        case name = "Name"
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    if viewStyle == .grid {
                        ThemeGridView(themes: viewModel.themes)
                    } else {
                        ThemeListView(themes: viewModel.themes)
                    }
                } header: {
                    ThemeBrowserHeader(
                        viewStyle: $viewStyle,
                        sortOption: $sortOption
                    )
                }
            }
        }
        .navigationTitle("Store")
        .task {
            await viewModel.loadThemes(sortBy: sortOption)
        }
        .onChange(of: sortOption) { newSort in
            Task {
                await viewModel.loadThemes(sortBy: newSort)
            }
        }
    }
}

struct ThemeBrowserHeader: View {
    @Binding var viewStyle: ThemeBrowserView.ViewStyle
    @Binding var sortOption: ThemeBrowserView.SortOption
    
    var body: some View {
        HStack {
            Text("All Themes")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // View style toggle
            Button(action: { viewStyle = .grid }) {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(viewStyle == .grid ? .blue : .gray)
            }
            
            Button(action: { viewStyle = .list }) {
                Image(systemName: "list.bullet")
                    .foregroundColor(viewStyle == .list ? .blue : .gray)
            }
            
            // Sort menu
            Menu {
                ForEach(ThemeBrowserView.SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(sortOption.rawValue)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct ThemeGridView: View {
    let themes: [ThemeMetadata]
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(themes) { theme in
                ThemeGridCard(theme: theme)
            }
        }
        .padding()
    }
}

struct ThemeGridCard: View {
    let theme: ThemeMetadata
    
    var body: some View {
        NavigationLink(destination: ThemeDetailView(themeId: theme.id)) {
            VStack(alignment: .leading, spacing: 8) {
                // Preview
                AsyncImage(url: theme.previewImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    KeyboardPreviewPlaceholder()
                }
                .frame(height: 100)
                .clipped()
                .cornerRadius(8)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .font(.caption2)
                        Text(theme.downloadCount.formatted())
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeListView: View {
    let themes: [ThemeMetadata]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(themes) { theme in
                NavigationLink(destination: ThemeDetailView(themeId: theme.id)) {
                    ThemeListRow(theme: theme)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.leading, 80)
            }
        }
    }
}

struct ThemeListRow: View {
    let theme: ThemeMetadata
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: theme.previewImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                KeyboardPreviewPlaceholder()
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("by \(theme.authorName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.caption)
                    Text("\(theme.downloadCount.formatted()) downloads")
                        .font(.caption)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(theme.updatedAt.relativeFormatted())
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
```

---

## 5. Theme Detail View

### Layout

```
┌─────────────────────────────────────┐
│ ← Neon Dreams                   ⋮   │
├─────────────────────────────────────┤
│                                     │
│      [Large Keyboard Preview]       │
│                                     │
│       Light │ Dark                  │
│                                     │
├─────────────────────────────────────┤
│  Neon Dreams                        │
│  by Murasu Systems                  │
│                                     │
│  A vibrant neon-inspired keyboard   │
│  theme with glowing effects         │
│                                     │
│  [ neon ] [ colorful ] [ modern ]   │
│                                     │
│  ⬇ 1,234 downloads                 │
│  📅 Updated 2 days ago              │
│  ⭐ Featured                        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Download Theme         │   │
│  └─────────────────────────────┘   │
│                                     │
│  Similar Themes                     │
│  [Theme1] [Theme2] [Theme3]         │
│                                     │
└─────────────────────────────────────┘
```

### States

**State 1: Not Downloaded**
```
┌─────────────────────────────────┐
│      Download Theme             │
└─────────────────────────────────┘
```

**State 2: Already Downloaded**
```
┌─────────────────────────────────┐
│  ✓ Downloaded • Apply to Keyboard│
└─────────────────────────────────┘
```

**State 3: Currently Active**
```
┌─────────────────────────────────┐
│  ✓ Currently Active             │
└─────────────────────────────────┘
```

**State 4: Downloading**
```
┌─────────────────────────────────┐
│  Downloading... [Progress Bar]  │
└─────────────────────────────────┘
```

**State 5: My Theme (Creator View)**
```
┌─────────────────────────────────┐
│         Edit Theme              │
└─────────────────────────────────┘

View Statistics
Downloads: 1,234
Status: Approved
Uploaded: 2 weeks ago
```

**SwiftUI Implementation:**
```swift
struct ThemeDetailView: View {
    let themeId: String
    @StateObject private var viewModel = ThemeDetailViewModel()
    @State private var showingPreview: ColorScheme = .light
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Preview Section
                VStack(spacing: 16) {
                    if let theme = viewModel.theme {
                        KeyboardPreviewView(theme: theme, mode: showingPreview)
                            .frame(height: 200)
                            .padding()
                    }
                    
                    // Mode toggle
                    Picker("Mode", selection: $showingPreview) {
                        Text("Light").tag(ColorScheme.light)
                        Text("Dark").tag(ColorScheme.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .background(Color(.secondarySystemBackground))
                
                // Details Section
                VStack(alignment: .leading, spacing: 16) {
                    // Title and author
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.metadata?.name ?? "")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let author = viewModel.metadata?.authorName {
                            Text("by \(author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Description
                    if let description = viewModel.metadata?.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags
                    if let tags = viewModel.metadata?.tags, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    TagView(text: tag)
                                }
                            }
                        }
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        StatRow(
                            icon: "arrow.down.circle",
                            text: "\(viewModel.metadata?.downloadCount ?? 0) downloads"
                        )
                        
                        StatRow(
                            icon: "calendar",
                            text: "Updated \(viewModel.metadata?.updatedAt.relativeFormatted() ?? "")"
                        )
                        
                        if viewModel.metadata?.isFeatured == true {
                            StatRow(
                                icon: "star.fill",
                                text: "Featured",
                                color: .yellow
                            )
                        }
                    }
                    
                    // Action button
                    actionButton
                        .padding(.vertical)
                    
                    // Similar themes
                    if !viewModel.similarThemes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Similar Themes")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.similarThemes) { theme in
                                        SimilarThemeCard(theme: theme)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isMyTheme {
                    Menu {
                        Button(action: viewModel.editTheme) {
                            Label("Edit Theme", systemImage: "pencil")
                        }
                        
                        Button(action: viewModel.viewStats) {
                            Label("View Statistics", systemImage: "chart.bar")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: viewModel.deleteTheme) {
                            Label("Delete Theme", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                } else {
                    Button(action: viewModel.shareTheme) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task {
            await viewModel.loadTheme(id: themeId)
        }
    }
    
    @ViewBuilder
    var actionButton: some View {
        switch viewModel.downloadState {
        case .notDownloaded:
            Button(action: { Task { await viewModel.downloadTheme() } }) {
                Label("Download Theme", systemImage: "arrow.down.circle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
        case .downloading(let progress):
            VStack(spacing: 8) {
                ProgressView(value: progress)
                Text("Downloading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
        case .downloaded:
            Button(action: viewModel.applyTheme) {
                Label("Apply to Keyboard", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            
        case .active:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Currently Active")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
        case .myTheme:
            Button(action: viewModel.editTheme) {
                Label("Edit Theme", systemImage: "pencil")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let text: String
    var color: Color = .secondary
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
```

---

## 6. My Themes Section

### Layout

```
┌─────────────────────────────────────┐
│ ← My Themes                         │
├─────────────────────────────────────┤
│  [ Uploaded ] Downloaded            │ ← Tabs
├─────────────────────────────────────┤
│                                     │
│  My Uploaded Themes                 │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Preview]                   │   │
│  │ Neon Dreams                 │   │
│  │ ⬇ 1,234 • ✓ Approved       │   │
│  │         [Edit] [Stats]      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Preview]                   │   │
│  │ Dark Minimal                │   │
│  │ 🕐 Pending Approval         │   │
│  │         [Edit] [Cancel]     │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Preview]                   │   │
│  │ Bright Colors               │   │
│  │ ❌ Rejected                 │   │
│  │ Reason: Too bright colors   │   │
│  │         [Edit] [Resubmit]   │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Theme States

**Approved:**
```
✓ Approved
⬇ 1,234 downloads
[View Stats] [Edit] [Delete]
```

**Pending:**
```
🕐 Pending Approval
Submitted 2 days ago
[Edit] [Cancel Submission]
```

**Rejected:**
```
❌ Rejected
Reason: Colors have insufficient contrast
[View Feedback] [Edit & Resubmit]
```

**SwiftUI Implementation:**
```swift
struct MyThemesView: View {
    @StateObject private var viewModel = MyThemesViewModel()
    @State private var selectedTab: Tab = .uploaded
    
    enum Tab {
        case uploaded, downloaded
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Section", selection: $selectedTab) {
                Text("Uploaded").tag(Tab.uploaded)
                Text("Downloaded").tag(Tab.downloaded)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    if selectedTab == .uploaded {
                        uploadedThemesContent
                    } else {
                        downloadedThemesContent
                    }
                }
                .padding()
            }
        }
        .navigationTitle("My Themes")
        .task {
            await viewModel.loadMyThemes()
        }
    }
    
    @ViewBuilder
    var uploadedThemesContent: some View {
        if viewModel.uploadedThemes.isEmpty {
            EmptyStateView(
                icon: "paintbrush",
                title: "No Uploaded Themes",
                message: "Create and upload your first theme to share with the community",
                action: ("Create Theme", viewModel.createNewTheme)
            )
        } else {
            ForEach(viewModel.uploadedThemes) { theme in
                UploadedThemeCard(theme: theme, viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    var downloadedThemesContent: some View {
        if viewModel.downloadedThemes.isEmpty {
            EmptyStateView(
                icon: "arrow.down.circle",
                title: "No Downloaded Themes",
                message: "Browse the store to download themes created by others",
                action: ("Browse Store", viewModel.openStore)
            )
        } else {
            ForEach(viewModel.downloadedThemes) { theme in
                DownloadedThemeCard(theme: theme, viewModel: viewModel)
            }
        }
    }
}

struct UploadedThemeCard: View {
    let theme: MyThemeMetadata
    let viewModel: MyThemesViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview
            AsyncImage(url: theme.previewImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                KeyboardPreviewPlaceholder()
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(theme.name)
                    .font(.headline)
                
                // Status badge
                statusBadge
                
                // Actions
                HStack(spacing: 12) {
                    if theme.status == .approved {
                        Button(action: { viewModel.viewStats(theme) }) {
                            Label("Stats", systemImage: "chart.bar")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: { viewModel.editTheme(theme) }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    
                    if theme.status == .pending {
                        Button(action: { viewModel.cancelSubmission(theme) }) {
                            Label("Cancel", systemImage: "xmark")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else if theme.status == .rejected {
                        Button(action: { viewModel.resubmitTheme(theme) }) {
                            Label("Resubmit", systemImage: "arrow.up.doc")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    var statusBadge: some View {
        switch theme.status {
        case .approved:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Approved")
                    .font(.subheadline)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Image(systemName: "arrow.down.circle")
                    .font(.caption)
                Text("\(theme.downloadCount) downloads")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            
        case .pending:
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Pending Approval")
                    .font(.subheadline)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("Submitted \(theme.submittedAt.relativeFormatted())")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            
        case .rejected:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Rejected")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                
                if let reason = theme.rejectionReason {
                    Text("Reason: \(reason)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

---

## 7. Search & Filters

### Search Interface

```
┌─────────────────────────────────────┐
│  🔍 Search themes...                │
├─────────────────────────────────────┤
│                                     │
│  Recent Searches                    │
│  • neon                             │
│  • dark theme                       │
│  • minimal                          │
│                                     │
│  Popular Tags                       │
│  [ dark ] [ light ] [ colorful ]    │
│  [ minimal ] [ modern ] [ vibrant ] │
│                                     │
└─────────────────────────────────────┘
```

### Search Results

```
┌─────────────────────────────────────┐
│  ← "neon"                   🔍      │
├─────────────────────────────────────┤
│  Found 8 themes                     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Preview] Neon Dreams       │   │
│  │ by Murasu • 1.2K downloads  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Preview] Neon Lights       │   │
│  │ by John • 456 downloads     │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**SwiftUI Implementation:**
```swift
struct ThemeSearchView: View {
    @StateObject private var viewModel = ThemeSearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search themes...", text: $searchText)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { newValue in
                        viewModel.search(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding()
            
            // Content
            if searchText.isEmpty {
                searchSuggestions
            } else {
                searchResults
            }
        }
        .navigationTitle("Search")
        .onAppear {
            isSearchFocused = true
        }
    }
    
    var searchSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recent searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Searches")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.recentSearches, id: \.self) { query in
                            Button(action: {
                                searchText = query
                                viewModel.search(query: query)
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text(query)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Popular tags
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Tags")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.popularTags, id: \.self) { tag in
                            Button(action: {
                                searchText = tag
                                viewModel.search(query: tag)
                            }) {
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    if viewModel.isSearching {
                        ProgressView()
                            .padding()
                    } else if viewModel.searchResults.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "Try different keywords or browse all themes"
                        )
                        .padding()
                    } else {
                        ForEach(viewModel.searchResults) { theme in
                            NavigationLink(destination: ThemeDetailView(themeId: theme.id)) {
                                ThemeListRow(theme: theme)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 80)
                        }
                    }
                } header: {
                    HStack {
                        Text("Found \(viewModel.searchResults.count) themes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
    }
}

@MainActor
class ThemeSearchViewModel: ObservableObject {
    @Published var searchResults: [ThemeMetadata] = []
    @Published var isSearching = false
    @Published var recentSearches: [String] = []
    @Published var popularTags: [String] = []
    
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadRecentSearches()
        loadPopularTags()
    }
    
    func search(query: String) {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                
                let results = try await APIClient.shared.searchThemes(query: query)
                
                if !Task.isCancelled {
                    searchResults = results
                    saveRecentSearch(query)
                }
            } catch {
                print("Search error: \(error)")
            }
            
            isSearching = false
        }
    }
    
    func clearSearch() {
        searchResults = []
        searchTask?.cancel()
    }
    
    private func saveRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }
        // Save to UserDefaults
    }
    
    private func loadRecentSearches() {
        // Load from UserDefaults
        recentSearches = ["neon", "dark theme", "minimal"]
    }
    
    private func loadPopularTags() {
        popularTags = [
            "dark", "light", "colorful", "minimal",
            "modern", "vibrant", "elegant", "playful"
        ]
    }
}
```

---

## 8. Backend API Specification

### Base URL
```
Production: https://api.sangamkeyboards.com/v1
Staging: https://staging-api.sangamkeyboards.com/v1
```

### Authentication
All API requests require authentication via JWT token in header:
```
Authorization: Bearer <jwt_token>
```

### API Endpoints

#### 1. Get All Themes (Public Store)

```http
GET /themes
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `limit` | integer | No | Items per page (default: 20, max: 100) |
| `sort` | string | No | Sort option: `popular`, `newest`, `name` (default: `popular`) |
| `tag` | string | No | Filter by tag |
| `search` | string | No | Search query |

**Response:**
```json
{
  "success": true,
  "data": {
    "themes": [
      {
        "id": "neon_dreams",
        "name": "Neon Dreams",
        "authorId": "user_12345",
        "authorName": "Murasu Systems",
        "description": "A vibrant neon-inspired keyboard theme",
        "tags": ["neon", "colorful", "modern"],
        "version": "1.0",
        "downloadCount": 1234,
        "isFeatured": true,
        "previewImageUrl": "https://cdn.sangamkeyboards.com/previews/neon_dreams.png",
        "createdAt": "2025-10-01T10:00:00Z",
        "updatedAt": "2025-10-15T14:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 98,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

**Errors:**
- `400` - Invalid parameters
- `401` - Unauthorized (not Pro user)
- `500` - Server error

#### 2. Get Theme Detail

```http
GET /themes/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "theme": {
      "id": "neon_dreams",
      "name": "Neon Dreams",
      "authorId": "user_12345",
      "authorName": "Murasu Systems",
      "description": "A vibrant neon-inspired keyboard theme",
      "tags": ["neon", "colorful", "modern"],
      "version": "1.0",
      "downloadCount": 1234,
      "isFeatured": true,
      "previewImageUrl": "https://cdn.sangamkeyboards.com/previews/neon_dreams.png",
      "themeJsonUrl": "https://cdn.sangamkeyboards.com/themes/neon_dreams.json",
      "createdAt": "2025-10-01T10:00:00Z",
      "updatedAt": "2025-10-15T14:30:00Z"
    }
  }
}
```

**Errors:**
- `404` - Theme not found
- `401` - Unauthorized

#### 3. Download Theme

```http
POST /themes/:id/download
```

**Response:**
```json
{
  "success": true,
  "data": {
    "downloadUrl": "https://cdn.sangamkeyboards.com/themes/neon_dreams.json",
    "expiresAt": "2025-10-17T11:00:00Z"
  }
}
```

**Side Effects:**
- Increments download count
- Records download in user's download history

**Errors:**
- `404` - Theme not found
- `401` - Unauthorized
- `403` - Not a Pro user

#### 4. Upload Theme

```http
POST /themes
```

**Request Body:**
```json
{
  "themeJson": "{...}", // Stringified theme JSON
  "metadata": {
    "name": "My Theme",
    "description": "A beautiful theme",
    "tags": ["dark", "minimal"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "themeId": "my_theme_abc123",
    "status": "pending",
    "message": "Theme submitted for approval"
  }
}
```

**Validation:**
- Theme JSON must be valid
- File size < 50KB
- User must be Pro
- Required metadata fields present
- No profanity in name/description

**Errors:**
- `400` - Validation error
- `401` - Unauthorized
- `403` - Not a Pro user
- `413` - File too large
- `429` - Rate limit exceeded (10/hour)

#### 5. Update Theme

```http
PUT /themes/:id
```

**Request Body:**
```json
{
  "themeJson": "{...}",
  "metadata": {
    "name": "My Theme v2",
    "description": "Updated description"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Theme updated and re-submitted for approval",
    "status": "pending"
  }
}
```

**Authorization:**
- User must be the theme creator

**Errors:**
- `403` - Not theme owner
- `404` - Theme not found

#### 6. Delete Theme

```http
DELETE /themes/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Theme deleted successfully"
  }
}
```

**Authorization:**
- User must be theme creator

**Errors:**
- `403` - Not theme owner
- `404` - Theme not found

#### 7. Get My Themes

```http
GET /users/me/themes
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | string | No | Filter by status: `approved`, `pending`, `rejected` |

**Response:**
```json
{
  "success": true,
  "data": {
    "uploadedThemes": [
      {
        "id": "my_theme",
        "name": "My Theme",
        "status": "approved",
        "downloadCount": 45,
        "createdAt": "2025-10-10T10:00:00Z",
        "updatedAt": "2025-10-10T10:00:00Z"
      },
      {
        "id": "pending_theme",
        "name": "Pending Theme",
        "status": "pending",
        "submittedAt": "2025-10-15T09:00:00Z"
      },
      {
        "id": "rejected_theme",
        "name": "Rejected Theme",
        "status": "rejected",
        "rejectionReason": "Insufficient color contrast",
        "rejectedAt": "2025-10-14T16:00:00Z"
      }
    ],
    "downloadedThemes": [
      {
        "id": "neon_dreams",
        "name": "Neon Dreams",
        "authorName": "Murasu",
        "downloadedAt": "2025-10-12T10:00:00Z"
      }
    ]
  }
}
```

#### 8. Search Themes

```http
GET /themes/search
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query |
| `limit` | integer | No | Results limit (default: 20) |

**Response:**
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "id": "neon_dreams",
        "name": "Neon Dreams",
        "authorName": "Murasu",
        "downloadCount": 1234,
        "previewImageUrl": "...",
        "relevanceScore": 0.95
      }
    ],
    "totalResults": 8
  }
}
```

#### 9. Get Featured Themes

```http
GET /themes/featured
```

**Response:**
```json
{
  "success": true,
  "data": {
    "themes": [
      // Array of theme objects
    ]
  }
}
```

#### 10. Get Similar Themes

```http
GET /themes/:id/similar
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Number of results (default: 5) |

**Response:**
```json
{
  "success": true,
  "data": {
    "themes": [
      // Array of similar theme objects
    ]
  }
}
```

**Algorithm:**
- Match by tags
- Match by color palette similarity
- Match by style (dark/light)
- Exclude already downloaded themes

---

## 9. Database Schema

### Tables

#### `themes`
```sql
CREATE TABLE themes (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    author_id VARCHAR(50) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    json_content TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    rejection_reason TEXT NULL,
    download_count INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    preview_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP NULL,
    approved_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    approved_by VARCHAR(50) NULL,
    
    INDEX idx_status (status),
    INDEX idx_author (author_id),
    INDEX idx_featured (is_featured),
    INDEX idx_downloads (download_count),
    INDEX idx_created (created_at),
    
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### `theme_tags`
```sql
CREATE TABLE theme_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    theme_id VARCHAR(100) NOT NULL,
    tag VARCHAR(50) NOT NULL,
    
    INDEX idx_theme (theme_id),
    INDEX idx_tag (tag),
    UNIQUE KEY unique_theme_tag (theme_id, tag),
    
    FOREIGN KEY (theme_id) REFERENCES themes(id) ON DELETE CASCADE
);
```

#### `theme_downloads`
```sql
CREATE TABLE theme_downloads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    theme_id VARCHAR(100) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_theme (theme_id),
    INDEX idx_user (user_id),
    INDEX idx_downloaded_at (downloaded_at),
    UNIQUE KEY unique_user_theme (user_id, theme_id),
    
    FOREIGN KEY (theme_id) REFERENCES themes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### `users`
```sql
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    is_pro BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_pro (is_pro)
);
```

#### `admin_actions`
```sql
CREATE TABLE admin_actions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    action_type ENUM('approve', 'reject', 'feature', 'unfeature', 'delete') NOT NULL,
    theme_id VARCHAR(100) NOT NULL,
    reason TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_admin (admin_id),
    INDEX idx_theme (theme_id),
    INDEX idx_created (created_at),
    
    FOREIGN KEY (admin_id) REFERENCES users(id),
    FOREIGN KEY (theme_id) REFERENCES themes(id) ON DELETE CASCADE
);
```

---

## 10. Admin Panel

### Admin Dashboard

```
┌─────────────────────────────────────┐
│  Admin Dashboard                    │
├─────────────────────────────────────┤
│                                     │
│  Pending Approval (12)              │
│  ┌─────────────────────────────┐   │
│  │ [Preview] Neon Dreams       │   │
│  │ by user@example.com         │   │
│  │ Submitted 2 hours ago       │   │
│  │ [View] [Approve] [Reject]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Recently Approved (5)              │
│  Recently Rejected (3)              │
│                                     │
│  Statistics                         │
│  • Total themes: 245                │
│  • Pending: 12                      │
│  • Approved today: 8                │
│  • Rejected today: 2                │
│                                     │
└─────────────────────────────────────┘
```

### Theme Review Interface

```
┌─────────────────────────────────────┐
│  Review Theme                       │
├─────────────────────────────────────┤
│                                     │
│  Theme: Neon Dreams                 │
│  Author: user@example.com           │
│  Submitted: 2025-10-17 10:30 AM     │
│                                     │
│  [Light Preview] [Dark Preview]     │
│                                     │
│  Metadata                           │
│  Name: Neon Dreams                  │
│  Description: A vibrant neon...     │
│  Tags: neon, colorful, modern       │
│  Version: 1.0                       │
│                                     │
│  Validation Checks                  │
│  ✓ Valid JSON format                │
│  ✓ File size: 12.5 KB               │
│  ✓ Required fields present          │
│  ⚠ Contrast ratio: 4.2:1 (borderline)│
│                                     │
│  Actions                            │
│  ┌─────────────────────────────┐   │
│  │        Approve Theme        │   │
│  └─────────────────────────────┘   │
│                                     │
│  Rejection Reason (optional)        │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │        Reject Theme         │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Admin API Endpoints

#### Get Pending Themes
```http
GET /admin/themes/pending
Authorization: Bearer <admin_jwt>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "themes": [
      {
        "id": "theme_abc",
        "name": "Neon Dreams",
        "authorId": "user_123",
        "authorEmail": "user@example.com",
        "submittedAt": "2025-10-17T08:30:00Z",
        "previewImageUrl": "...",
        "themeJsonUrl": "..."
      }
    ]
  }
}
```

#### Approve Theme
```http
POST /admin/themes/:id/approve
Authorization: Bearer <admin_jwt>
```

**Request Body:**
```json
{
  "featured": false
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Theme approved successfully"
  }
}
```

#### Reject Theme
```http
POST /admin/themes/:id/reject
Authorization: Bearer <admin_jwt>
```

**Request Body:**
```json
{
  "reason": "Insufficient color contrast between text and background"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Theme rejected"
  }
}
```

#### Feature/Unfeature Theme
```http
POST /admin/themes/:id/feature
Authorization: Bearer <admin_jwt>
```

**Request Body:**
```json
{
  "featured": true
}
```

---

## 11. Authentication & Authorization

### JWT Token Structure

```json
{
  "sub": "user_12345",
  "email": "user@example.com",
  "isPro": true,
  "isAdmin": false,
  "iat": 1697539200,
  "exp": 1697625600
}
```

### Authorization Middleware (PHP)

```php
<?php
function requirePro() {
    $token = getBearerToken();
    $decoded = validateJWT($token);
    
    if (!$decoded->isPro) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'error' => 'Pro subscription required'
        ]);
        exit;
    }
    
    return $decoded;
}

function requireAdmin() {
    $token = getBearerToken();
    $decoded = validateJWT($token);
    
    if (!$decoded->isAdmin) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'error' => 'Admin access required'
        ]);
        exit;
    }
    
    return $decoded;
}
```

---

## 12. Error Handling & Edge Cases

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Theme validation failed",
    "details": [
      "Theme name is required",
      "Description must be at least 10 characters"
    ]
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Authentication required |
| `PRO_REQUIRED` | 403 | Pro subscription required |
| `NOT_THEME_OWNER` | 403 | Not authorized to modify theme |
| `NOT_FOUND` | 404 | Resource not found |
| `FILE_TOO_LARGE` | 413 | Theme file exceeds size limit |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |

### Edge Cases

**1. Theme Already Downloaded:**
- Return downloadUrl from cache
- Don't increment download count
- Show "Re-download" option

**2. Creator Downloads Own Theme:**
- Allow download
- Don't increment download count
- Show as "Your Theme"

**3. Theme Deleted While User Viewing:**
- Show graceful error message
- Offer to browse similar themes
- Remove from user's downloaded list if applicable

**4. User's Pro Subscription Expires:**
- Can still use previously downloaded themes
- Cannot download new themes
- Cannot access store
- Upload button disabled
- Show upgrade prompt

**5. Theme Rejected During Edit:**
- Notify user via push notification
- Show rejection reason in "My Themes"
- Allow immediate re-submission after fixes
- Preserve original submission date

**6. Concurrent Theme Edits:**
- Use optimistic locking with version numbers
- Return 409 Conflict if version mismatch
- Prompt user to refresh and retry

**7. Network Failures During Download:**
- Implement retry logic (3 attempts)
- Cache partial downloads
- Resume download if possible
- Show clear error with retry button

**8. Theme JSON Corrupted:**
- Validate on server before storing
- Validate on client before applying
- Fall back to default theme if invalid
- Log error for investigation

**9. Preview Image Generation:**
- Generate on upload (server-side)
- Use default placeholder if generation fails
- Re-generate on theme update
- Cache with CDN

**10. Duplicate Theme IDs:**
- Server validates uniqueness on upload
- Auto-generate unique ID if conflict
- Return error with suggested alternative ID

### Error Handling in Swift

```swift
enum ThemeStoreError: LocalizedError {
    case notProUser
    case networkError
    case themeNotFound
    case downloadFailed
    case fileTooLarge
    case validationFailed([String])
    case rateLimitExceeded
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .notProUser:
            return "Pro subscription required to access the theme store"
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .themeNotFound:
            return "This theme is no longer available"
        case .downloadFailed:
            return "Failed to download theme. Please try again."
        case .fileTooLarge:
            return "Theme file is too large to upload"
        case .validationFailed(let errors):
            return "Validation failed:\n" + errors.joined(separator: "\n")
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notProUser:
            return "Upgrade to Pro to unlock the theme store"
        case .networkError:
            return "Try again when you have a stable connection"
        case .themeNotFound:
            return "Browse other themes in the store"
        case .downloadFailed:
            return "Tap to retry download"
        case .validationFailed:
            return "Fix the errors and try uploading again"
        case .rateLimitExceeded:
            return "Wait a few minutes before trying again"
        default:
            return nil
        }
    }
}
```

### Retry Logic

```swift
class APIClient {
    func downloadTheme(id: String, retryCount: Int = 0) async throws -> ThemeData {
        do {
            let url = URL(string: "\(baseURL)/themes/\(id)/download")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ThemeStoreError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(ThemeData.self, from: data)
            case 401:
                throw ThemeStoreError.notProUser
            case 404:
                throw ThemeStoreError.themeNotFound
            case 429:
                throw ThemeStoreError.rateLimitExceeded
            case 500...599:
                // Retry on server errors
                if retryCount < 3 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                    return try await downloadTheme(id: id, retryCount: retryCount + 1)
                }
                throw ThemeStoreError.serverError("Server error")
            default:
                throw ThemeStoreError.serverError("Unknown error")
            }
        } catch {
            if retryCount < 3 && isRetryableError(error) {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                return try await downloadTheme(id: id, retryCount: retryCount + 1)
            }
            throw error
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
}
```

---

## 13. Performance Optimization

### Client-Side Caching

```swift
class ThemeCache {
    private let cache = NSCache<NSString, ThemeData>()
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("themes")
    }
    
    init() {
        cache.countLimit = 50  // Cache up to 50 themes in memory
        createCacheDirectoryIfNeeded()
    }
    
    func get(id: String) -> ThemeData? {
        // Check memory cache first
        if let cached = cache.object(forKey: id as NSString) {
            return cached
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(id).json")
        if let data = try? Data(contentsOf: fileURL),
           let theme = try? JSONDecoder().decode(ThemeData.self, from: data) {
            cache.setObject(theme, forKey: id as NSString)
            return theme
        }
        
        return nil
    }
    
    func set(_ theme: ThemeData, forKey id: String) {
        // Save to memory
        cache.setObject(theme, forKey: id as NSString)
        
        // Save to disk
        let fileURL = cacheDirectory.appendingPathComponent("\(id).json")
        if let data = try? JSONEncoder().encode(theme) {
            try? data.write(to: fileURL)
        }
    }
    
    func clear() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
```

### Image Loading & Caching

```swift
struct AsyncImage: View {
    let url: URL?
    let placeholder: () -> AnyView
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        // Check cache first
        if let cached = ImageCache.shared.get(url: url) {
            image = cached
            return
        }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                ImageCache.shared.set(downloadedImage, forURL: url)
                image = downloadedImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
        
        isLoading = false
    }
}

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
    }
    
    func get(url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func set(_ image: UIImage, forURL url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
```

### Pagination

```swift
@MainActor
class ThemeBrowserViewModel: ObservableObject {
    @Published var themes: [ThemeMetadata] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private let pageSize = 20
    
    func loadThemes(sortBy: SortOption) async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await APIClient.shared.getThemes(
                page: currentPage,
                limit: pageSize,
                sort: sortBy.rawValue
            )
            
            if currentPage == 1 {
                themes = response.themes
            } else {
                themes.append(contentsOf: response.themes)
            }
            
            hasMorePages = response.pagination.hasNext
            currentPage += 1
        } catch {
            print("Failed to load themes: \(error)")
        }
    }
    
    func loadMoreIfNeeded(currentItem: ThemeMetadata) async {
        // Load more when user scrolls to last 5 items
        guard let index = themes.firstIndex(where: { $0.id == currentItem.id }),
              index >= themes.count - 5,
              hasMorePages,
              !isLoading else {
            return
        }
        
        await loadThemes(sortBy: .mostPopular)
    }
    
    func refresh() async {
        currentPage = 1
        hasMorePages = true
        await loadThemes(sortBy: .mostPopular)
    }
}

// Usage in view
LazyVStack {
    ForEach(viewModel.themes) { theme in
        ThemeCard(theme: theme)
            .task {
                await viewModel.loadMoreIfNeeded(currentItem: theme)
            }
    }
    
    if viewModel.isLoading {
        ProgressView()
            .padding()
    }
}
.refreshable {
    await viewModel.refresh()
}
```

### Server-Side Optimization

**Database Indexing:**
```sql
-- Optimize most common queries
CREATE INDEX idx_themes_status_downloads ON themes(status, download_count DESC);
CREATE INDEX idx_themes_status_created ON themes(status, created_at DESC);
CREATE INDEX idx_theme_tags_tag ON theme_tags(tag);

-- Full-text search index
CREATE FULLTEXT INDEX idx_themes_search ON themes(name, description);
```

**Query Optimization:**
```php
<?php
// Efficient query for theme listing
function getThemes($page, $limit, $sort, $status = 'approved') {
    global $db;
    
    $offset = ($page - 1) * $limit;
    
    // Build order clause
    switch ($sort) {
        case 'popular':
            $orderBy = 'download_count DESC';
            break;
        case 'newest':
            $orderBy = 'created_at DESC';
            break;
        case 'name':
            $orderBy = 'name ASC';
            break;
        default:
            $orderBy = 'download_count DESC';
    }
    
    // Use prepared statement
    $stmt = $db->prepare("
        SELECT 
            id, name, author_id, author_name, description,
            download_count, is_featured, preview_image_url,
            created_at, updated_at
        FROM themes
        WHERE status = ?
        ORDER BY $orderBy
        LIMIT ? OFFSET ?
    ");
    
    $stmt->bind_param('sii', $status, $limit, $offset);
    $stmt->execute();
    
    return $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
}

// Get theme with tags (single query using JOIN)
function getThemeWithTags($themeId) {
    global $db;
    
    $stmt = $db->prepare("
        SELECT 
            t.id, t.name, t.author_id, t.author_name,
            t.description, t.version, t.download_count,
            t.is_featured, t.preview_image_url,
            t.theme_json_url, t.created_at, t.updated_at,
            GROUP_CONCAT(tt.tag) as tags
        FROM themes t
        LEFT JOIN theme_tags tt ON t.id = tt.theme_id
        WHERE t.id = ? AND t.status = 'approved'
        GROUP BY t.id
    ");
    
    $stmt->bind_param('s', $themeId);
    $stmt->execute();
    
    $result = $stmt->get_result()->fetch_assoc();
    
    if ($result && $result['tags']) {
        $result['tags'] = explode(',', $result['tags']);
    } else {
        $result['tags'] = [];
    }
    
    return $result;
}
```

**CDN Configuration:**
```
# Nginx configuration for theme assets
location /themes/ {
    alias /var/www/theme-store/public/themes/;
    
    # Cache for 1 year (themes are immutable)
    expires 1y;
    add_header Cache-Control "public, immutable";
    
    # CORS headers for cross-origin requests
    add_header Access-Control-Allow-Origin *;
    
    # Gzip compression
    gzip on;
    gzip_types application/json;
}

location /previews/ {
    alias /var/www/theme-store/public/previews/;
    
    # Cache for 1 week
    expires 1w;
    add_header Cache-Control "public";
    
    # WebP conversion for modern browsers
    set $webp_suffix "";
    if ($http_accept ~* "webp") {
        set $webp_suffix ".webp";
    }
    
    try_files $uri$webp_suffix $uri =404;
}
```

---

## 14. Analytics & Monitoring

### Client-Side Analytics Events

```swift
enum ThemeStoreAnalyticsEvent {
    case storeViewed
    case themeViewed(themeId: String)
    case themeDownloaded(themeId: String)
    case themeApplied(themeId: String)
    case searchPerformed(query: String, resultCount: Int)
    case themeUploaded(themeId: String)
    case uploadFailed(reason: String)
    case proUpgradePromptShown(feature: String)
}

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    func track(_ event: ThemeStoreAnalyticsEvent) {
        // Send to your analytics service
        switch event {
        case .storeViewed:
            logEvent("theme_store_viewed")
            
        case .themeViewed(let themeId):
            logEvent("theme_viewed", parameters: ["theme_id": themeId])
            
        case .themeDownloaded(let themeId):
            logEvent("theme_downloaded", parameters: ["theme_id": themeId])
            
        case .themeApplied(let themeId):
            logEvent("theme_applied", parameters: ["theme_id": themeId])
            
        case .searchPerformed(let query, let resultCount):
            logEvent("theme_search", parameters: [
                "query": query,
                "result_count": resultCount
            ])
            
        case .themeUploaded(let themeId):
            logEvent("theme_uploaded", parameters: ["theme_id": themeId])
            
        case .uploadFailed(let reason):
            logEvent("theme_upload_failed", parameters: ["reason": reason])
            
        case .proUpgradePromptShown(let feature):
            logEvent("pro_prompt_shown", parameters: ["feature": feature])
        }
    }
    
    private func logEvent(_ name: String, parameters: [String: Any] = [:]) {
        // Implement with your analytics SDK (Firebase, Mixpanel, etc.)
        print("📊 Analytics: \(name) \(parameters)")
    }
}
```

### Server-Side Monitoring

```php
<?php
// Log important events
class ThemeStoreLogger {
    public static function logThemeUpload($themeId, $userId, $status) {
        $data = [
            'event' => 'theme_uploaded',
            'theme_id' => $themeId,
            'user_id' => $userId,
            'status' => $status,
            'timestamp' => date('c')
        ];
        
        error_log(json_encode($data));
        
        // Send to monitoring service
        self::sendToMonitoring($data);
    }
    
    public static function logThemeDownload($themeId, $userId) {
        $data = [
            'event' => 'theme_downloaded',
            'theme_id' => $themeId,
            'user_id' => $userId,
            'timestamp' => date('c')
        ];
        
        error_log(json_encode($data));
        self::sendToMonitoring($data);
    }
    
    public static function logError($context, $error) {
        $data = [
            'event' => 'error',
            'context' => $context,
            'error' => $error,
            'timestamp' => date('c')
        ];
        
        error_log(json_encode($data));
        
        // Send to error tracking service (Sentry, Rollbar, etc.)
        self::sendToErrorTracking($data);
    }
    
    private static function sendToMonitoring($data) {
        // Implement monitoring integration
    }
    
    private static function sendToErrorTracking($data) {
        // Implement error tracking integration
    }
}

// Usage
ThemeStoreLogger::logThemeUpload($themeId, $userId, 'pending');
```

---

## 15. Testing Strategy

### Unit Tests (Swift)

```swift
import XCTest
@testable import SangamKeyboards

class ThemeStoreTests: XCTestCase {
    var viewModel: ThemeBrowserViewModel!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        viewModel = ThemeBrowserViewModel(apiClient: mockAPIClient)
    }
    
    func testLoadThemesSuccess() async {
        // Given
        let mockThemes = [
            ThemeMetadata(id: "theme1", name: "Theme 1", authorName: "Author 1", downloadCount: 100),
            ThemeMetadata(id: "theme2", name: "Theme 2", authorName: "Author 2", downloadCount: 200)
        ]
        mockAPIClient.mockThemes = mockThemes
        
        // When
        await viewModel.loadThemes(sortBy: .mostPopular)
        
        // Then
        XCTAssertEqual(viewModel.themes.count, 2)
        XCTAssertEqual(viewModel.themes[0].id, "theme1")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadThemesNetworkError() async {
        // Given
        mockAPIClient.shouldFail = true
        
        // When
        await viewModel.loadThemes(sortBy: .mostPopular)
        
        // Then
        XCTAssertTrue(viewModel.themes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testProUserCanAccessStore() {
        // Given
        let mockUser = MockUserManager(isPro: true)
        
        // When
        let canAccess = mockUser.canAccessThemeStore()
        
        // Then
        XCTAssertTrue(canAccess)
    }
    
    func testFreeUserCannotAccessStore() {
        // Given
        let mockUser = MockUserManager(isPro: false)
        
        // When
        let canAccess = mockUser.canAccessThemeStore()
        
        // Then
        XCTAssertFalse(canAccess)
    }
}
```

### Integration Tests (API)

```php
<?php
class ThemeStoreAPITest extends TestCase {
    public function testGetThemesRequiresPro() {
        // Given: Free user token
        $token = $this->generateToken(['isPro' => false]);
        
        // When: Attempt to get themes
        $response = $this->get('/api/v1/themes', [
            'Authorization' => "Bearer $token"
        ]);
        
        // Then: Should return 403
        $response->assertStatus(403);
        $response->assertJson([
            'success' => false,
            'error' => [
                'code' => 'PRO_REQUIRED'
            ]
        ]);
    }
    
    public function testUploadThemeSuccess() {
        // Given: Pro user and valid theme
        $token = $this->generateToken(['isPro' => true]);
        $theme = $this->generateValidTheme();
        
        // When: Upload theme
        $response = $this->post('/api/v1/themes', [
            'themeJson' => json_encode($theme),
            'metadata' => [
                'name' => 'Test Theme',
                'description' => 'A test theme for unit testing',
                'tags' => ['test', 'dark']
            ]
        ], [
            'Authorization' => "Bearer $token"
        ]);
        
        // Then: Should return 200 with pending status
        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
            'data' => [
                'status' => 'pending'
            ]
        ]);
        
        // Verify database
        $this->assertDatabaseHas('themes', [
            'name' => 'Test Theme',
            'status' => 'pending'
        ]);
    }
    
    public function testDownloadIncrementsCounter() {
        // Given: Approved theme
        $theme = $this->createApprovedTheme();
        $initialCount = $theme->download_count;
        
        // When: Download theme
        $token = $this->generateToken(['isPro' => true]);
        $response = $this->post("/api/v1/themes/{$theme->id}/download", [], [
            'Authorization' => "Bearer $token"
        ]);
        
        // Then: Download count should increment
        $theme->refresh();
        $this->assertEquals($initialCount + 1, $theme->download_count);
    }
}
```

---

## Appendix A: Complete API Reference

### Request/Response Examples

**Upload Theme Request:**
```http
POST /api/v1/themes HTTP/1.1
Host: api.sangamkeyboards.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "themeJson": "{\"schemaVersion\":\"1.0\",\"id\":\"my_theme\",...}",
  "metadata": {
    "name": "My Beautiful Theme",
    "description": "A minimalist dark theme with subtle accents",
    "tags": ["dark", "minimal", "modern"]
  }
}
```

**Upload Theme Response (Success):**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "data": {
    "themeId": "my_theme_abc123",
    "status": "pending",
    "message": "Theme submitted for approval. You'll be notified once it's reviewed.",
    "estimatedReviewTime": "24-48 hours"
  }
}
```

**Upload Theme Response (Validation Error):**
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Theme validation failed",
    "details": [
      "Theme name must be at least 3 characters",
      "Description is required",
      "Insufficient contrast ratio between regularKeyText and regularKeyBackground (2.8:1, minimum 4.5:1)"
    ]
  }
}
```

---

## Appendix B: Webhook Events (Optional)

For advanced integration, theme store can send webhooks on certain events:

### Theme Approved
```json
{
  "event": "theme.approved",
  "timestamp": "2025-10-17T10:30:00Z",
  "data": {
    "themeId": "neon_dreams",
    "themeName": "Neon Dreams",
    "authorId": "user_12345",
    "approvedBy": "admin_1",
    "approvedAt": "2025-10-17T10:30:00Z"
  }
}
```

### Theme Rejected
```json
{
  "event": "theme.rejected",
  "timestamp": "2025-10-17T10:30:00Z",
  "data": {
    "themeId": "bad_theme",
    "themeName": "Bad Theme",
    "authorId": "user_12345",
    "rejectedBy": "admin_1",
    "rejectedAt": "2025-10-17T10:30:00Z",
    "reason": "Insufficient color contrast"
  }
}
```

### Milestone Reached
```json
{
  "event": "theme.milestone",
  "timestamp": "2025-10-17T10:30:00Z",
  "data": {
    "themeId": "neon_dreams",
    "themeName": "Neon Dreams",
    "authorId": "user_12345",
    "milestone": "1000_downloads",
    "downloadCount": 1000
  }
}
```

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 17, 2025 | Product Team | Initial specification |

---

**End of Document 4: iOS Theme Store & Backend API Specification**

---

This is document 4 of 5. Should I proceed with document 5 (Android Theme Implementation Guide)?