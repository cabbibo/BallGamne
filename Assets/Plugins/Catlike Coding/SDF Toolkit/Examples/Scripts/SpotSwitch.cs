/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component to switch two spotlight on and off via a slider.
	/// </summary>
	public class SpotSwitch : MonoBehaviour {

		/// <summary>
		/// First spotlight.
		/// </summary>
		public GameObject spot1;

		/// <summary>
		/// Second spotlight.
		/// </summary>
		public GameObject spot2;

		/// <summary>
		/// Control how many spotlights are enabled via a slider.
		/// </summary>
		public float SpotCount {
			set {
				spot1.SetActive(value > 0f);
				spot2.SetActive(value > 1f);
			}
		}
	}
}