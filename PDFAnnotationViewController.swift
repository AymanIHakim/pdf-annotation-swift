//
//  PDFAnnotationViewController.swift
//  Native View Controller for PDF Annotation
//

import UIKit
import PDFKit
import PencilKit

class PDFAnnotationViewController: UIViewController {
    
    // MARK: - Properties
    
    private let pdfURL: URL
    private let onComplete: (String) -> Void
    private let onCancel: () -> Void
    
    private var pdfView: PDFView!
    private var overlayProvider: PDFPageOverlayProvider!
    private var pdfDocument: MyPDFDocument?
    private var isAnnotating = false
    
    // MARK: - Initialization
    
    init(pdfURL: URL, onComplete: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.pdfURL = pdfURL
        self.onComplete = onComplete
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGray6
        title = "Annotate PDF"
        
        // Setup PDFView
        pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .lightGray
        view.addSubview(pdfView)
        
        // Setup overlay provider (iOS 16+)
        if #available(iOS 16.0, *) {
            overlayProvider = PDFPageOverlayProvider()
            pdfView.pageOverlayViewProvider = overlayProvider
        }
        
        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped)),
            UIBarButtonItem(image: UIImage(systemName: "pencil.circle"), style: .plain, target: self, action: #selector(toggleAnnotation))
        ]
    }
    
    private func loadPDF() {
        // Load PDF from URL
        if pdfURL.scheme == "http" || pdfURL.scheme == "https" {
            // Remote URL
            URLSession.shared.dataTask(with: pdfURL) { [weak self] data, response, error in
                guard let data = data, let pdfDoc = MyPDFDocument(data: data) else {
                    DispatchQueue.main.async {
                        self?.showError("Failed to load PDF")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.pdfDocument = pdfDoc
                    self?.pdfView.document = pdfDoc
                }
            }.resume()
        } else {
            // Local file
            if let pdfDoc = MyPDFDocument(url: pdfURL) {
                pdfDocument = pdfDoc
                pdfView.document = pdfDoc
            } else {
                showError("Failed to load PDF")
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleAnnotation() {
        isAnnotating.toggle()
        
        if #available(iOS 16.0, *) {
            pdfView.isInMarkupMode = isAnnotating
            overlayProvider?.setAnnotationMode(isAnnotating)
        }
        
        // Update button
        navigationItem.rightBarButtonItems?[1].image = UIImage(
            systemName: isAnnotating ? "pencil.circle.fill" : "pencil.circle"
        )
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
    
    @objc private func doneTapped() {
        guard let pdfDoc = pdfDocument else {
            showError("No PDF document loaded")
            return
        }
        
        // Export annotated PDF
        let exportedPath = exportAnnotatedPDF(pdfDoc)
        
        if let path = exportedPath {
            dismiss(animated: true) { [weak self] in
                self?.onComplete(path)
            }
        } else {
            showError("Failed to export annotated PDF")
        }
    }
    
    // MARK: - Export
    
    private func exportAnnotatedPDF(_ pdfDoc: MyPDFDocument) -> String? {
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
    
    // MARK: - Helper
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


