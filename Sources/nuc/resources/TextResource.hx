package nuc.resources;

import kha.Blob;
import nuc.Resources;

@:allow(nuc.Resources)
class TextResource extends Resource {

	public var text:String;
	var blob:Blob;

	@:allow(nuc.Resources)
	function new(text:String) {
		this.text = text;
		resourceType = ResourceType.TEXT;
	}

	override function memoryUse() {
        return text != null ? text.length : 0;
	}

	override function unload() {
		if (blob != null) {
			blob.unload();
			blob = null;
		}
		text = null;
	}

}
