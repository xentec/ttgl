#version 150

in vec2 texcoord;
out vec4 outColor;

uniform sampler2D fb;

void main() {
	vec4 s1 = texture(fb, texcoord - 1.0 / 300.0 - 1.0 / 200.0);
	vec4 s2 = texture(fb, texcoord + 1.0 / 300.0 - 1.0 / 200.0);
	vec4 s3 = texture(fb, texcoord - 1.0 / 300.0 + 1.0 / 200.0);
	vec4 s4 = texture(fb, texcoord + 1.0 / 300.0 + 1.0 / 200.0);
	vec4 sx = 4.0 * ((s4 + s3) - (s2 + s1));
	vec4 sy = 4.0 * ((s2 + s4) - (s1 + s3));
	vec4 sobel = sqrt(sx * sx + sy * sy);
	outColor = sobel;
}