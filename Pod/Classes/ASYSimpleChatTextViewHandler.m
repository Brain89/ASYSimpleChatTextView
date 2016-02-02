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

#import "ASYSimpleChatTextViewHandler.h"

#import "ASYAnimationCurveToAnimationOptionsConverter.h"
#import "ASYInputViewObserver.h"
#import "ASYRootViewFinder.h"

static CGFloat const ASYSimpleChatTextViewDefaultAnimationDuration = 0.34;
static NSUInteger const ASYSimpleChatTextViewDefaultMinimumNumberOfLines = 1u;
static NSUInteger const ASYSimpleChatTextViewDefaultMaximumNumberOfLines = NSUIntegerMax;

@interface ASYSimpleChatTextViewHandler () <ASYInputViewObserverDelegate>

@property (nonnull, nonatomic, strong, readwrite) UITextView *chatTextView;
@property (nonnull, nonatomic, strong, readwrite) NSLayoutConstraint *heightConstraint;
@property (nonnull, nonatomic, strong, readwrite) NSLayoutConstraint *scrollViewKeyboardConstraint;
@property (nonnull, nonatomic, strong, readwrite) UIScrollView *observableScrollView;

@property (nonatomic, assign) CGFloat scrollViewKeyboardConstraintOriginConstant;

@property (nonatomic, assign, readwrite) NSUInteger minimumNumberOfLines;
@property (nonatomic, assign, readwrite) NSUInteger maximumNumberOfLines;

@property (nonatomic, assign) CGFloat minimumHeight;
@property (nonatomic, assign) CGFloat maximumHeight;

@property (nullable, nonatomic, strong) ASYInputViewObserver *inputViewObserver;
@property (nullable, nonatomic, strong) ASYRootViewFinder *rootViewFinder;
@property (nullable, nonatomic, strong) ASYAnimationCurveToAnimationOptionsConverter *converter;

@end

@implementation ASYSimpleChatTextViewHandler

#pragma mark - Lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nullable instancetype)initWithTextView:(nonnull UITextView *)textView
                     withHeightConstraint:(nonnull NSLayoutConstraint *)textViewHeightConstraint
                  andObservableScrollView:(nullable __kindof UIScrollView *)scrollView
                   withKeyboardConstraint:(nullable NSLayoutConstraint *)scrollViewKeyboardConstraint {
    self = [super init];
    if (self) {
        _chatTextView = textView;
        _heightConstraint = textViewHeightConstraint;
        _scrollViewKeyboardConstraint = scrollViewKeyboardConstraint;
        _observableScrollView = scrollView;

        _scrollViewKeyboardConstraintOriginConstant = _scrollViewKeyboardConstraint.constant;

        _inputViewObserver = [ASYInputViewObserver new];
        _rootViewFinder = [ASYRootViewFinder new];
        _converter = [ASYAnimationCurveToAnimationOptionsConverter new];

        /**
         Sets default values
         */
        _textViewPositionInRelationToScrollView =
            (_observableScrollView != nil) ? ASYSimpleChatTextViewPositionAtScrollViewBottom : ASYSimpleChatTextViewPositionUndefined;
        _animated = YES;
        _animationDuration = ASYSimpleChatTextViewDefaultAnimationDuration;

        [self updateInputAccessoryView];
        [self updateMinimumNumberOfLines:ASYSimpleChatTextViewDefaultMinimumNumberOfLines
                 andMaximumNumberOfLines:ASYSimpleChatTextViewDefaultMaximumNumberOfLines];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTextViewTextDidChange:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:_chatTextView];
    }
    return self;
}

- (nullable instancetype)initWithTextView:(nonnull UITextView *)textView
                     withHeightConstraint:(nonnull NSLayoutConstraint *)textViewHeightConstraint {
    return [self initWithTextView:textView
             withHeightConstraint:textViewHeightConstraint
          andObservableScrollView:nil
           withKeyboardConstraint:nil];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (nullable instancetype)init {
    @throw
        [NSException exceptionWithName:NSInternalInconsistencyException
                                reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke "
                                                                  @"`initWithTextView:heightConstraint:scrollViewKeyboardConstraint:"
                                                                  @"andObservableScrollView:` instead.",
                                                                  NSStringFromClass([self class])]
                              userInfo:nil];
}

#pragma clang diagnostic pop

#pragma mark - Properties

- (void)setTextViewPositionInRelationToScrollView:(ASYSimpleChatTextViewPosition)aPosition {
    if (_textViewPositionInRelationToScrollView != aPosition) {
        _textViewPositionInRelationToScrollView = aPosition;
        [self updateInputAccessoryView];
    }
}

#pragma mark - Public methods

- (void)updateMinimumNumberOfLines:(NSUInteger)minimumNumberOfLines {
    [self updateMinimumNumberOfLines:minimumNumberOfLines andMaximumNumberOfLines:self.maximumNumberOfLines];
}

- (void)updateMaximumNumberOfLines:(NSUInteger)maximumNumberOfLines {
    [self updateMinimumNumberOfLines:self.minimumNumberOfLines andMaximumNumberOfLines:maximumNumberOfLines];
}

- (void)updateMinimumNumberOfLines:(NSUInteger)minimumNumberOfLines andMaximumNumberOfLines:(NSUInteger)maximumNumberOfLines {
    self.minimumNumberOfLines = minimumNumberOfLines;
    self.maximumNumberOfLines = maximumNumberOfLines;
    [self updateHeightAndResize];
}

- (void)setText:(nullable NSString *)text animated:(BOOL)animated {
    if (self.chatTextView.text.length == 0u && text.length == 0u) {
        return;
    }

    self.chatTextView.text = text;
    if (text.length == 0u) {
        [self updateWithHeight:self.minimumHeight animated:animated];
    } else {
        [self resizeTextViewAnimated:animated];
    }
}

- (void)setAttributedText:(nullable NSAttributedString *)attributedText animated:(BOOL)animated {
    if (self.chatTextView.attributedText.length == 0u && attributedText.length == 0u) {
        return;
    }

    self.chatTextView.attributedText = attributedText;
    if (attributedText.length == 0u) {
        [self updateWithHeight:self.minimumHeight animated:animated];
    } else {
        [self resizeTextViewAnimated:animated];
    }
}

- (void)appendText:(nullable NSString *)appendedText animated:(BOOL)animated {
    if (appendedText.length == 0u) {
        return;
    }

    if (self.chatTextView.text.length == 0u) {
        self.chatTextView.text = appendedText;
    } else {
        self.chatTextView.text = [self.chatTextView.text stringByAppendingString:appendedText];
    }
    [self resizeTextViewAnimated:animated];
}

- (void)appendAttributedText:(nullable NSAttributedString *)appendedAttributedText animated:(BOOL)animated {
    if (appendedAttributedText.length == 0u) {
        return;
    }

    if (self.chatTextView.attributedText.length == 0u) {
        self.chatTextView.attributedText = appendedAttributedText;
    } else {
        NSMutableAttributedString *mutableString = [self.chatTextView.attributedText mutableCopy];
        [mutableString appendAttributedString:appendedAttributedText];
        self.chatTextView.attributedText = mutableString;
    }
    [self resizeTextViewAnimated:animated];
}

#pragma mark - Notifications

- (void)handleTextViewTextDidChange:(NSNotification *)notification {
    [self resizeTextViewAnimated:self.animated];
}

#pragma mark - InputViewObserverDelegate methods

- (void)observer:(nonnull ASYInputViewObserver *)observer
    caughtAcessoryViewFrameWillChangeWithMinY:(CGFloat)inputAccessoryViewMinY
                            animationDuration:(NSTimeInterval)inputAccessoryViewAnimationDuration
                               animationCurve:(UIViewAnimationCurve)animationCurve {
    CGFloat constraintOffset = CGRectGetMaxY([UIScreen mainScreen].bounds) - inputAccessoryViewMinY +
                               CGRectGetHeight(self.chatTextView.inputAccessoryView.frame);
    CGFloat currentDataInScrollViewOffset =
        MAX(CGRectGetHeight(self.observableScrollView.frame) - self.observableScrollView.contentSize.height, 0.0);

    /**
     Increase because scrollViewKeyboardConstraintOriginConstant should change only for ASYSimpleChatTextViewPositionAtScrollViewBottom
     */
    CGFloat updatedConstraintConstant = self.scrollViewKeyboardConstraintOriginConstant + constraintOffset;
    CGFloat previousConstraintConstant = self.scrollViewKeyboardConstraint.constant;
    self.scrollViewKeyboardConstraint.constant = MAX(self.scrollViewKeyboardConstraintOriginConstant, updatedConstraintConstant);
    CGFloat constraintDelta = previousConstraintConstant - self.scrollViewKeyboardConstraint.constant;
    CGFloat updatedScrollViewContentOffsetY =
        MAX(self.observableScrollView.contentOffset.y - constraintDelta - currentDataInScrollViewOffset, 0.0);

    UIView *rootView = [self.rootViewFinder findRootViewOf:self.chatTextView];
    UIViewAnimationOptions optionsFromCurve = [self.converter convert:animationCurve];
    [UIView animateWithDuration:inputAccessoryViewAnimationDuration
                          delay:0.0
                        options:optionsFromCurve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [rootView layoutIfNeeded];
                         if (self.textViewPositionInRelationToScrollView == ASYSimpleChatTextViewPositionAtScrollViewBottom) {
                             self.observableScrollView.contentOffset =
                                 CGPointMake(self.observableScrollView.contentOffset.x, updatedScrollViewContentOffsetY);
                         }
                     }
                     completion:nil];
}

#pragma mark - Private helpers

- (CGFloat)recalculateMinimumHeight {
    CGFloat totalHeight = ceilf([self caretHeight] * self.minimumNumberOfLines + self.chatTextView.textContainerInset.top +
                                self.chatTextView.textContainerInset.bottom);
    return MAX(totalHeight, CGRectGetHeight(self.chatTextView.frame));
}

- (CGFloat)recalculateMaximumHeight {
    CGFloat totalHeight = ceilf([self caretHeight] * self.maximumNumberOfLines + self.chatTextView.textContainerInset.top +
                                self.chatTextView.textContainerInset.bottom);
    return totalHeight;
}

- (CGFloat)caretHeight {
    return CGRectGetHeight([self.chatTextView caretRectForPosition:self.chatTextView.selectedTextRange.end]);
}

- (CGFloat)currentHeight {
    CGFloat width = CGRectGetWidth(self.chatTextView.bounds) - 2.0 * self.chatTextView.textContainer.lineFragmentPadding;
    CGRect boundingRect =
        [self.chatTextView.attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                       context:nil];

    CGFloat heightByBoundingRect = ceilf(CGRectGetHeight(boundingRect) + self.chatTextView.font.lineHeight);
    return heightByBoundingRect;
}

- (NSUInteger)currentNumberOfLines {
    CGFloat caretHeight = [self caretHeight];
    CGFloat totalHeight =
        [self currentHeight] + self.chatTextView.textContainerInset.top + self.chatTextView.textContainerInset.bottom;
    NSUInteger numberOfLines = (totalHeight / caretHeight) - 1u;
    return numberOfLines;
}

- (void)resizeTextViewAnimated:(BOOL)animated {
    NSUInteger textViewNumberOfLines = self.currentNumberOfLines;
    CGFloat heightConstant = 0.0;
    if (textViewNumberOfLines <= self.minimumNumberOfLines) {
        heightConstant = self.minimumHeight;
    } else if ((textViewNumberOfLines > self.minimumNumberOfLines) && (textViewNumberOfLines <= self.maximumNumberOfLines)) {
        CGFloat currentHeight = [self currentHeight];
        heightConstant = (currentHeight > self.minimumHeight)
                             ? ((currentHeight < self.maximumHeight) ? currentHeight : self.maximumHeight)
                             : self.minimumHeight;
    } else if (textViewNumberOfLines > self.maximumNumberOfLines) {
        heightConstant = self.maximumHeight;
    }
    if (self.heightConstraint.constant != heightConstant) {
        [self updateWithHeight:heightConstant animated:animated];
    }
    if (textViewNumberOfLines <= self.maximumNumberOfLines) {
        [self.chatTextView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)updateInputAccessoryView {
    if (self.scrollViewKeyboardConstraint == nil) {
        self.inputViewObserver.delegate = nil;
        self.chatTextView.inputAccessoryView = nil;
    } else {
        self.inputViewObserver.delegate = self;
        self.chatTextView.inputAccessoryView = self.inputViewObserver;
    }
}

- (void)updateHeightAndResize {
    self.minimumHeight = [self recalculateMinimumHeight];
    self.maximumHeight = [self recalculateMaximumHeight];
    [self resizeTextViewAnimated:NO];
}

- (void)updateWithHeight:(CGFloat)height animated:(BOOL)animated {
    CGFloat originalHeight = CGRectGetHeight(self.chatTextView.frame);
    CGPoint updatedContentOffset = [self calculateUpdatedScrollViewContentOffsetWithHeight:height];
    self.heightConstraint.constant = height;

    if ([self.delegate respondsToSelector:@selector(textViewHandler:willChangeHeightOfTextView:from:to:)]) {
        [self.delegate textViewHandler:self willChangeHeightOfTextView:self.chatTextView from:originalHeight to:height];
    }

    UIView *rootView = [self.rootViewFinder findRootViewOf:self.chatTextView];
    if (animated == YES) {
        [UIView animateWithDuration:self.animationDuration
            animations:^{
                [rootView layoutIfNeeded];
                if (!CGPointEqualToPoint(self.observableScrollView.contentOffset, updatedContentOffset)) {
                    self.observableScrollView.contentOffset = updatedContentOffset;
                }
            }
            completion:^(BOOL finished) {
                if ([self.delegate respondsToSelector:@selector(textViewHandler:didChangeHeightOfTextView:from:to:)]) {
                    [self.delegate textViewHandler:self didChangeHeightOfTextView:self.chatTextView from:originalHeight to:height];
                }
            }];
    } else {
        [rootView layoutIfNeeded];
        if (!CGPointEqualToPoint(self.observableScrollView.contentOffset, updatedContentOffset)) {
            self.observableScrollView.contentOffset = updatedContentOffset;
        }
        if ([self.delegate respondsToSelector:@selector(textViewHandler:didChangeHeightOfTextView:from:to:)]) {
            [self.delegate textViewHandler:self didChangeHeightOfTextView:self.chatTextView from:originalHeight to:height];
        }
    }
}

- (CGPoint)calculateUpdatedScrollViewContentOffsetWithHeight:(CGFloat)height {
    CGPoint updatedContentOffset = self.observableScrollView.contentOffset;
    if (self.textViewPositionInRelationToScrollView == ASYSimpleChatTextViewPositionAtScrollViewBottom) {
        CGFloat heightDelta = height - self.heightConstraint.constant;
        CGFloat updatedScrollViewHeight = CGRectGetHeight(self.observableScrollView.bounds) - heightDelta;
        CGFloat updatedContentOffsetY = self.observableScrollView.contentOffset.y + heightDelta;
        if ((heightDelta > 0.0 && updatedScrollViewHeight <= self.observableScrollView.contentSize.height)) {
            updatedContentOffset = CGPointMake(self.observableScrollView.contentOffset.x, updatedContentOffsetY);
        } else if (heightDelta <= 0.0) {
            updatedContentOffsetY = (updatedContentOffsetY > 0.0) ? updatedContentOffsetY : 0.0;
            updatedContentOffset = CGPointMake(self.observableScrollView.contentOffset.x, updatedContentOffsetY);
        }
    }
    return updatedContentOffset;
}

@end
