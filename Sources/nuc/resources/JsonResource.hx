package nuc.resources;

import kha.Blob;
import nuc.Resources;

@:allow(nuc.Resources)
class JsonResource extends Resource {

	public var json:Dynamic;
	var blob:Blob;

	@:allow(nuc.Resources)
	function new(json:Dynamic) {
		this.json = json;
		resourceType = ResourceType.JSON;
	}

	override function unload() {
		if (blob != null) {
			blob.unload();
			blob = null;
		}
		json = null;
	}

}
