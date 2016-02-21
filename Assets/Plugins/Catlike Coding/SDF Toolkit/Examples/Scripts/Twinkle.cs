/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component to animate SDF contours with a sinusoid, to make subtle twinkling stars.
	/// </summary>
	public class Twinkle : MonoBehaviour {

		/// <summary>
		/// Frequency of the twinkling animation.
		/// </summary>
		public float frequency;

		/// <summary>
		/// Offset of the twinkling animation.
		/// </summary>
		public float offset;

		/// <summary>
		/// Amplitude of the twinking animation.
		/// </summary>
		public float amplitude;

		/// <summary>
		/// Material to animate.
		/// </summary>
		public Material material;

		private float c1, c2;

		private void Start () {
			c1 = material.GetFloat("_Contour");
			c2 = material.GetFloat("_Contour2");
		}
		
		private void Update () {
			float f = Mathf.Sin((Time.time * frequency + offset) * (Mathf.PI * 2f));
			f = f * f * amplitude;
			material.SetFloat("_Contour", c1 + f);
			material.SetFloat("_Contour2", c2 - f);
		}

		private void OnApplicationQuit () {
			// When animating a shared asset, restore original contours.
			material.SetFloat("_Contour", c1);
			material.SetFloat("_Contour2", c2);
		}
	}
}