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
