//
//  MarkdownPlugin.m
//  Markdown
//
//  Created by Atsushi Nagase on 5/26/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "MarkdownPlugin.h"
#import "PreviewWindowController.h"
#import "markdown.h"
#import "html.h"
#import <WebKit/WebKit.h>

@interface MarkdownPlugin ()

- (id)initWithPlugInController:(CodaPlugInsController*)aController
                 withBundleURL:(NSURL *)bundleURL;
- (void)reloadPreview;
- (void)reloadStylesheet;
- (NSString *)html;
- (NSString *)windowTitle;

@property (strong) CodaPlugInsController *pluginController;
@property (readonly) PreviewWindowController *previewWindowController;
@property (strong) NSURL *stylesheetURL;

@end

@implementation MarkdownPlugin

NSString *const kStylesheetURLDefaultsKey = @"MarkdownPluginSelectedStylesheetURL";

NSString *const kInitialHTMLTemplate = @"<html>\
<head>\
<link rel=\"stylesheet\" type=\"text/css\" href=\"%@\">\
</head>\
<body>\
%@\
</body>\
</html>";

@synthesize pluginController = _pluginController
, previewWindowController = _previewWindowController
, stylesheetURL = _stylesheetURL
, bundleURL = _bundleURL
;

#pragma mark - CodaPlugin Methods

- (NSString *)name { return @"Markdown Wiki"; }

- (id)initWithPlugInController:(CodaPlugInsController*)aController
                  plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle {
  return self = [self initWithPlugInController:aController withBundleURL:plugInBundle.bundleURL];
}

- (id)initWithPlugInController:(CodaPlugInsController *)aController
                        bundle:(NSBundle *)yourBundle {
  return self = [self initWithPlugInController:aController withBundleURL:yourBundle.bundleURL];
}

- (id)initWithPlugInController:(CodaPlugInsController*)aController
                 withBundleURL:(NSURL *)bundleURL {
  if(self=[self init]) {
    self.bundleURL = bundleURL;
    self.pluginController = aController;
    [NSEvent addLocalMonitorForEventsMatchingMask:NSRightMouseUpMask handler:^NSEvent *(NSEvent *event) {
      [self reloadPreview];
      return event;
    }];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseUpMask handler:^NSEvent *(NSEvent *event) {
      [self reloadPreview];
      return event;
    }];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSOtherMouseUpMask handler:^NSEvent *(NSEvent *event) {
      [self reloadPreview];
      return event;
    }];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyUpMask handler:^NSEvent *(NSEvent *event) {
      [self reloadPreview];
      return event;
    }];
    [aController registerActionWithTitle:NSLocalizedString(@"Open preview", nil)
                   underSubmenuWithTitle:nil
                                  target:self
                                selector:@selector(openPreview:)
                       representedObject:nil
                           keyEquivalent:nil
                              pluginName:self.name];
    
    [aController registerActionWithTitle:NSLocalizedString(@"Generate HTML", nil)
                   underSubmenuWithTitle:nil
                                  target:self
                                selector:@selector(generateHTML:)
                       representedObject:nil
                           keyEquivalent:nil
                              pluginName:self.name];
    
    [aController registerActionWithTitle:NSLocalizedString(@"Select StyleSheet", nil)
                   underSubmenuWithTitle:nil
                                  target:self
                                selector:@selector(selectStylesheet:)
                       representedObject:nil
                           keyEquivalent:nil
                              pluginName:self.name];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:kStylesheetURLDefaultsKey])
      self.stylesheetURL = [defaults URLForKey:kStylesheetURLDefaultsKey];
  }
  return self;
}

- (void)textViewDidFocus:(CodaTextView *)textView {
  [self reloadPreview];
  self.previewWindowController.window.title = self.windowTitle;
}

- (void)textViewWillSave:(CodaTextView *)textView {
}

#pragma mark -

- (void)openPreview:(id)sender {
  [self.previewWindowController showWindow:self];
  [self reloadPreview];
  self.previewWindowController.window.title = self.windowTitle;
}

- (void)generateHTML:(id)sender {
  NSString *html = self.html;
  CodaTextView *tv = [self.pluginController makeUntitledDocument];
  [tv insertText:html];
}

- (void)selectStylesheet:(id)sender {
  NSOpenPanel *pane = [NSOpenPanel openPanel];
  [pane setAllowedFileTypes:[NSArray arrayWithObject:@"css"]];
  [pane beginWithCompletionHandler:^(NSInteger result) {
    if(result == NSOKButton && pane.URL)
      self.stylesheetURL = pane.URL;
  }];
}

- (void)didPreviewClose {
}

#pragma mark -

- (PreviewWindowController *)previewWindowController {
  if(nil==_previewWindowController)
    _previewWindowController = [[PreviewWindowController alloc] initWithPlugin:self];
  return _previewWindowController;
}

- (void)setStylesheetURL:(NSURL *)stylesheetURL {
  _stylesheetURL = stylesheetURL;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setURL:stylesheetURL forKey:kStylesheetURLDefaultsKey];
  [defaults synchronize];
  [self reloadStylesheet];
}

- (NSURL *)stylesheetURL {
  return _stylesheetURL && [[NSFileManager defaultManager] fileExistsAtPath:_stylesheetURL.path] ?
  _stylesheetURL : [self.bundleURL URLByAppendingPathComponent:@"Contents/Resources/Default.css"];
}

- (NSString *)windowTitle {
  CodaTextView *tv = [self.pluginController focusedTextView:self];
  NSString *title = @"Markdown Preview";
  if(tv.path) {
    NSURL *URL = [[NSURL alloc] initFileURLWithPath:tv.path];
    title = [title stringByAppendingFormat:@": %@", [URL lastPathComponent]];
  }
  return title;
}

//
// Borrowed from https://gist.github.com/1291718
//

- (NSString *)html {
  CodaTextView *tv = [self.pluginController focusedTextView:self];
  NSString *source = tv.string;
  if(!source||source.length==0) return @"";
  
  struct sd_callbacks callbacks;
  struct html_renderopt options;
  const char *rawMarkdown = [source cStringUsingEncoding:NSUTF8StringEncoding];
  struct buf *inputBuffer = bufnew(strlen(rawMarkdown));
  bufputs(inputBuffer, rawMarkdown);
  
  // Parse the markdown into a new buffer using Sundown.
  struct buf *outputBuffer = bufnew(64);
  sdhtml_renderer(&callbacks, &options, 0);
  struct sd_markdown *markdown = sd_markdown_new(0, 16, &callbacks, &options);
  sd_markdown_render(outputBuffer, inputBuffer->data, inputBuffer->size, markdown);
  sd_markdown_free(markdown);
  
  NSString *parsedContent = [NSString stringWithCString:bufcstr(outputBuffer) encoding:NSUTF8StringEncoding];
  
  bufrelease(inputBuffer);
  bufrelease(outputBuffer);
  
  return parsedContent;
}

- (void)reloadStylesheet {
  [[self.previewWindowController.webView.mainFrame windowObject]
   evaluateWebScript:
   [NSString 
    stringWithFormat:
    @"document.querySelector(\"link[rel='stylesheet']\").setAttribute(\"href\", \"%@\")",
    self.stylesheetURL.absoluteString]];
}

- (void)reloadPreview {
  NSString *html = self.html;
  NSError *error = nil;
  WebFrame *frame = self.previewWindowController.webView.mainFrame;
  WebScriptObject *win = [frame windowObject];
  NSString *innerHTML = [win evaluateWebScript:@"document.body.innerHTML"];
  if(!innerHTML||innerHTML.length==0) {
    [self.previewWindowController.webView.mainFrame
     loadHTMLString:[NSString stringWithFormat:kInitialHTMLTemplate,
                     self.stylesheetURL.absoluteString, html]
     baseURL:self.bundleURL];
    return;
  }
  NSString * jsHTML =
  html ?
  [[NSString alloc] initWithData:
   [NSJSONSerialization dataWithJSONObject:html
                                   options:NSJSONReadingAllowFragments
                                     error:&error] encoding:NSUTF8StringEncoding] : @"";
  if(error) NSLog(@"%@", error);
  [win
   evaluateWebScript:[NSString stringWithFormat:@"document.body.innerHTML=%@",jsHTML]];
}

@end
