//
//  MyPDFAnnotation.swift
//  pdf-kit-2
//
//  Custom PDFAnnotation subclass to render PencilKit drawings
//  Based on Apple WWDC22 - What's new in PDFKit
//

import PDFKit
import PencilKit
import UIKit

class MyPDFAnnotation: PDFAnnotation {
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let page = self.page as? MyPDFPage,
              let drawing = page.drawing,
              !drawing.bounds.isEmpty else {
            return
        }
        
        let pageBounds = page.bounds(for: box)
        
        UIGraphicsPushContext(context)
        context.saveGState()
        
        // Calculate the offset between where we are (pageBounds) and where annotation is (bounds)
        let offsetX = bounds.origin.x - pageBounds.origin.x
        let offsetY = bounds.origin.y - pageBounds.origin.y
        
        // Translate to the annotation position within the page
        context.translateBy(x: offsetX, y: offsetY)
        
        // Flip coordinate system: PDF uses bottom-left origin, UIKit uses top-left
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Extract drawing using the annotation bounds size
        let extractRect = CGRect(origin: .zero, size: bounds.size)
        let image = drawing.image(from: extractRect, scale: UIScreen.main.scale)
        
        // Draw at origin
        image.draw(at: .zero)
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}