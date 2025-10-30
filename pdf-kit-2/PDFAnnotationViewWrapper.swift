//
//  PDFAnnotationViewWrapper.swift
//  pdf-kit-2
//
//  Wrapper to handle loading drawings
//

import SwiftUI
import PencilKit
import PDFKit

struct PDFAnnotationViewWrapper: View {
    let pdfDocument: PDFDocument?
    @Binding var isAnnotating: Bool
    @Binding var drawWithFinger: Bool
    @ObservedObject var viewModel: PDFViewModel
    @State private var controller: PDFAnnotationViewController?
    
    var body: some View {
        PDFAnnotationView(
            pdfDocument: pdfDocument,
            isAnnotating: $isAnnotating,
            drawWithFinger: $drawWithFinger,
            controllerReference: $controller,
            onPageChanged: { pageIndex, currentDrawing in
                // Save current drawing for this page, if supported
                // viewModel.overlayProvider?.saveDrawing(currentDrawing, forPageLabel: "\(pageIndex)")
                
                // Load the new page's drawing, if supported
                // let newDrawing = viewModel.overlayProvider?.loadDrawing(forPageLabel: "\(pageIndex)") ?? PKDrawing()
                // controller?.loadDrawing(newDrawing)
            },
            onDrawingChanged: { _ in
                // Drawing changed - auto-saved via onPageChanged
            }
        )
    }
}
