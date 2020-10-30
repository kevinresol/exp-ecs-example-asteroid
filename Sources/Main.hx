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
import asteroid.component.*;

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
					PreFixedUpdate, //
					{id: FixedUpdate, type: FixedTimestep(1 / 100)}, //
					Update, //
					Render, //
				]);

				// entities
				final input = PlayerInput.inst.spawn(world);
				final keyboard = input.get(Keyboard);
				final ship = Ship.inst.spawn(world, WIDTH / 2, HEIGHT / 2);
				final force = ship.get(Force2);
				final velocity = ship.get(Velocity2);
				final angular = ship.get(AngularVelocity2);
				final transform = ship.get(Transform2);

				var count = 10;
				while (count > 0) {
					final x = Std.random(WIDTH);
					final y = Std.random(HEIGHT);
					if (x > WIDTH / 4 && x < WIDTH * 3 / 4 && y > HEIGHT / 4 && y < HEIGHT * 3 / 4) {
						continue;
					} else {
						Asteroid.inst.spawn(world, x, y, Std.random(20) + 40);
						count--;
					}
				}

				final muzzle = new hxmath.math.Vector3(15, 0, 1);

				// systems
				world.pipeline.add(Input, new CaptureKeyboardInput());
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
						if (space && !ship.removed) {
							final muzzle = transform.global * muzzle;
							Bullet.inst.spawn(world, muzzle.x, muzzle.y, transform.rotation, velocity.x, velocity.y);
						}
					}));

				world.pipeline.add(PreFixedUpdate, new ResetCollisions());
				world.pipeline.add(FixedUpdate, new ApplyForce2());
				world.pipeline.add(FixedUpdate, new Move2());
				world.pipeline.add(FixedUpdate, new Rotate2());
				world.pipeline.add(FixedUpdate, System.single( //
					'WrapEdges', @:component(transform) Transform2, //
					(nodes, dt) -> for (node in nodes) {
						final transform = node.data.transform;
						final global = transform.global;
						final local = node.data.transform.position;
						if (global.tx < 0)
							local.x += WIDTH;
						if (global.tx > WIDTH)
							local.x -= WIDTH;
						if (global.ty < 0)
							local.y += HEIGHT;
						if (global.ty > HEIGHT)
							local.y -= HEIGHT;
					}));

				world.pipeline.add(FixedUpdate, new ComputeLocalTransform2());
				world.pipeline.add(FixedUpdate, new ComputeGlobalTransform2());
				world.pipeline.add(FixedUpdate, new DetectCollision2(WIDTH, HEIGHT, 5, 5));

				world.pipeline.add(Update, exp.ecs.System.single( //
					'HandleBulletCollision', @:component(null) BulletTag && Collider, //
					(nodes, dt) -> for (node in nodes)
						switch node.data.collider.hits {
							case []:
							case hits:
								for (id in hits) {
									switch world.entities.get(id) {
										case null:
										case asteroid: switch asteroid.get(Health) {
												case null:
												case health:
													health.value -= 1;
													if (health.value <= 0) {
														world.entities.remove(id);
														switch [asteroid.get(HitCircle), asteroid.get(Transform2)] {
															case [null, _] | [_, null]:
															case [{radius: radius}, {global: transform}]:
																if (radius > 20) {
																	// split
																	final asteroid = Asteroid.inst.spawn(world, transform.tx + 2, transform.ty, radius / 2);
																	final asteroid = Asteroid.inst.spawn(world, transform.tx - 2, transform.ty, radius / 2);
																}
														}
													}
											}
									}
								}
								world.entities.remove(node.entity.id);
						}));
				world.pipeline.add(Update, exp.ecs.System.single( //
					'HandleShipCollision', @:component(null) ShipTag && Collider && @:component(transform) Transform2 && @:component(velocity) Velocity2, //
					(nodes, dt) -> for (node in nodes)
						switch node.data.collider.hits {
							case []:
							case hits:
								final transform = node.data.transform;
								final velocity = node.data.velocity;
								ShipWreck.inst.spawn(world, transform.position.x, transform.position.y, transform.rotation, velocity.x, velocity.y);
								world.entities.remove(node.entity.id);
						}));
				world.pipeline.add(Update, exp.ecs.System.single( //
					'HandleTTL', @:component(ttl) TimeToLive, //
					(nodes, dt) -> for (node in nodes)
						if ((node.data.ttl.value -= dt) <= 0)
							world.entities.remove(node.entity.id)));

				final renderers:Array<{frame:kha.Framebuffer}> = [];
				function addRenderer(renderer) {
					renderers.push(renderer);
					return renderer;
				}

				world.pipeline.add(Render, cast addRenderer(new RenderGeometry2()));

				final renderer = addRenderer({frame: null});
				world.pipeline.add(Render, exp.ecs.System.single( //
					'RenderHealthBar', @:component(circle) HitCircle && Health && @:component(transform) Transform2, //
					(nodes, dt) -> {
						final g2 = renderer.frame.g2;
						g2.begin(false);
						g2.transformation.setFrom(kha.math.FastMatrix3.identity());
						for (node in nodes) {
							final health = node.data.health;
							final ratio = health.value / health.max;
							if (ratio < 1) {
								final radius = node.data.circle.radius;
								final length = 1.6 * radius;
								final transform = node.data.transform;
								final x = transform.global.tx - length / 2;
								var y = transform.global.ty - radius - 10;
								if (y < 0)
									y = transform.global.ty + radius + 10;
								g2.drawRect(x, y, length, 6, 2);
								g2.fillRect(x, y, length * ratio, 6);
							}
						}
						g2.end();
					}));
				world.pipeline.add(Render, cast addRenderer(new RenderFps(kha.Assets.fonts.kenney_mini, 10, 10)));
				world.pipeline.add(Render, cast addRenderer(new RenderDebug(kha.Assets.fonts.kenney_mini, 10, 30)));

				// game loop
				var time = kha.Scheduler.time();
				kha.System.notifyOnFrames(frames -> {
					final f = frames[0];
					final g2 = f.g2;
					for (renderer in renderers)
						renderer.frame = f; // I don't like this way of passing the frame to the render system

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
	var PreFixedUpdate;
	var FixedUpdate;
	var Update;
	var Render;
}
