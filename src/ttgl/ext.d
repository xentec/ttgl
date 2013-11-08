module ttgl.ext;

import glfw.glfw3;

version(Posix) {
	extern(System) {

		// Xlib
		// ###################
		struct XClassHint {
			const(char*) res_name;
			const(char*) res_class;
		};
		struct Display {};
		struct Window {};

		int 		XSetClassHint(Display* d, Window w, XClassHint* xch);

		// Xlib
		// ###################
		Display*	glfwGetX11Display();
		Window		glfwGetX11Window(GLFWwindow* window);
	}
}