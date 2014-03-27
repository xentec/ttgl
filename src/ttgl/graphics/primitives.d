module ttgl.graphics.primitives;

import gl3n.linalg;

struct Face {
	union {
		struct {
			vec3 a,b1,b2,c;
		}
		vec3 v[4];
	}
	vec4 tex = vec4(0,0,1,1);

	@property // 4 vx * 3 vec
	float[4*3] vertices() {
		typeof(return) r = void;
		foreach(ubyte i, ref vec3 vec; v) {
			foreach(ubyte d, ref float c; vec.vector)
				r[i*vec3.dimension+d] = c;
		}
		return r;
	}
	enum ubyte[6] indices = [0, 2, 3,  3, 1, 0];
}

struct Cube {
	/*
	enum Face[6] faces = [
		Face(vec3(0,0,0),vec3(1,0,0),vec3(0,1,0),vec3(1,1,0)),	// BOTTOM
		Face(vec3(0,0,1),vec3(1,0,1),vec3(0,1,1),vec3(1,1,1)),	// TOP
		Face(vec3(0,0,1),vec3(0,0,0),vec3(1,0,1),vec3(1,0,0)),	// BACK-LEFT
		Face(vec3(1,0,1),vec3(1,0,0),vec3(1,1,1),vec3(1,1,0)),	// FRONT-LEFT
		Face(vec3(1,1,1),vec3(1,1,0),vec3(0,1,1),vec3(0,1,0)),	// FRONT-RIGHT
		Face(vec3(0,1,1),vec3(0,1,0),vec3(0,0,1),vec3(0,0,0))	// BACK-RIGHT
	];
	*/

	vec3 position;
	vec3 scale;
	vec3 color = vec3(1f,1f,1f);
	vec4 tex = vec4(0f,0f,1f,1f);

	/*
		 4---6
		 v B ^
		 0-->2
	4->-00->-22->-66-->4
	| L	v^ G || R v^ T v
	5-<-11-<-33-<-77---5
		 1---3
		 ^ F v
		 5<--7
	arrows define the winding vertex
	*/
	static const float vertices[8*3] = [
		-0.5, -0.5,  -0.5,	//0
		0.5, -0.5,  -0.5,	//1
		-0.5,  0.5,  -0.5,	//2
		0.5,  0.5,  -0.5,	//3

		-0.5, -0.5,  0.5,	//4
		0.5, -0.5,  0.5,	//5
		-0.5,  0.5,  0.5,	//6
		0.5,  0.5,  0.5,	//7
	];
	// counter clock winding for face culling
	static const ubyte indices[(3*2)*6] = [
		0, 2, 3,  3, 1, 0, //Ground
		4, 5, 7,  7, 6, 4, //Top

		4, 0, 1,  1, 5, 4, //Left
		5, 1, 3,  3, 7, 5, //Front
		6, 2, 0,  0, 4, 6, //Back
		7, 3, 2,  2, 6, 7, //Right
	];

	ubyte colors[8*4] = [
		0,0,0,255, 		//0
		255,0,0,255, 	//1
		0,255,0,255, 	//2
		0,0,255,255, 	//3

		255,255,0,255, 	//4
		255,0,255,255, 	//5
		0,255,255,255,  //6
		255,255,255,255,//7
	];

	vec3[6] normals() {
		typeof(return) ns;
		const float* vx = vertices.ptr;
		const ubyte* ix = indices.ptr;
		for(int i; i < 6; i++) {
		//for(int j; j < 2; j++) {
			vec3 vix[3];
			for(int vi; vi < 3; vi++) {
				vix[vi] = vec3(vx[ix[i*6+vi]*3], vx[ix[i*6+vi]*3+1], vx[ix[i*6+vi]]*3+2);
			}
			vec3 a = vix[0];
			vec3 b = vix[1];
			vec3 c = vix[2];

			ns[i] = (b-a).cross(c-a);

		//}
		}
		return ns;
	}
	/*
	@property // 6 faces * 4 vx * 3 vec = 72
	float[6*4*3] vertices() {
		typeof(return) r = void;
		foreach(ubyte i, ref Face f; faces) {
			r[i*4*3..i*4*3+4*3] = f.vertices;
		}
		return r;
	}

	@property
	float[6*6] indices() {
		typeof(return) r = void;
		foreach(ubyte i, ref Face f; faces) {
			foreach(ubyte j, ref ubyte c; f.indices) {
				r[i*6+j] = c + i*4;
				writeln(r[i*6+j]);
			}
	 }
		return r;
	}
*/
}
