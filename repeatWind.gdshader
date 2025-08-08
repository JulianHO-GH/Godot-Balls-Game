shader_type canvas_item;

uniform sampler2D texture : source_color; // Textura del viento
uniform float speed : hint_range(0.1, 10.0) = 2.0; // Velocidad del movimiento
uniform float fade_width : hint_range(0.0, 1.0) = 0.2; // Ancho del desvanecimiento en el borde derecho (0.0 a 0.5)

void fragment() {
    // Desplazar UV.x basado en el tiempo para el movimiento de derecha a izquierda
    float shifted_uv_x = UV.x - TIME * speed;
    // Usar mod para que la textura se repita continuamente
    vec2 repeated_uv = vec2(mod(shifted_uv_x, 1.0), UV.y);
    // Obtener el color de la textura
    vec4 color = texture(texture, repeated_uv);
    
    // Calcular el desvanecimiento en el borde derecho
    float fade = 1.0;
    if (fade_width > 0.0) {
        // Desvanecimiento suave en el borde derecho (UV.x cerca de 1.0)
        fade = smoothstep(1.0 - fade_width, 1.0, UV.x);
        fade = 1.0 - fade; // Invertir para que 1.0 sea opaco y 0.0 sea transparente
    }
    
    // Aplicar el desvanecimiento al canal alfa
    COLOR = vec4(color.rgb, color.a * fade);
}