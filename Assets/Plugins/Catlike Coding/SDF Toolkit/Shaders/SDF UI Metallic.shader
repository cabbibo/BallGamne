/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 * An adaptation of the Unity 5 standard shader code to work with SDF and UI.
 */
Shader "SDF/UI/Metallic" {
	Properties {
		_MainTex("SDF", 2D) = "white" {}
		
		[Toggle(_CONTOUR2_ON)] _HasContour2("Second Contour", Float) = 0
		[Toggle] _Supersample("Supersample", Float) = 0
		[KeywordEnum(Auto, Manual, Mixed)] _SmoothingMode("Smoothing Mode", Float) = 0
		
		_Contour("Contour", Range(0, 1)) = 0.5
		_Contour2("Contour 2", Range(0, 1)) = 0.4
		_Smoothing("Contour Smoothing", Range(0, 1)) = 0.1
		_Smoothing2("Contour Smoothing 2", Range(0, 1)) = 0.1
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
		
		[Enum(1st, 0, 2nd, 1, 2nd Scaled, 2)] _UVSet ("UV Set for first material", Float) = 0
		[Enum(1st, 0, 2nd, 1, 2nd Scaled, 2)] _UVSet2 ("UV Set for second material", Float) = 0
		
		_AlbedoMap("Albedo", 2D) = "white" {}
		_AlbedoMap2("Albedo 2", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
		_Color2("Color 2", Color) = (0, 0, 0, 1)
		[Toggle] _VertexColor("Vertex Color", Float) = 0
		[Toggle] _VertexColor2("Vertex Color 2", Float) = 0
		
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_MetallicGlossMap2("Metallic 2", 2D) = "white" {}
		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		[Gamma] _Metallic2("Metallic 2", Range(0.0, 1.0)) = 0.0
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_Glossiness2("Smoothness 2", Range(0.0, 1.0)) = 0.5
		
		_EmissionMap("Emission", 2D) = "white" {}
		_EmissionMap2("Emission 2", 2D) = "white" {}
		_EmissionColor("Emission Color", Color) = (0, 0, 0)
		_EmissionColor2("Emission Color 2", Color) = (0, 0, 0)
		
		_NormalMap("Normal Map", 2D) = "bump" {}
		_NormalMap2("Normal Map", 2D) = "bump" {}
		_NormalScale("Scale", Float) = 1
		_NormalScale2("Scale", Float) = 1
		
		[Toggle] _Bevel("Bevel", Float) = 0
		_BevelScale("Bevel Scale", Range(0, 0.05)) = 0.025
		_BevelLow("Bevel Low", Range(0, 1)) = 0.5
		_BevelHigh("Bevel High", Range(0, 1)) = 1
		_BevelLow2("Bevel Low 2", Range(0, 1)) = 0
		_BevelHigh2("Bevel High 2", Range(0, 1)) = 0
		
		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0
		[HideInInspector] _SrcBlend("__src", Float) = 1
		[HideInInspector] _DstBlend("__dst", Float) = 0
		[HideInInspector] _ZWrite("__zw", Float) = 1
		
		// UI state
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15
	}
	
	CGINCLUDE
		#define SDF_UI
		#define SDF_METALLIC
	ENDCG
	
	SubShader {
		Tags {
			"Queue"="Transparent"
			"RenderType"="Transparent"
			"PerformanceChecks" = "False"
			"IgnoreProjector"="True"
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Stencil {
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}
		LOD 300
		
		ZTest [unity_GUIZTestMode]
		Offset -1, -1
		ColorMask [_ColorMask]
		
		Pass {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			
			CGPROGRAM
			
			#pragma shader_feature _CONTOUR2_ON
			#pragma shader_feature _SUPERSAMPLE_ON
			#pragma shader_feature _ _SMOOTHINGMODE_AUTO _SMOOTHINGMODE_MIXED
			#pragma shader_feature _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			
			#pragma shader_feature _ _ALBEDOMAP _ALBEDOTINTMAP
			#pragma shader_feature _ _EMISSION _EMISSIONMAP
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _METALLICGLOSSMAP2
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _BEVEL_ON
			#pragma shader_feature _VERTEXCOLOR_ON
			#pragma shader_feature _VERTEXCOLOR2_ON
			
			#pragma multi_compile_fwdbase
			
			#pragma target 3.0
			
			#pragma vertex vertForward
			#pragma fragment fragForward
			
			#define SDF_FORWARD_BASE
			
			#include "SDF Forward.cginc"

			ENDCG
		}
		
		Pass {
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One
			ZWrite Off

			CGPROGRAM

			#pragma shader_feature _CONTOUR2_ON
			#pragma shader_feature _SUPERSAMPLE_ON
			#pragma shader_feature _ _SMOOTHINGMODE_AUTO _SMOOTHINGMODE_MIXED
			#pragma shader_feature _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			
			#pragma shader_feature _ _ALBEDOMAP _ALBEDOTINTMAP
			#pragma shader_feature _ _EMISSION _EMISSIONMAP
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _METALLICGLOSSMAP2
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _BEVEL_ON
			#pragma shader_feature _VERTEXCOLOR_ON
			#pragma shader_feature _VERTEXCOLOR2_ON
			
			#pragma multi_compile_fwdadd
			
			#pragma target 3.0
			
			#pragma vertex vertForwardAdd
			#pragma fragment fragForwardAdd
			
			#define SDF_FORWARD_ADD
			
			#include "SDF Forward.cginc"

			ENDCG
		}
	}
	
	CustomEditor "CatlikeCoding.SDFToolkit.Editor.SDFShaderGUI"
}