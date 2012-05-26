//
//  MarkdownPlugin.h
//  Markdown
//
//  Created by Atsushi Nagase on 5/26/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodaPlugInsController.h"

@interface MarkdownPlugin : NSObject<CodaPlugIn>

@property (strong) NSURL *bundleURL;

- (void)didPreviewClose;

@end
