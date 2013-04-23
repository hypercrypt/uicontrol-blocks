//
//  UIControl+Blocks.h
//
//  Created by Klaus-Peter Dudas on 11/07/2012.
//

#import <UIKit/UIKit.h>

typedef void(^UIControlBlocksActionBlock)(UIControl *sender, UIEvent *event);

@interface UIControl (Blocks)

- (id)addActionForControlEvents:(UIControlEvents)controlEvents usingBlock:(UIControlBlocksActionBlock)block;
- (void)removeAllActions;
- (void)removeAction:(id)action;

@end
