            uint3 getIDs( uint id ){

              //tells us which part of tri we are
              uint tri = id % 6;

              // tells us which quad we are in
              float quadID = floor( float(id) / 6 );

              uint ribbonID = uint(floor( (float(quadID)) / _QuadsPerRibbon));

              uint baseRibbonID = (ribbonID * _RibbonWidth * _RibbonLength );
              uint baseRibbonQuadID = (ribbonID * (_QuadsPerRibbon));

              uint quadIDInRibbon = (quadID) - baseRibbonQuadID;

              uint col = quadIDInRibbon % _RibbonWidth;
              uint row = floor(float(quadIDInRibbon) / _RibbonWidth);

              uint rDoID =  row * _RibbonWidth;
              uint rUpID =  (row + 1) * _RibbonWidth;
              uint cDoID =  col;
              uint cUpID =  col + 1;

              if( cUpID == _RibbonWidth ){ cUpID = 0; }

              uint fID = 0;
              uint tri1 = 0;
              uint tri2 = 0;

              if( tri == 0 ){
                fID  = rDoID + cDoID;
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
                fID  = rUpID + cUpID;
                tri1 = rDoID + cUpID;
                tri2 = rDoID + cDoID;
              }else if( tri == 5 ){
                fID  = rDoID + cUpID;
                tri1 = rDoID + cDoID;
                tri2 = rUpID + cUpID;
              }else{
                fID = -10;
                tri1 = -10;
                tri2 = -10;
              }

              return uint4( fID  + baseRibbonID , tri1 + baseRibbonID  , tri2 + baseRibbonID  );


            }