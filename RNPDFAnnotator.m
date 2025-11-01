//
//  RNPDFAnnotator.m
//  Objective-C Bridge for React Native
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNPDFAnnotator, NSObject)

// Annotate PDF method
RCT_EXTERN_METHOD(annotatePDF:(NSString *)pdfURL
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

@end


