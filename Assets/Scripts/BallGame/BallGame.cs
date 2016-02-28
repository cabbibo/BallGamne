using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class BallGame : MonoBehaviour {

  public List<GameObject> Babies = new List<GameObject>();
  public GameObject BabyPrefab;
  public GameObject MommaPrefab;
  public GameObject   Momma;
  public GameObject StartButton;
  public GameObject StartButtonPrefab;

  public GameObject Hand;
  public GameObject Shield;
  public GameObject Controller;
  public GameObject ScoreText;
  public GameObject Platform;
  public GameObject CameraRig;
  public GameObject Title;
  public GameObject Instruction;
  public Material InstructionMat;
  public Material TitleMat;
  public Material PlatformMat;
  public AudioClip blarpClip;
  public AudioClip restartClip;
  private GameObject empty;

  public Shader PlatformShader;
  public GameObject Room;
  public float score;

  private bool triggerDown;
  private AudioSource restartSound;
  private AudioSource blarpSound;
  private SteamVR_PlayArea PlayArea;

  private Vector3 v1;
  private Vector3 v2;
  private Vector3 roomSize;
  private Vector4 MommaInfo;

  public AudioClip[] AudioList;
  public List<AudioSource> AudioSources = new List<AudioSource>();

	// Use this for initialization
	void Start () {

    triggerDown = false;

    EventManager.OnTriggerDown += OnTriggerDown;
    EventManager.OnTriggerUp += OnTriggerUp;
    //EventManager.StayTrigger += StayTrigger;

    restartSound = gameObject.AddComponent<AudioSource>();
    blarpSound = gameObject.AddComponent<AudioSource>();

    restartSound.clip = restartClip;
    blarpSound.clip = blarpClip;

    empty = new GameObject();

    PlayArea = CameraRig.GetComponent<SteamVR_PlayArea>();

    Vector3 v = PlayArea.vertices[0];
    Platform = GameObject.CreatePrimitive(PrimitiveType.Cube);
    Platform.transform.localScale = new Vector3( Mathf.Abs( v.x )  * 1.5f ,1.0f ,  Mathf.Abs( v.z ) * 1.5f);
    Platform.transform.position = new Vector3( 0f , -0.49f , 0f );

    Material m = PlatformMat; //new Material( PlatformShader );

    Platform.GetComponent<MeshRenderer>().material = m ;
    //m = PlatformMat;
    Platform.GetComponent<MeshRenderer>().material.SetVector("_Size" , Platform.transform.localScale );


    Title = GameObject.CreatePrimitive(PrimitiveType.Cube);
    Title.transform.localScale = new Vector3( 2.0f ,1.0f ,  .1f);
    Title.transform.position = new Vector3( 0f , 1.5f , -3f );

    m = TitleMat; //new Material( TitleShader );

    Title.GetComponent<MeshRenderer>().material = m ;
    //m = TitleMat;
    Title.GetComponent<MeshRenderer>().material.SetVector("_Scale" , Title.transform.localScale );



    Instruction = GameObject.CreatePrimitive(PrimitiveType.Cube);
    Instruction.transform.localScale = new Vector3( .5f ,2.0f , 2.0f);
    Instruction.transform.position = new Vector3( 2f , 1.5f , 0 );

    m = InstructionMat; //new Material( InstructionShader );

    Instruction.GetComponent<MeshRenderer>().material = m ;
    //m = InstructionMat;
    Instruction.GetComponent<MeshRenderer>().material.SetVector("_Scale" , Instruction.transform.localScale );


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

    StartButton = (GameObject) Instantiate( StartButtonPrefab, new Vector3() , new Quaternion());
    StartButton.GetComponent<StartButton>().BallGameObj = transform.gameObject;
    StartButton.transform.position = new Vector3(0 , 1  , -Platform.transform.localScale.z * .55f );

    //HandL.GetComponent<HandScript>().BallGameObj = transform.gameObject;
    //HandR.GetComponent<HandScript>().BallGameObj = transform.gameObject;

    ScoreText = Momma.transform.Find("Score").gameObject;//.GetComponent<TextMesh>();
    score = 0;
    restart( transform.gameObject );
    

	}
	
	// Update is called once per frame
	void Update () {

    float base100 = Mathf.Floor( score / 100 );
    float base10  = Mathf.Floor( (score - ( base100 * 100 )) / 10 );
    float base1   = score - (base10 * 10);
    //print( base1 );

    Momma.GetComponent<MeshRenderer>().material.SetInt( "_Digit1" , (int)base1 );
    Momma.GetComponent<MeshRenderer>().material.SetInt( "_Digit2" , (int)base10 );

    //if( triggerDown == false ){
      foreach( GameObject baby in Babies ){

        
       // LineRenderer r = baby.GetComponent<LineRenderer>();
       // r.SetPosition( 0 , baby.transform.position );
       // r.SetPosition( 1 , baby.transform.position );

        v1 = baby.transform.position - Hand.transform.position;
        float l = v1.magnitude;

        float w = (1.0f / (1.0f + l)) * (1.0f / (1.0f + l))  * (1.0f / (1.0f + l));

        float lineWidth = w * .05f;

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
        m.SetVector("_MommaInfo" , MommaInfo );

        Vector3 v = baby.GetComponent<Rigidbody>().velocity;
        baby.transform.LookAt( baby.transform.position + v , Vector3.up );
        v = baby.transform.InverseTransformDirection( v );
        m = baby.GetComponent<MeshRenderer>().material;
        m.SetVector( "_Velocity" , v );




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
    go.GetComponent<Rigidbody>().mass = .2f - (score / 340);
    go.GetComponent<Rigidbody>().angularDrag = 200;
    go.GetComponent<Rigidbody>().freezeRotation = true;
    go.transform.localScale = go.transform.localScale * (2.0f - (score/30));
    go.GetComponent<MeshRenderer>().material.SetFloat("_Score" , (float)score );
  
    //audioSource.clip = AudioList[(int)score];
    audioSource.clip = AudioList[(int)score%4];
    audioSource.pitch = .25f * Mathf.Pow(2 , (int)(score /4 )); 
    audioSource.volume =  Mathf.Pow(.7f , (int)(score /4 )); 
    audioSource.Play();

//    go.GetComponent<SpringJoint>().enabled = false; connectedBody = HandR.GetComponent<Rigidbody>();
    Babies.Add( go );
    
    resizeRoom();
    moveMomma();



    
    score ++;
    ScoreText.GetComponent<TextMesh>().text = score.ToString();
    



  }

  float getSizeFromScore(){
    return 3.0f + score / 3;
  }

  public void moveMomma(){

    float size = getSizeFromScore();

    
    
    Momma.transform.position = new Vector3( Random.Range(  -size/2 , size/2 ), 
                                            Random.Range(   0 + .15f , size/2 + .15f ),
                                            Random.Range(  -size/2 , size/2 ));

    Momma.transform.localScale = new Vector3( size / 10 , size / 10 , size / 10 );

    MommaInfo = new Vector4(
      Momma.transform.position.x,
      Momma.transform.position.y,
      Momma.transform.position.z,
      Momma.transform.localScale.x
    );

    Momma.GetComponent<AudioSource>().Play();

  }

  void resizeRoom(){

    float size = getSizeFromScore();
    
    Room.transform.localScale = new Vector3( size , size/2 + .3f , size );
    Room.transform.position = new Vector3( 0 , size/4 + .15f , 0 );


    roomSize = Room.transform.localScale;

  }

  public void HandHit( GameObject handHit ){
    //print("fUh!");

    //if( score > 1 ){

     restart( handHit );

    //}


  }

  void restart(GameObject handHit ){
     foreach( GameObject baby in Babies ){

        
        Destroy(baby);


      }

      Babies.Clear();
      score = 0;
      blarpSound.Play();

      
      

      StartButton.GetComponent<MeshRenderer>().enabled = true;
      StartButton.GetComponent<BoxCollider>().enabled = true;
      Title.GetComponent<MeshRenderer>().enabled = true;
      Title.GetComponent<BoxCollider>().enabled = true;

      Instruction.GetComponent<MeshRenderer>().enabled = true;
      Instruction.GetComponent<BoxCollider>().enabled = true;

      Momma.GetComponent<MeshRenderer>().enabled = false;
      resizeRoom();
      Room.GetComponent<Room>().active = false;
      //startGame( handHit );
  }

  public void startGame( GameObject go ){

    restartSound.Play();

    Room.GetComponent<Room>().active = true;
    
    StartButton.GetComponent<MeshRenderer>().enabled = false;
    StartButton.GetComponent<BoxCollider>().enabled = false;
    Momma.GetComponent<MeshRenderer>().enabled = true;

    Title.GetComponent<MeshRenderer>().enabled = false;
    Title.GetComponent<BoxCollider>().enabled = false;

    Instruction.GetComponent<MeshRenderer>().enabled = false;
      Instruction.GetComponent<BoxCollider>().enabled = false;

    float size = getSizeFromScore();
    empty.transform.position = new Vector3( Random.Range(  -size/4 , size/4 ), 
                                            Random.Range(   size/4 + .15f , size/4 + .15f ),
                                            Random.Range(  -size/4 , size/4 ));

    empty.transform.position = new Vector3( 0 ,
                                            1 ,
                                            -size/2 );


    MommaHit( empty );

    //StartButton.transform.position = new Vector3( 0 , 1 , 0 );

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
      float lV1 = v1.magnitude;
      v1.Normalize();
      

      Vector3 v = Controller.GetComponent<controllerInfo>().velocity;
      float lVel = v.magnitude;
      float dot = Vector3.Dot( v , v1 );

      v1 = -.5f * triggerVal * v1 * lVel * ( -dot + 1 );
      baby.GetComponent<Rigidbody>().AddForce( v1 );

      //v = Controller.GetComponent<controllerInfo>().angularVelocity;
      //v1 = baby.transform.position - go.transform.position;
      //v1.Normalize();
      //v1 *= .2f * triggerVal * -v.magnitude;
      //baby.GetComponent<Rigidbody>().AddForce( v1 );

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

      float w = (1.0f / (1.0f + lV1)) * (1.0f / (1.0f + lV1));

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
