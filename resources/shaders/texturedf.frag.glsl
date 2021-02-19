#version 450

in vec4 outColor;
in vec2 outTexCoord;
in float outTexFormat;

uniform sampler2D tex;

out vec4 FragColor;

void main(){
	vec4 texColor = texture(tex, outTexCoord);

	if(outTexFormat < 0.5) { //RGBA32
		texColor *= outColor;
		texColor.rgb *= outColor.a;
	} else if(outTexFormat < 1.5) { //L8
		texColor = texColor.rrrr * outColor;
	}

	FragColor = texColor;
}