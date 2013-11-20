#version 150

in vec2 texcoord;
out vec4 outColor;

uniform sampler2D fb;
uniform int effectFlag;

vec4 invert(sampler2D fb, vec2 texcoord) {
    return vec4(1.0, 1.0, 1.0, 1.0) -  texture(fb, texcoord);
}

vec4 greyscale(sampler2D fb, vec2 texcoord) {
	outColor = texture(fb, texcoord);
	float avg = (outColor.r + outColor.g + outColor.b) / 3.0;
	return vec4(avg, avg, avg, 1.0);
}

vec4 blur_box(sampler2D fb, vec2 texcoord, int samplesN, float sizeH, float sizeV) {
	vec4 sum = vec4(0.0);
	float samples = pow((samplesN+1) * 2.0, 2.0);
	for (int x = -samplesN; x <= samplesN; x++)
		for (int y = -samplesN; y <= samplesN; y++)
			sum += texture(fb, vec2(texcoord.x + x * sizeH, texcoord.y + y * sizeV)) / samples;
	return sum;
}

vec4 sobel(sampler2D fb, vec2 texcoord) {
	vec4 s1 = texture(fb, texcoord - 1.0 / 300.0 - 1.0 / 200.0);
	vec4 s2 = texture(fb, texcoord + 1.0 / 300.0 - 1.0 / 200.0);
	vec4 s3 = texture(fb, texcoord - 1.0 / 300.0 + 1.0 / 200.0);
	vec4 s4 = texture(fb, texcoord + 1.0 / 300.0 + 1.0 / 200.0);
	vec4 sx = 4.0 * ((s4 + s3) - (s2 + s1));
	vec4 sy = 4.0 * ((s2 + s4) - (s1 + s3));
	return sqrt(sx * sx + sy * sy);
}

void main() {
	switch(effectFlag) {
	case 1:
		outColor = invert(fb, texcoord);
		break;
	case 2:
		outColor = greyscale(fb, texcoord);
		break;
	case 3:
		outColor = blur_box(fb, texcoord, 4, 1.0/300.0, 1.0/200.0);
		break;
	case 4:
		outColor = sobel(fb, texcoord);
		break;
	case 5:
		if(texcoord.x < 0.25)
			outColor = invert(fb, texcoord);
		else if(texcoord.x > 0.25 && texcoord.x < 0.50)
			outColor = sobel(fb, texcoord);
		else if(texcoord.x > 0.50 && texcoord.x < 0.75)
			outColor = blur_box(fb, texcoord, 4, 1.0/300.0, 1.0/200.0);
		else if(texcoord.x > 0.75)
			outColor = greyscale(fb, texcoord);	
		break;
	default:
	    outColor = texture(fb, texcoord);
	}
}
