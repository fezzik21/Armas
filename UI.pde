
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
  fill(255, 255, 255);
  rect(width - UI_COLUMN_WIDTH, 0, width, height);
  for (int i = elements.size()-1; i >= 0; i--) {
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
  
  void update() {}
  void drawIfVisible() {
    if(visible) {
      draw();
    }
  }
  void draw() {}
}

class Label extends UIElement {
  String t;
  
  Label(String tIn, int yIn) {
    y = yIn;
    t = tIn;
    elements.add(this);
  }
  
  void draw() {
    fill(0, 0, 0);    
    text(t, width - UI_COLUMN_WIDTH + 5, y, UI_COLUMN_WIDTH, 20);
  }
}

class Line extends UIElement {
  Line(int yIn) {
    y = yIn;
    elements.add(this);
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
    elements.add(this);
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
      fill(192, 192, 192);
    } else {
      fill(128, 128, 128);
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

class TextBox extends UIElement {
  int w, h;
  String t;
  String label;
  public boolean focused;
  Thunk valueUpdated;
  int caretPos;
  TextBox(String tIn, String labelIn, int xIn, int yIn, int wIn, int hIn, Thunk valueUpdatedIn) {
    x = xIn; y = yIn; w = wIn; h = hIn;
    t = tIn;
    label = labelIn;
    caretPos = 0;
    elements.add(this);
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
    if(visible && focused && wasKeyPressed && !isKeyPressed) {
      if(keyCode == TAB) {
        int i = elements.indexOf(this);
        if(i < (elements.size() - 1)) {
          UIElement uie = elements.get(i + 1);
          if(uie instanceof TextBox) {
            ((TextBox)uie).focused = true;
          }
        }
        valueUpdated.apply();
        focused = false;
      } else if ((keyCode == ENTER) || (keyCode == ESC)) {
        valueUpdated.apply();
        focused = false;
      } else if (keyCode == LEFT) {
        if(caretPos > 0) caretPos--;
      } else if (keyCode == RIGHT) {
        if(caretPos < t.length()) caretPos++;
      } else if(keyCode == BACKSPACE) {
        if((caretPos == t.length()) && (caretPos > 0)) {
          t = t.substring(0, max(0, t.length()-1));
        } else if(caretPos > 0) {
          t = t.substring(0, caretPos - 1) + t.substring(caretPos, t.length());
        }        
        caretPos--;
      } else {
        if(caretPos == t.length()) {
          t = t + key;
        } else {
          t = t.substring(0, caretPos) + key + t.substring(caretPos, t.length());
        }
        caretPos++;
      }
    }
  }
}
