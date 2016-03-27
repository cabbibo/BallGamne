using UnityEngine;
using System.Collections;

public class SetMaterialFake : MonoBehaviour {

	// Use this for initialization
	void Start () {

    GetComponent<MeshRenderer>().material.SetFloat("_FAKE",1);
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
