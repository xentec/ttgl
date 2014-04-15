module ttgl.util;

import std.datetime;
import std.math;

enum TAU = PI*2;

@safe pure
real rad(in real angle) { return angle*TAU/360.0; }
@safe
float getAppTime() { return Clock.currAppTick.to!("seconds",float); }

struct Aware(T) {
	bool changed;
	alias data this;

	@property {
		ref T data() {
			return d;
		}

		void data(T assgn) {
			if(d != assgn) {
				d = assgn;
				changed = true;
			}
		}
	}

	auto opOpAssign(string op,To)(To rhs) {
		changed = true;
		return d.opOpAssign!op(rhs);
	}
private:
	T d;
}
