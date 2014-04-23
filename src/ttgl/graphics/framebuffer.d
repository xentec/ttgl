module ttgl.graphics.renderer;

import derelict.opengl3.gl3;
import gl3n.linalg;

import ttgl.graphics.base;
import ttgl.graphics.util;
import ttgl.graphics.camera;


class Framebuffer : Renderer, Drawable
{
	this(uint width, uint height, bool bind = false) {

		cam = new Camera(vec3(0),width,height);

		glGenVertexArrays(1, &vao);
		scope(failure) glDeleteVertexArrays(1, &vao);
		glBindVertexArray(vao);

		// Create vertex buffes to hold our vertices
		glGenBuffers(1, &vbo);
		scope(failure) glDeleteBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		// Upload the vertices
		glBufferData(GL_ARRAY_BUFFER, vertices.sizeof + tex.sizeof, null, GL_STATIC_DRAW);
		glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.sizeof, vertices.ptr);
		glBufferSubData(GL_ARRAY_BUFFER, vertices.sizeof, tex.sizeof, tex.ptr);


		// Program
		prog = createProgram(import("screen.v.glsl"), import("screen.f.glsl"));
		scope(failure) glDeleteProgram(prog);
		glUseProgram(prog);
		glUniform1i(glGetUniformLocation(prog, "fb"), 0);

		{
			int posAttrib = glGetAttribLocation(prog, "pos");
			glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 0, null);
			glEnableVertexAttribArray(posAttrib);

			int texAttrib = glGetAttribLocation(prog, "tex");
			glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 0, cast(void*) vertices.sizeof);
			glEnableVertexAttribArray(texAttrib);
		}

		// Texture
		glGenTextures(1, &cb);
		scope(failure) glDeleteTextures(1, &cb);

		// Depth and stencil buffer
		glGenRenderbuffers(1, &rbo);
		scope(failure) glDeleteRenderbuffers(1, &rbo);

		glGenFramebuffers(1, &fb);
		scope(failure) glDeleteFramebuffers(1, &fb);

		resize(width, height); // Initialize texture and renderbuffer

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

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
		cam.resize(width, height);
		glViewport(0, 0, width, height);

		glBindTexture(GL_TEXTURE_2D, cb);
		glTexImage2D(GL_TEXTURE_2D, 
		             0, GL_RGB, 
		             width, height, 
		             0, GL_RGB, 
		             GL_UNSIGNED_BYTE, null);

		glBindRenderbuffer(GL_RENDERBUFFER, rbo);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
	}

	void render(Drawable obj) {
		bind();
		glUseProgram(obj.program);
		glUniformMatrix4fv(glGetUniformLocation(obj.program, "view"), 1, GL_TRUE, cam.getView.value_ptr);
		glUniformMatrix4fv(glGetUniformLocation(obj.program, "proj"), 1, GL_TRUE, cam.getProjection.value_ptr);
		obj.draw();
	}

	@property
	GLint program() const {
		return prog;
	}

	@property
	ref Camera camera() {
		return cam;
	}

private:
	uint vao, vbo, prog, fb;
	uint cb, rbo;

	bool bound;

	Camera cam;

/*
	-1,-1 ---------- 1,-1
	  |  \            |
	  |       \       |
	  |            \  |
	-1,1 ----------- 1,1
*/
	static const GLfloat vertices[(2*3)*2] = [
		-1, -1,  -1,  1,   1,  1, // Left
		 1,  1,   1, -1,  -1, -1, // Right
	];

	static const GLfloat tex[(2*3)*2] = [
		0, 0,  0, 1,  1, 1,
		1, 1,  1, 0,  0, 0,
	];
}
