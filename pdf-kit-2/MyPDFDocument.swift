//
//  MyPDFDocument.swift
//  pdf-kit-2
//
//  Custom PDFDocument subclass that uses MyPDFPage
//  Based on Apple WWDC22 - What's new in PDFKit
//

import PDFKit
import PencilKit

class MyPDFDocument: PDFDocument {
    // Override pageClass to return our custom page class
    override var pageClass: AnyClass {
        return MyPDFPage.self
    }
}

