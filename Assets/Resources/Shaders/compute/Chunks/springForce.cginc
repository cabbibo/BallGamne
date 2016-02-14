float3 springForce( float3 p1 , float3 p2 , float d ){

  float3 dir = p1 - p2;
  float l = length( dir );
  dir = normalize( dir );

  float dif = l - d;

  return dif * dif * float(sign(dif)) * -dir;

}