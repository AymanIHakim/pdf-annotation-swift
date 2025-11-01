//
//  AnnotationToolbar.swift
//  pdf-kit-2
//
//  Custom annotation toolbar with inline customization panel
//

import SwiftUI
import PencilKit

struct AnnotationToolbar: View {
    @Binding var brushSettings: BrushSettings
    @Binding var drawWithFinger: Bool
    @Binding var showPencilKitToolPicker: Bool
    var onUndo: () -> Void
    var onRedo: () -> Void
    var canUndo: Bool
    var canRedo: Bool
    var currentPage: Int
    var totalPages: Int
    
    @State private var selectedToolForCustomization: DrawingToolType? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Main toolbar
            HStack(spacing: 12) {
                // Tool buttons
                ToolButton(
                    icon: "pencil",
                    title: "Pen",
                    isSelected: !showPencilKitToolPicker && brushSettings.type == .pen,
                    action: {
                        showPencilKitToolPicker = false
                        brushSettings.type = .pen
                        selectedToolForCustomization = .pen
                    }
                )
                
                ToolButton(
                    icon: "pencil.tip",
                    title: "Pencil",
                    isSelected: !showPencilKitToolPicker && brushSettings.type == .pencil,
                    action: {
                        showPencilKitToolPicker = false
                        brushSettings.type = .pencil
                        selectedToolForCustomization = .pencil
                    }
                )
                
                ToolButton(
                    icon: "paintbrush.fill",
                    title: "Highlighter",
                    isSelected: !showPencilKitToolPicker && brushSettings.type == .highlighter,
                    action: {
                        showPencilKitToolPicker = false
                        brushSettings.type = .highlighter
                        selectedToolForCustomization = .highlighter
                    }
                )
                
                ToolButton(
                    icon: "eraser.fill",
                    title: "Eraser",
                    isSelected: !showPencilKitToolPicker && brushSettings.type == .eraser,
                    action: {
                        showPencilKitToolPicker = false
                        brushSettings.type = .eraser
                        selectedToolForCustomization = .eraser
                    }
                )
                
                // PencilKit tool picker toggle
                ToolButton(
                    icon: "rectangle.and.pencil.and.ellipsis",
                    title: "PencilKit",
                    isSelected: showPencilKitToolPicker,
                    action: {
                        showPencilKitToolPicker.toggle()
                        if showPencilKitToolPicker {
                            selectedToolForCustomization = nil
                        } else {
                            // Restore last selected custom tool when turning off PencilKit
                            if brushSettings.type == .none {
                                brushSettings.type = .pen
                                selectedToolForCustomization = .pen
                            } else {
                                selectedToolForCustomization = brushSettings.type
                            }
                        }
                    }
                )
                
                Spacer()
                
                // Page number
                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // Undo button
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 18))
                        .foregroundColor(canUndo ? .primary : .gray.opacity(0.5))
                }
                .disabled(!canUndo)
                
                // Redo button
                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 18))
                        .foregroundColor(canRedo ? .primary : .gray.opacity(0.5))
                }
                .disabled(!canRedo)
                
                // Draw with finger toggle
                Button(action: {
                    drawWithFinger.toggle()
                }) {
                    Image(systemName: drawWithFinger ? "hand.draw.fill" : "hand.draw")
                        .font(.system(size: 18))
                        .foregroundColor(drawWithFinger ? .blue : .gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            
            // Inline customization panel
            if selectedToolForCustomization != nil && !showPencilKitToolPicker {
                ToolCustomizationPanel(
                    brushSettings: $brushSettings,
                    toolType: selectedToolForCustomization!
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

struct ToolButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .primary)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(width: 50, height: 50)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct ToolCustomizationPanel: View {
    @Binding var brushSettings: BrushSettings
    let toolType: DrawingToolType
    
    @State private var showingColorPicker = false
    @State private var customColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Stroke Width
                HStack(spacing: 6) {
                    Text("W:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .leading)
                    Slider(value: $brushSettings.width, in: 1...20, step: 0.5)
                        .frame(maxWidth: 80)
                    Text("\(Int(brushSettings.width))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25, alignment: .trailing)
                }
                .frame(maxWidth: 130)
                
                // Opacity (not shown for eraser)
                if toolType != .eraser {
                    HStack(spacing: 6) {
                        Text("O:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        Slider(value: $brushSettings.opacity, in: 0...1, step: 0.05)
                            .frame(maxWidth: 80)
                        Text("\(Int(brushSettings.opacity * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                    .frame(maxWidth: 140)
                }
                
                // Eraser Type (only for eraser tool)
                if toolType == .eraser {
                    VStack(spacing: 4) {
                        Text("Type")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Picker("Eraser Type", selection: $brushSettings.eraserType) {
                            Text("V").tag(EraserType.vector)
                            Text("P").tag(EraserType.bitmap)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 80)
                        .labelsHidden()
                    }
                    .frame(maxWidth: 100)
                }
                
                Spacer()
                
                // Color (not shown for eraser)
                if toolType != .eraser {
                    VStack(spacing: 4) {
                        Text("Color")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        ColorPickerButton(
                            color: $brushSettings.color,
                            showingColorPicker: $showingColorPicker
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(color: $brushSettings.color)
        }
    }
}

struct ColorPickerButton: View {
    @Binding var color: UIColor
    @Binding var showingColorPicker: Bool
    
    var body: some View {
        Button(action: {
            showingColorPicker = true
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(uiColor: color))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(6)
        }
    }
}

struct ColorPickerView: View {
    @Binding var color: UIColor
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedColorSpace: ColorSpace = .hex
    @State private var hexColor: String = "#000000"
    @State private var rgbRed: Double = 0
    @State private var rgbGreen: Double = 0
    @State private var rgbBlue: Double = 0
    @State private var rgbAlpha: Double = 1.0
    @State private var hsbHue: Double = 0
    @State private var hsbSaturation: Double = 0
    @State private var hsbBrightness: Double = 0
    
    enum ColorSpace: String, CaseIterable {
        case hex = "Hex"
        case rgb = "RGB"
        case hsb = "HSB"
        case preset = "Presets"
    }
    
    let presetColors: [(String, String)] = [
        ("#000000", "Black"),
        ("#FFFFFF", "White"),
        ("#FF0000", "Red"),
        ("#00FF00", "Green"),
        ("#0000FF", "Blue"),
        ("#FFFF00", "Yellow"),
        ("#FF00FF", "Magenta"),
        ("#00FFFF", "Cyan"),
        ("#FFA500", "Orange"),
        ("#800080", "Purple"),
        ("#FF69B4", "Pink"),
        ("#A52A2A", "Brown"),
        ("#808080", "Gray"),
        ("#008000", "Dark Green"),
        ("#000080", "Navy"),
        ("#800000", "Maroon")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ColorPicker("Select Color", selection: Binding(
                        get: { Color(uiColor: color) },
                        set: { color = UIColor($0) }
                    ))
                    .onChange(of: color) { newColor in
                        updateColorComponents(from: newColor)
                    }
                } header: {
                    Text("Color Picker")
                }
                
                Section {
                    Picker("Color Space", selection: $selectedColorSpace) {
                        ForEach(ColorSpace.allCases, id: \.self) { space in
                            Text(space.rawValue).tag(space)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                switch selectedColorSpace {
                case .hex:
                    Section {
                        TextField("Hex Color", text: $hexColor)
                            .autocapitalization(.none)
                            .onChange(of: hexColor) { newHex in
                                color = PDFPageOverlayProvider.colorFromString(newHex)
                            }
                    } header: {
                        Text("Hex Color (#RRGGBB or #AARRGGBB)")
                    }
                    
                case .rgb:
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Red")
                                Spacer()
                                Slider(value: $rgbRed, in: 0...255)
                                Text("\(Int(rgbRed))")
                                    .frame(width: 40)
                            }
                            HStack {
                                Text("Green")
                                Spacer()
                                Slider(value: $rgbGreen, in: 0...255)
                                Text("\(Int(rgbGreen))")
                                    .frame(width: 40)
                            }
                            HStack {
                                Text("Blue")
                                Spacer()
                                Slider(value: $rgbBlue, in: 0...255)
                                Text("\(Int(rgbBlue))")
                                    .frame(width: 40)
                            }
                            HStack {
                                Text("Alpha")
                                Spacer()
                                Slider(value: $rgbAlpha, in: 0...1)
                                Text(String(format: "%.2f", rgbAlpha))
                                    .frame(width: 40)
                            }
                        }
                        .onChange(of: rgbRed) { _ in updateColorFromRGB() }
                        .onChange(of: rgbGreen) { _ in updateColorFromRGB() }
                        .onChange(of: rgbBlue) { _ in updateColorFromRGB() }
                        .onChange(of: rgbAlpha) { _ in updateColorFromRGB() }
                    } header: {
                        Text("RGB Color")
                    }
                    
                case .hsb:
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Hue")
                                Spacer()
                                Slider(value: $hsbHue, in: 0...360)
                                Text("\(Int(hsbHue))°")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Saturation")
                                Spacer()
                                Slider(value: $hsbSaturation, in: 0...100)
                                Text("\(Int(hsbSaturation))%")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Brightness")
                                Spacer()
                                Slider(value: $hsbBrightness, in: 0...100)
                                Text("\(Int(hsbBrightness))%")
                                    .frame(width: 50)
                            }
                        }
                        .onChange(of: hsbHue) { _ in updateColorFromHSB() }
                        .onChange(of: hsbSaturation) { _ in updateColorFromHSB() }
                        .onChange(of: hsbBrightness) { _ in updateColorFromHSB() }
                    } header: {
                        Text("HSB Color")
                    }
                    
                case .preset:
                    Section {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                            ForEach(presetColors, id: \.0) { colorHex, colorName in
                                Button(action: {
                                    let newColor = PDFPageOverlayProvider.colorFromString(colorHex)
                                    color = newColor
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(uiColor: PDFPageOverlayProvider.colorFromString(colorHex)))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        Text(colorName)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Preset Colors")
                    }
                }
            }
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                updateColorComponents(from: color)
            }
        }
    }
    
    private func updateColorComponents(from uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        rgbRed = Double(r * 255)
        rgbGreen = Double(g * 255)
        rgbBlue = Double(b * 255)
        rgbAlpha = Double(a)
        
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &br, alpha: nil)
        hsbHue = Double(h * 360)
        hsbSaturation = Double(s * 100)
        hsbBrightness = Double(br * 100)
        
        hexColor = colorToHex(uiColor)
    }
    
    private func updateColorFromRGB() {
        color = UIColor(
            red: CGFloat(rgbRed / 255.0),
            green: CGFloat(rgbGreen / 255.0),
            blue: CGFloat(rgbBlue / 255.0),
            alpha: CGFloat(rgbAlpha)
        )
    }
    
    private func updateColorFromHSB() {
        color = UIColor(
            hue: CGFloat(hsbHue / 360.0),
            saturation: CGFloat(hsbSaturation / 100.0),
            brightness: CGFloat(hsbBrightness / 100.0),
            alpha: 1.0
        )
    }
    
    private func colorToHex(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

