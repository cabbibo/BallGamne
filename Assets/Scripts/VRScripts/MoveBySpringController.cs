using UnityEngine;
using System.Collections;

public class MoveBySpringController : MonoBehaviour {


  public Transform ogTransform;
  public bool moving;

  private bool inside;


  Collider colInside;
  SpringJoint sj;
  SpringJoint sj1;

  void OnEnable(){
    EventManager.OnTriggerDown += OnTriggerDown;
    EventManager.OnTriggerUp += OnTriggerUp;
    EventManager.StayTrigger += StayTrigger;
    inside = false;
    moving = false;
    ogTransform = transform.parent;
  }

  // Update is called once per frame
  void Update () {

  
  }

  void OnTriggerDown(GameObject o){
    if( inside == true ){
      //rint("YA");
      sj = gameObject.AddComponent<SpringJoint>() as SpringJoint;
      sj.connectedBody =colInside.GetComponent<Rigidbody>();
      sj.anchor = new Vector3( 0 , -1, 1);

      sj1 = gameObject.AddComponent<SpringJoint>() as SpringJoint;
      sj1.connectedBody =colInside.GetComponent<Rigidbody>();
      sj1.anchor = new Vector3( 0 , 1, 1 );
    }
  }

  void OnTriggerUp(GameObject o){
    Destroy( sj );
    Destroy( sj1 );
    moving = false;
  }


  void StayTrigger(GameObject o){
//    print("ff");
  }


  void onCollisionEnter(){
    print( "check" );
  }

  void onTriggerEnter(){
    print( "check" );
  }

  void OnTriggerEnter(Collider Other){

    if( Other.tag == "Hand"){ 
      colInside = Other;
      inside = true; 
    }
  }

  void OnTriggerExit(Collider Other){
    if( Other.tag == "Hand" && Other == colInside){ 
      colInside = null;
      inside = false; 
    }
  }
}
