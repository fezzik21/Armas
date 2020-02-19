//undo feature (yikes!)
//continue to implement FBX loader
//select only front facing vertices (verts with front facing normals?)
//allow graphical editing of normals
//Draw origin rotation frame of size relative to the scale
//Load Texture coordinates (yikes!)
//Display texture(s)
//still need better camera rotation - rotate around a look at point?
//Allow for a simple "computational framework" (QScript)
//edit boxes arrow keys to move around
//nonsense text in text box doesn't cause an update
//create a "toolbox" of clickable items to make changes to the world
//move is busted again :(
//add/remove normals button
//make sure normals are being saved out to the obj if there are any
//create cube, sphere, pyramid buttons
//create a github page, and a description of what the project is
//Seperate window out into a seperate tab

import org.joml.*;

ArrayList<Vertex> vertices;
ArrayList<Face> faces;
ArrayList<Window> windows;
Button snapToGridCheckbox;
Button showVerticesCheckbox;
Button showEdgesCheckbox, showFacesCheckbox, showLightingCheckbox, showNormalsCheckbox;
TextBox xTextBox, yTextBox, zTextBox;
TextBox nxTextBox, nyTextBox, nzTextBox;
Label editLabel;
int mode;
boolean saveNextDraw;
float oldWidth, oldHeight;

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
      c.moveForward((e > 0.0) ? 1.0 : -1.0);
    } else {
      modelViewMatrix = modelViewMatrix.scale(s, s, s);
    }
  }

  void mouseClicked() {
    if(!processMousePosition())
      return;
    if(mode == MODE_SELECT) {
      selectMouseStartX -= 3;
      selectMouseStartY -= 3;
      selectMouseEndX += 3;
      selectMouseEndY += 3;
      if(viewType == VIEW_3D) {
        
      g.perspective(PI/3.0, width/height, .0001, 100000.0);
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
    } else if(mode == MODE_VERTEX) { 
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
      if(mode == MODE_SELECT) {
        print("mousePressed with select\n");
        selecting = true;
      } else if (mode == MODE_MOVE) {
      }
    } 
    selectMouseStartX = mX;
    selectMouseStartY = mY;
    selectMouseEndX = mX;
    selectMouseEndY = mY;
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
              v.z -= (selectMouseEndX - selectMouseStartX) * scale.z;
              v.y += (selectMouseEndY - selectMouseStartY) * scale.z;
              if(snapToGridCheckbox.selected) {
                float vGY = round(v.y / STARTING_SCALE) * STARTING_SCALE;
                float vGZ = round(v.z / STARTING_SCALE) * STARTING_SCALE;
                gridOffsetX = -(v.z - vGZ);
                gridOffsetY = (v.y - vGY);
                v.y = vGY;
                v.z = vGZ;
              }
            }
            break;
            case VIEW_Y:
            { 
              v.x -= (selectMouseEndX - selectMouseStartX) * scale.z;
              v.z += (selectMouseEndY - selectMouseStartY) * scale.z;
              if(snapToGridCheckbox.selected) {
                float vGX = round(v.x / STARTING_SCALE) * STARTING_SCALE;
                float vGZ = round(v.z / STARTING_SCALE) * STARTING_SCALE;
                gridOffsetX = -(v.x - vGX);
                gridOffsetY = (v.z - vGZ);
                v.x = vGX;
                v.z = vGZ;
              }
            }
            break;
            case VIEW_Z:
            { 
              v.x += (selectMouseEndX - selectMouseStartX) * scale.z;
              v.y += (selectMouseEndY - selectMouseStartY) * scale.z;
              if(snapToGridCheckbox.selected) {
                float vGX = round(v.x / STARTING_SCALE) * STARTING_SCALE;
                float vGY = round(v.y / STARTING_SCALE) * STARTING_SCALE;
                gridOffsetX = (v.x - vGX);
                gridOffsetY = (v.y - vGY);
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
      selectMouseStartX = selectMouseEndX - (gridOffsetX / scale.z);
      selectMouseStartY = selectMouseEndY - (gridOffsetY / scale.z);
    }
  }
  
  boolean between(float v, float x1, float x2) {
    return (((v > x1) && (v < x2)) || ((v < x1) && (v > x2)));
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
    
    if(selecting && (mode == MODE_SELECT)) {
      if(viewType == VIEW_3D) {
        g.perspective(PI/3.0, width/height, .0001, 100000.0);
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
    g.stroke(92, 92, 92);
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
    g.background(0);  
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
      g.perspective(PI/3.0, width/height, .0001, 100000.0);
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
          g.stroke(255, 255, 255);  
          g.fill(255, 255, 255);
        }
        g.vertex(v.x, v.y, v.z);
      }
      g.endShape();
    }    
    
    
    if(saveNextDraw) { 
      beginRaw(DXF, "output.dxf");
    }
    
    if(showEdgesCheckbox.selected) {
      g.strokeWeight(1.0 * scale.z);
      g.stroke(255, 255, 255);
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
    for(int i = faces.size() - 1; i >= 0; i--) {
      Face f = faces.get(i);
      if(f.v1.hasNormal) {
        g.normal(f.v1.nx, f.v1.ny, f.v1.nz);
      }
      g.vertex(f.v1.x, f.v1.y, f.v1.z);
      if(f.v2.hasNormal) {
        g.normal(f.v2.nx, f.v2.ny, f.v2.nz);
      }
      g.vertex(f.v2.x, f.v2.y, f.v2.z);
      if(f.v3.hasNormal) {
        g.normal(f.v3.nx, f.v3.ny, f.v3.nz);
      }
      g.vertex(f.v3.x, f.v3.y, f.v3.z);
    }
    g.endShape(); 
    
    if(showNormalsCheckbox.selected) {
      g.beginShape(LINES);
      for (int i = vertices.size()-1; i >= 0; i--) {
          Vertex v = vertices.get(i);
          if(v.hasNormal) {
            g.stroke(255, 0, 0);
            g.vertex(v.x, v.y, v.z);
            g.vertex(v.x + v.nx * 0.2, v.y + v.ny * 0.2, v.z + v.nz * 0.2);          
          }
      }
      g.endShape();
    }
    
    if (saveNextDraw) {
      endRaw();
      saveNextDraw = false;
    }
    
    if(selecting) {
      g.stroke(255, 255, 255);
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

void updateSelected() {
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    if(v.selected) {
      selected.add(v);
      xTextBox.t = String.valueOf(v.x);
      yTextBox.t = String.valueOf(v.y);
      zTextBox.t = String.valueOf(v.z);
      nxTextBox.t = String.valueOf(v.nx);
      nyTextBox.t = String.valueOf(v.ny);
      nzTextBox.t = String.valueOf(v.nz);
    }
  }
  editLabel.visible = nxTextBox.visible = nyTextBox.visible = nzTextBox.visible =xTextBox.visible = yTextBox.visible = zTextBox.visible = false;
  if(selected.size() == 1) {
    editLabel.visible = xTextBox.visible = yTextBox.visible = zTextBox.visible = true;
    if(selected.get(0).hasNormal) {
      nxTextBox.visible = nyTextBox.visible = nzTextBox.visible = true;
    }
  }
}

void updateSelectedVertexPosition() {
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    if(v.selected) {
      v.x = float(xTextBox.t);
      v.y = float(yTextBox.t);
      v.z = float(zTextBox.t);
      if(v.hasNormal) {
        v.nx = float(nxTextBox.t);
        v.ny = float(nyTextBox.t);
        v.nz = float(nzTextBox.t);
      }
    }
  }
}

void pre() {
  if((oldWidth != width) || (oldHeight != height)) {
    resizeUI(oldWidth, oldHeight, width, height);
      
    int windowWidth = (width - UI_COLUMN_WIDTH) / 2 - 5;
    int windowHeight = height / 2 - 5;
    windows.get(0).resize(0, 0, windowWidth, windowHeight);
    windows.get(1).resize(windowWidth + 5, 0, windowWidth, windowHeight);
    windows.get(2).resize(0, windowHeight + 5, windowWidth, windowHeight);
    windows.get(3).resize(windowWidth + 5, windowHeight + 5, windowWidth, windowHeight);    
       
    oldWidth = width;
    oldHeight = height;
  }
}

void settings() {
  if((displayWidth > 1920) && (displayHeight > 1080)) {
    size(1920, 1080, P3D);
    oldWidth = 1920;
    oldHeight = 1080;
  } else {
    size(1280, 1024, P3D);
    oldWidth = 1280;
    oldHeight = 1024;
  }
}  

void setup() {
  frameRate(30);
  surface.setResizable(true);
  
  registerMethod ("pre", this ) ;
  
  vertices = new ArrayList<Vertex>();
  faces = new ArrayList<Face>();
  windows = new ArrayList<Window>();
  
  //c = new GUIController(this);
  final PApplet myThis = this;
  new Line(300);
  new Line(550);
  new Label("SHOW", 305);
  editLabel = new Label("EDIT", 555);
  new Button("Open", "o", false, null,  width - UI_COLUMN_WIDTH + 10, 20, 100, 25, new Thunk() { @Override public void apply() { openFile(myThis); } } );
  new Button("Save", "p", false, null,  width - UI_COLUMN_WIDTH + 10 + 110, 20, 100, 25, new Thunk() { @Override public void apply() { saveFile(myThis); } } );
  new Button("Vertex", "1", false, "Mode",  width - UI_COLUMN_WIDTH + 10, 80, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_VERTEX; } } ).selected = true;
  new Button("Select", "2", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, 80, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_SELECT; } } );
  new Button("Move", "3", false, "Mode",  width - UI_COLUMN_WIDTH + 10, 120, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_MOVE; } } );
  snapToGridCheckbox = new Button("Snap To Grid", "g", true, null,  width - UI_COLUMN_WIDTH + 10, 200, 100, 25, new Thunk() { @Override public void apply() { } } );
  showVerticesCheckbox = new Button("Vertices", "z", true, null,  width - UI_COLUMN_WIDTH + 10, 340, 100, 25, new Thunk() { @Override public void apply() { } } );
  showVerticesCheckbox.selected = true;
  showEdgesCheckbox = new Button("Edges", "x", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, 340, 100, 25, new Thunk() { @Override public void apply() { } } );
  showEdgesCheckbox.selected = true;
  showFacesCheckbox = new Button("Faces", "c", true, null,  width - UI_COLUMN_WIDTH + 10, 380, 100, 25, new Thunk() { @Override public void apply() { } } );
  showFacesCheckbox.selected = true;
  showLightingCheckbox = new Button("Light", "v", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, 380, 100, 25, new Thunk() { @Override public void apply() { } } );
  showLightingCheckbox.selected = true;
  showNormalsCheckbox = new Button("Normals", "b", true, null,  width - UI_COLUMN_WIDTH + 10, 420, 100, 25, new Thunk() { @Override public void apply() { } } );
  showNormalsCheckbox.selected = true;
  
  xTextBox = new TextBox("", "X", width - UI_COLUMN_WIDTH + 10, 600, 63, 25, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } } );
  yTextBox = new TextBox("", "Y", width - UI_COLUMN_WIDTH + 10 + 73, 600, 63, 25, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } });
  zTextBox = new TextBox("", "Z", width - UI_COLUMN_WIDTH + 10 + 73 + 73, 600, 64, 25, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } });
  nxTextBox = new TextBox("", "NX", width - UI_COLUMN_WIDTH + 10, 642, 63, 25, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } } );
  nyTextBox = new TextBox("", "NY", width - UI_COLUMN_WIDTH + 10 + 73, 642, 63, 25, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } });
  nzTextBox = new TextBox("", "NZ", width - UI_COLUMN_WIDTH + 10 + 73 + 73, 642, 64, 25, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } });
  
  int windowWidth = (width - UI_COLUMN_WIDTH) / 2 - 5;
  int windowHeight = height / 2 - 5;
  windows.add(new Window(0, 0, windowWidth, windowHeight, VIEW_Z));
  windows.add(new Window(windowWidth + 5, 0, windowWidth, windowHeight, VIEW_X));
  windows.add(new Window(0, windowHeight + 5, windowWidth, windowHeight, VIEW_Y));
  windows.add(new Window(windowWidth + 5, windowHeight + 5, windowWidth, windowHeight, VIEW_3D));
  
  updateSelected();
  mode = MODE_VERTEX; 
  thread("updateUI");
}

void mouseWheel(MouseEvent event) {
  for(Window w : windows) {
    w.mouseWheel(event);
  }
}

void mouseClicked() {
  for(Window w : windows) {
    w.mouseClicked();
  }
}

void mousePressed() {
  for(Window w : windows) {
    w.mousePressed();
  }
}

void mouseDragged() {  
  for(Window w : windows) {
    w.mouseDragged();
  }
}

void mouseReleased() { 
  for(Window w : windows) {
    w.mouseReleased();
  }
}

void keyPressed() {
  if(!uiTakesKeyInput()) {
    for(Window w : windows) {
      w.keyPressed();
    }
  }
  if(key == ESC) key = 0;
}

void keyReleased() {   
  for(Window w : windows) {
    w.keyReleased();
  }
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
  if(key == 'f') {
    for (int i = vertices.size()-1; i >= 0; i--) {
      Vertex v = vertices.get(i);
      if(v.selected) {
        selected.add(v);
      }
    }
    if(selected.size() == 3) {
      //See if the face already exists
      for (int i = faces.size()-1; i >= 0; i--) {
        Face f = faces.get(i);
        if(selected.contains(f.v1) && selected.contains(f.v2) && selected.contains(f.v3)) {
          faces.remove(f);
          return;
        }
      }
      faces.add(new Face(selected.get(0), selected.get(1), selected.get(2)));
    }
  } else if (key == DELETE) {
    for (int i = faces.size()-1; i >= 0; i--) {
      Face f = faces.get(i);
      if(f.v1.selected || f.v2.selected || f.v3.selected) {
        faces.remove(f);
      }
    }
    for (int i = vertices.size()-1; i >= 0; i--) {
      Vertex v = vertices.get(i);
      if(v.selected) {
        vertices.remove(v);
      }
    }
  } 
} 

void draw() {
  background(0);
  ortho(-width/2, width/2, -height/2, height/2);
  
  for(Window w : windows) {
    w.draw();
    
    fill(255, 0, 0);
    text(VIEW_NAMES[w.viewType], w.x, w.y + w.h - 10);
  }
  ortho(-width/2, width/2, -height/2, height/2);
  strokeWeight(2);
  stroke(192, 192, 255);
  line(0, height / 2, width - UI_COLUMN_WIDTH, height / 2);
  line((width - UI_COLUMN_WIDTH) / 2, 0, (width - UI_COLUMN_WIDTH) / 2, height);
  
  drawUI();
  //saveFrame("test-######.tif");
}
