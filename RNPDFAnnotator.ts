/**
 * RNPDFAnnotator.ts
 * TypeScript types for React Native PDF Annotator Module
 */

import { NativeModules } from 'react-native';

interface PDFAnnotatorResult {
  filePath: string;
}

interface RNPDFAnnotatorModule {
  /**
   * Opens native PDF annotation view
   * @param pdfURL - URL of the PDF to annotate (can be remote http/https or local file://)
   * @returns Promise with the path to the annotated PDF file
   */
  annotatePDF(pdfURL: string): Promise<PDFAnnotatorResult>;
}

const { RNPDFAnnotator } = NativeModules;

export default RNPDFAnnotator as RNPDFAnnotatorModule;


