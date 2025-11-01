/**
 * RNPDFAnnotatorView.tsx
 * React Native Component for Embedded PDF Annotation View
 */

import React from 'react';
import {
  requireNativeComponent,
  UIManager,
  ViewStyle,
  NativeModules,
  findNodeHandle,
} from 'react-native';

// Native component
const RNPDFAnnotatorViewNative = requireNativeComponent<any>('RNPDFAnnotatorView');

// View Manager for methods
const { RNPDFAnnotatorViewManager } = NativeModules;

// Types
export type ToolType = 'pen' | 'pencil' | 'highlighter' | 'eraser' | 'none';

export interface BrushSettings {
  type?: ToolType;
  color?: string; // Hex color string (e.g., "#FF0000" or "#AAFF0000" for ARGB)
  width?: number; // Stroke width (default: 3.0)
  opacity?: number; // Opacity 0.0 to 1.0 (default: 1.0)
}

export interface PDFAnnotationViewProps {
  style?: ViewStyle;
  pdfURL?: string;
  isAnnotating?: boolean;
  drawWithFinger?: boolean;
  brushSettings?: BrushSettings;
  // Legacy props (deprecated, use brushSettings instead)
  toolType?: ToolType;
  toolColor?: string;
  toolWidth?: number;
  toolOpacity?: number;
  onPDFLoaded?: (event: { nativeEvent: { pageCount: number } }) => void;
  onPDFLoadError?: (event: { nativeEvent: { error: string } }) => void;
  onAnnotationComplete?: (event: { nativeEvent: { filePath: string } }) => void;
  onAnnotationCancel?: () => void;
}

export interface PDFAnnotatorResult {
  filePath: string;
}

/**
 * Embedded PDF Annotation View Component
 * Can be used as a regular React Native View within your layout
 */
export class PDFAnnotationView extends React.Component<PDFAnnotationViewProps> {
  private viewRef: React.RefObject<any>;

  constructor(props: PDFAnnotationViewProps) {
    super(props);
    this.viewRef = React.createRef();
  }

  /**
   * Export the annotated PDF
   * @returns Promise with the path to the exported PDF file
   */
  async exportAnnotatedPDF(): Promise<PDFAnnotatorResult> {
    const nodeHandle = findNodeHandle(this.viewRef.current);
    if (!nodeHandle) {
      throw new Error('View reference not found');
    }
    return RNPDFAnnotatorViewManager.exportAnnotatedPDF(nodeHandle);
  }

  render() {
    const { brushSettings, toolType, toolColor, toolWidth, toolOpacity, ...otherProps } = this.props;
    
    // Support both brushSettings object and individual props (for backward compatibility)
    const props: any = {
      ...otherProps,
    };
    
    if (brushSettings) {
      props.toolType = brushSettings.type ?? 'pen';
      props.toolColor = brushSettings.color ?? '#000000';
      props.toolWidth = brushSettings.width ?? 3.0;
      props.toolOpacity = brushSettings.opacity ?? 1.0;
    } else {
      // Fallback to individual props if brushSettings not provided
      if (toolType !== undefined) props.toolType = toolType;
      if (toolColor !== undefined) props.toolColor = toolColor;
      if (toolWidth !== undefined) props.toolWidth = toolWidth;
      if (toolOpacity !== undefined) props.toolOpacity = toolOpacity;
    }
    
    return (
      <RNPDFAnnotatorViewNative
        ref={this.viewRef}
        {...props}
      />
    );
  }
}

export default PDFAnnotationView;

