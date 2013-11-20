#version 150

in vec2 texcoord;
out vec4 outColor;

uniform sampler2D fb;

const float blurSizeH = 1.0 / 300.0;
const float blurSizeV = 1.0 / 200.0;
const int samplesN = 4;

void main() {
    vec4 sum = vec4(0.0);
    float samples = pow((samplesN+1) * 2.0, 2.0);
    for (int x = -samplesN; x <= samplesN; x++)
        for (int y = -samplesN; y <= samplesN; y++)
            sum += texture(fb, vec2(texcoord.x + x * blurSizeH, texcoord.y + y * blurSizeV)) / samples;
    outColor = sum;
}