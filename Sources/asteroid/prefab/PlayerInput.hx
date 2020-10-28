package asteroid.prefab;

import exp.ecs.*;
import exp.ecs.module.input.component.*;

@:forward(spawn)
abstract PlayerInput(Prefab) to Prefab {
	public static var inst(get, null):PlayerInput;

	static function get_inst() {
		if (inst == null)
			inst = new PlayerInput();
		return inst;
	}

	function new() {
		this = new Prefab();
		this.add(Keyboard);
	}
}
