using UnityEngine;
using System.Collections;
using Valve.VR;

public class EventManager : MonoBehaviour 
{

  public delegate void TriggerDown(GameObject t);
  public static event TriggerDown OnTriggerDown;

  public delegate void TriggerUp(GameObject t);
  public static event TriggerUp OnTriggerUp;

  public delegate void TriggerStay(GameObject t);
  public static event TriggerStay StayTrigger;

  public GameObject handL;
  public GameObject handR;

  SteamVR_TrackedObject trackedObjL;
  SteamVR_TrackedObject trackedObjR;

  void Start(){

    trackedObjL = handL.GetComponent<SteamVR_TrackedObject>();
    trackedObjR = handR.GetComponent<SteamVR_TrackedObject>();

  }
  
  void FixedUpdate(){


    getTrigger( handL , trackedObjL );
    getTrigger( handR , trackedObjR );

  }

  void getTrigger( GameObject go , SteamVR_TrackedObject tObj ){

    if((int) tObj.index < 0 ){ return; }
    var device = SteamVR_Controller.Input((int)tObj.index);

    if ( device.GetTouchDown(SteamVR_Controller.ButtonMask.Trigger)){
      if(OnTriggerDown != null) OnTriggerDown(go);
    }

    if ( device.GetTouchUp(SteamVR_Controller.ButtonMask.Trigger)){
      if(OnTriggerUp != null) OnTriggerUp(go);
    }


    if ( device.GetTouch(SteamVR_Controller.ButtonMask.Trigger)){
      if(StayTrigger != null) StayTrigger(go);
    }

  }



}