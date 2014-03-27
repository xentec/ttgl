module ttgl.graphics.window;

import core.memory: GC;

import std.array;
import std.conv;
import std.signals;
import std.string : chop, _0 = toStringz, format;
import std.traits;

import glfw.glfw3;
import derelict.opengl3.gl3;

version(Posix) {
	import
		X11.Xutil,
		glfw.glfw3native;
}

import ttgl.global;

debug import std.stdio;

class Window
{
	struct Size {
		int width, height;
	}
	struct Config {
		bool resizable = true;
		bool visible = true;
		bool decorated = true;

		struct Bits {
			int 
				red = 8,
				green = 8,
				blue = 8,
				alpha = 8;
			int
				depth = 24,
				stencil = 8;
		};
		Bits bits;

		int auxBuffers;
		int samples;
		int refreshRate;

		Version GLversion = { major:1, minor:0 };

		enum Robustness {
			NONE,
			NO_RESET_NOTIFICATION = GLFW_NO_RESET_NOTIFICATION,
			LOSE_CONTEXT_ON_RESET = GLFW_LOSE_CONTEXT_ON_RESET
		};
		Robustness GLrobustness = Robustness.NONE;

		enum Profile {
			ANY,
			CORE = GLFW_OPENGL_CORE_PROFILE,
			COMPAT = GLFW_OPENGL_COMPAT_PROFILE
		}
		Profile GLprofile = Profile.ANY;

		bool forwarded = false;
		bool debuging = false;

	}

	this(int width, int height, in string title, in Config cfg = Config()) {
		Size s = { width, height };
		this(s, title, cfg);
	}
	this(in Size size, in string title, in Config cfg = Config()) {
		if(!windows) {
			if(!glfwInit()) {
				throw new WindowException(error.msg, null);
			}
		}
		this.title = title;
		this.size = size;
		this.cfg = cfg;
		// You stay where you are!
		GC.setAttr(cast(void*)this, GC.BlkAttr.NO_MOVE);
		windows++;
	}
	~this() {
		close();
		GC.clrAttr(cast(void*)this, GC.BlkAttr.NO_MOVE);
		if(--windows == 0) glfwTerminate();
	}

	@property
	void title(in string title) {
		if(!window) return;
		title_ = title;
		glfwSetWindowTitle(window, title._0);
	}
	@property
	string title() {
		return title_;
	}

	@property
	bool visible() {
		return window && glfwGetWindowAttrib(window, GLFW_VISIBLE);
	}
	@property
	void visible(bool flag) {
		cfg.visible = flag;
		if(!window) return;
		if(flag)
			glfwShowWindow(window);
		else
			glfwHideWindow(window);
	}

	void open(bool fullscreen = false) {
		setHints(cfg);
		GLFWmonitor* primary = null;
		if(fullscreen)
			primary = glfwGetPrimaryMonitor();

		// Just getting some living space here
		window = glfwCreateWindow(size.width, size.height, title._0, primary, null);
		if(!window)
			throw new WindowException(error.msg, null);	//TODO: Build some kind of recovery

		glfwSetWindowUserPointer(window, cast(void*)this);

		glfwSetKeyCallback(window, &keyCB);
		glfwSetWindowSizeCallback(window, &winSizeCB);
		glfwSetCursorPosCallback(window, &cursorPosCB);
		// Set X class hint
		{
			version(Posix) {
				XClassHint xch = {
					res_name: "gl", 	// aka instance
					res_class: APPNAME
				};
				XSetClassHint(glfwGetX11Display(), glfwGetX11Window(window), &xch);
			}
		}
		// OpenGL = on
		bindContext();

		// Catch cursor
		glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
	}

	bool isOpen() {
		return window && !glfwWindowShouldClose(window);
	}

	void close() {
		if(window) {
			glfwSetWindowUserPointer(window, null);
			glfwDestroyWindow(window);
			window = null;
		}
	}

	void bindContext() {
		glfwMakeContextCurrent(window);
	}

	void present() {
		glfwSwapBuffers(window);
	}

	@property
	void presentInterval(int iv) {
		glfwSwapInterval(iv);
	}

	static void pollEvents() {
		glfwPollEvents();
	}

	void delegate(int,int) onWindowMove;
	void delegate(int,int) onWindowResize;
	void delegate() onWindowClose;
	void delegate() onWindowRefresh;
	void delegate(bool) onWindowFocus;
	void delegate(bool) onWindowIconify;
	void delegate(int,int) onFramebufferResize;
	void delegate(int,int,int) onMouseButton;
	void delegate(double,double) onCursorMove;
	void delegate(int) onCursorEnter;
	void delegate(double,double) onScroll;
	void delegate(int,int,int,int) onKey;
	void delegate(dchar) onChar;
	void delegate(int) onMonitorStatus;

private:
	GLFWwindow* window;

	string title_;
	Size size;
	Config cfg;


	static this() {
		glfwSetErrorCallback(&glfwError_cb);

		// Getting current OpenGL version for a more precise window creation
		if(!glfwInit()) {
			throw new WindowException(error.msg, null);
		}
		scope(exit) glfwTerminate();
		// Spawn our silent spy!
		glfwWindowHint(GLFW_VISIBLE, GL_FALSE);
		GLFWwindow* test = glfwCreateWindow(13, 37, (APPNAME ~ " - GL Test!")._0, null, null);
		if(!test) throw new WindowException(error.msg, null);

		glfwDefaultWindowHints();
		scope(exit) glfwDestroyWindow(test);

		// Lets load all default symbols
		DerelictGL3.load();
		// OpenGL = on
		glfwMakeContextCurrent(test);
		// Sometimes loading everything is just not enough
		DerelictGL3.reload();
	}
	static GLFWError error;
	static uint windows;
}

class WindowException : Exception {

	const Window window;

	@safe pure nothrow
	this(string msg, Window win, string file = __FILE__, size_t line = __LINE__) {
		this(msg, win, null, file, line);
	}

	@safe pure nothrow
	this(string msg, Window win, Throwable next, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line, next);
		window = win;
	}
}


private:
struct GLFWError {
	int code;
	string msg;
}

extern(C)
void glfwError_cb(int code, const(char)* msg) nothrow {
	try {
		Window.error = GLFWError(code, text(msg));
		stderr.writeln(Window.error);
	} catch(Throwable e) {}
}

void setHints(in Window.Config cfg) {
	// Back to daylight
	glfwWindowHint(GLFW_VISIBLE, cfg.visible);
	glfwWindowHint(GLFW_RESIZABLE, cfg.resizable);
	// Setting the correct context
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, cfg.GLversion.major);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, cfg.GLversion.minor);
	glfwWindowHint(GLFW_OPENGL_PROFILE, cfg.GLprofile);
	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, cfg.forwarded);
	glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, cfg.debuging);

	glfwWindowHint(GLFW_RED_BITS, cfg.bits.red);
	glfwWindowHint(GLFW_GREEN_BITS, cfg.bits.green);
	glfwWindowHint(GLFW_BLUE_BITS, cfg.bits.blue);
	glfwWindowHint(GLFW_ALPHA_BITS, cfg.bits.alpha);
	// Setting the accuracy of the buffers
	glfwWindowHint(GLFW_DEPTH_BITS, cfg.bits.depth);
	glfwWindowHint(GLFW_STENCIL_BITS, cfg.bits.stencil);

	glfwWindowHint(GLFW_SAMPLES, cfg.samples);
}


Window get(GLFWwindow* w) { return cast(Window) glfwGetWindowUserPointer(w); }

extern(C) {
	void keyCB(GLFWwindow* gw, int key, int scancode, int action, int mode) nothrow {
		try {
			Window w = get(gw);
			if(w !is null && w.onKey !is null) 
				w.onKey(key, scancode, action, mode);
		} catch (Throwable e) {}
	};

	void winSizeCB(GLFWwindow* gw, int width, int height) nothrow {
		try {
			Window w = get(gw);
			if(w !is null && w.onWindowResize !is null) {
//				w.width = width;
//				w.height = height;
				w.onWindowResize(width, height);
			}
		} catch (Throwable e) {}
	}

	void cursorPosCB(GLFWwindow* gw, double x, double y) nothrow {
		try {
			Window w = get(gw);
			if(w !is null && w.onCursorMove !is null) w.onCursorMove(x, y);
		} catch (Throwable e) {}
	}
}