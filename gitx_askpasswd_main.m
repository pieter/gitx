/*
 *  gitx_askpasswd_main.m
 *  GitX
 *
 *  Created by Uli Kusterer on 19.02.10.
 *  Copyright 2010 The Void Software. All rights reserved.
 *
 */

#include <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>

#define OKBUTTONWIDTH			100.0
#define OKBUTTONHEIGHT			24.0
#define CANCELBUTTONWIDTH		100.0
#define CANCELBUTTONHEIGHT		24.0
#define	PASSHEIGHT				22.0


@interface GAPAppDelegate : NSObject <NSApplicationDelegate>
{
	NSPanel*			mPasswordPanel;
	NSSecureTextField*	mPasswordField;
}

-(NSPanel*)		passwordPanel;

-(IBAction)	doOKButton: (id)sender;
-(IBAction)	doCancelButton: (id)sender;

@end


@implementation GAPAppDelegate

-(void)	dealloc
{
	[mPasswordPanel release];
	mPasswordPanel = nil;
	
	[mPasswordField release];
	mPasswordField = nil;

	[super dealloc];
}

-(NSPanel*)	passwordPanel
{
	if( !mPasswordPanel )
	{
		NSRect			box = NSMakeRect( 100, 100, 400, 80 );
		mPasswordPanel = [[NSPanel alloc] initWithContentRect: box
															styleMask: NSTitledWindowMask
															backing: NSBackingStoreBuffered defer: NO];
		[mPasswordPanel setHidesOnDeactivate: NO];
		[mPasswordPanel setLevel: NSFloatingWindowLevel];
		[mPasswordPanel center];
		
		box.origin = NSZeroPoint;	// Only need local coords from now on.
		
		// OK:
		NSRect		okBox = box;
		okBox.origin.x = NSMaxX( box ) -OKBUTTONWIDTH -12;
		okBox.size.width = OKBUTTONWIDTH;
		okBox.origin.y += 12;
		okBox.size.height = OKBUTTONHEIGHT;
		NSButton*	okButton = [[[NSButton alloc] initWithFrame: okBox] autorelease];
		[okButton setTarget: self];
		[okButton setAction: @selector(doOKButton:)];
		[okButton setTitle: @"OK"];
		[okButton setKeyEquivalent: @"\r"];
		[okButton setBordered: YES];
		[okButton setBezelStyle: NSRoundedBezelStyle];
		[[mPasswordPanel contentView] addSubview: okButton];

		// Cancel:
		NSRect	cancelBox = box;
		cancelBox.origin.x = NSMinX( okBox ) -CANCELBUTTONWIDTH -6;
		cancelBox.size.width = CANCELBUTTONWIDTH;
		cancelBox.origin.y += 12;
		cancelBox.size.height = CANCELBUTTONHEIGHT;
		okButton = [[[NSButton alloc] initWithFrame: cancelBox] autorelease];
		[okButton setTarget: self];
		[okButton setAction: @selector(doCancelButton:)];
		[okButton setTitle: @"Cancel"];
		[okButton setBordered: YES];
		[okButton setBezelStyle: NSRoundedBezelStyle];
		[[mPasswordPanel contentView] addSubview: okButton];
		
		// Password field:
		NSRect				passBox = box;
		passBox.origin.y = NSMaxY(okBox) + 12;
		passBox.size.height = PASSHEIGHT;
		passBox.origin.x += 12;
		passBox.size.width -= 12 * 2;
		mPasswordField = [[NSSecureTextField alloc] initWithFrame: passBox];
		[mPasswordField setSelectable: YES];
		[mPasswordField setEditable: YES];
		[mPasswordField setBordered: YES];
		[mPasswordField setBezeled: YES];
		[mPasswordField setBezelStyle: NSTextFieldSquareBezel];
		[mPasswordField selectText: self];
		[[mPasswordPanel contentView] addSubview: mPasswordField];
	}
	
	return mPasswordPanel;
}


-(IBAction)	doOKButton: (id)sender
{
	printf( "%s\n", [[mPasswordField stringValue] UTF8String] );
	[[NSApplication sharedApplication] terminate: self];
}


-(IBAction)	doCancelButton: (id)sender
{
	printf("\n");
	[[NSApplication sharedApplication] terminate: self];
}

@end



int	main( int argc, const char** argv )
{
	ProcessSerialNumber	myPSN = { 0, kCurrentProcess };
	TransformProcessType( &myPSN, kProcessTransformToForegroundApplication );
	
	NSApplication	*	app = [NSApplication sharedApplication];
	GAPAppDelegate	*	appDel = [[GAPAppDelegate alloc] init];
	[app setDelegate: appDel];
	NSWindow*			passPanel = [appDel passwordPanel];
	
	[app activateIgnoringOtherApps: YES];
	[passPanel makeKeyAndOrderFront: nil];
	[app runModalForWindow: passPanel];
	
	return 0;
}

