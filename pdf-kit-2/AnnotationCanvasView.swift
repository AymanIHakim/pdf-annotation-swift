//
//  AnnotationCanvasView.swift
//  pdf-kit-2
//
//  Created by Ayman Ibne Hakim on 29/10/25.
//

import SwiftUI
import PencilKit

struct AnnotationCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isAnnotating: Bool
    @Binding var toolPicker: PKToolPicker
    @Binding var drawWithFinger: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 3)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.becomeFirstResponder()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update drawing policy based on drawWithFinger setting
        if drawWithFinger {
            uiView.drawingPolicy = .anyInput  // Both pencil and finger
        } else {
            uiView.drawingPolicy = .pencilOnly  // Only Apple Pencil on iPad, but allows finger on iPhone
        }
        
        // Show or hide the tool picker based on annotation mode
        if isAnnotating {
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        } else {
            toolPicker.setVisible(false, forFirstResponder: uiView)
        }
    }
}

