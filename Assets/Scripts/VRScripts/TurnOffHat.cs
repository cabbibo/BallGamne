using UnityEngine;
using System.Collections;

public class TurnOffHat : MonoBehaviour {

	// Use this for initialization
	void Start () {

	}
	
	// Update is called once per frame
	void Update () {

     GameObject th = transform.Find("trackhat").gameObject;
     if( th != null ) th.GetComponent<MeshRenderer>().enabled = false;
   // print( th );
	
	}
}
