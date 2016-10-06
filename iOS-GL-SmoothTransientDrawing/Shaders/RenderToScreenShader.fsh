
varying lowp vec2 vUV;

uniform sampler2D renderToScreenTexture;

void main() {
    gl_FragColor = texture2D(renderToScreenTexture, vUV);
}
