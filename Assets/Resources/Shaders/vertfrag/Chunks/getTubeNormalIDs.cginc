 uint4 getTubeNormalIDs( uint id  ){

  uint base = floor( id / 6 );
  uint tri  = id % 6;
  uint row = floor( base / _RibbonWidth );
  uint col = base % _RibbonWidth;

  // First figure out what vert it is in Triangle

  uint rDoID = row * _RibbonWidth;
  uint rUpID = (row + 1) * _RibbonWidth;
  uint cDoID = col;
  uint cUpID = col + 1;

  uint fID = 0;
  if( tri == 0 ){
    fID = rDoID + cDoID;
  }else if( tri == 1 ){
    fID = rUpID + cDoID;
  }else if( tri == 2 ){
    fID = rUpID + cUpID;
  }else if( tri == 3 ){
    fID = rDoID + cDoID;
  }else if( tri == 4 ){
    fID = rUpID + cUpID;
  }else if( tri == 5 ){
    fID = rDoID + cUpID;
  }else{
    fID = 0;
  }

  if( fID  >= _TotalVerts ){ fID  -= _TotalVerts; }

  base = fID;
  row = floor( base / _RibbonWidth );
  col = base % _RibbonWidth;

  uint l =  base - 1;
  uint r =  base + 1;

  // Looping Colums properly
  if( col == 0 ){ l += _RibbonWidth; }
  if( col == (_RibbonWidth-1) ){ r -= _RibbonWidth; }

  uint u = base + _RibbonWidth;
  uint d = base - _RibbonWidth;

  if( u >= _TotalVerts ){ u -= _TotalVerts; }
  if( d < 0 ){ d += _TotalVerts; }

  return uint4( l , r , u , d );

}