
class Vertex {
  float x, y, z;
  float nx, ny, nz;
  boolean selected;
  boolean hasNormal;
  
  Vertex(float inX, float inY, float inZ) {
    x = inX; y = inY; z = inZ;
    selected = false;
    hasNormal = false;
  }
  
  void setNormal(float inNx, float inNy, float inNz) {
    hasNormal = true;
    nx = inNx;
    ny = inNy;
    nz = inNz;
  }
}

class Face {
  Vertex v1, v2, v3;
  boolean selected;
  
  Face(Vertex inV1, Vertex inV2, Vertex inV3) {
    v1 = inV1; v2 = inV2; v3 = inV3;
    selected = false;
  }
}
