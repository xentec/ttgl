module ttgl;

import std.stdio;
import std.conv : to;

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
	
	// Greatness shall arise here... 
	
	//##################################
	//##################################
	writeln("Entering main loop...");
	while(!glfwWindowShouldClose(window)) {
		//##############
		
		//...in some future.

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
