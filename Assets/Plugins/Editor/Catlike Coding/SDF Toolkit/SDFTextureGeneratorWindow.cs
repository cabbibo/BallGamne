/*
 * Copyright 2012, Catlike Coding
 * http://catlikecoding.com
 */

using System.IO;
using UnityEditor;
using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Editor {

	/// <summary>
	/// Editor window for generating signed distance field textures.
	/// </summary>
	public class SDFTextureGeneratorWindow : EditorWindow {

		/// <summary>
		/// Open the window.
		/// </summary>
		[MenuItem("Window/SDF Texture Generator")]
		public static void OpenWindow () {
			EditorWindow.GetWindow<SDFTextureGeneratorWindow>(true, "SDF Texture Generator");
		}
		
		private static string
			rgbModeKey = "SDFToolkit.rgbFillMode",
			insideDistanceKey = "SDFToolkit.insideDistance",
			outsideDistanceKey = "SDFToolkit.outsideDistance",
			postProcessDistanceKey = "SDFToolkit.postProcessDistance";

		private static GUIContent
			sourceTextureContent = new GUIContent(
				"Source Texture",
				"The alpha channel of this texture is used to compute distances."),
			rgbFillModeContent = new GUIContent(
				"RGB Fill Mode",
				"What is put in the RGB channels of the exported texture. Distance is always stored in the alpha channel."),
			insideContent = new GUIContent(
				"Inside Distance",
				"Pixel distance inside the contour that is considered fully inside."),
			outsideContent = new GUIContent(
				"Outside Distance",
				"Pixel distance outside the contour that is considered fully outside."),
			postprocessContent = new GUIContent(
				"Post-process Distance",
				"Pixel range in which post-processing is performed. This might improve quality close to the contour.");
		
		private Texture2D source, destination;
		private RGBFillMode rgbFillMode;
		private float insideDistance = 3f, outsideDistance = 3f;
		private float postProcessDistance = 0f;
		private bool allowSave;
		private Vector2 scrollPosition;
		
		private void OnEnable () {
			source = Selection.activeObject as Texture2D;
			rgbFillMode = (RGBFillMode)EditorPrefs.GetInt(rgbModeKey);
			insideDistance = EditorPrefs.GetFloat(insideDistanceKey, 3f);
			outsideDistance = EditorPrefs.GetFloat(outsideDistanceKey, 3f);
			postProcessDistance = EditorPrefs.GetFloat(postProcessDistanceKey);
		}

		private void OnDisable () {
			DestroyImmediate(destination);
		}
		
		private void OnGUI () {
			GUILayout.BeginArea(new Rect(2f, 2f, 220f, position.height - 4f));

			EditorGUI.BeginChangeCheck();
			source = (Texture2D)EditorGUILayout.ObjectField(sourceTextureContent, source, typeof(Texture2D), false);
			if (EditorGUI.EndChangeCheck()) {
				DestroyImmediate(destination);
				allowSave = false;
			}

			EditorGUI.BeginChangeCheck();
			rgbFillMode = (RGBFillMode)EditorGUILayout.EnumPopup(rgbFillModeContent, rgbFillMode);
			if (EditorGUI.EndChangeCheck()) {
				EditorPrefs.SetInt(rgbModeKey, (int)rgbFillMode);
				allowSave = false;
			}
			
			EditorGUI.BeginChangeCheck();
			insideDistance = EditorGUILayout.FloatField(insideContent, insideDistance);
			if (EditorGUI.EndChangeCheck()) {
				EditorPrefs.SetFloat(insideDistanceKey, insideDistance);
				allowSave = false;
			}

			EditorGUI.BeginChangeCheck();
			outsideDistance = EditorGUILayout.FloatField(outsideContent, outsideDistance);
			if (EditorGUI.EndChangeCheck()) {
				EditorPrefs.SetFloat(outsideDistanceKey, outsideDistance);
				allowSave = false;
			}

			EditorGUI.BeginChangeCheck();
			postProcessDistance = EditorGUILayout.FloatField(postprocessContent, postProcessDistance);
			if (EditorGUI.EndChangeCheck()) {
				EditorPrefs.SetFloat(postProcessDistanceKey, postProcessDistance);
				allowSave = false;
			}
			
			if (source != null && GUILayout.Button("Generate")) {
				Generate();
			}
			
			if (allowSave && GUILayout.Button("Save PNG file")) {
				string filePath = EditorUtility.SaveFilePanel(
					"Save Signed Distance Field",
					new FileInfo(AssetDatabase.GetAssetPath(source)).DirectoryName,
					source.name + " SDF",
					"png");
				if (filePath.Length > 0) {
					File.WriteAllBytes(filePath, destination.EncodeToPNG());
					AssetDatabase.Refresh();
				}
			}
			
			GUILayout.EndArea();

			if (destination != null) {
				scrollPosition = GUI.BeginScrollView(
				new Rect(224f, 2f, position.width - 226f, position.height - 4f),
				scrollPosition,
				new Rect(0f, 0f, destination.width, destination.height));
				EditorGUI.DrawTextureAlpha(new Rect(0f, 0f, destination.width, destination.height), destination);
				GUI.EndScrollView();
			}
		}

		private void Generate () {
			if (destination == null) {
				destination = new Texture2D(source.width, source.height, TextureFormat.ARGB32, false);
				destination.hideFlags = HideFlags.HideAndDontSave;
			}
			string path = AssetDatabase.GetAssetPath(source);
			TextureImporter importer = TextureImporter.GetAtPath(path) as TextureImporter;
			if (importer == null) {
				Debug.LogError("Cannot work with built-in textures.");
				return;
			}
			bool isReadble = importer.isReadable;
			TextureImporterFormat format = importer.textureFormat;
			bool correctFormat =
				format == TextureImporterFormat.Alpha8 ||
				format == TextureImporterFormat.ARGB32 ||
				format == TextureImporterFormat.RGBA32 ||
				format == TextureImporterFormat.AutomaticTruecolor;
			
			if (!isReadble || !correctFormat) {
				importer.isReadable = true;
				importer.textureFormat = TextureImporterFormat.ARGB32;
				AssetDatabase.ImportAsset(path);
			}
			SDFTextureGenerator.Generate(
				source, destination, insideDistance, outsideDistance, postProcessDistance, rgbFillMode);
			if (!isReadble || !correctFormat) {
				importer.isReadable = isReadble;
				importer.textureFormat = format;
				AssetDatabase.ImportAsset(path);
			}
			destination.Apply();
			allowSave = true;
		}
	}
}