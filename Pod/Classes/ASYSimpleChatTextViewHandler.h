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

#import <UIKit/UIKit.h>

@protocol ASYSimpleChatTextViewHandlerDelegate;

/**
 Describes textView position in relation to scrollView
 */
typedef NS_ENUM(NSUInteger, ASYSimpleChatTextViewPosition) {
    /**
     Undefined (not set)
     */
    ASYSimpleChatTextViewPositionUndefined = NSUIntegerMax,
    /**
     TextView is at the bottom of scrollView
     */
    ASYSimpleChatTextViewPositionAtScrollViewBottom = 1u,
    /**
     TextView is at the top of scrollView
     */
    ASYSimpleChatTextViewPositionAtScrollViewTop = 2u,
};

/**
 An NSObject subclass to handle resizing of UITextView as the user types in.

 The textview resizes as long as the number of lines lies between specified minimum and maximum number of lines. This class calculates
 total size of UITextView text and adjusts the height constraint of that UITextView. You need to provide height constraint to
 UITextView.
 */
@interface ASYSimpleChatTextViewHandler : NSObject

/**
 UITextView to be handled
 */
@property (nonnull, nonatomic, strong, readonly) UITextView *chatTextView;

/**
 Animated height constraint of textView
 */
@property (nonnull, nonatomic, strong, readonly) NSLayoutConstraint *heightConstraint;

/**
 ObservableScrollView bottom constraint to avoid keyboard
 */
@property (nonnull, nonatomic, strong, readonly) NSLayoutConstraint *scrollViewKeyboardConstraint;

/**
 UIScrollView that animates along with textView and heightConstraint

 Useful for chat or add a comment stories
 */
@property (nonnull, nonatomic, strong, readonly) UIScrollView *observableScrollView;

/**
 The relative position of textView and scrollView.

 If scrollView is not nil default value is ASYSimpleChatTextViewPositionAtScrollViewBottom
 */
@property (nonatomic, assign) ASYSimpleChatTextViewPosition textViewPositionInRelationToScrollView;

/**
 Lower limit on number of lines
 */
@property (nonatomic, assign, readonly) NSUInteger minimumNumberOfLines;

/**
 Upper limit on number of lines
 */
@property (nonatomic, assign, readonly) NSUInteger maximumNumberOfLines;

/**
 Describes if heightConstraint's change should be animatable
 */
@property (nonatomic, assign) BOOL animated;

/**
 Duration of heightConstraint change animation
 */
@property (nonatomic, assign) CGFloat animationDuration;

/**
 Handler delegate
 */
@property (nullable, nonatomic, weak) id<ASYSimpleChatTextViewHandlerDelegate> delegate;

/**
 Returns an instance of ASYSimpleChatTextViewHandler.

 @param textView                 The UITextView which needs to be resized
 @param textViewHeightConstraint The height constraint of textview (changeable)
 */
- (nullable instancetype)initWithTextView:(nonnull UITextView *)textView
                     withHeightConstraint:(nonnull NSLayoutConstraint *)textViewHeightConstraint;

/**
 Returns an instance of ASYSimpleChatTextViewHandler.

 @param textView                     The UITextView which needs to be resized
 @param textViewHeightConstraint     The height constraint of textview (changeable)
 @param scrollView                   The UIScrollView that animates along with textView and heightConstraint
 @param scrollViewKeyboardConstraint The constraint to manipulate vertical position if inputView frame changes (changeable)
 */
- (nullable instancetype)initWithTextView:(nonnull UITextView *)textView
                     withHeightConstraint:(nonnull NSLayoutConstraint *)textViewHeightConstraint
                  andObservableScrollView:(nullable __kindof UIScrollView *)scrollView
                   withKeyboardConstraint:(nullable NSLayoutConstraint *)scrollViewKeyboardConstraint NS_DESIGNATED_INITIALIZER;

/**
 Limits resizing of UITextView with lines lower limit.
 
 @param minimumNumberOfLines Lower limit on number of lines
 */
- (void)updateMinimumNumberOfLines:(NSUInteger)minimumNumberOfLines;

/**
 Limits resizing of UITextView with lines upper limit.
 
 @param maximumNumberOfLines Upper limit on number of lines
 */
- (void)updateMaximumNumberOfLines:(NSUInteger)maximumNumberOfLines;

/**
 Limits resizing of UITextView between minimumNumberOfLines and maximumNumberOfLines.

 @param minimumNumberOfLines Lower limit on number of lines
 @param maximumNumberOfLines Upper limit on number of lines
 */
- (void)updateMinimumNumberOfLines:(NSUInteger)minimumNumberOfLines andMaximumNumberOfLines:(NSUInteger)maximumNumberOfLines;

/**
 Sets text of textView and resizes it according to the length of the text.
 Ignores object's animated property

 @param animated specify YES if you want to animate the size change of UITextView or NO if you don't
 */
- (void)setText:(nullable NSString *)text animated:(BOOL)animated;

/**
 Sets attributedText of textView and resizes it according to the length of the attributed text
 Ignores object's animated property.

 @param animated specify YES if you want to animate the size change of UITextView or NO if you don't
 */
- (void)setAttributedText:(nullable NSAttributedString *)attributedText animated:(BOOL)animated;

/**
 Appends appendedText to text of textView and resizes it according to the length of the resulting string
 Ignores object's animated property.

 @param animated specify YES if you want to animate the size change of UITextView or NO if you don't
*/
- (void)appendText:(nullable NSString *)appendedText animated:(BOOL)animated;

/**
 Appends attributed appendedText to attributedText of textView and resizes it according to the length of the resulting attributed
 string.
 Ignores object's animated property.

 @param animated specify YES if you want to animate the size change of UITextView or NO if you don't
 */
- (void)appendAttributedText:(nullable NSAttributedString *)appendedAttributedText animated:(BOOL)animated;

@end

@protocol ASYSimpleChatTextViewHandlerDelegate <NSObject>

@optional

- (void)textViewHandler:(nonnull ASYSimpleChatTextViewHandler *)handler
    willChangeHeightOfTextView:(nonnull UITextView *)textView
                          from:(CGFloat)originalHeight
                            to:(CGFloat)finalHeight;

- (void)textViewHandler:(nonnull ASYSimpleChatTextViewHandler *)handler
    didChangeHeightOfTextView:(nonnull UITextView *)textView
                         from:(CGFloat)originalHeight
                           to:(CGFloat)finalHeight;

@end
