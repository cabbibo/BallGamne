using UnityEngine;
using System.Collections;

public class HighScoreBall : MonoBehaviour {


  private float[] octaves;
	// Use this for initialization
	void Start () {
	 octaves = new float[4];
   octaves[0] = .5f;
   octaves[1] = 1;
   octaves[2] = .75f;
   octaves[3] = 1.25f;

	}
	
	// Update is called once per frame
	void Update () {
	transform.LookAt( Camera.main.gameObject.transform );
	}

  void OnCollisionEnter( Collision c ){

    GetComponent<AudioSource>().pitch = octaves[Random.Range(0, octaves.Length)];
    GetComponent<AudioSource>().Play();

  }
}
