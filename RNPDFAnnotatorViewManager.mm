//
//  RNPDFAnnotatorViewManager.mm
//  React Native ViewManager Bridge for Embedded PDF Annotation View
//

#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridge.h>

// Import frameworks required by Swift classes (must be before Swift header)
#import <PDFKit/PDFKit.h>
#import <PencilKit/PencilKit.h>

// Import Expo module for Expo types used in Swift header
#import <ExpoModulesCore-Swift.h>
#import <Expo-Swift.h>

// Import the Swift header to access Swift classes
// IMPORTANT: When integrating into your Expo app, replace "YourAppName" with your actual Expo app name
// The header name format is: "<YourAppName>-Swift.h" where hyphens may become underscores
// Example: If your app is "MyExpoApp", use: #import "MyExpoApp-Swift.h"
// To find your app name: Check your app.json/app.config.js → "name" field
// Or check Xcode Build Settings → "Product Module Name"
//
// For local testing in this project, you can use:
#import "pdf-kit-2-Swift.h"

@interface RNPDFAnnotatorViewManager : RCTViewManager
@end

@implementation RNPDFAnnotatorViewManager

RCT_EXPORT_MODULE(RNPDFAnnotatorView)

- (UIView *)view {
    return [[RNPDFAnnotatorView alloc] init];
}

// MARK: - Props

RCT_EXPORT_VIEW_PROPERTY(pdfURL, NSString)
RCT_EXPORT_VIEW_PROPERTY(isAnnotating, BOOL)
RCT_EXPORT_VIEW_PROPERTY(drawWithFinger, BOOL)
RCT_EXPORT_VIEW_PROPERTY(toolType, NSString)
RCT_EXPORT_VIEW_PROPERTY(toolColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(toolWidth, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(toolOpacity, NSNumber)

// MARK: - Events

RCT_EXPORT_VIEW_PROPERTY(onPDFLoaded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPDFLoadError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAnnotationComplete, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onAnnotationCancel, RCTDirectEventBlock)

// MARK: - Methods

RCT_EXPORT_METHOD(exportAnnotatedPDF:(nonnull NSNumber *)reactTag
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        UIView *view = viewRegistry[reactTag];
        if ([view isKindOfClass:[RNPDFAnnotatorView class]]) {
            RNPDFAnnotatorView *pdfView = (RNPDFAnnotatorView *)view;
            NSString *filePath = [pdfView exportAnnotatedPDF];
            if (filePath) {
                resolver(@{@"filePath": filePath});
            } else {
                rejecter(@"EXPORT_ERROR", @"Failed to export annotated PDF", nil);
            }
        } else {
            rejecter(@"INVALID_VIEW", @"View is not an instance of RNPDFAnnotatorView", nil);
        }
    }];
}

@end

