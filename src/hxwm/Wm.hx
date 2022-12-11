package hxwm;

import x11.XEventType.EventMask;
import haxe.Exception;
import x11.X11;
import x11.X11.XWindowAttributes;

class Wm {

	private var display : XDisplayPtr;
	private var root : Window;

	private var win2Frame : Map<Window, Window> = new Map<Window, Window>();

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
		for (child in children) {
			frameWindow(child, true);
		}
		X11.ungrabServer(display);
		// --- End

		// Handle WM events
		while(true) {
			X11.nextEvent(display);
			var type = X11.getXEventType();
		}
	}

	private function frameWindow( window : Window, is_wm_init : Bool = false ) {
		trace(win2Frame.get(window));
		if(win2Frame.get(window) != null)
			return;

		var winAttr : XWindowAttributes = new XWindowAttributes();
		X11.getWindowAttributes( display, window, winAttr );

		if(is_wm_init) {
			// if(winAttr.override_redirect || winAttr.map_state != 2)
			// 	return;
		}

		trace('before frame');
		var frame : Window = X11.createSimpleWindow(display, root, winAttr.x, winAttr.y, winAttr.width, winAttr.height, 10, 0x005060, 0x500000);
		X11.selectInput(display, frame, EventMask.SubstructureNotifyMask | EventMask.SubstructureRedirectMask);
		trace('after input');
		X11.addToSaveSet(display, window);
		X11.reparentWindow(display, window, frame, 0, 0);
		X11.mapWindow(display, frame);
		win2Frame.set(window, frame);
		trace('${window} framed');
	}

	private function alreadyHasWMHandler( display : XDisplayPtr, event : XErrorEventType ) : Int {
		has_wm = true;
		return 0;
	}

	public static function printHelp() {
		Sys.print("Usage: hxwm [display]\n");
	}
}
