module ttgl.util.math;

//import core.simd;
//TODO: Simd
import std.math;

class Vector(int dim = 3) {
public:
	float x, y, z;
	static if(dim == 4)
		float w;

	this() {
		this(0.0f);
	}
	
	this(float xyz) {
		this(xyz,xyz,xyz);
	}
	
	this(float x, float y, float z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	Vector opBinary(string op, T : Vector)(in T rhs) {
		return mixin("new Vector(x "~op~" rhs.x, y "~op~" rhs.y, z "~op~" rhs.z)"); 
	}
	
	Vector opBinary(string op, T : long)(in T rhs) {
		return mixin("new Vector(x "~op~" rhs, y "~op~" rhs, z "~op~" rhs)"); 
	}

	float lengthSQR() {
		return x^^2 + y^^2 + z^^2;
	}

	float length() {
		return std.math.sqrt(lengthSQR());
	}
	
	override string toString() {
		return std.conv.text(x, ",", y, ",", z);
	}
}


/* TODO
class Vector(T : float = float) {
public:
	T x, y, z;

	this() {
		this(T.init);
	}

	this(T xyz) {
		this(xyz,xyz,xyz);
	}

	this(T x, T y, T z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	Vector opBinary(string op)(in Vector rhs) {
		auto t = mixin("x"~op~"rhs.x");
		pragma(msg, typeof(t));
		return mixin("new Vector!(typeof(t))(t, y"~op~"rhs.y, z"~op~"rhs.z)"); 
	}

	Vector opBinary(string op, C : byte)(in C rhs) {
		auto t = mixin("x "~op~" rhs");
		return mixin("new Vector!(typeof(t))(t, y "~op~" rhs, z "~op~" rhs)"); 
	}

	Vector!C convert(C = float)() {
		return new Vector!C(cast(C) x, cast(C) y, cast(C) z);
	}
	alias convert to;

	float length() {
		Vector!float v = to!float;
		return sqrt(v.x^^2 + v.y^^2 + v.z^^2);
	}


	override string toString() {
		import std.conv : text;
		return text("{", x, ",", y, ",", z, "}");
	}
}

*/