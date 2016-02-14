using UnityEngine;
using System.Collections;

public class RoomAudio : MonoBehaviour {


  public AudioClip audioBuffer;
  public AudioSource[] aSources;
  public int numSources;
  public float timeBetween;

  public int[] aFinished;
  public float[] aTimes;
  public float[] aLengths;

  public float[] pitches;

  public float playbackStartTime;
  public float playbackStartRange;



  private float lastPlayTime;
  private int sourceNum;

  // Use this for initialization
  void Start () {

    sourceNum = 0;
    //numSources = 20;

    playbackStartRange = 5;

    aSources  = new AudioSource[numSources];
    aFinished = new int[numSources];
    aTimes    = new float[numSources];
    aLengths  = new float[numSources];

    pitches = new float[]{ 0.25f , .4f , .3f , .2f , .6f };


    for( int i = 0; i < numSources; i++ ){
      aSources[i] = gameObject.AddComponent<AudioSource>();
      aFinished[i] = 0;
      aTimes[i] = 0;
    }

    sourceNum = 0;
  
  }
  
  // Update is called once per frame
  void Update () {


    playbackStartTime = Mathf.Abs(transform.position.x);
    float t = Time.fixedTime;
    for( int i = 0; i < numSources; i++ ){
      updateSource(i, t);
    }
  
  }

  void updateSource(int id , float time ){

    AudioSource a = aSources[id];

    float elapsed = time - aTimes[id];
    float per = elapsed / aLengths[id];

    if( per < 0.2f ){
      a.volume = per / 0.2f;
    }else if( per > 0.2f && per < 0.6f ){
      a.volume = 1;
    }else{
      a.volume = 1 - ( (per - 0.6f) / 0.4f );
    }

    a.volume *= .5f;

    if( per > 1.0f ){
      aFinished[id]=0;
      a.Stop();
    }

  }

  /*void OnTriggerEnter(){

    int startSource = sourceNum;
    checkForProperSource(startSource);

  }

  void OnCollisionEnter(Collision collision) {
     int startSource = sourceNum;
    checkForProperSource(startSource);   
  }*/


  void checkForProperSource( int ss , float pitch ){

    if( aFinished[sourceNum] == 0 ){
      playSource(pitch);
      return;
    }

    sourceNum ++;

    if( sourceNum == numSources ){ sourceNum = 0; }

    if( sourceNum == ss ){
      //addNewSource();
      print( "fullLoop occured. not enough audio sources" );
      return;
    }

    checkForProperSource( ss , pitch );

  }

  void playSource(float pitch){

    AudioSource a = aSources[sourceNum];

//    print(aBuffers[1]);
    a.clip = audioBuffer;

    a.pitch = pitch;//pitches[Random.Range(0,pitches.Length)];
   // a.pitch = .25f;

    a.volume = .0f;

    a.time = 0;//Random.Range(playbackStartTime , playbackStartTime + playbackStartRange);

    aLengths[sourceNum] =  Random.Range(0.0f,1.0f);
    a.Play();
    aTimes[ sourceNum ] = Time.fixedTime;
    aFinished[ sourceNum ] = 1;
    sourceNum += 1;
    lastPlayTime = Time.fixedTime;


    if( sourceNum == numSources ){ sourceNum = 0; }



  }

  void OnTriggerStay(Collider Other){

    //Vect
    Vector3 otherPos = transform.InverseTransformPoint(Other.transform.position);

    playbackStartTime = 100 * otherPos.magnitude;

    hold();
  }

  public void hold(){

    if( Time.fixedTime - lastPlayTime > timeBetween ){
      float pitch = pitches[Random.Range(0,pitches.Length)];
      checkForProperSource(sourceNum , pitch );
    }

  }

  public void hit(float pitch ){
    checkForProperSource( sourceNum , pitch );
  }



}
