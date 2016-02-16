using UnityEngine;
using System.Collections;

public class StartButton : MonoBehaviour {

  public GameObject BallGameObj;

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}

  void OnTriggerEnter(){
    BallGameObj.GetComponent<BallGame>().startGame( transform.gameObject );
  }
}
