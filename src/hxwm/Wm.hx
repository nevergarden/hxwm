package hxwm;

import x11.XEventType.EventMask;
import haxe.Exception;
import x11.X11;
import x11.X11.XWindowAttributes;

class Wm {

	private var display : XDisplayPtr;
	private var root : Window;

	private var has_wm : Bool = false;

	public function new( ?displayString : String = null ) {
		if( displayString == null )
			display = X11.openDisplay(null);
		else {
			var d : hl.Bytes = hl.Bytes.fromBytes(haxe.io.Bytes.ofString(displayString));
			display = X11.openDisplay(d);
		}
		if( display == null )
			throw new Exception('Can not open display ${displayString}');

		root = X11.defaultRootWindow(display);

		// Checking for another window manager
		X11.setErrorHandler(alreadyHasWMHandler);
		X11.selectInput( display, root, EventMask.SubstructureNotifyMask | EventMask.SubstructureRedirectMask);
		X11.sync(display, false);
		if( has_wm ) {
			Sys.stderr().writeString("Stealing other WM is not cool.");
			Sys.exit(1);
		}

		// Query Children that don't have parent window manager.
		X11.grabServer(display);
		var windowsRef : hl.Ref<hl.NativeArray<Window>> = hl.Ref.make(new hl.NativeArray<Window>(0));
		var rootRef : hl.Ref<Null<Window>> = hl.Ref.make(null);
		var parentRef : hl.Ref<Null<Window>> = hl.Ref.make(null);
		// ---
		X11.queryTree(display, root, rootRef, parentRef, windowsRef);
		var children : hl.NativeArray<Window> = windowsRef.get();
		trace(children);
		X11.ungrabServer(display);
		// --- End

		// Handle WM events
		while(true) {
			X11.nextEvent(display);
		}
	}

	private function frameWindow( window : Window, is_wm_init : Bool = false ) {
		var winAttributesRef : hl.Ref<x11.X11.XWindowAttributes> = x11.X11.XWindowAttributes.getRef();
		X11.getWindowAttributes( display, window, winAttributesRef );
		var winAttributes = winAttributesRef.get();
		trace(winAttributes.x);
	}

	private function alreadyHasWMHandler( display : XDisplayPtr, event : XErrorEventType ) : Int {
		has_wm = true;
		return 0;
	}

	public static function printHelp() {
		Sys.print("Usage: hxwm [display]\n");
	}
}
