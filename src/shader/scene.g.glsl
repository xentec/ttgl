
#version 150

layout (points) in;
layout (triangle_strip, max_vertices = 36) out;

in VS_GS {
	vec3 sizes;
	vec3 color;
	vec4 tex;
} gs_in[];

out GS_FS {
	vec3 color;
	vec2 tex;
} gs_out;


uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

const vec3 cubev[] = vec3[](
	// BOTTOM
	vec3(0,0,0),vec3(1,0,0),vec3(1,1,0),
	vec3(0,0,0),vec3(0,1,0),vec3(1,1,0),
	// TOP
	vec3(0,0,1),vec3(1,0,1),vec3(1,1,1),
	vec3(0,0,1),vec3(0,1,1),vec3(1,1,1),
	// BACK-LEFT
	vec3(0,0,1),vec3(0,0,0),vec3(1,0,0),
	vec3(0,0,1),vec3(1,0,1),vec3(1,0,0),
	// FRONT-LEFT
	vec3(1,0,1),vec3(1,0,0),vec3(1,1,0),
	vec3(1,0,1),vec3(1,1,1),vec3(1,1,0),
	// FRONT-RIGHT
	vec3(1,1,1),vec3(1,1,0),vec3(0,1,0),
	vec3(1,1,1),vec3(0,1,1),vec3(0,1,0),
	// BACK-RIGHT
	vec3(0,1,1),vec3(0,1,0),vec3(0,0,0),
	vec3(0,1,1),vec3(0,0,1),vec3(0,0,0)
);

void main() {
	mat4 rotation = model;
	for(int i = 0; i < gl_in.length(); i++) {

		gs_out.color = gs_in[i].color;

		mat4 pos = mat4(1);
		pos[3] = gl_in[i].gl_Position;

		mat4 size = mat4(1.0);
		size[0][0] = gs_in[i].sizes.x;
		size[1][1] = gs_in[i].sizes.y;
		size[2][2] = gs_in[i].sizes.z;

		mat4 M = proj * view * pos * rotation * size;

		vec2 tex[] = vec2[](
			gs_in[i].tex.xy,
			gs_in[i].tex.yz,
			gs_in[i].tex.zw,
			gs_in[i].tex.xy,
			gs_in[i].tex.wx,
			gs_in[i].tex.zw
		);


		for(int j = 0, t = 0; j < 6*3*2; j++, t++) {
			gl_Position = M * vec4(cubev[j]-vec3(0.5), 1.0);
			gs_out.tex = tex[int(mod(j,6))];
			EmitVertex();
			if(j > 0 && mod(j+1,3) == 0.0) {
				EndPrimitive();
			}
		}

	}
}
