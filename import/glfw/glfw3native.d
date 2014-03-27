module glfw.glfw3native;

import glfw.glfw3;

extern(System):
version(Posix):

public import 
	X11.X, X11.Xlib;
	
Display*	glfwGetX11Display();
/*
 * Normally (as in original C headers) glfwGetX11Window returns
 * a Window struct by value, not pointer. But since it's opaque 
 * and D requires all opaque structs to be a pointer, we need to
 * correct it.
 */
Window*		glfwGetX11Window(GLFWwindow* window);
		
