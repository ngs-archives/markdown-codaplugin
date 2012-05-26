//
//  PreviewWindowController.h
//  Markdown
//
//  Created by Atsushi Nagase on 5/26/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MarkdownPlugin, WebView;
@interface PreviewWindowController : NSWindowController

- (id)initWithPlugin:(MarkdownPlugin *)plugin;

@property (weak) MarkdownPlugin *plugin;
@property (weak) IBOutlet WebView *webView;


@end
