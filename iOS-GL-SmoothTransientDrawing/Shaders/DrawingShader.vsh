
attribute vec4 position;
attribute vec2 uv;

uniform float uCurrLineDrawTimeDelta;
uniform float uAspectRatio;
uniform vec3 uColor;

varying vec4 vColor;

const float LineHalfWidth = 0.01;
const float LineDecayTimeInSeconds = 1.25;
const float LineGlow = 2.0;
const float ColorChangeTimeInSeconds = 0.5;

void main() {
    float interval = uCurrLineDrawTimeDelta - uv.x;
    
    float opacityT = clamp(1.0 - (interval / LineDecayTimeInSeconds), 0.0, 1.0);
    float opacity = opacityT * LineGlow;
    
    float colorT = clamp(interval / ColorChangeTimeInSeconds, 0.0, 1.0);
    
    vColor = mix(vec4(1.0, 1.0, 1.0, opacity), vec4(uColor, opacity), colorT);
    
    vec2 opacityBasedPosition = vec2(position.x + position.z * opacity * LineHalfWidth * uAspectRatio,
                                     position.y + position.w * opacity * LineHalfWidth);
    gl_Position = vec4(opacityBasedPosition.x, opacityBasedPosition.y, 0.0, 1.0);
}
