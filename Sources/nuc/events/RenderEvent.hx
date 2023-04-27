package nuc.events;

import nuc.Graphics;
import nuc.events.EventType;
import kha.Framebuffer;

@:allow(nuc.App)
class RenderEvent {

	static public inline var PRERENDER:EventType<RenderEvent> = 'PRERENDER';
	static public inline var RENDER:EventType<RenderEvent> = 'RENDER';
	static public inline var POSTRENDER:EventType<RenderEvent> = 'POSTRENDER';

	public var g2(default, null):kha.graphics2.Graphics;
	public var g4(default, null):kha.graphics4.Graphics;

	public function new() {}

	public function set(g2:kha.graphics2.Graphics, g4:kha.graphics4.Graphics) {
		this.g2 = g2;
		this.g4 = g4;
	}

}
