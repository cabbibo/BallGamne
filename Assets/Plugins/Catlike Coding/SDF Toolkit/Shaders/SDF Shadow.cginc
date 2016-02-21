/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * An adaptation of the Unity 5 standard shader code to work with SDF.
 */

#define SDF_SHADOW

#include "SDF.cginc"

#if defined(_SEMITRANSPARENT_SHADOWS_ON) && !defined(_ALPHATEST_ON)
	// Do dithering for alpha blended shadows on SM3+/desktop;
	// on lesser systems do simple alpha-tested shadows
	#if !((SHADER_TARGET < 30) || defined (SHADER_API_MOBILE) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
		#define UNITY_STANDARD_USE_DITHER_MASK
		sampler3D _DitherMaskLOD;
	#endif
#endif

// We have to do these dances of outputting SV_POSITION separately from the vertex shader,
// and inputting VPOS in the pixel shader, since they both map to "POSITION" semantic on
// some platforms, and then things don't go well.
void vertShadowCaster (VertexInput v, out v2fSDF o, out float4 opos : SV_POSITION) {
	o = CreateV2FSDF(v);
	#if defined(SDF_UNLIT)
		// Use legacy macro that doesn't apply normal offset for unlit, so it doesn't need normals.
		TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o, opos)
	#else
		TRANSFER_SHADOW_CASTER_NOPOS(o, opos)
	#endif
}

#if defined(UNITY_STANDARD_USE_DITHER_MASK)
	half4 fragShadowCaster (v2fSDF i, UNITY_VPOS_TYPE vpos : VPOS) : SV_Target {
		SDFData d = FillData(i);
		SDFResult r = sampleColor(d, getBlendFactors(d, d.distance));
		// Use dither mask for alpha blended shadows, based on pixel position xy
		// and alpha level. Our dither texture is 4x4x16.
		half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, r.alpha * 0.9375)).a;
		clip(alphaRef - 0.01);
		SHADOW_CASTER_FRAGMENT(i)
	}
#else
	half4 fragShadowCaster (v2fSDF i) : SV_Target {
		SDFData d = FillData(i);
		SDFResult r = sampleColor(d, getBlendFactors(d, d.distance));
		clip(r.alpha - _Cutoff);
		SHADOW_CASTER_FRAGMENT(i)
	}
#endif
