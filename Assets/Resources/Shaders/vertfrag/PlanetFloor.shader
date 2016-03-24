Shader "Custom/PlanetFloor" {
 Properties {
  

    _NumberSteps( "Number Steps", Int ) = 20
    _MaxTraceDistance( "Max Trace Distance" , Float ) = 10.0
    _IntersectionPrecision( "Intersection Precision" , Float ) = 0.0001

    _NoiseTexture( "NoiseTexture" , 2D ) = "white" {}
  

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
      //#pragma target 5.0

      #include "UnityCG.cginc"
      #include "Chunks/noise.cginc"
      
 
      


      uniform int _NumberSteps;
      uniform float  _IntersectionPrecision;
      uniform float _MaxTraceDistance;
      uniform sampler2D _NoiseTexture;
      uniform float3 _Hand1;
      uniform float3 _Hand2;
      uniform float3 _Size;
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
      float2 map( in float3 pos ){
        
        float2 res;
        float2 lineF;
        float2 sphere;

        //res = float2( 10000000. , -1. );
        res = float2( -sdBox( pos + float3( 0. , 0  , 0 ) , float3( .5 , 2, .5)  ) , 0.6 );

        float n = noise( pos * 10. + float3(0 ,_Time.x* 20.0, 0 ) );
         //    = float2( n - .8 , 1.);
        res.x += n * .3f * pos.y;
        float2 res2 = float2( sdBox( pos - float3( 0 , 0.35 , 0) , float3( .3 , .1 , .3 )), 0.6 );
        //res2.x += n * .1f;
        res = smoothU( res , res2 , 0.2 );

        //float2 res2 = float2( sdBox( modit(pos , modVal) - modVal / 2. , float3(.1 , 1. , .1 ) ) , 0.6 );
        //float2 res2 = float2( sdBox( modit(pos , modVal) - modVal / 2. , float3(1. , .1 , .1 ) ) , 0.6 );
        //float2 res2 = float2( sdBox( modit(pos , modVal) - modVal / 2. , float3(.1 , .1 , 1. ) ) , 0.6 );
        //float3 startPos = modit(pos , modVal) - modVal / 2.;
        //float2 res2 = float2( sdBox( pos - float3( 0 , -1 , 0) , float3( 2000 ,.1 , 2000 )), 0.6 );
        //res = smoothU( res , res2 , 0.02 );
        ////res = smoothU( res , res2 , 0.02 );
//
        //float n = noise( pos * 10. + float3(0 ,_Time.x* 20.0, 0 ) );
         //    = float2( n - .8 , 1.);
        //res.x += n * .3f;
        //res = float2( length( pos - float3( 0., -.8 ,0) ) - 1., 0.1 );
        //res = smoothU( res , float2( length( pos - float3( .3 , .2 , -.2) ) - .1, 0.1 ) , .05 );
        //res = smoothU( res , float2( length( pos - float3( -.4 , .2 , .4) ) - .1, 0.1 ) , .05 );
        //res = smoothU( res , float2( length( pos - float3( 0.3 , .2 , -.3) ) - .1, 0.1 ) , .05 );

        return res; 
     
      }

      float3 calcNormal( in float3 pos ){

        float3 eps = float3( 0.001, 0.0, 0.0 );
        float3 nor = float3(
            map(pos+eps.xyy).x - map(pos-eps.xyy).x,
            map(pos+eps.yxy).x - map(pos-eps.yxy).x,
            map(pos+eps.yyx).x - map(pos-eps.yyx).x );
        return normalize(nor);

      }
              
         

      float2 calcIntersection( in float3 ro , in float3 rd ){     
            
               
        float h =  _IntersectionPrecision * 2;
        float t = 0.0;
        float res = -1.0;
        float id = -1.0;
        
        for( int i=0; i< _NumberSteps; i++ ){
            
            if( h < _IntersectionPrecision || t > _MaxTraceDistance ) break;
    
            float3 pos = ro + rd*t;
            float2 m = map( pos );
            
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

        o.ro = v.position;
        o.camPos = mul( _World2Object , float4( _WorldSpaceCameraPos  , 1. )); 

        return o;

      }


     // Fragment Shader
      fixed4 frag(VertexOut i) : COLOR {
        if( i.normal.y < .9 ){discard;return fixed4( 1. , 1. , 1. , 1. );
        }else{
        float3 ro = i.ro;
        float3 rd = normalize(ro - i.camPos);

        float3 col = float3( 0.0 , 0.0 , 0.0 );
        float2 res = calcIntersection( ro , rd );
        
        col= float3( 0. , 0. , 0. );

        float alpha = tex2D( _NoiseTexture , i.uv ).x;
        if( alpha < pow( abs( i.uv.y - .5 ) , 4.)* 10.0 ){ discard; }
        if( alpha < pow( abs( i.uv.x - .5 ) , 4.)* 10.0 ){ discard; }

        if( res.y > -0.5 ){

          float3 pos = ro + rd * res.x;
          float3 norm = calcNormal( pos );
          col = norm * .5 + .5;
          //col *= 1. / (1. + 20. * pow( (res.x / _MaxTraceDistance) , 2. ));
          //col = float3( 1. , 0. , 0. );
          
        }

        //if(abs(.5 - i.uv.y) > .4){ col = float3( 1. , 1., 1.);}
     
        //col = float3( 1. , 1. , 1. );

        float m = col.x * col.y * col.z + .3;// length( col );
        col = lerp( col , float3( m  , m , m) , _Learning );

        fixed4 color;
        color = fixed4( col , 1. );
        return color;
      }
      }

      ENDCG
    }
  }
  FallBack "Diffuse"
}