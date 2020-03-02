class Window {
  int viewType;
  int x, y, w, h;
  boolean mouseInWindow;
  float mX, mY;
  boolean selecting;
  
  float selectMouseStartX, selectMouseStartY;
  float selectMouseEndX, selectMouseEndY;
  
  Matrix4f modelViewMatrix;
  
  PGraphics g;
  Camera c;
  
  Window(int xIn, int yIn, int wIn, int hIn, int viewTypeIn) {
    viewType = viewTypeIn;
    x = xIn; y = yIn; w = wIn; h = hIn;
    modelViewMatrix = new Matrix4f();
    
    if(viewType != VIEW_3D) {
      modelViewMatrix = modelViewMatrix.scale(VIEW_SCALE, VIEW_SCALE, VIEW_SCALE);
    } else {
      modelViewMatrix.setLookAt(0.0, 0.0, 10.0,
        0.0, 0.0, 0.0, 
        0.0, -1.0, 0.0);
    }
    selecting = false;
    
    g = createGraphics(w, h, P3D);
    if(viewType == VIEW_3D) {
      c = new Camera(this);
    }
  }
  
  void resize(int xIn, int yIn, int wIn, int hIn) {    
    x = xIn; y = yIn; w = wIn; h = hIn;
    g.dispose();
    g = createGraphics(w, h, P3D);
  }
    
  boolean processMousePosition() {
    mouseInWindow = ((mouseX >= x) && ((mouseX - x) < w) && (mouseY >= y) && ((mouseY - y) < h));
    mX = mouseX - x - (w / 2);
    mY = mouseY - y - (h / 2);
    
    return mouseInWindow;
  }
 
  
  void mouseWheel(MouseEvent event) {
    if(!processMousePosition())
      return;
    float e = event.getCount();
    float s = (e > 0.0) ? SCROLL_MULTIPLIER : (1.0f / SCROLL_MULTIPLIER);
    if(viewType == VIEW_3D) {
      c.moveForward((e == 0.0) ? 0.0 : (e > 0.0 ? 1.0 : -1.0));
    } else {
      if (e != 0.0) {
        modelViewMatrix = modelViewMatrix.scale(s, s, s);
      }
    }
  }
  
  // Function to get the position of the viewpoint in the current coordinate system
  Vector3f getEyePosition() {
    PMatrix3D mat = (PMatrix3D)g.getMatrix(); //Get the model view matrix
    mat.invert();
    return new Vector3f( mat.m03, mat.m13, mat.m23 );
  }
  
  
  Vector3f unProject(float winX, float winY) {
    float x = winX / (w / 2);
    float y = -(winY / (h / 2));
    float z = 1.0f;
    Vector3f ray_nds = new Vector3f(x, y, z);
    
    PMatrix3D projection = new PMatrix3D(((PGraphics3D)g).projection); 
    PMatrix3D modelview = new PMatrix3D(((PGraphics3D)g).modelview); 
    PMatrix3D mvp = new PMatrix3D();
    mvp.apply(projection);
    mvp.apply(modelview);
    projection.invert();
    modelview.invert();
    float[] in = {ray_nds.x, ray_nds.y, -1.0, 1.0f};
    float[] out = new float[4];
    projection.mult(in, out);
    Vector4f ray_eye = new Vector4f(out[0], out[1], -1.0, 0.0);
    float[] in2 = { ray_eye.x, ray_eye.y, ray_eye.z, ray_eye.w };
    modelview.mult(in2, out);
    Vector3f ray_wor = new Vector3f(out[0], out[1], out[2]);
    ray_wor.normalize();
    return ray_wor;
    
  }
  
  //Returns true if this point - which is presumed to be in the plane of Face f - is inside that
  //Face.
  boolean triangleContainsPointInPlane(Face f, Vector3f q, Vector3f n) {    
    Vector3f e1 = new Vector3f(f.v2.v.x  - f.v1.v.x, f.v2.v.y - f.v1.v.y, f.v2.v.z - f.v1.v.z);
    Vector3f e2 = new Vector3f(f.v3.v.x  - f.v2.v.x, f.v3.v.y - f.v2.v.y, f.v3.v.z - f.v2.v.z);
    Vector3f e3 = new Vector3f(f.v1.v.x  - f.v3.v.x, f.v1.v.y - f.v3.v.y, f.v1.v.z - f.v3.v.z);
    
    Vector3f c0 = new Vector3f(q.x - f.v1.v.x, q.y - f.v1.v.y, q.z - f.v1.v.z);
    Vector3f c1 = new Vector3f(q.x - f.v2.v.x, q.y - f.v2.v.y, q.z - f.v2.v.z);
    Vector3f c2 = new Vector3f(q.x - f.v3.v.x, q.y - f.v3.v.y, q.z - f.v3.v.z);
    Vector3f cp0 = new Vector3f();
    Vector3f cp1 = new Vector3f();
    Vector3f cp2 = new Vector3f();
    e1.cross(c0, cp0);  //cp0 = e1 x c0
    e2.cross(c1, cp1);  //cp1 = e2 x c1
    e3.cross(c2, cp2);  //cp2 = e3 x c2
    
    float dp0 = n.dot(cp0);
    float dp1 = n.dot(cp1);
    float dp2 = n.dot(cp2);
    return (((dp0 > 0) && (dp1 > 0) && (dp2 > 0)) ||
            ((dp0 < 0) && (dp1 < 0) && (dp2 < 0)));
  }
  
  boolean rayIntersectsTriangle(Face f, Vector3f ray, Vector3f eye, Vector3f n) {
    float t = ((f.v1.v.x * n.x + f.v1.v.y * n.y + f.v1.v.z * n.z) -
               (eye.x * n.x + eye.y * n.y + eye.z * n.z)) /
               (ray.x * n.x + ray.y * n.y + ray.z * n.z);
    Vector3f q = new Vector3f(eye.x + ray.x * t, eye.y + ray.y * t, eye.z + ray.z * t);
    
    return triangleContainsPointInPlane(f, q, n);
  }  
  
  boolean rayIntersects(Face f) {
    Vector3f e1 = new Vector3f(f.v2.v.x  - f.v1.v.x, f.v2.v.y - f.v1.v.y, f.v2.v.z - f.v1.v.z);
    Vector3f e2 = new Vector3f(f.v3.v.x  - f.v2.v.x, f.v3.v.y - f.v2.v.y, f.v3.v.z - f.v2.v.z);
    
    Vector3f n = new Vector3f(e1.y * e2.z - e1.z * e2.y,
                              e1.z * e2.x - e1.x * e2.z,
                              e1.y * e2.x - e1.x * e2.y);
    n.normalize();
          
    Vector3f eye = getEyePosition();
    switch(viewType) {
        case VIEW_X:   
        {
          Vector3f ray = new Vector3f(1.0f, 0.0f, 0.0f);
          Vector3f mousePos = new Vector3f(0.0f, -mY, mX);
          mousePos = modelViewMatrix.transformPosition(mousePos);
          eye.y = mousePos.y;
          eye.z = mousePos.z;
          return rayIntersectsTriangle(f, ray, eye, n);
        }
        case VIEW_Y:
        {
          Vector3f ray = new Vector3f(0.0f, 1.0f, 0.0f);
          Vector3f mousePos = new Vector3f(mX, 0.0f, -mY);
          mousePos = modelViewMatrix.transformPosition(mousePos);
          eye.x = mousePos.x;
          eye.z = mousePos.z;
          return rayIntersectsTriangle(f, ray, eye, n);
        }
        case VIEW_Z:
        {
          Vector3f ray = new Vector3f(0.0f, 0.0f, 1.0f);
          Vector3f mousePos = new Vector3f(-mX, -mY, 0.0f);
          mousePos = modelViewMatrix.transformPosition(mousePos);
          eye.x = mousePos.x;
          eye.y = mousePos.y;
          return rayIntersectsTriangle(f, ray, eye, n);
        }
        case VIEW_3D:
        {         
          Vector3f pointOnScreen = unProject(selectMouseStartX, selectMouseStartY);          
          Vector3f ray = new Vector3f(pointOnScreen.x, pointOnScreen.y, pointOnScreen.z);
          ray.normalize();
          return rayIntersectsTriangle(f, ray, eye, n);
        }
      }
      return false;
  }
  
  void mouseClicked() {
    if(!processMousePosition())
      return;
    if(mode == MODE_SELECT_FACE) {
      if(viewType == VIEW_3D) {
        g.perspective(PI/3.0, ((float)w) / h, .0001, 100000.0);
        g.resetMatrix();
        g.applyMatrix(modelViewMatrix.m00(), modelViewMatrix.m10(), modelViewMatrix.m20(), modelViewMatrix.m30(),
          modelViewMatrix.m01(), modelViewMatrix.m11(), modelViewMatrix.m21(), modelViewMatrix.m31(),
          modelViewMatrix.m02(), modelViewMatrix.m12(), modelViewMatrix.m22(), modelViewMatrix.m32(),
          modelViewMatrix.m03(), modelViewMatrix.m13(), modelViewMatrix.m23(), modelViewMatrix.m33());        
      }
      for(int i = faces.size() - 1; i >= 0; i--) {
        Face f = faces.get(i);
        if(rayIntersects(f) ||
           ((keyPressed && keyCode == SHIFT) && f.selected))
        {
          if(keyPressed && keyCode == CONTROL) {
            f.selected = false;
          } else {
            f.selected = true;
          }
        } else {
          if(!(keyPressed && keyCode == CONTROL)) {
            f.selected = false;
          }
        }
      }
      updateSelected();
    } else if(mode == MODE_SELECT_VERTEX) {
      selectMouseStartX -= 3;
      selectMouseStartY -= 3;
      selectMouseEndX += 3;
      selectMouseEndY += 3;
      if(viewType == VIEW_3D) {
        
      g.perspective(PI/3.0, ((float)w) / h, .0001, 100000.0);
      g.resetMatrix();
      g.applyMatrix(modelViewMatrix.m00(), modelViewMatrix.m10(), modelViewMatrix.m20(), modelViewMatrix.m30(),
        modelViewMatrix.m01(), modelViewMatrix.m11(), modelViewMatrix.m21(), modelViewMatrix.m31(),
        modelViewMatrix.m02(), modelViewMatrix.m12(), modelViewMatrix.m22(), modelViewMatrix.m32(),
        modelViewMatrix.m03(), modelViewMatrix.m13(), modelViewMatrix.m23(), modelViewMatrix.m33());        
      }
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        if(selectHelper(v) ||
           ((keyPressed && keyCode == SHIFT) && v.selected))
        {
          if(keyPressed && keyCode == CONTROL) {
            v.selected = false;
          } else {
            v.selected = true;
          }
        } else {
          if(!(keyPressed && keyCode == CONTROL)) {
            v.selected = false;
          }
        }
      }
      updateSelected();
    } else if(mode == MODE_PLACE) { 
      switch(viewType) {
        case VIEW_X:   
        {
          Vector3f mousePos = new Vector3f(0.0f, -mY, mX);
          mousePos = modelViewMatrix.transformPosition(mousePos);
          if(snapToGridCheckbox.selected) {
            mousePos.y = round(mousePos.y / STARTING_SCALE) * STARTING_SCALE;
            mousePos.z = round(mousePos.z / STARTING_SCALE) * STARTING_SCALE;
          }
          vertices.add(new Vertex(0.0, mousePos.y, mousePos.z));
        }
        break;
        case VIEW_Y:
        {
          Vector3f mousePos = new Vector3f(mX, 0.0f, -mY);
          mousePos = modelViewMatrix.transformPosition(mousePos);
          if(snapToGridCheckbox.selected) {
            mousePos.x = round(mousePos.x / STARTING_SCALE) * STARTING_SCALE;
            mousePos.z = round(mousePos.z / STARTING_SCALE) * STARTING_SCALE;
          }
          vertices.add(new Vertex(mousePos.x, 0.0, mousePos.z));
        }
        break;
        case VIEW_Z:
        {
          Vector3f mousePos = new Vector3f(-mX, -mY, 0.0f);
          mousePos = modelViewMatrix.transformPosition(mousePos);
          if(snapToGridCheckbox.selected) {
            mousePos.x = round(mousePos.x / STARTING_SCALE) * STARTING_SCALE;
            mousePos.y = round(mousePos.y / STARTING_SCALE) * STARTING_SCALE;
          }
          vertices.add(new Vertex(mousePos.x, mousePos.y, 0.0));
        }
        break;
        case VIEW_3D:
        break;
      }
    }
  }
  
  void mousePressed() {
    if(!processMousePosition())
      return;
    if(mouseButton == LEFT) {
      if(mode == MODE_SELECT_VERTEX || mode == MODE_SELECT_FACE) {
        selecting = true;
      } else if (mode == MODE_MOVE) {
      }
    } 
    selectMouseStartX = mX;
    selectMouseStartY = mY;
    selectMouseEndX = mX;
    selectMouseEndY = mY;
  }

  float getScaleFactor(float start, float end) {
    float diff = end - start;
    float baseScale = 1.0;
    if(diff > 0.0) {
      baseScale = pow(GEOM_SCALING_FACTOR, diff);
    } else if (diff < 0.0) {
      baseScale = (1.0f / pow(GEOM_SCALING_FACTOR, -diff));
    } 
    return baseScale;
  }
  
  void mouseDragged() {
    if(!processMousePosition())
      return;
    selectMouseEndX = mX;
    selectMouseEndY = mY;
    Vector3f scale = new Vector3f();
    modelViewMatrix.getScale(scale);
    
    float gridOffsetX = 0.0;
    float gridOffsetY = 0.0;
    if(viewType == VIEW_3D) {
      c.mouseDragged();
    }
    if(keyPressed && key == ' ') {
      switch(viewType) {
        case VIEW_X:
          modelViewMatrix = modelViewMatrix.translate(0.0f,
            (selectMouseEndY - selectMouseStartY),            
            -(selectMouseEndX - selectMouseStartX)); 
          break;
        case VIEW_Y:
          modelViewMatrix = modelViewMatrix.translate(-(selectMouseEndX - selectMouseStartX),
            0.0,
            (selectMouseEndY - selectMouseStartY));        
          break;
        case VIEW_Z:
          modelViewMatrix = modelViewMatrix.translate((selectMouseEndX - selectMouseStartX),
            (selectMouseEndY - selectMouseStartY),
            0.0);
          break;
        case VIEW_3D:
          c.pan((selectMouseEndX - selectMouseStartX),
            -(selectMouseEndY - selectMouseStartY));
          break;
      }
      selectMouseStartX = selectMouseEndX;
      selectMouseStartY = selectMouseEndY;
      selecting = false;
    } else if(mode == MODE_MOVE) {
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        if(v.selected) {
          switch(viewType) {
            case VIEW_X:
            { 
              v.z += (selectMouseEndX - selectMouseStartX) * scale.z;
              v.y -= (selectMouseEndY - selectMouseStartY) * scale.z;
              if(snapToGridCheckbox.selected) {
                float vGY = round(v.y / STARTING_SCALE) * STARTING_SCALE;
                float vGZ = round(v.z / STARTING_SCALE) * STARTING_SCALE;
                gridOffsetX = (v.z - vGZ);
                gridOffsetY = -(v.y - vGY);
                v.y = vGY;
                v.z = vGZ;
              }
            }
            break;
            case VIEW_Y:
            { 
              v.x += (selectMouseEndX - selectMouseStartX) * scale.z;
              v.z -= (selectMouseEndY - selectMouseStartY) * scale.z;
              if(snapToGridCheckbox.selected) {
                float vGX = round(v.x / STARTING_SCALE) * STARTING_SCALE;
                float vGZ = round(v.z / STARTING_SCALE) * STARTING_SCALE;
                gridOffsetX = (v.x - vGX);
                gridOffsetY = -(v.z - vGZ);
                v.x = vGX;
                v.z = vGZ;
              }
            }
            break;
            case VIEW_Z:
            { 
              v.x -= (selectMouseEndX - selectMouseStartX) * scale.z;
              v.y -= (selectMouseEndY - selectMouseStartY) * scale.z;
              if(snapToGridCheckbox.selected) {
                float vGX = round(v.x / STARTING_SCALE) * STARTING_SCALE;
                float vGY = round(v.y / STARTING_SCALE) * STARTING_SCALE;
                gridOffsetX = -(v.x - vGX);
                gridOffsetY = -(v.y - vGY);
                v.x = vGX;
                v.y = vGY;
              }
            }
            break;
            case VIEW_3D:
            break;
          }
        }
      }
      updateSelected();
      selectMouseStartX = selectMouseEndX - (gridOffsetX / scale.z);
      selectMouseStartY = selectMouseEndY - (gridOffsetY / scale.z);
    } else if(mode == MODE_SCALE) {
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        if(v.selected) {
          switch(viewType) {
            case VIEW_X:
            { 
              float baseScaleZ = getScaleFactor(selectMouseStartX, selectMouseEndX);
              float baseScaleY = getScaleFactor(selectMouseEndY, selectMouseStartY);
              if(ctrlPressed) {
                if(abs(selectMouseStartX - selectMouseEndX) > abs(selectMouseStartY - selectMouseEndY)) {
                  baseScaleY = 1.0;
                } else {
                  baseScaleZ = 1.0;
                }
              }
              if(centerOfMassCheckbox.selected) {
                v.y = centerOfMass.y + (v.y - centerOfMass.y) * baseScaleY;
                v.z = centerOfMass.z + (v.z - centerOfMass.z) * baseScaleZ;
              } else {
                v.y *= baseScaleY;
                v.z *= baseScaleZ;
              }
            }
            break;
            case VIEW_Y:
            { 
              float baseScaleX = getScaleFactor(selectMouseStartX, selectMouseEndX);
              float baseScaleZ = getScaleFactor(selectMouseEndY, selectMouseStartY);  
              if(ctrlPressed) {
                if(abs(selectMouseStartX - selectMouseEndX) > abs(selectMouseStartY - selectMouseEndY)) {
                  baseScaleX = 1.0;
                } else {
                  baseScaleZ = 1.0;
                }
              }                   
              if(centerOfMassCheckbox.selected) {
                v.x = centerOfMass.x + (v.x - centerOfMass.x) * baseScaleX;
                v.z = centerOfMass.z + (v.z - centerOfMass.z) * baseScaleZ;
              } else {
                v.x *= baseScaleX;
                v.z *= baseScaleZ;
              }
            }
            break;
            case VIEW_Z:
            { 
              float baseScaleX = getScaleFactor(selectMouseStartX, selectMouseEndX);
              float baseScaleY = getScaleFactor(selectMouseEndY, selectMouseStartY);  
              if(ctrlPressed) {
                if(abs(selectMouseStartX - selectMouseEndX) > abs(selectMouseStartY - selectMouseEndY)) {
                  baseScaleX = 1.0;
                } else {
                  baseScaleY = 1.0;
                }
              }
              if(centerOfMassCheckbox.selected) {
                v.x = centerOfMass.x + (v.x - centerOfMass.x) * baseScaleX;
                v.y = centerOfMass.y + (v.y - centerOfMass.y) * baseScaleY;
              } else {
                v.x *= baseScaleX;
                v.y *= baseScaleY;
              }
            }
            break;
            case VIEW_3D:
            break;
          }
        }
      }
      updateSelected();
      selectMouseStartX = selectMouseEndX - (gridOffsetX / scale.z);
      selectMouseStartY = selectMouseEndY - (gridOffsetY / scale.z);
    } else if(mode == MODE_SCALE_ALL) {
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        if(v.selected) {
          switch(viewType) {
            case VIEW_X:
            case VIEW_Y:
            case VIEW_Z:
            { 
              float baseScale = getScaleFactor(selectMouseStartX, selectMouseEndX);
              if(centerOfMassCheckbox.selected) {
                v.x = centerOfMass.x + (v.x - centerOfMass.x) * baseScale;
                v.y = centerOfMass.y + (v.y - centerOfMass.y) * baseScale;
                v.z = centerOfMass.z + (v.z - centerOfMass.z) * baseScale;
              } else {
                v.x *= baseScale;
                v.y *= baseScale;
                v.z *= baseScale;
              }
            }
            break;
            case VIEW_3D:
            break;
          }
        }
      }
      updateSelected();
      selectMouseStartX = selectMouseEndX - (gridOffsetX / scale.z);
      selectMouseStartY = selectMouseEndY - (gridOffsetY / scale.z);
    }
  }
  
  boolean between(float v, float x1, float x2) {
    return (((v > x1) && (v < x2)) || ((v < x1) && (v > x2)));
  }
   
  boolean selectHelper(Face f) {
     switch(viewType) {
      case VIEW_X:
      {  
        Vector3f startPos = new Vector3f(0.0f, -selectMouseStartY, selectMouseStartX);
        startPos = modelViewMatrix.transformPosition(startPos);
        Vector3f endPos = new Vector3f(0.0f, -selectMouseEndY, selectMouseEndX);
        endPos = modelViewMatrix.transformPosition(endPos);        
        return between(f.v1.v.y, startPos.y, endPos.y) && between(f.v1.v.z, startPos.z, endPos.z) &&
               between(f.v2.v.y, startPos.y, endPos.y) && between(f.v2.v.z, startPos.z, endPos.z) &&
               between(f.v3.v.y, startPos.y, endPos.y) && between(f.v3.v.z, startPos.z, endPos.z);
      }
      case VIEW_Y:
      {  
        Vector3f startPos = new Vector3f(selectMouseStartX, 0.0f, -selectMouseStartY);
        startPos = modelViewMatrix.transformPosition(startPos);
        Vector3f endPos = new Vector3f(selectMouseEndX, 0.0f, -selectMouseEndY);
        endPos = modelViewMatrix.transformPosition(endPos);
        //return between(v.x, startPos.x, endPos.x) && between(v.z, startPos.z, endPos.z);
        return between(f.v1.v.x, startPos.x, endPos.x) && between(f.v1.v.z, startPos.z, endPos.z) &&
               between(f.v2.v.x, startPos.x, endPos.x) && between(f.v2.v.z, startPos.z, endPos.z) &&
               between(f.v3.v.x, startPos.x, endPos.x) && between(f.v3.v.z, startPos.z, endPos.z);
      }
      case VIEW_Z:
      {  
        Vector3f startPos = new Vector3f(-selectMouseStartX, -selectMouseStartY, 0.0f);
        startPos = modelViewMatrix.transformPosition(startPos);
        Vector3f endPos = new Vector3f(-selectMouseEndX, -selectMouseEndY, 0.0f);
        endPos = modelViewMatrix.transformPosition(endPos);
        //return between(v.x, startPos.x, endPos.x) && between(v.y, startPos.y, endPos.y);
        return between(f.v1.v.x, startPos.x, endPos.x) && between(f.v1.v.y, startPos.y, endPos.y) &&
               between(f.v2.v.x, startPos.x, endPos.x) && between(f.v2.v.y, startPos.y, endPos.y) &&
               between(f.v3.v.x, startPos.x, endPos.x) && between(f.v3.v.y, startPos.y, endPos.y);
      }
      case VIEW_3D:
      { 
        float vX1 = g.screenX(f.v1.v.x, f.v1.v.y, f.v1.v.z) - w/2;
        float vY1 = g.screenY(f.v1.v.x, f.v1.v.y, f.v1.v.z) - h/2;
        float vX2 = g.screenX(f.v2.v.x, f.v2.v.y, f.v2.v.z) - w/2;
        float vY2 = g.screenY(f.v2.v.x, f.v2.v.y, f.v2.v.z) - h/2;
        float vX3 = g.screenX(f.v3.v.x, f.v3.v.y, f.v3.v.z) - w/2;
        float vY3 = g.screenY(f.v3.v.x, f.v3.v.y, f.v3.v.z) - h/2;
        //print(vX + " , " + vY + " " + selectMouseStartX + " , " + selectMouseStartY + " " + selectMouseEndX + " , " + selectMouseEndY + "\n");
        return between(vX1, selectMouseStartX, selectMouseEndX) && between(vY1, selectMouseStartY, selectMouseEndY) &&
               between(vX2, selectMouseStartX, selectMouseEndX) && between(vY2, selectMouseStartY, selectMouseEndY) &&
               between(vX3, selectMouseStartX, selectMouseEndX) && between(vY3, selectMouseStartY, selectMouseEndY);
      }
     }
     return false;
  }
  
  boolean selectHelper(Vertex v) {
     switch(viewType) {
      case VIEW_X:
      {  
        Vector3f startPos = new Vector3f(0.0f, -selectMouseStartY, selectMouseStartX);
        startPos = modelViewMatrix.transformPosition(startPos);
        Vector3f endPos = new Vector3f(0.0f, -selectMouseEndY, selectMouseEndX);
        endPos = modelViewMatrix.transformPosition(endPos);
        return between(v.y, startPos.y, endPos.y) && between(v.z, startPos.z, endPos.z);
      }
      case VIEW_Y:
      {  
        Vector3f startPos = new Vector3f(selectMouseStartX, 0.0f, -selectMouseStartY);
        startPos = modelViewMatrix.transformPosition(startPos);
        Vector3f endPos = new Vector3f(selectMouseEndX, 0.0f, -selectMouseEndY);
        endPos = modelViewMatrix.transformPosition(endPos);
        return between(v.x, startPos.x, endPos.x) && between(v.z, startPos.z, endPos.z);
      }
      case VIEW_Z:
      {  
        Vector3f startPos = new Vector3f(-selectMouseStartX, -selectMouseStartY, 0.0f);
        startPos = modelViewMatrix.transformPosition(startPos);
        Vector3f endPos = new Vector3f(-selectMouseEndX, -selectMouseEndY, 0.0f);
        endPos = modelViewMatrix.transformPosition(endPos);
        return between(v.x, startPos.x, endPos.x) && between(v.y, startPos.y, endPos.y);
      }
      case VIEW_3D:
      { 
        float vX = g.screenX(v.x, v.y, v.z) - w/2;
        float vY = g.screenY(v.x, v.y, v.z) - h/2;
        //print(vX + " , " + vY + " " + selectMouseStartX + " , " + selectMouseStartY + " " + selectMouseEndX + " , " + selectMouseEndY + "\n");
        return between(vX, selectMouseStartX, selectMouseEndX) && between(vY, selectMouseStartY, selectMouseEndY);
      }
     }
     return false;
  }
  
  void mouseReleased() {
    if(!processMousePosition())
      return;
    
    if(selecting && (mode == MODE_SELECT_VERTEX)) {
      if(viewType == VIEW_3D) {
        g.perspective(PI/3.0, ((float)w) / h, .0001, 100000.0);
        g.resetMatrix();
        g.applyMatrix(modelViewMatrix.m00(), modelViewMatrix.m10(), modelViewMatrix.m20(), modelViewMatrix.m30(),
          modelViewMatrix.m01(), modelViewMatrix.m11(), modelViewMatrix.m21(), modelViewMatrix.m31(),
          modelViewMatrix.m02(), modelViewMatrix.m12(), modelViewMatrix.m22(), modelViewMatrix.m32(),
          modelViewMatrix.m03(), modelViewMatrix.m13(), modelViewMatrix.m23(), modelViewMatrix.m33());
      }
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        if(selectHelper(v) ||
           ((keyPressed && keyCode == SHIFT) && v.selected))
        {
          if(keyPressed && keyCode == CONTROL) {
            v.selected = false;
          } else {
            v.selected = true;
          }
        } else {
          if(!(keyPressed && keyCode == CONTROL)) {
            v.selected = false;
          }
        }
      }
      updateSelected();
    } else if(selecting && (mode == MODE_SELECT_FACE)) {
      if(viewType == VIEW_3D) {
        g.perspective(PI/3.0, ((float)w) / h, .0001, 100000.0);
        g.resetMatrix();
        g.applyMatrix(modelViewMatrix.m00(), modelViewMatrix.m10(), modelViewMatrix.m20(), modelViewMatrix.m30(),
          modelViewMatrix.m01(), modelViewMatrix.m11(), modelViewMatrix.m21(), modelViewMatrix.m31(),
          modelViewMatrix.m02(), modelViewMatrix.m12(), modelViewMatrix.m22(), modelViewMatrix.m32(),
          modelViewMatrix.m03(), modelViewMatrix.m13(), modelViewMatrix.m23(), modelViewMatrix.m33());
      }
      for (int i = faces.size()-1; i >= 0; i--) {
        Face f = faces.get(i);
        if(selectHelper(f) ||
           ((keyPressed && keyCode == SHIFT) && f.selected))
        {
          if(keyPressed && keyCode == CONTROL) {
            f.selected = false;
          } else {
            f.selected = true;
          }
        } else {
          if(!(keyPressed && keyCode == CONTROL)) {
            f.selected = false;
          }
        }
      }
      updateSelected();
    }
    selecting = false;
  }
  
  void keyPressed() {   
    if(!processMousePosition())
      return;
    if(viewType == VIEW_3D) {
      c.keyPressed();
    }
  }
  
  void keyReleased() {   
    if(!processMousePosition())
      return;
    if(viewType == VIEW_3D) {
      c.keyReleased();
      if(key == '`') {
        c.frameModel();
      }
    }
  }
  
  void drawGrid() {
    Vector3f scale = new Vector3f();
    modelViewMatrix.getScale(scale);
    g.strokeWeight(0.5 * scale.z);
    if(darkModeCheckbox.selected) {
      g.stroke(92, 92, 92);
    } else {
      g.stroke(0, 0, 0);
    }
    Vector3f zero = new Vector3f();
    zero = modelViewMatrix.transformPosition(zero);
    int gridStartX = (int)((zero.x) / STARTING_SCALE);
    gridStartX *= STARTING_SCALE;
    int gridStartY = (int)((zero.y) / STARTING_SCALE);
    gridStartY *= STARTING_SCALE;
    int wG = (int)(((int)(w / STARTING_SCALE)) * STARTING_SCALE);
    int hG = (int)(((int)(h / STARTING_SCALE)) * STARTING_SCALE);    
    switch(viewType) {
      case VIEW_X:
      {                           
        for(int x = (int)(-STARTING_SCALE - wG); x < wG + STARTING_SCALE; x += STARTING_SCALE) {    
          g.line(0.0, gridStartX + x, -STARTING_SCALE + gridStartY - hG, 
                 0.0, gridStartX + x, hG + gridStartY + STARTING_SCALE);
        }
        for(int y = (int)(-STARTING_SCALE - hG) ; y < hG + STARTING_SCALE; y += STARTING_SCALE) {
          g.line(0.0, -STARTING_SCALE + gridStartX - wG, gridStartY + y, 
                 0.0, wG + gridStartX + STARTING_SCALE, gridStartY + y);
        }
      }      
      break;
      case VIEW_Y:
      {      
        for(int x = (int)(-STARTING_SCALE - wG); x < wG + STARTING_SCALE; x += STARTING_SCALE) {    
          g.line(gridStartX + x, 0.0, -STARTING_SCALE + gridStartY - hG, 
                 gridStartX + x, 0.0, hG + gridStartY + STARTING_SCALE);
        }
        for(int y = (int)(-STARTING_SCALE - hG) ; y < hG + STARTING_SCALE; y += STARTING_SCALE) {
          g.line(-STARTING_SCALE + gridStartX - wG, 0.0, gridStartY + y, 
                 wG + gridStartX + STARTING_SCALE, 0.0, gridStartY + y);
        }
      }
      break;
      case VIEW_Z:
      {           
        for(int x = (int)(-STARTING_SCALE - wG); x < wG + STARTING_SCALE; x += STARTING_SCALE) {    
          g.line(gridStartX + x, -STARTING_SCALE + gridStartY - hG, 0.0, 
                 gridStartX + x, hG + gridStartY + STARTING_SCALE, 0.0);
        }
        for(int y = (int)(-STARTING_SCALE - hG) ; y < hG + STARTING_SCALE; y += STARTING_SCALE) {
          g.line(-STARTING_SCALE + gridStartX - wG, gridStartY + y, 0.0, 
                 wG + gridStartX + STARTING_SCALE, gridStartY + y, 0.0);
        }
      }
      break;
      case VIEW_3D:
      break;
    }
  }  
  
  void draw() {  
    
    if(viewType == VIEW_3D) {
      c.update();
    }
    Vector3f scale = new Vector3f(1.0, 1.0, 1.0);
    if(viewType != VIEW_3D) {
      modelViewMatrix.getScale(scale);
    }
    
    g.beginDraw();
    g.pushMatrix();
    g.background(darkModeCheckbox.selected ? 0 : 192);  
    if(viewType == VIEW_Z) {
      g.ortho(-w/2, w/2, -h/2, h/2, -10000, 10000);
      g.camera(0.0, 0.0, 10.0, 
       0.0, 0.0, 0.0, 
       0.0, -1.0, 0.0);
    } else if(viewType == VIEW_Y) { 
      g.ortho(-w/2, w/2, -h/2, h/2, -10000, 10000);     
      g.camera(0.0, 10.0, 0.0, 
       0.0, 0.0, 0.0, 
       0.0, 0.0, -1.0);
    } else if(viewType == VIEW_X) {
      g.ortho(-w/2, w/2, -h/2, h/2, -10000, 10000);      
      g.camera(10.0, 0.0, 0.0, 
       0.0, 0.0, 0.0, 
       0.0, -1.0, 0.0);
    } else if(viewType == VIEW_3D) {
      g.perspective(PI/3.0, ((float)w) / h, .0001, 100000.0);
      g.resetMatrix();
      g.applyMatrix(modelViewMatrix.m00(), modelViewMatrix.m10(), modelViewMatrix.m20(), modelViewMatrix.m30(),
        modelViewMatrix.m01(), modelViewMatrix.m11(), modelViewMatrix.m21(), modelViewMatrix.m31(),
        modelViewMatrix.m02(), modelViewMatrix.m12(), modelViewMatrix.m22(), modelViewMatrix.m32(),
        modelViewMatrix.m03(), modelViewMatrix.m13(), modelViewMatrix.m23(), modelViewMatrix.m33());
    }
    
    if(viewType != VIEW_3D) {
      Matrix4f modelViewMatrixInvert = new Matrix4f(modelViewMatrix).invert();
      g.applyMatrix(modelViewMatrixInvert.m00(), modelViewMatrixInvert.m10(), modelViewMatrixInvert.m20(), modelViewMatrixInvert.m30(),
        modelViewMatrixInvert.m01(), modelViewMatrixInvert.m11(), modelViewMatrixInvert.m21(), modelViewMatrixInvert.m31(),
        modelViewMatrixInvert.m02(), modelViewMatrixInvert.m12(), modelViewMatrixInvert.m22(), modelViewMatrixInvert.m32(),
        modelViewMatrixInvert.m03(), modelViewMatrixInvert.m13(), modelViewMatrixInvert.m23(), modelViewMatrixInvert.m33());
    }
    
    g.beginShape(LINES);
    g.strokeWeight(1.0 * scale.z);
    g.stroke(255, 0, 0);
    g.vertex(0.0, 0.0, 0.0);
    g.vertex(5.0, 0.0, 0.0);
    g.stroke(0, 255, 0);
    g.vertex(0.0, 0.0, 0.0);
    g.vertex(0.0, 5.0, 0.0);
    g.stroke(0, 0, 255);
    g.vertex(0.0, 0.0, 0.0);
    g.vertex(0.0, 0.0, 5.0);
    g.endShape();
    
    drawGrid();
    if(!saveNextDraw && showVerticesCheckbox.selected) {
      
      g.strokeCap(PROJECT);
      g.strokeWeight(5.0 * scale.z);
      g.beginShape(POINTS);
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        if(v.selected) {        
          g.stroke(255, 0, 0);  
          g.fill(255, 0, 0);
        } else {
          if(darkModeCheckbox.selected) {
            g.stroke(255, 255, 255);  
            g.fill(255, 255, 255);
          } else {
            g.stroke(0, 0, 0);
            g.fill(0, 0, 0);
          }
        }
        g.vertex(v.x, v.y, v.z);
      }
      
      //g.fill(0, 255, 0);
      //g.stroke(0, 255, 0);
      //g.vertex(debugPoint.x, debugPoint.y, debugPoint.z);
      g.endShape();
    }    
    
    
    if(saveNextDraw) { 
      beginRaw(DXF, "output.dxf");
    }
    
    if(showEdgesCheckbox.selected) {
      g.strokeWeight(1.0 * scale.z);
      if(darkModeCheckbox.selected) {
        g.stroke(255, 255, 255);
      } else {
        g.stroke(0, 0, 0);
      }
    } else {
      g.noStroke();
    }
    if(showFacesCheckbox.selected) {
      g.fill(128, 128, 128);
    } else {
      g.noFill();
    }
    g.beginShape(TRIANGLES);
    if(showLightingCheckbox.selected) {
      g.lights();
    }
    boolean setTexture = true;
    g.textureMode(NORMAL);
    for(int i = faces.size() - 1; i >= 0; i--) {
      Face f = faces.get(i);
      if(darkModeCheckbox.selected) {
        g.fill(128, 128, 128);
        g.ambient(255, 255, 255);
        g.specular(255, 255, 255);
      } else {
        g.fill(64, 64, 64);
        g.ambient(64, 64, 64);
        g.specular(192, 192, 192);
      }
      if(f.m != null) {
        g.ambient(255 * f.m.Ka.x, 255 * f.m.Ka.y, 255 * f.m.Ka.z);
        g.fill(255 * f.m.Kd.x, 255 * f.m.Kd.y, 255 * f.m.Kd.z);
        g.specular(255 * f.m.Ks.x, 255 * f.m.Ks.y, 255 * f.m.Ks.z);
      }
      if(f.selected) {
        g.fill(255, 0, 0);
        g.ambient(255, 0, 0);
        g.specular(255, 0, 0);
      }
      if(f.v1.hasNormal) {
        g.normal(f.v1.nx, f.v1.ny, f.v1.nz);
      }
      if(!showFacesCheckbox.selected) {
        g.noFill();
      }
      if(showTexturesCheckbox.selected && f.v1.hasTexture) {
        //println("hasTexture");
        g.vertex(f.v1.v.x, f.v1.v.y, f.v1.v.z, f.v1.tx, f.v1.ty);
        if(setTexture) {
          //println("setTexture");
          setTexture = false;    
          if((f.m != null) && (f.m.texture_diffuse != null)) {
            //println("setting texture " + f.m.texture_diffuse);
            g.texture(f.m.texture_diffuse);
          } else {
            g.texture(null);
          }
        }
      } else {
        g.vertex(f.v1.v.x, f.v1.v.y, f.v1.v.z);
      }
      if(f.v2.hasNormal) {
        g.normal(f.v2.nx, f.v2.ny, f.v2.nz);
      }
      if(showTexturesCheckbox.selected && f.v2.hasTexture) {
        g.vertex(f.v2.v.x, f.v2.v.y, f.v2.v.z, f.v2.tx, f.v2.ty);
      } else {
        g.vertex(f.v2.v.x, f.v2.v.y, f.v2.v.z);
      }
      if(f.v3.hasNormal) {
        g.normal(f.v3.nx, f.v3.ny, f.v3.nz);
      }
      if(showTexturesCheckbox.selected && f.v3.hasTexture) {
        //println("drawing vertex: " + f.v3.x + " , " + f.v3.y + " , " + f.v3.z + " , " + f.v3.tx + " , " + f.v3.ty);
        g.vertex(f.v3.v.x, f.v3.v.y, f.v3.v.z, f.v3.tx, f.v3.ty);
      } else {
        g.vertex(f.v3.v.x, f.v3.v.y, f.v3.v.z);
      }
    }
    g.endShape(); 
    
    if(showNormalsCheckbox.selected) {
      g.beginShape(LINES);
      for (int i = faces.size()-1; i >= 0; i--) {
          Face f = faces.get(i);
          if(f.v1.hasNormal) {
            g.stroke(255, 0, 0);
            g.vertex(f.v1.v.x, f.v1.v.y, f.v1.v.z);
            g.vertex(f.v1.v.x + f.v1.nx * 0.2, f.v1.v.y + f.v1.ny * 0.2, f.v1.v.z + f.v1.nz * 0.2);          
          }
          if(f.v2.hasNormal) {
            g.stroke(255, 0, 0);
            g.vertex(f.v2.v.x, f.v2.v.y, f.v2.v.z);
            g.vertex(f.v2.v.x + f.v2.nx * 0.2, f.v2.v.y + f.v2.ny * 0.2, f.v2.v.z + f.v2.nz * 0.2);          
          }
          if(f.v3.hasNormal) {
            g.stroke(255, 0, 0);
            g.vertex(f.v3.v.x, f.v3.v.y, f.v3.v.z);
            g.vertex(f.v3.v.x + f.v3.nx * 0.2, f.v3.v.y + f.v3.ny * 0.2, f.v3.v.z + f.v3.nz * 0.2);          
          }
          //g.stroke(0, 255, 0);
          //g.vertex((f.v1.v.x + f.v2.v.x + f.v3.v.x) / 3, (f.v1.v.y + f.v2.v.y + f.v3.v.y) / 3, (f.v1.v.z + f.v2.v.z + f.v3.v.z) / 3);
          //g.vertex((f.v1.v.x + f.v2.v.x + f.v3.v.x) / 3 + debugNormal.x, (f.v1.v.y + f.v2.v.y + f.v3.v.y) / 3 + debugNormal.y, (f.v1.v.z + f.v2.v.z + f.v3.v.z) / 3 + debugNormal.z);
          
      }
      g.endShape();
    }
    
    if (saveNextDraw) {
      endRaw();
      saveNextDraw = false;
    }
    
    if(selecting) {
      g.stroke(255, 255, 255);
      g.ambient(255, 255, 255);
      g.specular(255, 255, 255);
      g.fill(255, 228, 228, 92);
      g.pushMatrix();      
      g.resetMatrix();
      g.ortho(-w/2, w/2, -h/2, h/2, -10000, 10000); 
      g.camera(0.0, 0.0, 10.0, 
        0.0, 0.0, 0.0, 
        0.0, 1.0, 0.0);           
      Vector3f startPos = new Vector3f(selectMouseStartX, selectMouseStartY, -10000.0f);
      Vector3f endPos = new Vector3f(selectMouseEndX, selectMouseEndY, -10000.0f);
      g.hint(DISABLE_DEPTH_TEST);
      g.rect(startPos.x, startPos.y, (endPos.x - startPos.x), (endPos.y - startPos.y));
      g.hint(ENABLE_DEPTH_TEST);
      g.popMatrix();
    }
    g.popMatrix();
    g.fill(255, 255, 255);
    g.stroke(255, 255, 255);
    g.endDraw();
    image(g, x, y);
    //saveFrame("test-######.tif");
  }
}
