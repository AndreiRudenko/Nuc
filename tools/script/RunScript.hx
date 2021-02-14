package;

import haxe.io.Path;
import sys.FileSystem;

class RunScript {

	public static function main() {
		var args = Sys.args();
		var cwd = args.pop();
		Sys.setCwd(cwd);
		var engineDir = FileSystem.absolutePath(Path.directory(neko.vm.Module.local().name));
		var cliPath = Path.join([engineDir, 'tools', 'nucli', 'run']);
		Sys.exit(Sys.command("neko", [cliPath].concat(args)));
	}
	
}