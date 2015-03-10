//
//  MGSFragariaAPI.h
//  Fragaria
//
//  Created by Jim Derry on 3/10/15.
//
//


#import <Foundation/Foundation.h>
#import "MGSFragaria.h"


@class SMLTextView;
@class MGSLineNumberView;
@class SMLSyntaxColouring;

/**
 *  The MGSFragariaAPI protocol defines the properties and methods that are
 *  used to control and configure an instance of MGSFragaria. It is adopted
 *  by MGSFragariaView so that the API's are identical.
 **/

@protocol MGSFragariaAPI <NSObject>

#pragma mark - Required Properties and Methods
/// @name Required Properties and Methods
@required


#pragma mark - Accessing Fragaria's Views
/// @name Accessing Fragaria's Views


/** Fragaria's text view. */
@property (nonatomic, strong, readonly) SMLTextView *textView;
/** Fragaria's scroll view. */
@property (nonatomic, strong, readonly) NSScrollView *scrollView;
/** Fragaria's gutter view. */
@property (nonatomic, strong, readonly) MGSLineNumberView *gutterView;
/** Fragaria's syntax colouring object. */
@property  (nonatomic, assign, readonly) SMLSyntaxColouring *syntaxColouring;


#pragma mark - Accessing Text Content
/// @name Accessing Text Content


/** The plain text string of the text editor.*/
@property (nonatomic, assign) NSString *string;

/** The text editor string, including temporary attributes which
 *  have been applied by the syntax highlighter. */
@property (nonatomic, readonly) NSAttributedString *attributedStringWithTemporaryAttributesApplied;


#pragma mark - Creating Split Panels
/// @name Creating Split Panels


/** Replaces the text storage object of this Fragaria instance's text view to
 *  the specified text storage.
 *
 *  @discussion This allows two Fragaria instances to show the same text in a
 *              split view, for example. Replacing the text storage directly
 *              on the text view's layout manager is not supported, and will
 *              not work properly. The two Fragaria instances will not share
 *              their syntax definition or syntax errors.
 *  @param textStorage The new text storage for this instance of Fragaria. */
- (void)replaceTextStorage:(NSTextStorage*)textStorage;


#pragma mark - Configuring Syntax Highlighting
/// @name Configuring Syntax Highlighting


/** Specifies whether the document shall be syntax highlighted.*/
@property (nonatomic, getter=isSyntaxColoured) BOOL syntaxColoured;

/** Specifies the current syntax definition name.*/
@property (nonatomic, assign) NSString *syntaxDefinitionName;
/** The syntax colouring delegate for this instance of Fragaria. The syntax
 * colouring delegate gets notified of the start and end of each colouring pass
 * so that it can modify the default syntax colouring provided by Fragaria. */
@property (nonatomic, weak) id<SMLSyntaxColouringDelegate> syntaxColouringDelegate;

/** Indicates if multiline strings should be coloured.*/
@property BOOL coloursMultiLineStrings;
/** Indicates if coloring should end at end of line.*/
@property BOOL coloursOnlyUntilEndOfLine;


#pragma mark - Configuring Autocompletion
/// @name Configuring Autocompletion


/** The autocomplete delegate for this instance of Fragaria. The autocomplete
 * delegate provides a list of words that can be used by the autocomplete
 * feature. If this property is nil, then the list of autocomplete words will
 * be read from the current syntax highlighting dictionary. */
@property (nonatomic, weak) id<SMLAutoCompleteDelegate> autoCompleteDelegate;

/** Specifies the delay time for autocomplete, in seconds.*/
@property double autoCompleteDelay;
/** Specifies whether or not auto complete is enabled.*/
@property BOOL autoCompleteEnabled;
/** Specifies if autocompletion should include keywords.*/
@property BOOL autoCompleteWithKeywords;


#pragma mark - Highlighting the current line
/// @name Highlighting the Current Line


/** Specifies the color to use when highlighting the current line.*/
@property (nonatomic, assign) NSColor *currentLineHighlightColour;
/** Specifies whether or not the line with the cursor should be highlighted.*/
@property (nonatomic, assign) BOOL highlightsCurrentLine;


#pragma mark - Configuring the Gutter
/// @name Configuring the Gutter


/** Indicates whether or not the gutter is visible.*/
@property (nonatomic, assign) BOOL showsGutter;
/** Specifies the minimum width of the line number gutter.*/
@property (nonatomic, assign) CGFloat minimumGutterWidth;

/** Indicates whether or not line numbers are displayed when the gutter is visible.*/
@property (nonatomic, assign) BOOL showsLineNumbers;
/** Specifies the starting line number in the text view.*/
@property (nonatomic, assign) NSUInteger startingLineNumber;

/** Specifies the standard font for the line numbers in the gutter.*/
@property (nonatomic, assign) NSFont *gutterFont;
/** Specifies the standard color of the line numbers in the gutter.*/
@property (nonatomic, assign) NSColor *gutterTextColour;


#pragma mark - Showing Syntax Errors
/// @name Showing Syntax Errors


/** When set to an array containing SMLSyntaxError instances, Fragaria
 *  use these instances to provide feedback to the user in the form of:
 *   - highlighting lines and syntax errors in the text view.
 *   - displaying warning icons in the gutter.
 *   - providing a description of the syntax errors in popovers. */
@property (nonatomic, assign) NSArray *syntaxErrors;

/** Indicates whether or not error warnings are displayed.*/
@property (nonatomic, assign) BOOL showsSyntaxErrors;


#pragma mark - Showing Breakpoints
/// @name Showing Breakpoints


/** The breakpoint delegate for this instance of Fragaria. The breakpoint
 * delegate is responsible of managing a list of lines where a breakpoint
 * marker is present. */
@property (nonatomic, weak) id<MGSBreakpointDelegate> breakpointDelegate;


#pragma mark - Tabulation and Indentation
/// @name Tabulation and Indentation


/** Specifies the number of spaces per tab.*/
@property (nonatomic, assign) NSInteger tabWidth;
/** Specifies the automatic indentation width.*/
@property (nonatomic, assign) NSUInteger indentWidth;
/** Specifies whether spaces should be inserted instead of tab characters when indenting.*/
@property (nonatomic, assign) BOOL indentWithSpaces;
/** Specifies whether or not tab stops should be used when indenting.*/
@property (nonatomic, assign) BOOL useTabStops;
/** Indicates whether or not braces should be indented automatically.*/
@property (nonatomic, assign) BOOL indentBracesAutomatically;
/** Indicates whether or not new lines should be indented automatically.*/
@property (nonatomic, assign) BOOL indentNewLinesAutomatically;


#pragma mark - Automatic Bracing
/// @name Automatic Bracing


/** Specifies whether or not closing paretheses are inserted automatically.*/
@property (nonatomic, assign) BOOL insertClosingParenthesisAutomatically;
/** Specifies whether or not closing braces are inserted automatically.*/
@property (nonatomic, assign) BOOL insertClosingBraceAutomatically;

/** Specifies whether or not matching braces are shown in the editor.*/
@property (nonatomic, assign) BOOL showsMatchingBraces;


#pragma mark - Page Guide and Line Wrap
/// @name Showing the Page Guide


/** Indicates the column number at which the page guide appears.*/
@property (nonatomic, assign) NSInteger pageGuideColumn;
/** Specifies whether or not to show the page guide.*/
@property (nonatomic, assign) BOOL showsPageGuide;

/** Indicates whether or not line wrap is enabled.*/
@property (nonatomic, assign) BOOL lineWrap;


#pragma mark - Showing Invisible Characters
/// @name Showing Invisible Characters


/** Indicates whether or not invisible characters in the editor are revealed.*/
@property (nonatomic, assign) BOOL showsInvisibleCharacters;
/** Specifies the colour to render invisible characters in the text view.*/
@property (nonatomic, assign) NSColor *textInvisibleCharactersColour;


#pragma mark - Configuring Text Appearance
/// @name Configuring Text Appearance


/** Indicates the base (non-highlighted) text color.*/
@property (nonatomic, assign) NSColor *textColor;
/** Indicates the text view background color.*/
@property NSColor *backgroundColor;
/** Specifies the text editor font.*/
@property (nonatomic, assign) NSFont *textFont;


#pragma mark - Configuring Additional Text View Behavior
/// @name Configuring Additional Text View Behavior


/** The text view delegate of this instance of Fragaria. This is an utility
 * accessor and setter for textView.delegate. */
@property (nonatomic, weak) id<MGSFragariaTextViewDelegate> textViewDelegate;

/** Indicates whether or not the vertical scroller should be displayed.*/
@property (nonatomic, assign) BOOL hasVerticalScroller;
/** Indicates the color of the insertion point.*/
@property (nonatomic, assign) NSColor *insertionPointColor;
/** Indicates whether or not the "rubber band" effect is disabled.*/
@property (nonatomic, assign) BOOL scrollElasticityDisabled;

/** Scrolls the text view to a specific line, selecting it if specified.
 *  @param lineToGoTo Indicates the line the view should attempt to move to.
 *  @param centered   Deprecated parameter.
 *  @param highlight  Indicates whether or not the line should be selected. */
- (void)goToLine:(NSInteger)lineToGoTo centered:(BOOL)centered highlight:(BOOL)highlight;


#pragma mark - Optional Properties and Methods
/// @name Optional Properties and Methods
@optional


#pragma mark - Syntax Highlighting Colours
/// @name Syntax Highlighting Colours


/** Specifies the autocomplete color **/
@property (nonatomic, assign) NSColor *colourForAutocomplete;

/** Specifies the attributes color **/
@property (nonatomic, assign) NSColor *colourForAttributes;

/** Specifies the commands color **/
@property (nonatomic, assign) NSColor *colourForCommands;

/** Specifies the comments color **/
@property (nonatomic, assign) NSColor *colourForComments;

/** Specifies the instructions color **/
@property (nonatomic, assign) NSColor *colourForInstructions;

/** Specifies the keywords color **/
@property (nonatomic, assign) NSColor *colourForKeywords;

/** Specifies the numbers color **/
@property (nonatomic, assign) NSColor *colourForNumbers;

/** Specifies the strings color **/
@property (nonatomic, assign) NSColor *colourForStrings;

/** Specifies the variables color **/
@property (nonatomic, assign) NSColor *colourForVariables;


#pragma mark - Syntax Highlighter Colouring Options
/// @name Syntax Highlighter Colouring Options


/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursAttributes;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursAutocomplete;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursCommands;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursComments;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursInstructions;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursKeywords;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursNumbers;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursStrings;

/** Specifies whether or not attributes should be syntax coloured. */
@property (nonatomic, assign) BOOL coloursVariables;


@end