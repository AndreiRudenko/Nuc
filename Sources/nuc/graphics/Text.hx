package nuc.graphics;

import kha.audio2.StreamChannel;
import nuc.graphics.BitmapFont;

using StringTools;
using nuc.utils.ArrayTools;

class Text {

	static final spaceCharCode:Int = " ".code;
	static final breakCharCode:Int = "\n".code;
	static final returnCharCode:Int = "\r".code;
	static final tabCharCode:Int = "\t".code;
	
	public var visible:Bool = true;

	public var x:Float;
	public var y:Float;

	public var width(get, set):Float;
	var _width:Float;
	inline function get_width() return _width;
	function set_width(v) {
		dirty = true;
		return _width = v;
	}

	public var height(get, set):Float;
	var _height:Float;
	inline function get_height() return _height;
	function set_height(v) {
		dirty = true;
		return _height = v;
	}

	public var text(get, set):String;
	var _text:String;
	inline function get_text() return _text;
	function set_text(v) {
		dirty = true;
		return _text = v;
	}

	public var color:Color = Color.WHITE;

	public var verticalAlign(get, set):TextAlign;
	var _verticalAlign:TextAlign = TextAlign.Top;
	inline function get_verticalAlign() return _verticalAlign;
	function set_verticalAlign(v) {
		dirty = true;
		return _verticalAlign = v;
	}

	public var horizontalAlign(get, set):TextAlign;
	var _horizontalAlign:TextAlign = TextAlign.Left;
	inline function get_horizontalAlign() return _horizontalAlign;
	function set_horizontalAlign(v) {
		dirty = true;
		return _horizontalAlign = v;
	}
	
	public var rotation(get, set):Float;
	var _rotation:Float;
	inline function get_rotation() return _rotation;
	function set_rotation(v) {
		dirty = true;
		return _rotation = v;
	}

	public var scaleX(get, set):Float;
	var _scaleX:Float;
	inline function get_scaleX() return _scaleX;
	function set_scaleX(v) {
		dirty = true;
		return _scaleX = v;
	}

	public var scaleY(get, set):Float;
	var _scaleY:Float;
	inline function get_scaleY() return _scaleY;
	function set_scaleY(v) {
		dirty = true;
		return _scaleY = v;
	}

	public var font(get, set):BitmapFont;
	var _font:BitmapFont = Resources.fontDefault;
	inline function get_font() return _font; 
	function set_font(v:BitmapFont):BitmapFont {
		if(v == null) v = Resources.fontDefault;
		dirty = true;
		return _font = v;
	}

	public var fontSize(get, set):Float;
	var _fontSize:Float = 16;
	inline function get_fontSize() return _fontSize;
	function set_fontSize(v) {
		dirty = true;
		return _fontSize = v;
	}

	public var leading(get, set):Float;
	var _leading:Float = 1.2;
	inline function get_leading() return _leading;
	function set_leading(v) {
		dirty = true;
		return _leading = v;
	}

	public var tracking(get, set):Float;
	var _tracking:Float = 0;
	inline function get_tracking() return _tracking;
	function set_tracking(v) {
		dirty = true;
		return _tracking = v;
	}

	public var tabSize(get, set):Int;
	var _tabSize:Int = 4;
	inline function get_tabSize() return _tabSize;
	function set_tabSize(v) {
		dirty = true;

		tabStr = "";
		for (i in 0...v) {
			tabStr += " ";
		}

		return _tabSize = v;
	}

	var chars:Array<CharInfo>;
	var dirty:Bool = true;
	var emptyStr:String = "";
	var tabStr:String = "    ";
	var spaceStr:String = " ";
	var lines:Array<String> = [];
	var sizes:Array<Float> = [];

	public function new(?font:BitmapFont) {
		chars = [];
		this.font = font;
	}

	function splitLines():Array<String> {
		lines.clear();
		sizes.clear();

		if (width == 0) {
			lines = text.split('\n');
			return lines;
		}

		final scaleDiff:Float = fontSize / font.fontSize;
		final spaceChar:BitmapChar = font.chars.get(spaceCharCode);
		final spaceWidth:Float = spaceChar.xadvance * scaleDiff + tracking;
		final tabWidth:Float = spaceChar.xadvance * scaleDiff * tabSize + tracking;
		final lineHeight:Float = font.lineHeight * leading * scaleDiff;

		var line = "";
		var charCode:Int = 0;
		var currentX:Float = 0;
		var currentY:Float = lineHeight;
	
		var wordPos:Int = 0;
		var wordLength:Int = 0;
		var wordWidth:Float = 0;
		var lineWidth:Float = 0;
		var lastWordPos:Float = 0;

		inline function applyWord(idx:Int) {
			// if (wordWidth > width) {
			// 	final word = text.substr(idx - wordLength, wordLength);

			// 	for (i in 0...word.length) {
			// 		if (currentY > height) break;

			// 		final curChar = word.charCodeAt(i);
			// 		final char = font.chars.get(curChar);
			// 		final charWidth = char.xadvance * scaleDiff + tracking;
					
			// 		if (currentX + charWidth > width && line != emptyStr) {
			// 			lines.push(line);
			// 			sizes.push(lastWordPos);
	
			// 			line = "";
			// 			lastWordPos = 0;
			// 			currentX = 0;
			// 			currentY += lineHeight;
			// 		}
	
			// 		line += word.charAt(i);
			// 		currentX += charWidth;
			// 		lastWordPos = currentX;
			// 	}

			// 	wordLength = 0;
			// 	wordWidth = 0;
			
			// } else {

				if (currentX + wordWidth > width && line != emptyStr) { // TODO: test it, Im not sure about line != emptyStr

					lines.push(line);
					sizes.push(lastWordPos);
	
					line = "";
					lastWordPos = 0;
					currentX = 0;
					currentY += lineHeight;
				}
	
				if (wordLength > 0) {
					line += text.substr(idx - wordLength, wordLength);
	
					currentX += wordWidth;
					lastWordPos = currentX;
	
					wordWidth = 0;
					wordLength = 0;
				}
			// }
		}

		for (i in 0...text.length) {
			if (currentY > height) break;

			final curChar = text.charCodeAt(i);

			switch (curChar) {
				case breakCharCode:
					applyWord(i);
					lines.push(line);
					sizes.push(lastWordPos);
					lastWordPos = 0;
					line = "";
					currentX = 0;
					currentY += lineHeight;

					continue;
				case spaceCharCode:
					applyWord(i);

					line += text.charAt(i);
					currentX += spaceWidth;
					
					continue;
				case tabCharCode:
					applyWord(i);

					line += text.charAt(i);
					currentX += tabWidth;
					continue;
				default:
			}

			final bChar:BitmapChar = font.chars.get(curChar);
			if (bChar == null) {
				wordLength++;
				continue;
			}

			final charWidth:Float = bChar.xadvance * scaleDiff + tracking;

			wordLength++;
			wordWidth += charWidth;
		}

		if (currentX + wordWidth > width && currentY < height) {
			lines.push(line);
			sizes.push(lastWordPos);

			line = "";
			lastWordPos = 0;
			currentX = 0;
			currentY += lineHeight;
		}

		if (wordLength > 0 && currentY < height) {
			line += text.substr(text.length - wordLength, wordLength);
			lines.push(line);
			sizes.push(currentX + wordWidth);
		}

		return lines;
	}

	function getLineOffsetX(lineIdx:Int):Float {
		var lineOffsetX:Float = 0;

		switch (horizontalAlign) {
			case TextAlign.Center:
				lineOffsetX = (width - sizes[lineIdx]) / 2;
			case TextAlign.Right:
				lineOffsetX = width - sizes[lineIdx];
			default:
		}

		return lineOffsetX;
	}

	function getLineOffsetY(linesCount:Int):Float {
		if (height == 0) return 0;
		var lineOffsetY:Float = 0;

		switch (verticalAlign) {
			case TextAlign.Center:
				lineOffsetY = (height - linesCount * font.lineHeight * leading * (fontSize / font.fontSize)) / 2;
			case TextAlign.Bottom:
				lineOffsetY = height - linesCount * font.lineHeight * leading * (fontSize / font.fontSize);
			default:
		}

		return lineOffsetY;
	}

	function updateChars() {
		if (!dirty || text == null || text.length == 0) return;

		chars.clear();

		final scaleDiff:Float = fontSize / font.fontSize;

		var bChar:BitmapChar;
		var charCode:Int = 0;
		var currentX:Float = 0;
		var currentY:Float = 0;

		var wordPos:Float = 0;
		var lines = splitLines();

		final spaceChar = font.chars.get(spaceCharCode);

		final offsetY = getLineOffsetY(lines.length);

		for (i in 0...lines.length) {
			final line = lines[i];
			final offsetX = getLineOffsetX(i);

			// if (sizes[i] < width) {
				for(j in 0...line.length) {
					charCode = line.fastCodeAt(j);

					if (charCode == spaceCharCode) {
						currentX += spaceChar.xadvance + tracking;
						continue;
					} else if (charCode == tabCharCode) {
						currentX += spaceChar.xadvance * tabSize + tracking;
						continue;
					}

					bChar = font.chars.get(charCode);
					if (bChar == null) continue;

					var charInfo = new CharInfo();

					charInfo.x = offsetX + (currentX + bChar.xoffset) * scaleDiff;
					charInfo.y = offsetY + (currentY + bChar.yoffset) * scaleDiff;
					charInfo.width = bChar.width * scaleDiff;
					charInfo.height = bChar.height * scaleDiff;

					charInfo.regionX = bChar.x;
					charInfo.regionY = bChar.y;
					charInfo.regionWidth = bChar.width;
					charInfo.regionHeight = bChar.height;

					charInfo.textureIdx = bChar.page;

					chars.push(charInfo);

					currentX += bChar.xadvance + tracking;
				}
			// }
			
			currentX = 0;
			currentY += font.lineHeight * leading;
		}

		dirty = false;
	}

	public function draw(b:SpriteBatch) {
		if (!visible) return;
		updateChars();

		b.color = color;

		for (char in chars) {
			b.drawImage(font.textures[char.textureIdx], x + char.x, y + char.y, char.width, char.height, char.regionX, char.regionY, char.regionWidth, char.regionHeight);
		}
	}

	public function clone():Text {
		var t = new Text(font);
		t.text = text;
		t.x = x;
		t.y = y;
		t.width = width;
		t.height = height;
		t.fontSize = fontSize;
		t.horizontalAlign = horizontalAlign;
		t.verticalAlign = verticalAlign;
		t.color = color;
		t.visible = visible;
		t.tracking = tracking;
		t.leading = leading;
		t.tabSize = tabSize;

		return t;
	}

}

class CharInfo {

	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;

	public var regionX:Float;
	public var regionY:Float;
	public var regionWidth:Float;
	public var regionHeight:Float;

	public var textureIdx:Int;

	public function new() {
		x = 0;
		y = 0;
		width = 0;
		height = 0;

		regionX = 0;
		regionY = 0;
		regionWidth = 0;
		regionHeight = 0;

		textureIdx = 0;
	}

}

enum abstract TextAlign(Int) {
	var Top;
	var Bottom;
	var Left;
	var Right;
	var Center;
}