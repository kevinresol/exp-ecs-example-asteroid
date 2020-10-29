package asteroid.data;

enum abstract CollisionMask(Int) to Int {
	var None = 0x0000;
	var Bullet = 0x0001;
	var Asteroid = 0x0002;
	var Ship = 0x0004;
}
