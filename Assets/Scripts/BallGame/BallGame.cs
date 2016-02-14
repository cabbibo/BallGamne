using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class BallGame : MonoBehaviour {

  public List<GameObject> Babies = new List<GameObject>();
  public GameObject BabyPrefab;
  public GameObject MommaPrefab;
  public GameObject   Momma;

  public GameObject Hand;
  public GameObject Controller;
  public GameObject ScoreText;
  public GameObject Platform;
  public GameObject CameraRig;
  public Material PlatformMat;
  public GameObject Room;
  public float score;

  private bool triggerDown;
  private AudioSource restartSound;
  private SteamVR_PlayArea PlayArea;

  private Vector3 v1;
  private Vector3 v2;
  private Vector3 roomSize;

  public AudioClip[] AudioList;
  public List<AudioSource> AudioSources = new List<AudioSource>();

	// Use this for initialization
	void Start () {

    triggerDown = false;

    EventManager.OnTriggerDown += OnTriggerDown;
    EventManager.OnTriggerUp += OnTriggerUp;
    //EventManager.StayTrigger += StayTrigger;

    restartSound = GetComponent<AudioSource>();

    PlayArea = CameraRig.GetComponent<SteamVR_PlayArea>();

    Vector3 v = PlayArea.vertices[0];
    Platform = GameObject.CreatePrimitive(PrimitiveType.Cube);
    Platform.transform.localScale = new Vector3( Mathf.Abs( v.x )  * 1.5f ,1.0f ,  Mathf.Abs( v.z ) * 1.5f);
    Platform.transform.position = new Vector3( 0f , -0.4f , 0f );
    Platform.GetComponent<MeshRenderer>().material = PlatformMat;


//Loading the items into the array
  /*AudioList =  new AudioClip[]{ (AudioClip)Resources.Load("Audio/friends/bass"),
                                 (AudioClip)Resources.Load("Audio/friends/plipPlop1"),
                                 (AudioClip)Resources.Load("Audio/friends/plipPlop2"),
                                 (AudioClip)Resources.Load("Audio/friends/shuffle"),
                                 (AudioClip)Resources.Load("Audio/friends/tenor"),
                                 (AudioClip)Resources.Load("Audio/friends/heartbeat"),
                                 (AudioClip)Resources.Load("Audio/friends/atmosphere"),
                                 (AudioClip)Resources.Load("Audio/friends/melody1"),
                                 (AudioClip)Resources.Load("Audio/friends/melody2"),
                                 (AudioClip)Resources.Load("Audio/friends/melody3"),
                                 (AudioClip)Resources.Load("Audio/friends/melody4"),
                                 (AudioClip)Resources.Load("Audio/friends/melody5"),
                                 (AudioClip)Resources.Load("Audio/friends/burial") };*/

  AudioList =  new AudioClip[]{ (AudioClip)Resources.Load("Audio/hydra/TipHit1"),
                                (AudioClip)Resources.Load("Audio/hydra/TipHit2"),
                                (AudioClip)Resources.Load("Audio/hydra/TipHit3"),
                                (AudioClip)Resources.Load("Audio/hydra/TipHit4"), };
     
    for( var i = 0; i < AudioList.Length; i ++ ){
      print(AudioList[i]);

       AudioSource audioSource = gameObject.AddComponent<AudioSource>();
       audioSource.clip = AudioList[i];
       audioSource.Play();
       audioSource.volume = 0;
       AudioSources.Add( audioSource );
    }




    Momma = (GameObject) Instantiate( MommaPrefab, new Vector3() , new Quaternion());
    Momma.GetComponent<Momma>().BallGameObj = transform.gameObject;
    Momma.transform.position = new Vector3( 0 , 3 , 0 );

    //HandL.GetComponent<HandScript>().BallGameObj = transform.gameObject;
    //HandR.GetComponent<HandScript>().BallGameObj = transform.gameObject;

    ScoreText = Momma.transform.Find("Score").gameObject;//.GetComponent<TextMesh>();
    score = 0;
    restart( transform.gameObject );
    

	}
	
	// Update is called once per frame
	void Update () {

    //if( triggerDown == false ){
      foreach( GameObject baby in Babies ){

        
       // LineRenderer r = baby.GetComponent<LineRenderer>();
       // r.SetPosition( 0 , baby.transform.position );
       // r.SetPosition( 1 , baby.transform.position );

        v1 = baby.transform.position - Hand.transform.position;
        float l = v1.magnitude;

        float w = (1.0f / (1.0f + l)) * (1.0f / (1.0f + l));

        float lineWidth = w * .15f;

         LineRenderer r = baby.GetComponent<LineRenderer>();
         Material m = r.material;
          r.SetPosition( 0 , baby.transform.position );
          r.SetPosition( 1 , Hand.transform.position );
          r.SetWidth(lineWidth, lineWidth) ;
          //r.SetWidth(1, lineWidth);
          r.SetColors( Color.red , Color.green );
          m.SetVector( "startPoint" , Hand.transform.position );
          m.SetVector( "endPoint" , baby.transform.position );
          m.SetFloat( "trigger" , Controller.GetComponent<controllerInfo>().triggerVal );

        m = baby.GetComponent<TrailRenderer>().material;
        m.SetVector("_Size" , roomSize );

      }
    //}

      //Hand.transform.localScale = new Vector3()

    
	
	}

  void FixedUpdate(){

    UpdateBabyForces( Hand );
  }

  public void MommaHit( GameObject goHit ){

    // Make a new object
    GameObject go = (GameObject) Instantiate( BabyPrefab, new Vector3() , new Quaternion());
    go.transform.position = goHit.transform.position;
    go.GetComponent<SpringJoint>().connectedBody = Hand.GetComponent<Rigidbody>();
    AudioSource audioSource = go.GetComponent<AudioSource>();
    go.GetComponent<Rigidbody>().drag = .7f - (score / 100);
    go.GetComponent<Rigidbody>().mass = .2f - (score / 140);
    go.transform.localScale = go.transform.localScale * (2.0f - (score/30));

    //audioSource.clip = AudioList[(int)score];
    audioSource.clip = AudioList[(int)score%4];
    audioSource.pitch = .25f * Mathf.Pow(2 , (int)(score /4 )); 
    audioSource.volume =  Mathf.Pow(.7f , (int)(score /4 )); 
    audioSource.Play();

//    go.GetComponent<SpringJoint>().enabled = false; connectedBody = HandR.GetComponent<Rigidbody>();
    Babies.Add( go );

    float size = 4.5f + score / 3;
    Room.transform.localScale = new Vector3( size , size/2 , size );
    Room.transform.position = new Vector3( 0 , size/4, 0 );

    roomSize = Room.transform.localScale;

    Momma.transform.position = new Vector3( Random.Range(  -size/2 , size/2 ), 
                                            Random.Range(   0 , size/2 ),
                                            Random.Range(  -size/2 , size/2 ));

    score ++;
    ScoreText.GetComponent<TextMesh>().text = score.ToString();
    Momma.GetComponent<AudioSource>().Play();
  }

  public void HandHit( GameObject handHit ){
    //print("fUh!");

    if( score > 1 ){

     restart( handHit );

    }


  }

  void restart(GameObject handHit ){
     foreach( GameObject baby in Babies ){

        
        Destroy(baby);


      }

      Babies.Clear();
      score = 0;

      MommaHit( handHit );
      restartSound.Play();
  }

  void OnTriggerDown( GameObject go ){

   // triggerDown = true;

  }

  void OnTriggerUp( GameObject go ){

    //triggerDown = false;

  }


  void UpdateBabyForces( GameObject go ){

    float triggerVal = Controller.GetComponent<controllerInfo>().triggerVal;
    if( triggerVal > 0 ){ triggerDown = true; }else{ triggerDown = false; }

    //print( Controller.GetComponent<controllerInfo>().velocity );

    foreach( GameObject baby in Babies ){

      v1 = baby.transform.position - go.transform.position;
      float l = v1.magnitude;
      v1.Normalize();
      v1 *= -.5f* triggerVal * l;

      Vector3 v = Controller.GetComponent<controllerInfo>().velocity;
      v1 = .5f * triggerVal * Vector3.Scale( v , v);
      //baby.GetComponent<Rigidbody>().AddForce( v1 );

      v = Controller.GetComponent<controllerInfo>().angularVelocity;
      v1 = baby.transform.position - go.transform.position;
      v1.Normalize();
      v1 *= .2f * triggerVal * -v.magnitude;
      baby.GetComponent<Rigidbody>().AddForce( v1 );

      SpringJoint sj = baby.GetComponent<SpringJoint>();
      sj.spring = 1 * triggerVal;

      /*foreach( GameObject oBaby in Babies ){

        if( oBaby != baby ){
          v1 = baby.transform.position - oBaby.transform.position;
          l = v1.magnitude;
          v1.Normalize();
          v2 = oBaby.GetComponent<Rigidbody>().velocity;
          v2.Normalize();
        if( l < .4f ){
          baby.GetComponent<Rigidbody>().AddForce( v1 * .1f );
          
        }
        if( l  < 1.2f ){
          baby.GetComponent<Rigidbody>().AddForce( v2 * .01f);
        }
        if( l > 3.0f ){
          baby.GetComponent<Rigidbody>().AddForce( v1 * -.4f);
        }

          

        }

      }*/
      
      //baby.GetComponent<Rigidbody>().AddForce( v1 );

      float w = (1.0f / (1.0f + l)) * (1.0f / (1.0f + l));

      float lineWidth = w * .15f;

      
      Color c = new Color( w , w , w );




     

     // print( r );


     /* foreach (Transform child in baby.transform){
        if( child.gameObject.tag == go.tag ){

          child.transform.parent = null;

          v1 = new Vector3( .1f , .1f , l  );

          child.localScale = v1;
          child.LookAt( go.transform.position , Vector3.left );
          child.transform.position = baby.transform.position - v1 * l * .5f;

          child.transform.parent = baby.transform;

        }
      }*/



    }

  }
}
