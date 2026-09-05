shader_type sky;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void sky() {
	float elevation=max(EYEDIR.y,0.0);
	float azimuth=atan(EYEDIR.x,-EYEDIR.z);
	vec3 horizon=vec3(0.65,0.71,0.68);
	vec3 indigo=vec3(0.10,0.25,0.36);
	vec3 color=mix(horizon,indigo,smoothstep(0.0,0.24,elevation));
	float layer=elevation*24.0;
	float row=floor(layer);
	float across=azimuth*9.0;
	float tear=(noise(vec2(across*2.0,row*3.0))-0.5)*0.18;
	float ribbon=smoothstep(0.18,0.21,fract(layer)+tear)*(1.0-smoothstep(0.44,0.47,fract(layer)+tear));
	float breaks=smoothstep(0.40,0.52,noise(vec2(across,row*9.0)));
	float cloud=ribbon*breaks*smoothstep(0.025,0.09,elevation)*(1.0-smoothstep(0.68,0.9,elevation));
	float fiber=hash(floor(vec2(azimuth,elevation)*1800.0))-0.5;
	color=mix(color,vec3(0.90,0.86,0.72),cloud*0.90);
	COLOR=color+fiber*0.012;
}
