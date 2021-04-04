package nuc.graphics;

import kha.Blob;
import kha.graphics2.truetype.StbTruetype;
import kha.graphics4.TextureFormat;
import nuc.resources.Resource;
import nuc.Resources;
using StringTools;

import haxe.ds.Vector;
import haxe.io.Bytes;

class Font extends Resource {

	public static function fromBytes(bytes:Bytes, fontIndex:Int = 0):Font {
		return new Font(Blob.fromBytes(bytes), fontIndex);
	}

	public var blob:Blob;

	var oldGlyphs:Array<Int>;
	var images:Map<Int, FontImage>;
	var fontIndex:Int;

	public function new(blob:Blob, fontIndex:Int = 0) {
		this.blob = blob;
		this.fontIndex = fontIndex;

		images = new Map();
		resourceType = ResourceType.FONT;
	}

	public function load(?onComplete:()->Void) {
		if(blob != null) {
			if(onComplete != null) onComplete();
		} else {
			images = new Map();
			kha.Assets.loadBlobFromPath(
				Nuc.resources.getResourcePath(name),
				function(b:Blob){
					blob = b;
					if(onComplete != null) onComplete();
				},
				Nuc.resources.onError
			);
		}
	}

	override function unload() {
		for (i in images) {
			i.dispose();
			// Nuc.resources.remove(t);
		}
		blob = null;
		images = null;
	}

	public function getFontImage(fontSize:Int):FontImage {
		var glyphs = kha.graphics2.Graphics.fontGlyphs;

		if (glyphs != oldGlyphs) {
			oldGlyphs = glyphs;
			// save first/last chars of sequences
			FontImage.charBlocks = [glyphs[0]];
			var nextChar = FontImage.charBlocks[0] + 1;
			for (i in 1...glyphs.length) {
				if (glyphs[i] != nextChar) {
					FontImage.charBlocks.push(glyphs[i - 1]);
					FontImage.charBlocks.push(glyphs[i]);
					nextChar = glyphs[i] + 1;
				} else {
					nextChar++;
				}
			}
			FontImage.charBlocks.push(glyphs[glyphs.length - 1]);
		}

		var imageIndex = fontIndex * 10000000 + fontSize * 10000 + glyphs.length;
		if (!images.exists(imageIndex)) {
			var width:Int = 64;
			var height:Int = 32;
			var baked = new Vector<Stbtt_bakedchar>(glyphs.length);
			for (i in 0...baked.length) {
				baked[i] = new Stbtt_bakedchar();
			}

			var pixels:Blob = null;

			var offset = StbTruetype.stbtt_GetFontOffsetForIndex(blob, fontIndex);
			if (offset == -1) {
				offset = StbTruetype.stbtt_GetFontOffsetForIndex(blob, 0);
			}
			var status:Int = -1;
			while (status <= 0) {
				if (height < width){
					height *= 2;
				} else {
					width *= 2;
				}
				pixels = Blob.alloc(width * height);
				status = StbTruetype.stbtt_BakeFontBitmap(blob, offset, fontSize, pixels, width, height, glyphs, baked);
			}

			// TODO:Scale pixels down if they exceed the supported texture size

			var info = new Stbtt_fontinfo();
			StbTruetype.stbtt_InitFont(info, blob, offset);

			var metrics = StbTruetype.stbtt_GetFontVMetrics(info);
			var scale = StbTruetype.stbtt_ScaleForPixelHeight(info, fontSize);
			var ascent = Math.round(metrics.ascent * scale); // equals baseline
			var descent = Math.round(metrics.descent * scale);
			var lineGap = Math.round(metrics.lineGap * scale);

			var image = new FontImage(Std.int(fontSize), ascent, descent, lineGap, width, height, baked, pixels);
			images[imageIndex] = image;
			return image;
		}

		return images[imageIndex];
	}

	
	override function memoryUse() {
        return blob.length;
	}

	public function getTexture(fontSize:Int):Texture {
		// var img = getFontImage(fontSize);

		// var t = textures.get(fontSize);

		// if(t == null) {
		// 	var k = getFontImage(fontSize);
		// 	t = new Texture(k.getTexture());
		// 	t.name = name + "_" + fontSize;
		// 	textures.set(fontSize, t);
		// }

		return getFontImage(fontSize).texture;
	}

	public function height(fontSize:Int):Float {
		return getFontImage(fontSize).getHeight();
	}

	public function width(fontSize:Int, str:String):Float {
		return getFontImage(fontSize).stringWidth(str);
	}

	public function charWidth(fontSize:Int, charCode:Int):Float {
		return getFontImage(fontSize).getCharWidth(charCode);
	}

	public function charactersWidth(fontSize:Int, characters:Array<Int>, start:Int, length:Int):Float {
		return getFontImage(fontSize).charactersWidth(characters, start, length);
	}

}

class FontImage {

	public static var charBlocks:Array<Int>;

	public var texture:Texture;

	public var width:Int;
	public var height:Int;

	var chars:Vector<Stbtt_bakedchar>;
	var baseline:Float;
	var size:Float;

	public function new(size:Int, ascent:Int, descent:Int, lineGap:Int, width:Int, height:Int, chars:Vector<Stbtt_bakedchar>, pixels:Blob) {
		this.size = size;
		this.width = width;
		this.height = height;
		this.chars = chars;
		baseline = ascent;

		for (char in chars) {
			char.yoff += baseline;
		}

		texture = Texture.create(width, height, TextureFormat.RGBA32);
		var bytes = texture.lock();

		var c:Color = new Color();
		var pos:Int = 0;
		var b:Int = 0;
		for (y in 0...height){
			for (x in 0...width) {
				b = pixels.readU8(pos);
				#if cpp
				c.setBytes(b, b, b, b);
				#else
				c.setBytes(255, 255, 255, b);
				#end
				bytes.setInt32(pos*4, c);
				pos++;
			}
		}

		texture.unlock();
	}

	public function getBakedQuad(q:CQuad, charIndex:Int, xpos:Float, ypos:Float):CQuad {
		if (charIndex >= chars.length) return null;
		var ipw:Float = 1.0 / width;
		var iph:Float = 1.0 / height;
		var b = chars[charIndex];
		if (b == null) return null;
		var round_x:Int = Math.round(xpos + b.xoff);
		var round_y:Int = Math.round(ypos + b.yoff);

		q.x0 = round_x;
		q.y0 = round_y;
		q.x1 = round_x + b.x1 - b.x0;
		q.y1 = round_y + b.y1 - b.y0;

		q.s0 = b.x0 * ipw;
		q.t0 = b.y0 * iph;
		q.s1 = b.x1 * ipw;
		q.t1 = b.y1 * iph;

		q.xadvance = b.xadvance;

		return q;
	}

	public function getCharWidth(charIndex:Int):Float {
		if (chars.length == 0)return 0;
		var offset = charBlocks[0];
		if (charIndex < offset) return chars[0].xadvance;

		for (i in 1...Std.int(charBlocks.length / 2)) {
			var prevEnd = charBlocks[i * 2 - 1];
			var start = charBlocks[i * 2];
			if (charIndex > start - 1) {
				offset += start - 1 - prevEnd;
			}
		}

		if (charIndex - offset >= chars.length)return chars[0].xadvance;

		return chars[charIndex - offset].xadvance;
	}

	public function dispose() {
		texture.unload();
		texture = null;
		chars = null;
	}

	public function getHeight():Float {
		return size;
	}

	public function stringWidth(str:String):Float {
		var width:Float = 0;
		for (c in 0...str.length) {
			width += getCharWidth(str.charCodeAt(c));
		}
		return width;
	}

	public function charactersWidth(characters:Array<Int>, start:Int, length:Int):Float {
		var width:Float = 0;
		for (i in start...start + length) {
			width += getCharWidth(characters[i]);
		}
		return width;
	}

	public function getBaselinePosition():Float {
		return baseline;
	}

}

class CQuad {
	public function new() {}

	// top-left
	public var x0:Float;
	public var y0:Float;
	public var s0:Float;
	public var t0:Float;

	// bottom-right
	public var x1:Float;
	public var y1:Float;
	public var s1:Float;
	public var t1:Float;

	public var xadvance:Float;
}