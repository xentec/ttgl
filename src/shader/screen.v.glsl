#version 150

in vec2 position;
in vec2 tex;
out vec2 texcoord;

void main() {
    texcoord = tex;
    gl_Position = vec4(position, 0.0, 1.0);
}
