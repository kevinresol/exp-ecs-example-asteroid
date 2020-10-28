package;

import exp.ecs.*;
import exp.ecs.module.transform.component.*;
import exp.ecs.module.geometry.component.*;
import exp.ecs.module.graphics.component.*;
import exp.ecs.module.input.component.*;
import exp.ecs.module.physics.component.*;
import exp.ecs.module.transform.system.*;
import exp.ecs.module.geometry.system.*;
import exp.ecs.module.graphics.system.*;
import exp.ecs.module.input.system.*;
import exp.ecs.module.physics.system.*;
import asteroid.prefab.*;

class Main {
	static final WIDTH = 1024;
	static final HEIGHT = 768;

	static function main() {
		kha.System.start({
			title: "Asteroid",
			width: WIDTH,
			height: HEIGHT,
			framebuffer: {samplesPerPixel: 4}
		}, _ -> {
			// Just loading everything is ok for small projects
			kha.Assets.loadEverything(() -> {
				final engine = new exp.ecs.Engine();
				final world = engine.worlds.create([
					Input, //
					{id: FixedUpdate, type: FixedTimestep(1 / 100)}, //
					Update, //
					Render, //
				]);

				// entities
				final input = PlayerInput.inst.spawn(world);
				final keyboard = input.get(Keyboard);
				final ship = Ship.inst.spawn(world, 200, 200);
				final force = ship.get(Force2);
				final velocity = ship.get(Velocity2);
				final angular = ship.get(AngularVelocity2);
				final transform = ship.get(Transform2);

				final muzzle = new hxmath.math.Vector3(15, 0, 1);

				// systems
				world.pipeline.add(Input, new CaptureKeyboardInput(CaptureKeyboardInput.getSpec()));
				world.pipeline.add(Input, System.simple( //
					'ControlShip', //
					_ -> {
						final up = keyboard.isDown.get(Up);
						final down = keyboard.isDown.get(Down);
						final left = keyboard.isDown.get(Left);
						final right = keyboard.isDown.get(Right);

						angular.value = if ((!left && !right) || (left && right)) 0 else if (right) 5 else -5;
						force.setWithRotation(if ((!up && !down) || (up && down)) 0 else if (down) -100 else 100, transform.rotation);

						final space = keyboard.justDown.get(Space);
						if (space) {
							final muzzle = transform.global * muzzle;
							Bullet.inst.spawn(world, muzzle.x, muzzle.y, transform.rotation, velocity.x, velocity.y);
						}
					}));
				world.pipeline.add(FixedUpdate, new ApplyForce2(ApplyForce2.getSpec()));
				world.pipeline.add(FixedUpdate, new Move2(Move2.getSpec()));
				world.pipeline.add(FixedUpdate, new Rotate2(Rotate2.getSpec()));
				world.pipeline.add(FixedUpdate, System.single( //
					'WrapEdges', @:component(transform) Transform2, //
					(nodes, dt) -> for (node in nodes) {
						final pos = node.components.transform.position;
						if (pos.x < 0)
							pos.x += WIDTH;
						if (pos.x > WIDTH)
							pos.x -= WIDTH;
						if (pos.y < 0)
							pos.y += HEIGHT;
						if (pos.y > HEIGHT)
							pos.y -= HEIGHT;
					}));

				world.pipeline.add(FixedUpdate, new ComputeLocalTransform2(ComputeLocalTransform2.getSpec()));
				world.pipeline.add(FixedUpdate, new ComputeGlobalTransform2(ComputeGlobalTransform2.getSpec()));

				final renderer1 = new RenderGeometry2(RenderGeometry2.getSpec());
				world.pipeline.add(Render, renderer1);
				final renderer2 = new RenderFps(kha.Assets.fonts.kenney_mini, 10, 10);
				world.pipeline.add(Render, renderer2);
				final renderer3 = new RenderDebug(kha.Assets.fonts.kenney_mini, 10, 30);
				world.pipeline.add(Render, renderer3);

				// game loop
				var time = kha.Scheduler.time();
				kha.System.notifyOnFrames(frames -> {
					final f = frames[0];
					final g2 = f.g2;
					renderer1.frame = renderer2.frame = renderer3.frame = f; // I don't like this way of passing the frame to the render system

					final now = kha.Scheduler.time();
					final dt = now - time;

					g2.begin(true, kha.Color.fromBytes(0, 95, 106));
					g2.end();

					engine.update(dt);
					time = now;
				});
			});
		});
	}
}

enum abstract Phase(Int) to Int {
	var Input;
	var FixedUpdate;
	var Update;
	var Render;
}
