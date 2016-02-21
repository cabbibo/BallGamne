float2 sdfSubtract( float2 shape1, float2 shape2 ){
  return -shape1.x > shape2.x ? float2( -shape1.x , shape1.y ) : shape2;
}