/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * An adaptation of the Unity 5 standard shader code to work with SDF.
 */
 
 #define SDF_DEFERRED

#define _ALPHATEST_ON
// _ALPHABLEND_ON and _ALPHAPREMULTIPLY_ON never use the deferred pass.

#include "SDF Standard.cginc"

v2fSDF vertDeferred (VertexInput v) {
	v2fSDF o = CreateV2FSDF(v);
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	
	float4 posWorld = mul(_Object2World, v.vertex);
	#if UNITY_SPECCUBE_BOX_PROJECTION
		o.posWorld = posWorld.xyz;
	#endif
	
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
		float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndParallax[0].xyz = 0;
		o.tangentToWorldAndParallax[1].xyz = 0;
		o.tangentToWorldAndParallax[2].xyz = normalWorld;
	#endif
	
	#ifndef LIGHTMAP_OFF
		o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		o.ambientOrLightmapUV.zw = 0;
	// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
	#elif UNITY_SHOULD_SAMPLE_SH
		#if (SHADER_TARGET < 30)
			o.ambientOrLightmapUV.rgb = ShadeSH9(half4(normalWorld, 1.0));
		#else
			// Optimization: L2 per-vertex, L0..L1 per-pixel
			o.ambientOrLightmapUV.rgb = ShadeSH3Order(half4(normalWorld, 1.0));
		#endif
	#endif
	
	#ifdef DYNAMICLIGHTMAP_ON
		o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif
	
	//	#ifdef _PARALLAXMAP
	//		TANGENT_SPACE_ROTATION;
	//		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
	//		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
	//		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
	//		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	//	#endif
		
	return o;
}

UnityLight DummyLight (half3 normalWorld) {
	UnityLight l;
	l.color = 0;
	l.dir = half3 (0,1,0);
	l.ndotl = LambertTerm(normalWorld, l.dir);
	return l;
}

void fragDeferred (
	v2fSDF i,
	out half4 outDiffuse : SV_Target0,			// RT0: diffuse color (rgb), occlusion (a)
	out half4 outSpecSmoothness : SV_Target1,	// RT1: spec color (rgb), smoothness (a)
	out half4 outNormal : SV_Target2,			// RT2: normal (rgb), --unused, very low precision-- (a) 
	out half4 outEmission : SV_Target3			// RT3: emission (rgb), --unused-- (a)
) {
	// TODO: Why is this even here?
	#if (SHADER_TARGET < 30)
		outDiffuse = 1;
		outSpecSmoothness = 1;
		outNormal = 0;
		outEmission = 0;
		return;
	#endif
	
	SDFData d = FillData(i);
	float2 blendFactors = getBlendFactors(d, d.distance);
	SDFResult r = sampleColor(d, blendFactors);
	#if defined(_NORMALMAP) || defined(_BEVEL_ON)
		sampleNormal(d, r, blendFactors);
	#endif
	
	#if defined(SDF_SUPERSAMPLE)
		// Of little use for the outer contour, but could still work for blending between the two contours.
		supersample(d, r);
	#endif
	
	// Always use alpha testing.
	clip(r.alpha - _Cutoff);
	
	// FRAGMENT_SETUP(s)
	half3 posWorld = IN_WORLDPOS(i);
	FragmentCommonData s = FragmentSetup(
		r,
		i.eyeVec,
		i.tangentToWorldAndParallax,
		posWorld);

	// no analytic lights in this pass
	UnityLight dummyLight = DummyLight(s.normalWorld);
	half atten = 1;

	// only GI
	half occlusion = 1;
	UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, dummyLight);
	half3 color = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;
	color += UNITY_BRDF_GI(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);
	color += r.emission;

	#ifndef UNITY_HDR_ON
		color.rgb = exp2(-color.rgb);
	#endif

	outDiffuse = half4(s.diffColor, occlusion);
	outSpecSmoothness = half4(s.specColor, s.oneMinusRoughness);
	outNormal = half4(s.normalWorld * 0.5 + 0.5, 1);
	outEmission = half4(color, 1);
}
