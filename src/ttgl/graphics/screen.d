module ttgl.graphics.screen;

import derelict.opengl3.gl3;

import ttgl.graphics.util;

class Screen
{
	this(uint width, uint height, bool bind = false) {
		glGenVertexArrays(1, &vao);
		scope(failure) glDeleteVertexArrays(1, &vao);
		glBindVertexArray(vao);

		// Create vertex buffes to hold our vertices
		glGenBuffers(1, &vbo);
		scope(failure) glDeleteBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		// Upload the vertices
		glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, vertices.ptr, GL_STATIC_DRAW);

		// Program
		prog = createProgram(import("screen.v.glsl"), import("screen.f.glsl"));
		scope(failure) glDeleteProgram(prog);
		glUseProgram(prog);
		glUniform1i(glGetUniformLocation(prog, "fb"), 0);

		{
			int posAttrib = glGetAttribLocation(prog, "pos");
			glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 4 * GLfloat.sizeof, null);
			glEnableVertexAttribArray(posAttrib);

			int texAttrib = glGetAttribLocation(prog, "tex");
			glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 4 * GLfloat.sizeof, cast(void*) (2 * GLfloat.sizeof));
			glEnableVertexAttribArray(texAttrib);
		}

		// Screen texture
		glGenTextures(1, &cb);
		scope(failure) glDeleteTextures(1, &cb);
		glBindTexture(GL_TEXTURE_2D, cb);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

		glTexImage2D(GL_TEXTURE_2D, 
		             0, GL_RGB, 
		             width, height, 
		             0, GL_RGB, 
		             GL_UNSIGNED_BYTE, null);

		// Depth and stencil buffer
		glGenRenderbuffers(1, &rbo);
		scope(failure) glDeleteRenderbuffers(1, &rbo);

		glBindRenderbuffer(GL_RENDERBUFFER, rbo);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);

		glGenFramebuffers(1, &fb);
		scope(failure) glDeleteFramebuffers(1, &fb);
		this.bind();

		glFramebufferTexture2D(GL_FRAMEBUFFER, 
		                       GL_COLOR_ATTACHMENT0, 
		                       GL_TEXTURE_2D, cb, 0);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, 
		                          GL_DEPTH_STENCIL_ATTACHMENT, 
		                          GL_RENDERBUFFER, rbo);
		if(!bind) this.unbind();
	}

	~this() {
		unbind();
		glDeleteFramebuffers(1, &fb);
		glDeleteProgram(prog);
		glDeleteTextures(1, &cb);
		glDeleteRenderbuffers(1, &rbo);
		glDeleteBuffers(1, &vbo);
		glDeleteVertexArrays(1, &vao);
	}

	void bind() {
		//if(bound) return; // TODO: Check other binds
		glBindFramebuffer(GL_FRAMEBUFFER, fb);
		bound = true;
	}

	void unbind() {
		//if(!bound) return;
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		bound = false;
	}

	void draw() {
		unbind();
		glBindVertexArray(vao);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, cb);
		glUseProgram(prog);

		glDrawArrays(GL_TRIANGLES, 0, 6);
	}

	void resize(int width, int height) {
		glBindTexture(GL_TEXTURE_2D, cb);
		glTexImage2D(GL_TEXTURE_2D, 
		             0, GL_RGB, 
		             width, height, 
		             0, GL_RGB, 
		             GL_UNSIGNED_BYTE, null);

		glBindRenderbuffer(GL_RENDERBUFFER, rbo);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
	}

	@property
	GLint program() const {
		return prog;
	}

private:
	uint vao, vbo, prog, fb;
	uint cb, rbo;

	bool bound;
/*
	-1,-1 ---------- 1,-1
	  |  \            |
	  |       \       |
	  |            \  |
	-1,1 ----------- 1,1
*/
	static immutable GLfloat vertices[3*2*4] = [
		-1.0f, -1.0f,  0.0f, 0.0f,
		-1.0f,  1.0f,  0.0f, 1.0f,
		1.0f,  1.0f,  1.0f, 1.0f,

		1.0f,  1.0f,  1.0f, 1.0f,
		1.0f, -1.0f,  1.0f, 0.0f,
		-1.0f, -1.0f,  0.0f, 0.0f,
	];
}
