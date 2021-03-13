package nuc.graphics;

import nuc.Resources;
import nuc.resources.Resource;

class Video extends Resource {

	public var video:kha.Video;

	public function new(video:kha.Video) {
		this.video = video;
		resourceType = ResourceType.VIDEO;
	}

	public function load(?onComplete:()->Void) {
		if(video != null) {
			if(onComplete != null) onComplete();
		} else {
			kha.Assets.loadVideoFromPath(
				Nuc.resources.getResourcePath(name),
				function(v:kha.Video){
					video = v;
					if(onComplete != null) onComplete();
				},
				Nuc.resources.onError
			);
		}
	}

	override function unload() {
		video.unload();
		video = null;
	}
	
}
