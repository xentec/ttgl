module X11.Xutil;

public import
	X11.X,
	X11.Xlib;

version(Posix):
extern(System):

struct XClassHint {
	const(char*) res_name;
	const(char*) res_class;
};

int	XSetClassHint(Display*, Window, XClassHint*);
