
float3 handForce( float3 p1 , float3 p2 , float d ){

  float3 dir = p1 - p2;
  float l = length( dir );
  dir = normalize( dir );

  float dif = 0.;
  if( l < d ){

    dif = (d-l)/ d;
  }

  return dif * -dir;

}

