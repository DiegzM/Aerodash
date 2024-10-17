shader_type spatial;

uniform vec3 outline_color = vec3(1.0, 1.0, 1.0); // Default outline color set to white
uniform float outline_thickness = 0.055; // Thickness of the outline

render_mode cull_front, unshaded; // Render only the back faces, unshaded for pure color

void fragment() {
    ALBEDO = outline_color; // Set the color of the outline
}

void vertex() {
    VERTEX += NORMAL * outline_thickness; // Push vertices outward to create an outline effect
}
