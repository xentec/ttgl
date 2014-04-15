module ttgl.graphics.camera;

import gl3n.linalg;
import ttgl.util;

class Camera
{
	this(vec3 position, float width, float height, float fov = 90, float near = 1, float far = 512) {
		pos.data = position;
		rot.data = quat.identity;
		right = cross(up, forward).normalized;

		proj = mat4.perspective(width, height, fov, near, far);
	}


	mat4 getView(bool update = false) {
		if(rot.changed || pos.changed || update) {
			view = rot.inverse.to_matrix!(4,4) * mat4.translation(-pos.x, -pos.y, -pos.z);
			rot.changed = pos.changed = false;
		}

		return view;
	}

	mat4 getProjection(bool update = false) {
		return proj;
	}

	/*
	 * Set the absolute position
	 */
	void setPosition(vec3 new_pos) {
		pos = new_pos;
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
	/*
	 * Left and right direction angle
	 */
	void yaw(float a) {
		rot = quat.axis_rotation(a, up) * rot;
	}

	void roll(float a) {
		rot = quat.axis_rotation(a, right) * rot;
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
	mat4 proj;
private:
	Aware!vec3 pos;
	Aware!quat rot;

	vec3 
		forward = vec3(1, 0, 0),
		up = vec3(0, 1, 0),
		right;
	
	vec2 mousePos = vec2(0,0);

	mat4 view;
}

