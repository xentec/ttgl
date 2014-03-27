#version 150

in vec2 pos;
in vec2 tex;

out VS_FS {
	vec2 tex;
} vs_out;

void main() {
    vs_out.tex = tex;
    gl_Position = vec4(pos, 0.0, 1.0);
}
