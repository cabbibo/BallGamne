using UnityEngine;
using System.Collections;

public class ResetGameData : MonoBehaviour {

	// Use this for initialization
	void Start () {
      Game.current = new Game();
      SaveLoad.Save();
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
