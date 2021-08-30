/*===========================================================================
 PrintEventDataAsEncodedString.m
 SilversidesTests
 Copyright (c) 2019 Ken Heglund. All rights reserved.
 ===========================================================================*/

@import AppKit;

#import "PrintEventDataAsEncodedString.h"

void PrintEventDataAsEncodedString(NSEvent *event) {
	CGEventRef cgEvent = event.CGEvent;
	if (! cgEvent) {
		return;
	}
	
	NSData *nsData = (__bridge_transfer NSData *)CGEventCreateData(kCFAllocatorDefault, cgEvent);
	if (! nsData) {
		return;
	}
	
	CGFloat effectiveScrollDelta = (event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY);
	if (fabs(effectiveScrollDelta) < 20.0) {
		return;
	}
	
	NSString *string = [nsData base64EncodedStringWithOptions:0];
	
	NSLog(@"******************");
	NSLog(@"Scroll delta: %f", effectiveScrollDelta);
	NSLog(@"%@", string);
}
