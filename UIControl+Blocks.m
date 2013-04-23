//
//  Copyright (C) 2012-2013 Klaus-Peter Istvan Dudas
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
