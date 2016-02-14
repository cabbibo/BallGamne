 uint3 getID( uint id  ){

  uint base = floor( id / 6 );
  uint tri  = id % 6;
  uint row = floor( base / _RibbonWidth );
  uint col = base % _RibbonWidth;

  uint rDoID = row * _RibbonWidth;
  uint rUpID = (row + 1) * _RibbonWidth;
  uint cDoID = col;
  uint cUpID = col + 1;

  uint fID = 0;
  uint tri1 = 0;
  uint tri2 = 0;


  if( tri == 0 ){
    fID = rDoID + cDoID;
        tri1 = rUpID + cDoID;
        tri2 = rUpID + cUpID;
  }else if( tri == 1 ){
    fID = rUpID + cDoID;
        tri1 = rUpID + cUpID;
        tri2 = rDoID + cDoID;
  }else if( tri == 2 ){
    fID = rUpID + cUpID;
        tri1 = rDoID + cDoID;
        tri2 = rUpID + cDoID;
  }else if( tri == 3 ){
    fID = rDoID + cDoID;
        tri1 = rUpID + cUpID;
        tri2 = rDoID + cUpID;
  }else if( tri == 4 ){
    fID = rUpID + cUpID;
        tri1 = rDoID + cUpID;
        tri2 = rDoID + cDoID;
  }else if( tri == 5 ){
    fID = rDoID + cUpID;
        tri1 = rDoID + cDoID;
        tri2 = rUpID + cUpID;
  }else{
    fID = 0;
  }


    if( fID  >= _TotalVerts ){ fID  -= _TotalVerts; }
    if( tri1 >= _TotalVerts ){ tri1 -= _TotalVerts; }
    if( tri2 >= _TotalVerts ){ tri2 -= _TotalVerts; }
    return uint3( fID , tri1 , tri2 );

}