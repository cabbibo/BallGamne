float2 semLookup( float3 e , float3 n ){
  
              float3 r = reflect( e, n );
              float m = 2. * sqrt( 
                  pow( r.x, 2. ) + 
                  pow( r.y, 2. ) + 
                  pow( r.z + 1., 2. ) 
              );

              return ( r.xy / m + .5 );

            }
