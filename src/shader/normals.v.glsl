#version 150 core

in vec3 base;
in vec4 color;

out VS_GS {
	vec4 color;
} vs_out;

uniform int rowLength;
uniform mat4 model;

void main() {
	float fl = floor(gl_InstanceID/rowLength);
	vec4 pos = vec4(fl, gl_InstanceID - rowLength * fl, 0, 0) * 2;

	gl_Position = (model * vec4(base, 1.0) + pos); // Pass them to Geometry shader
}

