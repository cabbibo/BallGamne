using UnityEngine;
using System.Collections;

public class tutorialButton : MonoBehaviour {

  public BallGame ballGame;

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}

  void OnTriggerEnter( Collider c ){

    print( c );
    print( c.gameObject.tag );
    if (c.gameObject.tag == "Hand"){

      print("YUP YUP");

      ballGame.startTutorial();

    }
  }
}
