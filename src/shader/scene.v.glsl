#version 150 core

in vec3 position;
in vec3 sizes;
in vec3 color;
in vec4 tex;

out VS_GS {
	vec3 sizes;
	vec3 color;
	vec4 tex;
} vs_out;


void main() {
	vs_out.tex = tex;
	vs_out.color = color;
	vs_out.sizes = sizes;
	gl_Position = vec4(position, 1.0); // Pass them to Geometry shader
}
