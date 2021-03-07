package nuc.utils;

import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;

@:enum
private abstract LogLevel(Int) from Int to Int {
	var VERBOSE = 0;
	var DEBUG = 1;
	var INFO = 2;
	var WARNING = 3;
	var ERROR = 4;
	var CRITICAL = 5;
}

class Log {

	static inline var _spaces:String = '  ';
	static inline var _minLevel = 
		#if (nuc_loglevel == 'info') LogLevel.INFO
		#elseif (nuc_loglevel == 'verbose') LogLevel.VERBOSE
		#elseif (nuc_loglevel == 'debug') LogLevel.DEBUG
		#elseif (nuc_loglevel == 'error') LogLevel.ERROR
		#elseif (nuc_loglevel == 'critical') LogLevel.CRITICAL
		#elseif (nuc_loglevel == 'verbose') LogLevel.VERBOSE
		#else LogLevel.WARNING
		#end;

	macro static public function verbose(value:Dynamic):Expr {
		#if !nuc_no_log
		var file = Path.withoutDirectory(Context.getPosInfos(Context.currentPos()).file);
		var context = Path.withoutExtension(file);
		if(Std.int(LogLevel.VERBOSE) >= Std.int(_minLevel)) {
			return macro @:pos(Context.currentPos()) trace($v{'${_spaces}V / $context / '} + $value);
		}
		#end
		return macro null;
	}

	macro static public function debug(value:Dynamic):Expr {
		#if !nuc_no_log
		var file = Path.withoutDirectory(Context.getPosInfos(Context.currentPos()).file);
		var context = Path.withoutExtension(file);
		if(Std.int(LogLevel.DEBUG) >= Std.int(_minLevel)) {
			return macro @:pos(Context.currentPos()) trace($v{'${_spaces}D / $context / '} + $value);
		}
		#end
		return macro null;
	}

	macro static public function info(value:Dynamic):Expr {
		#if !nuc_no_log
		var file = Path.withoutDirectory(Context.getPosInfos(Context.currentPos()).file);
		var context = Path.withoutExtension(file);
		if(Std.int(LogLevel.INFO) >= Std.int(_minLevel)) {
			return macro @:pos(Context.currentPos()) trace($v{'${_spaces}I / $context / '} + $value);
		}
		#end
		return macro null;
	}

	macro static public function warning(value:Dynamic):Expr {
		#if !nuc_no_log
		var file = Path.withoutDirectory(Context.getPosInfos(Context.currentPos()).file);
		var context = Path.withoutExtension(file);
		if(Std.int(LogLevel.WARNING) >= Std.int(_minLevel)) {
			return macro @:pos(Context.currentPos()) trace($v{'${_spaces}W / $context / '} + $value);
		}
		#end
		return macro null;
	}

	macro static public function error(value:Dynamic):Expr {
		#if !nuc_no_log
		var file = Path.withoutDirectory(Context.getPosInfos(Context.currentPos()).file);
		var context = Path.withoutExtension(file);
		if(Std.int(LogLevel.ERROR) >= Std.int(_minLevel)) {
			return macro @:pos(Context.currentPos()) trace($v{'${_spaces}E / $context / '} + $value);
		}
		#end
		return macro null;
	}

	macro static public function critical(value:Dynamic):Expr {
		#if !nuc_no_log
		var file = Path.withoutDirectory(Context.getPosInfos(Context.currentPos()).file);
		var context = Path.withoutExtension(file);
		if(Std.int(LogLevel.ERROR) >= Std.int(_minLevel)) {
			return macro @:pos(Context.currentPos()) trace($v{'${_spaces}! / $context / '} + $value);
		}
		#end
		return macro null;
	}

	macro static public function assert(expr:Expr, ?reason:ExprOf<String>) {
		#if !nuc_no_assert
			var str = haxe.macro.ExprTools.toString(expr);

			reason = switch(reason) {
				case macro null: macro '';
				case _: macro ' ( ' + $reason + ' )';
			}

			return macro @:pos(Context.currentPos()) {
				// if(!$expr) throw('$str' + $reason);
				if(!$expr) throw($v{'$str $reason'});
			}
		#end
		return macro null;
	}

}
