//
//  PDFPageOverlayProvider.swift
//  pdf-kit-2
//
//  Uses iOS 16+ PDFPageOverlayViewProvider API
//  Based on react-native-pdf-painter approach
//

import SwiftUI
import PDFKit
import PencilKit

// MARK: - Tool Type Enum
enum DrawingToolType: String {
    case pen = "pen"
    case pencil = "pencil"
    case highlighter = "highlighter"
    case eraser = "eraser"
    case none = "none"
}

// MARK: - Eraser Type Enum
enum EraserType {
    case vector
    case bitmap
}

// MARK: - Brush Settings Struct
struct BrushSettings {
    var type: DrawingToolType = .pen
    var color: UIColor = .blue
    var width: CGFloat = 3.0
    var opacity: CGFloat = 1.0 // 0.0 to 1.0
    var eraserType: EraserType = .vector // For eraser tool only
}

class PDFPageOverlayProvider: NSObject, PDFPageOverlayViewProvider {
    var pageToViewMapping = [PDFPage: PKCanvasView]()
    var toolPicker = PKToolPicker()
    var drawWithFinger = true
    var isAnnotationMode = false
    var brushSettings = BrushSettings()
    weak var delegate: PDFPageOverlayDelegate?
    
    // MARK: - PDFPageOverlayViewProvider
    
    
    @available(iOS 16.0, *)
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        // Reuse existing canvas or create new one
        let canvas: PKCanvasView
        if let existing = pageToViewMapping[page] {
            canvas = existing
        } else {
            canvas = PKCanvasView()
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            canvas.delegate = self
            canvas.drawingPolicy = drawWithFinger ? .anyInput : .pencilOnly
            canvas.tool = createTool(from: brushSettings)
            pageToViewMapping[page] = canvas
        }
        
        // Apply current brush settings to the canvas
        canvas.tool = createTool(from: brushSettings)
        
        // Load saved drawing if exists
        if let myPage = page as? MyPDFPage, let drawing = myPage.drawing {
            canvas.drawing = drawing
        }
        
        // Show tool picker if in annotation mode
        if isAnnotationMode {
            canvas.becomeFirstResponder()
            toolPicker.setVisible(true, forFirstResponder: canvas)
            toolPicker.addObserver(canvas)
        }
        
        return canvas
    }
    
    @available(iOS 16.0, *)
    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        guard let canvas = overlayView as? PKCanvasView,
              let myPage = page as? MyPDFPage else { return }
        
        myPage.drawing = canvas.drawing
        pageToViewMapping.removeValue(forKey: page)
    }
    
    // Normalize drawing bounds to match page bounds (public for use during export)
    func normalizeDrawing(_ drawing: PKDrawing, to page: PDFPage) -> PKDrawing {
        // PDFKit positions the overlay canvas to match page bounds, so the drawing is already aligned
        return drawing
    }
    
    func setAnnotationMode(_ enabled: Bool) {
        isAnnotationMode = enabled
        for canvas in pageToViewMapping.values {
            if enabled {
                canvas.becomeFirstResponder()
                toolPicker.setVisible(true, forFirstResponder: canvas)
                toolPicker.addObserver(canvas)
            } else {
                toolPicker.setVisible(false, forFirstResponder: canvas)
                toolPicker.removeObserver(canvas)
            }
        }
    }
    
    func setDrawingPolicy(_ drawWithFinger: Bool) {
        self.drawWithFinger = drawWithFinger
        for canvas in pageToViewMapping.values {
            canvas.drawingPolicy = drawWithFinger ? .anyInput : .pencilOnly
        }
    }
    
    func setBrushSettings(_ settings: BrushSettings) {
        brushSettings = settings
        // Apply to all existing canvases
        for canvas in pageToViewMapping.values {
            // Safely create and set tool
            let tool = createTool(from: settings)
            // Ensure tool is valid before setting
            if settings.type == .none {
                // For none type, don't update the tool
                continue
            }
            canvas.tool = tool
        }
    }
    
    func undo(for page: PDFPage) {
        guard let canvas = pageToViewMapping[page] else { return }
        canvas.undoManager?.undo()
    }
    
    func redo(for page: PDFPage) {
        guard let canvas = pageToViewMapping[page] else { return }
        canvas.undoManager?.redo()
    }
    
    func canUndo(for page: PDFPage) -> Bool {
        guard let canvas = pageToViewMapping[page],
              let undoManager = canvas.undoManager else { return false }
        return undoManager.canUndo
    }
    
    func canRedo(for page: PDFPage) -> Bool {
        guard let canvas = pageToViewMapping[page],
              let undoManager = canvas.undoManager else { return false }
        return undoManager.canRedo
    }
    
    func setToolPickerVisible(_ visible: Bool) {
        isAnnotationMode = visible
        for canvas in pageToViewMapping.values {
            if visible {
                canvas.becomeFirstResponder()
                toolPicker.setVisible(true, forFirstResponder: canvas)
                toolPicker.addObserver(canvas)
            } else {
                toolPicker.setVisible(false, forFirstResponder: canvas)
                toolPicker.removeObserver(canvas)
            }
        }
    }
    
    func getCurrentPage(from pdfView: PDFView?) -> PDFPage? {
        return pdfView?.currentPage
    }
    
    // MARK: - Tool Creation
    
    private func createTool(from settings: BrushSettings) -> PKTool {
        guard settings.type != .none else {
            // Return a default pen tool if type is none (but make it non-functional)
            return PKInkingTool(.pen, color: .clear, width: 0)
        }
        
        if settings.type == .eraser {
            // Eraser tool - support both vector and bitmap eraser types
            let eraserType: PKEraserTool.EraserType = settings.eraserType == .vector ? .vector : .bitmap
            // Ensure width is valid for eraser (minimum 1.0)
            let eraserWidth = max(1.0, settings.width)
            if #available(iOS 16.4, *) {
                return PKEraserTool(eraserType, width: eraserWidth)
            } else {
                // iOS < 16.4 only supports vector eraser without width parameter
                return PKEraserTool(.vector)
            }
        }
        
        // Inking tools (pen, pencil, highlighter)
        let inkType: PKInkingTool.InkType
        switch settings.type {
        case .pen:
            inkType = .pen
        case .pencil:
            inkType = .pencil
        case .highlighter:
            inkType = .marker
        default:
            inkType = .pen
        }
        
        // Apply opacity to color
        let colorWithOpacity = settings.color.withAlphaComponent(settings.opacity)
        
        // Ensure width is valid (minimum 0.5, maximum 50)
        let validWidth = max(0.5, min(50.0, settings.width))
        
        return PKInkingTool(inkType, color: colorWithOpacity, width: validWidth)
    }
    
    // MARK: - Color Helper
    
    static func colorFromString(_ colorString: String) -> UIColor {
        var hexString = colorString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove # if present
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }
        
        // Support both #RRGGBB and #AARRGGBB formats
        var hexValue: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexValue) else {
            return .black // Default color
        }
        
        if hexString.count == 6 {
            // RGB format - no alpha
            let red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(hexValue & 0x0000FF) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        } else if hexString.count == 8 {
            // ARGB format
            let alpha = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            let red = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            let green = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            let blue = CGFloat(hexValue & 0x000000FF) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        
        return .black // Default color
    }
}

extension PDFPageOverlayProvider: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        for (page, canvas) in pageToViewMapping where canvas === canvasView {
            if let myPage = page as? MyPDFPage {
                myPage.drawing = canvasView.drawing
            }
            break
        }
        
        NotificationCenter.default.post(name: Notification.Name("PKCanvasViewDrawingDidChange"), object: canvasView)
    }
}

protocol PDFPageOverlayDelegate: AnyObject {}

