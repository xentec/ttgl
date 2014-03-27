module ttgl.util;

import std.datetime;
import std.math;

enum TAU = PI*2;

@safe pure
real rad(in real angle) { return angle*TAU/360.0; }
@safe
float getAppTime() { return Clock.currAppTick.to!("seconds",float); }
