/*
 * Copyright 2015, Catlike Coding
 * http://catlikecoding.com
 */

using UnityEngine;

namespace CatlikeCoding.SDFToolkit.Examples {

	/// <summary>
	/// Simple component to toggle UI panel visibility with a key press.
	/// </summary>
	public class ToggleUI : MonoBehaviour {

		private GameObject panel;

		private void Start () {
			panel = transform.GetChild(0).gameObject;
		}

		private void Update () {
			if (Input.GetKeyDown(KeyCode.H)) {
				panel.SetActive(!panel.activeSelf);
			}
		}
	}
}