


class Camera {
  Window w;
  
  Camera(Window wIn) {
    w = wIn;
  }
  
  void keyPressed() {
  }
  
  void keyReleased() {
  }
  
  void mouseDragged() {
    if(mouseButton == RIGHT) {
      
      Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
      Vector3f up = new Vector3f();
      modelViewMatrixInvert.transformDirection(0, 1, 0, up);
      up.normalize(up);
      
      Vector3f right = new Vector3f();
      modelViewMatrixInvert.transformDirection(1, 0, 0, right);
      right.normalize(right);
      
      w.modelViewMatrix.rotate((w.selectMouseEndY - w.selectMouseStartY) * -(.31415 / 180.0) * ROTATE_SPEED, right);
      w.modelViewMatrix.rotate((w.selectMouseEndX - w.selectMouseStartX) * (.31415 / 180.0) * ROTATE_SPEED, up);
      w.selectMouseStartX = w.selectMouseEndX;
      w.selectMouseStartY = w.selectMouseEndY;
    }
  }
  
  void update() {
    Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
    if(keyDown['w']) { //w
      Vector3f forward = new Vector3f();
      modelViewMatrixInvert.transformDirection(0, 0, 1, forward);
      forward.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(forward);
    } 
    if(keyDown['s']) { //don't know s yet
      Vector3f backward = new Vector3f();
      modelViewMatrixInvert.transformDirection(0, 0, -1, backward);
      backward.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(backward);
    } 
    if(keyDown['a']) {
      Vector3f left = new Vector3f();
      modelViewMatrixInvert.transformDirection(1, 0, 0, left);
      left.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(left);
    } 
    if(keyDown['d']) {
      Vector3f right = new Vector3f();
      modelViewMatrixInvert.transformDirection(-1, 0, 0, right);
      right.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(right);
    }
  }
  
  void pan(float x, float y) {
    
    Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
    Vector3f up = new Vector3f();
    modelViewMatrixInvert.transformDirection(0, -1, 0, up);
    up.mul(y * PAN_SPEED_3D);
    w.modelViewMatrix.translate(up); 
    Vector3f right = new Vector3f();
    modelViewMatrixInvert.transformDirection(1, 0, 0, right);
    right.mul(x * PAN_SPEED_3D);
    w.modelViewMatrix.translate(right);
  }
  
  void moveForward(float amount) {
    Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
    Vector3f forward = new Vector3f();
    modelViewMatrixInvert.transformDirection(0, 0, -1, forward);
    forward.mul(amount);
    w.modelViewMatrix.translate(forward);
  }
  
  void frameModel() {
    Vertex centerOfMass = new Vertex(0.0, 0.0, 0.0);
    Vertex min = new Vertex(MAX_FLOAT, MAX_FLOAT, MAX_FLOAT);
    Vertex max = new Vertex(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
    
    float scale = 1.0;
    for (int i = 0; i < vertices.size(); i++) {
        Vertex v = vertices.get(i);
        centerOfMass.x += v.x * (1.0 / vertices.size());
        centerOfMass.y += v.y * (1.0 / vertices.size());
        centerOfMass.z += v.z * (1.0 / vertices.size());
        min.x = min(min.x, v.x);
        min.y = min(min.y, v.y);
        min.z = min(min.z, v.z);
        max.x = max(max.x, v.x);
        max.y = max(max.y, v.y);
        max.z = max(max.z, v.z);
        //print("min = " + min.x + " , " + min.y + " , " + min.z + " \n");
        //print("max = " + max.x + " , " + max.y + " , " + max.z + " \n");
    }
    scale = max((max.x - min.x), max(max.y - min.y, max.z - min.z));
    //print("scale = " + scale + "\n");
    w.modelViewMatrix.setLookAt(centerOfMass.x, centerOfMass.y, centerOfMass.z + 1.2 * scale, 
      centerOfMass.x, centerOfMass.y, centerOfMass.z,
      0.0, -1.0, 0.0);
  }
}
