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
import ttgl.graphics.renderer;
import ttgl.graphics.camera;
import ttgl.graphics.util;
import ttgl.graphics.primitives;

debug {
	import std.file : getcwd, dirEntries, SpanMode;
}

Window window;
Window.Size ws = { 800, 600 };

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

	if(DerelictGL3.loadedVersion < GLVersion.GL40) {
		writeln("OpenGL 4.0 or better is required");
		return 1;
	}

	// Window
	//##########################
	write("Creating main window... ");
	// Just getting some living space here
	window = new Window(ws.width, ws.height, APPNAME ~ " - Oh my!");
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

	// Data
	//##########################
	RandomCubes rc = new RandomCubes(FIELD, 1024, vec3(0));

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
	// Debug
	GLuint query;
	glGenQueries(1, &query);
	

	//####################################################
	// Screen
	//####################################################
	// aka pretty much the same as above

	Framebuffer screen = new Framebuffer(ws.width, ws.height);
	Camera cam = screen.camera;

	//##################################
	//##################################
	// Input handler

	window.onWindowResize = (int width, int height) {
		screen.resize(width,height);
	};

	window.onKey = (int key, int scancode, int action, int mod) {
		import glfw.glfw3;

		switch(action) {
			case GLFW_PRESS:
				switch(key) {
					case GLFW_KEY_W:
						cam.velocity.z--;
						break;
					case GLFW_KEY_S:
						cam.velocity.z++;
						break;
					case GLFW_KEY_D:
						cam.velocity.x++;
						break;
					case GLFW_KEY_A:
						cam.velocity.x--;
						break;
					case GLFW_KEY_SPACE:
						cam.velocity.y++;
						break;
					case GLFW_KEY_C:
						cam.velocity.y--;
						break;
					case GLFW_KEY_ESCAPE:
						if(window.onCursorMove is null)
							window.close();
						else {
							window.onCursorMove = null;
							window.cursorMode = Window.CursorMode.NORMAL;
						}
						break;
					case GLFW_KEY_TAB:
						static int e;
						if(++e > 5) e = 0;
						glUniform1i(glGetUniformLocation(screen.program, "effectFlag"), e);
						break;
					default:
				}
				goto case;
			case GLFW_REPEAT:
				switch(key) {
					case GLFW_KEY_E:
						cam.roll(1.rad);
						break;
					case GLFW_KEY_Q:
						cam.roll(-1.rad);
						break;
					default:
				}
				break;
			case GLFW_RELEASE:
				switch(key) {
					case GLFW_KEY_W:
						cam.velocity.z++;
						break;
					case GLFW_KEY_S:
						cam.velocity.z--;
						break;
					case GLFW_KEY_D:
						cam.velocity.x--;
						break;
					case GLFW_KEY_A:
						cam.velocity.x++;
						break;
					case GLFW_KEY_SPACE:
						cam.velocity.y--;
						break;
					case GLFW_KEY_C:
						cam.velocity.y++;
						break;
					default:
				}
				break;
			default:
		}
	};

	window.onMouseButton = (int key, int action, int mod) {
		import glfw.glfw3;
		if(action == GLFW_PRESS && window.onCursorMove is null) {
			window.onCursorMove = &cam.mouse;
			window.cursorMode = Window.CursorMode.DISABLED;
		}
	};

	window.onCursorMove = &cam.mouse;
	window.presentInterval = 0;

	// Initialising frame counter
	static bool slowDown = true;
	static const float goodSPF = 1f / 120f; // 60 frames in 1 second (1k ms)
	float totalTime = 0;
	uint totalFrames = 0;
	ulong tickSeconds = Clock.currAppTick.seconds;

	writeln("Entering main loop...");
	while(window.isOpen) {
		float time = getAppTime();
		//##############
		screen.bind();
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// Scene
		//##########################
		/*/
		foreach(uint i, ref t; tex) {
			glActiveTexture(GL_TEXTURE0 +i);
			glBindTexture(GL_TEXTURE_2D, t);
		}
		//*/

		glEnable(GL_DEPTH_TEST);
		glEnable(GL_CULL_FACE);
		//glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

		glBeginQuery(GL_SAMPLES_PASSED, query);

		rc.model = quat.axis_rotation(180*sin(rad(time)), vec3(0.0f, 0.0f, 1.0f)).to_matrix!(4,4);
		screen.render(rc);

		glEndQuery(GL_SAMPLES_PASSED);

		//glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		// Screen
		//##########################
		screen.draw();

		//##############
		// Spit it out
		window.present();

		float dt = getAppTime() - time; // Delta time

		// and wait for more to come
		window.pollEvents();

		totalFrames++; // +1 Frame
		totalTime += dt;

		cam.moveUpdate(500*dt);

		GLuint samples;
		glGetQueryObjectuiv(query, GL_QUERY_RESULT, &samples);

		if(Clock.currAppTick.seconds != tickSeconds) {
			window.title = std.string.format(TITLE_FORMAT, APPNAME, totalFrames, totalTime / totalFrames * 1000f, samples);

			tickSeconds = Clock.currAppTick.seconds;
			totalTime = 0;
			totalFrames = 0;
		}
		if(slowDown && dt < goodSPF) {
			Thread.getThis.sleep(lrint((goodSPF-dt)*1000.0).msecs); // Zzz..
		}
	}

	writeln("Exiting...");
	// Don't forget the scopes! ^
	return 0;
}


debug {
	import ttgl.graphics.error;
	// In case shit hits the fan
	extern(C) nothrow
	void glError_cb(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(GLchar)* message, GLvoid* userParam) {
		try {
			stderr.writeln("[",getAppTime(),"] ","glError:");
			stderr.write("\tID: ", id, ", ");
			stderr.write("Source: ", GL.Debug[source], ", ");
			stderr.write("Type: ", GL.Debug[type], ", ");
			stderr.writeln("Severity: ", GL.Debug[severity]);
			stderr.writeln("\t", text(message));
			stderr.flush();
			stderr.writeln("Stack trace:");
			stderr.writeln(saneStackTrace());
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