package nuc.graphics;

import nuc.Resources;
import nuc.resources.Resource;

class Video extends Resource {

	public var video:kha.Video;

	public function new(video:kha.Video) {
		this.video = video;
		resourceType = ResourceType.VIDEO;
	}

	override function unload() {
		video.unload();
	}
	
}
