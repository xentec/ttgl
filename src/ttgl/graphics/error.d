module ttgl.graphics.error;

import derelict.opengl3.arb;
import derelict.opengl3.constants;
import derelict.opengl3.types;



static const GLDef GL;

static this() {
	GL.Debug = [
		// Source
		GL_DEBUG_SOURCE_API: "API",
		GL_DEBUG_SOURCE_WINDOW_SYSTEM: "Window System",
		GL_DEBUG_SOURCE_SHADER_COMPILER: "Shader Compiler",
		GL_DEBUG_SOURCE_THIRD_PARTY: "Third Party",
		GL_DEBUG_SOURCE_APPLICATION: "Application",
		GL_DEBUG_SOURCE_OTHER: "Other",
		// Type
		GL_DEBUG_TYPE_ERROR: "Error",
		GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: "Deprecated",
		GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR: "Undefined",
		GL_DEBUG_TYPE_PORTABILITY: "Portability",
		GL_DEBUG_TYPE_PERFORMANCE: "Performance",
		GL_DEBUG_TYPE_OTHER: "Other",
		GL_DEBUG_TYPE_MARKER: "Marker",
		// Severity
		GL_DEBUG_SEVERITY_HIGH: "High",
		GL_DEBUG_SEVERITY_MEDIUM: "Medium",
		GL_DEBUG_SEVERITY_LOW: "Low",
		GL_DEBUG_SEVERITY_NOTIFICATION: "Notify",
	];
	GL.Shader = [
		GL_VERTEX_SHADER: "Vertex",
		GL_FRAGMENT_SHADER: "Fragment",
		GL_GEOMETRY_SHADER: "Geometry"
	];
	GL.Buffer = [
		GL_ARRAY_BUFFER: "Array",
		GL_ELEMENT_ARRAY_BUFFER: "Element array",
		GL_DRAW_INDIRECT_BUFFER: "Draw indirect"
	];
}

private:
struct GLDef {
	string[GLenum] 
		Debug,
		Shader,
		Buffer;
}