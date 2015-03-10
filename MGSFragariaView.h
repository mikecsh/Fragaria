//
//  MGSFragariaView.h
//  Fragaria
//
//  File created by Jim Derry on 2015/02/07.
//
//

#import <Foundation/Foundation.h>
#import "MGSFragariaAPI.h"

@class MGSFragaria;

/**
 *  MGSFragariaView abstracts much of Fragaria's overhead into an IB-compatible view.
 *  Implements an NSView subclass that abstracts several characteristics of Fragaria,
 *  such as the use of Interface Builder to set delegates and assign key-value pairs.
 *  Also provides two-way bindable property abstractions for Fragaria's settings
 *  and methods.
 *
 *  Consult MGSFragariaAPI.h for properties and methods this class implements.
 **/
@interface MGSFragariaView : NSView <MGSFragariaAPI>

/** Provides direct access to the view's instance of MGSFragaria. */
@property (nonatomic, strong, readonly) MGSFragaria *fragaria;


@end
