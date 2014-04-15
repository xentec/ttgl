import core.thread: Thread;
import core.memory;
import core.runtime;

import std.array : split;
import std.conv : text;
import std.datetime;
import std.math;
import std.random;
import std.stdio;
import std.string : chop, _0 = toStringz, format;

import derelict.opengl3.gl3;
import gl3n.linalg;

import ttgl.global;
import ttgl.util;
import ttgl.graphics.window;
import ttgl.graphics.screen;
import ttgl.graphics.camera;
import ttgl.graphics.util;
import ttgl.graphics.primitives;

debug {
	import std.file : getcwd, dirEntries, SpanMode;
}

Window window;

int main(string[] args) {
	writeln(APPNAME, " ", VERSION.major, ".", VERSION.minor);
	debug(5) {
		writeln("==============================");
		writeln("Arguements: ", args);
		writeln("==============================");
		writeln("Environment: ");
		foreach(k, env; std.process.environment.toAA()) {
			write("\t", k, ": ");
			if(k == "PATH") {
				writeln("\\");
				foreach(ref path; env.split(":"))
					writeln("\t\t", path);
			}
			else
				writeln(env);
		}
		writeln("==============================");
		writeln(getcwd());
		foreach (name; dirEntries(".", SpanMode.shallow))
			writeln("\t", name);
		writeln("==============================");
	}

	// Don't forget to say good bye (scopes are executed in reverse order)
	scope(success) writeln("Have a nice day!");
	scope(failure) writeln("._.");

	writeln("Initializing... ");

	if(DerelictGL3.loadedVersion < GLVersion.GL32) {
		writeln("OpenGL 3.2 or better is required");
		return 1;
	}

	// Window
	//##########################
	write("Creating main window... ");
	// Just getting some living space here
	window = new Window(800, 600, APPNAME ~ " - Oh my!");
	try {
		window.open();
		writeln("DONE");
	} catch(WindowException e) {
		writeln("FAILED: ", e.msg);		// Not as wrong as above, but wrong enough
		return 0;
	}

	debug {
		glDebugMessageCallback(&glError_cb, null);
		glEnable(GL_DEBUG_OUTPUT);
	}
	//##################################
	//##################################

	//####################################################
	// Scene
	//####################################################
	// Create our Vertex Array Object
	GLuint sceneVAO;
	glGenVertexArrays(1, &sceneVAO);
	scope(exit) glDeleteVertexArrays(1, &sceneVAO);
	glBindVertexArray(sceneVAO);

	// Data
	//##########################
	Cube cube;

	// Buffers
	//##########################
	writeln("Filling buffers...");
	// Create vertex buffes to hold our vertices
	GLuint sceneVBO;
	glGenBuffers(1, &sceneVBO);
	scope(exit) glDeleteBuffers(1, &sceneVBO);
	glBindBuffer(GL_ARRAY_BUFFER, sceneVBO);
	// Upload the vertices
	glBufferData(GL_ARRAY_BUFFER, cube.vertices.sizeof + cube.colors.sizeof, cube.vertices.ptr, GL_STATIC_DRAW);
	glBufferSubData(GL_ARRAY_BUFFER, cube.vertices.sizeof, cube.colors.sizeof, cube.colors.ptr);

	/*/ Verify
	debug printBuffer!(float)("sceneVBO", GL_ARRAY_BUFFER, 0, cube.vertices.length, 3);
	debug printBuffer!(ubyte)("sceneVBOc", GL_ARRAY_BUFFER, cube.vertices.sizeof, cube.colors.length, 4);
	//*/

	GLuint sceneIBO;
	glGenBuffers(1, &sceneIBO);
	scope(exit) glDeleteBuffers(1, &sceneIBO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, sceneIBO);
	// Upload the indices
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, cube.indices.sizeof, cube.indices.ptr, GL_STATIC_DRAW);

	/*/ Verify
	debug printBuffer!(byte)("sceneIBO", GL_ELEMENT_ARRAY_BUFFER, 0, 36, 6);
	//*/

	// Transformations
	//##########################
	// Enter the Matrix!
	mat4 model = mat4.identity;
	mat4 view = mat4.look_at(vec3(-10f, -10f, 5.0f), vec3(-10f, -10f, 5.0f) + vec3(1, 1, 0), vec3(0.0f, 0.0f, 1.0f));
	mat4 proj = mat4.perspective(800f, 600f, 90.0f, 1.0f, 512.0f);

	Camera cam = new Camera(vec3(10f, 10f, 10.0f));

	// Program
	//##########################
	GLint[string] program;
	program["scene"] = createProgram(import("scene.v.glsl"), import("scene.f.glsl"));
	//program["normals"] = createProgram(import("normals.v.glsl"), import("normals.f.glsl"), import("normals.g.glsl"));

	scope(exit)
		foreach(prog; program)
			glDeleteProgram(prog);

	foreach(name, prog; program) {

		glUseProgram(prog);
		// Vertices
		//##########################
		{
			// Tell our vertex shader how to use the vertices from our VBO
			GLint position = glGetAttribLocation(prog, "base");
			glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 0, null);
			glEnableVertexAttribArray(position);

			GLint color = glGetAttribLocation(prog, "color");
			glVertexAttribPointer(color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, cast(void*) cube.vertices.sizeof);
			glEnableVertexAttribArray(color);
		}

		GLint uniModel = glGetUniformLocation(prog, "model");
		glUniformMatrix4fv(uniModel, 1, GL_TRUE, model.value_ptr);

		GLint uniView = glGetUniformLocation(prog, "view");
		glUniformMatrix4fv(uniView, 1, GL_TRUE, view.value_ptr);

		GLint uniProj = glGetUniformLocation(prog, "proj");
		glUniformMatrix4fv(uniProj, 1, GL_TRUE, proj.value_ptr);


		// Misc
		//##########################
		//GLint uniColor = glGetUniformLocation(sceneProgram, "overrideColor");
		GLint uniRowLength = glGetUniformLocation(prog, "rowLength");
		glUniform1i(uniRowLength, FIELD);
		GLint uniSeed = glGetUniformLocation(prog, "seed");
		glUniform1i(uniSeed, 1);
		//	GLint uniSeed = glGetUniformLocation(sceneProgram, "seed");
		//	glUniform(uniSeed, unpredictableSeed);
	}

	/*/ Textures
		//##########################
		// Prepare to load images
		write("Loading images... ");

	// Texture files
	string[] textures = [ "cat.png", "scenery.jpg" ];

	GLuint[] tex;
	tex.length = textures.length;

	writeln(textures.length);
	foreach(uint i, ref string file; textures) {
		string name = file.split(".")[0];
		write("\t" ,i , ": ", name, "... \t");

		// Load
		glActiveTexture(GL_TEXTURE0+i);
		tex[i] = createTexture(file);
		// and link.
		glUniform1i(glGetUniformLocation(sceneProgram, name._0), i);
	}
	// Clean textures when exiting
	scope(exit)
		foreach(ref t;tex)
			glDeleteTextures(1, &t);
	//*/

	//####################################################
	// Screen
	//####################################################
	// aka pretty much the same as above
	Window.Size ws = window.getSize;
	Screen screen = new Screen(ws.width,ws.height);

	//##################################
	//##################################
	// Input handler

	window.onWindowResize = (int width, int height) {
		glViewport(0, 0, width, height);
		screen.resize(width,height);
		proj = mat4.perspective(width, height, 70.0f, 1.0f, 512.0f);
	};

	window.onKey = (int key, int scancode, int action, int mods) {
		import glfw.glfw3;
		if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) // Make it close itself on ESC
			window.close();
		if(key == GLFW_KEY_TAB && action == GLFW_PRESS) {
			static int e = 0;
			if(++e > 5) e = 0;
			glUniform1i(glGetUniformLocation(screen.program, "effectFlag"), e);
		}
		switch(action) {
			case GLFW_PRESS:
			case GLFW_REPEAT:
				switch(key) {
					case GLFW_KEY_W:
						cam.moveForward();
						break;
					case GLFW_KEY_S:
						cam.moveBackward();
						break;
					case GLFW_KEY_D:
						cam.moveRight();
						break;
					case GLFW_KEY_A:
						cam.moveLeft();
						break;
					case GLFW_KEY_SPACE:
						cam.moveUp();
						break;
					case GLFW_KEY_LEFT_SHIFT:
						cam.moveDown();
						break;

					case GLFW_KEY_E:
						cam.roll(1.rad);
						break;
					case GLFW_KEY_Q:
						cam.roll(-1.rad);
						break;

					case GLFW_KEY_UP:
						cam.pitch(1.rad);
						break;
					case GLFW_KEY_DOWN:
						cam.pitch(-1.rad);
						break;
					case GLFW_KEY_RIGHT:
						cam.yaw(-1.rad);
						break;
					case GLFW_KEY_LEFT:
						cam.yaw(1.rad);
						break;
					default:
				}
				break;
			default:
				break;
		}
	};

	window.onCursorMove = &cam.mouse;

	// Initialising frame counter
	static bool slowDown = true;
	static float goodSPF = 1f / 120f; // 60 frames in 1 second (1k ms)
	float totalTime = 0;
	uint totalFrames = 0;
	ulong tickSeconds = Clock.currAppTick.seconds;

	glViewport(0, 0, 800, 600);
	window.presentInterval = 0;

	writeln("Entering main loop...");

	while(window.isOpen) {
		float time = getAppTime();
		//##############
		screen.bind();
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// Scene
		//##########################
		glBindVertexArray(sceneVAO);

		/*/
		foreach(uint i, ref t; tex) {
			glActiveTexture(GL_TEXTURE0 +i);
			glBindTexture(GL_TEXTURE_2D, t);
		}
		//*/

		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
		//glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

		foreach(prog; program) {
			glUseProgram(prog);
			// Rotate it
			glUniformMatrix4fv(glGetUniformLocation(prog, "model"), 1, GL_TRUE, quat.axis_rotation(rad(time*25f), vec3(0.0f, 0.0f, 1.0f)).to_matrix!(4,4).value_ptr);

			//cam.rotate(rad(time), vec3(0.0f, 0.0f, 1.0f));
			glUniformMatrix4fv(glGetUniformLocation(prog, "view"), 1, GL_TRUE, cam.matrix().value_ptr);

			// Draw the cube array
			glDrawElementsInstanced(GL_TRIANGLES, 36, GL_UNSIGNED_BYTE, cast(void*) 0, FIELD^^2);
		}

		//glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		// Screen
		//##########################
		screen.draw();

		//##############
		// Spit it out
		window.present();
		// and wait for more to come
		window.pollEvents();

		float SPF = getAppTime() - time;
		totalFrames++; // +1 Frame
		totalTime += SPF;

		if(Clock.currAppTick.seconds != tickSeconds) {
			float avrTime = totalTime / totalFrames * 1000f;
			window.title = std.string.format(TITLE_FORMAT, APPNAME, totalFrames, avrTime);

			tickSeconds = Clock.currAppTick.seconds;
			totalTime = 0;
			totalFrames = 0;
		}
		if(slowDown && SPF < goodSPF) {
			Thread.getThis.sleep(lrint((goodSPF-SPF)*1000f).msecs); // Zzz..
		}
	}

	writeln("Exiting...");
	// Don't forget the scopes! ^
	return 0;
}


static this() {
	debug {
		GLErrors = [
			// Source
			GL_DEBUG_SOURCE_API: "API",
			GL_DEBUG_SOURCE_WINDOW_SYSTEM: "Window System",
			GL_DEBUG_SOURCE_SHADER_COMPILER: "Shader Compiler",
			GL_DEBUG_SOURCE_THIRD_PARTY: "Third Party",
			GL_DEBUG_SOURCE_APPLICATION: "Application",
			GL_DEBUG_SOURCE_OTHER: "Other",
			// Type
			GL_DEBUG_TYPE_ERROR: "Error",
			GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: "Deprecated",
			GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR: "Undefined",
			GL_DEBUG_TYPE_PORTABILITY: "Portability",
			GL_DEBUG_TYPE_PERFORMANCE: "Performance",
			GL_DEBUG_TYPE_OTHER: "Other",
			GL_DEBUG_TYPE_MARKER: "Marker",
			// Severity
			GL_DEBUG_SEVERITY_HIGH: "High",
			GL_DEBUG_SEVERITY_MEDIUM: "Medium",
			GL_DEBUG_SEVERITY_LOW: "Low",
			GL_DEBUG_SEVERITY_NOTIFICATION: "Notify",
		];
	}
}

debug {
	static immutable string[GLenum] GLErrors;

	// In case shit hits the fan
	extern(C) nothrow
	void glError_cb(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(GLchar)* message, GLvoid* userParam) {
		try {
			stderr.writeln("[",getAppTime(),"] ","glError:");
			stderr.write("\tID: ", id, ", ");
			stderr.write("Source: ", GLErrors[source], ", ");
			stderr.write("Type: ", GLErrors[type], ", ");
			stderr.writeln("Severity: ", GLErrors[severity]);
			stderr.writeln("\t", text(message));
			stderr.flush();
			stderr.writeln("Stack trace:");
			stderr.writeln(defaultTraceHandler());
			stderr.flush();
			if(severity == GL_DEBUG_SEVERITY_HIGH)
				window.close();
		} catch (Throwable e) {
			try 
				stdout.writeln("GLDEBUGPROC has thrown exception: ", e);
			catch(Throwable e2) {}
		}
	};
}