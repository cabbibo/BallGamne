using UnityEngine;
using System.Collections;

public class HandScript : MonoBehaviour {

  public GameObject BallGameObj;
  private BallGame ballGame;

  // Use this for initialization
  void Start () {


    ballGame = BallGameObj.GetComponent<BallGame>();
    print("YO");
    print( ballGame );

  
  }
  
  // Update is called once per frame
  void Update () {
  
  }


  void OnCollisionEnter( Collision c ){
    if( c.gameObject.tag == "Baby" ){
      ballGame.HandHit( c.gameObject );
    }
  }
}
