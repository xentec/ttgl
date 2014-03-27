#version 150 core

in vec3 base;
//in vec3 sizes;
in vec4 color;
//in vec4 tex;

out VS_FS {
	vec4 color;
//	vec4 tex;
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

uniform vec4 tex;
uniform int seed;
uniform int rowLength;

int random(int seed, int iterations) {
    int value = seed;
    int n;

    for (n = 0; n < iterations; n++) {
        value = ((value >> 7) ^ (value << 9)) * 15485863;
    }

    return value;
}

vec4 random_vector(int seed) {
    int r = random(seed, 4);
    int g = random(r, 2);
    int b = random(g, 2);
    int a = random(b, 2);

    return vec4(float(r & 0x3FF) / 1024.0,
                float(g & 0x3FF) / 1024.0,
                float(b & 0x3FF) / 1024.0,
                float(a & 0x3FF) / 1024.0);
}

void main() {
	mat4 M = proj * view;

	//vs_out.tex = tex[int(mod(gl_VertexID,12))];
	vs_out.color = random_vector(gl_InstanceID+seed);
	vs_out.color = (color + vs_out.color)*0.5;

	float fl = floor(gl_InstanceID/rowLength);
	vec4 pos = vec4(fl - rowLength/2.0, 0.0, gl_InstanceID - rowLength * fl - rowLength/2.0, 0) ;
/*
	if(pos.x == 0.0)
		vs_out.color = vec4(1.0, 0.0, 0.0, 1.0); // y axis
	if(pos.z == 0.0)
		vs_out.color = vec4(0.0, 1.0, 0.0, 1.0); // x axis
	if(pos.x == 0.0 && pos.z == 0.0)
		vs_out.color = vec4(0.0, 0.0, 0.0, 1.0);
*/
	gl_Position = M * (model * vec4(base, 1.0) + pos); // Pass them to Geometry shader
}
