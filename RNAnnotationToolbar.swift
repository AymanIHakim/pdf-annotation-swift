//
//  RNAnnotationToolbar.swift
//  React Native Annotation Toolbar
//
//  UIKit-based toolbar for React Native with annotate toggle and tools
//

import UIKit
import PencilKit

@objc(RNAnnotationToolbar)
class RNAnnotationToolbar: UIView, UIColorPickerViewControllerDelegate {
    // MARK: - Properties
    
    private var stackView: UIStackView!
    private var annotationToggleButton: UIButton!
    private var toolsContainerView: UIView!
    private var toolsStackView: UIStackView!
    private var customizationPanel: UIView?
    private var customizationPanelStack: UIStackView?
    private var selectedToolForCustomization: DrawingToolType?
    private var colorView: UIView?
    
    // Callbacks for customization changes
    var onColorChanged: ((UIColor) -> Void)?
    var onWidthChanged: ((CGFloat) -> Void)?
    var onOpacityChanged: ((CGFloat) -> Void)?
    var onEraserTypeChanged: ((EraserType) -> Void)?
    
    // Current brush settings (for initialization)
    private var currentColor: UIColor = .black
    private var currentWidth: CGFloat = 3.0
    private var currentOpacity: CGFloat = 1.0
    private var currentEraserType: EraserType = .vector
    
    // Tool buttons
    private var penButton: UIButton!
    private var pencilButton: UIButton!
    private var highlighterButton: UIButton!
    private var eraserButton: UIButton!
    private var pencilKitButton: UIButton!
    private var undoButton: UIButton!
    private var redoButton: UIButton!
    private var fingerToggleButton: UIButton!
    private var pageLabel: UILabel!
    
    // Current state
    private var isAnnotating: Bool = false
    private var currentTool: DrawingToolType = .pen
    private var showPencilKitToolPicker: Bool = false
    private var canUndo: Bool = false
    private var canRedo: Bool = false
    private var currentPage: Int = 0
    private var totalPages: Int = 0
    private var drawWithFinger: Bool = true
    
    // Callbacks
    var onAnnotationToggle: ((Bool) -> Void)?
    var onToolSelected: ((DrawingToolType) -> Void)?
    var onPencilKitToggle: ((Bool) -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onFingerToggle: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupToolbar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToolbar()
    }
    
    // MARK: - Setup
    
    private func setupToolbar() {
        backgroundColor = .systemBackground
        
        // Main container
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Annotation toggle button (shown when not annotating)
        annotationToggleButton = createAnnotateToggleButton()
        
        // Tools container (shown when annotating)
        toolsContainerView = UIView()
        setupToolsContainer()
    }
    
    private func createAnnotateToggleButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Annotate", for: .normal)
        button.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(annotateToggleTapped), for: .touchUpInside)
        
        // Add padding
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        return button
    }
    
    private func setupToolsContainer() {
        // Tools horizontal stack
        let toolsStack = UIStackView()
        toolsStack.axis = .horizontal
        toolsStack.spacing = 6
        toolsStack.alignment = .center
        toolsStack.distribution = .fill
        toolsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Tool buttons
        penButton = createToolButton(icon: "pencil", title: "Pen", tool: .pen)
        pencilButton = createToolButton(icon: "pencil.tip", title: "Pencil", tool: .pencil)
        highlighterButton = createToolButton(icon: "paintbrush.fill", title: "Highlighter", tool: .highlighter)
        eraserButton = createToolButton(icon: "eraser.fill", title: "Eraser", tool: .eraser)
        pencilKitButton = createToolButton(icon: "rectangle.and.pencil.and.ellipsis", title: "PencilKit", tool: .none)
        
        toolsStack.addArrangedSubview(penButton)
        toolsStack.addArrangedSubview(pencilButton)
        toolsStack.addArrangedSubview(highlighterButton)
        toolsStack.addArrangedSubview(eraserButton)
        toolsStack.addArrangedSubview(pencilKitButton)
        
        toolsStack.addArrangedSubview(UIView()) // Spacer
        
        // Page label
        pageLabel = UILabel()
        pageLabel.font = .systemFont(ofSize: 11, weight: .medium)
        pageLabel.textColor = .secondaryLabel
        pageLabel.text = "1 / 1"
        pageLabel.textAlignment = .center
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        toolsStack.addArrangedSubview(pageLabel)
        
        // Undo button
        undoButton = createActionButton(icon: "arrow.uturn.backward", action: #selector(undoTapped))
        toolsStack.addArrangedSubview(undoButton)
        
        // Redo button
        redoButton = createActionButton(icon: "arrow.uturn.forward", action: #selector(redoTapped))
        toolsStack.addArrangedSubview(redoButton)
        
        // Finger toggle
        fingerToggleButton = createActionButton(icon: "hand.draw.fill", action: #selector(fingerToggleTapped))
        fingerToggleButton.tintColor = .systemBlue // Initial state is finger drawing enabled
        toolsStack.addArrangedSubview(fingerToggleButton)
        
        // Annotation toggle (to disable annotation)
        let disableButton = createActionButton(icon: "pencil.circle.fill", action: #selector(annotateToggleTapped))
        disableButton.tintColor = .systemBlue
        toolsStack.addArrangedSubview(disableButton)
        
        toolsStackView = toolsStack
        
        toolsContainerView.addSubview(toolsStack)
        NSLayoutConstraint.activate([
            toolsStack.topAnchor.constraint(equalTo: toolsContainerView.topAnchor, constant: 8),
            toolsStack.leadingAnchor.constraint(equalTo: toolsContainerView.leadingAnchor, constant: 8),
            toolsStack.trailingAnchor.constraint(equalTo: toolsContainerView.trailingAnchor, constant: -8),
            toolsStack.bottomAnchor.constraint(equalTo: toolsContainerView.bottomAnchor, constant: -8)
        ])
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 2
    }
    
    private func createToolButton(icon: String, title: String, tool: DrawingToolType) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Vertical stack for icon and title
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        
        let iconImage = UIImage(systemName: icon)
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 8)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        
        button.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
        // Store tool in accessibility identifier for identification
        button.accessibilityIdentifier = tool.rawValue
        
        return button
    }
    
    private func createActionButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: icon)
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(image?.withConfiguration(configuration), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        return button
    }
    
    // MARK: - Actions
    
    @objc private func annotateToggleTapped() {
        isAnnotating.toggle()
        updateToolbarVisibility()
        onAnnotationToggle?(isAnnotating)
    }
    
    @objc private func toolButtonTapped(_ sender: UIButton) {
        // Determine which tool was tapped using button references
        if sender == penButton {
            selectTool(.pen)
        } else if sender == pencilButton {
            selectTool(.pencil)
        } else if sender == highlighterButton {
            selectTool(.highlighter)
        } else if sender == eraserButton {
            selectTool(.eraser)
        } else if sender == pencilKitButton {
            showPencilKitToolPicker.toggle()
            updatePencilKitButton()
            onPencilKitToggle?(showPencilKitToolPicker)
            if showPencilKitToolPicker {
                currentTool = .none
                selectedToolForCustomization = nil
                hideCustomizationPanel()
                updateToolButtonStates()
            }
        }
    }
    
    @objc private func undoTapped() {
        onUndo?()
    }
    
    @objc private func redoTapped() {
        onRedo?()
    }
    
    @objc private func fingerToggleTapped() {
        // Toggle finger drawing
        drawWithFinger.toggle()
        updateFingerToggleButton()
        onFingerToggle?(drawWithFinger)
    }
    
    func setDrawWithFinger(_ enabled: Bool) {
        drawWithFinger = enabled
        updateFingerToggleButton()
    }
    
    private func updateFingerToggleButton() {
        // Update button appearance based on state
        let iconName = drawWithFinger ? "hand.draw.fill" : "hand.draw"
        fingerToggleButton.setImage(UIImage(systemName: iconName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)), for: .normal)
        fingerToggleButton.tintColor = drawWithFinger ? .systemBlue : .label
    }
    
    // MARK: - Public Methods
    
    func setAnnotating(_ annotating: Bool) {
        isAnnotating = annotating
        updateToolbarVisibility()
    }
    
    func setCurrentTool(_ tool: DrawingToolType) {
        // Only update if tool actually changed and not showing PencilKit picker
        if !showPencilKitToolPicker && currentTool != tool {
            // Update state without triggering callback (this is called from outside)
            showPencilKitToolPicker = false
            currentTool = tool
            updateToolButtonStates()
            updatePencilKitButton()
            // Don't call onToolSelected here to avoid infinite loop
        }
    }
    
    func setPencilKitToolPickerVisible(_ visible: Bool) {
        showPencilKitToolPicker = visible
        updatePencilKitButton()
        if visible {
            currentTool = .none
            updateToolButtonStates()
        }
    }
    
    func setCanUndo(_ canUndo: Bool) {
        self.canUndo = canUndo
        undoButton.isEnabled = canUndo
        undoButton.tintColor = canUndo ? .label : .systemGray3
    }
    
    func setCanRedo(_ canRedo: Bool) {
        self.canRedo = canRedo
        redoButton.isEnabled = canRedo
        redoButton.tintColor = canRedo ? .label : .systemGray3
    }
    
    func setPage(_ current: Int, total: Int) {
        currentPage = current
        totalPages = total
        pageLabel.text = "\(current + 1) / \(total)"
    }
    
    // MARK: - Private Helpers
    
    private func selectTool(_ tool: DrawingToolType) {
        // Prevent redundant selection
        guard currentTool != tool || showPencilKitToolPicker else { return }
        
        showPencilKitToolPicker = false
        currentTool = tool
        
        // Update button states immediately for visual feedback
        updateToolButtonStates()
        updatePencilKitButton()
        
        // Show customization panel for all tools (eraser has width/type controls)
        if tool != .none {
            selectedToolForCustomization = tool
            showCustomizationPanel()
        } else {
            selectedToolForCustomization = nil
            hideCustomizationPanel()
        }
        
        // Call callback after UI update
        onToolSelected?(tool)
    }
    
    private func updateToolbarVisibility() {
        // Remove all views from stack (including customization panel)
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isAnnotating {
            stackView.addArrangedSubview(toolsContainerView)
            updateToolButtonStates()
            // Show customization panel if a tool is selected
            if let tool = selectedToolForCustomization {
                showCustomizationPanel()
            }
        } else {
            stackView.addArrangedSubview(annotationToggleButton)
            hideCustomizationPanel()
        }
    }
    
    private func updateToolButtonStates() {
        let buttons: [(UIButton, DrawingToolType)] = [
            (penButton, .pen),
            (pencilButton, .pencil),
            (highlighterButton, .highlighter),
            (eraserButton, .eraser)
        ]
        
        for (button, tool) in buttons {
            let isSelected = !showPencilKitToolPicker && currentTool == tool
            // Make highlight more visible
            button.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
            button.layer.cornerRadius = 8
            button.layer.masksToBounds = true
            button.tintColor = isSelected ? .systemBlue : .label
            // Also highlight the icon view if available
            if let stack = button.subviews.first(where: { $0 is UIStackView }) as? UIStackView,
               let iconView = stack.arrangedSubviews.first as? UIImageView {
                iconView.tintColor = isSelected ? .systemBlue : .label
            }
        }
    }
    
    private func updatePencilKitButton() {
        pencilKitButton.backgroundColor = showPencilKitToolPicker ? UIColor.systemBlue.withAlphaComponent(0.1) : .clear
        pencilKitButton.tintColor = showPencilKitToolPicker ? .systemBlue : .label
    }
    
    // MARK: - Customization Panel
    
    private func showCustomizationPanel() {
        guard let tool = selectedToolForCustomization, tool != .none else {
            hideCustomizationPanel()
            return
        }
        
        // Always recreate panel to ensure it matches the current tool
        setupCustomizationPanel()
        
        guard let panel = customizationPanel else { return }
        
        // Remove panel if already added
        panel.removeFromSuperview()
        
        // Add panel to stack
        stackView.addArrangedSubview(panel)
        
        // Animate appearance
        panel.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            panel.alpha = 1.0
        }
    }
    
    private func hideCustomizationPanel() {
        guard let panel = customizationPanel else { return }
        UIView.animate(withDuration: 0.2, animations: {
            panel.alpha = 0.0
        }) { _ in
            panel.removeFromSuperview()
        }
    }
    
    private func setupCustomizationPanel() {
        // Remove existing panel if any
        customizationPanel?.removeFromSuperview()
        
        let panel = UIView()
        panel.backgroundColor = .secondarySystemBackground
        panel.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(divider)
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        
        // Width slider (for all tools)
        let widthContainer = createSliderControl(
            label: "W:",
            value: currentWidth,
            min: 1.0,
            max: 20.0,
            onChange: { [weak self] value in
                self?.currentWidth = value
                self?.onWidthChanged?(value)
            }
        )
        stack.addArrangedSubview(widthContainer)
        
        if let tool = selectedToolForCustomization {
            if tool == .eraser {
                // Eraser type picker (only for eraser)
                let eraserTypeContainer = createEraserTypePicker()
                stack.addArrangedSubview(eraserTypeContainer)
            } else {
                // Opacity slider (for non-eraser tools)
                let opacityContainer = createSliderControl(
                    label: "O:",
                    value: currentOpacity,
                    min: 0.0,
                    max: 1.0,
                    onChange: { [weak self] value in
                        self?.currentOpacity = value
                        self?.onOpacityChanged?(value)
                    }
                )
                stack.addArrangedSubview(opacityContainer)
            }
        }
        
        // Spacer
        stack.addArrangedSubview(UIView())
        
        // Color picker button (not for eraser)
        if let tool = selectedToolForCustomization, tool != .eraser {
            let colorButton = createColorPickerButton()
            // Set initial color
            colorView?.backgroundColor = currentColor
            stack.addArrangedSubview(colorButton)
        }
        
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: panel.topAnchor),
            divider.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -8)
        ])
        
        customizationPanel = panel
        customizationPanelStack = stack
    }
    
    private func createSliderControl(label: String, value: CGFloat, min: CGFloat, max: CGFloat, onChange: @escaping (CGFloat) -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 10, weight: .medium)
        labelView.textColor = .secondaryLabel
        labelView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(labelView)
        
        let slider = UISlider()
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        slider.value = Float(value)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(slider)
        
        // Store callback in slider's tag (we'll use a dictionary for this)
        let sliderKey = ObjectIdentifier(slider)
        if sliderCallbacks == nil {
            sliderCallbacks = [:]
        }
        sliderCallbacks?[sliderKey] = onChange
        
        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 10, weight: .medium)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        // Update value label
        if label == "W:" {
            valueLabel.text = "\(Int(value))"
        } else {
            valueLabel.text = "\(Int(value * 100))%"
        }
        
        // Store reference to value label
        objc_setAssociatedObject(slider, "valueLabel", valueLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 20),
            
            slider.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 6),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 80),
            
            valueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 6),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.widthAnchor.constraint(equalToConstant: 25),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private var sliderCallbacks: [ObjectIdentifier: (CGFloat) -> Void]?
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let value = CGFloat(slider.value)
        let sliderKey = ObjectIdentifier(slider)
        sliderCallbacks?[sliderKey]?(value)
        
        // Update value label
        if let valueLabel = objc_getAssociatedObject(slider, "valueLabel") as? UILabel {
            if slider.maximumValue == 20 {
                valueLabel.text = "\(Int(value))"
            } else {
                valueLabel.text = "\(Int(value * 100))%"
            }
        }
    }
    
    private func createColorPickerButton() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Color"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        container.addSubview(label)
        
        let colorView = UIView()
        colorView.backgroundColor = .systemBlue
        colorView.layer.cornerRadius = 12
        colorView.layer.borderWidth = 1
        colorView.layer.borderColor = UIColor.separator.cgColor
        container.addSubview(colorView)
        
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(colorPickerButtonTapped), for: .touchUpInside)
        container.addSubview(button)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        colorView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            colorView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            colorView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 24),
            colorView.heightAnchor.constraint(equalToConstant: 24),
            
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Store color view reference for easy updates
        objc_setAssociatedObject(button, "colorView", colorView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.colorView = colorView
        colorView.backgroundColor = currentColor
        
        return container
    }
    
    @objc private func colorPickerButtonTapped() {
        if #available(iOS 14.0, *) {
            // Use modern UIColorPickerViewController
            let colorPicker = UIColorPickerViewController()
            colorPicker.selectedColor = currentColor
            colorPicker.delegate = self
            colorPicker.supportsAlpha = true
            
            // Present from toolbar's view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(colorPicker, animated: true)
            }
        } else {
            // Fallback to alert with preset colors
            let alert = UIAlertController(title: "Select Color", message: nil, preferredStyle: .actionSheet)
            
            let colors: [(String, UIColor)] = [
                ("Black", .black),
                ("White", .white),
                ("Red", .red),
                ("Blue", .systemBlue),
                ("Green", .systemGreen),
                ("Yellow", .yellow),
                ("Orange", .systemOrange),
                ("Purple", .systemPurple),
                ("Pink", .systemPink)
            ]
            
            for (name, color) in colors {
                alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                    self?.currentColor = color
                    self?.onColorChanged?(color)
                    self?.colorView?.backgroundColor = color
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Present from toolbar's view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = self
                    popover.sourceRect = bounds
                }
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    private func createEraserTypePicker() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Type"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        container.addSubview(label)
        
        let segmentedControl = UISegmentedControl(items: ["Vector", "Bitmap"])
        segmentedControl.selectedSegmentIndex = currentEraserType == .vector ? 0 : 1
        segmentedControl.addTarget(self, action: #selector(eraserTypeChanged(_:)), for: .valueChanged)
        container.addSubview(segmentedControl)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            segmentedControl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 120),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    @objc private func eraserTypeChanged(_ sender: UISegmentedControl) {
        let eraserType: EraserType = sender.selectedSegmentIndex == 0 ? .vector : .bitmap
        currentEraserType = eraserType
        onEraserTypeChanged?(eraserType)
    }
    
    // MARK: - Public Methods for Setting Initial Values
    
    func setBrushSettings(color: UIColor, width: CGFloat, opacity: CGFloat) {
        currentColor = color
        currentWidth = width
        currentOpacity = opacity
        colorView?.backgroundColor = color
        // Update sliders if panel exists
        if let panel = customizationPanel {
            updatePanelValues()
        }
    }
    
    private func updatePanelValues() {
        // This would update slider values if we stored references
        // For now, the sliders will use their initial values
    }
    
    // MARK: - UIColorPickerViewControllerDelegate
    
    @available(iOS 14.0, *)
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        currentColor = viewController.selectedColor
        onColorChanged?(viewController.selectedColor)
        colorView?.backgroundColor = viewController.selectedColor
    }
    
    @available(iOS 14.0, *)
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        // Color picker was dismissed
    }
}

