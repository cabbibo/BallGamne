using UnityEngine;
using System.Collections;

public class Momma : MonoBehaviour {

  public GameObject BallGameObj;
  public GameObject Score;
  private BallGame ballGame;

	// Use this for initialization
	void Start () {

    ballGame = BallGameObj.GetComponent<BallGame>();
    Score = transform.Find("Score").gameObject;//.GetComponent<TextMesh>();
    Score.GetComponent<MeshRenderer>().enabled = false;

	
	}
	
	// Update is called once per frame
	void Update () {

    transform.LookAt( Camera.main.gameObject.transform );
	
	}


  void OnCollisionEnter( Collision c ){
    if( c.gameObject.tag == "Baby" ){
      ballGame.MommaHit( c.gameObject );
    }
  }
}
