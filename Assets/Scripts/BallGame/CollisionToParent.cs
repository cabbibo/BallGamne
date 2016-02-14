using UnityEngine;
using System.Collections;

public class CollisionToParent : MonoBehaviour {

  public GameObject parent;
	// Use this for initialization
	void Start () {
	
	}
	
  void OnCollisionEnter( Collision c ){

    if( c.gameObject.tag == "Baby" ){
      print("YA");
      parent.GetComponent<Room>().BabyHit(c);
    }
  }
}
