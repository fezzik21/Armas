
ArrayList<UIElement> elements = new ArrayList<UIElement>();
boolean isMousePressed = false;
boolean isKeyPressed = false;
boolean wasMousePressed = false;
boolean wasKeyPressed = false;

boolean uiTakesKeyInput() {
  for (int i = elements.size()-1; i >= 0; i--) {
    UIElement e = elements.get(i);
    if(e instanceof TextBox) {
      TextBox tb = (TextBox)e;
      if(tb.focused) {
        return true;
      }
    }
  }
  return false;
}

boolean uiTakesMouseInput() {
  for (int i = elements.size()-1; i >= 0; i--) {
    UIElement e = elements.get(i);
    if(e instanceof ColorPicker) {
      ColorPicker cp = (ColorPicker)e;
      if(cp.takesMouseInput()) {
        return true;
      }
    }
  }
  return false;
}

void updateUI() {
  while(true) {
    isMousePressed = mousePressed;
    isKeyPressed = keyPressed; 
    for (int i = elements.size()-1; i >= 0; i--) {
        UIElement e = elements.get(i);
        e.update();
    }
    wasMousePressed = isMousePressed;
    wasKeyPressed = isKeyPressed;
  }
}

void drawUI() {
  hint(DISABLE_OPTIMIZED_STROKE);
  fill(255, 255, 255);
  rect(width - UI_COLUMN_WIDTH, 0, width, height);
  for (int i = 0; i < elements.size(); i++) {
      UIElement e = elements.get(i);
      e.drawIfVisible();
  }      
}

void resizeUI(float oldW, float oldH, float newW, float newH) {
  for (int i = elements.size()-1; i >= 0; i--) {
     UIElement e = elements.get(i);
     e.x += (newW - oldW);
     if(e.anchorBottom) {
       e.y += (newH - oldH);
     }
  }
}

public interface Thunk { void apply(); }
public interface ThunkString { void apply(String s); }

class UIElement {
  int x, y;
  public boolean visible = true;  
  public boolean anchorBottom = false;
  
  UIElement() {  
    elements.add(this);
  }
  UIElement(UIGroup g) {    
    elements.add(this);
    if(g != null) {
      g.add(this);
    }
  }
  
  void setVisible(boolean b) {
    visible = b;
  }
  void update() {}
  void drawIfVisible() {
    if(visible) {
      draw();
    }
  }
  void draw() {}
}

class UIGroup extends UIElement {
  private ArrayList<UIElement> elements = new ArrayList<UIElement>();
  
  UIGroup() {}
  UIGroup(UIGroup g) {
    super(g);
  }
  
  void add(UIElement e) {
    elements.add(e);
  }
  
  void setVisible(boolean b) {
    for (int i = elements.size()-1; i >= 0; i--) {
     UIElement e = elements.get(i);
     e.setVisible(b);
    }
  }
}

class Label extends UIElement {
  String t;
  
  Label(String tIn, int yIn, UIGroup g) {
    super(g);
    y = yIn;
    t = tIn;
  }
  
  void draw() {
    fill(0, 0, 0);    
    text(t, width - UI_COLUMN_WIDTH + 5, y, UI_COLUMN_WIDTH, 20);
  }
}

class Line extends UIElement {
  Line(int yIn, UIGroup g) {
    super(g);
    y = yIn;
  }
  
  void draw() {
    stroke(0, 0, 0);
    strokeWeight(2.0);
    line(width - UI_COLUMN_WIDTH, y, width, y);
  }
}

class Button extends UIElement {
  int w, h;
  String t, tip;
  boolean highlight = false;
  Thunk onClick;
  boolean isCheckbox;
  public boolean selected;
  String group;
  
  Button(String tIn, String tipIn, boolean isCheckboxIn, String groupIn, int xIn, int yIn, int wIn, int hIn, Thunk onClickIn) {
    x = xIn; y = yIn; w = wIn; h = hIn;
    t = tIn;
    tip = tipIn;
    onClick = onClickIn;
    isCheckbox = isCheckboxIn;
    group = groupIn;
    selected = false;
  }
  
  void apply() {
    onClick.apply();
    if(isCheckbox) {
      selected = !selected;
    } else if(group != null) {
      for (int i = elements.size()-1; i >= 0; i--) {
        UIElement e = elements.get(i);
        if(e instanceof Button) {
          Button b = (Button)e;
          if((b.group != null) && b.group.equals(group)) {
            b.selected = false;
          }
        }
      }
      selected = true;
    }
  }
  
  void update() {
    if((mouseX > x) && (mouseX < x + w) && (mouseY > y) && (mouseY < y + h)) {
      highlight = true;
      if(wasMousePressed && !isMousePressed) {
        apply();
      }
    } else {
      highlight = false;
    }
    if(!uiTakesKeyInput() && wasKeyPressed && !isKeyPressed && (key == tip.charAt(0))) {
      apply();
    }
  }
    
  void draw() {
    if(highlight) {
      fill(220, 220, 220);
    } else {
      fill(192, 192, 192);
    }
    stroke(0, 0, 0);
    rect(x, y, w, h);
    if(selected) {
      fill(255, 255, 255);
    } else {
      fill(0, 0, 0);
    }
    textAlign(CENTER, CENTER);
    text(t, x, y, w, h);
    textAlign(LEFT, TOP);
    text(tip, x + 1, y + 1, w, h);
    
  }
}

boolean contains(float x, float y, float w, float h) {
  return ((mouseX > x) && (mouseX < (x + w)) && (mouseY > y) && (mouseY < (y + h)));
}

class VectorEditor extends UIGroup {
  TextBox x, y, z;
  ColorPicker cp;
  Thunk thunk;
  
  VectorEditor(String t1, String t2, String t3, boolean showZ, boolean useColorPickerIn, int xStart, int yStart, Thunk thunkIn, UIGroup group) {
    super(group);
    thunk = thunkIn;
    x = new TextBox("", t1, xStart, yStart, 63, 25, thunkIn, this );
    y = new TextBox("", t2, xStart + 73, yStart, 63, 25, thunkIn, this );
    if(showZ) {
      z = new TextBox("", t3, xStart + 73 + 73, yStart, 63, 25, thunkIn, this );
    }
    if(useColorPickerIn) { 
      cp = new ColorPicker(xStart - 150, yStart, 255, 0, 0, new Thunk() { @Override public void apply() { x.t = String.valueOf(cp.r / 255.0); y.t = String.valueOf(cp.g / 255.0); z.t = String.valueOf(cp.b / 255.0); thunk.apply(); } }, this);
      cp.visible = false;
    }
  }
  
  void update() {
    if(contains(x.x + 73 + 73 + 35, x.y - 12, 35, 10)) {
      if(wasMousePressed && !isMousePressed) {
        cp.visible = true;
      }      
    }
  }
  void draw() {
    if(cp != null) {
      stroke(255, 255, 255);
      fill(float(x.t) * 255, float(y.t) * 255, float(z.t) * 255);
      rect(x.x + 73 + 73 + 35, x.y - 12, 35, 10);
    }
  }
  
  void setVisible(boolean b) {
    this.visible = b;
    x.setVisible(b);
    y.setVisible(b);
    if(z != null) {
      z.setVisible(b);
    }
    return;
  }
  
  void updateText(Vector3f v) {
    x.t = String.valueOf(v.x);
    y.t = String.valueOf(v.y);
    if(z != null) {
      z.t = String.valueOf(v.z);
    }
  }
  
  void updateValues(Vector3f v) {
    v.x = float(x.t);
    v.y = float(y.t);
    if(z != null) {
      v.z = float(z.t);
    }
  }
}

class DropDownList extends UIElement {
  int w, h;
  ArrayList<String> options;
  int selectedOption;
  boolean open;
  Thunk valueChanged;
  
  DropDownList(ArrayList<String> optionsIn, int xIn, int yIn, int wIn, int hIn, Thunk valueChangedIn, UIGroup group) {
    super(group);
    x = xIn; y = yIn;
    w = wIn;
    h = hIn;
    options = optionsIn;
    open = false;
    valueChanged = valueChangedIn;
    selectedOption = 0;
  }
  
  void update() {
    if((mouseX > x) && (mouseX < x + w) && (mouseY > y) && (mouseY < y + h)) {
      if(wasMousePressed && !isMousePressed) {
        open = !open;
      }      
    } else if (open &&
               (mouseX > (x + 10)) && (mouseX < (x + w - 10)) &&
               (mouseY > (y + h)) && (mouseY < (y + h + options.size() * h))) {
      if(wasMousePressed && !isMousePressed) {        
        selectedOption = (mouseY - (y + h)) / h;
        open = false;
        valueChanged.apply();
      }
    } else {
      if(wasMousePressed && !isMousePressed) {
        open = false;
      }
    }
  }
  
  void draw() {
    fill(255, 255, 255);
    stroke(0, 0, 0);
    rect(x, y, w, h);
    fill(0, 0, 0);
    textAlign(LEFT, CENTER);
    if(selectedOption < options.size()) {
      text(options.get(selectedOption), x + 2, y, w, h);
    }
    triangle(x + w - 10, y + 5,
             x + w - 4, y + 5,
             x + w - 7, y + 11);
    if(open) {
      fill(255, 255, 255);
      rect(x + 10, y + h, w - 10, options.size() * h);
      fill(0, 0, 0);
      for(int i = 0 ; i < options.size(); ++i) {
        text(options.get(i), x + 12, y + h + i * h, w - 10, h);
      }
    }
  }
}

class ColorPicker extends UIElement {
  Thunk valueUpdated;
  float hue;
  float saturation;
  float value;
  float r, g, b;
  
  ColorPicker(int xIn, int yIn, int rIn, int gIn, int bIn, Thunk valueUpdatedIn, UIGroup group) {
    super(group);
    x = xIn; y = yIn;
    if(y + 160 > height) {
      y = height - 160;
    }
    r = rIn; g = gIn; b = bIn;
    valueUpdated = valueUpdatedIn;
    hue = 120.0;
    saturation = 0.5;
    value = 0.5;
  }
  
  
  boolean takesMouseInput() {
    return (visible &&
       contains(x, y , 130, 160));
  }
  
  void update() {
    if(visible) {
      if(contains(x + 10, y + 5, 100, 150)) { 
        if(isMousePressed) {
          Vector3f hsv = new Vector3f(hue, (mouseX - (x + 10)) / 100.0, (mouseY - (y + 5)) * (1.0 / 150.0));
          Vector3f rgb = hsvToRgb(hsv);
          saturation = (mouseX - (x + 10)) / 100.0;
          value = (mouseY - (y + 5)) * (1.0 / 150.0);
          r = rgb.x;
          g = rgb.y;
          b = rgb.z;
          valueUpdated.apply();
        }
      }
      if(contains(x + 115, y + 5, 10, 100)) {   
        if(isMousePressed) { 
          Vector3f hsv = new Vector3f((mouseY - (y + 5)) * (360.0 / 100.0), saturation, value);
          Vector3f rgb = hsvToRgb(hsv);
          hue = (mouseY - (y + 5)) * (360.0 / 100.0);
          r = rgb.x;
          g = rgb.y;
          b = rgb.z;
          valueUpdated.apply();
        }
      }
      if(contains(x + 115, y + 145, 15, 15)) {  
        if(wasMousePressed && !isMousePressed) {  
          visible = false;
        }
      }
    }
  }
  
  void draw() {
    fill(128, 128, 128);
    stroke(255, 255, 255);
    rect(x, y, 130, 160);
    //colorMode(HSB, 100);
    for (int s = 0; s < 100; s++) {
      for(int v = 0; v < 150; v++) {
        Vector3f hsv = new Vector3f(hue, s / 100.0, v / 150.0);
        Vector3f rgb = hsvToRgb(hsv);
        set(x + 10 + s, y + 5 + v, color(rgb.x, rgb.y, rgb.z));        
      }
    }
    for(int h = 0; h < 100; h++) {
      for(int xh = 0; xh < 10; xh++) {
        Vector3f hsv = new Vector3f(h * (360.0 / 100.0), 1.0, 1.0);
        Vector3f rgb = hsvToRgb(hsv);
        set(x + 115 + xh, y + 5 + h, color(rgb.x, rgb.y, rgb.z));
      }
    }
    fill(255, 255, 255);
    stroke(0, 0, 0);
    circle(x + 121, y + 151, 12);
    line(x + 118, y + 148, x + 124, y + 154);
    line(x + 118, y + 154, x + 124, y + 148);
    //colorMode(RGB, 255);
  }
}

class TextBox extends UIElement {
  int w, h;
  String t;
  String label;
  public boolean focused;
  Thunk valueUpdated;
  int caretPos;
  
  TextBox(String tIn, String labelIn, int xIn, int yIn, int wIn, int hIn, Thunk valueUpdatedIn, UIGroup group) {
    super(group);
    x = xIn; y = yIn; w = wIn; h = hIn;
    t = tIn;
    label = labelIn;
    caretPos = 0;
    focused = false;
    valueUpdated = valueUpdatedIn;
  }
  
  void draw() {
    fill(192, 128, 128);
    stroke(0, 0, 0);
    rect(x, y, w, h);
    
    fill(0, 0, 0);
    textAlign(LEFT, CENTER);
    text(label, x, y - 22, w, h);
    text(t, x + 2, y, w, h);
    if(visible && focused && (frameCount % 8 < 4)) {
      float c = 0;
      if(caretPos <= t.length()) {
        c = textWidth(t.substring(0, caretPos));
      }
      if(c < w - 4) {
        text("_", x + 2 + c, y, w, h);
      }
    }
  }
  
  void update() {
    if(wasMousePressed && !isMousePressed) {
       if(visible && (mouseX > x) && (mouseX < x + w) && (mouseY > y) && (mouseY < y + h)) {
         focused = true;
         caretPos = t.length();
       } else {
         if(focused) {
          valueUpdated.apply();
         }
         focused = false;
       }
    }
    if(visible && focused) {
      for(int k = 0; k < 1024; k++) {
        if(keyDown[k] && !lastKeyDown[k]) {
          if((k != ENTER) && (k != BACKSPACE)) {
            if(caretPos == t.length()) {
              t = t + key;
            } else {
              t = t.substring(0, caretPos) + key + t.substring(caretPos, t.length());
            }
            keyDown[k] = false;
            caretPos++;
          }
        }
        if(keyCodeDown[k] && !lastKeyCodeDown[k]) {
          if(k == TAB) {
            int i = elements.indexOf(this);
            if(i < (elements.size() - 1)) {
              UIElement uie = elements.get(i + 1);
              if(uie instanceof TextBox) {
                ((TextBox)uie).focused = true;
              }
            }
            valueUpdated.apply();
            keyCodeDown[k] = false;
            focused = false;
            
          } else if ((k == ENTER) || (k == ESC)) {
            valueUpdated.apply();
            keyCodeDown[k] = false;
            focused = false;
          } else if (k == LEFT) {
            if(caretPos > 0) caretPos--;
            keyCodeDown[k] = false;
          } else if (k == RIGHT) {
            if(caretPos < t.length()) caretPos++;
            keyCodeDown[k] = false;
          } else if(k == BACKSPACE) {
            if((caretPos == t.length()) && (caretPos > 0)) {
              t = t.substring(0, max(0, t.length()-1));
              caretPos--;
            } else if(caretPos > 0) {
              t = t.substring(0, caretPos - 1) + t.substring(caretPos, t.length());
              caretPos--;
            }        
            keyCodeDown[k] = false;
          }
        }
      }
    }
  }
}
