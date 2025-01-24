shader_type canvas_item;

uniform vec2 mouse_position; // Normalized mouse position (0 to 1 in viewport space)
uniform float poke_strength : hint_range(0.0, 1.0) = 0.3; // Strength of the inward deformation
uniform float deformation_radius : hint_range(0.0, 1.0) = 0.5; // Area of influence for deformation

void fragment() {
    vec2 uv = UV; // Normalized texture coordinates
    vec2 center = vec2(0.5); // Center of the bubble in UV space

    // Calculate distance and direction
    float distance_from_center = length(uv - center);
    vec2 direction_to_mouse = normalize(mouse_position - center); // From bubble center to mouse
    vec2 direction_to_uv = normalize(uv - center); // From bubble center to current pixel
    float distance_from_mouse = length(uv - mouse_position);

    // Define bubble boundary
    float bubble_radius = 0.4; // Bubble radius

    // Apply deformation only if within range
    float mouse_influence = smoothstep(deformation_radius, 0.0, distance_from_mouse);

    // Stronger inward deformation near the mouse
    vec2 inward_deformation = -direction_to_mouse * mouse_influence * poke_strength * max(0.0, 1.0 - distance_from_center / bubble_radius);

    // Subtle outward deformation to balance (reduce this to focus on inward pull)
    vec2 outward_deformation = direction_to_uv * mouse_influence * poke_strength * 0.2;

    // Combine inward and outward deformations
    vec2 deformation = inward_deformation + outward_deformation;

    // Modify the bubble boundary
    float deformation_effect = dot(deformation, direction_to_uv);
    float bubble_edge = bubble_radius - distance_from_center + deformation_effect;

    // Render bubble with circular clipping
    if (bubble_edge > 0.0) {
        COLOR = vec4(0.6, 0.8, 1.0, 1.0); // Light blue bubble color
    } else {
        discard; // Transparent outside the bubble
    }
}
