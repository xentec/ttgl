module ttgl.math;

import std.math;
import std.stdio;

import gl3n.linalg;

enum TAU = PI*2;

real rad(in real angle) {
	return angle*TAU/360.0;
}

@safe pure T linear_interpolate(T)(float t, in T[] points ...) {
	if(points.length == 1)
		return points[0];

	T[] vps;
	vps.length = points.length - 1;

	for(int i = 0; i < vps.length; i++)
		vps[i] = points[i] * (1 - t) + points[i+1] * t;

	return linear_interpolate!T(t, vps);
}
