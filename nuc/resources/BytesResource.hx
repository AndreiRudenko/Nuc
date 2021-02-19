package nuc.resources;

import haxe.io.Bytes;
import nuc.Resources;
import nuc.resources.Resource;

class BytesResource extends Resource {

	static public function create(size:Int):BytesResource {
		var b = kha.Blob.alloc(size);
		return new BytesResource(b);
	}

	static public function createFromBytes(bytes:Bytes):BytesResource {
		var b = kha.Blob.fromBytes(bytes);
		return new BytesResource(b);
	}

	public var blob:kha.Blob;

	public function new(blob:kha.Blob) {
		this.blob = blob;
		resourceType = ResourceType.BYTES;
	}

	public function load() {

	}

	override function unload() {
		blob.unload();
	}

	override function memoryUse() {
		return blob.length;
	}

}