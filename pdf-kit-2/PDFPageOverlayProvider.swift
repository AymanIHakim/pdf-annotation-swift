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

class PDFPageOverlayProvider: NSObject, PDFPageOverlayViewProvider {
    var pageToViewMapping = [PDFPage: PKCanvasView]()
    var toolPicker = PKToolPicker()
    var drawWithFinger = true
    var isAnnotationMode = false
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
            canvas.tool = PKInkingTool(.pen, color: .blue, width: 3)
            pageToViewMapping[page] = canvas
        }
        
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
        
        // Save drawing to page
        myPage.drawing = canvas.drawing
        pageToViewMapping.removeValue(forKey: page)
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
}

extension PDFPageOverlayProvider: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Save drawing immediately when it changes
        for (page, canvas) in pageToViewMapping where canvas === canvasView {
            if let myPage = page as? MyPDFPage {
                myPage.drawing = canvasView.drawing
            }
            break
        }
    }
}

protocol PDFPageOverlayDelegate: AnyObject {}

