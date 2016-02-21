/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component to control the position of the sun in the sky via a slider.
	/// </summary>
	public class Sun : MonoBehaviour {

		/// <summary>
		/// Set the sun's angle.
		/// </summary>
		public float Angle {
			set {
				transform.localRotation = Quaternion.Euler(value, 330f, 0f);
			}
		}
	}
}