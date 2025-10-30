//
//  PDFViewModel.swift
//  pdf-kit-2
//
//  Created by Ayman Ibne Hakim on 29/10/25.
//

import SwiftUI
import PDFKit
import PencilKit

class PDFViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAnnotating = false
    @Published var drawWithFinger = true
    
    func loadPDF(from urlString: String) {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
            isLoading = true
            errorMessage = nil
            
            // For remote URLs
        if url.scheme == "http" || url.scheme == "https" {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Error loading PDF: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let data = data else {
                        self?.errorMessage = "No data received"
                        return
                    }
                    
                        // Use MyPDFDocument instead of PDFDocument
                        if let pdfDoc = MyPDFDocument(data: data) {
                            self?.pdfDocument = pdfDoc
                        } else {
                            self?.errorMessage = "Failed to create PDF document"
                        }
                }
            }.resume()
        } else {
            // For local file URLs
            if let pdfDoc = MyPDFDocument(url: url) {
                pdfDocument = pdfDoc
                isLoading = false
            } else {
                errorMessage = "Failed to load PDF from local URL"
                isLoading = false
            }
        }
    }
    
    func toggleAnnotationMode() {
        isAnnotating.toggle()
    }
    
    func exportAnnotatedPDF() -> URL? {
        guard let pdfDoc = pdfDocument else { return nil }
        
        // Add annotation for each page with drawing
        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) as? MyPDFPage,
                  let drawing = page.drawing else { continue }
            
            let annotation = MyPDFAnnotation(bounds: page.bounds(for: .mediaBox), forType: .stamp, withProperties: nil)
            page.addAnnotation(annotation)
        }
        
        // Save with burned-in annotations
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("annotated_\(UUID().uuidString).pdf")
        let options: [PDFDocumentWriteOption: Any] = [.burnInAnnotationsOption: true]
        let data = pdfDoc.dataRepresentation(options: options)
        
        try? data?.write(to: tempURL)
        return data != nil ? tempURL : nil
    }
    
    func shareAnnotatedPDF(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let url = self?.exportAnnotatedPDF()
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
}

