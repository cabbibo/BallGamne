using UnityEngine;
using System.Collections;
 
[System.Serializable]
public class Game { 
 
    public static Game current;
    public bool finishedTutorial;
    public float highScore;
    public float lastScore;
 
    public Game () {
        finishedTutorial = false;
        highScore = 0;
        lastScore = 0;
    }
         
}