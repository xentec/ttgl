module ttgl.util;

import core.runtime;

import std.array;
import std.algorithm;
import std.conv;
import std.datetime;
import std.math;

enum TAU = PI*2;

@safe pure
real rad(in real angle) { return angle*TAU/360.0; }
@safe
float getAppTime() { return Clock.currAppTick.to!("seconds",float); }

void distrib(T)(in T[] array, T*[] values) {
	assert(array.length >= values.length);
	foreach(uint i, ref T* val; values) {
		*val = array[i];
	}
}


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



string saneStackTrace(in string func = __PRETTY_FUNCTION__, in string file = __FILE__, int line = __LINE__) {
	auto saneST = appender!string;
	auto saneL = appender!string;

	saneST.put(text("[0] ", func, '\n',
	                '\t', file, ':', line, '\n'));

	string st = defaultTraceHandler().toString();
	if(!st.length) {
		saneST.put("-------- < empty > ---------");
	} else {
		string stl[] = st.split("\n");
		for(uint i, s; i < stl.length; i++) {
			version(GDC) {
				if(stl[i].startsWith("0x"))
					saneL.put(text("[",++s,"] "));

				if(stl[i].endsWith("???")) {
					saneL.put(text(stl[i][0..$-4], " ...",'\n'));
					i++;
				} else if(stl[i].find("rt.dmain2").length) {
					break;
				} else {
					saneL.put(text(stl[i],'\n'));
				}
			} else {
				saneL.put(stl[i] ~ "\n");
			}
			saneST.put(saneL.data);
			saneL.clear();
		}
		saneST.put("----- End of user code -----");
	}
	return saneST.data;
}