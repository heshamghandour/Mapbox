#import "CDVMapbox.h"

@interface CDVMapbox(){
@private
  MapsManager *_mapsManager;
}
@end

@implementation CDVMapbox

- (void)pluginInitialize {

#if CORDOVA_VERSION_MIN_REQUIRED >= __CORDOVA_4_0_0
  self.webView.backgroundColor = [UIColor clearColor];
  self.webView.opaque = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageDidLoad) name:CDVPageDidLoadNotification object:nil];
#endif

  /* Init the plugin layer responsible to capture touch events.
   * It permits to have Dom Elements on top of the map.
   * If a touch event occurs in one of the embed rectangles and outside of a inner html element,
   * the plugin layer considers that is a map action (drag, pan, etc.).
   * If not, the user surely want to access the UIWebView.
  */
  self.pluginLayer = [[PluginLayer alloc] initWithFrame:self.webView.frame];
  self.pluginLayer.webView = self.webView;
  self.pluginLayer.backgroundColor = [UIColor whiteColor];
  self.pluginLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  /* Init a scroll view which on are attached the maps. This enables the map views to track the UIWebView.
   * This scroll view is synchronised with the web view UIScrollView thanks to the UIScrollViewDelegate functions
   */
  self.pluginScrollView = [[PluginScrollView alloc] initWithFrame:self.webView.frame];
  self.webView.scrollView.delegate = self;
  self.pluginScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.pluginScrollView setContentSize:CGSizeMake(320, 960)];

  [self.pluginLayer addSubview:self.pluginScrollView];

  /* Get all the current sub views of this view controller and pass it under the Plugin Layer.
   * Then, all user touch will be first intercepted by the plugin layer
   * which will decide whether or not it is a map action.
   */
  NSArray *subViews = self.viewController.view.subviews;
  UIView *view;
  for (int i = 0; i < [subViews count]; i++) {
    view = subViews[(NSUInteger) i];
    //NSLog(@"remove i=%d class=%@", i, view.class);
    [view removeFromSuperview];
    [self.pluginLayer addSubview: view];
  }

  [self.viewController.view addSubview:self.pluginLayer];



  /* Create a MapsManager to handle multiple maps.
   * Each map has an ID.
   * At each creation a mapFrame is added to the PluginLayer and the PluginScrollView
   */
  _mapsManager = [[MapsManager alloc] initWithCDVPlugin:self withCDVMapboxPlugin:self withAccessToken:[MGLAccountManager accessToken]];
}

/**
 * Make the web view background transparent to see the map through. Override CSS effect.
 */
-(void)pageDidLoad {
  self.webView.backgroundColor = [UIColor clearColor];
  self.webView.opaque = NO;
}

/**
 * Synchronise the pluginScrollView delegate to the main web view scroll view.
 * So the maps follow when the user pan the web page.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGPoint offset = self.pluginScrollView.contentOffset;
  offset.x = self.webView.scrollView.contentOffset.x;
  offset.y = self.webView.scrollView.contentOffset.y;
  [self.pluginScrollView setContentOffset:offset];
}

/**
 * Resize the plugin scroll view when the webview changes. (eg. Portrait <-> landscape)
 */
-(void)viewDidLayoutSubviews {
  [self.pluginScrollView setContentSize: self.webView.scrollView.contentSize];
  [self.pluginScrollView flashScrollIndicators];
}


// todo handle show specific map id
- (void) show:(CDVInvokedUrlCommand *)command {

    NSDictionary *args = command.arguments[0];

  // create map if id does not exist
  if(![_mapsManager getCcount] || [_mapsManager getMap:command.arguments[0][@"ids"][0] == nil]){

    Map *map = [self createMap:args];

    NSMutableDictionary *_args = [[NSMutableDictionary alloc] initWithDictionary:args];
    NSMutableArray *ids = [NSMutableArray array];
    [ids addObject:@((NSInteger) map.id)];
    _args[@"ids"] = ids;

    NSMutableArray *_arguments = [[NSMutableArray alloc] initWithArray:command.arguments];
    _arguments[0] = _args;

    // recreate the command with the new map before sending to exec
    CDVInvokedUrlCommand *newCommand = [[CDVInvokedUrlCommand alloc] initWithArguments:_arguments
                                                                            callbackId:command.callbackId
                                                                             className:command.className
                                                                            methodName:command.methodName];

      CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      pluginResult.keepCallback = @YES;
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

      // execute the command with the new map id
    [self exec:newCommand withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
        [aMap show:aCommand];
    }];
  } else {
    // or execute the original command
    [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
        [aMap show:aCommand];
    }];
  }
}

- (void) hide:(CDVInvokedUrlCommand *)command{
  NSDictionary *args = command.arguments[0];
  [_mapsManager removeMap:[args[@"ids"] allValues]];
}

- (void) onRegionWillChange:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap onRegionWillChange:aCommand];
  }];
}
- (void) onRegionIsChanging:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap onRegionIsChanging:aCommand];
  }];
}
- (void) onRegionDidChange:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap onRegionDidChange:aCommand];
  }];
}
- (void) setCenterCoordinates:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap setCenterCoordinates:aCommand];
  }];
}
- (void) getCenterCoordinates:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap getCenterCoordinates:aCommand];
  }];
}
- (void) getZoomLevel:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap getZoomLevel:aCommand];
  }];
}
- (void) setZoomLevel:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap setZoomLevel:aCommand];
  }];
}
- (void) getTilt:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap getTilt:aCommand];
  }];
}
- (void) setTilt:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap setTilt:aCommand];
  }];
}
- (void) animateCamera:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap animateCamera:aCommand];
  }];
}
- (void) addPolygon:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap addPolygon:aCommand];
  }];
}
- (void) addGeoJSON:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap addGeoJSON:aCommand];
  }];
}
- (void) addMarkers:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap addMarkers:aCommand];
  }];
}
- (void) addMarkerCallback:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap addMarkerCallback:aCommand];
  }];
}
- (void) convertCoordinate:(CDVInvokedUrlCommand *)command{
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand){
      [aMap convertCoordinate:aCommand];
  }];
}
- (void) convertPoint:(CDVInvokedUrlCommand *)command {
  [self exec:command withMethod:^(Map *aMap, CDVInvokedUrlCommand *aCommand) {
      [aMap convertPoint:aCommand];
  }];
}

- (void)exec:(CDVInvokedUrlCommand *)command withMethod:(void (^)(Map*, CDVInvokedUrlCommand*))execute_map_method {

  NSMutableArray *ids = [command.arguments[0][@"ids"] mutableCopy];

  // load all the map of the command
  for (NSInteger i = 0; i < [ids count]; i++) {
    int *index = (int *) [ids[(NSUInteger) i] intValue];
    Map *map = [_mapsManager getMap:(int) index];
    execute_map_method(map, command);
  }
}

- (Map*) createMap:(NSDictionary*)args{
//  [self.commandDelegate runInBackground:^{
  Map* map = [_mapsManager createMap:args];
  //CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: (int) map.id];
  // keep the callback because there are various events the developer may be interested in
  //pluginResult.keepCallback = @YES;
  return map;
  //}];
}

- (void) onPause:(Boolean *)multitasking{

}

- (void) onResume:(Boolean *)multitasking{

}

- (void) onDestroy{

}

- (float) getRetinaFactor{
  return 1.0;
}

@end
