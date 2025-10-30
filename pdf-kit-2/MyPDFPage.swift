//
//  MyPDFPage.swift
//  pdf-kit-2
//
//  Custom PDFPage subclass to store PencilKit drawings
//  Based on Apple WWDC22 - What's new in PDFKit
//

import PDFKit
import PencilKit

class MyPDFPage: PDFPage {
    // Store the drawing for this page
    var drawing: PKDrawing?
}

