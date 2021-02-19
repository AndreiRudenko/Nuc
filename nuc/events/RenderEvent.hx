package nuc.events;

import nuc.Graphics;
import nuc.Renderer;
import nuc.utils.EventType;
import kha.Framebuffer;

@:allow(nuc.App)
class RenderEvent implements IEvent {

	static public inline var PRERENDER:EventType<RenderEvent>;
	static public inline var POSTRENDER:EventType<RenderEvent>;
	static public inline var RENDER:EventType<RenderEvent>;

	public var r(default, null):Renderer;
	public var g(default, null):Graphics;
	public var g2(default, null):kha.graphics2.Graphics;
	public var g4(default, null):kha.graphics4.Graphics;

	function new() {}

	function set(r:Renderer, g:Graphics, g2:kha.graphics2.Graphics, g4:kha.graphics4.Graphics) {
		this.r = r;
		this.g = g;
		this.g2 = g2;
		this.g4 = g4;
	}

}
