#version 450

in vec4 outColor;
in vec2 outTexCoord;
in float outTexId;
in float outTexFormat;

uniform sampler2D tex[8];

out vec4 FragColor;

vec4 effect(sampler2D tex, vec4 color, vec2 texCoord){
	vec4 texColor = texture(tex, texCoord);

	if(outTexFormat == 1) texColor = texColor.rrrr;

	texColor.rgb *= color.a;
	texColor *= color;

	return texColor;
}

void main(){
	vec4 texColor;

	if(outTexId < 0.5) {
		texColor = effect(tex[0], outColor, outTexCoord);
	} else if(outTexId < 1.5) {
		texColor = effect(tex[1], outColor, outTexCoord);
	} else if(outTexId < 2.5) {
		texColor = effect(tex[2], outColor, outTexCoord);
	} else if(outTexId < 3.5) {
		texColor = effect(tex[3], outColor, outTexCoord);
	} else if(outTexId < 4.5) {
		texColor = effect(tex[4], outColor, outTexCoord);
	} else if(outTexId < 5.5) {
		texColor = effect(tex[5], outColor, outTexCoord);
	} else if(outTexId < 6.5) {
		texColor = effect(tex[6], outColor, outTexCoord);
	} else {
		texColor = effect(tex[7], outColor, outTexCoord);
	}

	FragColor = texColor;
}
