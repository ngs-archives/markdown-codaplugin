//
//  MarkdownPlugin.m
//  Markdown
//
//  Created by Atsushi Nagase on 5/26/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "MarkdownPlugin.h"
#import "NSString+Sundown.h"

@implementation MarkdownPlugin

#pragma mark - CodaPlugin Methods

- (NSString *)name { return @"Markdown"; }

- (NSString *)html {
  CodaTextView *tv = [self.pluginController focusedTextView:self];
  NSString *source = tv.string;
  return source && source.length>0 ? source.sd_renderedString : @"";
}

@end
