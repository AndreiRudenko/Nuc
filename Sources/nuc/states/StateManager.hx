package nuc.states;

class StateManager {

	var currentState:State;

	public function new() {}

	public function set(state:State) {
		if (currentState != null) {
			currentState.exit();
		}
		currentState = state;
		currentState.enter();
	}

	public function update() {
		if (currentState != null) {
			currentState.update();
		}
	}

	public function draw() {
		if (currentState != null) {
			currentState.draw();
		}
	}

	public function pause() {
		if (currentState != null) {
			currentState.pause();
		}
	}

	public function resume() {
		if (currentState != null) {
			currentState.resume();
		}
	}
}