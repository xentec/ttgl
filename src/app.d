

import ttgl.math;

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

	// Lets load all symbols
	DerelictGL3.load();
//	DerelictGLFW3.load();

	// GLFW error catcher
	__gshared string glfwError;
	GLFWerrorfun glfwError_cb = (int code, const(char)* msg) {
		glfwError = text(code, " => ", msg);
	};
	glfwSetErrorCallback(glfwError_cb);

	write("Creating main window... ");
	if(!glfwInit()) {
		writeln("FAILED"); // Something is seriously wrong
		throw new Exception(glfwError);
	}

	// Better safe than sorry
	scope(exit) glfwTerminate();

	// Setting the correct context
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	if (glfwExtensionSupported("GLX_ARB_create_context_profile")) {
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
	}
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

	// Sometimes loading everything is just not enough
	DerelictGL3.reload();

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

	// Our triangle
	float vertices[] = [
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

	string vertexSource =
		`	#version 430 core

			in vec3 position;
			in vec3 col;
			in vec2 tex;

			out vec3 color;
			out vec2 texcoord;

			uniform mat4 model;
			uniform mat4 view;
			uniform mat4 proj;
			uniform vec3 overrideColor;

			void main()	{
				texcoord = tex;	// Just passing by
				color = col * overrideColor;	// Mixing!
				gl_Position = proj * view * model * vec4(position, 1.0); //Put vertices in right position
			}
		`;

	string fragmentSource =
		`	#version 430 core

			in vec3 color;
			in vec2 texcoord;
			out vec4 outColor;

			uniform sampler2D cat;
			uniform sampler2D scenery;

			void main() {	// texture mixer:  cat	+	scene		with ratio of
				outColor = mix(texture(cat, texcoord), texture(scenery, texcoord), 0.5) * vec4(color, 1.0); // Color per vertex = rainbows
			}
		`;

	// Buffers
	//##########################
	// Create our Vertex Array Object
	GLuint vao;
	glGenVertexArrays(1, &vao);
	scope(exit) glDeleteVertexArrays(1, &vao);
	glBindVertexArray(vao);

	// Create vertex buffes to hold our vertices
	GLuint vbo;
	glGenBuffers(1, &vbo);
	scope(exit) glDeleteBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	// Upload the vertices
	glBufferData(GL_ARRAY_BUFFER, float.sizeof * vertices.length, vertices.ptr, GL_STATIC_DRAW);

	// Program
	//##########################
	// Use helper functions from below
	GLuint shaderProgram = createProgram(vertexSource, fragmentSource);
	scope(exit) glDeleteProgram(shaderProgram);

	// Setting color vector output in fragment shader to outColor
	glBindFragDataLocation(shaderProgram, 0, "outColor");

	// Vertices
	//##########################
	writeln("Loading vertices...");

	// Tell our vertex shader how to use the vertices from our VBO
	GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
	glVertexAttribPointer(posAttrib, 3, GL_FLOAT, GL_FALSE, 8 * float.sizeof, null);
	glEnableVertexAttribArray(posAttrib);

	// ...and how to color them
	GLint colAttrib = glGetAttribLocation(shaderProgram, "col");
	glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE, 8 * float.sizeof, cast(void*) (3 * float.sizeof));
	glEnableVertexAttribArray(colAttrib);

	GLint texAttrib = glGetAttribLocation(shaderProgram, "tex");
	glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 8 * float.sizeof, cast(void*) (6 * float.sizeof));
	glEnableVertexAttribArray(texAttrib);

	// Transformations
	//##########################
	debug writeln("Calculating Matrices...");
	// Enter the Matrix!
	mat4 model;
	GLuint uniModel = glGetUniformLocation(shaderProgram, "model");

	mat4 view = mat4.look_at(vec3(2.5f, 2.5f, 2.0f), vec3(0.0f, 0.0f, 0.0f), vec3(0.0f, 0.0f, 1.0f));

	GLuint uniView = glGetUniformLocation(shaderProgram, "view");
	glUniformMatrix4fv(uniView, 1, GL_TRUE, view.value_ptr);

	mat4 proj = mat4.perspective(800f, 600f, 45.0f, 1.0f, 10.0f);
	GLuint uniProj = glGetUniformLocation(shaderProgram, "proj");
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
		glUniform1i(glGetUniformLocation(shaderProgram, name.nt), i);
	}

	// Clean textures when exiting
	scope(exit)
		foreach(ref t;tex)
			glDeleteTextures(1, &t);


	// Advanced Buffers
	//##########################
	// Depth
	glEnable(GL_DEPTH_TEST);

	// Misc
	GLint uniColor = glGetUniformLocation(shaderProgram, "overrideColor");

	//##################################
	//##################################
	// Input handler
	extern (C) void input_cb(GLFWwindow* window, int key, int scancode, int action, int mods) {
		if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) // Make it close itself on ESC
			glfwSetWindowShouldClose(window, GL_TRUE);
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

		// white background
		glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// Rotate it
		model = mat4.identity;
		model.rotate(rad(time*180f), vec3(0.0f, 0.0f, 1.0f));
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
	glTexImage2D(GL_TEXTURE_2D, 0, format,
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
	glUseProgram(shaderProgram);
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


