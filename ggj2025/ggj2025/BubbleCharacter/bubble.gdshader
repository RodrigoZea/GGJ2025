shader_type canvas_item;

// Animate the wave (looping animation)
uniform float progress: hint_range(0.0, 1.0) = 0.0;

// Wave amplitude (controls how strong the wave effect is)
uniform float meltness: hint_range(0.0, 3.0) = 1.0;

// Wave frequency (controls how many waves appear across the sprite)
uniform float wave_frequency: hint_range(0.0, 30.0) = 20.0;

// Animation speed multiplier
uniform float speed: hint_range(0.0, 10.0) = 1.0;

float wave(float x, float y) {
    return sin(2.0 * PI * (progress * speed) + wave_frequency * x + wave_frequency * y);
}

void fragment() {
    vec2 uv = UV;

    // Apply a wave effect to both X and Y UV coordinates
    uv.x += wave(uv.y, uv.x) * meltness * 0.01;
    uv.y += wave(uv.x, uv.y) * meltness * 0.01;

    // Sample the texture with the distorted UVs
    COLOR = texture(TEXTURE, uv);

    // Ensure the alpha doesn't extend outside the texture boundaries
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR.a = 0.0;
    }
}
