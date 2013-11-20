#version 150 core

in vec3 color;
in vec2 texcoord;
out vec4 outColor;

uniform sampler2D cat;
uniform sampler2D scenery;

void main() {	// texture mixer:  cat	+	scenery		with ratio of
	outColor = mix(texture(cat, texcoord), texture(scenery, texcoord), 0.5) * vec4(color, 1.0); // Color per vertex = rainbows
}
