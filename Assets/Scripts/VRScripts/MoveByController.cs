using UnityEngine;
using System.Collections;

public class MoveByController : MonoBehaviour {


  public Transform ogTransform;
  public bool moving;
  public bool maintainVelocity;

  private bool inside;
  private Vector3 oPos;
  private Vector3[] posArray = new Vector3[3];
  private Vector3 vel;

  private Quaternion relQuat;
  private Vector3 relPos;



  Collider colInside;

	void OnEnable(){
    EventManager.OnTriggerDown += OnTriggerDown;
    EventManager.OnTriggerUp += OnTriggerUp;
    EventManager.StayTrigger += StayTrigger;
    inside = false;
    moving = false;

    //posArray = new Vector3[10];
  }

	// Update is called once per frame
	void Update () {
    if( moving == true ){
      for( int i  = 2; i > 0; i --){
        posArray[i] = posArray[i-1];
      }
      posArray[0] = colInside.transform.position;
     
     // vel = oPos - pos;
      transform.position = colInside.transform.position;
      transform.rotation = colInside.transform.rotation * relQuat;

      transform.position = transform.position - ( colInside.transform.rotation* relPos);
      //transform.rotation = transform.rotation * relQuat;
    }
	
	}

  void OnTriggerDown(GameObject o){
    if( inside == true ){
      //transform.SetParent(o.transform);
      moving = true;

      relPos = colInside.transform.position - transform.position;

      relQuat = Quaternion.Inverse(colInside.transform.rotation) * transform.rotation;
      relPos = Quaternion.Inverse(colInside.transform.rotation) * relPos;
    
    }
  }

  void OnTriggerUp(GameObject o){
   //transform.SetParent(ogTransform);
    

    if( maintainVelocity == true && moving == true ){

      for( int i = 0; i<2; i++){
        vel += ( posArray[i] - posArray[i+1] );
      }
      vel /= 3;
      print( vel );
      GetComponent<Rigidbody>().velocity = vel * 120.0f;
    }

    
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
    if( Other.tag == "Hand" && Other == colInside && moving == false){ 
      colInside = null;
      inside = false; 
    }
  }

}
