//
//  PDFKitView.swift
//  pdf-kit-2
//
//  Created by Ayman Ibne Hakim on 29/10/25.
//

import SwiftUI
import PDFKit
import PencilKit

struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument?
    @Binding var canvasView: PKCanvasView
    @Binding var isAnnotating: Bool
    var onPageChanged: ((Int) -> Void)?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.document = pdfDocument
        pdfView.backgroundColor = .lightGray
        
        // Store references
        context.coordinator.pdfView = pdfView
        context.coordinator.canvasView = canvasView
        context.coordinator.onPageChanged = onPageChanged
        
        // Setup canvas
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        pdfView.addSubview(canvasView)
        
        // Setup notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pdfViewScaleChanged(_:)),
            name: .PDFViewScaleChanged,
            object: pdfView
        )
        
        // Two-finger gesture for navigation
        let twoFingerPan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTwoFingerPan(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.delegate = context.coordinator
        pdfView.addGestureRecognizer(twoFingerPan)
        
        // Initial setup
        DispatchQueue.main.async {
            context.coordinator.updateCanvasBounds()
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update document if changed
        if uiView.document !== pdfDocument {
            uiView.document = pdfDocument
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                context.coordinator.updateCanvasBounds()
            }
        }
        
        // Control interaction based on annotation mode
        context.coordinator.setAnnotationMode(isAnnotating)
        
        // Update canvas bounds on any update
        DispatchQueue.main.async {
            context.coordinator.updateCanvasBounds()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var pdfView: PDFView?
        weak var canvasView: PKCanvasView?
        var onPageChanged: ((Int) -> Void)?
        private var savedGestureStates: [(UIGestureRecognizer, Bool)] = []
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func setAnnotationMode(_ isAnnotating: Bool) {
            guard let pdfView = pdfView, let canvasView = canvasView else { return }
            
            if isAnnotating {
                // Enable canvas for drawing
                canvasView.isUserInteractionEnabled = true
                
                // Disable all PDF gestures except our two-finger gesture
                savedGestureStates.removeAll()
                if let gestures = pdfView.gestureRecognizers {
                    for gesture in gestures {
                        // Skip our custom two-finger gesture
                        if gesture is UIPanGestureRecognizer,
                           let pan = gesture as? UIPanGestureRecognizer,
                           pan.minimumNumberOfTouches == 2 {
                            continue
                        }
                        savedGestureStates.append((gesture, gesture.isEnabled))
                        gesture.isEnabled = false
                    }
                }
            } else {
                // Disable canvas
                canvasView.isUserInteractionEnabled = false
                
                // Restore PDF gestures
                for (gesture, wasEnabled) in savedGestureStates {
                    gesture.isEnabled = wasEnabled
                }
                savedGestureStates.removeAll()
            }
        }
        
        func updateCanvasBounds() {
            guard let pdfView = pdfView,
                  let canvasView = canvasView,
                  let currentPage = pdfView.currentPage else {
                return
            }
            
            // Get PDF page bounds
            let pageBounds = currentPage.bounds(for: .mediaBox)
            
            // Convert to PDFView coordinates
            let pageRect = pdfView.convert(pageBounds, from: currentPage)
            
            // Validate rect
            guard pageRect.width > 0, 
                  pageRect.height > 0,
                  pageRect.width.isFinite,
                  pageRect.height.isFinite else {
                return
            }
            
            // Set canvas frame to match PDF page bounds exactly
            canvasView.frame = pageRect
            
            // Ensure canvas is on top
            pdfView.bringSubviewToFront(canvasView)
        }
        
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else {
                return
            }
            
            let pageIndex = document.index(for: currentPage)
            
            // Update canvas bounds for new page
            updateCanvasBounds()
            
            // Notify about page change
            onPageChanged?(pageIndex)
        }
        
        @objc func pdfViewScaleChanged(_ notification: Notification) {
            // Update canvas when PDF is zoomed
            updateCanvasBounds()
        }
        
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard let pdfView = pdfView else { return }
            
            let translation = gesture.translation(in: gesture.view)
            
            if gesture.state == .changed {
                if translation.y < -50 {
                    pdfView.goToNextPage(nil)
                    gesture.setTranslation(.zero, in: gesture.view)
                } else if translation.y > 50 {
                    pdfView.goToPreviousPage(nil)
                    gesture.setTranslation(.zero, in: gesture.view)
                }
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
