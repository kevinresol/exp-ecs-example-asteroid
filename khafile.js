let project = new Project("Asteroid");

project.windowOptions.width = 1024;
project.windowOptions.height = 768;

function addLixLibrary(name) {
	let exec = require("child_process").execSync;
	let buffer;
	for (line of exec(`haxe --run resolve-args -lib ${name}`).toString().split("\n")) {
		if (line.charAt(0) == "-") {
			if (buffer) project.addParameter(buffer);
			buffer = line;
		} else {
			buffer += " " + line;
		}
	}
	if (buffer) project.addParameter(buffer);
}

addLixLibrary("exp-ecs-module-transform");
addLixLibrary("exp-ecs-module-geometry");
addLixLibrary("exp-ecs-module-graphics");
addLixLibrary("exp-ecs-module-physics");
addLixLibrary("exp-ecs-module-input");

project.addAssets("Assets/**");
project.addShaders("Shaders/**");
project.addSources("Sources");
project.addParameter("-D HXMATH_USE_KHA_STRUCTURES");
project.addParameter("-D analyzer-optimize");
project.addParameter("-dce full");
resolve(project);
