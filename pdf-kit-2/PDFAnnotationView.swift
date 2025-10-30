//
//  PDFAnnotationView.swift
//  pdf-kit-2
//
//  Based on Apple's PDFKit and PencilKit documentation
//

import SwiftUI
import PDFKit
import PencilKit

struct PDFAnnotationView: UIViewControllerRepresentable {
    let pdfDocument: PDFDocument?
    @Binding var isAnnotating: Bool
    @Binding var drawWithFinger: Bool
    @Binding var controllerReference: PDFAnnotationViewController?
    var onPageChanged: ((Int, PKDrawing) -> Void)?
    var onDrawingChanged: ((PKDrawing) -> Void)?
    
    func makeUIViewController(context: Context) -> PDFAnnotationViewController {
        let controller = PDFAnnotationViewController()
        controller.pdfDocument = pdfDocument
        controller.coordinator = context.coordinator
        context.coordinator.controller = controller
        
        // Pass controller reference back
        DispatchQueue.main.async {
            controllerReference = controller
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PDFAnnotationViewController, context: Context) {
        uiViewController.pdfDocument = pdfDocument
        uiViewController.setAnnotationMode(isAnnotating, drawWithFinger: drawWithFinger)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPageChanged: onPageChanged, onDrawingChanged: onDrawingChanged)
    }
    
    class Coordinator: NSObject {
        var onPageChanged: ((Int, PKDrawing) -> Void)?
        var onDrawingChanged: ((PKDrawing) -> Void)?
        weak var controller: PDFAnnotationViewController?
        
        init(onPageChanged: ((Int, PKDrawing) -> Void)?, onDrawingChanged: ((PKDrawing) -> Void)?) {
            self.onPageChanged = onPageChanged
            self.onDrawingChanged = onDrawingChanged
        }
        
        func notifyPageChanged(_ pageIndex: Int, drawing: PKDrawing) {
            onPageChanged?(pageIndex, drawing)
        }
        
        func notifyDrawingChanged(_ drawing: PKDrawing) {
            onDrawingChanged?(drawing)
        }
    }
}

class PDFAnnotationViewController: UIViewController, PKCanvasViewDelegate {
    var pdfView: PDFView!
    var canvasView: PKCanvasView!
    var toolPicker: PKToolPicker!
    var coordinator: PDFAnnotationView.Coordinator?
    
    var pdfDocument: PDFDocument? {
        didSet {
            pdfView?.document = pdfDocument
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
        setupCanvasView()
        setupToolPicker()
        setupNotifications()
    }
    
    private func setupPDFView() {
        pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .lightGray
        view.addSubview(pdfView)
    }
    
    private func setupCanvasView() {
        canvasView = PKCanvasView(frame: view.bounds)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        view.addSubview(canvasView)
        
        // Initially disable canvas
        canvasView.isUserInteractionEnabled = false
    }
    
    private func setupToolPicker() {
        toolPicker = PKToolPicker()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )
    }
    
    func setAnnotationMode(_ isAnnotating: Bool, drawWithFinger: Bool) {
        canvasView.drawingPolicy = drawWithFinger ? .anyInput : .pencilOnly
        
        if isAnnotating {
            // Enable annotation
            canvasView.isUserInteractionEnabled = true
            canvasView.becomeFirstResponder()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            
            // Disable PDF interaction
            disablePDFGestures()
        } else {
            // Disable annotation
            canvasView.isUserInteractionEnabled = false
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            
            // Enable PDF interaction
            enablePDFGestures()
        }
        
        updateCanvasFrame()
    }
    
    func loadDrawing(_ drawing: PKDrawing) {
        canvasView.drawing = drawing
    }
    
    private func updateCanvasFrame() {
        guard let currentPage = pdfView.currentPage else { return }
        
        let pageBounds = currentPage.bounds(for: .mediaBox)
        let pageFrame = pdfView.convert(pageBounds, from: currentPage)
        
        // Validate frame
        guard pageFrame.width > 0,
              pageFrame.height > 0,
              pageFrame.width.isFinite,
              pageFrame.height.isFinite else {
            return
        }
        
        canvasView.frame = pageFrame
    }
    
    @objc private func pageChanged() {
        guard let document = pdfView.document,
              let currentPage = pdfView.currentPage else {
            return
        }
        
        let pageIndex = document.index(for: currentPage)
        let currentDrawing = canvasView.drawing
        
        updateCanvasFrame()
        coordinator?.notifyPageChanged(pageIndex, drawing: currentDrawing)
    }
    
    // MARK: - PKCanvasViewDelegate
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        coordinator?.notifyDrawingChanged(canvasView.drawing)
    }
    
    // MARK: - Gesture Management
    
    private var savedGestureStates: [(UIGestureRecognizer, Bool)] = []
    
    private func disablePDFGestures() {
        savedGestureStates.removeAll()
        pdfView.gestureRecognizers?.forEach { gesture in
            savedGestureStates.append((gesture, gesture.isEnabled))
            gesture.isEnabled = false
        }
    }
    
    private func enablePDFGestures() {
        savedGestureStates.forEach { gesture, wasEnabled in
            gesture.isEnabled = wasEnabled
        }
        savedGestureStates.removeAll()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

