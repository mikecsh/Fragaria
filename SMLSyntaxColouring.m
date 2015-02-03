

/* This class syntax-colours and line-highlights. */

/*

 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria
 
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/
#import "MGSFragaria.h"
#import "MGSFragariaFramework.h"


// syntax colouring information dictionary keys
NSString *SMLSyntaxGroup = @"group";
NSString *SMLSyntaxGroupID = @"groupID";
NSString *SMLSyntaxWillColour = @"willColour";
NSString *SMLSyntaxAttributes = @"attributes";
NSString *SMLSyntaxInfo = @"syntaxInfo";

// syntax colouring group names
NSString *SMLSyntaxGroupNumber = @"number";
NSString *SMLSyntaxGroupCommand = @"command";
NSString *SMLSyntaxGroupInstruction = @"instruction";
NSString *SMLSyntaxGroupKeyword = @"keyword";
NSString *SMLSyntaxGroupAutoComplete = @"autocomplete";
NSString *SMLSyntaxGroupVariable = @"variable";
NSString *SMLSyntaxGroupFirstString = @"firstString";
NSString *SMLSyntaxGroupSecondString = @"secondString";
NSString *SMLSyntaxGroupAttribute = @"attribute";
NSString *SMLSyntaxGroupSingleLineComment = @"singleLineComment";
NSString *SMLSyntaxGroupMultiLineComment = @"multiLineComment";
NSString *SMLSyntaxGroupSecondStringPass2 = @"secondStringPass2";


// class extension
@interface SMLSyntaxColouring()

- (void)applySyntaxDefinition;
- (NSString *)assignSyntaxDefinition;
- (void)autocompleteWordsTimerSelector:(NSTimer *)theTimer;
- (NSString *)completeString;
- (void)applyColourDefaults;
- (NSRange)recolourRange:(NSRange)range;
- (void)removeAllColours;
- (void)removeColoursFromRange:(NSRange)range;
- (void)pageRecolour;
- (void)setColour:(NSDictionary *)colour range:(NSRange)range;
- (void)highlightLineRange:(NSRange)lineRange;
- (BOOL)isSyntaxColouringRequired;
- (NSDictionary *)syntaxDictionary;

@end


@implementation SMLSyntaxColouring


@synthesize reactToChanges, undoManager, syntaxErrors, syntaxDefinition;


#pragma mark -
#pragma mark Instance methods
/*
 
 - init
 
 */
- (id)init
{
	self = [self initWithDocument:nil];
	
	return self;
}

/*
 
 - initWithDocument:
 
 */
- (id)initWithDocument:(id)theDocument
{
	if ((self = [super init])) {

		NSAssert(theDocument, @"bad document");
		
		// retain the document
		document = theDocument;

		// configure the document text view
		NSTextView *textView = [document valueForKey:ro_MGSFOTextView];
		NSAssert([textView isKindOfClass:[NSTextView class]], @"bad textview");
        self.undoManager = [textView undoManager];
        
        NSScrollView *scrollView = [document valueForKey:ro_MGSFOScrollView];
        [[scrollView contentView] setPostsBoundsChangedNotifications:YES];

		// configure ivars
		lastCursorLocation = 0;
		lastLineHighlightRange = NSMakeRange(0, 0);
		reactToChanges = YES;
        syntaxColouringCleanRange = NSMakeRange(0, 0);
		
		// configure layout managers
		layoutManager = (SMLLayoutManager *)[textView layoutManager];
		
		// configure colouring
		[self applyColourDefaults];
		
		// configure syntax definition
		[self applySyntaxDefinition];
		
		// add document KVO observers
		[document addObserver:self forKeyPath:@"syntaxDefinition" options:NSKeyValueObservingOptionNew context:@"syntaxDefinition"];
        
        // add text view notification observers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:textView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:textView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageRecolour) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
		
		// add NSUserDefaultsController KVO observers
		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];

		[defaultsController addObserver:self forKeyPath:@"values.FragariaCommandsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaCommentsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaInstructionsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaKeywordsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaAutocompleteColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaVariablesColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaStringsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaAttributesColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaNumbersColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
        
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourCommands" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourComments" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourInstructions" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourKeywords" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourAutocomplete" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourVariables" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourStrings" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourAttributes" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourNumbers" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
        
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourMultiLineStrings" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaOnlyColourTillTheEndOfLine" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaHighlightCurrentLine" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaHighlightLineColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.FragariaColourMultiLineStrings" options:NSKeyValueObservingOptionNew context:@"MultiLineChanged"];
        
        [defaultsController addObserver:self forKeyPath:@"values.FragariaLineWrapNewDocuments" options:NSKeyValueObservingOptionNew context:@"LineWrapChanged"];
	}
	
    return self;
}


#pragma mark -
#pragma mark KVO
/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"ColoursChanged"]) {
		[self applyColourDefaults];
		[self pageRecolour];
		if ([[SMLDefaults valueForKey:MGSFragariaPrefsHighlightCurrentLine] boolValue] == YES) {
			NSRange range = [[self completeString] lineRangeForRange:[[document valueForKey:ro_MGSFOTextView] selectedRange]];
			[self highlightLineRange:range];
			lastLineHighlightRange = range;
		} else {
			[self highlightLineRange:NSMakeRange(0, 0)];
		}
	} else if ([(__bridge NSString *)context isEqualToString:@"MultiLineChanged"]) {
        [self removeAllColours];
		[self pageRecolour];
	} else if ([(__bridge NSString *)context isEqualToString:@"syntaxDefinition"]) {
		[self applySyntaxDefinition];
		[self removeAllColours];
		[self pageRecolour];
	} else if ([(__bridge NSString*)context isEqualToString:@"LineWrapChanged"]) {
        [self pageRecolour];
    } else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
	
}


/*
 
 - dealloc
 
 */
-(void)dealloc
{
    [document removeObserver:self forKeyPath:@"syntaxDefinition"];
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
}


#pragma mark -
#pragma mark Syntax definition handling
/*
 
 - applySyntaxDefinition
 
 */
- (void)applySyntaxDefinition
{			
	// parse
    syntaxDefinition = [[MGSSyntaxDefinition alloc] initFromSyntaxDictionary:self.syntaxDictionary];
}

/*
 
 - syntaxDictionary
 
 */
- (NSDictionary *)syntaxDictionary
{
	NSString *definitionName = [document valueForKey:MGSFOSyntaxDefinitionName];
	
	// if document has no syntax definition name then assign one
	if (!definitionName || [definitionName length] == 0) {
		definitionName = [self assignSyntaxDefinition];
	}
	
	// get syntax dictionary
	NSDictionary *syntaxDictionary = [[MGSSyntaxController sharedInstance] syntaxDictionaryWithName:definitionName];
    
    return syntaxDictionary;
}

/*
 
 - assignSyntaxDefinition
 
 */
- (NSString *)assignSyntaxDefinition
{
	NSString *definitionName = [document valueForKey:MGSFOSyntaxDefinitionName];
	if (definitionName && [definitionName length] > 0) return definitionName;

	NSString *documentExtension = [[document valueForKey:MGSFODocumentName] pathExtension];
	
    NSString *lowercaseExtension = nil;
    
    // If there is no extension try to guess definition from first line
    if ([documentExtension isEqualToString:@""]) { 
        
        NSString *string = [[[document valueForKey:ro_MGSFOScrollView] documentView] string];
        NSString *firstLine = [string substringWithRange:[string lineRangeForRange:NSMakeRange(0,0)]];
        if ([firstLine hasPrefix:@"#!"] || [firstLine hasPrefix:@"%"] || [firstLine hasPrefix:@"<?"]) {
            lowercaseExtension = [[MGSSyntaxController sharedInstance] guessSyntaxDefinitionExtensionFromFirstLine:firstLine];
        } 
    } else {
        lowercaseExtension = [documentExtension lowercaseString];
    }
    
    if (lowercaseExtension) {
        definitionName = [[MGSSyntaxController sharedInstance] syntaxDefinitionNameWithExtension:lowercaseExtension];
    }
	
	if (!definitionName || [definitionName length] == 0) {
		definitionName = [MGSSyntaxController standardSyntaxDefinitionName];
	}
	
	// update document definition
	[document setValue:definitionName forKey:MGSFOSyntaxDefinitionName];
	
	return definitionName;
}


#pragma mark -
#pragma mark Accessors

/*
 
 - completeString
 
 */
- (NSString *)completeString
{
	return [[document valueForKey:ro_MGSFOTextView] string];
}

#pragma mark -
#pragma mark Colouring

/*
 
 - removeAllColours
 
 */
- (void)removeAllColours
{
	NSRange wholeRange = NSMakeRange(0, [[self completeString] length]);
	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:wholeRange];
    syntaxColouringCleanRange = NSMakeRange(0, 0);
}

/*
 
 - removeColoursFromRange
 
 */
- (void)removeColoursFromRange:(NSRange)range
{
	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
    /* We could make more complex computations but this method is not called often enough to warrant them. This is easier and always correct, though slower. */
    syntaxColouringCleanRange = NSMakeRange(0, 0);
}

/*
 
 - pageRecolour
 
 */
- (void)pageRecolour
{
	[self pageRecolourTextView:[document valueForKey:ro_MGSFOTextView]];
}


/*
 
 - pageRecolourTextView:
 
 */
- (void)pageRecolourTextView:(SMLTextView *)textView
{
    [self pageRecolourTextView:textView textDidChange:NO];
}


- (void)pageRecolourTextView:(SMLTextView *)textView textDidChange:(BOOL)tdc
{
	if (!self.isSyntaxColouringRequired) {
		return;
	}
	if (textView == nil) {
		return;
	}
    
    BOOL colouringIsNotLineBased = (![[SMLDefaults valueForKey:MGSFragariaPrefsOnlyColourTillTheEndOfLine] boolValue]) | [[SMLDefaults valueForKey:MGSFragariaPrefsColourMultiLineStrings] boolValue];
    
	NSRect visibleRect = [[[textView enclosingScrollView] contentView] documentVisibleRect];
	NSRange visibleRange = [[textView layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[textView textContainer]];
	NSInteger beginningOfFirstVisibleLine = [[textView string] lineRangeForRange:NSMakeRange(visibleRange.location, 0)].location;
	NSInteger endOfLastVisibleLine = NSMaxRange([[self completeString] lineRangeForRange:NSMakeRange(NSMaxRange(visibleRange), 0)]);
	
    NSRange pageRange = NSMakeRange(beginningOfFirstVisibleLine, endOfLastVisibleLine - beginningOfFirstVisibleLine);
    NSRange newCleanRange = NSUnionRange(pageRange, syntaxColouringCleanRange);
    NSRange effectiveRange = NSMakeRange(0,0);
    if (!tdc) {
        NSRange colourRange = newCleanRange;
        colourRange.length -= syntaxColouringCleanRange.length;
        if (colourRange.location >= syntaxColouringCleanRange.location)
            colourRange.location += syntaxColouringCleanRange.length;
        if (colourRange.length) {
            //NSLog(@"Recolouring range: %@", NSStringFromRange(colourRange));
            effectiveRange = [self recolourRange:colourRange];
        }
    } else {
        //NSLog(@"Recolouring page");
        effectiveRange = [self recolourRange:pageRange];
        if (colouringIsNotLineBased) {
            newCleanRange.length = NSMaxRange(pageRange) - newCleanRange.location;
        }
    }
    syntaxColouringCleanRange = NSUnionRange(newCleanRange, effectiveRange);
}

/*
 
 - pageRecolourTextView:options:
 
 */
- (void)pageRecolourTextView:(SMLTextView *)textView options:(NSDictionary *)options
{
	if (!textView) {
		return;
	}

	if (!self.isSyntaxColouringRequired) {
		return;
	}
	
	// colourAll option
	NSNumber *colourAll = [options objectForKey:@"colourAll"];
	if (!colourAll || ![colourAll boolValue]) {
        NSNumber *visibleTextDidChange = [options objectForKey:@"visibleTextDidChange"];
        if (visibleTextDidChange && [visibleTextDidChange boolValue]) {
            [self pageRecolourTextView:textView textDidChange:YES];
        } else
            [self pageRecolourTextView:textView];
    } else {
        syntaxColouringCleanRange = NSMakeRange(0,0);
        [self recolourRange:NSMakeRange(0, [[textView string] length])];
    }
}

/*
 
 - recolourRange:
 
 */
- (NSRange)recolourRange:(NSRange)rangeToRecolour
{
	if (reactToChanges == NO) {
		return NSMakeRange(0,0);
	}

    // establish behavior
	BOOL shouldOnlyColourTillTheEndOfLine = [[SMLDefaults valueForKey:MGSFragariaPrefsOnlyColourTillTheEndOfLine] boolValue];
	BOOL shouldColourMultiLineStrings = [[SMLDefaults valueForKey:MGSFragariaPrefsColourMultiLineStrings] boolValue];
    	
    // setup
    NSString *documentString = [self completeString];
    NSUInteger documentStringLength = [documentString length];
	NSRange effectiveRange = rangeToRecolour;
	NSRange rangeOfLine = NSMakeRange(0, 0);
	NSRange foundRange = NSMakeRange(0, 0);
	NSRange searchRange = NSMakeRange(0, 0);
	NSUInteger searchSyntaxLength = 0;
	NSUInteger colourStartLocation = 0, colourEndLocation = 0, endOfLine = 0;
    NSUInteger colourLength = 0;
	NSUInteger endLocationInMultiLine = 0;
	NSUInteger beginLocationInMultiLine = 0;
	NSUInteger queryLocation = 0;
    unichar testCharacter = 0;
    
    // trace
    //NSLog(@"rangeToRecolor location %i length %i", rangeToRecolour.location, rangeToRecolour.length);
    
    // adjust effective range
    //
    // When multiline strings are coloured we need to scan backwards to
    // find where the string might have started if it's "above" the top of the screen,
    // or we need to scan forwards to find where a multiline string which wraps off
    // the range ends.
    //
    // This is not always correct but it's better than nothing.
    //
	if (shouldColourMultiLineStrings) {
		NSInteger beginFirstStringInMultiLine = [documentString rangeOfString:syntaxDefinition.firstString options:NSBackwardsSearch range:NSMakeRange(0, effectiveRange.location)].location;
        if (beginFirstStringInMultiLine != NSNotFound && [[layoutManager temporaryAttributesAtCharacterIndex:beginFirstStringInMultiLine effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
			NSInteger startOfLine = [documentString lineRangeForRange:NSMakeRange(beginFirstStringInMultiLine, 0)].location;
			effectiveRange = NSMakeRange(startOfLine, rangeToRecolour.length + (rangeToRecolour.location - startOfLine));
		}
        
        
        NSInteger lastStringBegin = [documentString rangeOfString:syntaxDefinition.firstString options:NSBackwardsSearch range:rangeToRecolour].location;
        if (lastStringBegin != NSNotFound) {
            NSRange restOfString = NSMakeRange(NSMaxRange(rangeToRecolour), 0);
            restOfString.length = [documentString length] - restOfString.location;
            NSInteger lastStringEnd = [documentString rangeOfString:syntaxDefinition.firstString options:0 range:restOfString].location;
            if (lastStringEnd != NSNotFound) {
                NSInteger endOfLine = NSMaxRange([documentString lineRangeForRange:NSMakeRange(lastStringEnd, 0)]);
                effectiveRange = NSUnionRange(effectiveRange, NSMakeRange(lastStringBegin, endOfLine-lastStringBegin));
            }
        }
	}
	
    // setup working locations based on the effective range
	NSUInteger rangeLocation = effectiveRange.location;
	NSUInteger maxRangeLocation = NSMaxRange(effectiveRange);
    
    // assign range string
	NSString *rangeString = [documentString substringWithRange:effectiveRange];
	NSUInteger rangeStringLength = [rangeString length];
	if (rangeStringLength == 0) {
		return effectiveRange;
	}
    
    // allocate the range scanner
	NSScanner *rangeScanner = [[NSScanner alloc] initWithString:rangeString];
	[rangeScanner setCharactersToBeSkipped:nil];
    
    // allocate the document scanner
	NSScanner *documentScanner = [[NSScanner alloc] initWithString:documentString];
	[documentScanner setCharactersToBeSkipped:nil];
	
    // uncolour the range
	[self removeColoursFromRange:effectiveRange];
	
    // colouring delegate
    id colouringDelegate = [document valueForKey:MGSFOSyntaxColouringDelegate];
    BOOL delegateRespondsToShouldColourGroup = [colouringDelegate respondsToSelector:@selector(fragariaDocument:shouldColourGroupWithBlock:string:range:info:)];
    BOOL delegateRespondsToDidColourGroup = [colouringDelegate respondsToSelector:@selector(fragariaDocument:didColourGroupWithBlock:string:range:info:)];
    NSDictionary *delegateInfo =  nil;
	
    // define a block that the colour delegate can use to effect colouring
    BOOL (^colourRangeBlock)(NSDictionary *, NSRange) = ^(NSDictionary *colourInfo, NSRange range) {
        [self setColour:colourInfo range:range];
        
        // at the moment we always succeed
        return YES;
    };
    
    @try {
		
        BOOL doColouring = YES;
        
        //
        // query delegate about colouring the document
        //
        if ([colouringDelegate respondsToSelector:@selector(fragariaDocument:shouldColourWithBlock:string:range:info:)]) {
            
            // build minimal delegate info dictionary
            delegateInfo = @{SMLSyntaxInfo : self.syntaxDictionary, SMLSyntaxWillColour : @(self.isSyntaxColouringRequired)};
            
            // query delegate about colouring
            doColouring = [colouringDelegate fragariaDocument:document shouldColourWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
            
        }
        
        if (doColouring) {
            //
            // Numbers
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourNumbers] boolValue];
           
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupNumber, SMLSyntaxGroupID : @(kSMLSyntaxGroupNumber), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : numbersColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            } 
            
            // do colouring
            if (doColouring) {
                
                // reset scanner
                [rangeScanner mgs_setScanLocation:0];

                // scan range to end
                while (![rangeScanner isAtEnd]) {
                    
                    // scan up to a number character
                    [rangeScanner scanUpToCharactersFromSet:syntaxDefinition.numberCharacterSet intoString:NULL];
                    colourStartLocation = [rangeScanner scanLocation];
                    
                    // scan to number end
                    [rangeScanner scanCharactersFromSet:syntaxDefinition.numberCharacterSet intoString:NULL];
                    colourEndLocation = [rangeScanner scanLocation];
                    
                    if (colourStartLocation == colourEndLocation) {
                        break;
                    }
                    
                    // don't colour if preceding character is a letter.
                    // this prevents us from colouring numbers in variable names,
                    queryLocation = colourStartLocation + rangeLocation;
                    if (queryLocation > 0) {
                        testCharacter = [documentString characterAtIndex:queryLocation - 1];
                        
                        // numbers can occur in variable, class and function names
                        // eg: var_1 should not be coloured as a number
                        if ([syntaxDefinition.nameCharacterSet characterIsMember:testCharacter]) {
                            continue;
                        }
                    }

                    // TODO: handle constructs such as 1..5 which may occur within some loop constructs
                    
                    // don't colour a trailing decimal point as some languages may use it as a line terminator
                    if (colourEndLocation > 0) {
                        queryLocation = colourEndLocation - 1;
                        testCharacter = [rangeString characterAtIndex:queryLocation];
                        if (testCharacter == syntaxDefinition.decimalPointCharacter) {
                            colourEndLocation--;
                        }
                    }

                    [self setColour:numbersColour range:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
                }
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                } 
            }


            //
            // Commands
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourCommands] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupCommand, SMLSyntaxGroupID : @(kSMLSyntaxGroupCommand), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : commandsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            } 

            if (doColouring && ![syntaxDefinition.beginCommand isEqualToString:@""]) {
                searchSyntaxLength = [syntaxDefinition.endCommand length];
                unichar beginCommandCharacter = [syntaxDefinition.beginCommand characterAtIndex:0];
                unichar endCommandCharacter = [syntaxDefinition.endCommand characterAtIndex:0];
                
                // reset scanner
                [rangeScanner mgs_setScanLocation:0];

                // scan range to end
                while (![rangeScanner isAtEnd]) {
                    [rangeScanner scanUpToString:syntaxDefinition.beginCommand intoString:nil];
                    colourStartLocation = [rangeScanner scanLocation];
                    endOfLine = NSMaxRange([rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)]);
                    if (![rangeScanner scanUpToString:syntaxDefinition.endCommand intoString:nil] || [rangeScanner scanLocation] >= endOfLine) {
                        [rangeScanner mgs_setScanLocation:endOfLine];
                        continue; // Don't colour it if it hasn't got a closing tag
                    } else {
                        // To avoid problems with strings like <yada <%=yada%> yada> we need to balance the number of begin- and end-tags
                        // If ever there's a beginCommand or endCommand with more than one character then do a check first
                        NSUInteger commandLocation = colourStartLocation + 1;
                        NSUInteger skipEndCommand = 0;
                        
                        while (commandLocation < endOfLine) {
                            unichar commandCharacterTest = [rangeString characterAtIndex:commandLocation];
                            if (commandCharacterTest == endCommandCharacter) {
                                if (!skipEndCommand) {
                                    break;
                                } else {
                                    skipEndCommand--;
                                }
                            }
                            if (commandCharacterTest == beginCommandCharacter) {
                                skipEndCommand++;
                            }
                            commandLocation++;
                        }
                        if (commandLocation < endOfLine) {
                            [rangeScanner mgs_setScanLocation:commandLocation + searchSyntaxLength];
                        } else {
                            [rangeScanner mgs_setScanLocation:endOfLine];
                        }
                    }
                    
                    [self setColour:commandsColour range:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
                }

                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }
            


            //
            // Instructions
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourInstructions] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupInstruction, SMLSyntaxGroupID : @(kSMLSyntaxGroupInstruction), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : instructionsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }

            if (doColouring && ![syntaxDefinition.beginInstruction isEqualToString:@""]) {
                // It takes too long to scan the whole document if it's large, so for instructions, first multi-line comment and second multi-line comment search backwards and begin at the start of the first beginInstruction etc. that it finds from the present position and, below, break the loop if it has passed the scanned range (i.e. after the end instruction)
                
                beginLocationInMultiLine = [documentString rangeOfString:syntaxDefinition.beginInstruction options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
                endLocationInMultiLine = [documentString rangeOfString:syntaxDefinition.endInstruction options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
                if (beginLocationInMultiLine == NSNotFound || (endLocationInMultiLine != NSNotFound && beginLocationInMultiLine < endLocationInMultiLine)) {
                    beginLocationInMultiLine = rangeLocation;
                }			

                searchSyntaxLength = [syntaxDefinition.endInstruction length];

                // reset scanner
                [documentScanner mgs_setScanLocation:0];

                // scan document to end
                while (![documentScanner isAtEnd]) {
                    searchRange = NSMakeRange(beginLocationInMultiLine, rangeToRecolour.length);
                    if (NSMaxRange(searchRange) > documentStringLength) {
                        searchRange = NSMakeRange(beginLocationInMultiLine, documentStringLength - beginLocationInMultiLine);
                    }
                    
                    colourStartLocation = [documentString rangeOfString:syntaxDefinition.beginInstruction options:NSLiteralSearch range:searchRange].location;
                    if (colourStartLocation == NSNotFound) {
                        break;
                    }
                    [documentScanner mgs_setScanLocation:colourStartLocation];
                    if (![documentScanner scanUpToString:syntaxDefinition.endInstruction intoString:nil] || [documentScanner scanLocation] >= documentStringLength) {
                        if (shouldOnlyColourTillTheEndOfLine) {
                            [documentScanner mgs_setScanLocation:NSMaxRange([documentString lineRangeForRange:NSMakeRange(colourStartLocation, 0)])];
                        } else {
                            [documentScanner mgs_setScanLocation:documentStringLength];
                        }
                    } else {
                        if ([documentScanner scanLocation] + searchSyntaxLength <= documentStringLength) {
                            [documentScanner mgs_setScanLocation:[documentScanner scanLocation] + searchSyntaxLength];
                        }
                    }
                    
                    [self setColour:instructionsColour range:NSMakeRange(colourStartLocation, [documentScanner scanLocation] - colourStartLocation)];
                    if ([documentScanner scanLocation] > maxRangeLocation) {
                        break;
                    }
                    beginLocationInMultiLine = [documentScanner scanLocation];
                }

                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }


            //
            // Keywords
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourKeywords] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupKeyword, SMLSyntaxGroupID : @(kSMLSyntaxGroupKeyword), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : keywordsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }
            
            if (doColouring && [syntaxDefinition.keywords count] > 0) {
                
                // reset scanner
                [rangeScanner mgs_setScanLocation:0];
                
                // scan range to end
                while (![rangeScanner isAtEnd]) {
                    [rangeScanner scanUpToCharactersFromSet:syntaxDefinition.keywordStartCharacterSet intoString:nil];
                    colourStartLocation = [rangeScanner scanLocation];
                    if ((colourStartLocation + 1) < rangeStringLength) {
                        [rangeScanner mgs_setScanLocation:(colourStartLocation + 1)];
                    }
                    [rangeScanner scanUpToCharactersFromSet:syntaxDefinition.keywordEndCharacterSet intoString:nil];
                    
                    colourEndLocation = [rangeScanner scanLocation];
                    if (colourEndLocation > rangeStringLength || colourStartLocation == colourEndLocation) {
                        break;
                    }
                    
                    NSString *keywordTestString = nil;
                    if (!syntaxDefinition.keywordsCaseSensitive) {
                        keywordTestString = [[documentString substringWithRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)] lowercaseString];
                    } else {
                        keywordTestString = [documentString substringWithRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
                    }
                    if ([syntaxDefinition.keywords containsObject:keywordTestString]) {
                        if (!syntaxDefinition.recolourKeywordIfAlreadyColoured) {
                            if ([[layoutManager temporaryAttributesAtCharacterIndex:colourStartLocation + rangeLocation effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
                                continue;
                            }
                        }	
                        [self setColour:keywordsColour range:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
                    }
                }
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }


            //
            // Autocomplete
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourAutocomplete] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupAutoComplete, SMLSyntaxGroupID : @(kSMLSyntaxGroupAutoComplete), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : autocompleteWordsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }
            
            if (doColouring && [syntaxDefinition.autocompleteWords count] > 0) {
                
                // reset scanner
                [rangeScanner mgs_setScanLocation:0];
                
                // scan range to end
                while (![rangeScanner isAtEnd]) {
                    [rangeScanner scanUpToCharactersFromSet:syntaxDefinition.keywordStartCharacterSet intoString:nil];
                    colourStartLocation = [rangeScanner scanLocation];
                    if ((colourStartLocation + 1) < rangeStringLength) {
                        [rangeScanner mgs_setScanLocation:(colourStartLocation + 1)];
                    }
                    [rangeScanner scanUpToCharactersFromSet:syntaxDefinition.keywordEndCharacterSet intoString:nil];
                    
                    colourEndLocation = [rangeScanner scanLocation];
                    if (colourEndLocation > rangeStringLength || colourStartLocation == colourEndLocation) {
                        break;
                    }
                    
                    NSString *autocompleteTestString = nil;
                    if (!syntaxDefinition.keywordsCaseSensitive) {
                        autocompleteTestString = [[documentString substringWithRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)] lowercaseString];
                    } else {
                        autocompleteTestString = [documentString substringWithRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
                    }
                    if ([syntaxDefinition.autocompleteWords containsObject:autocompleteTestString]) {
                        if (!syntaxDefinition.recolourKeywordIfAlreadyColoured) {
                            if ([[layoutManager temporaryAttributesAtCharacterIndex:colourStartLocation + rangeLocation effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
                                continue;
                            }
                        }	
                        
                        [self setColour:autocompleteWordsColour range:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
                    }
                }
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }
            

            //
            // Variables
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourVariables] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupVariable, SMLSyntaxGroupID : @(kSMLSyntaxGroupVariable), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : variablesColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }
            
            if (doColouring && syntaxDefinition.beginVariableCharacterSet != nil) {
                
                // reset scanner
                [rangeScanner mgs_setScanLocation:0];
                
                // scan range to end
                while (![rangeScanner isAtEnd]) {
                    [rangeScanner scanUpToCharactersFromSet:syntaxDefinition.beginVariableCharacterSet intoString:nil];
                    colourStartLocation = [rangeScanner scanLocation];
                    if (colourStartLocation + 1 < rangeStringLength) {
                        if ([syntaxDefinition.firstSingleLineComment isEqualToString:@"%"] && [rangeString characterAtIndex:colourStartLocation + 1] == '%') { // To avoid a problem in LaTex with \%
                            if ([rangeScanner scanLocation] < rangeStringLength) {
                                [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                            }
                            continue;
                        }
                    }
                    endOfLine = NSMaxRange([rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)]);
                    if (![rangeScanner scanUpToCharactersFromSet:syntaxDefinition.endVariableCharacterSet intoString:nil] || [rangeScanner scanLocation] >= endOfLine) {
                        [rangeScanner mgs_setScanLocation:endOfLine];
                        colourLength = [rangeScanner scanLocation] - colourStartLocation;
                    } else {
                        colourLength = [rangeScanner scanLocation] - colourStartLocation;
                        if ([rangeScanner scanLocation] < rangeStringLength) {
                            [rangeScanner mgs_setScanLocation:[rangeScanner scanLocation] + 1];
                        }
                    }
                    
                    [self setColour:variablesColour range:NSMakeRange(colourStartLocation + rangeLocation, colourLength)];
                }
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }


            //
            // Second string, first pass
            //

            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourStrings] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupSecondString, SMLSyntaxGroupID : @(kSMLSyntaxGroupSecondString), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : stringsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            } 

            if (doColouring && ![syntaxDefinition.secondString isEqualToString:@""]) {
                ICUPattern *stringPattern;
                
                if (!shouldColourMultiLineStrings)
                    stringPattern = [syntaxDefinition secondStringPattern];
                else
                    stringPattern = [syntaxDefinition secondMultilineStringPattern];
                
                @try {
                    secondStringMatcher = [[ICUMatcher alloc] initWithPattern:stringPattern overString:rangeString];
                }
                @catch (NSException *exception) {
                    return effectiveRange;
                }

                while ([secondStringMatcher findNext]) {
                    foundRange = [secondStringMatcher rangeOfMatch];
                    [self setColour:stringsColour range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
                }

                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }

            }


            //
            // First string
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourStrings] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupFirstString, SMLSyntaxGroupID : @(kSMLSyntaxGroupFirstString), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : stringsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }
        
            if (doColouring && ![syntaxDefinition.firstString isEqualToString:@""]) {
                ICUPattern *stringPattern;
                
                if (!shouldColourMultiLineStrings)
                    stringPattern = [syntaxDefinition firstStringPattern];
                else
                    stringPattern = [syntaxDefinition firstMultilineStringPattern];
                
                @try {
                    firstStringMatcher = [[ICUMatcher alloc] initWithPattern:stringPattern overString:rangeString];
                }
                @catch (NSException *exception) {
                    return effectiveRange;
                }
                
                while ([firstStringMatcher findNext]) {
                    foundRange = [firstStringMatcher rangeOfMatch];
                    if ([[layoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                        continue;
                    }
                    [self setColour:stringsColour range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
                }

                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            
            }


            //
            // Attributes
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourAttributes] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupAttribute, SMLSyntaxGroupID : @(kSMLSyntaxGroupAttribute), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : attributesColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            } 

            if (doColouring) {
                
                // reset scanner
                [rangeScanner mgs_setScanLocation:0];
                
                // scan range to end
                while (![rangeScanner isAtEnd]) {
                    [rangeScanner scanUpToString:@" " intoString:nil];
                    colourStartLocation = [rangeScanner scanLocation];
                    if (colourStartLocation + 1 < rangeStringLength) {
                        [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                    } else {
                        break;
                    }
                    if (![[layoutManager temporaryAttributesAtCharacterIndex:(colourStartLocation + rangeLocation) effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
                        continue;
                    }
                    
                    [rangeScanner scanCharactersFromSet:syntaxDefinition.attributesCharacterSet intoString:nil];
                    colourEndLocation = [rangeScanner scanLocation];
                    
                    if (colourEndLocation + 1 < rangeStringLength) {
                        [rangeScanner mgs_setScanLocation:[rangeScanner scanLocation] + 1];
                    }
                    
                    if ([documentString characterAtIndex:colourEndLocation + rangeLocation] == '=') {
                        [self setColour:attributesColour range:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
                    }
                }

                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }

            }
            

            //
            // Colour single-line comments
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourComments] boolValue];
            
            // initial delegate group colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupSingleLineComment, SMLSyntaxGroupID : @(kSMLSyntaxGroupSingleLineComment), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : commentsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            } 

            if (doColouring) {
                for (NSString *singleLineComment in syntaxDefinition.singleLineComments) {
                    if (![singleLineComment isEqualToString:@""]) {
                        
                        // reset scanner
                        [rangeScanner mgs_setScanLocation:0];
                        searchSyntaxLength = [singleLineComment length];
                        
                        // scan range to end
                        while (![rangeScanner isAtEnd]) {
                            
                            // scan for comment
                            [rangeScanner scanUpToString:singleLineComment intoString:nil];
                            colourStartLocation = [rangeScanner scanLocation];
                            
                            // common case handling
                            if ([singleLineComment isEqualToString:@"//"]) {
                                if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == ':') {
                                    [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                                    continue; // To avoid http:// ftp:// file:// etc.
                                }
                            } else if ([singleLineComment isEqualToString:@"#"]) {
                                if (rangeStringLength > 1) {
                                    rangeOfLine = [rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)];
                                    if ([rangeString rangeOfString:@"#!" options:NSLiteralSearch range:rangeOfLine].location != NSNotFound) {
                                        [rangeScanner mgs_setScanLocation:NSMaxRange(rangeOfLine)];
                                        continue; // Don't treat the line as a comment if it begins with #!
                                    } else if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == '$') {
                                        [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                                        continue; // To avoid $#
                                    } else if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == '&') {
                                        [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                                        continue; // To avoid &#
                                    }
                                }
                            } else if ([singleLineComment isEqualToString:@"%"]) {
                                if (rangeStringLength > 1) {
                                    if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == '\\') {
                                        [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                                        continue; // To avoid \% in LaTex
                                    }
                                }
                            } 
                            
                            // If the comment is within an already coloured string then disregard it
                            if (colourStartLocation + rangeLocation + searchSyntaxLength < documentStringLength) {
                                if ([[layoutManager temporaryAttributesAtCharacterIndex:colourStartLocation + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                                    [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                                    continue; 
                                }
                            }
                            
                            // this is a single line comment so we can scan to the end of the line
                            endOfLine = NSMaxRange([rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)]);
                            [rangeScanner mgs_setScanLocation:endOfLine];
                            
                            // colour the comment
                            [self setColour:commentsColour range:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
                        }
                    }
                } // end for
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }
            

            //
            // Multi-line comments
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourComments] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupMultiLineComment, SMLSyntaxGroupID : @(kSMLSyntaxGroupMultiLineComment), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : commentsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }
        
            if (doColouring) {
                for (NSArray *multiLineComment in syntaxDefinition.multiLineComments) {
                    
                    // Get strings
                    NSString *beginMultiLineComment = [multiLineComment objectAtIndex:0];
                    NSString *endMultiLineComment = [multiLineComment objectAtIndex:1];
                    
                    if (![beginMultiLineComment isEqualToString:@""]) {
                        
                        // Default to start of document
                        beginLocationInMultiLine = 0;
                        
                        // If start and end comment markers are the the same we
                        // always start searching at the beginning of the document.
                        // Otherwise we must consider that our start location may be mid way through
                        // a multiline comment.
                        if (![beginMultiLineComment isEqualToString:endMultiLineComment]) {
                            
                            // Search backwards from range location looking for comment start
                            beginLocationInMultiLine = [documentString rangeOfString:beginMultiLineComment options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
                            endLocationInMultiLine = [documentString rangeOfString:endMultiLineComment options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
                            
                            // If comments not found then begin at range location
                            if (beginLocationInMultiLine == NSNotFound || (endLocationInMultiLine != NSNotFound && beginLocationInMultiLine < endLocationInMultiLine)) {
                                beginLocationInMultiLine = rangeLocation;
                            }
                        }
                        
                        [documentScanner mgs_setScanLocation:beginLocationInMultiLine];
                        searchSyntaxLength = [endMultiLineComment length];
                        
                        // Iterate over the document until we exceed our work range
                        while (![documentScanner isAtEnd]) {
                            
                            // Search up to document end
                            searchRange = NSMakeRange(beginLocationInMultiLine, documentStringLength - beginLocationInMultiLine);
                            
                            // Look for comment start in document
                            colourStartLocation = [documentString rangeOfString:beginMultiLineComment options:NSLiteralSearch range:searchRange].location;
                            if (colourStartLocation == NSNotFound) {
                                break;
                            }
                            
                            // Increment our location.
                            // This is necessary to cover situations, such as F-Script, where the start and end comment strings are identical
                            if (colourStartLocation + 1 < documentStringLength) {
                                [documentScanner mgs_setScanLocation:colourStartLocation + 1];
                                
                                // If the comment is within a string disregard it
                                if ([[layoutManager temporaryAttributesAtCharacterIndex:colourStartLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                                    beginLocationInMultiLine++;
                                    continue; 
                                }
                            } else {
                                [documentScanner mgs_setScanLocation:colourStartLocation];
                            }
                            
                            // Scan up to comment end
                            if (![documentScanner scanUpToString:endMultiLineComment intoString:nil] || [documentScanner scanLocation] >= documentStringLength) {
                                
                                // Comment end not found
                                if (shouldOnlyColourTillTheEndOfLine) {
                                    [documentScanner mgs_setScanLocation:NSMaxRange([documentString lineRangeForRange:NSMakeRange(colourStartLocation, 0)])];
                                } else {
                                    [documentScanner mgs_setScanLocation:documentStringLength];
                                }
                                colourLength = [documentScanner scanLocation] - colourStartLocation;
                            } else {
                                
                                // Comment end found
                                if ([documentScanner scanLocation] < documentStringLength) {
                                    
                                    // Safely advance scanner
                                    [documentScanner mgs_setScanLocation:[documentScanner scanLocation] + searchSyntaxLength];
                                }
                                colourLength = [documentScanner scanLocation] - colourStartLocation;
                                
                                // HTML specific
                                if ([endMultiLineComment isEqualToString:@"-->"]) {
                                    [documentScanner scanUpToCharactersFromSet:syntaxDefinition.letterCharacterSet intoString:nil]; // Search for the first letter after -->
                                    if ([documentScanner scanLocation] + 6 < documentStringLength) {// Check if there's actually room for a </script>
                                        if ([documentString rangeOfString:@"</script>" options:NSCaseInsensitiveSearch range:NSMakeRange([documentScanner scanLocation] - 2, 9)].location != NSNotFound || [documentString rangeOfString:@"</style>" options:NSCaseInsensitiveSearch range:NSMakeRange([documentScanner scanLocation] - 2, 8)].location != NSNotFound) {
                                            beginLocationInMultiLine = [documentScanner scanLocation];
                                            continue; // If the comment --> is followed by </script> or </style> it is probably not a real comment
                                        }
                                    }
                                    [documentScanner mgs_setScanLocation:colourStartLocation + colourLength]; // Reset the scanner position
                                }
                            }

                            // Colour the range
                            [self setColour:commentsColour range:NSMakeRange(colourStartLocation, colourLength)];

                            // We may be done
                            if ([documentScanner scanLocation] > maxRangeLocation) {
                                break;
                            }
                            
                            // set start location for next search
                            beginLocationInMultiLine = [documentScanner scanLocation];
                        }
                    }
                } // end for
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
                
           }
        
            //
            // Second string, second pass
            //
            doColouring = [[SMLDefaults valueForKey:MGSFragariaPrefsColourStrings] boolValue];
            
            // query delegate about colouring
            if (delegateRespondsToShouldColourGroup) {
                
                // build delegate info dictionary
                delegateInfo = @{SMLSyntaxGroup : SMLSyntaxGroupSecondStringPass2, SMLSyntaxGroupID : @(kSMLSyntaxGroupSecondStringPass2), SMLSyntaxWillColour : @(doColouring), SMLSyntaxAttributes : stringsColour, SMLSyntaxInfo : self.syntaxDictionary};
                
                // call the delegate
                doColouring = [colouringDelegate fragariaDocument:document shouldColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
                
            }
        
            if (doColouring && ![syntaxDefinition.secondString isEqualToString:@""]) {
                
                @try {
                    [secondStringMatcher reset];
                }
                @catch (NSException *exception) {
                    return effectiveRange;
                }
                
                while ([secondStringMatcher findNext]) {
                    foundRange = [secondStringMatcher rangeOfMatch];
                    if ([[layoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour] || [[layoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:commentsColour]) {
                        continue;
                    }
                    [self setColour:stringsColour range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
                }
                
                // inform delegate that colouring is done
                if (delegateRespondsToDidColourGroup) {
                    [colouringDelegate fragariaDocument:document didColourGroupWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo];
                }
            }


            //
            // tell delegate we are did colour the document
            //
            if ([colouringDelegate respondsToSelector:@selector(fragariaDocument:didColourWithBlock:string:range:info:)]) {
                
                // build minimal delegate info dictionary
                delegateInfo = @{@"syntaxInfo" : self.syntaxDictionary};
                
                [colouringDelegate fragariaDocument:document didColourWithBlock:colourRangeBlock string:documentString range:rangeToRecolour info:delegateInfo ];
            }

        }

    }
	@catch (NSException *exception) {
		NSLog(@"Syntax colouring exception: %@", exception);
	}

    @try {
        //
        // highlight errors
        //
        [self highlightErrors];
	}
	@catch (NSException *exception) {
		NSLog(@"Error highlighting exception: %@", exception);
	}
    return effectiveRange;
}

/*
 
 - setColour:range:
 
 */
- (void)setColour:(NSDictionary *)colourDictionary range:(NSRange)range
{
	[layoutManager setTemporaryAttributes:colourDictionary forCharacterRange:range];
}

/*
 
 - applyColourDefaults
 
 */
- (void)applyColourDefaults
{
	commandsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsCommandsColourWell]], NSForegroundColorAttributeName, nil];
	
	commentsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsCommentsColourWell]], NSForegroundColorAttributeName, nil];
	
	instructionsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsInstructionsColourWell]], NSForegroundColorAttributeName, nil];
	
	keywordsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsKeywordsColourWell]], NSForegroundColorAttributeName, nil];
	
	autocompleteWordsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsAutocompleteColourWell]], NSForegroundColorAttributeName, nil];
	
	stringsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsStringsColourWell]], NSForegroundColorAttributeName, nil];
	
	variablesColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsVariablesColourWell]], NSForegroundColorAttributeName, nil];
	
	attributesColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsAttributesColourWell]], NSForegroundColorAttributeName, nil];
	
	lineHighlightColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsHighlightLineColourWell]], NSBackgroundColorAttributeName, nil];

	numbersColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:MGSFragariaPrefsNumbersColourWell]], NSForegroundColorAttributeName, nil];

}

/*
 
 - isSyntaxColouringRequired
 
 */
- (BOOL)isSyntaxColouringRequired
{
    return ([[document valueForKey:MGSFOIsSyntaxColoured] boolValue] && syntaxDefinition.syntaxDefinitionAllowsColouring ? YES : NO);
}
/*
 
 - highlightLineRange:
 
 */
- (void)highlightLineRange:(NSRange)lineRange
{
	if (lineRange.location == lastLineHighlightRange.location && lineRange.length == lastLineHighlightRange.length) {
		return;
	}
	
	[layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:lastLineHighlightRange];
		
	[self pageRecolour];
	
	[layoutManager addTemporaryAttributes:lineHighlightColour forCharacterRange:lineRange];
	
	lastLineHighlightRange = lineRange;
}

/*
 
 - characterIndexFromLine:character:inString:
 
 */
- (NSInteger) characterIndexFromLine:(int)line character:(int)character inString:(NSString*) str
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    
    int currentLine = 1;
    while (![scanner isAtEnd])
    {
        if (currentLine == line)
        {
            // Found the right line
            NSInteger location = [scanner scanLocation] + character-1;
            if (location >= (NSInteger)str.length) location = str.length - 1;
            return location;
        }
        
        // Scan to a new line
        [scanner scanUpToString:@"\n" intoString:NULL];
        
        if (![scanner isAtEnd])
        {
            scanner.scanLocation += 1;
        }
        currentLine++;
    }
    
    return -1;
}

/*
 
 - highlightErrors
 
 */
- (void)highlightErrors
{
    SMLTextView* textView = [document valueForKey:ro_MGSFOTextView];
    NSString* text = [self completeString];
    
    // Clear all highlights
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, text.length)];
    
    // Clear all buttons
    NSMutableArray* buttons = [NSMutableArray array];
    for (NSView* subview in [textView subviews])
    {
        if ([subview isKindOfClass:[NSButton class]])
        {
            [buttons addObject:subview];
        }
    }
    for (NSButton* button in buttons)
    {
        [button removeFromSuperview];
    }
    
    if (!syntaxErrors) return;
    
    // Highlight all errors and add buttons
    NSMutableSet* highlightedRows = [NSMutableSet set];

    for (SMLSyntaxError* err in syntaxErrors)
    {
        // Highlight an erronous line
        NSInteger location = [self characterIndexFromLine:err.line character:err.character inString:text];
        
        // Skip lines we cannot identify in the text
        if (location == -1) continue;
        
        NSRange lineRange = [text lineRangeForRange:NSMakeRange(location, 0)];
     
        // Highlight row if it is not already highlighted
        if (![highlightedRows containsObject:[NSNumber numberWithInt:err.line]])
        {
            // Remember that we are highlighting this row
            [highlightedRows addObject:[NSNumber numberWithInt:err.line]];
            
            // Add highlight for background
            if (!err.customBackgroundColor) {
                [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedRed:1 green:1 blue:0.7 alpha:1] forCharacterRange:lineRange];
            } else {
                [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:err.customBackgroundColor forCharacterRange:lineRange];
            }
            
            if ([err.description length] > 0)
                [layoutManager addTemporaryAttribute:NSToolTipAttributeName value:err.description forCharacterRange:lineRange];
            
            if (!err.hideWarning) {
                NSInteger glyphIndex = [layoutManager glyphIndexForCharacterAtIndex:lineRange.location];
                
                NSRect linePos = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:[textView textContainer]];
                
                // Add button
                NSButton* warningButton = [[NSButton alloc] init];
                
                [warningButton setButtonType:NSMomentaryChangeButton];
                [warningButton setBezelStyle:NSRegularSquareBezelStyle];
                [warningButton setBordered:NO];
                [warningButton setImagePosition:NSImageOnly];
                [warningButton setImage:[MGSFragaria imageNamed:@"editor-warning.png"]];
                [warningButton setTag:err.line];
                [warningButton setTarget:self];
                [warningButton setAction:@selector(pressedWarningBtn:)];
                [warningButton setTranslatesAutoresizingMaskIntoConstraints:NO];
                [textView addSubview:warningButton];
                
                [textView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[warningButton]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(warningButton)]];
                [textView addConstraint:[NSLayoutConstraint constraintWithItem:warningButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:textView attribute:NSLayoutAttributeTop multiplier:1.0 constant:linePos.origin.y-2]];
            }
        }
    }
}

/*
 
 - widthOfString:withFont:
 
 */
- (CGFloat) widthOfString:(NSString *)string withFont:(NSFont *)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

#pragma mark -
#pragma mark Actions

/*
 
 - pressedWarningBtn
 
 */
- (void) pressedWarningBtn:(id) sender
{
    int line = (int)[sender tag];
    
    // Fetch errors to display
    NSMutableArray* errorsOnLine = [NSMutableArray array];
    for (SMLSyntaxError* err in syntaxErrors)
    {
        if (err.line == line)
        {
            [errorsOnLine addObject:err.description];
        }
    }
    
    if (errorsOnLine.count == 0) return;
    
    [SMLErrorPopOver showErrorDescriptions:errorsOnLine relativeToView:sender];
}


#pragma mark -
#pragma mark Text change observation

/*
 
 - textDidChange:
 
 */
- (void)textDidChange:(NSNotification *)notification
{
	if (reactToChanges == NO) {
		return;
	}
	NSString *completeString = [self completeString];
	
	if ([completeString length] < 2) {
		// MGS[SMLInterface updateStatusBar]; // One needs to call this from here as well because otherwise it won't update the status bar if one writes one character and deletes it in an empty document, because the textViewDidChangeSelection delegate method won't be called.
	}
	
	SMLTextView *textView = (SMLTextView *)[notification object];
	
	if ([[SMLDefaults valueForKey:MGSFragariaPrefsHighlightCurrentLine] boolValue] == YES) {
		[self highlightLineRange:[completeString lineRangeForRange:[textView selectedRange]]];
	} else if ([self isSyntaxColouringRequired]) {
		[self pageRecolourTextView:textView textDidChange:YES];
	}
	
	if (autocompleteWordsTimer != nil) {
		[autocompleteWordsTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[[SMLDefaults valueForKey:MGSFragariaPrefsAutocompleteAfterDelay] floatValue]]];
	} else if ([[SMLDefaults valueForKey:MGSFragariaPrefsAutocompleteSuggestAutomatically] boolValue] == YES) {
		autocompleteWordsTimer = [NSTimer scheduledTimerWithTimeInterval:[[SMLDefaults valueForKey:MGSFragariaPrefsAutocompleteAfterDelay] floatValue] target:self selector:@selector(autocompleteWordsTimerSelector:) userInfo:textView repeats:NO];
	}
}

/*
 
 - textViewDidChangeSelection:
 
 */
- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
    if (reactToChanges == NO) {
		return;
	}
	
	NSString *completeString = [self completeString];

	NSUInteger completeStringLength = [completeString length];
	if (completeStringLength == 0) {
		return;
	}
	
	SMLTextView *textView = [aNotification object];
		
	NSRange editedRange = [textView selectedRange];
	
	if ([[SMLDefaults valueForKey:MGSFragariaPrefsHighlightCurrentLine] boolValue] == YES) {
		[self highlightLineRange:[completeString lineRangeForRange:editedRange]];
	}
	
	if ([[SMLDefaults valueForKey:MGSFragariaPrefsShowMatchingBraces] boolValue] == NO) {
		return;
	}

	
	NSUInteger cursorLocation = editedRange.location;
	NSInteger differenceBetweenLastAndPresent = cursorLocation - lastCursorLocation;
	lastCursorLocation = cursorLocation;
	if (differenceBetweenLastAndPresent != 1 && differenceBetweenLastAndPresent != -1) {
		return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
	}
	
	if (differenceBetweenLastAndPresent == 1) { // Check if the cursor has moved forward
		cursorLocation--;
	}
	
	if (cursorLocation == completeStringLength) {
		return;
	}
	
	unichar characterToCheck = [completeString characterAtIndex:cursorLocation];
	NSInteger skipMatchingBrace = 0;
	
	if (characterToCheck == ')') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '(') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ')') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == ']') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '[') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ']') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '}') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '{') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '>') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '<') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '>') {
				skipMatchingBrace++;
			}
		}
	}
}


#pragma mark -
#pragma mark NSTimer callbacks
/*
 
 - autocompleteWordsTimerSelector:
 
 */

- (void)autocompleteWordsTimerSelector:(NSTimer *)theTimer
{
	SMLTextView *textView = [theTimer userInfo];
	NSRange selectedRange = [textView selectedRange];
	NSString *completeString = [self completeString];
	NSUInteger stringLength = [completeString length];
    
	if (selectedRange.location <= stringLength && selectedRange.length == 0 && stringLength != 0) {
		if (selectedRange.location == stringLength) { // If we're at the very end of the document
			[textView complete:nil];
		} else {
			unichar characterAfterSelection = [completeString characterAtIndex:selectedRange.location];
			if ([[NSCharacterSet symbolCharacterSet] characterIsMember:characterAfterSelection] || [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:characterAfterSelection] || [[NSCharacterSet punctuationCharacterSet] characterIsMember:characterAfterSelection] || selectedRange.location == stringLength) { // Don't autocomplete if we're in the middle of a word
				[textView complete:nil];
			}
		}
	}
	
	if (autocompleteWordsTimer) {
		[autocompleteWordsTimer invalidate];
		autocompleteWordsTimer = nil;
	}
}

#pragma mark -
#pragma mark SMLAutoCompleteDelegate

/*
 
 - completions
 
 */
- (NSArray*) completions
{
    return syntaxDefinition.keywordsAndAutocompleteWords;
}


@end