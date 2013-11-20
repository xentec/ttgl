

import core.thread: Thread;

import std.array : split;
import std.conv : text;
import std.datetime : Clock, Duration, dur;
import std.math;
import std.stdio;
import std.string : chop, nt = toStringz, format;

import glfw.glfw3;
import SOIL.SOIL;

import derelict.opengl3.gl3;

import gl3n.linalg;

enum string APPNAME = "TTGL";
enum int[string] VERSION = [ "major":1, "minor":0 ];
enum string PATH = "res";
enum string TITLE_FORMAT = "%s - FPS: %s%d (%.3fms)";

enum TAU = PI*2;
real rad(in real angle) { return angle*TAU/360.0; }

GLuint c_screenProgram;

int main(string[] args) {
	writeln(APPNAME, " ", VERSION["major"], ".",VERSION["minor"]);
	debug {
		writeln("==============================");
		writeln("Arguements: ");
		foreach(i, arg; args)
			writeln("\t", i,"\t", arg);
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
		import std.file : getcwd, dirEntries, SpanMode;
		writeln(getcwd());
		foreach (name; dirEntries(".", SpanMode.shallow))
			writeln("\t", name);
		writeln("==============================");
	}

	// Don't forget to say good bye (scopes are executed in reverse order)
	scope(success) writeln("Have a nice day!");
	scope(failure) writeln("._.");

	// GLFW error catcher
	__gshared string glfwError;
	GLFWerrorfun glfwError_cb = (int code, const(char)* msg) {
		glfwError = text(code, " => ", msg);
	};
	glfwSetErrorCallback(glfwError_cb);

	writeln("Initializing... ");
	if(!glfwInit()) {
		writeln("FAILED"); // Something is seriously wrong
		throw new Exception(glfwError);
	}
	// Better safe than sorry
	scope(exit) glfwTerminate();

	{ // Getting actualy OpenGL version for a more precise window creation
		// Spawn our silent spy!
		glfwWindowHint(GLFW_VISIBLE, GL_FALSE);
		GLFWwindow* test = glfwCreateWindow(50, 50, (APPNAME ~ " - GL Test!").nt, null, null);
		if(!test) { // Spy failed! Abandon ship!
			writeln("FAILED");
			throw new Exception(glfwError);
		}
		scope(exit) glfwDestroyWindow(test);

		// Lets load all symbols
		DerelictGL3.load();
		// OpenGL = on
		glfwMakeContextCurrent(test);
		// Sometimes loading everything is just not enough
		DerelictGL3.reload();

		writeln("\n", "OpenGL ", text(glGetString(GL_VERSION)),"\n");
	}

	if(DerelictGL3.loadedVersion < GLVersion.GL32) {
		writeln("OpenGL 3.2 or better is required");
		return 1;
	}

	// Window
	//##########################
	write("Creating main window... ");

	// Back to daylight
	glfwWindowHint(GLFW_VISIBLE, GL_TRUE);
	glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
	// Setting the correct context
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
	debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

	// Setting the accuracy of the buffers
	glfwWindowHint(GLFW_DEPTH_BITS, 24);
	glfwWindowHint(GLFW_STENCIL_BITS, 2);


	// Just getting some living space here
	GLFWwindow* window = glfwCreateWindow(800, 600, (APPNAME ~ " - Oh my!").nt, null, null);
	if(!window) {
		writeln("FAILED");		// Not as wrong as above, but wrong enough
		throw new Exception(glfwError);	//TODO: Build some kind of recovery
	} else
		writeln("DONE");

	// Remember to burn everything after mission
	scope(exit) {
		writeln("Destroying main window...");
		glfwDestroyWindow(window);
	}

	// Set X class hint
	version(Posix) {
		import X11.Xutil, glfw.glfw3native;
		XClassHint xch = {
			res_name: "gl", 	// aka instance
			res_class: APPNAME
		};
		XSetClassHint(glfwGetX11Display(), glfwGetX11Window(window), &xch);
	}

	// OpenGL = on
	glfwMakeContextCurrent(window);

	debug {
		// In case shit hits the fan
		GLDEBUGPROC glError_cb = (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(GLchar)* message, GLvoid* userParam) {
			try {
				stderr.writeln("[",glfwGetTime(),"] ","glError: \tSource: ", source, "; Type: ", type, "; ID: ", id, "; Severity: ", severity, "; Length: ", length, "\n"
						"\t\t", text(message), "\n",
						"\t\t", userParam);
				stderr.flush();
			} catch (Throwable e) {	}
		};
		glDebugMessageCallback(glError_cb, null);
		glEnable(GL_DEBUG_OUTPUT);
	}
	//##################################
	//##################################

	// VAOs
	//##########################
	// Create our Vertex Array Object
	GLuint sceneVAO, screenVAO;
	glGenVertexArrays(1, &sceneVAO);
	glGenVertexArrays(1, &screenVAO);
	scope(exit) glDeleteVertexArrays(1, &sceneVAO);
	scope(exit) glDeleteVertexArrays(1, &screenVAO);

	//####################################################
	// Scene
	//####################################################
	glBindVertexArray(sceneVAO);

	// Our cube
	immutable GLfloat sceneVertices[] = [
		//  Position		 Color             Texcoords
		-0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
		 0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,
		 0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		// Bottom
		 0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,
		-0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,


		-0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
		 0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,
		 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		// Top
		 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,
		-0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,


		-0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,
		-0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		-0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,

		-0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,
		-0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
		-0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,


		 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,
		 0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		 0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,

		 0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,
		 0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
		 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,


		-0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,
		 0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		 0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,

		 0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,
		-0.5f, -0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
		-0.5f, -0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,


		-0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,
		 0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f,
		 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,

		 0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f,
		-0.5f,  0.5f,  0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
		-0.5f,  0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f,



		-1.0f, -1.0f, -0.5f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
		 1.0f, -1.0f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f,
		 1.0f,  1.0f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f,

		 1.0f,  1.0f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f,
		-1.0f,  1.0f, -0.5f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f,
		-1.0f, -1.0f, -0.5f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
	];

	// Buffers
	//##########################
	// Create vertex buffes to hold our vertices
	GLuint sceneVBO;
	glGenBuffers(1, &sceneVBO);
	scope(exit) glDeleteBuffers(1, &sceneVBO);
	glBindBuffer(GL_ARRAY_BUFFER, sceneVBO);
	// Upload the vertices
	glBufferData(GL_ARRAY_BUFFER, GLfloat.sizeof * sceneVertices.length, sceneVertices.ptr, GL_STATIC_DRAW);

	// Program
	//##########################
	// Use helper functions from below
	GLuint sceneProgram = createProgram(import("scene.vert"), import("scene.frag"));
	scope(exit) glDeleteProgram(sceneProgram);

	// Setting color vector output in fragment shader to outColor
	glBindFragDataLocation(sceneProgram, 0, "outColor");

	// The device has been modified...
	glUseProgram(sceneProgram);

	// Vertices
	//##########################
	writeln("Loading vertices...");

	{
		// Tell our vertex shader how to use the vertices from our VBO
		GLint posAttrib = glGetAttribLocation(sceneProgram, "position");
		glVertexAttribPointer(posAttrib, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, null);
		glEnableVertexAttribArray(posAttrib);

		// ...and how to color them
		GLint colAttrib = glGetAttribLocation(sceneProgram, "col");
		glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*) (3 * GLfloat.sizeof));
		glEnableVertexAttribArray(colAttrib);

		// ...and how picture them
		GLint texAttrib = glGetAttribLocation(sceneProgram, "tex");
		glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*) (6 * GLfloat.sizeof));
		glEnableVertexAttribArray(texAttrib);
	}

	// Transformations
	//##########################
	debug writeln("Calculating Matrices...");
	// Enter the Matrix!
	mat4 model;
	GLuint uniModel = glGetUniformLocation(sceneProgram, "model");

	mat4 view = mat4.look_at(vec3(2.0f, 2.0f, 1.75f), vec3(0.0f, 0.0f, 0.0f), vec3(0.0f, 0.0f, 1.0f));
	GLuint uniView = glGetUniformLocation(sceneProgram, "view");
	glUniformMatrix4fv(uniView, 1, GL_TRUE, view.value_ptr);

	mat4 proj = mat4.perspective(800f, 600f, 45.0f, 1.0f, 10.0f);
	GLuint uniProj = glGetUniformLocation(sceneProgram, "proj");
	glUniformMatrix4fv(uniProj, 1, GL_TRUE, proj.value_ptr);

	// Textures
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
		glUniform1i(glGetUniformLocation(sceneProgram, name.nt), i);
	}
	// Clean textures when exiting
	scope(exit)
		foreach(ref t;tex)
			glDeleteTextures(1, &t);

	// Misc
	//##########################
	GLint uniColor = glGetUniformLocation(sceneProgram, "overrideColor");

	//####################################################
	// Screen
	//####################################################
	// aka pretty much the same as above
	glBindVertexArray(screenVAO);

	// Screen vertices
	GLfloat screenVertices[] = [
		-1.0f,  1.0f,  0.0f, 1.0f,
		 1.0f,  1.0f,  1.0f, 1.0f,
		 1.0f, -1.0f,  1.0f, 0.0f,

		 1.0f, -1.0f,  1.0f, 0.0f,
		-1.0f, -1.0f,  0.0f, 0.0f,
		-1.0f,  1.0f,  0.0f, 1.0f
	];

	// Buffers
	//##########################
	// Create vertex buffes to hold our vertices
	GLuint screenVBO;
	glGenBuffers(1, &screenVBO);
	scope(exit) glDeleteBuffers(1, &screenVBO);
	glBindBuffer(GL_ARRAY_BUFFER, screenVBO);
	// Upload the vertices
	glBufferData(GL_ARRAY_BUFFER, GLfloat.sizeof * screenVertices.length, screenVertices.ptr, GL_STATIC_DRAW);

	// Program
	//##########################
	GLuint screenProgram = createProgram(import("screen.vert"), import("screen.frag"));
	scope(exit) glDeleteProgram(screenProgram);

	glBindFragDataLocation(screenProgram, 0, "outColor");

	// The device has been modified... again!
	glUseProgram(screenProgram);
	glUniform1i(glGetUniformLocation(screenProgram, "fb"), 0);

	// Vertices
	//##########################
	{
		GLint posAttrib = glGetAttribLocation(screenProgram, "position");
		glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 4 * GLfloat.sizeof, null);
		glEnableVertexAttribArray(posAttrib);

		GLint texAttrib = glGetAttribLocation(screenProgram, "tex");
		glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 4 * GLfloat.sizeof, cast(void*) (2 * GLfloat.sizeof));
		glEnableVertexAttribArray(texAttrib);
	}

	// Framebuffer
	//##########################
	GLuint frameBuffer;
	glGenFramebuffers(1, &frameBuffer);
	scope(exit) glDeleteFramebuffers(1, &frameBuffer);

	glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);

	GLuint colorBuffer;
		glGenTextures(1, &colorBuffer);
		scope(exit) glDeleteTextures(1, &colorBuffer);

		glBindTexture(GL_TEXTURE_2D, colorBuffer);

		glTexImage2D(GL_TEXTURE_2D, 
					 0, GL_RGB, 
					 800, 600, 
					 0, GL_RGB, 
					 GL_UNSIGNED_BYTE, null);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glFramebufferTexture2D(GL_FRAMEBUFFER, 
							   GL_COLOR_ATTACHMENT0, 
							   GL_TEXTURE_2D, colorBuffer, 0);

	GLuint rboDepthStencil;
		glGenRenderbuffers(1, &rboDepthStencil);
		scope(exit) glDeleteRenderbuffers(1, &rboDepthStencil);

		glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 800, 600);

		glFramebufferRenderbuffer(GL_FRAMEBUFFER, 
							  GL_DEPTH_STENCIL_ATTACHMENT, 
							  GL_RENDERBUFFER, rboDepthStencil);

	//##################################
	//##################################
	// Input handler
	c_screenProgram = screenProgram;
	extern (C) void input_cb(GLFWwindow* window, int key, int scancode, int action, int mods) {
		if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) // Make it close itself on ESC
			glfwSetWindowShouldClose(window, GL_TRUE);
		if(key == GLFW_KEY_SPACE && action == GLFW_PRESS) {
			static int e = 0;
			if(++e > 5) e = 0;
			glUniform1i(glGetUniformLocation(c_screenProgram, "effectFlag"), e);
		}
	}
	glfwSetKeyCallback(window, &input_cb); //  Since glfw is a C library, we can't use inline function syntax

	// Resize handler
	extern (C) void resize_cb(GLFWwindow* window, int width, int height) {
		glViewport(0, 0, width, height);
	}
	glfwSetFramebufferSizeCallback(window, &resize_cb);

	// Initialising frame counter
	uint[2] frames;
	enum framesPrefix = "~+-";
	ulong tickSeconds = Clock.currAppTick.seconds;

	enum float goodSPF = 1f / 120f; // 60 frames in 1 second (1k ms)

	glfwSwapInterval(0); // Turn VSync off

	writeln("Entering main loop...");
	while(!glfwWindowShouldClose(window)) {
		float time = glfwGetTime();
		//##############

		// Scene
		//##########################
		glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
		glBindVertexArray(sceneVAO);
		glUseProgram(sceneProgram);
		glEnable(GL_DEPTH_TEST);

		foreach(uint i, ref t; tex) {
			glActiveTexture(GL_TEXTURE0 +i);
			glBindTexture(GL_TEXTURE_2D, t);
		}

		// white background
		glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// Rotate it
		model = mat4.identity;
		model.rotate(rad(time*30f), vec3(0.0f, 0.0f, 1.0f));
		glUniformMatrix4fv(uniModel, 1, GL_TRUE, model.value_ptr);

		// Draw the 'real' cube
		glDrawArrays(GL_TRIANGLES, 0, 36);

		// Now time for advanced procedures
		{
			glEnable(GL_STENCIL_TEST);
			scope(exit) glDisable(GL_STENCIL_TEST); // Just in case this scope goes fubar at runtime

			// Setup stencil test for plane
			glStencilFunc(GL_ALWAYS, 1, 0xFF);
			glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
			glStencilMask(0xFF); // Set stencil buffer
			// Ignore depth test for this
			glDepthMask(GL_FALSE);
			// Clear buffer for fresh draw
			glClear(GL_STENCIL_BUFFER_BIT);

			// Draw the plane
			glDrawArrays(GL_TRIANGLES, 36, 6);

			// Reset everything
			glDepthMask(GL_TRUE);
			glStencilFunc(GL_EQUAL, 1, 0xFF);
			glStencilMask(0x00); // Ignore stencil test

			// Mirror the cube
			model.translate(0, 0, -1).scale(1, 1, -1);
			glUniformMatrix4fv(uniModel, 1, GL_TRUE, model.value_ptr);

			// Draw again...
			glUniform3f(uniColor, 0.3f, 0.3f, 0.3f);
			glDrawArrays(GL_TRIANGLES, 0, 36);
			glUniform3f(uniColor, 1.0f, 1.0f, 1.0f);
		}

		// Screen
		//##########################
		// Bind default framebuffer and draw contents of our framebuffer
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glBindVertexArray(screenVAO);
		glDisable(GL_DEPTH_TEST);
		glUseProgram(screenProgram);

		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, colorBuffer);

		glDrawArrays(GL_TRIANGLES, 0, 6);

		//##############
		// Spit it out
		glfwSwapBuffers(window);
		// and wait for more to come
		glfwPollEvents();

		float secsPerFrame = glfwGetTime() - time;
		frames[0]++; // +1 Frame

		if(Clock.currAppTick.seconds != tickSeconds) {
			byte sign = frames[0] == frames[1] ? 0 : frames[0] > frames[1] ? 1 : 2;
			glfwSetWindowTitle(window, std.string.format(TITLE_FORMAT, APPNAME, framesPrefix[sign], frames[0], secsPerFrame*1000f).nt);

			tickSeconds = Clock.currAppTick.seconds;
			frames[1] = frames[0];
			frames[0] = 0;
		}
		if(secsPerFrame < goodSPF) {
			Thread.getThis.sleep(dur!"msecs"(lround((goodSPF-secsPerFrame)*1000f))); // Zzz..
		}
	}

	writeln("Exiting...");
	// Don't forget the scopes! ^
	return 0;
}

GLuint createTexture(string file) {
	// Generate
	GLuint tex;
	glGenTextures(1, &tex);

	// Set correct context
	glBindTexture(GL_TEXTURE_2D, tex);

	string path = PATH~ "/" ~file;
	debug write("::FILE:", path, "::TEX:", tex, "... ");

	int width, height, channels;
	ubyte* data;

	// Actually loading
	data = SOIL_load_image(path.nt, &width, &height, &channels, SOIL_LOAD_AUTO);
	scope(exit) SOIL_free_image_data(data);
	if(data == null) {
		writeln("FAILED");
		throw new Exception(text(SOIL_last_result()));
	}
	write("sampling... ");
	debug write("::",width,"x",height,"x",channels,"... ");

	GLenum format = channels == 4 ? GL_RGBA : GL_RGB;

	// Upload!
	glTexImage2D(GL_TEXTURE_2D, 
	             0, format, 
	             width, height, 
	             0, format, 
	             GL_UNSIGNED_BYTE, data);

	// Wrapper parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	// Filters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	writeln("DONE");
	return tex;
}

GLuint createShader(GLenum type, in string source) {
	GLuint shader = glCreateShader(type);

	const(char)* s = source.nt;
	glShaderSource(shader, 1, &s, null);

	glCompileShader(shader);
	GLint ok;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);

	if(!ok) {
		GLint length;
		char[] buffer;

		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
		buffer.length = length;
		glGetShaderInfoLog(shader, length, null, buffer.ptr);
		throw new Exception(chop(buffer).idup);
	}

	return shader;
}

GLuint createProgram(GLuint vertexShader, GLuint fragmentShader) {
	GLuint shaderProgram = glCreateProgram();

	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);

	glLinkProgram(shaderProgram);
	return shaderProgram;
}

GLuint createProgram(in string vertexSource, in string fragmentSource) {
	write("Creating shader program... ");
	write("compiling shaders... ");

	GLint vertex = createShader(GL_VERTEX_SHADER, vertexSource);
	scope (exit) glDeleteShader(vertex);

	GLint fragment = createShader(GL_FRAGMENT_SHADER, fragmentSource);
	scope (exit) glDeleteShader(fragment);

	writeln("DONE");
	return createProgram(vertex,fragment);
}
