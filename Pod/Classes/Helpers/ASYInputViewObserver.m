// The MIT License (MIT)
//
// Copyright (c) 2016 Sychev Aleksandr
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
// (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "ASYInputViewObserver.h"

@interface ASYInputViewObserver ()

@property (nonatomic, assign) CGPoint outScreenPoint1;
@property (nonatomic, assign) CGPoint outScreenPoint2;
@property (nonatomic, assign) CGPoint lattestOutScreenPoint;
@property (nonatomic, assign) CGRect lattestInputViewOriginalFrame;
@property (nonatomic, assign) CGRect lattestInputViewFinalFrame;
@property (nonatomic, assign) CGFloat fixRotationHeight;

@end

@implementation ASYInputViewObserver

#pragma mark - Lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        _outScreenPoint1 = CGPointMake(0.0, CGRectGetMaxY([UIScreen mainScreen].bounds));
        _outScreenPoint2 = CGPointMake(0.0, CGRectGetMaxX([UIScreen mainScreen].bounds));
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameWillChange:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Notifications

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *originalFrameValue = notification.userInfo[UIKeyboardFrameBeginUserInfoKey];
    NSValue *finalFrameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect originalFrame = [originalFrameValue CGRectValue];
    CGRect finalFrame = [finalFrameValue CGRectValue];
    CGPoint currentOutScreenPoint = CGPointMake(0.0, CGRectGetMaxY([UIScreen mainScreen].bounds));

    /**
     Fix iOS8 hardware keyboard toggling
     */
    if (CGRectEqualToRect(self.lattestInputViewFinalFrame, finalFrame) &&
        CGRectEqualToRect(self.lattestInputViewOriginalFrame, originalFrame)) {
        return;
    }

    /**
     Fix iOS8 & iOS9 hardware keyboard toggling
     */
    if (CGRectGetMinY(originalFrame) >= currentOutScreenPoint.y && CGRectGetMinY(finalFrame) >= currentOutScreenPoint.y &&
        CGPointEqualToPoint(currentOutScreenPoint, self.lattestOutScreenPoint)) {
        return;
    }

    CGFloat originalMinY = CGRectGetMinY(originalFrame);
    CGFloat finalMinY = CGRectGetMinY(finalFrame);
    CGFloat heightDelta = originalMinY - finalMinY;

    /**
     Fix iOS9 rotation
     */
    if (CGPointEqualToPoint(self.lattestInputViewFinalFrame.origin, self.outScreenPoint1) ||
        CGPointEqualToPoint(self.lattestInputViewFinalFrame.origin, self.outScreenPoint2)) {
        CGFloat originalHeight = CGRectGetHeight(originalFrame);
        CGFloat finalHeight = CGRectGetHeight(finalFrame);
        if (originalHeight != finalHeight) {
            self.fixRotationHeight = finalHeight;
            heightDelta = self.fixRotationHeight;
        }
    } else if (self.fixRotationHeight != 0.0) {
        heightDelta -= self.fixRotationHeight;
        self.fixRotationHeight = 0.0;
    }

    self.lattestInputViewOriginalFrame = originalFrame;
    self.lattestInputViewFinalFrame = finalFrame;
    self.lattestOutScreenPoint = currentOutScreenPoint;

    NSNumber *animationDurationValue = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurveValue = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];

    [self.delegate observer:self
        caughtAcessoryViewFrameWillChangeWithHeightDelta:heightDelta
                                       animationDuration:animationDurationValue.doubleValue
                                          animationCurve:animationCurveValue.integerValue];
}

@end
