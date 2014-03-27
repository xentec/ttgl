module ttgl.graphics.util;

import core.memory;

import std.conv;
import std.stdio;
import std.string: _0 = toStringz, chop;

import derelict.opengl3.gl3;
import SOIL.SOIL;

import ttgl.global;

GLuint createTexture(string file) {
	// Generate
	GLuint tex;
	glGenTextures(1, &tex);

	// Set correct context
	glBindTexture(GL_TEXTURE_2D, tex);

	string path = PATH~ "/" ~file;
	debug write("::FILE:", path, "::TEX:", tex, "... ");

	int width, height, channels;
	ubyte* data;

	// Actually loading
	data = SOIL_load_image(path._0, &width, &height, &channels, SOIL_LOAD_AUTO);
	scope(exit) SOIL_free_image_data(data);
	if(data == null) {
		writeln("FAILED");
		throw new Exception(text(SOIL_last_result()));
	}
	write("sampling... ");
	debug write("::",width,"x",height,"x",channels,"... ");

	GLenum format = channels == 4 ? GL_RGBA : GL_RGB;

	// Upload!
	glTexImage2D(GL_TEXTURE_2D, 
	             0, format, 
	             width, height, 
	             0, format, 
	             GL_UNSIGNED_BYTE, data);

	// Wrapper parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	// Filters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	writeln("DONE");
	return tex;
}

GLuint createShader(GLenum type, in string source) {
	GLuint shader = glCreateShader(type);

	const(char)* s = source._0;
	glShaderSource(shader, 1, &s, null);

	glCompileShader(shader);
	GLint ok;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);

	if(!ok) {
		GLint length;
		char[] buffer;

		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
		buffer.length = length;
		glGetShaderInfoLog(shader, length, null, buffer.ptr);
		throw new Exception(chop(buffer).idup ~ source[0..32]);
	}

	return shader;
}

GLuint createProgram(GLint vertexShader, GLint fragmentShader, GLint geometryShader = -1) {
	GLuint shaderProgram = glCreateProgram();

	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);
	if(geometryShader >= 0)
		glAttachShader(shaderProgram, geometryShader);

	// Setting color vector output in fragment shader to outColor
	glBindFragDataLocation(shaderProgram, 0, "color");

	glLinkProgram(shaderProgram);
	return shaderProgram;
}

GLuint createProgram(in string vertexSource, in string fragmentSource, in string geometrySource = "") {
	write("Creating shader program... ");
	write("compiling shaders... ");

	GLint vertex = createShader(GL_VERTEX_SHADER, vertexSource);
	scope (exit) glDeleteShader(vertex);

	GLint fragment = createShader(GL_FRAGMENT_SHADER, fragmentSource);
	scope (exit) glDeleteShader(fragment);

	GLint geometry = -1;
	if(geometrySource.length) {
		geometry = createShader(GL_GEOMETRY_SHADER, geometrySource);
	}
	scope (exit) if(geometrySource.length) glDeleteShader(geometry);

	writeln("DONE");
	return createProgram(vertex,fragment,geometry);
}
void printBuffer(T)(GLenum buffer, size_t offset, int num, int stride = 0) {
	printBuffer!T("", buffer, offset, num, stride);
}
void printBuffer(T)(in string name, GLenum buffer, size_t offset, int num, int stride = 0) {
	size_t size = T.sizeof*num;
	T *ptr = cast(T*) GC.malloc(size, GC.BlkAttr.NO_SCAN | GC.BlkAttr.NO_MOVE);
	scope(exit) GC.free(ptr);

	glGetBufferSubData(buffer, offset, size, ptr);
	writeln(name, " (",typeid(T),"):");
	for(uint i; i < num;) {
		write('[');
		for(uint j = stride+i; i < j; i++) {
			write(ptr[i]);
			if(i+1 < j) write(", ");
		}
		writeln("]");
	}
}

