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
        
        // Two-finger navigation
        let gesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerPan(_:)))
        gesture.minimumNumberOfTouches = 2
        pdfView.addGestureRecognizer(gesture)
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        context.coordinator.setAnnotationMode(isAnnotating, drawWithFinger: drawWithFinger)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, PDFPageOverlayDelegate {
        weak var pdfView: PDFView?
        var overlayProvider: PDFPageOverlayProvider?
        
        func setAnnotationMode(_ isAnnotating: Bool, drawWithFinger: Bool) {
            guard #available(iOS 16.0, *) else { return }
            
            overlayProvider?.setDrawingPolicy(drawWithFinger)
            overlayProvider?.setAnnotationMode(isAnnotating)
            pdfView?.isInMarkupMode = isAnnotating
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

