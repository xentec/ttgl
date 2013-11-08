module glfw.glfw3native;

import glfw.glfw3;

extern(System):
version(Posix):

public import 
	X11.X, X11.Xlib;
	
Display*	glfwGetX11Display();
Window		glfwGetX11Window(GLFWwindow* window);
		
