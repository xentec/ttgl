module ttgl.graphics.base;

interface Drawable {
	void draw();
	int program();
}

interface Renderer {
	void render(Drawable);
}