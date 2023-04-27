package nuc.resources;

import haxe.io.Bytes;
import nuc.Resources;
import nuc.resources.Resource;

class BytesResource extends Resource {

	static public function create(size:Int):BytesResource {
		return new BytesResource(kha.Blob.alloc(size));
	}

	static public function createFromBytes(bytes:Bytes):BytesResource {
		return new BytesResource(kha.Blob.fromBytes(bytes));
	}

	public var blob:kha.Blob;

	@:allow(nuc.Resources)
	function new(blob:kha.Blob) {
		this.blob = blob;
		resourceType = ResourceType.BYTES;
	}

	override function unload() {
		blob.unload();
		blob = null;
	}

	override function memoryUse() {
		return blob.length;
	}

}