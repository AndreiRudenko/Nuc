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

	public function load(?onComplete:()->Void) {
		if(blob != null) {
			if(onComplete != null) onComplete();
		} else {
			kha.Assets.loadBlobFromPath(
				Nuc.resources.getResourcePath(name),
				function(b:kha.Blob){
					blob = b;
					if(onComplete != null) onComplete();
				},
				Nuc.resources.onError
			);
		}
	}
	override function unload() {
		blob.unload();
		blob = null;
	}

	override function memoryUse() {
		return blob.length;
	}

}