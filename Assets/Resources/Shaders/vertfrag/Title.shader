Shader "Custom/Title" {
 Properties {
  

    _NumberSteps( "Number Steps", Int ) = 20
    _MaxTraceDistance( "Max Trace Distance" , Float ) = 10.0
    _IntersectionPrecision( "Intersection Precision" , Float ) = 0.0001
    _Scale( "Scale" , Vector ) = ( 1.5 , .2 , 2 , 0 )
    _TitleTexture( "TitleTexture" , 2D ) = "white" {}
    _CubeMap( "CubeMap" , Cube ) = "" {}




  }
  
  SubShader {
    //Tags { "RenderType"="Transparent" "Queue" = "Transparent" }

    Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
    LOD 200

    Pass {
      //Blend SrcAlpha OneMinusSrcAlpha // Alpha blending

      CULL OFF
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // Use shader model 3.0 target, to get nicer looking lighting
      #pragma target 3.0

      #include "UnityCG.cginc"
      #include "Chunks/noise.cginc"
      
 
      


      uniform int _NumberSteps;
      uniform float  _IntersectionPrecision;
      uniform float _MaxTraceDistance;
      uniform sampler2D _TitleTexture;
      uniform samplerCUBE _CubeMap;

      uniform float3 _Hand1;
      uniform float3 _Hand2;
      uniform float3 _Scale;
      uniform float _Learning;
      


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
          float3 centerP : TEXCOORD3;

          //float3 rd     : TEXCOORD3;
          float3 camPos : TEXCOORD4;
      };
        

float3 hsv(float h, float s, float v)
{
  return lerp( float3( 1.0 , 1, 1 ) , clamp( ( abs( frac(
    h + float3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}

      VertexOut vert(VertexIn v) {
        
        VertexOut o;

        o.normal = v.normal;
        
        o.uv = v.texcoord;
  
        // Getting the position for actual position
        o.pos = mul( UNITY_MATRIX_MVP , v.position );
     
        float3 mPos = mul( _Object2World , v.position );
        o.centerP = mul( _Object2World , float4( 0. , 0. , 0. , 1. ) ).xyz;

        o.ro = v.position;
        o.camPos = mul( _World2Object , float4( _WorldSpaceCameraPos  , 1. )); 

        return o;

      }


     // Fragment Shader
      fixed4 frag(VertexOut i) : COLOR {

      	//if( i.normal.z < .9 ){ discard; }

        float3 ro = i.ro;
        float3 rd = normalize(ro - i.camPos);

       // ro -= i.centerP;
       // rd += i.centerP;

        float3 col = float3( 0.0 , 0.0 , 0.0 );

    		col= float3( 0. , 0. , 0. );

    		
        for( int i = 0; i < 40; i++){

          float3 pos = ro + rd * (float(i) * .01 );

          float2 lookup = pos.xy * float2( _Scale.x , _Scale.y ) * .6 +.5 * float2( _Scale.x * .5 , _Scale.y);

          float val = tex2D(_TitleTexture , lookup).a;

          float noiseVal = 2 * noise( pos * _Scale * 20.0 + float3( 0 , 0 , _Time.y));

          float total = val +  noiseVal * val;

          if( total > .8 ){
            col += hsv( float(i) / 40.0 , 1. , 1. ) / (float(i)* 100.0+1);
            //break;
          }
          ;

        }
        col /= 40.0;
        col = normalize( col );
     
    		//col = float3( 1. , 1. , 1. );
        float m = col.x * col.y * col.z + .3;// length( col );
        col = lerp( col , float3( m  , m , m) , _Learning );

            fixed4 color;
            color = fixed4( col , 1. );
            return color;
      }

      ENDCG
    }
  }
  FallBack "Diffuse"
}