/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */
 Shader "SDF/Unlit" {
	Properties {
		_MainTex("SDF", 2D) = "white" {}
		
		[Toggle(_CONTOUR2_ON)] _HasContour2 ("Second Contour", Float) = 0
		[Toggle] _Supersample("Supersample", Float) = 0
		[KeywordEnum(Auto, Manual, Mixed)] _SmoothingMode("Smoothing Mode", Float) = 0
		[Toggle(_SEMITRANSPARENT_SHADOWS_ON)] _SemitransparentShadows ("Semitransparent Shadows", Float) = 0
		
		_Contour("Contour", Range(0, 1)) = 0.5
		_Contour2("Contour 2", Range(0, 1)) = 0.4
		_Smoothing("Smoothing", Range(0, 1)) = 0.1
		_Smoothing2("Smoothing2", Range(0, 1)) = 0.1
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
		
		[Enum(1st, 0, 2nd, 1, 4th, 3)] _UVSet ("UV Set for first material", Float) = 0
		[Enum(1st, 0, 2nd, 1, 4th, 3)] _UVSet2 ("UV Set for second material", Float) = 0
		
		_AlbedoMap("Albedo", 2D) = "white" {}
		_AlbedoMap2("Albedo 2", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
		_Color2("Color 2", Color) = (0, 0, 0, 1)
		[Toggle] _VertexColor("Vertex Color", Float) = 0
		[Toggle] _VertexColor2("Vertex Color 2", Float) = 0
		
		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}
	
	CGINCLUDE
		#define SDF_UNLIT
	ENDCG
	
	SubShader {
		Tags {
			"RenderType"="Opaque"
			"PerformanceChecks"="False"
		}
		LOD 100
		
		Fog { Mode Off }
		
		Pass {
			Name "Unlit"
			Tags { "LightMode" = "Always" }
			
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			
			CGPROGRAM
			
			#pragma shader_feature _CONTOUR2_ON
			#pragma shader_feature _SUPERSAMPLE_ON
			#pragma shader_feature _ _SMOOTHINGMODE_AUTO _SMOOTHINGMODE_MIXED
			#pragma shader_feature _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			
			#pragma shader_feature _ _ALBEDOMAP _ALBEDOTINTMAP
			#pragma shader_feature _VERTEXCOLOR_ON
			#pragma shader_feature _VERTEXCOLOR2_ON
			
			#pragma target 3.0 _SMOOTHINGMODE_AUTO _SMOOTHINGMODE_MIXED _SUPERSAMPLE_ON
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "SDF Unlit.cginc"

			ENDCG
		}
		
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			
			// No automatic smoothing for shadows, but include feature to determine if a manual mode is used.
			#pragma shader_feature _CONTOUR2_ON
			#pragma shader_feature _SMOOTHINGMODE_AUTO
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS_ON
			
			#pragma shader_feature _ _ALBEDOMAP _ALBEDOTINTMAP
			#pragma shader_feature _VERTEXCOLOR_ON
			#pragma shader_feature _VERTEXCOLOR2_ON
			
			#pragma multi_compile_shadowcaster
			
			#pragma target 3.0 _SEMITRANSPARENT_SHADOWS_ON
			
			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster
			
			#include "SDF Shadow.cginc"

			ENDCG
		}
		
		Pass {
			Name "META"
			Tags { "LightMode" = "Meta" }
			Cull Off

			CGPROGRAM
			
			// No automatic smoothing for lightmapping, but include feature to determine if a manual mode is used.
			#pragma shader_feature _CONTOUR2_ON
			#pragma shader_feature _SMOOTHINGMODE_AUTO
			
			#pragma shader_feature _ _ALBEDOMAP _ALBEDOTINTMAP
			#pragma shader_feature _VERTEXCOLOR_ON
			#pragma shader_feature _VERTEXCOLOR2_ON
			
			#pragma target 3.0
			
			#pragma vertex vertMeta
			#pragma fragment fragMeta
			
			#include "SDF Meta.cginc"
			
			ENDCG
		}
	}
	
	CustomEditor "CatlikeCoding.SDFToolkit.Editor.SDFShaderGUI"
}	