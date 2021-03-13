package nuc.graphics;

import kha.Kravur;
import kha.Kravur.KravurImage;
import nuc.resources.Resource;
import nuc.Resources;
using StringTools;

@:access(kha.Kravur)
@:access(kha.KravurImage)
class Font extends Resource {

	public var font:kha.Font;
	public var textures(default, null):Map<Int, Texture>;

	public function new(font:kha.Font) {
		this.font = font;
		textures = new Map();
		
		resourceType = ResourceType.FONT;
	}

	public function load(?onComplete:()->Void) {
		if(font != null) {
			if(onComplete != null) onComplete();
		} else {
			kha.Assets.loadFontFromPath(
				Nuc.resources.getResourcePath(name),
				function(f:kha.Font){
					font = f;
					if(onComplete != null) onComplete();
				},
				Nuc.resources.onError
			);
		}
	}

	override function unload() {
		font.unload();
		font = null;
		for (t in textures) {
			Nuc.resources.remove(t);
		}
		textures = null;
	}
	
	override function memoryUse() {
        return font.blob.length;
	}

	public function getTexture(fontSize:Int):Texture {
		var t = textures.get(fontSize);

		if(t == null) {
			var k = font._get(fontSize);
			t = new Texture(k.getTexture());
			t.name = name + "_" + fontSize;
			textures.set(fontSize, t);
		}

		return t;
	}

	public function height(fontSize:Int):Float {
		return font._get(fontSize).getHeight();
	}

	public function width(fontSize:Int, str:String):Float {
		return font._get(fontSize).stringWidth(str);
	}

	public function charWidth(fontSize:Int, charCode:Int):Float {
		return font._get(fontSize).getCharWidth(charCode);
	}

	public function charactersWidth(fontSize:Int, characters:Array<Int>, start:Int, length:Int):Float {
		return font._get(fontSize).charactersWidth(characters, start, length);
	}

}
