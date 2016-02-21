/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * An adaptation of the Unity 5 standard shader code to work with SDF.
 */
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

#include "SDF.cginc"

// Copied from UnityStandardCore.
half3 NormalizePerVertexNormal (half3 n) {
	#if (SHADER_TARGET < 30)
		return normalize(n);
	#else
		return n; // will normalize per-pixel instead
	#endif
}

// Copied from UnityStandardCore.
half3 NormalizePerPixelNormal (half3 n) {
	#if (SHADER_TARGET < 30)
		return n;
	#else
		return normalize(n);
	#endif
}

// Copied from UnityStandardCore.
struct FragmentCommonData {
	half3 diffColor, specColor;
	// Note: oneMinusRoughness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
	// Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
	half oneMinusReflectivity, oneMinusRoughness;
	half3 normalWorld, eyeVec, posWorld;
	half alpha;
};

// Copied form UnityStandardCore, changed to use final input data instead of uv.
inline FragmentCommonData SpecularSetup (half4 specGloss, half3 albedo) {
	half3 specColor = specGloss.rgb;
	half oneMinusRoughness = specGloss.a;

	half oneMinusReflectivity;
	half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular(albedo, specColor, /*out*/ oneMinusReflectivity);
	
	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
}

// Copied from UnityStandardCore, changed to use final input data instead of uv.
inline FragmentCommonData MetallicSetup (half2 metallicGloss, half3 albedo) {
	half metallic = metallicGloss.x;
	half oneMinusRoughness = metallicGloss.y;

	half oneMinusReflectivity;
	half3 specColor;
	half3 diffColor = DiffuseAndSpecularFromMetallic(albedo, metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
}

half3 PerPixelWorldNormal (half3 normalTangent, half4 tangentToWorld[3]) {
	#if defined(_NORMALMAP) || defined(_BEVEL_ON)
		half3 tangent = tangentToWorld[0].xyz;
		half3 binormal = tangentToWorld[1].xyz;
		half3 normal = tangentToWorld[2].xyz;
		
		#if UNITY_TANGENT_ORTHONORMALIZE
			normal = NormalizePerPixelNormal(normal);

			// ortho-normalize Tangent
			tangent = normalize(tangent - normal * dot(tangent, normal));

			// recalculate Binormal
			half3 newB = cross(normal, tangent);
			binormal = newB * sign(dot(newB, binormal));
		#endif
		
		half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);
	#else
		half3 normalWorld = normalize(tangentToWorld[2].xyz);
	#endif
	return normalWorld;
}

// Customized FragmentSetup.
inline FragmentCommonData FragmentSetup (SDFResult r, half3 i_eyeVec, half4 tangentToWorld[3], half3 i_posWorld) {
	
	#if defined(SDF_SPECULAR)
		FragmentCommonData o = SpecularSetup(r.specGloss, r.albedo);
	#else
		FragmentCommonData o = MetallicSetup(r.metallicGloss, r.albedo);
	#endif
	
	o.normalWorld = PerPixelWorldNormal(r.normal, tangentToWorld);
	o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
	o.posWorld = i_posWorld;
	o.diffColor = PreMultiplyAlpha(o.diffColor, r.alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
	return o;
}

#if UNITY_SPECCUBE_BOX_PROJECTION
	#define IN_WORLDPOS(i) i.posWorld
#else
	#define IN_WORLDPOS(i) half3(0,0,0)
#endif

// Copied from UnityStandardCore.
inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light, bool reflections) {
	UnityGIInput d;
	d.light = light;
	d.worldPos = s.posWorld;
	d.worldViewDir = -s.eyeVec;
	d.atten = atten;
	#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
		d.ambient = 0;
		d.lightmapUV = i_ambientOrLightmapUV;
	#else
		d.ambient = i_ambientOrLightmapUV.rgb;
		d.lightmapUV = 0;
	#endif
	d.boxMax[0] = unity_SpecCube0_BoxMax;
	d.boxMin[0] = unity_SpecCube0_BoxMin;
	d.probePosition[0] = unity_SpecCube0_ProbePosition;
	d.probeHDR[0] = unity_SpecCube0_HDR;

	d.boxMax[1] = unity_SpecCube1_BoxMax;
	d.boxMin[1] = unity_SpecCube1_BoxMin;
	d.probePosition[1] = unity_SpecCube1_ProbePosition;
	d.probeHDR[1] = unity_SpecCube1_HDR;

	if(reflections)
	{
		Unity_GlossyEnvironmentData g;
		g.roughness		= 1 - s.oneMinusRoughness;
//	#if UNITY_OPTIMIZE_TEXCUBELOD || UNITY_STANDARD_SIMPLE
//		g.reflUVW 		= s.reflUVW;
//	#else
		g.reflUVW		= reflect(s.eyeVec, s.normalWorld);
//	#endif

		return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
	}
	else
	{
		return UnityGlobalIllumination (d, occlusion, s.normalWorld);
	}
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
	return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}