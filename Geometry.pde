
class Vertex {
  float x, y, z;
  float nx, ny, nz;
  float tx, ty;
  boolean selected;
  boolean hasNormal;
  boolean hasTexture;
  
  Vertex(float inX, float inY, float inZ) {
    x = inX; y = inY; z = inZ;
    selected = false;
    hasNormal = false;
    hasTexture = false;
  }
  
  void setNormal(float inNx, float inNy, float inNz) {
    hasNormal = true;
    nx = inNx;
    ny = inNy;
    nz = inNz;
  }
  void setTexture(float inTx, float inTy) {
    hasTexture = true;
    tx = inTx;
    ty = inTy;
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

Vertex makeVertex(float x, float y, float z) {
  Vertex result = new Vertex(x, y, z);
  vertices.add(result);
  return result;
}

void makeCube() {
  Vertex v1 = makeVertex(-1.0, -1.0, -1.0);
  Vertex v2 = makeVertex(-1.0, -1.0, 1.0);
  Vertex v3 = makeVertex(-1.0, 1.0, -1.0);
  Vertex v4 = makeVertex(-1.0, 1.0, 1.0);
  Vertex v5 = makeVertex(1.0, -1.0, -1.0);
  Vertex v6 = makeVertex(1.0, -1.0, 1.0);
  Vertex v7 = makeVertex(1.0, 1.0, -1.0);
  Vertex v8 = makeVertex(1.0, 1.0, 1.0);
  
  faces.add(new Face(v1, v2, v3));  
  faces.add(new Face(v2, v4, v3));
  faces.add(new Face(v1, v5, v6));
  faces.add(new Face(v1, v6, v2));
  faces.add(new Face(v3, v7, v8));
  faces.add(new Face(v3, v8, v4));
  faces.add(new Face(v5, v7, v6));
  faces.add(new Face(v6, v7, v8));
  faces.add(new Face(v2, v4, v6));
  faces.add(new Face(v4, v6, v8));
  faces.add(new Face(v1, v3, v5));
  faces.add(new Face(v3, v5, v7));
}

static final int NUM_AROUND = 15;
static final int NUM_UP = 50;

void makeSphere() {
  Vertex b = makeVertex(-1.0, 0.0, 0.0);
  ArrayList<Vertex> shelf = new ArrayList<Vertex>();
  for(int i = 0; i < NUM_AROUND; ++i) {
    float h = -1.0 + (2.0 / NUM_UP);
    float d = sqrt(1.0 - h * h);
    shelf.add(makeVertex(-1.0 + (2.0 / NUM_UP), d * cos(i * 2.0 * PI / NUM_AROUND), d * sin(i * 2.0 * PI / NUM_AROUND)));
    if(i != 0) {
      faces.add(new Face(b, shelf.get(i - 1), shelf.get(i)));
    }
  }
  faces.add(new Face(b, shelf.get(NUM_AROUND - 1), shelf.get(0)));
  
  ArrayList<Vertex> oldShelf = shelf;
  shelf = new ArrayList<Vertex>();
  for(int j = 0; j < NUM_UP - 2; ++j) {
    float h = -1.0 + (j + 1) * (2.0 / NUM_UP);
    float d = sqrt(1.0 - h * h);
    for(int i = 0; i < NUM_AROUND; ++i) {
        shelf.add(makeVertex(-1.0 + (j + 1) * (2.0 / NUM_UP), d * cos(i * 2.0 * PI / NUM_AROUND), d * sin(i * 2.0 * PI / NUM_AROUND)));
    }
    for(int i = 0; i < NUM_AROUND - 1; ++i) {
      faces.add(new Face(oldShelf.get(i), shelf.get(i), oldShelf.get(i + 1)));
      faces.add(new Face(oldShelf.get(i + 1), shelf.get(i + 1), shelf.get(i)));
    }
    faces.add(new Face(oldShelf.get(NUM_AROUND - 1), oldShelf.get(0), shelf.get(NUM_AROUND - 1)));
    faces.add(new Face(oldShelf.get(0), shelf.get(0), shelf.get(NUM_AROUND - 1)));    
    oldShelf = shelf;
    shelf = new ArrayList<Vertex>();
  }
  Vertex t = makeVertex(1.0, 0.0, 0.0);
  for(int i = 0; i < NUM_AROUND; ++i) {
    if(i != 0) {
      faces.add(new Face(t, oldShelf.get(i - 1), oldShelf.get(i)));
    }
  }
  faces.add(new Face(t, oldShelf.get(NUM_AROUND - 1), oldShelf.get(0)));
  
  return;  
}
