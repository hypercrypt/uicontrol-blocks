//  Copyright (c) Hypercrypt Solutions Ltd. and individual contributors.
//  
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  
//      1. Redistributions of source code must retain the above copyright notice, 
//         this list of conditions and the following disclaimer.
//      
//      2. Redistributions in binary form must reproduce the above copyright 
//         notice, this list of conditions and the following disclaimer in the
//         documentation and/or other materials provided with the distribution.
//  
//      3. Neither the name of Django nor the names of its contributors may be used
//         to endorse or promote products derived from this software without
//         specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  UIControl+Blocks.m
//
//  Created by Klaus-Peter Dudas on 11/07/2012.
//

#import <objc/runtime.h>

#import "UIControl+Blocks.h"

static NSString * const UIControlBlocksControlEventsKey = @"UIControlBlocksControlEventsKey";
static NSString * const UIControlBlocksSelectorKey      = @"UIControlBlocksSelectorKey";

static inline NSString *uuid() {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef string = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return [(__bridge_transfer NSString *)string copy];
}

@implementation UIControl (Blocks)

- (NSMutableArray *)actionsArray
{
    NSMutableArray *actionsArray = objc_getAssociatedObject(self, _cmd);
    
    if (!actionsArray)
    {
        actionsArray = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, actionsArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return actionsArray;
}
    
- (id)addActionForControlEvents:(UIControlEvents)controlEvents usingBlock:(UIControlBlocksActionBlock)block
{
    static NSString * const CommonPrefix = @"UIControlBlocks__";
    
    if (![NSStringFromClass([self class]) hasPrefix:CommonPrefix])
    {
        NSString *newClassName = [@[CommonPrefix, NSStringFromClass([self class]), uuid()] componentsJoinedByString:@"__"];

        Class newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
        
        objc_registerClassPair(newClass);
        
        object_setClass(self, newClass);
    }
    
    NSString *actionString = [NSString stringWithFormat:@"%@__action__%@:forEvent:", CommonPrefix, uuid()];
    
    SEL action = NSSelectorFromString(actionString);
    IMP imp = imp_implementationWithBlock([^(id _self, UIControl *sender, UIEvent *event){ block(sender, event); } copy]);
    
    class_addMethod([self class], action, imp, "v@:@@");
    [self addTarget:self action:action forControlEvents:controlEvents];
    
    id actionIdentifier = @{
        UIControlBlocksSelectorKey:      actionString,
        UIControlBlocksControlEventsKey: @(controlEvents),
    };

    [self.actionsArray addObject:actionIdentifier];
    
    return actionIdentifier;
}

- (void)removeAllActions
{
    for (id action in [self.actionsArray copy])
    {
        [self removeAction:action];
    }
}

- (void)removeAction:(NSDictionary *)action
{
    NSParameterAssert([action isKindOfClass:[NSDictionary class]]);
    
    @try
    {
        SEL actionSelector = NSSelectorFromString(action[UIControlBlocksSelectorKey]);
        NSNumber *controlEventsNumber = action[UIControlBlocksControlEventsKey];
        [self removeTarget:self action:actionSelector forControlEvents:controlEventsNumber.unsignedIntegerValue];
        
        [self.actionsArray removeObject:action];
        
    }
    @catch (NSException *exception)
    {
    }
}

@end
