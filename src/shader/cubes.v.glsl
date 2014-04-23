#version 150 core

in vec4 basePos;
in vec4 cubePos;
in vec4 cubeColor;
//in vec3 sizes;
//in vec4 tex;


out VS_FS {
	vec4 color;
//	vec4 tex;
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

//uniform vec4 tex;

void main() {
	mat4 M = proj * view;

	//vs_out.tex = tex[int(mod(gl_VertexID,12))];
	vs_out.color = cubeColor;

	gl_Position = M * (basePos * model + cubePos);
}
