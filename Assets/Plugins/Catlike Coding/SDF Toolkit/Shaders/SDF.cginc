/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

#include "UnityCG.cginc"

sampler2D _MainTex, _AlbedoMap, _AlbedoMap2;
float4 _MainTex_ST, _AlbedoMap_ST, _AlbedoMap2_ST;
half _UVSet, _UVSet2;

half4 _Color, _Color2;

half _Cutoff;
half _Contour, _Contour2;
half _Smoothing, _Smoothing2;

sampler2D _MetallicGlossMap, _MetallicGlossMap2;
half _Metallic, _Metallic2;
sampler2D _SpecGlossMap, _SpecGlossMap2;
half3 _Specular, _Specular2;
half _Glossiness, _Glossiness2;

sampler2D _EmissionMap, _EmissionMap2;
half3 _EmissionColor, _EmissionColor2;

sampler2D _NormalMap, _NormalMap2;
half _NormalScale, _NormalScale2;

float _BevelScale;
float _BevelLow, _BevelHigh;
float _BevelLow2, _BevelHigh2;

#if defined(SDF_SPECULAR) || defined(SDF_METALLIC)
	#if defined(_NORMALMAP) || defined(_BEVEL_ON) || !defined(DIRLIGHTMAP_OFF)
		#define _TANGENT_TO_WORLD
	#endif

	#if defined(_BEVEL_ON)
		float4 _MainTex_TexelSize;
	#endif
#endif

#if defined(SDF_META) || defined(SDF_SHADOW)
	// Meta and shadow passes don't use automatic smoothing, but manual smoothing does influence them.
	#if !defined(_SMOOTHINGMODE_AUTO)
		#define SDF_SMOOTHING_MANUAL
	#endif
#else
	#if defined(_SMOOTHINGMODE_AUTO) || defined(_SMOOTHINGMODE_MIXED)
		#define SDF_SMOOTHING_AUTO
	#endif
	#if !defined(_SMOOTHINGMODE_AUTO)
		#define SDF_SMOOTHING_MANUAL
	#endif
#endif

#if defined(_SUPERSAMPLE_ON)
	#define SDF_SUPERSAMPLE
#endif

#if defined(_VERTEXCOLOR_ON) || (defined(_CONTOUR2_ON) && defined (_VERTEXCOLOR2_ON))
	#define SDF_VERTEXCOLOR
#endif

// Albedo is either only tint, only map, or both. These keywords are shared by both contours.
#if defined(_ALBEDOMAP) || defined(_ALBEDOTINTMAP)
	#define SDF_ALBEDOMAP
	#define SDF_TEXTURED
#endif
#if !defined(_ALBEDOMAP)
	#define SDF_ALBEDOTINT
#endif

#if !defined(SDF_TEXTURED)
	// Determine whether UV coordinates are needed for materials.
	#if defined(_SPECGLOSSMAP) || defined(_SPECGLOSSMAP2)
		#define SDF_TEXTURED
	#elif defined(_METALLICGLOSSMAP) || defined(_METALLICGLOSSMAP2)
		#define SDF_TEXTURED
	#elif defined(_EMISSIONMAP) || defined(_NORMALMAP)
		#define SDF_TEXTURED
	#endif
#endif

#if defined(SDF_UI) && defined(SDF_TEXTURED)
	float4 _AlbedoMap_TexelSize, _AlbedoMap2_TexelSize;
#endif

struct VertexInput {
	float4 vertex : POSITION;
	
	#if defined(SDF_VERTEXCOLOR)
		half4 color : COLOR;
	#endif
	
	#if !defined(SDF_META) && !defined(SDF_UNLIT)
		half3 normal : NORMAL;
	#endif
	
	#if defined(_TANGENT_TO_WORLD)
		half4 tangent : TANGENT;
	#endif
	
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	#if defined(SDF_META) || defined(DYNAMICLIGHTMAP_ON)
		// Realtime GI uv.
		float2 uv2 : TEXCOORD2;
	#endif
	float2 uv3 : TEXCOORD3;
};

#if defined(SDF_SHADOW)
	struct v2fSDF {
		#if defined(SDF_VERTEXCOLOR)
			half4 color : COLOR;
		#endif
		
		V2F_SHADOW_CASTER_NOPOS
		
		float2 uvSDF : TEXCOORD1;
		#if defined(SDF_TEXTURED)
			float4 uvM : TEXCOORD2;
		#endif
	};
#elif defined(SDF_META) || defined(SDF_UNLIT)
	struct v2fSDF {
		float4 pos : SV_POSITION;
		
		#if defined(SDF_VERTEXCOLOR)
			half4 color : COLOR;
		#endif
		
		float2 uvSDF : TEXCOORD0;
		#if defined(SDF_TEXTURED)
			float4 uvM : TEXCOORD1;
		#endif
		
	};
#elif defined(SDF_SPECULAR) || defined(SDF_METALLIC)
	struct v2fSDF {
		float4 pos : SV_POSITION;
		
		#if defined(SDF_VERTEXCOLOR)
			half4 color : COLOR;
		#endif
		
		float3 uvSDF : TEXCOORD0; // Added room for fog.
		#if defined(SDF_TEXTURED)
			float4 uvM : TEXCOORD1;
		#endif
		
		half3 eyeVec : TEXCOORD2;
		
		#if defined(SDF_FORWARD_BASE)
			half4 tangentToWorldAndParallax[3] : TEXCOORD3; // [3x3:tangentToWorld | 1x3:viewDirForParallax]
			half4 ambientOrLightmapUV : TEXCOORD6; // SH or Lightmap UV
			SHADOW_COORDS(7)
			
			// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
			#if UNITY_SPECCUBE_BOX_PROJECTION
				float3 posWorld : TEXCOORD8;
			#endif
		#elif defined(SDF_DEFERRED)
			half4 tangentToWorldAndParallax[3] : TEXCOORD3; // [3x3:tangentToWorld | 1x3:viewDirForParallax]
			half4 ambientOrLightmapUV : TEXCOORD6; // SH or Lightmap UV
			#if UNITY_SPECCUBE_BOX_PROJECTION
				float3 posWorld : TEXCOORD7;
			#endif
		#elif defined(SDF_FORWARD_ADD)
			half4 tangentToWorldAndLightDir[3] : TEXCOORD3; // [3x3:tangentToWorld | 1x3:lightDir]
			LIGHTING_COORDS(6,7)
		#endif
	};
#endif

// Pass SDF texture uv and color data from vertex to fragment.
v2fSDF CreateV2FSDF (VertexInput v) {
	v2fSDF o;
	UNITY_INITIALIZE_OUTPUT(v2fSDF, o);
	o.uvSDF.xy = TRANSFORM_TEX(v.uv0, _MainTex);
	
	#if defined(SDF_TEXTURED)
		// Branch on uniform variables instead of using more keywords.
		#if defined(SDF_UI)
			float2 uvM1 = _UVSet == 0 ? v.uv0 : (_UVSet == 1 ? v.uv1 : (v.uv1 * _AlbedoMap_TexelSize.xy));
		#else
			float2 uvM1 = _UVSet == 0 ? v.uv0 : (_UVSet == 1 ? v.uv1 : v.uv3);
		#endif
		o.uvM.xy = TRANSFORM_TEX(uvM1, _AlbedoMap);
		
		#if defined(_CONTOUR2_ON)
			#if defined(SDF_UI)
				float2 uvM2 = _UVSet2 == 0 ? v.uv0 : (_UVSet2 == 1 ? v.uv1 : (v.uv1 * _AlbedoMap2_TexelSize.xy));
			#else
				float2 uvM2 = _UVSet2 == 0 ? v.uv0 : (_UVSet2 == 1 ? v.uv1 : v.uv3);
			#endif
			o.uvM.zw = TRANSFORM_TEX(uvM2, _AlbedoMap2);
		#endif
	#endif
	
	#if defined(SDF_VERTEXCOLOR)
		o.color = v.color;
	#endif
	return o;
}

struct SDFData {
	float2 uvSDF;
	half distance;
	half2 range, range2;
	half3 albedo, albedo2;
	half alpha, alpha2;
	half4 specGloss, specGloss2;
	half2 metallicGloss, metallicGloss2;
	half3 emission, emission2;
	half3 normal, normal2;
};

// Create SDF data structure and initialize with sane defaults.
SDFData CreateSDFData () {
	SDFData d;
	d.uvSDF = 0;
	d.distance = 0;
	d.range = float2(0, 0);
	d.range2 = d.range;
	d.albedo = half3(0, 0, 0);
	d.albedo2 = d.albedo;
	d.alpha = 1;
	d.alpha2 = d.alpha;
	d.specGloss = half4(1, 1, 1, 1);
	d.specGloss2 = d.specGloss;
	d.metallicGloss = half2(0, 0);
	d.metallicGloss2 = d.metallicGloss;
	d.emission = half3(0, 0, 0);
	d.emission2 = d.emission;
	d.normal = half3(0, 0, 1);
	d.normal2 = d.normal;
	return d;
}

// Sample SDF texture to get a distance measure.
float sampleDistance (float2 uv) {
	#if defined(SDF_SUPERSAMPLE) && !defined(SHADER_API_MOBILE)
		// Shouldn't use mipmaps when supersampling.
		// But don't use tex2Dlod on mobiles, because of bad support.
		return tex2Dlod(_MainTex, float4(uv, 0, 0)).a;
	#else
		return tex2D(_MainTex, uv).a;
	#endif
}

// Extract SDF data from shader variables and vertex input.
SDFData FillData(v2fSDF i) {
	SDFData d = CreateSDFData();
	
	d.uvSDF = i.uvSDF;
	d.distance = sampleDistance(d.uvSDF);
	
	half smoothing = 0;
	#if defined(SDF_SMOOTHING_AUTO)
		smoothing = fwidth(d.distance);
	#endif
	half smoothing2 = smoothing;
	
	#if defined(SDF_SMOOTHING_MANUAL)
		smoothing += _Smoothing;
		smoothing2 += _Smoothing2;
	#endif
	
	d.range = half2(_Contour - smoothing, _Contour + smoothing);
	d.range2 = half2(_Contour2 - smoothing2, _Contour2 + smoothing2);
	
	half4 color1 = half4(1, 1, 1, 1);
	half4 color2 = color1;
	
	#if defined(SDF_ALBEDOTINT)
		color1 = _Color;
	#endif
	#if defined(SDF_VERTEXCOLOR) && defined(_VERTEXCOLOR_ON)
		color1 *= i.color;
	#endif
	
	#if defined(SDF_TEXTURED)
		float2 uvM1 = i.uvM.xy;
		float2 uvM2 = i.uvM.zw;
	#endif
	
	#if defined(SDF_ALBEDOMAP)
		half4 m1AlbedoAlpha = tex2D(_AlbedoMap, uvM1) * color1;
		d.albedo = m1AlbedoAlpha.rgb;
		d.alpha = m1AlbedoAlpha.a;
	#else
		d.albedo = color1.rgb;
		d.alpha = color1.a;
	#endif
	
	#if defined(SDF_SPECULAR)
		#if defined(_SPECGLOSSMAP)
			d.specGloss = tex2D(_SpecGlossMap, uvM1);
		#else
			d.specGloss = half4(_Specular, _Glossiness);
		#endif
	#elif defined(SDF_METALLIC)
		#if defined(_METALLICGLOSSMAP)
			d.metallicGloss = tex2D(_MetallicGlossMap, uvM1).ra;
		#else
			d.metallicGloss = half2(_Metallic, _Glossiness);
		#endif
	#endif
	
	#if defined(_EMISSION) || defined(_EMISSIONMAP)
		d.emission = _EmissionColor;
		#if defined(_EMISSIONMAP)
			d.emission *= tex2D(_EmissionMap, uvM1);
		#endif
	#endif
	
	#if defined(_NORMALMAP)
		d.normal = UnpackScaleNormal(tex2D(_NormalMap, uvM1), _NormalScale);
	#endif
	
	#if defined(_CONTOUR2_ON)
		#if defined(SDF_ALBEDOTINT)
			color2 = _Color2;
		#endif
		#if defined(SDF_VERTEXCOLOR) && defined(_VERTEXCOLOR2_ON)
			color2 *= i.color;
		#endif
		
		#if defined(SDF_ALBEDOMAP)
			half4 m2AlbedoAlpha = tex2D(_AlbedoMap2, uvM2) * color2;
			d.albedo2 = m2AlbedoAlpha.rgb;
			d.alpha2 = m2AlbedoAlpha.a;
		#else
			d.albedo2 = color2.rgb;
			d.alpha2 = color2.a;
		#endif
		
		#if defined(SDF_SPECULAR)
			#if defined(_SPECGLOSSMAP2)
				d.specGloss2 = tex2D(_SpecGlossMap2, uvM2);
			#else
				d.specGloss2 = half4(_Specular2, _Glossiness2);
			#endif
		#elif defined(SDF_METALLIC)
			#if defined(_METALLICGLOSSMAP2)
				d.metallicGloss2 = tex2D(_MetallicGlossMap2, uvM2).ra;
			#else
				d.metallicGloss2 = half2(_Metallic2, _Glossiness2);
			#endif
		#endif
		
		#if defined(_EMISSION) || defined(_EMISSIONMAP)
			d.emission2 = _EmissionColor2;
			#if defined(_EMISSIONMAP)
				d.emission2 *= tex2D(_EmissionMap2, uvM2);
			#endif
		#endif
		
		#if defined(_NORMALMAP)
			d.normal2 = UnpackScaleNormal(tex2D(_NormalMap2, uvM2), _NormalScale2);
		#endif
	#endif
	
	return d;
}

struct SDFResult {
	half3 albedo;
	half alpha;
	half4 specGloss;
	half2 metallicGloss;
	half3 emission;
	half3 normal;
};

// Compute contour blend factors from SDF data and a distance.
half2 getBlendFactors (SDFData d, half distance) {
	half2 bf;
	#if (defined(SDF_META) || defined(SDF_SHADOW)) && !defined(SDF_SMOOTHING_MANUAL)
		bf.x = step(d.range.x, distance);
		bf.y = step(d.range2.x, distance);
	#else
		bf.x = smoothstep(d.range.x, d.range.y, distance);
		bf.y = smoothstep(d.range2.x, d.range2.y, distance);
	#endif
	return bf;
}

// Interpolate SDF data.
SDFResult sampleColor (SDFData d, half2 t) {
	SDFResult r;
	UNITY_INITIALIZE_OUTPUT(SDFResult, r);
	#if defined(_CONTOUR2_ON)
		r.albedo = lerp(d.albedo2, d.albedo, t.x);
		r.alpha = lerp(d.alpha2, d.alpha, t.x) * t.y;
		r.specGloss = lerp(d.specGloss2, d.specGloss, t.x);
		r.metallicGloss = lerp(d.metallicGloss2, d.metallicGloss, t.x);
		r.emission = lerp(d.emission2, d.emission, t.x);
	#else
		r.albedo = d.albedo;
		r.alpha = d.alpha * t.x;
		r.specGloss = d.specGloss;
		r.metallicGloss = d.metallicGloss;
		r.emission = d.emission;
	#endif
	return r;
}

// Add another SDF result.
void AddSample (inout SDFResult r, SDFResult sample) {
	r.alpha += sample.alpha;
	#if defined(_CONTOUR2_ON)
		r.albedo += sample.albedo;
		r.specGloss += sample.specGloss;
		r.metallicGloss += sample.metallicGloss;
		r.emission += sample.emission;
	#endif
}

// Supersample SDF.
void supersample (SDFData d, inout SDFResult r) {
	float2 deltaUV = 0.3535534 * (ddx(d.uvSDF) + ddy(d.uvSDF));
	float4 boxUV = float4(d.uvSDF + deltaUV, d.uvSDF - deltaUV);

	// Blending entire samples produces much better results than only blending distance samples.
	AddSample(r, r);
	AddSample(r, sampleColor(d, getBlendFactors(d, sampleDistance(boxUV.xy))));
	AddSample(r, sampleColor(d, getBlendFactors(d, sampleDistance(boxUV.xw))));
	AddSample(r, sampleColor(d, getBlendFactors(d, sampleDistance(boxUV.zy))));
	AddSample(r, sampleColor(d, getBlendFactors(d, sampleDistance(boxUV.zw))));
	
	half weight = 1.0 / 6.0;
	r.alpha *= weight;
	#if defined(_CONTOUR2_ON)
		r.albedo *= weight;
		r.specGloss *= weight;
		r.metallicGloss *= weight;
		r.emission *= weight;
	#endif
}

// Sample SDF normal data, including bevel.
void sampleNormal (SDFData d, inout SDFResult r, float2 t) {
	#if defined(_NORMALMAP)
		#if defined(_CONTOUR2_ON)
			r.normal = lerp(d.normal2, d.normal, t.x);
		#else
			r.normal = d.normal;
		#endif
	#endif
	
	#if defined(_BEVEL_ON)
		// Using 2-pixel offset to smooth out precision terracing due to 8-bit precision of texture samples.
		float3 uvOffset = float3(_MainTex_TexelSize.x, _MainTex_TexelSize.y, 0) * 2;
		float4 uvA = d.uvSDF.xyxy - uvOffset.xzzy;
		float4 uvB = d.uvSDF.xyxy + uvOffset.xzzy;
		float4 crossSamples = float4(
			tex2D(_MainTex, uvA.xy).a, // left
			tex2D(_MainTex, uvB.xy).a, // right
			tex2D(_MainTex, uvA.zw).a, // bottom
			tex2D(_MainTex, uvB.zw).a  // top
		);
		
		// Perform manual smoothstep.
		float4 heights = saturate((crossSamples - _BevelLow) / (_BevelHigh - _BevelLow));
		heights = heights * heights * (3.0 - (2.0 * heights));
		
		// Branch on uniform variables to avoid second bevel computation.
		if (_BevelLow2 != _BevelHigh2) {
			float4 heights2 = saturate((crossSamples - _BevelLow2) / (_BevelHigh2 - _BevelLow2));
			heights += heights2 * heights2 * (3.0 - (2.0 * heights2));
		}
		
		float2 heightData = (heights.xz - heights.yw) * _BevelScale * _MainTex_TexelSize.yx;
		
		// Derivation of bevel normal computation.
		
		// lhs = (_MainTex_TexelSize.x, 0, heights.y - heights.x)
		// rhs = (0, _MainTex_TexelSize.y, heights.w - heights.z)
		
		// cross product
		// lhs.y * rhs.z - lhs.z * rhs.y,
		// lhs.z * rhs.x - lhs.x * rhs.z,
		// lhs.x * rhs.y - lhs.y * rhs.x
		
		// 0 * (heights.w - heights.z) - (heights.y - heights.x) * _MainTex_TexelSize.y,
		// (heights.y - heights.x) * 0 - _MainTex_TexelSize.x * (heights.w - heights.z),
		// _MainTex_TexelSize.x * _MainTex_TexelSize.y - 0 * 0
		
		// (heights.x - heights.y) * _MainTex_TexelSize.y,
		// (heights.z - heights.w) * _MainTex_TexelSize.x,
		// _MainTex_TexelSize.x * _MainTex_TexelSize.y
		
		float3 bevel = normalize(float3(heightData.x, heightData.y, _MainTex_TexelSize.x * _MainTex_TexelSize.y * 4));
		
		#if defined(_NORMALMAP)
			r.normal = BlendNormals(r.normal, bevel);
		#else
			r.normal = bevel;
		#endif
	#endif
}
