shader_type canvas_item;

uniform vec2 squishDir = vec2(1.000000, 0.000000);
uniform float squishRatio = 1.0;
uniform vec2 squishPivot;
uniform vec2 holePos;
uniform float holeSize;
uniform vec2 shearPivot;
uniform vec2 shearAmts;

mat3 everything(vec2 tps){
	vec2 pixelSpace = vec2(1,1) / tps / vec2(2,2);
	vec2 v = normalize(squishDir);
	float s = squishRatio;
	vec2 w = squishPivot * pixelSpace;
	vec2 q = shearPivot * pixelSpace;
	vec2 r = -shearAmts;
	float a = v.x*v.y*(s-1./s);
	vec2 v2 = v*v;
	float vys = v2.x*s+v2.y/s;
	float vxs = v2.y*s+v2.x/s;
	mat3 spawnOfSatan = mat3(vec3(
			vys+r.y*a,
			a+r.y*vxs,
			0
		), vec3(
			r.x*vys+a,
			r.x*a+vxs,
			0
		), vec3(
			q.y*r.x*vys-r.y*q.x*a-w.x*(vys-1.)-w.y*a,
			q.y*r.x*a-r.y*q.x*(vxs)-w.x*a-w.y*(vxs-1.),
			1.
		)
	);
	return spawnOfSatan;
}

mat3 everythingInverse(vec2 tps){
	vec2 pixelSpace = vec2(1,1) / tps / vec2(2,2);
	vec2 v = normalize(squishDir);
	float s = squishRatio;
	vec2 w = vec2(0,0);
	vec2 q = vec2(0,0);
	vec2 r = -shearAmts;
	float a = v.x*v.y*(s-1./s);
	vec2 v2 = v*v;
	float vys = v2.x*s+v2.y/s;
	float vxs = v2.y*s+v2.x/s;
	mat3 spawnOfSatan = mat3(vec3(
			vys+r.y*a,
			a+r.y*vxs,
			0
		), vec3(
			r.x*vys+a,
			r.x*a+vxs,
			0
		), vec3(
			q.y*r.x*vys-r.y*q.x*a-w.x*(vys-1.)-w.y*a,
			q.y*r.x*a-r.y*q.x*(vxs)-w.x*a-w.y*(vxs-1.),
			1.
		)
	);
	return spawnOfSatan;
}

void vertex() {
	VERTEX = (everything(TEXTURE_PIXEL_SIZE)*vec3(VERTEX,1)).xy;
}

void fragment() {
	vec2 UVtransformed = (everythingInverse(TEXTURE_PIXEL_SIZE)*vec3(2.*UV-1.,1)).xy;
	vec2 holePosCalc = holePos*-1.*(1.-holeSize)/holeSize;
	vec2 UVabs = abs(UVtransformed-holePosCalc);
	if (max(UVabs.x,UVabs.y) > 1./holeSize){
		COLOR.a = 1.;
	} else{
		COLOR.a = 0.;
	}
		
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
