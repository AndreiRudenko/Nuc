#version 450

in vec4 outColor;
in vec2 outTexCoord;
in float outTexId;

uniform sampler2D tex[16];

out vec4 FragColor;

void main(){
	vec4 texColor;

	if(outTexId == 0) {
		texColor = texture(tex[0], outTexCoord);
	} else if(outTexId == 1) {
		texColor = texture(tex[1], outTexCoord);
	} else if(outTexId == 2) {
		texColor = texture(tex[2], outTexCoord);
	} else if(outTexId == 3) {
		texColor = texture(tex[3], outTexCoord);
	} else if(outTexId == 4) {
		texColor = texture(tex[4], outTexCoord);
	} else if(outTexId == 5) {
		texColor = texture(tex[5], outTexCoord);
	} else if(outTexId == 6) {
		texColor = texture(tex[6], outTexCoord);
	} else if(outTexId == 7) {
		texColor = texture(tex[7], outTexCoord);
	} else if(outTexId == 8) {
		texColor = texture(tex[8], outTexCoord);
	} else if(outTexId == 9) {
		texColor = texture(tex[9], outTexCoord);
	} else if(outTexId == 10) {
		texColor = texture(tex[10], outTexCoord);
	} else if(outTexId == 11) {
		texColor = texture(tex[11], outTexCoord);
	} else if(outTexId == 12) {
		texColor = texture(tex[12], outTexCoord);
	} else if(outTexId == 13) {
		texColor = texture(tex[13], outTexCoord);
	} else if(outTexId == 14) {
		texColor = texture(tex[14], outTexCoord);
	} else {
		texColor = texture(tex[15], outTexCoord);
	}

	texColor.rgb *= outColor.a;
	texColor *= outColor;

	FragColor = texColor;
}