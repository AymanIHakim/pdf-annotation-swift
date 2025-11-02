//
//  RNAnnotationToolbar.swift
//  React Native Annotation Toolbar
//
//  UIKit-based toolbar for React Native with annotate toggle and tools
//

import UIKit
import PencilKit

@objc(RNAnnotationToolbar)
class RNAnnotationToolbar: UIView {
    // MARK: - Properties
    
    private var stackView: UIStackView!
    private var annotationToggleButton: UIButton!
    private var toolsContainerView: UIView!
    private var toolsStackView: UIStackView!
    
    // Tool buttons
    private var undoButton: UIButton!
    private var redoButton: UIButton!
    private var fingerToggleButton: UIButton!
    private var pageLabel: UILabel!
    
    // Current state
    private var isAnnotating: Bool = false
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
        toolsStack.spacing = 12
        toolsStack.alignment = .center
        toolsStack.distribution = .fill
        toolsStack.translatesAutoresizingMaskIntoConstraints = false
        
        toolsStack.addArrangedSubview(UIView()) // Spacer on left
        
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
    
    private func updateToolbarVisibility() {
        // Remove all views from stack
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isAnnotating {
            stackView.addArrangedSubview(toolsContainerView)
        } else {
            stackView.addArrangedSubview(annotationToggleButton)
        }
    }
}

