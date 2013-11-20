#version 150 core

in vec3 position;
in vec3 col;
in vec2 tex;

out vec3 color;
out vec2 texcoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;
uniform vec3 overrideColor;

void main()	{
	texcoord = tex;	// Just passing by
	color = col * overrideColor;	// Mixing!
	gl_Position = proj * view * model * vec4(position, 1.0); //Put vertices in right position
}
