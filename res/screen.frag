#version 150

in vec2 texcoord;
out vec4 outColor;

uniform sampler2D fb;

void main() {
    outColor = vec4(1.0, 1.0, 1.0, 1.0) -  texture(fb, texcoord);
}