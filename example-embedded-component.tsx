/**
 * Example: Embedded PDF Annotation Component
 * Shows how to use PDFAnnotationView as an embedded component
 * taking up half the screen with other components
 */

import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { PDFAnnotationView, BrushSettings, ToolType } from './RNPDFAnnotatorView';
import RNFS from 'react-native-fs';

export default function EmbeddedPDFAnnotatorScreen() {
  const [isAnnotating, setIsAnnotating] = useState(false);
  const [drawWithFinger, setDrawWithFinger] = useState(true);
  const [pdfURL, setPdfURL] = useState(
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
  );
  const [loading, setLoading] = useState(false);
  const [pageCount, setPageCount] = useState(0);
  const [brushSettings, setBrushSettings] = useState<BrushSettings>({
    type: 'pen',
    color: '#000000',
    width: 3.0,
    opacity: 1.0,
  });
  const pdfViewRef = useRef<PDFAnnotationView>(null);

  // Handle PDF loaded
  const handlePDFLoaded = (event: { nativeEvent: { pageCount: number } }) => {
    setPageCount(event.nativeEvent.pageCount);
    setLoading(false);
    Alert.alert('Success', `PDF loaded with ${event.nativeEvent.pageCount} pages`);
  };

  // Handle PDF load error
  const handlePDFLoadError = (event: { nativeEvent: { error: string } }) => {
    setLoading(false);
    Alert.alert('Error', event.nativeEvent.error);
  };

  // Handle annotation complete
  const handleAnnotationComplete = (event: { nativeEvent: { filePath: string } }) => {
    Alert.alert('Success', `PDF exported to: ${event.nativeEvent.filePath}`);
  };

  // Export annotated PDF
  const handleExportPDF = async () => {
    if (!pdfViewRef.current) {
      Alert.alert('Error', 'PDF view not available');
      return;
    }

    try {
      setLoading(true);
      const result = await pdfViewRef.current.exportAnnotatedPDF();
      
      // Save to documents
      const destPath = `${RNFS.DocumentDirectoryPath}/annotated_${Date.now()}.pdf`;
      await RNFS.copyFile(result.filePath, destPath);
      
      Alert.alert('Success', `PDF exported to: ${destPath}`);
      
      // Clean up temp file
      await RNFS.unlink(result.filePath);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to export PDF');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>PDF Annotator</Text>
        <Text style={styles.headerSubtitle}>
          {pageCount > 0 ? `${pageCount} pages` : 'No PDF loaded'}
        </Text>
      </View>

      {/* Main Content - Split Screen */}
      <View style={styles.contentContainer}>
        {/* Left Half - PDF View */}
        <View style={styles.pdfContainer}>
          <PDFAnnotationView
            ref={pdfViewRef}
            style={styles.pdfView}
            pdfURL={pdfURL}
            isAnnotating={isAnnotating}
            drawWithFinger={drawWithFinger}
            brushSettings={brushSettings}
            onPDFLoaded={handlePDFLoaded}
            onPDFLoadError={handlePDFLoadError}
            onAnnotationComplete={handleAnnotationComplete}
            onAnnotationCancel={() => Alert.alert('Cancelled', 'Annotation cancelled')}
          />
          
          {/* PDF Controls Overlay */}
          <View style={styles.controlsOverlay}>
            <TouchableOpacity
              style={[styles.controlButton, isAnnotating && styles.controlButtonActive]}
              onPress={() => setIsAnnotating(!isAnnotating)}
            >
              <Text style={styles.controlButtonText}>
                {isAnnotating ? '✏️ Annotating' : '📄 View'}
              </Text>
            </TouchableOpacity>
            
            {isAnnotating && (
              <TouchableOpacity
                style={[styles.controlButton, drawWithFinger && styles.controlButtonActive]}
                onPress={() => setDrawWithFinger(!drawWithFinger)}
              >
                <Text style={styles.controlButtonText}>
                  {drawWithFinger ? '👆 Finger' : '✏️ Pencil'}
                </Text>
              </TouchableOpacity>
            )}
            
            <TouchableOpacity
              style={styles.controlButton}
              onPress={handleExportPDF}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator size="small" color="white" />
              ) : (
                <Text style={styles.controlButtonText}>💾 Export</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>

        {/* Right Half - Other Components */}
        <View style={styles.sidePanel}>
          <ScrollView style={styles.sidePanelContent}>
            <Text style={styles.sidePanelTitle}>Settings</Text>
            
            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>PDF URL</Text>
              <TouchableOpacity
                style={styles.urlButton}
                onPress={() => {
                  Alert.prompt(
                    'Enter PDF URL',
                    'Enter a URL to load a different PDF',
                    [
                      { text: 'Cancel', style: 'cancel' },
                      {
                        text: 'Load',
                        onPress: (url) => {
                          if (url) {
                            setLoading(true);
                            setPdfURL(url);
                          }
                        },
                      },
                    ],
                    'plain-text',
                    pdfURL
                  );
                }}
              >
                <Text style={styles.urlButtonText} numberOfLines={1}>
                  {pdfURL}
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>Annotation Mode</Text>
              <TouchableOpacity
                style={[
                  styles.toggleButton,
                  isAnnotating && styles.toggleButtonActive,
                ]}
                onPress={() => setIsAnnotating(!isAnnotating)}
              >
                <Text style={styles.toggleButtonText}>
                  {isAnnotating ? '✓ Enabled' : '✗ Disabled'}
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>Drawing Input</Text>
              <TouchableOpacity
                style={[
                  styles.toggleButton,
                  drawWithFinger && styles.toggleButtonActive,
                ]}
                onPress={() => setDrawWithFinger(!drawWithFinger)}
              >
                <Text style={styles.toggleButtonText}>
                  {drawWithFinger ? '✓ Finger Drawing' : '✗ Pencil Only'}
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>Tool Type</Text>
              <View style={styles.toolButtons}>
                {(['pen', 'pencil', 'highlighter', 'eraser'] as ToolType[]).map((tool) => (
                  <TouchableOpacity
                    key={tool}
                    style={[
                      styles.toolButton,
                      brushSettings.type === tool && styles.toolButtonActive,
                    ]}
                    onPress={() => setBrushSettings({ ...brushSettings, type: tool })}
                  >
                    <Text style={styles.toolButtonText}>
                      {tool === 'pen' && '✏️'}
                      {tool === 'pencil' && '✎'}
                      {tool === 'highlighter' && '🖍️'}
                      {tool === 'eraser' && '🧹'}
                      {' '}
                      {tool.charAt(0).toUpperCase() + tool.slice(1)}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>Color</Text>
              <View style={styles.colorButtons}>
                {[
                  { name: 'Black', color: '#000000' },
                  { name: 'Red', color: '#FF0000' },
                  { name: 'Blue', color: '#0000FF' },
                  { name: 'Green', color: '#00FF00' },
                  { name: 'Yellow', color: '#FFFF00' },
                  { name: 'Purple', color: '#800080' },
                ].map((colorOption) => (
                  <TouchableOpacity
                    key={colorOption.color}
                    style={[
                      styles.colorButton,
                      { backgroundColor: colorOption.color },
                      brushSettings.color === colorOption.color && styles.colorButtonActive,
                    ]}
                    onPress={() => setBrushSettings({ ...brushSettings, color: colorOption.color })}
                  >
                    {brushSettings.color === colorOption.color && (
                      <Text style={styles.colorCheckmark}>✓</Text>
                    )}
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>
                Width: {brushSettings.width?.toFixed(1)}pt
              </Text>
              <View style={styles.sliderContainer}>
                <Text style={styles.sliderLabel}>1</Text>
                <TouchableOpacity
                  style={styles.sliderTrack}
                  onPress={(e) => {
                    const { locationX, layout } = e.nativeEvent as any;
                    const width = Math.max(1, Math.min(20, (locationX / 250) * 19 + 1));
                    setBrushSettings({ ...brushSettings, width });
                  }}
                >
                  <View
                    style={[
                      styles.sliderThumb,
                      { left: `${((brushSettings.width ?? 3) - 1) / 19 * 100}%` },
                    ]}
                  />
                </View>
                <Text style={styles.sliderLabel}>20</Text>
              </View>
              <View style={styles.quickWidthButtons}>
                {[1, 3, 5, 10].map((width) => (
                  <TouchableOpacity
                    key={width}
                    style={[
                      styles.quickWidthButton,
                      brushSettings.width === width && styles.quickWidthButtonActive,
                    ]}
                    onPress={() => setBrushSettings({ ...brushSettings, width })}
                  >
                    <Text style={styles.quickWidthButtonText}>{width}pt</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>
                Opacity: {((brushSettings.opacity ?? 1.0) * 100).toFixed(0)}%
              </Text>
              <View style={styles.sliderContainer}>
                <Text style={styles.sliderLabel}>0%</Text>
                <TouchableOpacity
                  style={styles.sliderTrack}
                  onPress={(e) => {
                    const { locationX } = e.nativeEvent as any;
                    const opacity = Math.max(0, Math.min(1, locationX / 250));
                    setBrushSettings({ ...brushSettings, opacity });
                  }}
                >
                  <View
                    style={[
                      styles.sliderThumb,
                      { left: `${(brushSettings.opacity ?? 1.0) * 100}%` },
                    ]}
                  />
                </View>
                <Text style={styles.sliderLabel}>100%</Text>
              </View>
              <View style={styles.quickWidthButtons}>
                {[0.25, 0.5, 0.75, 1.0].map((opacity) => (
                  <TouchableOpacity
                    key={opacity}
                    style={[
                      styles.quickWidthButton,
                      brushSettings.opacity === opacity && styles.quickWidthButtonActive,
                    ]}
                    onPress={() => setBrushSettings({ ...brushSettings, opacity })}
                  >
                    <Text style={styles.quickWidthButtonText}>
                      {(opacity * 100).toFixed(0)}%
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.settingsSection}>
              <Text style={styles.settingsLabel}>Info</Text>
              <Text style={styles.infoText}>
                • Two-finger swipe to navigate pages{'\n'}
                • Tap annotation button to enable drawing{'\n'}
                • Select tool, color, width, and opacity{'\n'}
                • Use Export to save annotated PDF
              </Text>
            </View>
          </ScrollView>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#007AFF',
    paddingTop: 50,
    paddingBottom: 15,
    paddingHorizontal: 20,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
  },
  headerSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginTop: 4,
  },
  contentContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  pdfContainer: {
    flex: 1,
    backgroundColor: '#333',
    position: 'relative',
  },
  pdfView: {
    flex: 1,
  },
  controlsOverlay: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    flexDirection: 'row',
    gap: 10,
  },
  controlButton: {
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderRadius: 8,
    flex: 1,
    alignItems: 'center',
  },
  controlButtonActive: {
    backgroundColor: '#007AFF',
  },
  controlButtonText: {
    color: 'white',
    fontWeight: '600',
    fontSize: 14,
  },
  sidePanel: {
    width: 300,
    backgroundColor: 'white',
    borderLeftWidth: 1,
    borderLeftColor: '#e0e0e0',
  },
  sidePanelContent: {
    flex: 1,
    padding: 20,
  },
  sidePanelTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#333',
  },
  settingsSection: {
    marginBottom: 25,
  },
  settingsLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
  },
  urlButton: {
    backgroundColor: '#f0f0f0',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  urlButtonText: {
    fontSize: 12,
    color: '#007AFF',
  },
  toggleButton: {
    backgroundColor: '#f0f0f0',
    padding: 12,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#ddd',
  },
  toggleButtonActive: {
    backgroundColor: '#e3f2fd',
    borderColor: '#007AFF',
  },
  toggleButtonText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  infoText: {
    fontSize: 12,
    color: '#666',
    lineHeight: 20,
  },
  toolButtons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  toolButton: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: '#f0f0f0',
    padding: 12,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#ddd',
    alignItems: 'center',
  },
  toolButtonActive: {
    backgroundColor: '#e3f2fd',
    borderColor: '#007AFF',
  },
  toolButtonText: {
    fontSize: 12,
    color: '#333',
    fontWeight: '500',
  },
  colorButtons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  colorButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: '#ddd',
    alignItems: 'center',
    justifyContent: 'center',
  },
  colorButtonActive: {
    borderColor: '#007AFF',
    borderWidth: 3,
  },
  colorCheckmark: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
    textShadowColor: 'rgba(0,0,0,0.5)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  sliderContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 10,
  },
  sliderLabel: {
    fontSize: 12,
    color: '#666',
    width: 35,
  },
  sliderTrack: {
    flex: 1,
    height: 30,
    backgroundColor: '#f0f0f0',
    borderRadius: 15,
    position: 'relative',
    marginHorizontal: 10,
  },
  sliderThumb: {
    position: 'absolute',
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#007AFF',
    top: 3,
    marginLeft: -12,
  },
  quickWidthButtons: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
  },
  quickWidthButton: {
    flex: 1,
    backgroundColor: '#f0f0f0',
    padding: 8,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ddd',
    alignItems: 'center',
  },
  quickWidthButtonActive: {
    backgroundColor: '#e3f2fd',
    borderColor: '#007AFF',
  },
  quickWidthButtonText: {
    fontSize: 12,
    color: '#333',
    fontWeight: '500',
  },
});

