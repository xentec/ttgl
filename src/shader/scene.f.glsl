#version 150 core

in GS_FS {
	vec3 color;
	vec2 tex;
} fs_in;

out vec4 color;

uniform sampler2D cat;
uniform sampler2D scenery;

void main() {	// texture mixer:  cat	+	scenery		with ratio of
	color = mix(texture(cat, fs_in.tex), texture(scenery, fs_in.tex), 0.5) * vec4(fs_in.color, 1.0); // Color per vertex = rainbows
}
