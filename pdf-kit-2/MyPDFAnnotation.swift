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
              let drawing = page.drawing else {
            return
        }
        
        let pageBounds = page.bounds(for: box)
        
        UIGraphicsPushContext(context)
        context.saveGState()
        
        // Flip coordinate system: PDF uses bottom-left origin, UIKit uses top-left
        context.translateBy(x: 0, y: pageBounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Render drawing as image and draw it
        let image = drawing.image(from: pageBounds, scale: 2.0)
        image.draw(in: pageBounds)
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}

