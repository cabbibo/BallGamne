Shader "Custom/RoomParticles" {



    SubShader{
//        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        Cull off
        Pass{

            Blend SrcAlpha OneMinusSrcAlpha // Alpha blending
 
            CGPROGRAM
            #pragma target 5.0
 
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
 

            #include "Chunks/VertStruct.cginc"

            struct Pos {
                float3 pos;
            };

            StructuredBuffer<Vert> buf_Points;
            StructuredBuffer<Pos> og_Points;

 
            //A simple input struct for our pixel shader step containing a position.
            struct varyings {
                float4 pos      : SV_POSITION;
                float size : PSIZE;
                float3 debug : TEXCOORD0;
            };

 
            //Our vertex function simply fetches a point from the buffer corresponding to the vertex index
            //which we transform with the view-projection matrix before passing to the pixel program.
            varyings vert (uint id : SV_VertexID){

                varyings o;

                Vert v = buf_Points[(id/3)];

                float3 a1 = float3( 1. , 0. , 0 );
                float3 a2 = float3( -1 , 0 , 0 );
                float3 a3 = float3( .5 , 1 , 0 );

                float3 fPos;
                float vSize = .01;
                if( id % 3 == 0 ){
                  fPos = v.pos + a1 * vSize;
                }else if( id % 3 == 1 ){
                  fPos = v.pos + a2 * vSize;
                }else if( id % 3 == 2 ){
                  fPos = v.pos + a3 * vSize;
                }
                o.pos = mul (UNITY_MATRIX_VP, float4(fPos,1.0f));
                o.size = 10;
                o.debug = v.debug;
                return o;
            }
 
            //Pixel function returns a solid color for each point.
            float4 frag (varyings i) : COLOR {

                float3 col = i.debug;
                return float4( col , 1.);//.1 * float4(1,0.5f,0.0f,1.0) / ( i.dToPoint * i.dToPoint  * i.dToPoint );
            }
 
            ENDCG
 
        }
    }
 
    Fallback Off
	
}
