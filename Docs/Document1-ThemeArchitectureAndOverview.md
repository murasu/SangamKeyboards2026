Great idea! Let me assess what we need to document.

## Documents Needed

Based on our discussion, I recommend **5 separate documents**:

1. **Theme System Architecture & Overview** - High-level system design, components, user flows, business rules
2. **Theme JSON Schema Specification** - Complete JSON format, field definitions, platform compatibility
3. **iOS Theme Editor Specification** - Detailed UI/UX specs, SwiftUI implementation guidelines
4. **iOS Theme Store & Backend API Specification** - Store UI, server API endpoints, database schema
5. **Android Theme Implementation Guide** - GradientDrawable approach, code modifications needed

Let me start with the first document:

---

# Theme System Architecture & Overview

**Project:** Sangam Keyboards - Cross-Platform Theme System  
**Version:** 1.0  
**Date:** October 17, 2025  
**Author:** System Architecture Documentation

## Table of Contents
1. Executive Summary
2. System Architecture
3. Platform Support
4. User Roles & Permissions
5. Theme Lifecycle
6. Business Rules
7. Technical Constraints
8. Implementation Phases

---

## 1. Executive Summary

### Project Goal
Build a cross-platform keyboard theme system that allows users to customize keyboard appearance. Pro users can create, share, and browse themes through a curated store. Free users can use system themes and themes shared directly by friends.

### Key Principles
- **Simplicity First** - Avoid over-engineering, focus on delightful UX
- **Platform Parity** - iOS first, Android follows with same JSON format
- **Creator-Focused** - Pro users are content creators who want visibility
- **Curated Quality** - All store themes require manual approval
- **No DRM** - Themes are shareable, Pro unlocks store access and creator tools

### Success Metrics
- Number of Pro users creating themes
- Theme download counts
- User engagement with theme customization
- Conversion rate from free to Pro

---

## 2. System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        USERS                                 │
│  ┌─────────────┐              ┌─────────────┐              │
│  │  Free User  │              │  Pro User   │              │
│  └─────────────┘              └─────────────┘              │
└────────┬────────────────────────────┬────────────────────────┘
         │                            │
         │                            │
┌────────▼────────────────────────────▼────────────────────────┐
│                     iOS APPLICATION                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Keyboard   │  │    Theme     │  │    Theme     │       │
│  │  Extension   │  │    Editor    │  │    Store     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└───────────────────────────────┬───────────────────────────────┘
                                │
                                │ HTTP/JSON
                                │
┌───────────────────────────────▼───────────────────────────────┐
│                    BACKEND SERVER (PHP)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Theme API  │  │    MySQL     │  │    Admin     │       │
│  │  (REST/JSON) │  │   Database   │  │    Panel     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└───────────────────────────────┬───────────────────────────────┘
                                │
                                │ (Future)
                                │
┌───────────────────────────────▼───────────────────────────────┐
│                  ANDROID APPLICATION                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Keyboard    │  │    Theme     │  │    Theme     │       │
│  │     IME      │  │    Editor    │  │    Store     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└───────────────────────────────────────────────────────────────┘
```

### Three Core Components

#### 1. Theme Editor (iOS/Android Apps)
- Create and edit keyboard themes
- Live preview of changes
- Metadata entry (name, description, author)
- Save themes locally
- Export/share themes (Pro only)
- Upload to store (Pro only, requires approval)

#### 2. Theme Store (iOS/Android Apps)
- Browse curated themes (Pro only)
- Download themes
- View theme details and download counts
- "My Themes" section for creators
- Search and filter capabilities

#### 3. Backend Server (PHP + MySQL)
- REST API for theme operations
- Theme storage and retrieval
- User authentication and Pro status verification
- Admin approval workflow
- Download count tracking
- Theme metadata management

---

## 3. Platform Support

### iOS (Phase 1 - Current Focus)
- **Status:** In Development
- **Timeline:** 4-6 weeks
- **Features:** Full theme support including gradients, shadows, custom fonts
- **Rendering:** Direct SwiftUI/UIKit drawing
- **Minimum Version:** iOS 14.0+

### Android (Phase 2 - Future)
- **Status:** Planned
- **Timeline:** 1-2 weeks after iOS completion
- **Features:** 90% theme compatibility (no gradients initially)
- **Rendering:** GradientDrawable-based (minimal code changes)
- **Minimum Version:** Android 7.0+ (API 24)

### Theme Format
- **Storage:** JSON files
- **Schema Version:** 1.0
- **Platform Agnostic:** Same JSON works for both platforms
- **iOS-Specific Properties:** Prefixed with underscore, ignored by Android
- **Size Limit:** 50KB per theme file

---

## 4. User Roles & Permissions

### Free Users

**Can:**
- ✅ Use all system-provided themes (bundled with app)
- ✅ Receive themes via AirDrop/WhatsApp/file sharing
- ✅ Use imported themes
- ✅ Create themes in editor (stored locally only)
- ✅ Edit their own created themes

**Cannot:**
- ❌ Browse public theme store - only the themes bundled in the app
- ❌ Download themes from store
- ❌ Upload themes to store
- ❌ Share themes from editor (no export button)
- ❌ Edit themes downloaded/imported from others

### Pro Users

**Can (All Free User Capabilities Plus):**
- ✅ Browse theme store
- ✅ Download unlimited themes from store
- ✅ Upload their created themes to store (requires approval)
- ✅ Share their created themes via AirDrop/WhatsApp/file
- ✅ View download statistics for their uploaded themes
- ✅ Edit and re-upload their store themes (re-approval required)

**Cannot:**
- ❌ Edit other users' themes (downloaded from store)
- ❌ Approve/reject themes (admin only)
- ❌ Share other users' themes from the store

### Admin Users

**Can (All Pro User Capabilities Plus):**
- ✅ Review pending theme submissions
- ✅ Approve themes for store publication
- ✅ Reject themes with feedback
- ✅ Remove published themes
- ✅ View all theme statistics
- ✅ Manage user accounts

---

## 5. Theme Lifecycle

### Creation Flow
```
1. User opens Theme Editor
2. User creates new theme or duplicates existing
3. User edits theme properties with live preview
4. User fills in metadata (name, description, tags)
5. User saves theme locally
   ├─ Free User: Theme stored locally only
   └─ Pro User: Option to upload to store appears
```

### Upload & Approval Flow (Pro Users Only)
```
1. Pro user clicks "Upload to Store" in editor
2. App validates theme (required fields, file size)
3. App sends theme JSON + metadata to server
4. Server stores theme with status="pending"
5. Server sends notification to admin
6. Admin reviews theme in admin panel
   ├─ APPROVE → status="approved", appears in store
   └─ REJECT → status="rejected", creator notified
7. If approved, theme appears in store for all Pro users
```

### Download Flow (Pro Users Only)
```
1. Pro user browses theme store
2. User taps theme to view details
3. User taps "Download" button
4. App downloads theme JSON from server
5. Server increments download count
6. Theme saved to user's device
7. Theme available in keyboard settings
8. User can apply theme to keyboard
```

### Sharing Flow (Direct, Not Through Store)
```
1. Pro user opens their created theme in editor
2. User taps "Share" button
3. iOS share sheet appears (AirDrop, WhatsApp, etc.)
4. Theme exported as .theme or .json file
5. Recipient receives file
6. Recipient taps file to import
7. App imports theme to local storage
8. Recipient can use theme (but not edit or re-share)
```

---

## 6. Business Rules

### Theme Ownership
- **Creator owns theme permanently**
- Only creator can edit their theme
- Editing uploaded theme requires re-approval
- Creator can delete their uploaded themes
- Downloaded themes are read-only for downloaders

### Theme Approval
- **All uploads require manual approval** (no auto-publish)
- Approval typically within 24-48 hours
- Rejection includes feedback/reason
- Creator can fix and re-submit
- No limit on submission attempts

### Theme Store Access
- **Store browsing requires Pro subscription**
- Download capability requires active Pro subscription
- If Pro expires, previously downloaded themes remain usable
- Theme store unavailable to free users (no paywall prompts within store)

### Theme Sharing
- **Direct sharing is unrestricted** (AirDrop, WhatsApp, etc.)
- Only creator can share their own themes
- Cannot share themes downloaded from store
- Cannot share system-provided themes
- Free users can receive shared themes

### Theme Validation
- **Required fields:** id, name, version, author, light theme, dark theme
- **File size limit:** 50KB maximum
- **Color format:** Hex colors only (#RRGGBB or #AARRGGBB)
- **Name length:** 3-50 characters
- **Description length:** 10-200 characters
- **Profanity filter:** Auto-check theme names and descriptions

### Theme Deletion
- Creator can delete their local themes anytime
- Creator can request removal of store themes (admin approval)
- Deleted store themes remain on users' devices who downloaded them
- Download counts preserved even after deletion

---

## 7. Technical Constraints

### iOS Constraints
- Keyboard extension height fixed by device (cannot change)
- System globe key area not customizable
- Limited to specific iOS APIs in keyboard extension
- App Group required for data sharing between app and extension

### Android Constraints
- No gradient support in Phase 1 (GradientDrawable limitation avoided)
- Shadow rendering differs from iOS (elevation-based)
- Different keyboard height metrics per device
- Latin IME codebase must remain stable

### Backend Constraints
- Theme file size: 50KB maximum
- API rate limiting: 100 requests/hour per user
- Image uploads not supported (auto-generated preview only)
- Theme count per user: No limit but monitored for abuse

### Network Constraints
- Theme download must work on slow connections
- Offline mode: Use cached/local themes only
- Upload retry logic for failed submissions
- Thumbnail generation for store previews

---

## 8. Implementation Phases

### Phase 1: iOS Core (Weeks 1-6)

**Week 1-2: Theme Editor**
- Accordion-style editor UI
- Live preview implementation
- Metadata input forms
- Local theme storage
- Theme validation

**Week 3-4: Backend & API**
- Database schema design
- REST API endpoints
- Authentication system
- Admin approval workflow
- Theme upload/download logic

**Week 5: Theme Store**
- Store browsing UI
- Theme details view
- Download functionality
- "My Themes" section
- Search and filters

**Week 6: Integration & Testing**
- Connect editor to backend
- Pro/Free user differentiation
- End-to-end testing
- Bug fixes
- Beta release

### Phase 2: Android Implementation (Weeks 7-8)

**Week 7: Android Theme Support**
- KeyboardThemeConfig class
- JSON parser implementation
- GradientDrawable factory
- Theme application to keyboard
- Testing on multiple devices

**Week 8: Android Editor & Store**
- Port editor UI to Android
- Implement theme store
- Connect to existing backend
- Testing and bug fixes
- Production release

### Phase 3: Enhancements (Future)

**Potential Features:**
- Theme ratings and reviews
- Theme collections/categories
- Seasonal/featured themes
- Theme preview GIFs/videos
- Social sharing integration
- Theme remix capability (with attribution)
- Android gradient support (full direct drawing)
- Custom font support
- Animation/transition themes

---

## 9. Data Flow Diagrams

### Theme Creation & Upload
```
┌─────────┐         ┌─────────┐         ┌─────────┐         ┌─────────┐
│  User   │         │  Theme  │         │ Backend │         │  Admin  │
│ Editor  │         │   API   │         │   DB    │         │  Panel  │
└────┬────┘         └────┬────┘         └────┬────┘         └────┬────┘
     │                   │                   │                   │
     │ Create Theme      │                   │                   │
     ├──────────────────>│                   │                   │
     │                   │                   │                   │
     │ Upload Theme      │                   │                   │
     ├──────────────────>│                   │                   │
     │                   │ Store Theme       │                   │
     │                   ├──────────────────>│                   │
     │                   │ (status=pending)  │                   │
     │                   │                   │                   │
     │                   │                   │ Notify New        │
     │                   │                   │ Submission        │
     │                   │                   ├──────────────────>│
     │                   │                   │                   │
     │                   │                   │                   │ Review
     │                   │                   │                   ├────┐
     │                   │                   │                   │    │
     │                   │                   │                   │<───┘
     │                   │                   │                   │
     │                   │                   │ Update Status     │
     │                   │                   │<──────────────────┤
     │                   │                   │ (approved/rejected)│
     │ Notification      │ Theme Approved    │                   │
     │<──────────────────┤<──────────────────┤                   │
     │                   │                   │                   │
```

### Theme Discovery & Download
```
┌─────────┐         ┌─────────┐         ┌─────────┐
│   Pro   │         │  Theme  │         │ Backend │
│  User   │         │  Store  │         │   DB    │
└────┬────┘         └────┬────┘         └────┬────┘
     │                   │                   │
     │ Browse Store      │                   │
     ├──────────────────>│                   │
     │                   │ Fetch Themes      │
     │                   ├──────────────────>│
     │                   │ (status=approved) │
     │                   │                   │
     │                   │ Theme List        │
     │ Display Themes    │<──────────────────┤
     │<──────────────────┤                   │
     │                   │                   │
     │ Tap Download      │                   │
     ├──────────────────>│                   │
     │                   │ Get Theme JSON    │
     │                   ├──────────────────>│
     │                   │                   │
     │                   │ Theme Data +      │
     │                   │ Increment Count   │
     │ Save Locally      │<──────────────────┤
     │<──────────────────┤                   │
     │                   │                   │
```

---

## 10. Security Considerations

### Authentication
- JWT tokens for API authentication
- Pro status verified server-side on every request
- Token expiration: 24 hours
- Refresh token mechanism for longer sessions

### Data Validation
- Server-side validation of all theme properties
- SQL injection prevention (parameterized queries)
- XSS prevention in theme metadata
- File size validation before storage
- Color hex format validation

### Privacy
- User email addresses not exposed in themes
- Creator name is public (part of theme metadata)
- Download statistics aggregated, not per-user
- No tracking of theme usage after download

### Rate Limiting
- Upload: 10 themes per hour per user
- Download: 100 themes per hour per user
- API calls: 1000 requests per hour per user
- Admin actions: No rate limit

---

## 11. Monitoring & Analytics

### Key Metrics to Track
- Theme creation count (daily/weekly/monthly)
- Theme upload count
- Theme approval rate (approved/rejected ratio)
- Average approval time
- Theme download count (per theme, total)
- Active Pro users using theme features
- Theme sharing activity (via analytics)
- App crashes related to theme rendering

### Admin Dashboard
- Pending approval queue
- Recently approved themes
- Most downloaded themes
- User submission history
- Rejection reasons breakdown
- System health metrics

---

## 12. Error Handling

### User-Facing Errors
- **Upload failed:** Retry button, offline detection
- **Download failed:** Auto-retry, cache mechanism
- **Theme invalid:** Clear error messages with fix suggestions
- **Pro required:** Upgrade prompt with feature explanation
- **Approval rejected:** Display rejection reason, allow resubmission

### System Errors
- **Database failure:** Graceful degradation, use cached data
- **API timeout:** Retry with exponential backoff
- **Theme parsing error:** Fall back to default theme
- **Storage full:** Warn user, offer cleanup options

---

## 13. Future Considerations

### Scalability
- CDN for theme file distribution
- Database sharding for large theme libraries
- Caching strategy for frequently downloaded themes
- Load balancing for API servers

### Internationalization
- Theme names in multiple languages
- Localized theme descriptions
- Regional theme recommendations
- Right-to-left language support

### Accessibility
- High contrast theme validation
- Color blindness friendly themes
- Screen reader compatible theme editor
- Keyboard navigation in theme store

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 17, 2025 | Architecture Team | Initial document creation |

---

**End of Document 1: Theme System Architecture & Overview**

---

This is document 1 of 5. Should I proceed with document 2 (Theme JSON Schema Specification)?