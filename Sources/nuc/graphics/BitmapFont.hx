package nuc.graphics;

import kha.Blob;
import haxe.Json;
import nuc.Resources;
import nuc.resources.Resource;
import nuc.graphics.Texture;
import nuc.utils.Math;
using StringTools;

@:allow(nuc.Resources)
class BitmapFont extends Resource {

	public var textures(default, null):Array<Texture>;
	public var fontName(default, null):String;
	public var fontSize(default, null):Int;
	public var lineHeight(default, null):Int;
	public var base(default, null):Int;
	public var chars(default, null):Map<Int, BitmapChar>;

	var blob:Blob;
	
	function new(data:Dynamic, textures:Array<Texture>) {
		this.textures = textures;
		chars = new Map();
		parse(data);
	}

	override function unload() {
		for (t in textures) {
			t.dispose();
		}

		if (blob != null) {
			blob.unload();
		}

		fontName = null;
		textures = null;
		chars = null;
		blob = null;
	}

	function parse(data:Dynamic) {
		fontName = data.info.face;
		fontSize = Math.iabs(data.info.size);
		lineHeight = data.common.lineHeight;
		base = data.common.base;

		final charList = data.chars;
		for (i in 0...charList.length) {
			final c = charList[i];
			final char = new BitmapChar(
				c.id,
				c.x, c.y,
				c.width, c.height,
				c.xoffset, c.yoffset,
				c.xadvance,
				c.page
			);
			chars.set(char.id, char);
		}
	}

	public function getHeight():Float {
		return fontSize;
	}

	public function getCharWidth(charCode:Int):Float {
		final char = chars.get(charCode);
		if(char == null) return 0;
		return char.xadvance;
	}

	public function getStringWidth(str:String):Float {
		var width:Float = 0;
		for (c in 0...str.length) {
			width += getCharWidth(str.charCodeAt(c));
		}
		return width;
	}

	public function getCharactersWidth(characters:Array<Int>, start:Int, length:Int):Float {
		var width:Float = 0;
		for (i in start...start + length) {
			width += getCharWidth(characters[i]);
		}
		return width;
	}

}

class BitmapChar {
	public var id:Int;
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	public var xoffset:Int;
	public var yoffset:Int;
	public var xadvance:Int;
	public var page:Int;

	public function new(id:Int, x:Int, y:Int, width:Int, height:Int, xoffset:Int, yoffset:Int, xadvance:Int, page:Int) {
		this.id = id;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.xoffset = xoffset;
		this.yoffset = yoffset;
		this.xadvance = xadvance;
		this.page = page;
	}
}

