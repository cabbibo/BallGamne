/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component that animates a light by adding sinusoids to its position.
	/// </summary>
	public class MovingLight : MonoBehaviour {

		/// <summary>
		/// The amplitudes of the sinusoids.
		/// </summary>
		public Vector3 amplitudes;

		/// <summary>
		/// The frequencies of the sinusoids.
		/// </summary>
		public Vector3 frequencies;

		/// <summary>
		/// The offsets of the sinusoids.
		/// </summary>
		public Vector3 offsets;

		/// <summary>
		/// Start position of the animation.
		/// </summary>
		private Vector3 startPosition;

		private void Start () {
			startPosition = transform.localPosition;
		}
		
		private void Update () {
			float t = Time.time;
			Vector3 p;
			p.x = amplitudes.x * Mathf.Sin((t * frequencies.x + offsets.x) * (Mathf.PI * 2f));
			p.y = amplitudes.y * Mathf.Sin((t * frequencies.y + offsets.y) * (Mathf.PI * 2f));
			p.z = amplitudes.z * Mathf.Sin((t * frequencies.z + offsets.z) * (Mathf.PI * 2f));
			transform.localPosition = startPosition + p;
			transform.LookAt(Vector3.zero);
		}
	}
}