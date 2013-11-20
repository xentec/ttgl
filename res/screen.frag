#version 150

in vec2 texcoord;
out vec4 outColor;

uniform sampler2D fb;

void main() {
    outColor = texture(fb, texcoord);
	float avg = (outColor.r + outColor.g + outColor.b) / 3.0;
	outColor = vec4(avg, avg, avg, 1.0);
}