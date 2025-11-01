/**
 * Example React Native Usage
 * Complete example showing different use cases
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import RNPDFAnnotator from './modules/RNPDFAnnotator';
import RNFS from 'react-native-fs';

export default function PDFAnnotatorExample() {
  const [loading, setLoading] = useState(false);
  const [savedPDFs, setSavedPDFs] = useState<string[]>([]);

  // Example 1: Annotate a remote PDF
  const annotateRemotePDF = async () => {
    setLoading(true);
    try {
      const pdfURL = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
      
      const result = await RNPDFAnnotator.annotatePDF(pdfURL);
      
      // Save to documents
      const destPath = `${RNFS.DocumentDirectoryPath}/remote_annotated_${Date.now()}.pdf`;
      await RNFS.copyFile(result.filePath, destPath);
      
      setSavedPDFs(prev => [...prev, destPath]);
      Alert.alert('Success', 'PDF annotated and saved!');
      
      // Clean up temp file
      await RNFS.unlink(result.filePath);
      
    } catch (error: any) {
      if (error.code === 'USER_CANCELLED') {
        Alert.alert('Cancelled', 'You cancelled the annotation');
      } else {
        Alert.alert('Error', error.message || 'Failed to annotate PDF');
      }
    } finally {
      setLoading(false);
    }
  };

  // Example 2: Annotate a local PDF
  const annotateLocalPDF = async () => {
    setLoading(true);
    try {
      // Assume you have a PDF in your bundle or downloaded
      const localPDFPath = `${RNFS.DocumentDirectoryPath}/sample.pdf`;
      
      const result = await RNPDFAnnotator.annotatePDF(`file://${localPDFPath}`);
      
      const destPath = `${RNFS.DocumentDirectoryPath}/local_annotated_${Date.now()}.pdf`;
      await RNFS.moveFile(result.filePath, destPath);
      
      setSavedPDFs(prev => [...prev, destPath]);
      Alert.alert('Success', 'Local PDF annotated!');
      
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to annotate local PDF');
    } finally {
      setLoading(false);
    }
  };

  // Example 3: Annotate and upload to server
  const annotateAndUpload = async () => {
    setLoading(true);
    try {
      const pdfURL = 'https://example.com/document.pdf';
      
      const result = await RNPDFAnnotator.annotatePDF(pdfURL);
      
      // Read file as base64
      const fileContent = await RNFS.readFile(result.filePath, 'base64');
      
      // Upload to your backend
      const uploadResponse = await fetch('https://your-api.com/upload-annotated-pdf', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN',
        },
        body: JSON.stringify({
          filename: `annotated_${Date.now()}.pdf`,
          content: fileContent,
          contentType: 'application/pdf',
        }),
      });
      
      if (uploadResponse.ok) {
        Alert.alert('Success', 'PDF uploaded to server!');
      } else {
        throw new Error('Upload failed');
      }
      
      // Clean up
      await RNFS.unlink(result.filePath);
      
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to upload');
    } finally {
      setLoading(false);
    }
  };

  // Example 4: Share annotated PDF
  const annotateAndShare = async () => {
    setLoading(true);
    try {
      const pdfURL = 'https://example.com/document.pdf';
      
      const result = await RNPDFAnnotator.annotatePDF(pdfURL);
      
      // Use React Native Share
      const Share = require('react-native').Share;
      await Share.share({
        url: `file://${result.filePath}`,
        type: 'application/pdf',
        title: 'Share Annotated PDF',
      });
      
    } catch (error: any) {
      if (error.code !== 'USER_CANCELLED') {
        Alert.alert('Error', error.message);
      }
    } finally {
      setLoading(false);
    }
  };

  // List saved PDFs
  const listSavedPDFs = () => {
    if (savedPDFs.length === 0) {
      return <Text style={styles.emptyText}>No saved PDFs yet</Text>;
    }
    
    return savedPDFs.map((path, index) => (
      <View key={index} style={styles.pdfItem}>
        <Text style={styles.pdfPath} numberOfLines={1}>
          {path.split('/').pop()}
        </Text>
        <TouchableOpacity
          onPress={() => {
            Alert.alert('PDF Location', path, [
              { text: 'OK' },
              { 
                text: 'Delete',
                style: 'destructive',
                onPress: async () => {
                  await RNFS.unlink(path);
                  setSavedPDFs(prev => prev.filter(p => p !== path));
                }
              },
            ]);
          }}
        >
          <Text style={styles.viewButton}>View</Text>
        </TouchableOpacity>
      </View>
    ));
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>PDF Annotator Examples</Text>
      
      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Opening PDF...</Text>
        </View>
      )}
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Basic Examples</Text>
        
        <TouchableOpacity
          style={styles.button}
          onPress={annotateRemotePDF}
          disabled={loading}
        >
          <Text style={styles.buttonText}>📄 Annotate Remote PDF</Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={styles.button}
          onPress={annotateLocalPDF}
          disabled={loading}
        >
          <Text style={styles.buttonText}>📁 Annotate Local PDF</Text>
        </TouchableOpacity>
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Advanced Examples</Text>
        
        <TouchableOpacity
          style={styles.button}
          onPress={annotateAndUpload}
          disabled={loading}
        >
          <Text style={styles.buttonText}>☁️ Annotate & Upload</Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={styles.button}
          onPress={annotateAndShare}
          disabled={loading}
        >
          <Text style={styles.buttonText}>📤 Annotate & Share</Text>
        </TouchableOpacity>
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Saved PDFs</Text>
        {listSavedPDFs()}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginVertical: 20,
    color: '#333',
  },
  loadingContainer: {
    alignItems: 'center',
    padding: 20,
  },
  loadingText: {
    marginTop: 10,
    color: '#666',
  },
  section: {
    backgroundColor: 'white',
    marginHorizontal: 15,
    marginBottom: 15,
    borderRadius: 10,
    padding: 15,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 10,
    color: '#333',
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 8,
    marginBottom: 10,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  emptyText: {
    color: '#999',
    textAlign: 'center',
    padding: 20,
  },
  pdfItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 10,
    backgroundColor: '#f9f9f9',
    borderRadius: 5,
    marginBottom: 8,
  },
  pdfPath: {
    flex: 1,
    fontSize: 14,
    color: '#333',
  },
  viewButton: {
    color: '#007AFF',
    fontWeight: '600',
    marginLeft: 10,
  },
});


