//
//  RNPDFAnnotatorView.swift
//  Embedded PDF Annotation View for React Native
//

import UIKit
import PDFKit
import PencilKit
import React

@objc(RNPDFAnnotatorView)
class RNPDFAnnotatorView: UIView {
    // MARK: - Properties
    
    private var pdfView: PDFView!
    private var overlayProvider: PDFPageOverlayProvider?
    private var pdfDocument: MyPDFDocument?
    private var toolbar: RNAnnotationToolbar?
    private var currentPageIndex: Int = 0
    private var totalPages: Int = 0
    private var currentEraserType: EraserType = .vector
    
    // React Native event handlers
    @objc var onAnnotationComplete: RCTDirectEventBlock?
    @objc var onAnnotationCancel: RCTDirectEventBlock?
    @objc var onPDFLoadError: RCTDirectEventBlock?
    @objc var onPDFLoaded: RCTDirectEventBlock?
    
    // React Native props
    @objc var pdfURL: String? {
        didSet {
            if pdfURL != oldValue {
                loadPDF(from: pdfURL)
            }
        }
    }
    
    @objc var isAnnotating: Bool = false {
        didSet {
            updateAnnotationMode()
        }
    }
    
    @objc var drawWithFinger: Bool = true {
        didSet {
            updateAnnotationMode()
        }
    }
    
    @objc var toolType: String? {
        didSet {
            updateBrushSettings()
        }
    }
    
    @objc var toolColor: String? {
        didSet {
            updateBrushSettings()
        }
    }
    
    @objc var toolWidth: NSNumber? {
        didSet {
            updateBrushSettings()
        }
    }
    
    @objc var toolOpacity: NSNumber? {
        didSet {
            updateBrushSettings()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPDFView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPDFView()
    }
    
    // MARK: - Setup
    
    private func setupPDFView() {
        // Create toolbar
        toolbar = RNAnnotationToolbar()
        toolbar?.translatesAutoresizingMaskIntoConstraints = false
        toolbar?.onAnnotationToggle = { [weak self] isAnnotating in
            self?.isAnnotating = isAnnotating
        }
        toolbar?.onToolSelected = { [weak self] tool in
            self?.setTool(tool)
        }
        toolbar?.onPencilKitToggle = { [weak self] show in
            guard #available(iOS 16.0, *) else { return }
            self?.overlayProvider?.setToolPickerVisible(show)
        }
        toolbar?.onUndo = { [weak self] in
            self?.performUndo()
        }
        toolbar?.onRedo = { [weak self] in
            self?.performRedo()
        }
        toolbar?.onFingerToggle = { [weak self] enabled in
            self?.drawWithFinger = enabled
        }
        toolbar?.onColorChanged = { [weak self] color in
            // Convert UIColor to hex string
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let hexString = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
            self?.toolColor = hexString
        }
        toolbar?.onWidthChanged = { [weak self] width in
            self?.toolWidth = NSNumber(value: Float(width))
        }
        toolbar?.onOpacityChanged = { [weak self] opacity in
            self?.toolOpacity = NSNumber(value: Float(opacity))
        }
        toolbar?.onEraserTypeChanged = { [weak self] eraserType in
            // Store and apply eraser type change
            self?.currentEraserType = eraserType
            self?.updateBrushSettings()
        }
        
        // Initialize toolbar with default color and settings
        let defaultColor = PDFPageOverlayProvider.colorFromString(toolColor ?? "#000000")
        toolbar?.setBrushSettings(color: defaultColor, width: CGFloat(toolWidth?.floatValue ?? 3.0), opacity: CGFloat(toolOpacity?.floatValue ?? 1.0))
        toolbar?.setDrawWithFinger(drawWithFinger)
        
        addSubview(toolbar!)
        
        // Create PDFView
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .lightGray
        addSubview(pdfView)
        
        // Setup overlay provider (iOS 16+)
        if #available(iOS 16.0, *) {
            overlayProvider = PDFPageOverlayProvider()
            pdfView.pageOverlayViewProvider = overlayProvider
            
            // Observe page changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pdfViewPageChanged(_:)),
                name: Notification.Name.PDFViewPageChanged,
                object: pdfView
            )
            
            // Observe drawing changes for undo/redo state
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(drawingDidChange(_:)),
                name: Notification.Name("PKCanvasViewDrawingDidChange"),
                object: nil
            )
        }
        
        // Two-finger navigation gesture
        let twoFingerPan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleTwoFingerPan(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        pdfView.addGestureRecognizer(twoFingerPan)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            toolbar!.topAnchor.constraint(equalTo: topAnchor),
            toolbar!.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar!.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            pdfView.topAnchor.constraint(equalTo: toolbar!.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updateToolbarVisibility()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update layout if needed
    }
    
    // MARK: - PDF Loading
    
    private func loadPDF(from urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            return
        }
        
        if url.scheme == "http" || url.scheme == "https" {
            // Remote URL
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.sendErrorEvent("Error loading PDF: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        self.sendErrorEvent("No data received")
                        return
                    }
                    
                    if let pdfDoc = MyPDFDocument(data: data) {
                        self.pdfDocument = pdfDoc
                        self.pdfView.document = pdfDoc
                        self.totalPages = pdfDoc.pageCount
                        self.currentPageIndex = 0
                        self.toolbar?.setPage(0, total: pdfDoc.pageCount)
                        self.sendLoadedEvent()
                        self.updateToolbarVisibility()
                    } else {
                        self.sendErrorEvent("Failed to create PDF document")
                    }
                }
            }.resume()
        } else {
            // Local file
            if let pdfDoc = MyPDFDocument(url: url) {
                pdfDocument = pdfDoc
                pdfView.document = pdfDoc
                totalPages = pdfDoc.pageCount
                currentPageIndex = 0
                toolbar?.setPage(0, total: pdfDoc.pageCount)
                sendLoadedEvent()
                updateToolbarVisibility()
            } else {
                sendErrorEvent("Failed to load PDF from local URL")
            }
        }
    }
    
    // MARK: - Annotation Mode
    
    private func updateAnnotationMode() {
        guard #available(iOS 16.0, *) else { return }
        
        overlayProvider?.setDrawingPolicy(drawWithFinger)
        overlayProvider?.setAnnotationMode(isAnnotating)
        pdfView.isInMarkupMode = isAnnotating
        toolbar?.setAnnotating(isAnnotating)
        updateToolbarVisibility()
        updateUndoRedoState()
    }
    
    private func updateToolbarVisibility() {
        toolbar?.isHidden = pdfDocument == nil
        if isAnnotating && pdfDocument != nil {
            toolbar?.setAnnotating(true)
        } else {
            toolbar?.setAnnotating(false)
        }
    }
    
    private func setTool(_ tool: DrawingToolType) {
        // Always allow tool selection - it can be set even if PDF isn't loaded yet
        // This allows the UI to update immediately
        
        // Update tool type string
        let toolString: String
        switch tool {
        case .pen: toolString = "pen"
        case .pencil: toolString = "pencil"
        case .highlighter: toolString = "highlighter"
        case .eraser: toolString = "eraser"
        case .none: toolString = "none"
        }
        
        // Close PencilKit tool picker when selecting other tools
        if tool != .none {
            toolbar?.setPencilKitToolPickerVisible(false)
            if #available(iOS 16.0, *) {
                overlayProvider?.setToolPickerVisible(false)
            }
        }
        
        // Update toolType - this will trigger updateBrushSettings() via didSet
        // Don't call toolbar?.setCurrentTool() here to avoid infinite loop since
        // the toolbar already knows it's selected (it triggered this call)
        toolType = toolString
    }
    
    @objc private func pdfViewPageChanged(_ notification: Notification) {
        guard let document = pdfView.document else { return }
        if let currentPage = pdfView.currentPage {
            let pageIndex = document.index(for: currentPage)
            currentPageIndex = pageIndex
            totalPages = document.pageCount
            toolbar?.setPage(pageIndex, total: document.pageCount)
            updateUndoRedoState()
        }
    }
    
    private func performUndo() {
        guard #available(iOS 16.0, *),
              let overlayProvider = overlayProvider,
              let currentPage = pdfView.currentPage else { return }
        overlayProvider.undo(for: currentPage)
        updateUndoRedoState()
    }
    
    private func performRedo() {
        guard #available(iOS 16.0, *),
              let overlayProvider = overlayProvider,
              let currentPage = pdfView.currentPage else { return }
        overlayProvider.redo(for: currentPage)
        updateUndoRedoState()
    }
    
    private func updateUndoRedoState() {
        guard #available(iOS 16.0, *),
              let overlayProvider = overlayProvider,
              let currentPage = pdfView.currentPage else { return }
        let canUndo = overlayProvider.canUndo(for: currentPage)
        let canRedo = overlayProvider.canRedo(for: currentPage)
        toolbar?.setCanUndo(canUndo)
        toolbar?.setCanRedo(canRedo)
    }
    
    @objc private func drawingDidChange(_ notification: Notification) {
        updateUndoRedoState()
    }
    
    // MARK: - Brush Settings
    
    private func updateBrushSettings() {
        guard #available(iOS 16.0, *) else { return }
        guard let overlayProvider = overlayProvider else { return }
        guard pdfDocument != nil else { return }
        
        // Parse tool type
        let toolTypeString = toolType?.lowercased() ?? "pen"
        let drawingToolType: DrawingToolType
        switch toolTypeString {
        case "pen":
            drawingToolType = .pen
        case "pencil":
            drawingToolType = .pencil
        case "highlighter":
            drawingToolType = .highlighter
        case "eraser":
            drawingToolType = .eraser
        case "none":
            drawingToolType = .none
        default:
            drawingToolType = .pen
        }
        
        // Parse color
        let colorString = toolColor ?? "#000000"
        let color = PDFPageOverlayProvider.colorFromString(colorString)
        
        // Parse width (default 3.0, ensure minimum 0.5 and maximum 50)
        let widthValue = CGFloat(toolWidth?.floatValue ?? 3.0)
        let width = max(0.5, min(50.0, widthValue))
        
        // Parse opacity (default 1.0, clamp between 0.0 and 1.0)
        let opacityValue = CGFloat(toolOpacity?.floatValue ?? 1.0)
        let opacity = max(0.0, min(1.0, opacityValue))
        
        // Create and apply brush settings
        var settings = BrushSettings()
        settings.type = drawingToolType
        settings.color = color
        settings.width = width
        settings.opacity = opacity
        // Ensure eraserType is set for eraser tool
        if drawingToolType == .eraser {
            settings.eraserType = currentEraserType
        }
        
        // Update toolbar with current color to keep it in sync
        toolbar?.setBrushSettings(color: color, width: width, opacity: opacity)
        
        // Safely set brush settings
        overlayProvider.setBrushSettings(settings)
    }
    
    // MARK: - Export PDF
    
    @objc func exportAnnotatedPDF() -> String? {
        guard let pdfDoc = pdfDocument else { return nil }
        
        // Add annotation for each page with drawing
        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) as? MyPDFPage,
                  let drawing = page.drawing else { continue }
            
            let annotation = MyPDFAnnotation(
                bounds: page.bounds(for: .mediaBox),
                forType: .stamp,
                withProperties: nil
            )
            page.addAnnotation(annotation)
        }
        
        // Save with burned-in annotations
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("annotated_\(UUID().uuidString).pdf")
        
        let options: [PDFDocumentWriteOption: Any] = [.burnInAnnotationsOption: true]
        let data = pdfDoc.dataRepresentation(options: options)
        
        do {
            try data?.write(to: tempURL)
            return tempURL.path
        } catch {
            print("Error writing PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .changed else { return }
        let translation = gesture.translation(in: gesture.view)
        
        if translation.y < -50 {
            pdfView.goToNextPage(nil)
            gesture.setTranslation(.zero, in: gesture.view)
        } else if translation.y > 50 {
            pdfView.goToPreviousPage(nil)
            gesture.setTranslation(.zero, in: gesture.view)
        }
    }
    
    // MARK: - Event Sending
    
    private func sendLoadedEvent() {
        guard let onPDFLoaded = onPDFLoaded else { return }
        onPDFLoaded([
            "pageCount": pdfDocument?.pageCount ?? 0
        ])
    }
    
    private func sendErrorEvent(_ message: String) {
        guard let onPDFLoadError = onPDFLoadError else { return }
        onPDFLoadError([
            "error": message
        ])
    }
    
    @objc func sendAnnotationCompleteEvent(_ filePath: String) {
        guard let onAnnotationComplete = onAnnotationComplete else { return }
        onAnnotationComplete([
            "filePath": filePath
        ])
    }
    
    @objc func sendAnnotationCancelEvent() {
        guard let onAnnotationCancel = onAnnotationCancel else { return }
        onAnnotationCancel([:])
    }
}

