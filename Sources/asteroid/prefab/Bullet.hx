package asteroid.prefab;

import asteroid.data.*;
import asteroid.component.*;
import exp.ecs.*;
import exp.ecs.module.transform.component.*;
import exp.ecs.module.graphics.component.*;
import exp.ecs.module.geometry.component.*;
import exp.ecs.module.physics.component.*;

abstract Bullet(Prefab) to Prefab {
	public static final MUZZLE_SPEED = 500;
	public static var inst(get, null):Bullet;

	static function get_inst() {
		if (inst == null)
			inst = new Bullet();
		return inst;
	}

	function new() {
		this = new Prefab();
		this.add(BulletTag);
		this.add(Transform2);
		this.add(Velocity2, 0, 0);
		this.add(Circle, 1);
		this.add(HitCircle, 1);
		this.add(Color, 0xffffffff);
		this.add(Collider, CollisionMask.Bullet, CollisionMask.Asteroid);
		this.add(TimeToLive, 1);
	}

	public function spawn(world, x, y, r, vx, vy) {
		final entity = this.spawn(world);
		entity.get(Transform2).position.set(x, y);
		entity.get(Velocity2).set(vx + MUZZLE_SPEED * Math.cos(r), vy + MUZZLE_SPEED * Math.sin(r));
		return entity;
	}
}
