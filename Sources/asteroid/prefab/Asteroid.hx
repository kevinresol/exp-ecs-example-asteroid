package asteroid.prefab;

import asteroid.data.*;
import asteroid.component.*;
import exp.ecs.*;
import exp.ecs.component.*;
import exp.ecs.module.transform.component.*;
import exp.ecs.module.graphics.component.*;
import exp.ecs.module.geometry.component.*;
import exp.ecs.module.physics.component.*;

abstract Asteroid(Prefab) to Prefab {
	public static var inst(get, null):Asteroid;

	static function get_inst() {
		if (inst == null)
			inst = new Asteroid();
		return inst;
	}

	function new() {
		this = new Prefab();
		this.add(Name, 'Asteriod');
		this.add(Mass, 1);
		this.add(Transform2);
		this.add(Velocity2, 0, 0);
		this.add(Force2, 0, 0);
		this.add(AngularVelocity2, 0);
		this.add(Polygon, []);
		this.add(HitCircle, 0);
		this.add(Color, 0xffffffff);
		this.add(Collider, CollisionMask.Asteroid, CollisionMask.None);
		this.add(Health, 10, 10);
	}

	public function spawn(world, x, y, radius:Float) {
		final entity = this.spawn(world);
		entity.get(Transform2).position.set(x, y);
		entity.get(AngularVelocity2).value = randomSign(Math.random() * 0.8 + 0.2);
		final speedMultiplier = 50 / radius;
		entity.get(Velocity2).set(speedMultiplier * randomSign(Std.random(10) + 5), speedMultiplier * randomSign(Std.random(10) + 5));
		entity.get(HitCircle).radius = radius;
		final vertices = entity.get(Polygon).vertices;
		var angle = 0.;
		while (angle < Math.PI * 2) {
			final length = (0.75 + Math.random() * 0.25) * radius;
			vertices.push({x: Math.cos(angle) * length, y: Math.sin(angle) * length});
			angle += Math.random() * 0.5;
		}

		return entity;
	}

	inline function randomSign(v:Float) {
		return v * (Math.random() > 0.5 ? -1 : 1);
	}
}
