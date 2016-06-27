//
// Created by vikti on 22/06/2016.
//

#import <UIKit/UIKit.h>

#import "PluginOverlay.h"

@interface PluginDebugLayer : UIView
@property (nonatomic) PluginOverlay *pluginLayer;
@property (nonatomic) CGRect mapFrame;
@property (nonatomic) UIWebView *webView;
@property (nonatomic) float offsetX;
@property (nonatomic) float offsetY;
@property (nonatomic) BOOL debuggable;
@property (nonatomic) BOOL clickable;
@property (nonatomic) NSMutableDictionary *HTMLNodes;
- (void)putHTMLElement:(NSString *)domId size:(NSDictionary *)size;
- (void)removeHTMLElement:(NSString *)domId;
- (void)clearHTMLElement;
@end