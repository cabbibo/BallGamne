float3 getGridDiscard( float2 uv , float3 col ){

              float xVal = sin( uv.x * 100. );
              float yVal = sin( uv.y * 300. );


               if( xVal < .8 ){ 
                 
                 if( yVal < .8 ){ 
                  // cubeCol = float3( 0. , 0. , 0.);
                  // discard;
                 }else{
                   discard;
                   col = col * min((yVal - .8 ) * 5. , 1.);
                 }


               }else{
                 discard;
                   col = col * min((xVal - .8 ) * 5. , 1.);
               }

               return col;

            }
