using UnityEngine;
using System.Collections;

[RequireComponent(typeof(SteamVR_TrackedObject))]
public class controllerInfo : MonoBehaviour{

  public int triggerDown;
  public int thumbDown;
  public Vector2 thumbPosition;
  public Vector2 oThumbPosition;
  public Vector2 thumbVelocity;
  public float sliderX;
  public float sliderY;

  public Vector3 position;
  public Vector3 velocity; 
  public Vector3 angularVelocity; 

  public float triggerVal;



  SteamVR_TrackedObject trackedObj;

  void Awake(){
    trackedObj = GetComponent<SteamVR_TrackedObject>();
    sliderX = 0;
    sliderY = 0;
  }

  void FixedUpdate(){

    var device = SteamVR_Controller.Input((int)trackedObj.index);
    if ( device.GetTouchDown(SteamVR_Controller.ButtonMask.Trigger)){
      triggerDown = 1;
    }

    if ( device.GetTouchUp(SteamVR_Controller.ButtonMask.Trigger)){
      triggerDown = 0;
    }

    position = transform.position;
    velocity = device.velocity;
    angularVelocity = device.angularVelocity;

    oThumbPosition = thumbPosition;
    thumbPosition = device.GetAxis(Valve.VR.EVRButtonId.k_EButton_Axis0);
    
    if(device.GetTouchDown(SteamVR_Controller.ButtonMask.Touchpad)){
      thumbDown = 1;
    }else if(device.GetTouchUp(SteamVR_Controller.ButtonMask.Touchpad)){
      thumbDown = 0;
//      print( sliderX );
    }

    if( thumbDown == 1 ){
      thumbVelocity = thumbPosition - oThumbPosition;
      sliderX += thumbVelocity.x;
      sliderY += thumbVelocity.y;
    }else{
      thumbVelocity = new Vector2( 0 , 0 );
    }

    var axis = device.GetState().rAxis[1];

    triggerVal = axis.x;
    //print( axis.x );

  }


}
