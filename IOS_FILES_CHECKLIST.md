# iOS Files Checklist for React Native Integration

This checklist helps you ensure all required files are added to your React Native iOS project.

## ✅ Required Files

### Core PDF Classes (Required - Copy from `pdf-kit-2/pdf-kit-2/` folder)

- [ ] **MyPDFDocument.swift** - Custom PDF document class
- [ ] **MyPDFPage.swift** - Custom PDF page class with drawing storage
- [ ] **MyPDFAnnotation.swift** - Custom annotation class for rendering
- [ ] **PDFPageOverlayProvider.swift** - Overlay provider for PencilKit canvases

### Embedded Component Files (Copy from root folder)

- [ ] **RNPDFAnnotatorView.swift** - Main embedded UIView component
- [ ] **RNPDFAnnotatorViewManager.mm** - React Native ViewManager bridge
- [ ] **RNAnnotationToolbar.swift** - UIKit toolbar with annotate toggle and tools

### Modal Component Files (Optional - Copy from root folder)

- [ ] **RNPDFAnnotator.swift** - Modal component native module
- [ ] **RNPDFAnnotator.m** - Objective-C bridge for modal
- [ ] **PDFAnnotationViewController.swift** - Full-screen view controller

### TypeScript Files (Add to your React Native project)

- [ ] **RNPDFAnnotatorView.tsx** - TypeScript component (copy to `src/components/`)
- [ ] **RNPDFAnnotator.ts** - Modal component types (copy to `src/modules/` if using modal)

## File Locations Reference

### Source Files (Where to copy FROM)

```
pdf-kit-2/
├── pdf-kit-2/              ← Copy these files:
│   ├── MyPDFDocument.swift
│   ├── MyPDFPage.swift
│   ├── MyPDFAnnotation.swift
│   └── PDFPageOverlayProvider.swift
│
└── [root]/                 ← Copy these files:
    ├── RNPDFAnnotatorView.swift
    ├── RNPDFAnnotatorViewManager.mm
    ├── RNAnnotationToolbar.swift
    ├── RNPDFAnnotator.swift         (Optional)
    ├── RNPDFAnnotator.m              (Optional)
    ├── PDFAnnotationViewController.swift (Optional)
    ├── RNPDFAnnotatorView.tsx
    └── RNPDFAnnotator.ts             (Optional)
```

### Destination (Where to copy TO in your React Native project)

```
YourReactNativeApp/
├── ios/
│   └── YourAppName/
│       ├── MyPDFDocument.swift              ✅ Core
│       ├── MyPDFPage.swift                   ✅ Core
│       ├── MyPDFAnnotation.swift            ✅ Core
│       ├── PDFPageOverlayProvider.swift     ✅ Core
│       ├── RNPDFAnnotatorView.swift         ✅ Embedded
│       ├── RNPDFAnnotatorViewManager.mm     ✅ Embedded
│       ├── RNAnnotationToolbar.swift        ✅ Embedded
│       ├── RNPDFAnnotator.swift             ⚪ Modal (optional)
│       ├── RNPDFAnnotator.m                 ⚪ Modal (optional)
│       └── PDFAnnotationViewController.swift ⚪ Modal (optional)
│
└── src/
    ├── components/
    │   └── RNPDFAnnotatorView.tsx           ✅ Embedded
    └── modules/
        └── RNPDFAnnotator.ts                ⚪ Modal (optional)
```

## Quick Copy Script

Save this as `copy-ios-files.sh` and run it:

```bash
#!/bin/bash

# Set your React Native app name
RN_APP_NAME="YourAppName"

# Set source paths (update these to match your pdf-kit-2 location)
SOURCE_ROOT="/path/to/pdf-kit-2"
DEST_ROOT="/path/to/YourReactNativeApp"

# Core PDF classes (from pdf-kit-2 subfolder)
cp "$SOURCE_ROOT/pdf-kit-2/MyPDFDocument.swift" "$DEST_ROOT/ios/$RN_APP_NAME/"
cp "$SOURCE_ROOT/pdf-kit-2/MyPDFPage.swift" "$DEST_ROOT/ios/$RN_APP_NAME/"
cp "$SOURCE_ROOT/pdf-kit-2/MyPDFAnnotation.swift" "$DEST_ROOT/ios/$RN_APP_NAME/"
cp "$SOURCE_ROOT/pdf-kit-2/PDFPageOverlayProvider.swift" "$DEST_ROOT/ios/$RN_APP_NAME/"

# Embedded component files (from root)
cp "$SOURCE_ROOT/RNPDFAnnotatorView.swift" "$DEST_ROOT/ios/$RN_APP_NAME/"
cp "$SOURCE_ROOT/RNPDFAnnotatorViewManager.mm" "$DEST_ROOT/ios/$RN_APP_NAME/"
cp "$SOURCE_ROOT/RNAnnotationToolbar.swift" "$DEST_ROOT/ios/$RN_APP_NAME/"

# TypeScript files
mkdir -p "$DEST_ROOT/src/components"
mkdir -p "$DEST_ROOT/src/modules"
cp "$SOURCE_ROOT/RNPDFAnnotatorView.tsx" "$DEST_ROOT/src/components/"
cp "$SOURCE_ROOT/RNPDFAnnotator.ts" "$DEST_ROOT/src/modules/"

echo "✅ Files copied successfully!"
echo "📝 Next steps:"
echo "1. Open your project in Xcode"
echo "2. Add files to your target"
echo "3. Run: cd ios && pod install && cd .."
echo "4. Build and run!"
```

## Xcode Setup Steps

1. **Open Xcode**: Open `ios/YourApp.xcworkspace` (not `.xcodeproj`)
2. **Add Files**: Right-click your app folder → "Add Files to YourApp..."
3. **Select Files**: Select all the `.swift` and `.mm` files you copied
4. **Check Options**: 
   - ✅ "Copy items if needed"
   - ✅ Add to targets: YourApp
5. **Build Settings**:
   - Set "Objective-C Bridging Header" to `YourApp/YourApp-Bridging-Header.h`
6. **Run Pod Install**: `cd ios && pod install && cd ..`

## Verification

After adding files, verify in Xcode:

1. All files appear in Project Navigator
2. Files are checked in Target Membership (File Inspector)
3. No red errors in Project Navigator
4. Build succeeds (Cmd+B)

## Features by File

| File | Features It Enables |
|------|-------------------|
| `MyPDFDocument.swift` | Custom PDF document loading |
| `MyPDFPage.swift` | Per-page drawing storage |
| `MyPDFAnnotation.swift` | Burn annotations into PDF |
| `PDFPageOverlayProvider.swift` | PencilKit canvas overlay, tool management, undo/redo |
| `RNPDFAnnotatorView.swift` | Embedded PDF view, toolbar integration |
| `RNPDFAnnotatorViewManager.mm` | React Native bridge for embedded view |
| `RNAnnotationToolbar.swift` | Built-in toolbar with annotate toggle, tools, undo/redo |
| `RNPDFAnnotatorView.tsx` | TypeScript component for React Native |
| `RNPDFAnnotator.ts` | TypeScript types for modal (optional) |

