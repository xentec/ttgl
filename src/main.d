module ttgl.app;

import std.conv : text;
import std.datetime;
import std.math;
import std.stdio;
import std.string;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;
import derelict.devil.il;

enum string APPNAME = "TTGL";
enum int[string] VERSION = [ "major":1, "minor":0 ];

int main(string[] args) {
	writeln(APPNAME, " ", VERSION["major"], ".",VERSION["minor"]);
	debug {
		writeln("==============================");
		writeln("Arguements: ");
		foreach(i, arg; args)
			writeln("\t", i,"\t", arg);
		writeln("==============================");
		writeln("Environment: ");
		foreach(k, env; std.process.environment.toAA())
			writeln("\t", k,":\t", env);
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
	DerelictGLFW3.load();

	// GLFW error catcher
	__gshared string glfwError;
	GLFWerrorfun error_cb = (int code, const(char)* msg) {
		glfwError = text(code, " => ", msg);
	};
	glfwSetErrorCallback(error_cb);

	write("Creating main window... ");
	if(!glfwInit()) {
		writeln("FAILED"); // Something is seriously wrong
		throw new Exception(glfwError);
	}

	// Better safe than sorry
	scope(exit) glfwTerminate();
	
	// Just getting some living space here
	GLFWwindow* window = glfwCreateWindow(800, 600, (APPNAME ~ " - Oh my!").toStringz, null, null);
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
	
	// OpenGL = on
	glfwMakeContextCurrent(window);

	// Sometimes loading everything is just not enough
	DerelictGL3.reload();
	//##################################
	//##################################

	// Our triangle
	float vertices[] = [
		//  Position   Color             Texcoords
		-0.5f,  0.5f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, // Top-left
		 0.5f,  0.5f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, // Top-right
		 0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, // Bottom-right
		-0.5f, -0.5f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f  // Bottom-left
	];

	GLuint elements[] = [
		0, 1, 2, 2, 3, 0
	];

	const char* vertexSource = 
		`	#version 130

			in vec2 position;
			in vec3 col;
			in vec2 tex;
			out vec3 color;
			out vec2 texcoord;

			void main()	{
				color = col;	// Just passing by
				texcoord = tex;	// Just passing by
				gl_Position = vec4(position, 0.0, 1.0); //Put vertices in right position
			}
		`;
	
	const char* fragmentSource = 
		`	#version 130

			in vec3 color;
			in vec2 texcoord;
			out vec4 outColor;

			uniform sampler2D tex;

			void main() {
				outColor = texture(tex, texcoord) * vec4(color, 1.0); // Color per vertex = rainbow triangle
			}
		`;

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

	GLuint ebo;
	glGenBuffers(1, &ebo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, GLuint.sizeof * elements.length, elements.ptr, GL_STATIC_DRAW);

	writeln("Compiling shaders...");

	write("\tVertex... ");
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	scope(exit) glDeleteShader(vertexShader);
	glShaderSource(vertexShader, 1, &vertexSource, null);
	
	glCompileShader(vertexShader);
	if(!isShaderCompiled(vertexShader)) {
		writeln("FAILED");
		throw new Exception(getShaderCompileLog(vertexShader));
	} else
		writeln("DONE");

	write("\tFragment... ");
	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	scope(exit) glDeleteShader(fragmentShader);
	glShaderSource(fragmentShader, 1, &fragmentSource, null);
	
	glCompileShader(fragmentShader);
	if(!isShaderCompiled(fragmentShader)) {
		writeln("FAILED");
		throw new Exception(getShaderCompileLog(fragmentShader));
	} else
		writeln("DONE");

	writeln("Starting the shader program...");
	GLuint shaderProgram = glCreateProgram();
	scope(exit) glDeleteProgram(shaderProgram);
	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);

	// Setting color vector output in fragment shader to outColor
	glBindFragDataLocation(shaderProgram, 0, "outColor");
	glLinkProgram(shaderProgram);
	glUseProgram(shaderProgram);

	// Tell our vertex shader how to use the vertices from our VBO
	GLuint posAttrib = glGetAttribLocation(shaderProgram, "position");
	glEnableVertexAttribArray(posAttrib);
	glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 7 * float.sizeof, null);

	// ...and how to color them
	GLuint colAttrib = glGetAttribLocation(shaderProgram, "col");
	glEnableVertexAttribArray(colAttrib);
	glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE, 7 * float.sizeof, cast(void*) (2 * float.sizeof));

	GLuint texAttrib = glGetAttribLocation(shaderProgram, "tex");
	glEnableVertexAttribArray(texAttrib);
	glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 7 * float.sizeof, cast(void*) (5 * float.sizeof));

	// Prepare to load images
	write("Loading images... ");
	// Init
	DerelictIL.load();
	ilInit();
	// Actually loading
	ILuint img;
	ilGenImages(1, &img);
	scope(exit) ilDeleteImages(1, &img);
	ilBindImage(img);
	if(ilLoadImage("image-cat.png") == IL_FALSE) {
		writeln("FAILED");

		// load all symbols and make an init for a single function call to get an error message. meh.
		import derelict.devil.ilu;
		DerelictILU.load();
		iluInit();
		ILenum err = ilGetError();
		throw new Exception(text(err, " => ", iluErrorString(err)));
	} else
		writeln("DONE");
	
	int imgWidth = ilGetInteger(IL_IMAGE_WIDTH);
	int imgHeight = ilGetInteger(IL_IMAGE_HEIGHT); 
	ILubyte *imgData = ilGetData();

	writeln("Converting to textures... ");
	GLuint tex;
	glGenTextures(1, &tex);
	scope(exit) glDeleteTextures(1, &tex);
	glBindTexture(GL_TEXTURE_2D, tex);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgWidth, imgHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imgData);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

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
	enum frames_p = "~+-";
	ulong ticks_ms = Clock.currAppTick.seconds;

	writeln("Entering main loop...");
	while(!glfwWindowShouldClose(window)) {
		//##############

		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		// Draw it!
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

		//##############
		// Spit it out
		glfwSwapBuffers(window);
		// and wait for more to come
		glfwPollEvents();

		if(Clock.currAppTick.seconds != ticks_ms) {
			byte f = frames[0] == frames[1] ? 0 : frames[0] > frames[1] ? 1 : 2;
			glfwSetWindowTitle(window, text(APPNAME, " - FPS: ", frames_p[f], frames[0]).toStringz);
			ticks_ms = Clock.currAppTick.seconds;
			frames[1] = frames[0];
			frames[0] = 0;
		}

		frames[0]++;
	}

	writeln("Exiting...");
	// Don't forget the scopes! ^
	return 0;
}

bool isShaderCompiled(in GLuint shader) {
	GLint status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
	return status ? true : false;
}

string getShaderCompileLog(in GLuint shader) {
	GLint length;
	char[] buffer;

	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
	buffer.length = length;
	glGetShaderInfoLog(shader, length, null, buffer.ptr);

	return chop(buffer).idup;
}
