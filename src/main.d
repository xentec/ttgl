module ttgl.app;

import std.stdio;
import std.conv : to;
import std.math;
import std.datetime;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl;

enum string APPNAME = "TTGL";
enum int[string] VERSION = [ "major":1, "minor":0 ];

int main(string[] args) {
	writeln(APPNAME ~ " " ~ to!string(VERSION["major"]) ~ "." ~ to!string(VERSION["minor"]));

	// Don't forget to say good bye (scopes are executed in reverse order)
	scope(success) writeln("Have a nice day!");
	scope(failure) writeln("._.");
	
	// Lets load all symbols
	DerelictGL3.load();
	DerelictGLFW3.load();
	
	write("Creating main window... ");
	if(!glfwInit()) {
		writeln("FAILED"); // Something is seriously wrong
		throw new Exception("<");
	}

	// Better safe than sorry
	scope(exit) glfwTerminate();
	
	// Just getting some living space here
	GLFWwindow* window = glfwCreateWindow(800, 600, APPNAME ~ " - Oh my!", null, null);
	if(!window) {
		writeln("FAILED");		// Not as wrong as above, but wrong enough
		throw new Exception("<");	//TODO: Build some kind of recovery
	} else
		writeln("DONE");
	
	// Remember to burn everything after mission
	scope(exit) {
		writeln("Destroying main window...");
		glfwDestroyWindow(window);
	}
	
	// OpenGL = on
	glfwMakeContextCurrent(window);

	// Sometimes loading everything is not just not enough
	DerelictGL3.reload();
	//##################################
	//##################################

	// Our triangle
	float vertices[] = [
		0.0f,	0.5f,	// Vertex 1 (X, Y)
		0.5f,	-0.5f,	// Vertex 2 (X, Y)
		-0.5f,	-0.5f,	// Vertex 3 (X, Y)
	];
	
	const char* vertexSource = 
		`	#version 150

			in vec2 position;

			void main()	{
				gl_Position = vec4(position, 0.0, 1.0); //Put vertices in right position
			}
		`;
	
	const char* fragmentSource = 
		`	#version 150

			uniform vec3 triangleColor;
			out vec4 outColor;

			void main() {
				outColor = vec4(triangleColor, 1.0); // "triangleColor, you manage the color!"
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
	glBufferData(GL_ARRAY_BUFFER, float.sizeof*vertices.length, vertices.ptr, GL_STATIC_DRAW);

	writeln("Compiling shaders...");

	write("\tVertex... ");
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	scope(exit) glDeleteShader(vertexShader);
	glShaderSource(vertexShader, 1, &vertexSource, null);
	
	glCompileShader(vertexShader);
	if(!isShaderCompiled(vertexShader)) {
		writeln("E: " ~ getShaderCompileLog(vertexShader));
		throw new Exception("<");
	} else
		writeln("DONE");
	
	write("\tFragment... ");
	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	scope(exit) glDeleteShader(fragmentShader);
	glShaderSource(fragmentShader, 1, &fragmentSource, null);
	
	glCompileShader(fragmentShader);
	if(!isShaderCompiled(fragmentShader)) {
		writeln("E: " ~ getShaderCompileLog(fragmentShader));
		throw new Exception("<");
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
	glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 0, null);
	glEnableVertexAttribArray(posAttrib);

	// Setting link to our color manager
	GLuint uniColor = glGetUniformLocation(shaderProgram, "triangleColor");

	//##################################
	//##################################
	writeln("Entering main loop...");
	while(!glfwWindowShouldClose(window)) {
		//##############

		// Let's see it blink in green
		float time = glfwGetTime(); // or Clock.currAppTick.to!("seconds", float); for D's implementation
		glUniform3f(uniColor, 0.0f, 0.5f * (sin(time * 4.0) + 1.0f), 0.0f);

		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		// Draw it!
		glDrawArrays(GL_TRIANGLES, 0, 3);

		//##############
		// Spit it out
		glfwSwapBuffers(window);
		// and wait for more to come
		glfwPollEvents();
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

	return std.string.chop(buffer).idup;
}
