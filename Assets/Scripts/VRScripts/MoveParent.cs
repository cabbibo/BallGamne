using UnityEngine;
using System.Collections;

public class MoveParent : MonoBehaviour {

  Transform ogTransform;
	// Use this for initialization
	void Start () {
    ogTransform = transform.parent;
	}
	
	// Update is called once per frame
	void Update () {

    if(GetComponent<MoveByController>().moving == true ){
    ogTransform.position = transform.position;
    ogTransform.rotation = transform.rotation;
    }
	
	}
}
