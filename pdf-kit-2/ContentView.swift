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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // PDF Viewer with Annotation (iOS 16+ Proper Way)
                if let pdfDocument = viewModel.pdfDocument {
                    if #available(iOS 16.0, *) {
                        PDFAnnotationViewProper(
                            pdfDocument: pdfDocument,
                            isAnnotating: $viewModel.isAnnotating,
                            drawWithFinger: $viewModel.drawWithFinger
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
            }
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
                        
                            if viewModel.isAnnotating {
                                Button(action: {
                                    viewModel.drawWithFinger.toggle()
                                }) {
                                    Image(systemName: viewModel.drawWithFinger ? "hand.draw.fill" : "hand.draw")
                                }
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
}

#Preview {
    ContentView()
}
