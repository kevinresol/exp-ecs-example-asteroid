package asteroid.prefab;

import asteroid.component.*;
import asteroid.data.*;
import exp.ecs.*;
import exp.ecs.component.*;
import exp.ecs.module.transform.component.*;
import exp.ecs.module.graphics.component.*;
import exp.ecs.module.geometry.component.*;
import exp.ecs.module.physics.component.*;

abstract ShipWreck(Prefab) to Prefab {
	public static var inst(get, null):ShipWreck;

	static function get_inst() {
		if (inst == null)
			inst = new ShipWreck();
		return inst;
	}

	function new() {
		this = new Prefab();
		this.add(Name, 'ShipWreck');
		this.add(Transform2);
		this.add(Velocity2, 0, 0);
		this.add(AngularVelocity2, 0);
		this.add(Color, 0xffffffff);
	}

	public function spawn(world, x, y, r, vx:Float, vy:Float) {
		final splitSpeed = 20;
		final splitAngle = Math.atan2(vy, vx) + Math.PI / 2;
		final sin = Math.sin(splitAngle);
		final cos = Math.cos(splitAngle);
		final impact = 0.2;

		final v = Math.sqrt(vx * vx + vy * vy);

		final right = this.spawn(world);
		right.add(Polygon, [{x: 15., y: 0.}, {x: -8., y: 8.}, {x: -4., y: 0.}]);
		right.get(AngularVelocity2).value = (Math.random() + 1) * v * 0.01;
		final vel = right.get(Velocity2);
		vel.x = vx * impact + splitSpeed * cos;
		vel.y = vy * impact + splitSpeed * sin;
		final transform = right.get(Transform2);
		transform.position.set(x, y);
		transform.rotation = r;

		final left = this.spawn(world);
		left.add(Polygon, [{x: 15., y: 0.}, {x: -4., y: 0.}, {x: -8., y: -8.}]);
		left.get(AngularVelocity2).value = -(Math.random() + 1) * v * 0.01;
		final vel = left.get(Velocity2);
		vel.x = vx * impact - splitSpeed * cos;
		vel.y = vy * impact - splitSpeed * sin;
		final transform = left.get(Transform2);
		transform.position.set(x, y);
		transform.rotation = r;
	}
}
