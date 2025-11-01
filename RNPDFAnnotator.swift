//
//  RNPDFAnnotator.swift
//  React Native PDF Annotation Module
//

import Foundation
import UIKit
import PDFKit
import PencilKit

@objc(RNPDFAnnotator)
class RNPDFAnnotator: NSObject {
    
    // MARK: - Annotate PDF Method
    
    @objc
    func annotatePDF(
        _ pdfURL: String,
        resolver: @escaping RCTPromiseResolveBlock,
        rejecter: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            // Validate URL
            guard let url = URL(string: pdfURL) else {
                rejecter("INVALID_URL", "Invalid PDF URL provided", nil)
                return
            }
            
            // Present annotation view controller
            self.presentAnnotationViewController(url: url, resolver: resolver, rejecter: rejecter)
        }
    }
    
    // MARK: - Present Annotation View
    
    private func presentAnnotationViewController(
        url: URL,
        resolver: @escaping RCTPromiseResolveBlock,
        rejecter: @escaping RCTPromiseRejectBlock
    ) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            rejecter("NO_ROOT_VC", "Could not find root view controller", nil)
            return
        }
        
        // Create and present the annotation view controller
        let annotationVC = PDFAnnotationViewController(
            pdfURL: url,
            onComplete: { [weak self] annotatedPDFPath in
                // Success - return the annotated PDF file path
                resolver(["filePath": annotatedPDFPath])
            },
            onCancel: { [weak self] in
                // User cancelled
                rejecter("USER_CANCELLED", "User cancelled annotation", nil)
            }
        )
        
        let navController = UINavigationController(rootViewController: annotationVC)
        navController.modalPresentationStyle = .fullScreen
        rootViewController.present(navController, animated: true)
    }
    
    // MARK: - React Native Requirements
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}


