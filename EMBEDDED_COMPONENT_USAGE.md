# Embedded PDF Annotation Component

This document explains how to use the embedded PDF annotation component that can be placed within your React Native layout.

## Overview

The embedded component (`PDFAnnotationView`) can be used as a regular React Native View, allowing you to:
- Place it anywhere in your layout
- Size it to take up half the screen, a portion, or any size you want
- Have other components alongside it (headers, sidebars, etc.)
- Control annotation mode programmatically
- Export annotated PDFs

## Files Required

### iOS Native Files (Add to `ios/YourAppName/`)

**Core PDF Classes (Required - from `pdf-kit-2/pdf-kit-2/` folder):**
1. **MyPDFDocument.swift** - Custom PDF document class
2. **MyPDFPage.swift** - Custom PDF page class with drawing storage
3. **MyPDFAnnotation.swift** - Custom annotation class for rendering
4. **PDFPageOverlayProvider.swift** - Overlay provider for PencilKit canvases

**Embedded Component Files (Required - from root folder):**
5. **RNPDFAnnotatorView.swift** - Native UIView component with integrated toolbar
6. **RNPDFAnnotatorViewManager.mm** - React Native bridge (Objective-C++)
7. **RNAnnotationToolbar.swift** - UIKit toolbar with annotate toggle and tools

### TypeScript Files (Add to your React Native project)

8. **RNPDFAnnotatorView.tsx** - TypeScript React component wrapper (from root folder)
9. **example-embedded-component.tsx** - Complete usage example (from root folder)

## Setup Instructions

### 1. Add Files to Xcode Project

**Required Files to Add:**

**Core PDF Classes (from `pdf-kit-2/pdf-kit-2/` folder):**
- `MyPDFDocument.swift`
- `MyPDFPage.swift`
- `MyPDFAnnotation.swift`
- `PDFPageOverlayProvider.swift`

**Embedded Component Files (from root folder):**
- `RNPDFAnnotatorView.swift`
- `RNPDFAnnotatorViewManager.mm`
- `RNAnnotationToolbar.swift`

**Important:** 
- Make sure all Swift files are added to your target's "Compile Sources" in Build Phases
- Add `RNPDFAnnotatorViewManager.mm` to your target as well

### 2. Configure Bridging Header (if needed)

If you get compilation errors about Swift headers, you may need to:

1. In Xcode, go to **Build Settings**
2. Search for **"Objective-C Generated Interface Header Name"**
3. Set it to: `pdf-kit-2-Swift.h` (or your module name)
4. Or manually import the generated header in `RNPDFAnnotatorViewManager.mm`:
   ```objc
   #import "pdf-kit-2-Swift.h"
   ```

### 3. Import in React Native

```tsx
import { PDFAnnotationView } from './RNPDFAnnotatorView';
```

## Usage Example

### Basic Usage

```tsx
import React, { useState, useRef } from 'react';
import { View, StyleSheet } from 'react-native';
import { PDFAnnotationView } from './RNPDFAnnotatorView';

export default function MyScreen() {
  // Note: The component has a built-in toolbar that appears when PDF is loaded
  // The toolbar has an "Annotate" button to toggle annotation mode
  // You can also control annotation mode via the isAnnotating prop
  const pdfViewRef = useRef<PDFAnnotationView>(null);

  return (
    <View style={styles.container}>
      {/* Built-in toolbar is automatically shown when PDF loads */}
      <PDFAnnotationView
        ref={pdfViewRef}
        style={styles.pdfView}
        pdfURL="https://example.com/document.pdf"
        onPDFLoaded={(event) => {
          console.log('PDF loaded:', event.nativeEvent.pageCount);
        }}
        onPDFLoadError={(event) => {
          console.error('Error:', event.nativeEvent.error);
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  pdfView: {
    flex: 1,
  },
});
```

### Split Screen Layout

```tsx
<View style={styles.container}>
  {/* Header */}
  <View style={styles.header}>
    <Text>My App Header</Text>
  </View>

  {/* Content - Split View */}
  <View style={styles.contentContainer}>
    {/* Left Half - PDF */}
    <View style={styles.pdfContainer}>
      <PDFAnnotationView
        ref={pdfViewRef}
        style={styles.pdfView}
        pdfURL={pdfURL}
        isAnnotating={isAnnotating}
        drawWithFinger={drawWithFinger}
        onPDFLoaded={handlePDFLoaded}
      />
    </View>

    {/* Right Half - Other Components */}
    <View style={styles.sidePanel}>
      <Text>Settings Panel</Text>
      <Button 
        title="Toggle Annotation"
        onPress={() => setIsAnnotating(!isAnnotating)}
      />
    </View>
  </View>
</View>
```

### Export Annotated PDF

```tsx
const handleExport = async () => {
  if (!pdfViewRef.current) return;
  
  try {
    const result = await pdfViewRef.current.exportAnnotatedPDF();
    console.log('Exported to:', result.filePath);
  } catch (error) {
    console.error('Export failed:', error);
  }
};
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `pdfURL` | `string` | - | URL of PDF to load (remote http/https or local file://) |
| `isAnnotating` | `boolean` | `false` | Enable/disable annotation mode (can also use toolbar button) |
| `drawWithFinger` | `boolean` | `true` | Allow finger drawing (false = pencil only) |
| `brushSettings` | `BrushSettings` | - | **New!** Tool settings: type, color, width, opacity, eraserType |
| `toolType` | `ToolType` | - | Legacy: Tool type ('pen', 'pencil', 'highlighter', 'eraser') |
| `toolColor` | `string` | - | Legacy: Hex color string |
| `toolWidth` | `number` | - | Legacy: Stroke width |
| `toolOpacity` | `number` | - | Legacy: Opacity 0.0-1.0 |
| `onPDFLoaded` | `function` | - | Called when PDF loads successfully |
| `onPDFLoadError` | `function` | - | Called when PDF fails to load |
| `onAnnotationComplete` | `function` | - | Called when annotation is complete |
| `onAnnotationCancel` | `function` | - | Called when annotation is cancelled |

**Note:** The component includes a built-in toolbar that appears when the PDF is loaded. The toolbar provides:
- "Annotate" button (when not annotating)
- Full tool set when annotating (pen, pencil, highlighter, eraser, PencilKit toggle)
- Page number display
- Undo/Redo buttons
- Finger drawing toggle

## Methods

### `exportAnnotatedPDF()`

Exports the annotated PDF and returns a promise with the file path.

```tsx
const result = await pdfViewRef.current.exportAnnotatedPDF();
// result.filePath contains the path to the exported PDF
```

## Events

### `onPDFLoaded`

```tsx
onPDFLoaded={(event) => {
  const { pageCount } = event.nativeEvent;
  console.log(`PDF loaded with ${pageCount} pages`);
}}
```

### `onPDFLoadError`

```tsx
onPDFLoadError={(event) => {
  const { error } = event.nativeEvent;
  console.error('PDF load error:', error);
}}
```

### `onAnnotationComplete`

```tsx
onAnnotationComplete={(event) => {
  const { filePath } = event.nativeEvent;
  console.log('Annotation complete:', filePath);
}}
```

## Gestures

- **Two-finger swipe up**: Go to next page
- **Two-finger swipe down**: Go to previous page
- **Single finger/drawing**: Draw annotations (when `isAnnotating` is true)

## Differences from Modal Component

| Feature | Modal (`RNPDFAnnotator`) | Embedded (`PDFAnnotationView`) |
|---------|---------------------------|--------------------------------|
| **Presentation** | Full-screen modal | Embedded in layout |
| **Layout Control** | None (covers screen) | Full control via styles |
| **Other Components** | Blocks entire app | Can have components alongside |
| **Use Case** | Standalone annotation | Part of larger screen |
| **API** | Function call | React Component |

## Complete Example

See `example-embedded-component.tsx` for a complete example showing:
- Split-screen layout (PDF on left, controls on right)
- Header component
- Settings panel
- Annotation controls
- Export functionality

