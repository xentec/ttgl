#version 150

in vec2 texcoord;
out vec4 outColor;

uniform sampler2D fb;

void main() {
    outColor = texture(fb, texcoord);
}