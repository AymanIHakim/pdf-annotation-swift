//
//  ContentView.swift
//  pdf-kit-2
//
//  Created by Ayman Ibne Hakim on 29/10/25.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    @StateObject private var viewModel = PDFViewModel()
    @State private var pdfURLString = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
    @State private var showingURLInput = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    @State private var pdfViewCoordinator: PDFAnnotationViewProper.Coordinator?
    @State private var canUndo = false
    @State private var canRedo = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Annotation Toolbar (shown when in annotation mode) - AT TOP
                if viewModel.isAnnotating && viewModel.pdfDocument != nil {
                    AnnotationToolbar(
                        brushSettings: $viewModel.brushSettings,
                        drawWithFinger: $viewModel.drawWithFinger,
                        showPencilKitToolPicker: $viewModel.showPencilKitToolPicker,
                        onUndo: {
                            pdfViewCoordinator?.undo()
                        },
                        onRedo: {
                            pdfViewCoordinator?.redo()
                        },
                        canUndo: canUndo,
                        canRedo: canRedo,
                        currentPage: viewModel.currentPageIndex,
                        totalPages: viewModel.totalPages
                    )
                }
                
                // PDF Viewer with Annotation (iOS 16+ Proper Way)
                ZStack {
                    if let pdfDocument = viewModel.pdfDocument {
                        if #available(iOS 16.0, *) {
                            PDFAnnotationViewProper(
                                pdfDocument: pdfDocument,
                                isAnnotating: $viewModel.isAnnotating,
                                drawWithFinger: $viewModel.drawWithFinger,
                                brushSettings: $viewModel.brushSettings,
                                showPencilKitToolPicker: $viewModel.showPencilKitToolPicker,
                                coordinator: $pdfViewCoordinator,
                                onPageChanged: { pageIndex in
                                    viewModel.currentPageIndex = pageIndex
                                },
                                onUndoRedoStateChanged: { canUndo, canRedo in
                                    self.canUndo = canUndo
                                    self.canRedo = canRedo
                                }
                            )
                            .ignoresSafeArea()
                        } else {
                            Text("iOS 16+ required for PDF annotation")
                                .foregroundColor(.red)
                        }
                    } else if viewModel.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading PDF...")
                                .padding(.top)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No PDF Loaded")
                                .font(.headline)
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            
                            Button("Load Sample PDF") {
                                viewModel.loadPDF(from: pdfURLString)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Load from Custom URL") {
                                showingURLInput = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                } // <-- End ZStack
            } // <-- End VStack
            .navigationTitle("PDF Annotator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.pdfDocument != nil {
                        // Save/Export button
                        Button(action: {
                            viewModel.shareAnnotatedPDF { url in
                                if let url = url {
                                    shareURL = url
                                    showingShareSheet = true
                                } else {
                                    saveMessage = "Failed to export PDF"
                                    showingSaveAlert = true
                                }
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            viewModel.toggleAnnotationMode()
                        }) {
                            Image(systemName: viewModel.isAnnotating ? "pencil.circle.fill" : "pencil.circle")
                                .foregroundColor(viewModel.isAnnotating ? .blue : .gray)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingURLInput = true
                    }) {
                        Image(systemName: "link")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Enter PDF URL", isPresented: $showingURLInput) {
                TextField("PDF URL", text: $pdfURLString)
                    .autocapitalization(.none)
                Button("Load") {
                    viewModel.loadPDF(from: pdfURLString)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the URL of a PDF file to load")
            }
            .alert("Export Status", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveMessage)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
} // <-- FIX: This closing bracket was missing!

// MARK: - Brush Settings View

struct BrushSettingsView: View {
    @Binding var brushSettings: BrushSettings
    @Environment(\.dismiss) var dismiss
    
    let toolTypes: [(DrawingToolType, String, String)] = [
        (.pen, "✏️", "Pen"),
        (.pencil, "✎", "Pencil"),
        (.highlighter, "🖍️", "Highlighter"),
        (.eraser, "🧹", "Eraser")
    ]
    
    let colors: [(String, String)] = [
        ("#000000", "Black"),
        ("#FF0000", "Red"),
        ("#0000FF", "Blue"),
        ("#00FF00", "Green"),
        ("#FFFF00", "Yellow"),
        ("#800080", "Purple"),
        ("#FFA500", "Orange"),
        ("#FF69B4", "Pink")
    ]
    
    // Helper to compare UIColor equality by components
    func colorsEqual(_ color1: UIColor, _ color2: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01 && abs(a1 - a2) < 0.01
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Tool Type Section
                Section("Tool Type") {
                    ForEach(toolTypes, id: \.0) { toolType, icon, name in
                        Button(action: {
                            brushSettings.type = toolType
                        }) {
                            HStack {
                                Text(icon)
                                    .font(.title2)
                                Text(name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if brushSettings.type == toolType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Color Section
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                        ForEach(colors, id: \.0) { colorHex, colorName in
                            Button(action: {
                                let color = PDFPageOverlayProvider.colorFromString(colorHex)
                                brushSettings.color = color
                            }) {
                                ZStack {
                                    let displayColor = PDFPageOverlayProvider.colorFromString(colorHex)
                                    Circle()
                                        .fill(Color(uiColor: displayColor))
                                        .frame(width: 50, height: 50)
                                    
                                    if colorsEqual(brushSettings.color, displayColor) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20, weight: .bold))
                                            .shadow(color: .black.opacity(0.5), radius: 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Width Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Width: \(String(format: "%.1f", brushSettings.width))pt")
                            .font(.headline)
                        
                        Slider(value: $brushSettings.width, in: 1...20, step: 0.5)
                        
                        HStack {
                            ForEach([1.0, 3.0, 5.0, 10.0] as [CGFloat], id: \.self) { width in
                                Button(action: {
                                    brushSettings.width = width
                                }) {
                                    Text("\(Int(width))pt")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            brushSettings.width == width ? Color.blue : Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            brushSettings.width == width ? .white : .primary
                                        )
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                    }
                } header: {
                    Text("Width")
                }
                
                // Opacity Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Opacity: \(String(format: "%.0f", brushSettings.opacity * 100))%")
                            .font(.headline)
                        
                        Slider(value: $brushSettings.opacity, in: 0...1, step: 0.05)
                        
                        HStack {
                            ForEach([0.25, 0.5, 0.75, 1.0] as [CGFloat], id: \.self) { opacity in
                                Button(action: {
                                    brushSettings.opacity = opacity
                                }) {
                                    Text("\(Int(opacity * 100))%")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            abs(brushSettings.opacity - opacity) < 0.01 ? Color.blue : Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            abs(brushSettings.opacity - opacity) < 0.01 ? .white : .primary
                                        )
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                    }
                } header: {
                    Text("Opacity")
                }
            }
            .navigationTitle("Brush Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

