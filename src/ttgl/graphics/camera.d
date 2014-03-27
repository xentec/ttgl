module ttgl.graphics.camera;

import gl3n.linalg;
import ttgl.util;

//@safe
class Camera
{
	this(vec3 position = vec3(0))	{
		pos = position;
		right = cross(up, forward).normalized;
	}


	mat4 matrix(bool update = false) {
		if(changed || update) {
			cam = rot.inverse.to_matrix!(4,4) * mat4.translation(-pos.x, -pos.y, -pos.z);
			changed = false;
		}

		return cam;
	}

	/*
	 * Set the absolute position
	 */
	void setPosition(vec3 new_pos) {
		pos = new_pos;
		changed = true;
	}

//	void setDirection(vec3 new_dir) {
//		rot = quat.from_matrix(mat3.rotation());
//	}

	/*
	 * Move relative to actual position
	 */
	void moveRelative(vec3 rel_pos) {
		pos += rel_pos;
		changed = true;
	}
	/*
	 * Move relative to position _and_ direction
	 */
	void moveDirected(vec3 rel_pos) {
		pos += rot * rel_pos;
		changed = true;
	}
	/*
	 * Move some units forward
	 */
	void moveForward(float units = 1) {
		pos += (rot * right).normalized * units;
		changed = true;
	}
	/*
	 * Move some units backward
	 */
	void moveBackward(float units = 1) {
		pos += (rot * -right).normalized * units;
		changed = true;
	}
	/*
	 * Move some units to the right
	 */
	void moveRight(float units = 1) {
		pos += (rot * forward).normalized * units;
		changed = true;
	}
	/*
	 * Move some units to the left
	 */
	void moveLeft(float units = 1) {
		pos += (rot * -forward).normalized * units;
		changed = true;
	}
	/*
	 * Move some units up
	 */
	void moveUp(float units = 1) {
		pos += up * units;
		changed = true;
	}
	/*
	 * Move some units to the left
	 */
	void moveDown(float units = 1) {
		pos += -up * units;
		changed = true;
	}

	/*
	 * Up and down direction angle
	 */
	void pitch(float a) {
		rot = rot * quat.axis_rotation(a, forward);
		changed = true;
	}
	/*
	 * Left and right direction angle
	 */
	void yaw(float a) {
		rot = quat.axis_rotation(a, up) * rot;
		changed = true;
	}

	void roll(float a) {
		rot = rot * quat.axis_rotation(a, right);
		changed = true;
	}

	void mouse(double x, double y) {
		yaw(rad(mousePos.x - x));
		pitch(rad(mousePos.y - y));

		mousePos = vec2(x,y);
	}

private:
	vec3 pos;
	quat rot = quat.identity;

	vec3 forward = vec3(1.0, 0.0, 0.0);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right;

	vec2 mousePos = vec2(0,0);
	bool changed = true;

	mat4 cam;
}

