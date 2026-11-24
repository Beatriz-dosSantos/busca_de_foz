shader_type canvas_item;

void fragment() {
	vec2 tamanho = vec2(textureSize(TEXTURE, 0));
	vec2 px = UV * tamanho;
	vec2 borda = floor(px + 0.5);
	vec2 px_tela = max(fwidth(px), vec2(1e-5));
	px = borda + clamp((px - borda) / px_tela, -0.5, 0.5);
	COLOR = texture(TEXTURE, px / tamanho);
}
