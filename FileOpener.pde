
import java.awt.*;
import java.io.*;
import java.nio.*;
import java.nio.channels.*;
import java.util.Scanner;
import javax.swing.*;

class MyFileChooser extends JFileChooser {
    protected JDialog createDialog(Component parent) throws HeadlessException {
        final JDialog dialog = super.createDialog(parent);
        dialog.setAlwaysOnTop(true);        
        new java.util.Timer().schedule( 
        new java.util.TimerTask() {
            @Override
            public void run() {
              dialog.toFront();
            }
          }, 
          100 
        );
        return dialog;
    }
}

void openFile(final PApplet p) {
  EventQueue.invokeLater(new Runnable() {
            @Override
            public void run() {
              try {
                    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
                } catch (Exception ex) {
                }
                MyFileChooser chooser = new MyFileChooser();
                      if (chooser.showOpenDialog(((PSurfaceJOGL)p.getSurface()).getComponent()) == JFileChooser.APPROVE_OPTION) {
                          // do something
                          File selectedFile = chooser.getSelectedFile();
                          String extension = "";

                          int i = selectedFile.getAbsolutePath().lastIndexOf('.');
                          if (i > 0) {
                              extension = selectedFile.getAbsolutePath().substring(i+1);
                          }
                          if(extension.equals("fbx")) {
                            loadFbx(selectedFile);
                          } else {
                            try {
                              Scanner scanner = new Scanner(selectedFile);
                              String line = null;
                              int startingCount = vertices.size();
                              int curNormalIndex = 0;
                              while(scanner.hasNextLine()) {
                                line = scanner.nextLine();
                                String[] pieces = splitTokens(line, " ");
                                if(pieces.length == 0) {
                                  continue;
                                }
                                if(pieces[0].equals("#")) {
                                  continue;
                                }
                                if(pieces[0].equals("v")) {
                                  float x = float(pieces[1]);
                                  float y = float(pieces[2]);
                                  float z = float(pieces[3]);
                                  
                                  Vertex v = new Vertex(x, y, z);
                                  vertices.add(v);
                                } 
                                if(pieces[0].equals("vn")) {
                                  float x = float(pieces[1]);
                                  float y = float(pieces[2]);
                                  float z = float(pieces[3]);
                                  
                                  vertices.get(curNormalIndex).setNormal(x, y, z);
                                  curNormalIndex++;
                                } 
                                if(pieces[0].equals("f")) {
                                  if(pieces.length == 4) {
                                    String [] subPieces = split(pieces[1], '/');
                                    Vertex v1 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    subPieces = split(pieces[2], '/');
                                    Vertex v2 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    subPieces = split(pieces[3], '/');
                                    Vertex v3 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    
                                    faces.add(new Face(v1, v2, v3));
                                  } else if (pieces.length == 5) {
                                    String [] subPieces = split(pieces[1], '/');
                                    Vertex v1 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    subPieces = split(pieces[2], '/');
                                    Vertex v2 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    subPieces = split(pieces[3], '/');
                                    Vertex v3 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    subPieces = split(pieces[4], '/');
                                    Vertex v4 = vertices.get(int(subPieces[0]) - 1 + startingCount);
                                    
                                    faces.add(new Face(v1, v2, v3));
                                    faces.add(new Face(v1, v3, v4));
                                  }
                                }
                              }
                              scanner.close();
                            } catch (IOException e) {
                              print("exception " + e);
                              e.printStackTrace();
                            }   
                          }
                      }
                  }              
        });
}

void saveFile(final PApplet p) {
  EventQueue.invokeLater(new Runnable() {
            @Override
            public void run() {
                try {
                    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
                } catch (Exception ex) {
                }
                MyFileChooser chooser = new MyFileChooser();
                      if (chooser.showSaveDialog(((PSurfaceJOGL)p.getSurface()).getComponent()) == JFileChooser.APPROVE_OPTION) {
                          // do something
                          File selectedFile = chooser.getSelectedFile();
                          PrintWriter pw = createWriter(selectedFile.getAbsolutePath());
                          for (int i = 0; i < vertices.size(); i++) {
                            Vertex v = vertices.get(i);
                            pw.println("v " + v.x + " " + v.y + " " + v.z);
                          }
                          pw.println("");
                          for (int i = faces.size()-1; i >= 0; i--) {
                            Face f = faces.get(i);
                            pw.println("f " + (vertices.indexOf(f.v1) + 1) + " " + (vertices.indexOf(f.v2) + 1) + " " + (vertices.indexOf(f.v3) + 1));
                          }
                          pw.flush();
                          pw.close();
                      }
                  }              
        });
}

void loadFbx(File f) {
  try {
    RandomAccessFile aFile = new RandomAccessFile
                (f.getAbsolutePath(), "r");
    FileChannel inChannel = aFile.getChannel();
    MappedByteBuffer buffer = inChannel.map(FileChannel.MapMode.READ_ONLY, 0, inChannel.size());
    buffer.order(ByteOrder.LITTLE_ENDIAN);
    buffer.load();  
    
    byte[] header = new byte[23];
    buffer.get(header);
    int version = buffer.getInt();
    println("FBX version = " + version);
        
    fbxReadNode(buffer);
    
    buffer.clear(); // do something with the data and clear/compact it.
    inChannel.close();
    aFile.close();
  } catch (Exception ex) {
  }
}

void fbxReadNode(ByteBuffer b) throws IOException {
  println("NODE");
  int endOffset = b.getInt();
  int numProperties = b.getInt();
  int propertyListLen = b.getInt();
  int nameLen = b.get();
  byte[] name = new byte[nameLen];
  b.get(name);
  println("endOffset = " + endOffset);
  println("numProperties = " + numProperties);
  println("propertyListLen = " + propertyListLen);
  println("nameLen = " + nameLen);
  println("name = " + new String(name));
  for(int i = 0; i < numProperties; i++) {
    fbxReadProperty(b);
  }
  if(b.position() < endOffset) {
    fbxReadNode(b);
  }
}

void fbxReadProperty(ByteBuffer b) throws IOException {
  char propertyType = b.getChar();
  println(propertyType);
  if(propertyType == 'Y') {
    short s = b.getShort();
    println(s);
  } else if (propertyType == 'C') {
    boolean boo = (b.getChar() != 0);
    println(b);
  } else if (propertyType == 'I') {
    int i = b.getInt();
    println(i);
  } else if (propertyType == 'F') {
    float f = b.getFloat();
    println(f);
  } else if (propertyType == 'D') {
    double d = b.getDouble();
    println(d);
  } else if (propertyType == 'L') {
    long l = b.getLong();
    println(l);
  }
}