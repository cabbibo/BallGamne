using UnityEngine;
using System.Collections;

public class Shield : MonoBehaviour {

  public GameObject shieldObj;
  public GameObject Controller;

  public Vector3 startScale;
  public Vector3 startPos;

  private Material mat;

	// Use this for initialization
	void Start () {
	 startScale = shieldObj.transform.localScale;
   startPos = shieldObj.transform.localPosition;
   mat = shieldObj.GetComponent<MeshRenderer>().material;
	}
	
	// Update is called once per frame
	void Update () {

    controllerInfo ci = Controller.GetComponent<controllerInfo>();
	
    Vector3 v = ci.velocity;
//    print( ci.triggerVal );
    //if( ci.triggerVal < 0.01 ){
    //  shieldObj.GetComponent<BoxCollider>().enabled = false;
    //  shieldObj.GetComponent<Renderer>().enabled = false;
    //}else{
    //  shieldObj.GetComponent<BoxCollider>().enabled = true;
    //  shieldObj.GetComponent<Renderer>().enabled = true;
//
      shieldObj.transform.localScale =  ci.triggerVal * startScale;
      shieldObj.transform.localPosition = ci.triggerVal * startPos;

      //print(shieldObj.transform.localScale );
      mat.SetVector( "_Size" , shieldObj.transform.localScale );
    //}
    //shieldObj.GetComponent<Rigidbody>().velocity = v;
	}
}
