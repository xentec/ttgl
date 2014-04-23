#version 150 core

in VS_FS {
	vec4 color;
//	vec2 tex;
} fs_in;

out vec4 color;

uniform sampler2D cat;
uniform sampler2D scenery;

void main() {	// texture mixer:  cat	+	scenery		with ratio of
	//color = mix(texture(cat, fs_in.tex), texture(scenery, fs_in.tex), 0.5) * vec4(fs_in.color, 1.0); // Color per vertex = rainbows
	//fs_in.color = vec3(1.0,1.0,1.0);
	color = fs_in.color; // Color per vertex = rainbows
}