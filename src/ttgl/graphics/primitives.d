module ttgl.graphics.primitives;

import 
	std.array,
	std.random;

import 
	gl3n.linalg,
	gl3n.math;
import derelict.opengl3.gl3;

import ttgl.graphics.base;
import ttgl.graphics.util;
import ttgl.util;

debug import std.stdio;

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

class RandomCubes : Drawable {

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
	static const float vertices[4*8] = [
		-0.5, -0.5, -0.5, 1,	//0
		 0.5, -0.5, -0.5, 1,	//1
		-0.5,  0.5, -0.5, 1,	//2
		 0.5,  0.5, -0.5, 1,	//3

		-0.5, -0.5,  0.5, 1,	//4
		 0.5, -0.5,  0.5, 1,	//5
		-0.5,  0.5,  0.5, 1,	//6
		 0.5,  0.5,  0.5, 1,	//7
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

	static const float normals[3*6] = [
		0, 0, -1,  0, 0, 1,
		0, -1, 0,  1, 0, 0,
		-1, 0, 0,  0, 1, 0
	];

	this(uint amount, int range, vec3 basePosition, vec3 scale = vec3(1)) {
		basePos = basePosition;

		Random rnd = Random(unpredictableSeed);

		vec4 positions[] = uninitializedArray!(vec4[])(amount);
		ulong posSize = positions.length * typeof(positions[0]).sizeof;
		foreach(ref pos; positions) {
			pos = vec4(uniform(-range, range, rnd), 
			           uniform(-range, range, rnd), 
			           uniform(-range, range, rnd), 
			           1);
		}

		vec4u colors[] = uninitializedArray!(vec4u[])(amount);
		ulong colSize = colors.length * typeof(colors[0]).sizeof;

		foreach(ref col; colors) {
			col = vec4u(cast(ubyte) uniform(0, 255, rnd), 
			            cast(ubyte) uniform(0, 255, rnd), 
			            cast(ubyte) uniform(0, 255, rnd), 
			            cast(ubyte) 255);
		}

		cmd.instanceCount = amount;

		createBuffers([&vbo, &ibo, &cbo]);

		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, vertices.sizeof + posSize + colSize, null, GL_STATIC_DRAW);
		glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.sizeof, vertices.ptr);
		glBufferSubData(GL_ARRAY_BUFFER, vertices.sizeof, posSize, positions.ptr);
		glBufferSubData(GL_ARRAY_BUFFER, vertices.sizeof + posSize, colSize, colors.ptr);

		//printBuffer!


		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.sizeof, indices.ptr, GL_STATIC_DRAW);

		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, cbo);
		glBufferData(GL_DRAW_INDIRECT_BUFFER, cmd.sizeof, &cmd, GL_STATIC_DRAW);

		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		prog = createProgram(import("cubes.v.glsl"), import("cubes.f.glsl"));
		glUseProgram(prog);

		GLint atribBasePos = glGetAttribLocation(prog, "basePos");
		glVertexAttribPointer(atribBasePos, 4, GL_FLOAT, GL_FALSE, 0, null);
		glEnableVertexAttribArray(atribBasePos);

		GLint atribCubePos = glGetAttribLocation(prog, "cubePos");
		glVertexAttribPointer(atribCubePos, 4, GL_FLOAT, GL_FALSE, 0, cast(void*) vertices.sizeof);
		glEnableVertexAttribArray(atribCubePos);
		glVertexAttribDivisor(atribCubePos, 1);

		GLint atribCubeColor = glGetAttribLocation(prog, "cubeColor");
		glVertexAttribPointer(atribCubeColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, cast(void*) (vertices.sizeof + posSize));
		glEnableVertexAttribArray(atribCubeColor);
		glVertexAttribDivisor(atribCubeColor, 1);

		glUseProgram(0);
	}

	~this() {
		destroyBuffers([vbo,ibo,cbo]);
		glDeleteVertexArrays(1, &vao);
	}

	void draw() {
		glBindVertexArray(vao);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, cbo);
		glUniformMatrix4fv(glGetUniformLocation(prog, "model"), 1, GL_TRUE, (model * mat4.translation(basePos.x,basePos.y,basePos.z)).value_ptr);
		glDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_BYTE, null);
	}

	int program() const {
		return prog;
	}
	mat4 model = mat4.identity;
private:
	GLuint vao, vbo, ibo, cbo;
	GLint prog;

	vec3 basePos;

	DrawElementsIndrectCMD cmd = { count: 36 };
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

	@property
	float[6*3] normals() {
		typeof(return) ns;
		const float* vx = vertices.ptr;
		const ubyte* ix = indices.ptr;
		for(int i; i < 6; i++) {
			//for(int j; j < 2; j++) {
			vec3 vix[3];
			for(int vi; vi < 3; vi++) {
				vix[vi] = vec3(vx[ix[i*6+vi]*3], vx[ix[i*6+vi]*3+1], vx[ix[i*6+vi]*3+2]);
			}
			vec3 a = vix[0];
			vec3 b = vix[1];
			vec3 c = vix[2];

			ns[i*3..i*3+3] = ((b-a).cross(c-a)).normalized.vector[];
			//}
		}
		return ns;
	}
*/
}
