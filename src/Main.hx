package;

import hxwm.Wm;

class Main {
	public static var wm : Wm;

	public static function main() {
		trace(Sys.args());
		if(Sys.args().length > 1) {
			Wm.printHelp();
			Sys.exit(64);
		}

		if(Sys.args().length == 0) {
			wm = new Wm();
		} else {
			wm = new Wm(Sys.args()[0]);
		}
	}
}
