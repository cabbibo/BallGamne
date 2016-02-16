Shader "Custom/LineShader" {
 Properties {
  

    _NumberSteps( "Number Steps", Int ) = 20
    _MaxTraceDistance( "Max Trace Distance" , Float ) = 10.0
    _IntersectionPrecision( "Intersection Precision" , Float ) = 0.0001



  }
  
  SubShader {
    //Tags { "RenderType"="Transparent" "Queue" = "Transparent" }

    Tags { "RenderType"="Transparent" "Queue" = "Geometry" }
    LOD 200

    Pass {
      //Blend SrcAlpha OneMinusSrcAlpha // Alpha blending


      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // Use shader model 3.0 target, to get nicer looking lighting
      #pragma target 3.0

      #include "UnityCG.cginc"
      
 
      


      uniform int _NumberSteps;
      uniform float  _IntersectionPrecision;
      uniform float _MaxTraceDistance;

      uniform float3 _Hand1;
      uniform float3 _Hand2;

      uniform float3 endPoint;
      uniform float3 startPoint;

      uniform float trigger;
      


      struct VertexIn
      {
         float4 position  : POSITION; 
         float3 normal    : NORMAL; 
         float4 texcoord  : TEXCOORD0; 
         float4 tangent   : TANGENT;
      };

      struct VertexOut {
          float4 pos    : POSITION; 
          float3 normal : NORMAL; 
          float4 uv     : TEXCOORD0; 
          float3 ro     : TEXCOORD2;
          float3 directionVector  : TEXCOORD3;

          //float3 rd     : TEXCOORD3;
          float3 camPos : TEXCOORD4;
      };
        


      VertexOut vert(VertexIn v) {
        
        VertexOut o;

        o.normal = v.normal;
        
        o.uv = v.texcoord;
  
        // Getting the position for actual position
        o.pos = mul( UNITY_MATRIX_MVP , v.position );
     
        float3 mPos = mul( _Object2World , v.position );

        o.ro = v.position;
        o.directionVector = normalize( startPoint - endPoint );
        o.camPos = mul( _World2Object , float4( _WorldSpaceCameraPos  , 1. )); 

        return o;

      }


     // Fragment Shader
      fixed4 frag(VertexOut i) : COLOR {


        float3 col = float3( 1.0 , 1.0 , 1.0 );

        float v = sin( (1. - i.uv.x) * ( 80. + 5. * trigger) );
        float cuttoff = .8;
        if(trigger > 0 ){ 
         // v = -v;
          //col = float3( .3 , .5 , .7 );
        }else{ 
          //col = float3( .7 , .5 , .3 );
          
        }
        if( v > trigger * 1. - .95){
          discard;
        }
   
    	
        float dist = length( startPoint - endPoint );

        //col = float3( sin( i.uv.x * 100. ) , 0. , trigger * .7 + min( 1. , trigger * 1000. ) * .3 );
        //col = float3( trigger , trigger , trigger );
        fixed4 color;
        color = fixed4( col  / (dist * dist) , 1.0 );
        return color;
      }

      ENDCG
    }
  }
  FallBack "Diffuse"
}