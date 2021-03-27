#version 450

in vec4 outColor;
in vec2 outTexCoord;
in float outTexId;

uniform sampler2D tex[8];

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
	} else {
		texColor = texture(tex[7], outTexCoord);
	}

	texColor.rgb *= outColor.a;
	texColor *= outColor;

	FragColor = texColor;
}
