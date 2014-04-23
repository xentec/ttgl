module ttgl.graphics.camera;

import gl3n.linalg;
import gl3n.math;
import ttgl.util;

debug import std.stdio;

class Camera
{
	this(vec3 position, float width, float height, float fov = 90, float near = 1, float far = 512) {
		pos.data = position;
		rot.data = quat.identity;
		right = cross(up, forward).normalized;

		persp.data = Perspective(width, height, fov, near, far);
	}


	mat4 getView(bool update = false) {
		if(rot.changed || pos.changed || update) {
			view = rot.inverse.to_matrix!(4,4) * mat4.translation(-pos.x, -pos.y, -pos.z);
			rot.changed = pos.changed = false;
		}

		return view;
	}

	mat4 getProjection(bool update = false) {
		if(persp.changed || update) {
			proj = mat4.perspective(persp.width, persp.height, persp.fov, persp.near, persp.far);
			persp.changed = false;
		}
		return proj;
	}

	/*
	 * Set the absolute position
	 */
	@property {
		vec3 position() {
			return pos;
		}
		void position(vec3 new_pos) {
			pos.data = new_pos;
		}
	}

	@property {
		float fov() {
			return persp.fov;
		}
		void fov(float new_fov) {
			persp.fov = new_fov;
			persp.changed = true;
		}
	}

	@property {
		float nearPlane() {
			return persp.near;
		}
		void nearPlane(float new_near) {
			persp.near = new_near;
			persp.changed = true;
		}
	}

	@property {
		float farPlane() {
			return persp.far;
		}
		void farPlane(float new_far) {
			persp.far = new_far;
			persp.changed = true;
		}
	}

	void resize(float new_width, float new_height) {
		if(persp.width == new_width && persp.height == new_height)
			return;
		persp.width = new_width;
		persp.height = new_height;
		persp.changed = true;
	}

//	void setDirection(vec3 new_dir) {
//		rot = quat.from_matrix(mat3.rotation());
//	}

	/*
	 * Move relative to actual position
	 */
	void moveRelative(vec3 rel_pos) {
		pos += rel_pos;
	}
	/*
	 * Move relative to position _and_ direction
	 */
	void moveDirected(vec3 rel_pos) {
		pos += rot * rel_pos;
	}
	/*
	 * Move some units forward
	 */
	void moveForward(float units = 1) {
		pos += (rot * right).normalized * units;
	}
	/*
	 * Move some units backward
	 */
	void moveBackward(float units = 1) {
		pos += (rot * -right).normalized * units;
	}
	/*
	 * Move some units to the right
	 */
	void moveRight(float units = 1) {
		pos += (rot * forward).normalized * units;
	}
	/*
	 * Move some units to the left
	 */
	void moveLeft(float units = 1) {
		pos += (rot * -forward).normalized * units;
	}
	/*
	 * Move some units up
	 */
	void moveUp(float units = 1) {
		pos += up * units;
	}
	/*
	 * Move some units to the left
	 */
	void moveDown(float units = 1) {
		pos += -up * units;
	}

	/*
	 * Up and down direction angle
	 */
	void pitch(float a) {
		rot = rot * quat.axis_rotation(a, forward);
	}
	//TODO: Correct yaw rotation in upside-down situtation
	/*
	 * Left and right direction angle
	 */
	void yaw(float a) {
		rot = quat.axis_rotation(a, up) * rot;
	}

	void roll(float a) {
		rot = rot * quat.axis_rotation(a, right);
	}

	void mouse(double x, double y) {
		yaw(rad(mousePos.x - x));
		pitch(rad(mousePos.y - y));

		mousePos = vec2(x,y);
	}

	void moveUpdate(float dt) {
		moveDirected(velocity*dt);
	}

	vec3 velocity = vec3(0);

private:
	Aware!vec3 pos;
	Aware!quat rot;

	vec3 
		forward = vec3(1, 0, 0),
		up = vec3(0, 1, 0),
		right;

	vec2 mousePos = vec2(0,0);

	Aware!Perspective persp;

	// cache
	mat4 view, proj;
}

private:

struct Perspective {
	float width, height;
	float fov;
	float near, far;
}

