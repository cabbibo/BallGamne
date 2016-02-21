Shader "Custom/Instructions" {
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
        

      float sdBox( float3 p, float3 b ){

        float3 d = abs(p) - b;

        return min(max(d.x,max(d.y,d.z)),0.0) +
               length(max(d,0.0));

      }

      float sdSphere( float3 p, float s ){
        return length(p)-s;
      }

      float sdCapsule( float3 p, float3 a, float3 b, float r )
      {
          float3 pa = p - a, ba = b - a;
          float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
          return length( pa - ba*h ) - r;
      }

      float2 smoothU( float2 d1, float2 d2, float k)
      {
          float a = d1.x;
          float b = d2.x;
          float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
          return float2( lerp(b, a, h) - k*h*(1.0-h), lerp(d2.y, d1.y, pow(h, 2.0)));
      }

      
      float3 modit(float3 x, float3 m) {
			    float3 r = x%m;
			    return r<0 ? r+m : r;
			}
      float2 map( in float3 pos , in float3 cPos ){
        
        float2 res;
        float2 lineF;
        float2 sphere;

        //pos *= _Scale;

			//res = float2( sdSphere( pos , .4 ) , 0.6 );
        float3 modVal = float3( 1.2 , 1.2 , 1.2 );
        //pos -= float3( 0 , .2 , 0.);
//
        //pos += .1 * float3( sin( pos.x * 10. ) , sin( pos.y * 10. ) , sin( pos.z * 10. ));
        //pos += .1 * float3( sin( pos.x * 10. ) , sin( pos.y * 10. ) , sin( pos.z * 10. ));
        //pos += .1 * float3( sin( pos.x * 10. ) , sin( pos.y * 10. ) , sin( pos.z * 10. ));
        int3 test;

        float3 fPos= pos - cPos - float3( 0., 0., 0.);
        //float2 res2 = float2( sdSphere( modit(pos , modVal) - modVal / 2. , .3 ) , 0.6 );
        float2 res2 = float2( sdBox( fPos , _Scale * .5 - float3( .2 , .2 , .2 ) ) , 0.6 );
      	float n = noise( pos * (10. +sin( _Time.x * 20.) ) + float3( _SinTime.x , _SinTime.y , _SinTime.z ) );


        float2 lookup = fPos.zy * .8 + float2( .5 , .5 );
        lookup.x = 1.-lookup.x;
        float val = tex2D(_TitleTexture , lookup).a;
        res2.x -= val * .05;// * max( 0. , fPos.z);
        res2.x -= n* (.04 + val * .04);
        res2.y = 1. + val;
        //if( val >= .95 ){ res2.y = 5.; }
       	//res = smoothU( res , res2 , 0.1 );
    		//res = float2( length( pos - float3( 0., -.8 ,0) ) - 1., 0.1 );
    		//res = smoothU( res , float2( length( pos - float3( .3 , .2 , -.2) ) - .1, 0.1 ) , .05 );
    		//res = smoothU( res , float2( length( pos - float3( -.4 , .2 , .4) ) - .1, 0.1 ) , .05 );
    		//res = smoothU( res , float2( length( pos - float3( 0.3 , .2 , -.3) ) - .1, 0.1 ) , .05 );

  	    return res2; 
  	 
  	  }

      float3 calcNormal( in float3 pos  , in float3 centerP ){

      	float3 eps = float3( 0.001, 0.0, 0.0 );
      	float3 nor = float3(
      	    map(pos+eps.xyy , centerP ).x - map(pos-eps.xyy, centerP).x,
      	    map(pos+eps.yxy , centerP ).x - map(pos-eps.yxy, centerP).x,
      	    map(pos+eps.yyx , centerP ).x - map(pos-eps.yyx, centerP).x );
      	return normalize(nor);

      }
              
         

      float2 calcIntersection( in float3 ro , in float3 rd , in float3 centerP ){     
            
               
        float h =  _IntersectionPrecision * 2;
        float t = 0.0;
        float res = -1.0;
        float id = -1.0;
        
        [unroll(50)] for( int i=0; i< 50; i++ ){
            
            if( h < _IntersectionPrecision || t > _MaxTraceDistance ) break;
    
            float3 pos = ro + rd*t;
            float2 m = map( pos , centerP );
            
            h = m.x;
            t += h;
            id = m.y;
            
        }
    
    
        if( t <  _MaxTraceDistance ){ res = t; }
        if( t >  _MaxTraceDistance ){ id = -1.0; }
        
        return float2( res , id );
          
      
      }
            
    

      VertexOut vert(VertexIn v) {
        
        VertexOut o;

        o.normal = v.normal;
        
        o.uv = v.texcoord;
  
        // Getting the position for actual position
        o.pos = mul( UNITY_MATRIX_MVP , v.position );
     
        float3 mPos = mul( _Object2World , v.position );
        o.centerP = mul( _Object2World , float4( 0. , 0. , 0. , 1. ) ).xyz;

        o.ro = mPos;
        o.camPos = _WorldSpaceCameraPos; //float4( _WorldSpaceCameraPos  , 1. );mul( _World2Object , float4( _WorldSpaceCameraPos  , 1. )); 

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
    		float2 res = calcIntersection( ro , rd , i.centerP );
    		
    		col= float3( 0. , 0. , 0. );

    		if( res.y > -0.5 ){

    			float3 pos = ro + rd * res.x;
    			float3 norm = calcNormal( pos , i.centerP );
    			col = norm * .5 + .5;

          float3 fRefl = reflect( -rd , norm );
          float3 cubeCol = texCUBE(_CubeMap,fRefl ).rgb;
          //col *= cubeCol;

          float3 fPos= pos - i.centerP;


        float2 lookup = fPos.xz * .5 + float2( .5 , .5 );
        	if( res.y > 1. ){
            col *= abs(res.y - 1.5) * 2.0;
          }

          //if( res.y <= 1.0 ){ discard; }
    			//col = float3( 1. , 0. , 0. );
    			
    		}else{
    			//col = float3( 1. , 0. , 0.);
          discard;
        }
     
    		//col = float3( 1. , 1. , 1. );

            fixed4 color;
            color = fixed4( col , 1. );
            return color;
      }

      ENDCG
    }
  }
  FallBack "Diffuse"
}