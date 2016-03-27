using UnityEngine;
using System.Collections;

using UnityEngine;
 
// TODO: make it so each frame, the number of collisions is updated via a uniform. 
// buffer always remains large size, but uniform passed through will make sure we
// only loop through the collisions active that frame;


public class Room : MonoBehaviour {


    public const int ts = 6;
    public const int threadX = ts;
    public const int threadY = ts;
    public const int threadZ = ts;

    public const int strideX = ts;
    public const int strideY = ts;
    public const int strideZ = ts;

    public int ribbonWidth = 20;
    public int numCollisions = 5;

    public Shader shader;
    public Shader particleShader;
    public ComputeShader computeShader;

        private int collisionsThisFrame;



    private ComputeBuffer _vertBuffer;
    private ComputeBuffer _ogBuffer;
    private ComputeBuffer _transBuffer;
    private ComputeBuffer _collisionBuffer;

    public GameObject handL;
    public GameObject handR;
    public GameObject mini;

    public Texture2D normalMap;
    public Cubemap cubeMap;

    public bool active;

    private RoomAudio roomAudio;


      /*
        
        float3 pos 
        float3 vel
        float3 nor
        float2 uv
        float  ribbonID
        float  life 
        float3 debug

    */

    private const int VERT_SIZE = 16;

    /*struct Collision {
        float3 pos;
        float3 direction;
        float speed;
        float active;
      };*/
    private const int COLLISION_SIZE = 8;



    private int gridX { get { return threadX * strideX; } }
    private int gridY { get { return threadY * strideY; } }
    private int gridZ { get { return threadZ * strideZ; } }

    private int maxVertCount { get { return gridX * gridY * gridZ; } }


    private int numberRibbons = 6;


    private int maxVertsPerRibbon { get { return (int)Mathf.Floor( (float)maxVertCount / numberRibbons ); } }
    private int ribbonLength { get { return (int)Mathf.Floor( (float)maxVertsPerRibbon / ribbonWidth ); } }
    private int quadsPerRibbon { get { return (ribbonWidth - 1) * (ribbonLength-1); } }
    private int vertsPerRibbon { get { return ribbonWidth * (ribbonLength); } }


    private int usedVertCount { get { return ribbonLength * ribbonWidth * numberRibbons; } }
    private int unusedVertCount { get { return maxVertCount - usedVertCount; } }
    private int numVertsTotal {get{return numberRibbons * quadsPerRibbon * 3 * 2; }}
      

    private int _kernel;
    private Material material;
    private Material particleMat;

    private Vector3 p1;
    private Vector3 p2;

    private Texture2D audioMap;

    private float[] transValues = new float[32];
    private float[] collisionValues;// = new float[ numCollisions * COLLISION_SIZE ];

    public struct CollisionInfo {

      public float time;
      public Vector3 pos;
      public Vector3 dir;
      public float active;
      public float speed;
    
    }

    public int activeCollision = 0;
    
    public CollisionInfo[] collisions;

 

	// Use this for initialization
	void Start(){

    collisionValues = new float[ numCollisions * COLLISION_SIZE ];
    collisions = new CollisionInfo[ numCollisions ];

    foreach( Transform childTransform in transform )
    {
        CollisionToParent colPar = childTransform.gameObject.AddComponent<CollisionToParent>();
        colPar.parent = transform.gameObject;
        
    }

    roomAudio = transform.gameObject.GetComponent<RoomAudio>();

    //print(quadsPerRibbon);
    //print("maxVertCount");
    //print(maxVertCount);
    //print("usedVertCount");
    //print(usedVertCount);
    //print("unusedVertsCount");
    //print(unusedVertCount);
//
    //print("ribbonLength");
    //print(ribbonLength);
//
    //print("numVertsTotal");
    //print(numVertsTotal);
      
    createBuffers();
    createMaterial();

    _kernel = computeShader.FindKernel("CSMain");

    PostRenderEvent.PostRender += Render;
	
	}
	// Update is called once per frame
	void Update () {
	
	}

 
  //For some reason I made this method to create a material from the attached shader.
  private void createMaterial(){

    material = new Material( shader );
    particleMat = new Material( particleShader );

  }

  //Remember to release buffers and destroy the material when play has been stopped.
  void ReleaseBuffer(){

    _vertBuffer.Release(); 
    _ogBuffer.Release(); 
    _transBuffer.Release(); 
    DestroyImmediate( material );

  }




  private void Render(){

    if( this.active == true ){     
      Dispatch();

     
      
      material.SetPass(0);

      material.SetBuffer("buf_Points", _vertBuffer);
      material.SetBuffer("og_Points", _ogBuffer);
      material.SetBuffer("transBuffer", _transBuffer);

      material.SetInt("_RibbonWidth"   , ribbonWidth   );
      material.SetInt("_RibbonLength"  , ribbonLength  );
      material.SetInt("_NumberRibbons" , numberRibbons );
      material.SetInt("_QuadsPerRibbon"  , quadsPerRibbon);

      material.SetTexture( "_NormalMap" , normalMap );
      material.SetTexture("_CubeMap" , cubeMap );   
      material.SetMatrix("worldMat", transform.localToWorldMatrix);


      Graphics.DrawProcedural(MeshTopology.Triangles, numVertsTotal);

      particleMat.SetPass(0);

      particleMat.SetBuffer("buf_Points", _vertBuffer);
      particleMat.SetBuffer("og_Points", _ogBuffer);

      //Graphics.DrawProcedural(MeshTopology.Triangles, maxVertCount * 3 );

    }


  }

  private void createBuffers() {

      _vertBuffer = new ComputeBuffer( maxVertCount ,  VERT_SIZE * sizeof(float));
      _ogBuffer = new ComputeBuffer( maxVertCount ,  3 * sizeof(float));
      _transBuffer = new ComputeBuffer( 32 ,  sizeof(float));
      _collisionBuffer = new ComputeBuffer( numCollisions ,  COLLISION_SIZE * sizeof(float));
      setCollisionDebugValues();

      float[] inValues = new float[VERT_SIZE * maxVertCount];
      float[] ogValues = new float[3 * maxVertCount];

      int index = 0;
      int indexOG = 0;

      float a = .3f;
      float c = .8f;

      Vector3[] vecs = new [] {
        new Vector3(  1 ,  0 ,  0 ),
        new Vector3( -1 ,  0 ,  0 ),
        new Vector3(  0 ,  1 ,  0 ),
        new Vector3(  0 , -1 ,  0 ),
        new Vector3(  0 ,  0 ,  1 ),
        new Vector3(  0 ,  0 , -1 )
      };



      for (int z = 0; z < gridZ; z++) {
        for (int y = 0; y < gridY; y++) {
          for (int x = 0; x < gridX; x++) {

            int id = x + y * gridX + z * gridX * gridY; 

            int idInRibbon = id;
            int faceID = (int)Mathf.Floor( idInRibbon / (ribbonWidth * ribbonLength) );
           // if( (float)faceID == (float)stalkID / (ribbonWidth * ribbonLength)){ print(faceID); print("WOW"); }

            idInRibbon = idInRibbon - faceID * ( ribbonWidth * ribbonLength );

            float uvX = ((float)(idInRibbon % ribbonWidth )) / (ribbonWidth-1);
            float uvY = (Mathf.Floor( (float)(idInRibbon / ribbonWidth))) / (ribbonLength-1);
            
           // if( uvX == 0 ){ print( uvY ); }

            float u = uvY * 2.0f * Mathf.PI;
            float v = uvX * 2.0f * Mathf.PI;

            float xV = (1.0f * uvX) - 0.5f;
            float zV = (1.0f * uvY) - 0.5f;
            float yV = .5f;

            Vector3 vec  = new Vector3( xV , yV , zV );

            Vector3 rVec, uVec, fVec; // right up forward
            Vector3 upVec = new Vector3( 0 , 1 , 0 );
            upVec.Normalize();
            if( faceID <= 3 ){
              vec = Quaternion.AngleAxis(360 * faceID / 4, Vector3.forward) * vec;

              ogValues[indexOG++] = vec.x;
              ogValues[indexOG++] = vec.y;
              ogValues[indexOG++] = vec.z;

              vec = transform.localToWorldMatrix.MultiplyPoint( vec );

              upVec = Quaternion.AngleAxis(360 * faceID / 4, Vector3.forward) * upVec;

            }else if( faceID == 4 || faceID == 5 ){
              vec = Quaternion.AngleAxis( 360 * ((faceID-4) * 2 + 1 ) / 4  , Vector3.right ) * vec;

              ogValues[indexOG++] = vec.x;
              ogValues[indexOG++] = vec.y;
              ogValues[indexOG++] = vec.z;

              vec = transform.localToWorldMatrix.MultiplyPoint( vec );
              upVec = Quaternion.AngleAxis( 360 * ((faceID-4) * 2 + 1 ) / 4  , Vector3.right ) * upVec;
            }



            // /xV  = uvX / 10;
            // /yV  = 1;
            // /zV  =( uvY -.5f)* 10;

           



            //pos
            // need to be slightly different to not get infinte forces
            inValues[index++] = vec.x * 1.0f;
            inValues[index++] = vec.y * 1.0f;
            inValues[index++] = vec.z * 1.0f;
           
            //vel
            inValues[index++] = Random.Range(-.01f , .01f );
            inValues[index++] = Random.Range(-.01f , .01f );
            inValues[index++] = Random.Range(-.01f , .01f );

            //nor
            inValues[index++] = upVec.x;
            inValues[index++] = upVec.y;
            inValues[index++] = upVec.z;

            //uv
            inValues[index++] = uvX;
            inValues[index++] = uvY;

            //ribbon id
            inValues[index++] = 0f;

            //life
            inValues[index++] = -1f;

            //debug
            inValues[index++] = upVec.x;
            inValues[index++] = upVec.y;
            inValues[index++] = upVec.z;

          }
        }
      }

      _vertBuffer.SetData(inValues);
      _ogBuffer.SetData(ogValues);

    }

  private void setTransValues(){
    Matrix4x4 m = transform.localToWorldMatrix;

    for( int i = 0; i < 16; i++ ){
      int x = i % 4;
      int y = (int) Mathf.Floor(i / 4);
      transValues[i] = m[x,y];
    }

    m = transform.worldToLocalMatrix;

    for( int i = 0; i < 16; i++ ){
      int x = i % 4;
      int y = (int) Mathf.Floor(i / 4);
      transValues[i+16] = m[x,y];
    }

    _transBuffer.SetData(transValues);

  }

  public void setCollisionValues(){

    for( int i = 0; i < numCollisions; i++ ){
      CollisionInfo colInfo = collisions[i];
      int baseIndex = i * COLLISION_SIZE;

      float min = 1.0f / (1.0f + Mathf.Abs((float)colInfo.time - (float)Time.time));

      colInfo.active = Mathf.Max( 0.0f , min);
      //colInfo.active = 1.0f;

      //print( colInfo.pos );

      collisionValues[ baseIndex  + 0 ] = colInfo.pos.x;
      collisionValues[ baseIndex  + 1 ] = colInfo.pos.y;
      collisionValues[ baseIndex  + 2 ] = colInfo.pos.z;

      collisionValues[ baseIndex  + 3 ] = colInfo.dir.x;
      collisionValues[ baseIndex  + 4 ] = colInfo.dir.y;
      collisionValues[ baseIndex  + 5 ] = colInfo.dir.z;

      collisionValues[ baseIndex  + 6 ] = colInfo.speed;
      collisionValues[ baseIndex  + 7 ] = colInfo.active;

    }


    _collisionBuffer.SetData( collisionValues );

  }

    public void setCollisionDebugValues(){

    for( int i = 0; i < numCollisions; i++ ){
      CollisionInfo colInfo = collisions[activeCollision];
      int baseIndex = i * COLLISION_SIZE;

      float min = (float)colInfo.time - Time.time;
      colInfo.active = Mathf.Max( 0.0f ,min);
      colInfo.active = 1.0f;

      collisionValues[ baseIndex  + 0 ] = 0; //colInfo.pos.x;
      collisionValues[ baseIndex  + 1 ] = 0; //colInfo.pos.y;
      collisionValues[ baseIndex  + 2 ] = 0; //colInfo.pos.z;
      collisionValues[ baseIndex  + 3 ] = 0; //colInfo.dir.x;
      collisionValues[ baseIndex  + 4 ] = 0; //colInfo.dir.y;
      collisionValues[ baseIndex  + 5 ] = 0; //colInfo.dir.z;
      collisionValues[ baseIndex  + 6 ] = 0; //colInfo.speed;
      collisionValues[ baseIndex  + 7 ] = 0; //colInfo.active;

    }


    _collisionBuffer.SetData( collisionValues );

  }


  private void Dispatch() {

    setTransValues();
    setCollisionValues();

    computeShader.SetVector("_HandL", handL.transform.position);
    computeShader.SetVector("_HandR", handR.transform.position);


    computeShader.SetFloat( "_DeltaTime"    , Time.deltaTime );
    computeShader.SetFloat( "_Time"         , Time.time      );
    computeShader.SetInt( "_RibbonWidth"    , ribbonWidth    );
    computeShader.SetInt( "_NumCollisions"    , numCollisions    );


    computeShader.SetBuffer(_kernel, "transBuffer"  , _transBuffer);
    computeShader.SetBuffer(_kernel, "vertBuffer"   , _vertBuffer);
    computeShader.SetBuffer(_kernel, "ogBuffer"     , _ogBuffer);
    computeShader.SetBuffer(_kernel, "collisionBuffer"     , _collisionBuffer);

    computeShader.Dispatch(_kernel, strideX , strideY , strideZ );

    collisionsThisFrame = 0;

  }




  public void BabyHit( Collision c ){

    collisionsThisFrame ++;
    if(collisionsThisFrame > 2 ){ return;}

//      print(activeCollision);
    CollisionInfo colInfo = collisions[activeCollision];
    

    colInfo.dir = c.relativeVelocity;//.Normalize();
    colInfo.speed = colInfo.dir.magnitude;
    colInfo.dir.Normalize();
    colInfo.time = Time.time;
    colInfo.pos = c.gameObject.transform.position;
    colInfo.active = 1.0f;

    collisions[activeCollision] = colInfo;

    activeCollision ++;
    if( activeCollision == numCollisions ){ activeCollision = 0;}

    //setCollisionValues();
    float pitch = colInfo.speed * .1f + .1f;
    roomAudio.hit( pitch );
  }
 


}
