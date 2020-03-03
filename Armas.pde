//undo feature (yikes!)
//continue to implement FBX loader
//select only front facing vertices (verts with front facing normals?)
//allow graphical editing of normals
//Draw origin rotation frame of size relative to the scale
//Allow for a simple "computational framework" (QScript)
//add/remove normals button
//rotate object mode
//load other textures (e.g. bump, specular) (might require writing a custom shader?)
//text box scroll contents
//selecting only one face (the closest one)
//select faces algo has offset errors
//rename to avalanche, have a mountain logo, figure out how to make an executable
//camera rotate tries to keep the up vector up somehow
//create a new material
//  add a (non-working) "<new material>" option
//something's wrong with changing materials, the colors get screwed up eventually
//Name: Servo?  Torgo?  Avalanche?  
//allow material to load a new texture
//  display the current texture somehow
//move command uses Ctrl to only move in one axis
//add a help button (someplace), or at least some help documentation someplace
//lots of 3d z-fighting
//save file completion bar
//scale all totally screwed up on iron man
//text boxes print floats to only 3 significant digits



import java.util.*;
import org.joml.*;

ArrayList<Vertex> vertices;
ArrayList<Face> faces;
ArrayList<Window> windows;
HashMap<String, Material> materials;
Button snapToGridCheckbox;
Button showVerticesCheckbox;
Button centerOfMassCheckbox;
Button darkModeCheckbox;
Vertex centerOfMass;
Vertex singleSelectedVertex;
Face singleSelectedFace;
Button showEdgesCheckbox, showFacesCheckbox, showLightingCheckbox, showNormalsCheckbox, showTexturesCheckbox;
UIGroup vertexEditGroup, faceEditGroup, materialEditGroup;
VectorEditor vEditor;
VectorEditor n1Editor, n2Editor, n3Editor;
VectorEditor t1Editor, t2Editor, t3Editor;
VectorEditor kaEditor, kdEditor, ksEditor;
TextBox commandBox;
Label editLabel;
DropDownList materialSelector;
int mode;
boolean saveNextDraw;
float oldWidth, oldHeight;
boolean ctrlPressed = false;

//This is here to keep the UI from reporting press, drag, release, click - we don't want the click at the end
boolean dragWithoutPressInvalidatesClick = false;
//PImage sampleTexture;

boolean keyDown[];
boolean lastKeyDown[];
boolean keyCodeDown[];
boolean lastKeyCodeDown[];
  

void resetMaterials() {
  ArrayList<String> materialNames = new ArrayList<String>();
  Iterator<Material> v = materials.values().iterator();
  while(v.hasNext()) {
    Material vm = v.next();
    materialNames.add(vm.name);
  }
  materialSelector.options = materialNames;
  materialSelector.selectedOption = 0;
}

void clearSelected() {
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    v.selected = false;
  }
  for (int i = faces.size()-1; i >= 0; i--) {
    Face f = faces.get(i);
    f.selected = false;
  }
}

void updateSelected() {
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
  centerOfMass = new Vertex(0.0, 0.0, 0.0);
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    if(v.selected) {
      selected.add(v);
      centerOfMass.x += v.x;
      centerOfMass.y += v.y;
      centerOfMass.z += v.z;
      vEditor.updateText(new Vector3f(v.x, v.y, v.z));
    }
  }
  ArrayList<Face> selectedFaces = new ArrayList<Face>();
  for (int i = faces.size() - 1; i >= 0; i--) {
    Face f = faces.get(i);
    if(f.selected) {
      selectedFaces.add(f);
      n1Editor.updateText(new Vector3f(f.v1.nx, f.v1.ny, f.v1.nz));
      n2Editor.updateText(new Vector3f(f.v2.nx, f.v2.ny, f.v2.nz));
      n3Editor.updateText(new Vector3f(f.v3.nx, f.v3.ny, f.v3.nz));
      t1Editor.updateText(new Vector3f(f.v1.tx, f.v1.ty, 0.0));
      t2Editor.updateText(new Vector3f(f.v2.tx, f.v2.ty, 0.0));
      t3Editor.updateText(new Vector3f(f.v3.tx, f.v3.ty, 0.0));
      if(f.m != null) {
        kaEditor.updateText(f.m.Ka);
        kdEditor.updateText(f.m.Kd);
        ksEditor.updateText(f.m.Ks);
      }
    }
  }
  centerOfMass.x /= selected.size();
  centerOfMass.y /= selected.size();
  centerOfMass.z /= selected.size();  
  vertexEditGroup.setVisible(false);
  faceEditGroup.setVisible(false);
  materialEditGroup.setVisible(false);
  if(selected.size() == 1) {
    singleSelectedVertex = selected.get(0);
    vertexEditGroup.setVisible(true);
  }
  if(selectedFaces.size() == 1) {
    singleSelectedFace = selectedFaces.get(0);
    if(singleSelectedFace.m != null) {
      materialEditGroup.setVisible(true);
      materialSelector.selectedOption = materialSelector.options.indexOf(singleSelectedFace.m.name);
    }
    if(singleSelectedFace.v1.hasNormal) {
      n1Editor.setVisible(true);
    }
    if(singleSelectedFace.v1.hasTexture) {
      t1Editor.setVisible(true);
    }
    if(singleSelectedFace.v2.hasNormal) {
      n2Editor.setVisible(true);
    }
    if(singleSelectedFace.v2.hasTexture) {
      t2Editor.setVisible(true);
    }
    if(singleSelectedFace.v3.hasNormal) {
      n3Editor.setVisible(true);
    }
    if(singleSelectedFace.v3.hasTexture) {
      t3Editor.setVisible(true);
    }
  }
}

void updateSelectedVertexPosition() {
  Vertex v = singleSelectedVertex;
  if(v.selected) {
    Vector3f vec = new Vector3f();
    vEditor.updateValues(vec);
    v.x = vec.x; v.y = vec.y; v.z = vec.z;
  }
}

void updateMaterialChoice() {
  Face f = singleSelectedFace;
  if(f.selected) {
    f.m = materials.get(materialSelector.options.get(materialSelector.selectedOption));
  }
}

void updateSelectedMaterial() {
  Face f = singleSelectedFace;
  if(f.selected) {
    Material m = f.m;
    if(m != null) {
      kaEditor.updateValues(singleSelectedFace.m.Ka);
      kdEditor.updateValues(singleSelectedFace.m.Kd);
      ksEditor.updateValues(singleSelectedFace.m.Ks);
    }
  }
}
    
void updateSelectedFace() {
  Face f = singleSelectedFace;
  if(f.selected) {
    Vector3f vec = new Vector3f();
    n1Editor.updateValues(vec);
    f.v1.nx = vec.x; f.v1.ny = vec.y; f.v1.nz = vec.z;
    n2Editor.updateValues(vec);
    f.v2.nx = vec.x; f.v2.ny = vec.y; f.v2.nz = vec.z;
    n3Editor.updateValues(vec);
    f.v3.nx = vec.x; f.v3.ny = vec.y; f.v3.nz = vec.z;
    t1Editor.updateValues(vec);
    f.v1.tx = vec.x; f.v1.ty = vec.y;
    t2Editor.updateValues(vec);
    f.v2.tx = vec.x; f.v2.ty = vec.y;
    t3Editor.updateValues(vec);
    f.v3.tx = vec.x; f.v3.ty = vec.y;
      
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
  pixelDensity(displayDensity());
}  

void setup() {
  frameRate(30);
  surface.setResizable(true);
  
  registerMethod ("pre", this ) ;
  
  vertices = new ArrayList<Vertex>();
  faces = new ArrayList<Face>();
  windows = new ArrayList<Window>();
  materials = new HashMap<String, Material>();
  
  keyDown = new boolean[1024];
  keyCodeDown = new boolean[1024];
  lastKeyDown = new boolean[1024];
  lastKeyCodeDown = new boolean[1024];
  
  final PApplet myThis = this;
  new Line(305, null);
  new Line(550, null);
  new Label("SHOW", 310, null);
  editLabel = new Label("EDIT", 555, null);
  new Button("Open", "o", false, null,  width - UI_COLUMN_WIDTH + 10, 15, 100, 25, new Thunk() { @Override public void apply() { openFile(myThis); } } );
  new Button("Save", "p", false, null,  width - UI_COLUMN_WIDTH + 10 + 110, 15, 100, 25, new Thunk() { @Override public void apply() { saveFile(myThis); } } );
  new Line(50, null);  
  new Button("Place", "1", false, "Mode",  width - UI_COLUMN_WIDTH + 10, 60, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_PLACE; } } ).selected = true;
  new Button("Select Vertex", "2", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, 60, 100, 25, new Thunk() { @Override public void apply() { clearSelected(); mode = MODE_SELECT_VERTEX; } } );
  new Button("Select Face", "3", false, "Mode",  width - UI_COLUMN_WIDTH + 10, 100, 100, 25, new Thunk() { @Override public void apply() { clearSelected(); mode = MODE_SELECT_FACE; } } );
  new Button("Move", "4", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, 100, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_MOVE; } } );
  new Button("Scale (All)", "5", false, "Mode",  width - UI_COLUMN_WIDTH + 10, 140, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_SCALE_ALL; } } );
  new Button("Scale", "6", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, 140, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_SCALE; } } );
  new Button("Rotate", "7", false, "Mode",  width - UI_COLUMN_WIDTH + 10, 180, 100, 25, new Thunk() { @Override public void apply() { mode = MODE_ROTATE; } } );
  new Line(220, null);
  snapToGridCheckbox = new Button("Snap To Grid", "g", true, null,  width - UI_COLUMN_WIDTH + 10, 230, 100, 25, new Thunk() { @Override public void apply() { } } );
  centerOfMassCheckbox = new Button("Center of Mass", "h", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, 230, 100, 25, new Thunk() { @Override public void apply() { } } );
  centerOfMassCheckbox.selected = true;
  darkModeCheckbox = new Button("Dark Mode", "i", true, null,  width - UI_COLUMN_WIDTH + 10, 270, 100, 25, new Thunk() { @Override public void apply() { } } );
  darkModeCheckbox.selected = true;
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
  showTexturesCheckbox = new Button("Texture", "n", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, 420, 100, 25, new Thunk() { @Override public void apply() { } } );
  showTexturesCheckbox.selected = true;
  
  new Button("Face", "f", false, null,  width - UI_COLUMN_WIDTH + 10, 475, 100, 25, new Thunk() { @Override public void apply() {  addFace(); } } );
  new Button("Cube", "/", false, null,  width - UI_COLUMN_WIDTH + 10, 515, 100, 25, new Thunk() { @Override public void apply() {  makeCube(); } } );
  new Button("Sphere", "?", false, null,  width - UI_COLUMN_WIDTH + 10 + 110, 515, 100, 25, new Thunk() { @Override public void apply() {  makeSphere(); } } );
  
  vertexEditGroup = new UIGroup();
  vEditor = new VectorEditor("X", "Y", "Z", true, false, width - UI_COLUMN_WIDTH + 10, 600, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } }, vertexEditGroup);
  
  faceEditGroup = new UIGroup();
  n1Editor = new VectorEditor("NX", "NY", "NZ", true, false, width - UI_COLUMN_WIDTH + 10, 600, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  n2Editor = new VectorEditor("NX", "NY", "NZ", true, false, width - UI_COLUMN_WIDTH + 10, 640, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  n3Editor = new VectorEditor("NX", "NY", "NZ", true, false, width - UI_COLUMN_WIDTH + 10, 680, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  t1Editor = new VectorEditor("U", "V", "", false, false, width - UI_COLUMN_WIDTH + 10, 720, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  t2Editor = new VectorEditor("U", "V", "", false, false, width - UI_COLUMN_WIDTH + 10, 760, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  t3Editor = new VectorEditor("U", "V", "", false, false, width - UI_COLUMN_WIDTH + 10, 800, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  
  materialEditGroup = new UIGroup(); 
  new Line(840, materialEditGroup);
  new Label("MATERIAL", 845, materialEditGroup);
  ArrayList<String> materialNames = new ArrayList<String>();
  materialNames.add("mat_1");
  materialNames.add("mat_2");
  kaEditor = new VectorEditor("AR", "AG", "AB", true, true, width - UI_COLUMN_WIDTH + 10, 920, new Thunk() { @Override public void apply() { updateSelectedMaterial(); } }, materialEditGroup);
  kdEditor = new VectorEditor("DR", "DG", "DB", true, true, width - UI_COLUMN_WIDTH + 10, 960, new Thunk() { @Override public void apply() { updateSelectedMaterial(); } }, materialEditGroup);
  ksEditor = new VectorEditor("SR", "SG", "SB", true, true, width - UI_COLUMN_WIDTH + 10, 1000, new Thunk() { @Override public void apply() { updateSelectedMaterial(); } }, materialEditGroup);
  materialSelector = new DropDownList(materialNames, width - UI_COLUMN_WIDTH + 10, 880, UI_COLUMN_WIDTH - 40, 25, new Thunk() { @Override public void apply() { updateMaterialChoice(); } }, materialEditGroup);
  
  //ColorPicker(int xIn, int yIn, int r, int g, int b, Thunk valueUpdatedIn, UIGroup group) {  
  //colorPicker = new ColorPicker(width - UI_COLUMN_WIDTH - 150, 920, 255, 0, 0, new Thunk() { @Override public void apply() { } }, materialEditGroup);
  
  commandBox = new TextBox("", "COMMAND", width - UI_COLUMN_WIDTH + 10, height - 27, UI_COLUMN_WIDTH- 20, 25, new Thunk() { @Override public void apply() { executeCommand(); } }, null );
  commandBox.anchorBottom = true;
  
  int windowWidth = (width - UI_COLUMN_WIDTH) / 2 - 5;
  int windowHeight = height / 2 - 5;
  windows.add(new Window(0, 0, windowWidth, windowHeight, VIEW_Z));
  windows.add(new Window(windowWidth + 5, 0, windowWidth, windowHeight, VIEW_X));
  windows.add(new Window(0, windowHeight + 5, windowWidth, windowHeight, VIEW_Y));
  windows.add(new Window(windowWidth + 5, windowHeight + 5, windowWidth, windowHeight, VIEW_3D));
  
  updateSelected();
  mode = MODE_PLACE; 
  registerCommands();
  thread("updateUI");
  textSize(12);
  //sampleTexture = loadImage("Eye_D.jpg");
}

void mouseWheel(MouseEvent event) {
  for(Window w : windows) {
    w.mouseWheel(event);
  }
}

void mouseClicked() {
  if(dragWithoutPressInvalidatesClick) {
    //we got a drag, no intervening press, then a click.  we don't want this click in our UI.
    dragWithoutPressInvalidatesClick = false;
    if(mode != MODE_PLACE) {
      return;
    }
  }
  for(Window w : windows) {
    w.mouseClicked();
  }
}

void mousePressed() {
  if(!uiTakesMouseInput()) {
    dragWithoutPressInvalidatesClick = false;
    for(Window w : windows) {
      w.mousePressed();
    }
  }
}

void mouseDragged() {
  if(!uiTakesMouseInput()) {  
    dragWithoutPressInvalidatesClick = true;
    for(Window w : windows) {
      w.mouseDragged();
    }
  }
}

void mouseReleased() {   
  if(!uiTakesMouseInput()) {
    for(Window w : windows) {
      w.mouseReleased();
    }
  }
}

void keyPressed() {
  if(key < 1024) {
    lastKeyDown[key] = keyDown[key];
    keyDown[key] = true;
  }
  lastKeyCodeDown[keyCode] = keyCodeDown[keyCode];
  keyCodeDown[keyCode] = true;
  if(!uiTakesKeyInput()) {
    for(Window w : windows) {
      w.keyPressed();
    }
  }
  if(key == ESC) key = 0;
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = true;
    }
  }
}

void keyReleased() {   
    if(key < 1024) {
      lastKeyDown[key] = keyDown[key];
      keyDown[key] = false;
    }
    lastKeyCodeDown[keyCode] = keyCodeDown[keyCode];
    keyCodeDown[keyCode] = false;
    for(Window w : windows) {
    w.keyReleased();
  }
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = false;
    }
  }
  if(ctrlPressed && keyCode == 65) {
    if(mode == MODE_SELECT_FACE) {
      for (int i = faces.size()-1; i >= 0; i--) {
        Face f = faces.get(i);
        f.selected = true;
      }
    } else {
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        v.selected = true;
      }
    }
  }
  if (key == DELETE) {
    for (int i = faces.size()-1; i >= 0; i--) {
      Face f = faces.get(i);
      if(f.selected || f.v1.v.selected || f.v2.v.selected || f.v3.v.selected) {
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

void addFace() {  
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
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
}

void draw() {
  background(darkModeCheckbox.selected ? 0 : 192);
  ortho(-width/2, width/2, -height/2, height/2);
  
  for(Window w : windows) {
    w.draw();
    
    fill(255, 0, 0);
    text(VIEW_NAMES[w.viewType], w.x, w.y + w.h - 10);
  }
  ortho(-width/2, width/2, -height/2, height/2);
  strokeWeight(2);
  if(darkModeCheckbox.selected) {
    stroke(192, 192, 255);
  } else {
    stroke(64, 64, 128);
  }
  line(0, height / 2, width - UI_COLUMN_WIDTH, height / 2);
  line((width - UI_COLUMN_WIDTH) / 2, 0, (width - UI_COLUMN_WIDTH) / 2, height);
  
  drawUI();
  //saveFrame("test-######.tif");
}
