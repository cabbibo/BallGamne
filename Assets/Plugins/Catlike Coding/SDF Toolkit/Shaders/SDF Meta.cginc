/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * An adaptation of the Unity 5 standard shader code to work with SDF.
 */

#define SDF_META

#include "SDF Standard.cginc"

#include "UnityMetaPass.cginc"

// copied from core and tweaked until it work

// Copied from UnityStandardMeta:
// Albedo for lightmapping should basically be diffuse color.
// But rough metals (black diffuse) still scatter quite a lot of light around, so
// we want to take some of that into account too.
half3 UnityLightmappingAlbedo (half3 diffuse, half3 specular, half oneMinusRoughness)
{
	half roughness = 1 - oneMinusRoughness;
	half3 res = diffuse;
	res += specular * roughness * roughness * 0.5;
	return res;
}

v2fSDF vertMeta (VertexInput v) {
	v2fSDF o = CreateV2FSDF(v);
	o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
	return o;
}

float4 fragMeta (v2fSDF i) : SV_Target {
	SDFData d = FillData(i);
	SDFResult r = sampleColor(d, getBlendFactors(d, d.distance));
	
	UnityMetaInput o;
	// Enlighten doesn't do transparency, so no clipping. Instead modulate color.
	// Multiply albedo with alpha to fade out contribution of transparent areas.
	#if defined(SDF_UNLIT)
		o.Albedo = r.albedo * r.alpha;
		// If you bother to lightmap unlit stuff, let it emit.
		o.Emission = o.Albedo;
	#else
		#if defined(SDF_SPECULAR)
			FragmentCommonData data = SpecularSetup(r.specGloss, r.albedo);
		#else
			FragmentCommonData data = MetallicSetup(r.metallicGloss, r.albedo);
		#endif
		o.Albedo = UnityLightmappingAlbedo(data.diffColor, data.specColor, data.oneMinusRoughness) * r.alpha;
		o.Emission = r.emission * r.alpha;
	#endif
	return UnityMetaFragment(o);
}
