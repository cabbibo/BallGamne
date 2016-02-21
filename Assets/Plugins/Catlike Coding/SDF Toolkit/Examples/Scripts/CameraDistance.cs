/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component to adjust camera distance from the center of the scene.
	/// Controlled at runtime by setting DistanceFactor via a slider.
	/// </summary>
	public class CameraDistance : MonoBehaviour {

		/// <summary>
		/// Minimum camera distance.
		/// </summary>
		public float min;

		/// <summary>
		/// Maximum camera distance.
		/// </summary>
		public float max;

		/// <summary>
		/// Point the camera should look at.
		/// </summary>
		public Vector3 lookAt;

		/// <summary>
		/// Set the distance factor. 0 is minimum, 1 is maximum.
		/// </summary>
		public float DistanceFactor {
			set {
				Vector3 p = transform.localPosition;
				p.z = Mathf.Lerp(min, max, value);
				transform.localPosition = p;
				transform.LookAt(lookAt);
			}
		}
	}
}