/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component that is used to point a spotlight in the direction of the cursor.
	/// </summary>
	public class CursorSpotlight : MonoBehaviour {

		private void Update () {
			Vector3 p = Input.mousePosition;
			p.z = Camera.main.nearClipPlane;
			p = Camera.main.ScreenToWorldPoint(p);
			transform.LookAt(p);
		}
	}
}