#version 330

// Input vertex attributes (from vertex shader)
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform sampler2D mask;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

/* vec3 alumi[] = vec3[]( vec3(0.223, 0.164, 0.109), vec3(0.407, 0.298, 0.235), vec3(0.572, 0.494, 0.415), vec3(0.937, 0.847, 0.631)); */
/* vec3 steel[] = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.223, 0.164, 0.109), vec3(0.407, 0.298, 0.235), vec3(0.572, 0.494, 0.415)); */
/* vec3 tire[]  = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.121, 0.141, 0.039), vec3(0.223, 0.164, 0.109), vec3(0.407, 0.298, 0.235)); */
/* vec3 wood[]  = vec3[]( vec3(0.211, 0.090, 0.047), vec3(0.270, 0.137, 0.050), vec3(0.447, 0.254, 0.074), vec3(0.670, 0.360, 0.109)); */
/* vec3 grass[] = vec3[]( vec3(0.121, 0.141, 0.039), vec3(0.223, 0.341, 0.109), vec3(0.647, 0.549, 0.152), vec3(0.937, 0.674, 0.156)); */
/* vec3 leaf[]  = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.121, 0.141, 0.039), vec3(0.223, 0.341, 0.109), vec3(0.647, 0.549, 0.152)); */
/* vec3 sand[]  = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.937, 0.674, 0.156), vec3(0.937, 0.717, 0.458), vec3(0.937, 0.847, 0.631)); */
/* vec3 water[] = vec3[]( vec3(0.094, 0.247, 0.223), vec3(0.152, 0.392, 0.407), vec3(0.235, 0.623, 0.611), vec3(0.937, 0.847, 0.631)); */
/* vec3 sky[]   = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.094, 0.247, 0.223), vec3(0.152, 0.392, 0.407), vec3(0.235, 0.623, 0.611)); */
/* vec3 warn[]  = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.937, 0.674, 0.156), vec3(0.937, 0.674, 0.156), vec3(0.937, 0.847, 0.631)); */
/* vec3 blood[] = vec3[]( vec3(0.211, 0.090, 0.047), vec3(0.333, 0.058, 0.039), vec3(0.607, 0.101, 0.039), vec3(0.937, 0.227, 0.047)); */
/* vec3 clear[] = vec3[]( vec3(0.164, 0.113, 0.050), vec3(0.164, 0.113, 0.050), vec3(0.937, 0.847, 0.631), vec3(0.937, 0.847, 0.631)); */

vec3 alumi[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.490, 0.439, 0.443), vec3(0.627, 0.576, 0.556), vec3(0.874, 0.964, 0.960));
vec3 steel[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.188, 0.172, 0.180), vec3(0.352, 0.325, 0.325), vec3(0.490, 0.439, 0.443));
vec3 tire[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.188, 0.172, 0.180), vec3(0.223, 0.278, 0.470), vec3(0.352, 0.325, 0.325));
vec3 wood[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.627, 0.356, 0.325), vec3(0.749, 0.474, 0.345), vec3(0.933, 0.631, 0.376));
vec3 grass[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.223, 0.482, 0.266), vec3(0.443, 0.666, 0.203), vec3(0.713, 0.835, 0.235));
vec3 leaf[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.235, 0.349, 0.337), vec3(0.223, 0.482, 0.266), vec3(0.443, 0.666, 0.203));
vec3 sand[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.956, 0.705, 0.105), vec3(0.933, 0.631, 0.376), vec3(0.956, 0.8, 0.631));
vec3 sea[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.223, 0.278, 0.470), vec3(0.156, 0.8, 0.874), vec3(0.874, 0.964, 0.960));
vec3 sky[] = vec3[]( vec3(0.223, 0.470, 0.658), vec3(0.156, 0.8, 0.874), vec3(0.541, 0.921, 0.945), vec3(0.874, 0.964, 0.960));
vec3 warn[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.956, 0.494, 0.105), vec3(0.956, 0.494, 0.105), vec3(0.956, 0.705, 0.105));
vec3 blood[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.662, 0.231, 0.231), vec3(0.901, 0.282, 0.180), vec3(0.956, 0.494, 0.105));
vec3 clear[] = vec3[]( vec3(0.223, 0.192, 0.294), vec3(0.811, 0.776, 0.721), vec3(0.874, 0.964, 0.960), vec3(0.874, 0.964, 0.960));

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}
float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

vec3 dithermono(vec2 pos, vec4 col, vec4 maskCol) {
    int red = int(maskCol.r * 256.0);
    int green = int(maskCol.g * 256.0);
    int blue = int(maskCol.b * 256.0);
    vec3 palette[] = steel;


    if (red < 64) { // 20
        if (green < 64) { // 20
            if (blue < 64) { // 20
                palette = tire;
            }; 
        } else if (green < 128) { // 60
            if (blue < 64) { // 20
                palette = leaf;
            } else { // E0
                palette = sea;
            };
        } else if (green < 192) { // A0
            if (blue < 64) { // 20
            } else { // E0
                palette = sky;
            };
        };
    } else if (red < 128) { // 60
        if (green < 64) { // 20
            if (blue < 64) { // 20
                palette = wood;
            };
        } else if (green < 128) { // 60
            if (blue < 64) { // 20
            } else if (blue < 128) { // 60
                palette = steel;
            };
        } else if (green < 192) { // A0
            if (blue < 64) { // 20
                palette = grass;
            };
        } else { // E0
            if (blue < 64) { // 20
            };
        };
    } else if (red < 192) { // A0
        if (green < 64) { // 20
            if (blue < 64) { // 20
            };
        } else if (green < 128) { // 60
            if (blue < 64) { // 20
            };
        } else if (green < 192) { // A0
            if (blue < 64) { // 20
                palette = alumi;
            };
        } else { // E0
            if (blue < 64) { // 20
            };
        };
    } else { // E0
        if (green < 64) { // 20
            if (blue < 64) { // 20
                palette = blood;
            };
        } else if (green < 128) { // 60
            if (blue < 64) { // 20
            };
        } else if (green < 192) { // A0
            if (blue < 64) { // 20
                palette = warn;
            };
        } else { // E0
            /* if (blue < 64) { // 20 */
            if (blue < 192) {
                palette = sand;
            } else { // E0
                palette = clear;
            };
        };
    };

    float bands = palette.length();
    float bri = luma(col);

    int pixelSize = 1;
    pos = pos - mod(pos, pixelSize);
	float x = floor(mod(pos.x, 4.0*pixelSize))/pixelSize;
	float y = floor(mod(pos.y, 4.0*pixelSize))/pixelSize;
	float index = floor(x + y * 4.0);

	/* float x = floor(mod(pos.x, 4.0)); */
	/* float y = floor(mod(pos.y, 4.0)); */
	/* float index = floor(x + y * 4.0); */
	float limit = 0.0;
	float stepp = 1.0 / bands;
	/* float stepp = 2.0 / bands; */

    float matrix[16] = float[](
		0.0625, 0.5625, 0.1875, 0.6875, 
        0.8125, 0.3125, 0.9375, 0.4375, 
        0.25,   0.75,   0.125,  0.625,  
        1.0,    0.5,    0.875,  0.375   
    );

    limit = matrix[int(index)];
	float a = bri - mod(bri,stepp);
    float b = a + stepp;
	limit = limit/bands + a;
	float _out = a;
	if (bri > limit) { _out = b; };
    return palette[int(floor(_out*bands*0.99))];
}

void main() {

    vec4 texelColor = texture(texture0, fragTexCoord);
    vec3 lightDot = vec3(0.0);
    vec3 normal = normalize(fragNormal);
    vec3 specular = vec3(0.0);
    vec3 light = vec3(0.0);

    light = -normalize(vec3(0.0,0.0,0.0) - vec3(1.0,1.0,1.0));
    /* light = normalize(lights[0].position - fragPosition); */
    /* float NdotL = max(-dot(normal, light), 0.0); */
    float NdotL = (-dot(normal, light) * 0.5) + 0.5;
    /* lightDot += lights[0].color.rgb*NdotL; */
    lightDot += vec3(1.0,1.0,1.0).rgb*NdotL;

    float specCo = 0.0;
    // Specularity
    specular += specCo;

    finalColor += texelColor*(vec4(0.4,0.4,0.4,1.0)/10.0)*colDiffuse;
    finalColor = (texelColor*((colDiffuse + vec4(specular, 1.0))*0.5*vec4(lightDot, 1.0)));
    /* finalColor += texelColor*(0.8/10.0)*colDiffuse; */

    // Gamma correction
    finalColor = pow(finalColor, vec4(1.0/2.2));

    vec4 maskColor = texture(mask, fragTexCoord);
    
    finalColor = vec4(dithermono(gl_FragCoord.xy, finalColor, maskColor), 1.0);
}
