package asteroid.prefab;

import asteroid.component.*;
import asteroid.data.*;
import exp.ecs.*;
import exp.ecs.component.*;
import exp.ecs.module.transform.component.*;
import exp.ecs.module.graphics.component.*;
import exp.ecs.module.geometry.component.*;
import exp.ecs.module.physics.component.*;

abstract Ship(Prefab) to Prefab {
	public static var inst(get, null):Ship;

	static function get_inst() {
		if (inst == null)
			inst = new Ship();
		return inst;
	}

	function new() {
		this = new Prefab();
		this.add(Name, 'Ship');
		this.add(ShipTag);
		this.add(Mass, 1);
		this.add(Transform2, -Math.PI / 2);
		this.add(Velocity2, 0, 0);
		this.add(Force2, 0, 0);
		this.add(AngularVelocity2, 0);
		this.add(Polygon, [{x: 15., y: 0.}, {x: -8., y: 8.}, {x: -4., y: 0.}, {x: -8., y: -8.}]);
		this.add(Color, 0xffffffff);
		this.add(HitCircle, 6);
		this.add(Collider, CollisionMask.Ship, CollisionMask.Asteroid);
	}

	public function spawn(world, x, y) {
		final entity = this.spawn(world);
		entity.get(Transform2).position.set(x, y);
		return entity;
	}
}
