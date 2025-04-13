shader_type canvas_item;

uniform bool seleccionado = false;
uniform vec4 color_emision : source_color = vec4(0.5, 1.0, 0.5, 1.0);

void fragment() {
    vec4 color_base = texture(TEXTURE, UV);  // Color original del sprite con alfa
    if (seleccionado && color_base.a > 0.0) {  // Solo aplicar si el píxel no es transparente
        COLOR = vec4(color_base.rgb + color_emision.rgb, color_base.a);  // Sumar emisión, mantener alfa
    } else {
        COLOR = color_base;  // Mantener el color original (incluyendo transparencia)
    }
}