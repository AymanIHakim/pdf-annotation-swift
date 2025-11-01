# React Native Integration Guide

This guide shows how to integrate the PDF annotation functionality into your React Native app.

## Two Integration Options

This library provides **two ways** to use PDF annotation in React Native:

1. **Modal Component** (`RNPDFAnnotator`) - Full-screen modal that covers the entire screen
2. **Embedded Component** (`PDFAnnotationView`) - Embeddable view that can be placed in your layout

### Which Should I Use?

| Feature | Modal Component | Embedded Component |
|---------|----------------|-------------------|
| **Presentation** | Full-screen modal | Embedded in layout |
| **Layout Control** | None (covers screen) | Full control via styles |
| **Other Components** | Blocks entire app | Can have components alongside |
| **Use Case** | Standalone annotation | Part of larger screen |
| **API** | Function call | React Component |
| **Best For** | Simple annotation flows | Custom layouts, split screens, sidebars |

**Choose Modal if:**
- You want a simple, standalone annotation experience
- Users should focus only on annotating
- You don't need other components visible

**Choose Embedded if:**
- You need the PDF to take up part of the screen
- You want side-by-side components (headers, sidebars, settings)
- You need full layout control
- You're building a complex screen with multiple components

## Architecture

```
React Native (JavaScript/TypeScript)
          ↓
   Native Module Bridge
          ↓
   Swift PDF Annotation Code
          ↓
   Returns Annotated PDF File Path
```

## Files Needed for React Native iOS Integration

### Required iOS Native Files

Add these files to your React Native iOS project (typically in `ios/YourAppName/`):

#### **Core PDF Classes (Required for both Modal and Embedded)**
1. **`MyPDFDocument.swift`** - Custom PDF document class (from `pdf-kit-2/MyPDFDocument.swift`)
2. **`MyPDFPage.swift`** - Custom PDF page class with drawing storage (from `pdf-kit-2/MyPDFPage.swift`)
3. **`MyPDFAnnotation.swift`** - Custom annotation class for rendering (from `pdf-kit-2/MyPDFAnnotation.swift`)
4. **`PDFPageOverlayProvider.swift`** - Overlay provider that manages PencilKit canvases (from `pdf-kit-2/PDFPageOverlayProvider.swift`)

#### **For Embedded Component (Recommended)**
5. **`RNPDFAnnotatorView.swift`** - Embedded UIView component with integrated toolbar
6. **`RNPDFAnnotatorViewManager.mm`** - React Native ViewManager bridge (Objective-C++)
7. **`RNAnnotationToolbar.swift`** - UIKit-based toolbar with annotate toggle and tools

#### **For Modal Component (Full-Screen - Optional)**
8. **`RNPDFAnnotator.swift`** - Main native module for modal presentation
9. **`RNPDFAnnotator.m`** - Objective-C bridge for modal component
10. **`PDFAnnotationViewController.swift`** - Native view controller for full-screen annotation

#### **TypeScript/JavaScript Files (Add to your React Native project)**

11. **`RNPDFAnnotatorView.tsx`** - TypeScript component for embedded view (from root folder)
12. **`RNPDFAnnotator.ts`** - TypeScript types for modal component (from root folder, if using modal)

### File Organization in Your React Native Project

```
YourReactNativeApp/
├── ios/
│   └── YourAppName/
│       ├── MyPDFDocument.swift
│       ├── MyPDFPage.swift
│       ├── MyPDFAnnotation.swift
│       ├── PDFPageOverlayProvider.swift
│       ├── RNPDFAnnotatorView.swift      (Embedded Component)
│       ├── RNPDFAnnotatorViewManager.mm  (Embedded Component)
│       ├── RNAnnotationToolbar.swift     (Embedded Component - New!)
│       ├── RNPDFAnnotator.swift          (Modal Component - Optional)
│       ├── RNPDFAnnotator.m              (Modal Component - Optional)
│       └── PDFAnnotationViewController.swift (Modal Component - Optional)
├── src/
│   ├── components/
│   │   └── RNPDFAnnotatorView.tsx        (Copy from root)
│   └── modules/
│       └── RNPDFAnnotator.ts              (Copy from root, if using modal)
└── ...
```

### Copy Commands

```bash
# Navigate to your React Native project
cd YourReactNativeApp

# Copy core PDF classes (from pdf-kit-2 subfolder)
cp /path/to/pdf-kit-2/pdf-kit-2/MyPDFDocument.swift ios/YourAppName/
cp /path/to/pdf-kit-2/pdf-kit-2/MyPDFPage.swift ios/YourAppName/
cp /path/to/pdf-kit-2/pdf-kit-2/MyPDFAnnotation.swift ios/YourAppName/
cp /path/to/pdf-kit-2/pdf-kit-2/PDFPageOverlayProvider.swift ios/YourAppName/

# Copy embedded component files (from root folder)
cp /path/to/pdf-kit-2/RNPDFAnnotatorView.swift ios/YourAppName/
cp /path/to/pdf-kit-2/RNPDFAnnotatorViewManager.mm ios/YourAppName/
cp /path/to/pdf-kit-2/RNAnnotationToolbar.swift ios/YourAppName/

# Copy modal component files (if using modal - from root folder)
cp /path/to/pdf-kit-2/RNPDFAnnotator.swift ios/YourAppName/
cp /path/to/pdf-kit-2/RNPDFAnnotator.m ios/YourAppName/
cp /path/to/pdf-kit-2/PDFAnnotationViewController.swift ios/YourAppName/

# Copy TypeScript files to your React Native project
cp /path/to/pdf-kit-2/RNPDFAnnotatorView.tsx src/components/
cp /path/to/pdf-kit-2/RNPDFAnnotator.ts src/modules/  # Only if using modal
```

## Setup Instructions

### 1. Add Files to Your React Native iOS Project

```bash
# Navigate to your React Native project
cd YourReactNativeApp

# Copy the native files to iOS folder
cp /path/to/pdf-kit-2/*.swift ios/YourAppName/
cp /path/to/pdf-kit-2/RNPDFAnnotator.m ios/YourAppName/
```

### 2. Add Files to Xcode

1. Open `YourApp.xcworkspace` in Xcode
2. Right-click on your app folder in the Project Navigator
3. Select "Add Files to YourApp..."
4. Select all the `.swift` and `.m` files
5. Make sure "Copy items if needed" is checked
6. Click "Add"

### 3. Create Bridging Header (if not exists)

If Xcode asks to create a bridging header, click "Create Bridging Header".

If not, create `YourApp-Bridging-Header.h`:

```objc
//
//  YourApp-Bridging-Header.h
//

#import <React/RCTBridgeModule.h>
```

### 4. Configure Build Settings

In Xcode:
1. Select your project in Project Navigator
2. Select your app target
3. Go to "Build Settings"
4. Search for "Objective-C Bridging Header"
5. Set it to: `YourApp/YourApp-Bridging-Header.h`

### 5. Add the TypeScript Modules

Copy the TypeScript files to your React Native project:

```bash
# For modal component
cp RNPDFAnnotator.ts src/modules/

# For embedded component
cp RNPDFAnnotatorView.tsx src/components/
```

## Usage in React Native

## Option 1: Modal Component (Full-Screen)

Use this when you want a standalone, full-screen annotation experience.

### Basic Example

```typescript
import React, { useState } from 'react';
import { View, Button, Text, Alert } from 'react-native';
import RNPDFAnnotator from './modules/RNPDFAnnotator';
import RNFS from 'react-native-fs';

export default function App() {
  const [annotatedPDFPath, setAnnotatedPDFPath] = useState<string | null>(null);

  const handleAnnotatePDF = async () => {
    try {
      const pdfURL = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
      
      // Open native annotation view
      const result = await RNPDFAnnotator.annotatePDF(pdfURL);
      
      // Save the annotated PDF to app's documents directory
      const destPath = `${RNFS.DocumentDirectoryPath}/annotated_${Date.now()}.pdf`;
      await RNFS.copyFile(result.filePath, destPath);
      
      setAnnotatedPDFPath(destPath);
      Alert.alert('Success', `PDF saved to: ${destPath}`);
      
    } catch (error) {
      if (error.code === 'USER_CANCELLED') {
        Alert.alert('Cancelled', 'User cancelled annotation');
      } else {
        Alert.alert('Error', error.message);
      }
    }
  };

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
      <Button title="Annotate PDF" onPress={handleAnnotatePDF} />
      
      {annotatedPDFPath && (
        <Text style={{ marginTop: 20 }}>
          Annotated PDF saved at: {annotatedPDFPath}
        </Text>
      )}
    </View>
  );
}
```

### Advanced Example with Local PDF

```typescript
import { launchImageLibrary } from 'react-native-image-picker';
import RNPDFAnnotator from './modules/RNPDFAnnotator';
import RNFS from 'react-native-fs';

const annotateLocalPDF = async () => {
  try {
    // Pick a PDF file
    const result = await launchImageLibrary({
      mediaType: 'mixed',
      includeBase64: false,
    });

    if (result.assets && result.assets[0].uri) {
      const localPDFPath = result.assets[0].uri;
      
      // Annotate the PDF
      const annotated = await RNPDFAnnotator.annotatePDF(localPDFPath);
      
      // Move to permanent location
      const destPath = `${RNFS.DocumentDirectoryPath}/my_annotated.pdf`;
      await RNFS.moveFile(annotated.filePath, destPath);
      
      console.log('Annotated PDF saved:', destPath);
    }
  } catch (error) {
    console.error('Error:', error);
  }
};
```

### Upload Annotated PDF to Server

```typescript
const annotateAndUpload = async (pdfURL: string) => {
  try {
    // Annotate the PDF
    const result = await RNPDFAnnotator.annotatePDF(pdfURL);
    
    // Read the file as base64
    const fileContent = await RNFS.readFile(result.filePath, 'base64');
    
    // Upload to your server
    const response = await fetch('https://your-api.com/upload', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        filename: 'annotated.pdf',
        content: fileContent,
      }),
    });
    
    // Clean up temp file
    await RNFS.unlink(result.filePath);
    
    console.log('Upload successful:', response);
  } catch (error) {
    console.error('Error:', error);
  }
};
```

## Option 2: Embedded Component

Use this when you need the PDF annotation view to be part of your layout (e.g., split screen, side-by-side with other components).

### Basic Embedded Example

```typescript
import React, { useState, useRef } from 'react';
import { View, StyleSheet } from 'react-native';
import { PDFAnnotationView } from './components/RNPDFAnnotatorView';

export default function MyScreen() {
  // Note: The toolbar is built-in and appears automatically when PDF is loaded
  // Annotation mode is controlled via the toolbar's "Annotate" button
  const pdfViewRef = useRef<PDFAnnotationView>(null);

  return (
    <View style={styles.container}>
      {/* PDF with built-in toolbar - no header needed */}
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
  container: { flex: 1 },
  pdfView: { flex: 1 },
});
```

### Advanced Example with Brush Settings

```typescript
import React, { useState, useRef } from 'react';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';
import { PDFAnnotationView, BrushSettings } from './components/RNPDFAnnotatorView';

export default function AdvancedExample() {
  const [brushSettings, setBrushSettings] = useState<BrushSettings>({
    type: 'pen',
    color: '#FF0000',
    width: 5.0,
    opacity: 0.8,
  });
  const pdfViewRef = useRef<PDFAnnotationView>(null);

  return (
    <View style={styles.container}>
      <PDFAnnotationView
        ref={pdfViewRef}
        style={styles.pdfView}
        pdfURL="https://example.com/document.pdf"
        brushSettings={brushSettings}
        onPDFLoaded={(event) => {
          console.log('PDF loaded with', event.nativeEvent.pageCount, 'pages');
        }}
      />
      
      {/* Optional: Your own custom controls */}
      <View style={styles.customControls}>
        <Text>Custom Brush Settings</Text>
        <TouchableOpacity
          onPress={() => setBrushSettings({ ...brushSettings, type: 'pen' })}
        >
          <Text>Pen</Text>
        </TouchableOpacity>
        {/* ... more controls */}
      </View>
    </View>
  );
}
```

### Split Screen Layout Example

```typescript
import React, { useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { PDFAnnotationView } from './components/RNPDFAnnotatorView';

export default function SplitScreenExample() {
  const [isAnnotating, setIsAnnotating] = useState(false);
  const pdfViewRef = useRef<PDFAnnotationView>(null);

  const handleExport = async () => {
    if (!pdfViewRef.current) return;
    const result = await pdfViewRef.current.exportAnnotatedPDF();
    console.log('Exported to:', result.filePath);
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>PDF Annotator</Text>
      </View>

      {/* Split Screen Content */}
      <View style={styles.contentContainer}>
        {/* Left Half - PDF */}
        <View style={styles.pdfContainer}>
          <PDFAnnotationView
            ref={pdfViewRef}
            style={styles.pdfView}
            pdfURL="https://example.com/document.pdf"
            isAnnotating={isAnnotating}
            drawWithFinger={true}
          />
        </View>

        {/* Right Half - Controls */}
        <View style={styles.sidePanel}>
          <Text>Settings</Text>
          <TouchableOpacity
            onPress={() => setIsAnnotating(!isAnnotating)}
            style={styles.button}
          >
            <Text>{isAnnotating ? 'Disable Annotation' : 'Enable Annotation'}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={handleExport} style={styles.button}>
            <Text>Export PDF</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { padding: 20, backgroundColor: '#007AFF' },
  headerTitle: { color: 'white', fontSize: 20, fontWeight: 'bold' },
  contentContainer: { flex: 1, flexDirection: 'row' },
  pdfContainer: { flex: 1 },
  pdfView: { flex: 1 },
  sidePanel: { width: 300, padding: 20, backgroundColor: 'white' },
  button: { padding: 15, backgroundColor: '#007AFF', borderRadius: 8, marginTop: 10 },
});
```

**See `example-embedded-component.tsx` for a complete embedded component example.**

## API Reference

### Modal Component API

#### `RNPDFAnnotator.annotatePDF(pdfURL: string)`

Opens a native full-screen PDF annotation view.

**Parameters:**
- `pdfURL` (string): URL of the PDF to annotate
  - Remote: `https://example.com/document.pdf`
  - Local: `file:///path/to/document.pdf`

**Returns:**
- `Promise<{ filePath: string }>`: Path to the annotated PDF in temporary directory

**Errors:**
- `INVALID_URL`: Invalid PDF URL provided
- `NO_ROOT_VC`: Could not find root view controller
- `USER_CANCELLED`: User cancelled annotation

### Embedded Component API

#### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `pdfURL` | `string` | - | URL of PDF to load (remote http/https or local file://) |
| `isAnnotating` | `boolean` | `false` | Enable/disable annotation mode (can also use toolbar button) |
| `drawWithFinger` | `boolean` | `true` | Allow finger drawing (false = pencil only) |
| `brushSettings` | `BrushSettings` | - | Tool settings object (type, color, width, opacity) - **New!** |
| `toolType` | `ToolType` | - | Tool type: 'pen', 'pencil', 'highlighter', 'eraser' (legacy prop) |
| `toolColor` | `string` | - | Hex color string (legacy prop, use brushSettings instead) |
| `toolWidth` | `number` | - | Stroke width in points (legacy prop) |
| `toolOpacity` | `number` | - | Opacity 0.0-1.0 (legacy prop) |
| `onPDFLoaded` | `function` | - | Called when PDF loads successfully: `(event: { nativeEvent: { pageCount: number } }) => void` |
| `onPDFLoadError` | `function` | - | Called when PDF fails to load: `(event: { nativeEvent: { error: string } }) => void` |
| `onAnnotationComplete` | `function` | - | Called when annotation is complete: `(event: { nativeEvent: { filePath: string } }) => void` |
| `onAnnotationCancel` | `function` | - | Called when annotation is cancelled: `() => void` |

#### BrushSettings Interface

```typescript
interface BrushSettings {
  type?: 'pen' | 'pencil' | 'highlighter' | 'eraser' | 'none';
  color?: string;      // Hex color: "#FF0000" or "#AAFF0000" (ARGB)
  width?: number;      // Stroke width: 1.0-20.0 points (default: 3.0)
  opacity?: number;    // Opacity: 0.0-1.0 (default: 1.0)
  eraserType?: 'vector' | 'bitmap'; // For eraser tool only (default: 'vector')
}
```

#### Methods

##### `exportAnnotatedPDF(): Promise<{ filePath: string }>`

Exports the annotated PDF and returns a promise with the file path.

```typescript
const result = await pdfViewRef.current.exportAnnotatedPDF();
// result.filePath contains the path to the exported PDF
```

**See `EMBEDDED_COMPONENT_USAGE.md` for detailed embedded component documentation.**

## Features Available

### Modal Component
✅ Full-screen native PDF viewer  
✅ Modal presentation (blocks entire app)  
✅ Built-in navigation (cancel/done buttons)

### Embedded Component
✅ Embeddable in any layout  
✅ Customizable size and positioning  
✅ Coexists with other React Native components  
✅ Programmatic control via props and refs  
✅ **Built-in toolbar** with annotate toggle  
✅ **Tool selection** (pen, pencil, highlighter, eraser, PencilKit)  
✅ **Inline customization panel** (width, opacity, color)  
✅ **No header required** - toolbar is self-contained

### Both Components
✅ Apple Pencil and finger drawing  
✅ PencilKit tool picker (pen, pencil, highlighter, eraser)  
✅ Customizable tools with inline customization panel  
✅ Separate pen, pencil, highlighter, eraser options  
✅ Customizable colors, width, and opacity  
✅ Eraser types: Vector and Pixel eraser  
✅ Per-page annotation storage  
✅ Export with burned-in annotations  
✅ iOS 16+ optimized  
✅ Two-finger swipe navigation (up = next page, down = previous page)  
✅ Undo/Redo functionality  
✅ Page number display  
✅ Integrated toolbar (embedded component)  
✅ Annotate toggle button in toolbar  

## Dependencies

Required in your React Native project:

```bash
npm install react-native-fs
# or
yarn add react-native-fs
```

## Platform Support

- iOS 16.0+
- Works with both Old and New React Native Architecture

## Troubleshooting

### Module not found
```bash
cd ios && pod install && cd ..
npx react-native run-ios
```

### Swift errors
Make sure the bridging header is correctly configured in Build Settings.

### Embedded component not rendering
- Make sure `RNPDFAnnotatorView.swift` is added to your target's "Compile Sources"
- Check that `RNPDFAnnotatorViewManager.mm` is in your target
- Verify the Swift header is generated (check Xcode build settings for "Objective-C Generated Interface Header Name")

### Cannot find PDFKit
Add to your `Podfile`:
```ruby
target 'YourApp' do
  # ... other pods
  pod 'PDFKit'
end
```

## License

MIT License


