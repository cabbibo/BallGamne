Shader "Custom/RoomShader" {



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
            StructuredBuffer<float4x4> transBuffer;

            uniform float4x4 worldMat;

            uniform float3 _HandL;
            uniform float3 _HandR;
            uniform int _RibbonWidth;
            uniform int _RibbonLength;
            uniform int _NumberRibbons;
            uniform int _QuadsPerRibbon;

            uniform int _TotalVerts;
            uniform sampler2D _NormalMap;
            uniform sampler2D _TextureMap;
            uniform sampler2D _BumpMap;
            uniform sampler2D _AudioMap;
            uniform samplerCUBE _CubeMap;
 
            //A simple input struct for our pixel shader step containing a position.
            struct varyings {
                float4 pos      : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 nor      : TEXCOORD0;
                float3 eye      : TEXCOORD2;
                float3 debug    : TEXCOORD3;
                float2 uv       : TEXCOORD4;
            };

            struct Lookup{
              uint main;
              uint left;
              uint right;
              uint up;
              uint down;
            };


           // #include "Chunks/getRibbonID.cginc"
            //#include "Chunks/getTubeNormalIDs.cginc"
            
            //#include "Chunks/getGridDiscard.cginc"
            #include "Chunks/semLookup.cginc"
            #include "Chunks/uvNormalMap.cginc"

            //#include "Assets/Shaders/Chunks/Resources/uvNormalMap.cginc"

           
            uint convertToID( uint row , uint col , uint baseRibbonID ){

              uint id;
  
              id = row * _RibbonWidth + col;

              id += baseRibbonID;

              if( row == -1 || row == _RibbonLength || col == -1 || col == _RibbonWidth ){
                id = -10;
              }

              return id;

            }

            Lookup getIDs( uint id ){

              //tells us which part of tri we are
              uint tri = id % 6;

              // tells us which quad we are in
              float quadID = floor( float(id) / 6 );

              uint ribbonID = uint(floor( (float(quadID)) / _QuadsPerRibbon));

              uint baseRibbonID = (ribbonID * _RibbonWidth * _RibbonLength );
              uint baseRibbonQuadID = (ribbonID * (_QuadsPerRibbon));

              uint quadIDInRibbon = (quadID) - baseRibbonQuadID;

              uint col = quadIDInRibbon % (_RibbonWidth-1);
              uint row = floor(float(quadIDInRibbon) / (_RibbonWidth-1));

              uint rDoID =  row * (_RibbonWidth-1);
              uint rUpID =  (row + 1) * (_RibbonWidth-1);
              uint cDoID =  col;
              uint cUpID =  col + 1;

              //if( cUpID == _RibbonWidth ){ cUpID = 0; }

              uint fRow=row;
              uint fCol=col;

              if( tri == 0 ){

              }else if( tri == 1 ){
                fRow ++;
              }else if( tri == 2 ){
                fRow ++;
                fCol ++;
              }else if( tri == 3 ){
              }else if( tri == 4 ){
                fRow ++;
                fCol ++;
              }else if( tri == 5 ){
                fCol ++;
              }else{ }

              Lookup l;
              l.main  = convertToID( fRow   , fCol   , baseRibbonID );
              l.left  = convertToID( fRow   , fCol-1 , baseRibbonID );
              l.right = convertToID( fRow   , fCol+1 , baseRibbonID );
              l.up    = convertToID( fRow+1 , fCol   , baseRibbonID );
              l.down  = convertToID( fRow-1 , fCol   , baseRibbonID );


              return l;

            }




            //Our vertex function simply fetches a point from the buffer corresponding to the vertex index
            //which we transform with the view-projection matrix before passing to the pixel program.
            varyings vert (uint id : SV_VertexID){

                varyings o;

                Lookup ids = getIDs( id );
                Vert v = buf_Points[ids.main];
                Pos og = og_Points[ids.main];

                float3 dif = mul( worldMat , float4( og.pos , 1.) ).xyz;
                dif -= v.pos;
                o.debug = dif;



                Vert l; 
                Vert r;
                Vert u;
                Vert d;

                if( ids.up != -10 ){
                  u = buf_Points[ids.up];
                }else{
                  u = buf_Points[ids.main];
                }

                if( ids.down != -10 ){
                  d = buf_Points[ids.down];
                }else{
                  d = buf_Points[ids.main];
                }

                if( ids.left != -10 ){
                  l = buf_Points[ids.left];
                }else{
                  l = buf_Points[ids.main];
                }

                if( ids.right != -10 ){
                  r = buf_Points[ids.right];
                }else{
                  r = buf_Points[ids.main];
                }

                float3 lr = l.pos - r.pos;
                float3 ud = u.pos - d.pos;


               // if( ids.down == -10 ){ ud = float3( 1 , 1 , 1 );}
                ud = normalize( ud );
                lr = normalize( lr );

                float3 nor = normalize(cross( lr , ud ));

                //float3 l = buf_Points[ids.x].pos;
                //float3 r = buf_Points[ids.y].pos;
                //float3 u = buf_Points[ids.z].pos;
                //float3 d = buf_Points[ids.w].pos;
//
                //float3 nor = -normalize( cross( normalize(l - r) , normalize( u - d ) ));


                o.worldPos = v.pos;

                o.pos = mul (UNITY_MATRIX_VP, float4(o.worldPos,1.0f));

                //o.debug = normalize( dif ) * nor;//o.worldPos - og.pos;

                o.eye = _WorldSpaceCameraPos - o.worldPos;
                o.uv = v.uv;

                //tells us which part of tri we are
              //uint tri = id % 6;

              // tells us which quad we are in
              //uint baseID = floor( id / 6 );

              //uint ribbonID = uint(floor( float(baseID) / float(_QuadsPerRibbon)));
             // uint baseRibbonID = (ribbonID * _QuadsPerRibbon);
                //o.debug = dif;//v.debug;

                o.nor = nor; //nor;// * .5 + .5;//float3(float(fID)/32768., v.uv.x , v.uv.y);
                return o;
            }
 
            //Pixel function returns a solid color for each point.
            float4 frag (varyings i) : COLOR {


                float3 fNorm = uvNormalMap( _NormalMap , i.pos ,  i.uv  * float2( 1. , .2), i.nor , 10.1 ,.5);


                float3 fRefl = reflect( -i.eye , fNorm );
                float3 cubeCol = texCUBE(_CubeMap,fRefl ).rgb;

                float3 fCol = cubeCol + (i.nor * .5 + .5);
                //fCol *= cubeCol;
         				 
                float disp = 4 * length( i.debug );
         				fCol *= disp;// float3( disp , disp , disp ); 
                return float4( fCol , 1.);
            }
 
            ENDCG
 
        }
    }
 
    Fallback Off
	
}
