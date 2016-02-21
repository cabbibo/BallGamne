/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

#include "SDF.cginc"

v2fSDF vert (VertexInput v) {
	v2fSDF o = CreateV2FSDF(v);
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	return o;
}

float4 frag (v2fSDF f) : SV_Target {
	SDFData d = FillData(f);
	SDFResult r = sampleColor(d, getBlendFactors(d, d.distance));
	#if defined(SDF_SUPERSAMPLE)
		supersample(d, r);
	#endif
	#if defined(_ALPHATEST_ON)
		clip(r.alpha - _Cutoff);
		r.alpha = 1;
	#endif
	return float4(r.albedo, r.alpha);
}
