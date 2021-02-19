package nuc.resources;

import nuc.Resources;

class JsonResource extends Resource {

	public var json:Dynamic;

	public function new(json:Dynamic) {
		this.json = json;
		resourceType = ResourceType.JSON;
	}

}
