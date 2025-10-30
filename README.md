# PDF Annotation App

A native iOS PDF viewer and annotation app built with SwiftUI, PDFKit, and PencilKit.

## Features

✅ **PDF Viewing**
- Load PDFs from URLs
- Single-page display mode
- Auto-scaling

✅ **Annotation**
- Draw with Apple Pencil or finger
- Full PencilKit tool picker integration
- Multiple drawing tools (pen, pencil, highlighter, eraser)
- Per-page annotation storage
- Annotations persist across app sessions

✅ **Export & Share**
- Export annotated PDFs with burned-in annotations
- Share via AirDrop, Mail, Messages, etc.
- Save to Files app

✅ **Navigation**
- Two-finger swipe for page navigation
- Smooth page transitions

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

This app uses Apple's recommended approach from [WWDC22 - What's new in PDFKit](https://developer.apple.com/videos/play/wwdc2022/10089/):

### Custom PDF Classes

- **`MyPDFDocument`**: Custom `PDFDocument` subclass that uses `MyPDFPage`
- **`MyPDFPage`**: Custom `PDFPage` subclass with a `drawing: PKDrawing?` property for per-page annotation storage
- **`MyPDFAnnotation`**: Custom `PDFAnnotation` subclass that renders `PKDrawing` objects when saving

### iOS 16+ API

- **`PDFPageOverlayViewProvider`**: Provides `PKCanvasView` overlays for each PDF page
- **`isInMarkupMode`**: Enables annotation mode on `PDFView`
- **`.burnInAnnotationsOption`**: Burns annotations into PDF when exporting

## Code Structure

```
pdf-kit-2/
├── ContentView.swift              # Main SwiftUI view
├── PDFViewModel.swift             # PDF loading and export logic
├── PDFAnnotationViewProper.swift  # UIViewRepresentable for PDFView
├── PDFPageOverlayProvider.swift   # Canvas overlay provider
├── MyPDFDocument.swift            # Custom PDFDocument
├── MyPDFPage.swift                # Custom PDFPage with drawing storage
├── MyPDFAnnotation.swift          # Custom PDFAnnotation for rendering
└── ShareSheet.swift               # Share functionality
```

## How It Works

1. **Loading**: PDFs are loaded from URLs using `MyPDFDocument`
2. **Annotation**: `PDFPageOverlayProvider` creates a `PKCanvasView` for each page
3. **Storage**: Drawings are saved to `MyPDFPage.drawing` property
4. **Export**: `MyPDFAnnotation` renders drawings into PDF context with coordinate transformation
5. **Saving**: PDF is saved with `.burnInAnnotationsOption` to permanently embed annotations

## Usage

1. Launch the app
2. Load a PDF (default sample PDF loads automatically)
3. Tap the pencil icon to enable annotation mode
4. Use the PencilKit tool picker to select your drawing tool
5. Draw on the PDF with Apple Pencil or finger
6. Tap the share icon to export and share the annotated PDF

## License

MIT License - Feel free to use this code in your own projects!

## Credits

Based on Apple's WWDC22 PDFKit session and inspired by [react-native-pdf-painter](https://github.com/example/react-native-pdf-painter).

