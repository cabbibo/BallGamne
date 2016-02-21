/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using System;

namespace CatlikeCoding.SDFToolkit.Editor {

	/// <summary>
	/// Unified UI for SDF shaders.
	/// </summary>
	/// <description>
	/// Adaptation of Unity's standard shader UI.
	/// </description>
	public class SDFShaderGUI : ShaderGUI {

		#region Enums and Styles

		enum SDFBlendMode {
			Cutout,
			Fade,
			Transparent
		}

		enum ShaderType {
			Unlit,
			Metallic,
			Specular
		}

		enum SP {
			MainTex,
			Mode,
			HasContour2,
			Cutoff,
			SmoothingMode,
			Supersample,
			SemitransparentShadows,
			Bevel,
			BevelScale,
			BevelLow,
			BevelHigh,
			BevelLow2,
			BevelHigh2
		}

		enum CP {
			VertexColor,
			AlbedoMap,
			Contour,
			Smoothing,
			Color,
			UVSet,
			MetallicGlossMap,
			Metallic,
			SpecGlossMap,
			Specular,
			Glossiness,
			NormalMap,
			NormalScale,
			EmissionColor,
			EmissionMap
		}

		static class Styles {
			public static readonly string[] blendNames = Enum.GetNames(typeof (SDFBlendMode));
			public static readonly string[] views = {"SDF", "Contours"};
			
			public static GUIContent sdf = new GUIContent("SDF", "Distance Field, white is fully inside (A)");
			public static GUIContent albedoMap = new GUIContent("Albedo", "Albedo Map, Tint, and Vertex Color");
			public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");
			public static GUIContent uvSetLabel = new GUIContent("UV Set");
			public static GUIContent specGloss = new GUIContent("Specular", "Specular (RGB) and Smoothness (A)");
			public static GUIContent metallic = new GUIContent("Metallic", "Metallic (R) and Smoothness (A)");
			public static GUIContent normalMap = new GUIContent("Normal Map", "Normal Map and Scale");
			public static GUIContent emission = new GUIContent("Emission", "Emission (RGB)");
			public static GUIContent glossiness = new GUIContent("Smoothness", "Smoothness");
		}

		#endregion
		
		static int viewIndex;
		
		static string[] sdfPropertyNames;
		static string[][] contourPropertyNames;

		static void InitContourPropertyMetaData () {
			if (contourPropertyNames != null) {
				return;
			}
			sdfPropertyNames = Array.ConvertAll(Enum.GetNames(typeof(SP)), x => "_" + x);
			contourPropertyNames = new string[2][];
			contourPropertyNames[0] = Array.ConvertAll(Enum.GetNames(typeof(CP)), x => "_" + x);
			contourPropertyNames[1] = Array.ConvertAll(contourPropertyNames[0], x => x + "2");
		}

		static float GetFloat (SP property, Material material) {
			return material.GetFloat(sdfPropertyNames[(int)property]);
		}

		static Color GetColor (CP property, int c, Material material) {
			return material.GetColor(contourPropertyNames[c][(int)property]);
		}

		static Texture GetTexture (CP property, int c, Material material) {
			return material.GetTexture(contourPropertyNames[c][(int)property]);
		}

		static bool Exists (CP property, Material material) {
			return material.HasProperty(contourPropertyNames[0][(int)property]);
		}

		MaterialProperty[] sdfProperties;
		MaterialProperty[][] contourProperties;
		
		ShaderType type;

		bool isUI;
		
		MaterialEditor editor;

		ColorPickerHDRConfig hdrConfig = new ColorPickerHDRConfig(0f, 99f, 1 / 99f, 3f);

		bool firstTimeApply = true;

		MaterialProperty Get (SP property) {
			return sdfProperties[(int)property];
		}
		
		MaterialProperty Get (CP property, int contour) {
			return contourProperties[contour][(int)property];
		}
		
		void FindProperties (MaterialProperty[] props) {
			sdfProperties = new MaterialProperty[sdfPropertyNames.Length];
			for (int i = 0; i < sdfProperties.Length; i++) {
				sdfProperties[i] = FindProperty(sdfPropertyNames[i], props, false);
			}

			contourProperties = new MaterialProperty[2][];
			int contourPropertyCount = contourPropertyNames[0].Length;
			contourProperties[0] = new MaterialProperty[contourPropertyCount];
			contourProperties[1] = new MaterialProperty[contourPropertyCount];
			for (int i = 0; i < contourPropertyCount; i++) {
				contourProperties[0][i] = FindProperty(contourPropertyNames[0][i], props, false);
				contourProperties[1][i] = FindProperty(contourPropertyNames[1][i], props, false);
			}

			if (Get(CP.Metallic, 0) != null) {
				type = ShaderType.Metallic;
			}
			else if (Get(CP.Specular, 0) != null) {
				type = ShaderType.Specular;
			}
			else {
				type = ShaderType.Unlit;
			}

			isUI = Get(SP.SemitransparentShadows) == null;
		}

		public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] props) {
			InitContourPropertyMetaData();
			// MaterialProperties can be animated so we do not cache them but fetch them every event
			// to ensure animated values are updated correctly.
			FindProperties (props);
			editor = materialEditor;
			Material material = materialEditor.target as Material;
			ShaderPropertiesGUI(material);
			
			// Make sure that needed keywords are set up if we're switching some existing
			// material to an SDF shader.
			if (firstTimeApply) {
				SetMaterialKeywords(material);
				firstTimeApply = false;
			}
		}

		void ShaderPropertiesGUI (Material material) {
			EditorGUIUtility.labelWidth = 0f;
			viewIndex = GUILayout.Toolbar(viewIndex, Styles.views);
			EditorGUI.BeginChangeCheck();
			if (viewIndex == 0) {
				SDFGUI();
			}
			else {
				ContoursGUI();
			}
			if (EditorGUI.EndChangeCheck()) {
				foreach (var obj in sdfProperties[0].targets)
					MaterialChanged((Material)obj);
			}
		}

		void SDFGUI () {
			editor.ShaderProperty(Get(SP.SmoothingMode), "Smoothing Mode");
			editor.ShaderProperty(Get(SP.Supersample), "Supersample");
			
			BlendModePopup();
			if (((SDFBlendMode)Get(SP.Mode).floatValue == SDFBlendMode.Cutout ||
			     (!isUI && Get(SP.SemitransparentShadows).floatValue == 0f))) {
				editor.ShaderProperty(
					Get(SP.Cutoff), Styles.alphaCutoffText.text,
					MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
			}
			
			MaterialProperty sdfMap = Get(SP.MainTex);
			editor.TexturePropertySingleLine(Styles.sdf, sdfMap);
			if (isUI) {
				if (sdfMap.textureValue) {
					EditorGUILayout.HelpBox(
						"For previewing only.\nThe SDF texture is replaced with sprites in the UI.",
						MessageType.Info);
				}
			}
			else {
				editor.TextureScaleOffsetProperty(sdfMap);
				editor.LightmapEmissionProperty();
			}
			
			if (type != ShaderType.Unlit) {
				editor.ShaderProperty(Get(SP.Bevel), "Bevel");
				if (Get(SP.Bevel).floatValue != 0f) {
					editor.ShaderProperty(Get(SP.BevelScale), "Scale");
					editor.ShaderProperty(Get(SP.BevelLow), "Low");
					editor.ShaderProperty(Get(SP.BevelHigh), "High");
					editor.ShaderProperty(Get(SP.BevelLow2), "Low 2");
					editor.ShaderProperty(Get(SP.BevelHigh2), "High 2");
				}
			}
		}

		void ContoursGUI () {
			ContourGUI(0);
			
			EditorGUILayout.Space();
			MaterialProperty hasContour2 = Get(SP.HasContour2);
			editor.ShaderProperty(hasContour2, "Second Contour");
			if (hasContour2.floatValue > 0f) {
				ContourGUI(1);
			}

			if (isUI) {
				MaterialProperty uvSet = Get(CP.UVSet, 0), uvSet2 = Get(CP.UVSet, 1);
				if (uvSet.floatValue > 0f || uvSet2.floatValue > 0f) {
					EditorGUILayout.HelpBox(
						"The second UV set of a sprite has to be defined by a vertex modifier UI component.",
						MessageType.Info);
				}
				if (uvSet.floatValue > 1f && !Get(CP.AlbedoMap, 0).textureValue ||
				    uvSet2.floatValue > 1f && !Get(CP.AlbedoMap, 1).textureValue) {
					EditorGUILayout.HelpBox(
						"The second UV set can only be scaled when an albedo map is provided.",
						MessageType.Warning);
				}
			}
		}

		void ContourGUI (int c) {
			editor.ShaderProperty(Get(CP.Contour, c), "");
			editor.ShaderProperty(Get(CP.Smoothing, c), "Smoothing");
			
			editor.TexturePropertySingleLine(
				Styles.albedoMap, Get(CP.AlbedoMap, c), Get(CP.Color, c), Get(CP.VertexColor, c));
			
			MaterialProperty specGlossMap = Get(CP.SpecGlossMap, c);
			if (type == ShaderType.Specular) {
				if (specGlossMap.textureValue == null) {
					editor.TexturePropertyTwoLines(
						Styles.specGloss, specGlossMap, Get(CP.Specular, c),
						Styles.glossiness, Get(CP.Glossiness, c));
				}
				else {
					editor.TexturePropertySingleLine(Styles.specGloss, specGlossMap);
				}
			}
			else if (type == ShaderType.Metallic) {
				MaterialProperty metallicGlossMap = Get(CP.MetallicGlossMap, c);
				if (metallicGlossMap.textureValue == null) {
					editor.TexturePropertyTwoLines(
						Styles.metallic, metallicGlossMap, Get(CP.Metallic, c),
						Styles.glossiness, Get(CP.Glossiness, c));
				}
				else {
					editor.TexturePropertySingleLine(Styles.metallic, metallicGlossMap);
				}
			}
			if (type != ShaderType.Unlit) {
				editor.TexturePropertyWithHDRColor(
					Styles.emission, Get(CP.EmissionMap, c), Get(CP.EmissionColor, c), hdrConfig, false);
				editor.TexturePropertySingleLine(Styles.normalMap, Get(CP.NormalMap, c), Get(CP.NormalScale, c));
			}
			
			editor.ShaderProperty(Get(CP.UVSet, c), Styles.uvSetLabel.text);
			editor.TextureScaleOffsetProperty(Get(CP.AlbedoMap, c));
		}

		void BlendModePopup () {
			MaterialProperty blendMode = Get(SP.Mode);
			EditorGUI.showMixedValue = blendMode.hasMixedValue;
			SDFBlendMode mode = (SDFBlendMode)blendMode.floatValue;
			EditorGUI.BeginChangeCheck();
			mode = (SDFBlendMode)EditorGUILayout.Popup("Rendering Mode", (int)mode, Styles.blendNames);
			if (EditorGUI.EndChangeCheck()) {
				editor.RegisterPropertyChangeUndo("Rendering Mode");
				blendMode.floatValue = (float)mode;
			}
			if (mode != SDFBlendMode.Cutout && !isUI) {
				editor.ShaderProperty(Get(SP.SemitransparentShadows), "Semitransp. Shadows");
			}
			EditorGUI.showMixedValue = false;
		}

		static void MaterialChanged(Material material) {
			SetupMaterialWithBlendMode(material, (SDFBlendMode)GetFloat(SP.Mode, material));
			SetMaterialKeywords(material);
		}

		static void SetupMaterialWithBlendMode(Material material, SDFBlendMode blendMode) {
			switch (blendMode) {
			case SDFBlendMode.Cutout:
				material.SetInt("_SrcBlend", (int)BlendMode.One);
				material.SetInt("_DstBlend", (int)BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.EnableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = 2450;
				break;
			case SDFBlendMode.Fade:
				material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
				material.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.DisableKeyword("_ALPHATEST_ON");
				material.EnableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = 3000;
				break;
			case SDFBlendMode.Transparent:
				material.SetInt("_SrcBlend", (int)BlendMode.One);
				material.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.DisableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = 3000;
				break;
			}
		}

		static void SetMaterialKeywords(Material material) {
			// keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
			// (MaterialProperty value might come from renderer material property block)
			bool hasContour2 = GetFloat(SP.HasContour2, material) > 0f;
			ShaderType type;
			if (Exists(CP.SpecGlossMap, material)) {
				type = ShaderType.Specular;
			}
			else if(Exists(CP.MetallicGlossMap, material)) {
				type = ShaderType.Metallic;
			}
			else {
				type = ShaderType.Unlit;
			}
			
			SetPBSMaps(material, type, hasContour2);
			SetEmissiveAndGI(material, type, hasContour2);
		}

		static void SetPBSMaps (Material material, ShaderType type, bool hasContour2) {
			if (GetTexture(CP.AlbedoMap, 0, material) || hasContour2 && GetTexture(CP.AlbedoMap, 1, material)) {
				bool tinted =
					GetColor(CP.Color, 0, material) != Color.white ||
						hasContour2 && GetColor(CP.Color, 1, material) != Color.white;
				SetKeyword(material, "_ALBEDOMAP", !tinted);
				SetKeyword(material, "_ALBEDOTINTMAP", tinted);
			}
			else {
				SetKeyword(material, "_ALBEDOMAP", false);
				SetKeyword(material, "_ALBEDOTINTMAP", false);
			}

			if (type != ShaderType.Unlit) {
				SetKeyword(
					material, "_NORMALMAP",
					GetTexture(CP.NormalMap, 0, material) || hasContour2 && GetTexture(CP.NormalMap, 1, material));
			}
			if (type == ShaderType.Specular) {
				SetKeyword(material, "_SPECGLOSSMAP", GetTexture(CP.SpecGlossMap, 0, material));
				SetKeyword(material, "_SPECGLOSSMAP2", hasContour2 && GetTexture(CP.SpecGlossMap, 1, material));
			}
			else if (type == ShaderType.Metallic) {
				SetKeyword(material, "_METALLICGLOSSMAP", GetTexture(CP.MetallicGlossMap, 0, material));
				SetKeyword(material, "_METALLICGLOSSMAP2", hasContour2 && GetTexture(CP.MetallicGlossMap, 1, material));
			}
		}

		static void SetEmissiveAndGI (Material material, ShaderType type, bool hasContour2) {
			bool emits;
			if (type == ShaderType.Unlit) {
				emits = true;
			}
			else {
				emits =
					Emits(GetColor(CP.EmissionColor, 0, material)) ||
						hasContour2 && Emits(GetColor(CP.EmissionColor, 1, material));
				
				if (emits) {
					bool emissionMaps =
						GetTexture(CP.EmissionMap, 0, material) ||
							(hasContour2 && GetTexture(CP.EmissionMap, 1, material));
					SetKeyword(material, "_EMISSION", !emissionMaps);
					SetKeyword(material, "_EMISSIONMAP", emissionMaps);
				}
				else {
					SetKeyword(material, "_EMISSION", false);
					SetKeyword(material, "_EMISSIONMAP", false);
				}
			}
			
			// Setup lightmap and emissive flags
			MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
			MaterialGlobalIlluminationFlags mask = MaterialGlobalIlluminationFlags.BakedEmissive |
				MaterialGlobalIlluminationFlags.RealtimeEmissive;
			if ((flags & mask) != 0) {
				if (emits) {
					flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
				}
				else {
					flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
				}
				material.globalIlluminationFlags = flags;
			}
		}

		static bool Emits (Color color) {
			return color.r > 0f || color.g > 0f || color.b > 0f;
		}
		
		static void SetKeyword (Material m, string keyword, bool state) {
			if (state) {
				m.EnableKeyword(keyword);
			}
			else {
				m.DisableKeyword(keyword);
			}
		}
	}
}