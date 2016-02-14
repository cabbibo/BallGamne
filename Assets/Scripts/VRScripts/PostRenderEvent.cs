using UnityEngine;
using System.Collections;

public class PostRenderEvent : MonoBehaviour 
{

  public delegate void CameraPostRender();
  public static event CameraPostRender PostRender;

  void Update(){}
  void OnPostRender(){
    if(PostRender != null)
      PostRender();
  }

}