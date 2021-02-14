package commands;

import Config;
import haxe.io.Path;

class Watch extends Command {

	public function new() {
		super(
			'watch', 
			'Watch files and recompile on change'
		);
	}

	override function execute(args:Array<String>) {
		CLI.execute('start', ['cmd', "/c", '${CLI.khamakePath}', '--watch', '--projectfile', 'build/khafile.js']);
	}

}