//
//  NSString+Sundown.m
//  Markdown
//
//  Created by Atsushi Nagase on 5/28/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "NSString+Sundown.h"
#import "markdown.h"
#import "html.h"

@implementation NSString (Sundown)

//
// Borrowed from https://gist.github.com/1291718
//

- (NSString *)sd_renderedString {
  struct sd_callbacks callbacks;
  struct html_renderopt options;
  const char *rawMarkdown = [self cStringUsingEncoding:NSUTF8StringEncoding];
  struct buf *inputBuffer = bufnew(strlen(rawMarkdown));
  bufputs(inputBuffer, rawMarkdown);
  
  // Parse the markdown into a new buffer using Sundown.
  struct buf *outputBuffer = bufnew(64);
  sdhtml_renderer(&callbacks, &options, 0);
  unsigned int extensions = MKDEXT_NO_INTRA_EMPHASIS|MKDEXT_TABLES|MKDEXT_FENCED_CODE|MKDEXT_AUTOLINK|MKDEXT_STRIKETHROUGH|MKDEXT_SPACE_HEADERS|MKDEXT_SUPERSCRIPT|MKDEXT_LAX_SPACING;
  struct sd_markdown *markdown = sd_markdown_new(extensions, 16, &callbacks, &options);
  sd_markdown_render(outputBuffer, inputBuffer->data, inputBuffer->size, markdown);
  sd_markdown_free(markdown);
  
  NSString *parsedContent = [NSString stringWithCString:bufcstr(outputBuffer) encoding:NSUTF8StringEncoding];
  
  bufrelease(inputBuffer);
  bufrelease(outputBuffer);
  
  return parsedContent;
}

@end
