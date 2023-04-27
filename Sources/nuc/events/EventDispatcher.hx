package nuc.events;

class EventDispatcher {

	@:noCompletion public var bindings:Map<EventType<Dynamic>, Array<Dynamic->Void>>;

	var removeQueue:Array<EmitHandler<Dynamic>>;
	var addQueue:Array<EmitHandler<Dynamic>>;
	var processing:Bool;

	public function new() {
		bindings = new Map();

		removeQueue = [];
		addQueue = [];
		processing = false;
	}

	public function fire<T>(event:EventType<T>, ?data:T) {
		final list = bindings.get(event);

		if(list == null) return;

		processing = true;
		for (e in list) {
			e(data);
		}
		processing = false;

		removeQueuedHandlers();
		addQueuedHandlers();
	}

	public function on<T>(event:EventType<T>, handler:(e:T)->Void) {
		if(hasHandler(event, handler)) return;
		
		if(processing) {
			addHandlerToAddQueue(event, handler);
		} else {
			addHandler(event, handler);
		}
	}

	public function once<T>(event:EventType<T>, handler:(e:T)->Void) {
		if(hasHandler(event, handler)) return;
		
		on(event, function(e:T) {
			handler(e);
			off(event, handler);
		});
	}

	public function off<T>(event:EventType<T>, handler:(e:T)->Void) {
		if(!hasHandler(event, handler)) return;
		
		if(processing) {
			addHandlerToRemoveQueue(event, handler);
		} else {
			removeHandler(event, handler);
		}
	}

	function hasHandler<T>(event:EventType<T>, handler:(e:T)->Void):Bool {
		final list = bindings.get(event);
		return list != null && list.indexOf(handler) >= 0;
	}
	
    inline function addHandler<T>(event:EventType<T>, handler:(e:T)->Void) {
		var list = bindings.get(event);
		
		if(list == null) {
			list = new Array<T->Void>();
			bindings.set(event, list);
		}

		list.push(handler);
	}

	inline function removeHandler<T>(event:EventType<T>, handler:(e:T)->Void) {
		final list = bindings.get(event);
	
		final idx = list.indexOf(handler);
		if(idx >= 0) list.splice(idx, 1);

		if(list.length == 0) bindings.remove(event);
	}
	
	function addHandlerToRemoveQueue<T>(event:EventType<T>, handler:(e:T)->Void) {
		for (e in removeQueue) {
			if(e.callback == handler) return;
		}
		removeQueue.push(new EmitHandler(event, handler));
	}

	function addHandlerToAddQueue<T>(event:EventType<T>, handler:(e:T)->Void) {
		for (e in addQueue) {
			if(e.callback == handler) return;
		}
		addQueue.push(new EmitHandler(event, handler));
	}

	inline function removeQueuedHandlers() {
		if(removeQueue.length > 0) {
			for (e in removeQueue) {
				removeHandler(e.event, e.callback);
			}
			removeQueue.splice(0, removeQueue.length);
		}
	}

	inline function addQueuedHandlers() {
		if(addQueue.length > 0) {
			for (eh in addQueue) {
				addHandler(eh.event, eh.callback);
			}
			addQueue.splice(0, addQueue.length);
		}
	}

	public function toString() {
		var result = "Events:";
		for (key in bindings.keys()) {
			result += "\n\t" + key + " (" + bindings.get(key).length + ")";
		}
		return result;
	}

}

private class EmitHandler<T> {

	public var event:EventType<T>;
	public var callback:(e:T)->Void;

	public function new(event:EventType<T>, callback:(e:T)->Void) {
		this.event = event;
		this.callback = callback;
	}

}


