/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * An adaptation of the Unity 5 standard shader code to work with SDF.
 */
 
 #include "SDF Standard.cginc"

void TransferFog (inout v2fSDF o) {
	// UNITY_TRANSFER_FOG expects a struct with fogCoord.
	struct FogDummy {
		float fogCoord;
	};
	FogDummy fogDummy;
	fogDummy.fogCoord = 0;
	UNITY_TRANSFER_FOG(fogDummy, o.pos);
	// Piggyback fog coordinate.
	o.uvSDF.z = fogDummy.fogCoord;
}

#if defined(SDF_FORWARD_BASE)
	
	half4 VertexGIForward (VertexInput v, float3 posWorld, half3 normalWorld) {
		half4 ambientOrLightmapUV = 0;
		// Static lightmaps
		#ifndef LIGHTMAP_OFF
			ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			ambientOrLightmapUV.zw = 0;
		// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
		#elif UNITY_SHOULD_SAMPLE_SH
			#if UNITY_SAMPLE_FULL_SH_PER_PIXEL
				ambientOrLightmapUV.rgb = 0;
			#elif (SHADER_TARGET < 30)
				ambientOrLightmapUV.rgb = ShadeSH9(half4(normalWorld, 1.0));
			#else
				// Optimization: L2 per-vertex, L0..L1 per-pixel
				ambientOrLightmapUV.rgb = ShadeSH3Order(half4(normalWorld, 1.0));
			#endif
			// Add approximated illumination from non-important point lights
			#ifdef VERTEXLIGHT_ON
				ambientOrLightmapUV.rgb += Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, posWorld, normalWorld);
			#endif
		#endif
		
		#ifdef DYNAMICLIGHTMAP_ON
			ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif
		
		return ambientOrLightmapUV;
	}

	v2fSDF vertForward (VertexInput v) {
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
		
		TRANSFER_SHADOW(o);
		o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
		TransferFog(o);
		return o;
	}

#elif defined(SDF_FORWARD_ADD)

	v2fSDF vertForwardAdd (VertexInput v) {
		v2fSDF o = CreateV2FSDF(v);
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		float4 posWorld = mul(_Object2World, v.vertex);
		o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
		float3 normalWorld = UnityObjectToWorldNormal(v.normal);
		
		#ifdef _TANGENT_TO_WORLD
			float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

			float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
			o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
			o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
			o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
		#else
			o.tangentToWorldAndLightDir[0].xyz = 0;
			o.tangentToWorldAndLightDir[1].xyz = 0;
			o.tangentToWorldAndLightDir[2].xyz = normalWorld;
		#endif
		
		//We need this for shadow receving
		TRANSFER_VERTEX_TO_FRAGMENT(o);

		float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
		#ifndef USING_DIRECTIONAL_LIGHT
			lightDir = NormalizePerVertexNormal(lightDir);
		#endif
		o.tangentToWorldAndLightDir[0].w = lightDir.x;
		o.tangentToWorldAndLightDir[1].w = lightDir.y;
		o.tangentToWorldAndLightDir[2].w = lightDir.z;

		TransferFog(o);
		return o;
	}
	
#endif

float4 OutputFragment (half3 color, half alpha, float2 blendFactors) {
	#if defined(_ALPHAPREMULTIPLY_ON)
		// Eliminate lighting outside the contours.
		#if defined(_CONTOUR2_ON)
			return float4(color, alpha) * blendFactors.y;
		#else
			return float4(color, alpha) * blendFactors.x;
		#endif
	#else
		return float4(color, alpha);
	#endif
}

#if defined(SDF_FORWARD_BASE)
	
	UnityLight MainLight (half3 normalWorld) {
		UnityLight l;
		#ifdef LIGHTMAP_OFF
			
			l.color = _LightColor0.rgb;
			l.dir = _WorldSpaceLightPos0.xyz;
			l.ndotl = LambertTerm (normalWorld, l.dir);
		#else
			// no light specified by the engine
			// analytical light might be extracted from Lightmap data later on in the shader depending on the Lightmap type
			l.color = half3(0.f, 0.f, 0.f);
			l.ndotl  = 0.f;
			l.dir = half3(0.f, 0.f, 0.f);
		#endif

		return l;
	}
	
	float4 fragForward (v2fSDF i) : SV_Target {
		SDFData d = FillData(i);
		float2 blendFactors = getBlendFactors(d, d.distance);
		SDFResult r = sampleColor(d, blendFactors);
		
		#if defined(_NORMALMAP) || defined(_BEVEL_ON)
			sampleNormal(d, r, blendFactors);
		#endif
		
		#if defined(SDF_SUPERSAMPLE)
			supersample(d, r);
		#endif
		
		#if defined(_ALPHATEST_ON)
			clip(r.alpha - _Cutoff);
			r.alpha = 1;
		#elif defined(_ALPHAPREMULTIPLY_ON) && !defined(SHADER_API_MOBILE)
			// Optimization for non-mobiles.
			clip(r.alpha - 0.001);
		#endif
		
		// FRAGMENT_SETUP(s)
		half3 posWorld = IN_WORLDPOS(i);
		FragmentCommonData s = FragmentSetup(
			r,
			i.eyeVec,
			i.tangentToWorldAndParallax,
			posWorld);
		
		UnityLight mainLight = MainLight(s.normalWorld);
		half atten = SHADOW_ATTENUATION(i);
		
		half occlusion = 1;
		UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, mainLight);
		half4 c = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
		c.rgb += UNITY_BRDF_GI(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);
		c.rgb += r.emission;

		UNITY_APPLY_FOG(i.uvSDF.z, c.rgb);
		
		return OutputFragment(c.rgb, s.alpha, blendFactors);
	}

#elif defined(SDF_FORWARD_ADD)
	
	UnityLight AdditiveLight (half3 normalWorld, half3 lightDir, half atten) {
		UnityLight l;

		l.color = _LightColor0.rgb;
		l.dir = lightDir;
		#ifndef USING_DIRECTIONAL_LIGHT
			l.dir = NormalizePerPixelNormal(l.dir);
		#endif
		l.ndotl = LambertTerm (normalWorld, l.dir);

		// shadow the light
		l.color *= atten;
		return l;
	}
	
	UnityIndirect ZeroIndirect () {
		UnityIndirect ind;
		ind.diffuse = 0;
		ind.specular = 0;
		return ind;
	}
	
	half4 fragForwardAdd (v2fSDF i) : SV_Target {
		SDFData d = FillData(i);
		float2 blendFactors = getBlendFactors(d, d.distance);
		SDFResult r = sampleColor(d, blendFactors);
		
		#if defined(_NORMALMAP) || defined(_BEVEL_ON)
			sampleNormal(d, r, blendFactors);
		#endif
		
		#if defined(SDF_SUPERSAMPLE)
			supersample(d, r);
		#endif
		
		#if defined(_ALPHATEST_ON)
			clip(r.alpha - _Cutoff);
			r.alpha = 1;
		#elif defined(_ALPHAPREMULTIPLY_ON) && !defined(SHADER_API_MOBILE)
			// Optimization for non-mobiles.
			clip(r.alpha - 0.001);
		#endif
		
		FragmentCommonData s = FragmentSetup(
			r,
			i.eyeVec,
			i.tangentToWorldAndLightDir,
			half3(0, 0, 0));
		
		half3 lightDir = half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w); // IN_LIGHTDIR_FWDADD(i)
		
		UnityLight light = AdditiveLight(s.normalWorld, lightDir, LIGHT_ATTENUATION(i));
		UnityIndirect noIndirect = ZeroIndirect();

		half4 c = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, light, noIndirect);
		
		UNITY_APPLY_FOG_COLOR(i.uvSDF.z, c.rgb, half4(0, 0, 0, 0)); // fog towards black in additive pass
		
		return OutputFragment(c.rgb, s.alpha, blendFactors);
	}
	
#endif
