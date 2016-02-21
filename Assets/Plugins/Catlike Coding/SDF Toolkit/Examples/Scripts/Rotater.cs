/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component to rotate an object.
	/// Controlled at runtime by setting DegreesPerSecond via a slider.
	/// </summary>
	public class Rotater : MonoBehaviour {

		/// <summary>
		/// Rotation speed.
		/// </summary>
		public float degreesPerSecond = 90f;

		/// <summary>
		/// Set the degrees per second.
		/// </summary>
		public float DegreesPerSecond {
			set {
				degreesPerSecond = value;
			}
		}

		private void Update () {
			transform.Rotate(0f, degreesPerSecond * Time.deltaTime, 0f);
		}
	}
}