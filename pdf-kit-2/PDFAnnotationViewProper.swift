//
//  PDFAnnotationViewProper.swift
//  pdf-kit-2
//
//  Proper implementation using PDFPageOverlayViewProvider (iOS 16+)
//

import SwiftUI
import PDFKit
import PencilKit

struct PDFAnnotationViewProper: UIViewRepresentable {
    let pdfDocument: PDFDocument?
    @Binding var isAnnotating: Bool
    @Binding var drawWithFinger: Bool
    @Binding var brushSettings: BrushSettings
    @Binding var showPencilKitToolPicker: Bool
    @Binding var coordinator: Coordinator?
    var onPageChanged: ((Int) -> Void)?
    var onUndoRedoStateChanged: ((Bool, Bool) -> Void)?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .lightGray
        
        // Setup overlay provider (iOS 16+)
        if #available(iOS 16.0, *) {
            let provider = PDFPageOverlayProvider()
            provider.delegate = context.coordinator
            context.coordinator.overlayProvider = provider
            pdfView.pageOverlayViewProvider = provider
        }
        
        pdfView.document = pdfDocument
        context.coordinator.pdfView = pdfView
        context.coordinator.onPageChanged = onPageChanged
        context.coordinator.onUndoRedoStateChanged = onUndoRedoStateChanged
        coordinator = context.coordinator
        
        // Observe page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pdfViewPageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )
        
        // Observe drawing changes for undo/redo state
        if #available(iOS 16.0, *) {
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.drawingDidChange(_:)),
                name: Notification.Name("PKCanvasViewDrawingDidChange"),
                object: nil
            )
        }
        
        // Two-finger navigation
        let gesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerPan(_:)))
        gesture.minimumNumberOfTouches = 2
        pdfView.addGestureRecognizer(gesture)
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        context.coordinator.setAnnotationMode(isAnnotating, drawWithFinger: drawWithFinger)
        context.coordinator.setBrushSettings(brushSettings)
        context.coordinator.setToolPickerVisible(showPencilKitToolPicker)
        coordinator = context.coordinator
        context.coordinator.updateUndoRedoState()
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
    
    class Coordinator: NSObject, PDFPageOverlayDelegate {
        weak var pdfView: PDFView?
        var overlayProvider: PDFPageOverlayProvider?
        var onPageChanged: ((Int) -> Void)?
        var onUndoRedoStateChanged: ((Bool, Bool) -> Void)?
        
        func setAnnotationMode(_ isAnnotating: Bool, drawWithFinger: Bool) {
            guard #available(iOS 16.0, *) else { return }
            
            overlayProvider?.setDrawingPolicy(drawWithFinger)
            overlayProvider?.setAnnotationMode(isAnnotating)
            pdfView?.isInMarkupMode = isAnnotating
        }
        
        func setBrushSettings(_ settings: BrushSettings) {
            guard #available(iOS 16.0, *) else { return }
            overlayProvider?.setBrushSettings(settings)
        }
        
        func setToolPickerVisible(_ visible: Bool) {
            guard #available(iOS 16.0, *) else { return }
            overlayProvider?.setToolPickerVisible(visible)
        }
        
        func undo() {
            guard #available(iOS 16.0, *),
                  let pdfView = pdfView,
                  let currentPage = pdfView.currentPage else { return }
            overlayProvider?.undo(for: currentPage)
            updateUndoRedoState()
        }
        
        func redo() {
            guard #available(iOS 16.0, *),
                  let pdfView = pdfView,
                  let currentPage = pdfView.currentPage else { return }
            overlayProvider?.redo(for: currentPage)
            updateUndoRedoState()
        }
        
        func canUndo() -> Bool {
            guard #available(iOS 16.0, *),
                  let pdfView = pdfView,
                  let currentPage = pdfView.currentPage else { return false }
            return overlayProvider?.canUndo(for: currentPage) ?? false
        }
        
        func canRedo() -> Bool {
            guard #available(iOS 16.0, *),
                  let pdfView = pdfView,
                  let currentPage = pdfView.currentPage else { return false }
            return overlayProvider?.canRedo(for: currentPage) ?? false
        }
        
        func updateUndoRedoState() {
            let canUndo = self.canUndo()
            let canRedo = self.canRedo()
            DispatchQueue.main.async {
                self.onUndoRedoStateChanged?(canUndo, canRedo)
            }
        }
        
        @objc func drawingDidChange(_ notification: Notification) {
            updateUndoRedoState()
        }
        
        @objc func pdfViewPageChanged(_ notification: Notification) {
            guard let pdfView = pdfView,
                  let document = pdfView.document else { return }
            if let currentPage = pdfView.currentPage {
                let pageIndex = document.index(for: currentPage)
                if pageIndex != -1 {
                    onPageChanged?(pageIndex)
                    updateUndoRedoState()
                }
            }
        }
        
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard let pdfView = pdfView, gesture.state == .changed else { return }
            let translation = gesture.translation(in: gesture.view)
            
            if translation.y < -50 {
                pdfView.goToNextPage(nil)
                gesture.setTranslation(.zero, in: gesture.view)
            } else if translation.y > 50 {
                pdfView.goToPreviousPage(nil)
                gesture.setTranslation(.zero, in: gesture.view)
            }
        }
    }
}
