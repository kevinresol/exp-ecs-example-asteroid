Project.prototype.addLixLibrary = function(name) {
	let exec = require("child_process").execSync;
	let buffer;
	for (line of exec(`haxe --run resolve-args -lib ${name}`).toString().split("\n")) {
		if (line.charAt(0) == "-") {
			if (buffer) this.addParameter(buffer);
			buffer = line;
		} else {
			buffer += " " + line;
		}
	}
	if (buffer) this.addParameter(buffer);
}

let project = new Project("Asteroid");

project.windowOptions.width = 1024;
project.windowOptions.height = 768;

project.addLixLibrary("exp-ecs-module-transform");
project.addLixLibrary("exp-ecs-module-geometry");
project.addLixLibrary("exp-ecs-module-graphics");
project.addLixLibrary("exp-ecs-module-physics");
project.addLixLibrary("exp-ecs-module-input");

project.addAssets("Assets/**");
project.addShaders("Shaders/**");
project.addSources("Sources");
project.addParameter("-D HXMATH_USE_KHA_STRUCTURES");
project.addParameter("-D analyzer-optimize");
project.addParameter("-dce full");
resolve(project);
