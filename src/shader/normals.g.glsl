#version 150

layout (triangles) in;
layout (line_strip, max_vertices = 8) out;

in VS_GS {
	vec4 color;
} gs_in[];

out GS_FS {
	vec4 color;
} gs_out;

uniform mat4 view;
uniform mat4 proj;

void main() {
	vec3 a = gl_in[0].gl_Position.xyz;
	vec3 b = gl_in[1].gl_Position.xyz;
	vec3 c = gl_in[2].gl_Position.xyz;

	vec3 normal = normalize(cross(b-a, c-a));
	vec4 tri_centroid = (gl_in[0].gl_Position + gl_in[1].gl_Position + gl_in[2].gl_Position) / 3.0;

	mat4 M = proj * view;

	gl_Position = M * tri_centroid;
	EmitVertex();

	gl_Position = M * (tri_centroid + vec4(normal * 0.5, 0.0));
	EmitVertex();
}
