module X11.Xutil;

public import
	X11.X,
	X11.Xlib;

extern(System):

struct XClassHint {
	const(char*) res_name;
	const(char*) res_class;
};
/*
 * Normally (as in original C headers) XSetClassHint takes
 * a Window struct by value, not pointer. But since it's opaque 
 * and D requires all opaque structs to be a pointer, we need to
 * correct it.
 */
int	XSetClassHint(Display*, Window*, XClassHint*);
