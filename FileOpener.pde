
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

VertexRecord vertexHelper(String s, int startingCount, ArrayList<Vector3f> textureIndices, ArrayList<Vector3f> normals)
{
  String [] subPieces = split(s, '/');
  VertexRecord v1 = new VertexRecord(vertices.get(int(subPieces[0]) - 1 + startingCount));                                  
  if(subPieces.length > 1) {
    //Get texture index
    if(subPieces[1].length() > 0) {
      v1.setTexture(textureIndices.get(int(subPieces[1]) - 1).x, textureIndices.get(int(subPieces[1]) - 1).y);
    }
  }
  if(subPieces.length > 2) {
    //Get normal index
    if(subPieces[2].length() > 0) {
      v1.setNormal(normals.get(int(subPieces[2]) - 1).x, normals.get(int(subPieces[2]) - 1).y, normals.get(int(subPieces[2]) - 1).z);
    }
  }
  return v1;
}

void loadMaterials(String s) throws IOException {
  Material m = null;
  File f = new File(s);
  if(!f.exists()) {
    return;
  }
  Scanner scanner = new Scanner(f);
  String line = null;
  while(scanner.hasNextLine()) {
    line = scanner.nextLine();
    String[] pieces = splitTokens(line, " ");
    if(pieces.length == 0) {
      continue;
    }
    if(pieces[0].equals("newmtl")) {
      m = new Material(pieces[1]);
      println("add materials name " + m.name);
      materials.put(m.name, m);
      println("mat count = " + materials.size());
    }
    if(pieces[0].equals("Ka")) {
      m.Ka = new Vector3f(float(pieces[1]), float(pieces[2]), float(pieces[3]));
    }
    if(pieces[0].equals("Kd")) {
      m.Kd = new Vector3f(float(pieces[1]), float(pieces[2]), float(pieces[3]));
    }
    if(pieces[0].equals("Ks")) {
      m.Ks = new Vector3f(float(pieces[1]), float(pieces[2]), float(pieces[3]));
    }
    if(pieces[0].equals("map_Kd")) {
      m.texture_diffuse = loadImage(f.getParent() + "\\" + pieces[1]);      
    }
  }
  scanner.close();
  return;
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
                          } else if(extension.equals("stl")) {
                            loadBinaryStl(selectedFile);
                          } else {
                            try {
                              Scanner scanner = new Scanner(selectedFile);
                              String line = null;
                              int startingCount = vertices.size();
                              ArrayList<Vector3f> normals = new ArrayList<Vector3f>();
                              ArrayList<Vector3f> textureIndices = new ArrayList<Vector3f>();
                              Material curMaterial = null;
                              while(scanner.hasNextLine()) {
                                line = scanner.nextLine();
                                String[] pieces = splitTokens(line, " ");
                                if(pieces.length == 0) {
                                  continue;
                                }
                                if(pieces[0].equals("#")) {
                                  continue;
                                }
                                if(pieces[0].equals("o")) {
                                  //New object.  We don't support objects yet
                                }
                                if(pieces[0].equals("mtllib")) {                                  
                                  loadMaterials(selectedFile.getParent() + "\\" + pieces[1]);
                                }
                                if(pieces[0].equals("usemtl")) {
                                  curMaterial = materials.get(pieces[1]);
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
                                  
                                  normals.add(new Vector3f(x, y, z));                                  
                                } 
                                if(pieces[0].equals("vt")) {
                                  float x = float(pieces[1]);
                                  float y = float(pieces[2]);
                                  //float z = float(pieces[3]);  //There is a third, we're ignoring
                                  
                                  textureIndices.add(new Vector3f(x, y, 0));
                                } 
                                //OK this is actually wrong.  We're storing the normal and the texture index on the vertex, where as they can differ
                                //per face.  That means we're getting this wrong for some models.  We need to re-architect the data model to support this.
                                if(pieces[0].equals("f")) {
                                  if(pieces.length == 4) {
                                    VertexRecord v1 = vertexHelper(pieces[1], startingCount, textureIndices, normals);
                                    VertexRecord v2 = vertexHelper(pieces[2], startingCount, textureIndices, normals);
                                    VertexRecord v3 = vertexHelper(pieces[3], startingCount, textureIndices, normals);
                                    faces.add(new Face(v1, v2, v3, curMaterial));
                                  } else if (pieces.length == 5) {
                                    VertexRecord v1 = vertexHelper(pieces[1], startingCount, textureIndices, normals);
                                    VertexRecord v2 = vertexHelper(pieces[2], startingCount, textureIndices, normals);
                                    VertexRecord v3 = vertexHelper(pieces[3], startingCount, textureIndices, normals);
                                    VertexRecord v4 = vertexHelper(pieces[4], startingCount, textureIndices, normals);                                    
                                    faces.add(new Face(v1, v2, v3, curMaterial));
                                    faces.add(new Face(v1, v3, v4, curMaterial));
                                  }
                                }
                              }
                              println("read: " + vertices.size() + " , " + textureIndices.size() + " , " + normals.size());
                              scanner.close();
                            } catch (IOException e) {
                              print("exception " + e);
                              e.printStackTrace();
                            }   
                          }
                          resetMaterials();
                      }
                  }              
        });
}

int curNormalIndex, curTextureIndex;

String vertexRecordHelper(VertexRecord vr) {
  String result = (vertices.indexOf(vr.v) + 1) + "";
  if(vr.hasTexture) {
    result = result + "/" + (curTextureIndex + 1);
    curTextureIndex++;
  } else if (!vr.hasTexture && vr.hasNormal) {
    result = result + "/";
  }
  if(vr.hasNormal) {
    result = result + "/" + (curNormalIndex + 1);
    curNormalIndex++;
  }
  return result;
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
                      String extension = "";
                      int ie = selectedFile.getAbsolutePath().lastIndexOf('.');
                      if (ie > 0) {
                          extension = selectedFile.getAbsolutePath().substring(ie+1);
                      }
                      if(extension.equals("stl")) {
                            saveBinaryStl(selectedFile);
                      } else {
                        PrintWriter pw = createWriter(selectedFile.getAbsolutePath());
                        //Save out materials
                        if(materials.size() > 0) {
                          String s = selectedFile.getAbsolutePath();
                          int i = s.lastIndexOf('.');
                          if (i > 0) {
                            s = s.substring(0, i);                            
                          }
                          PrintWriter mpw = createWriter(s + ".mtl");
                           Iterator<Material> mv = materials.values().iterator();
    
                          while(mv.hasNext()) {
                            Material m = mv.next();
                            //println("mi = " + mi + " m = " + materials.get(mi));
                            mpw.println("newmtl " + m.name);
                            mpw.println("Ka " + m.Ka.x + " " + m.Ka.y + " " + m.Ka.z);
                            mpw.println("Kd " + m.Kd.x + " " + m.Kd.y + " " + m.Kd.z);
                            mpw.println("Ks " + m.Ks.x + " " + m.Ks.y + " " + m.Ks.z);
                            if(m.texture_diffuse != null) {
                              String imgName = s + "_" + m.name + "_diffuse.png";
                              m.texture_diffuse.save(imgName);
                              mpw.println("map_Kd " + new File(imgName).getName());
                            }
                          }
                          mpw.flush();
                          mpw.close();
                          pw.println("mtllib " + (new File(s + ".mtl")).getName());
                        }
                        for (int i = 0; i < vertices.size(); i++) {
                          Vertex v = vertices.get(i);
                          pw.println("v " + v.x + " " + v.y + " " + v.z);
                        }
                        pw.println("");
                        for (int i = faces.size()-1; i >= 0; i--) {
                          Face f = faces.get(i);
                          if(f.v1.hasNormal) {
                            pw.println("vn " + f.v1.nx + " " + f.v1.ny + " " + f.v1.nz);
                          }
                          if(f.v2.hasNormal) {
                            pw.println("vn " + f.v2.nx + " " + f.v2.ny + " " + f.v2.nz);
                          }
                          if(f.v3.hasNormal) {
                            pw.println("vn " + f.v3.nx + " " + f.v3.ny + " " + f.v3.nz);
                          }
                        }
                        pw.println("");
                        for (int i = faces.size()-1; i >= 0; i--) {
                          Face f = faces.get(i);                        
                          if(f.v1.hasTexture) {
                            pw.println("vt " + f.v1.tx + " " + f.v1.ty);
                          }
                          if(f.v2.hasTexture) {
                            pw.println("vt " + f.v2.tx + " " + f.v2.ty);
                          }
                          if(f.v3.hasTexture) {
                            pw.println("vt " + f.v3.tx + " " + f.v3.ty);
                          }
                        }
                        curNormalIndex = 0;
                        curTextureIndex = 0;
                        String curMatName = "";
                        for (int i = faces.size()-1; i >= 0; i--) {
                          Face f = faces.get(i);
                          if((f.m != null) &&
                             (!f.m.name.equals(curMatName))) {
                               curMatName = f.m.name;
                               pw.println("usemtl " + f.m.name);
                          }
                          pw.println("f " + vertexRecordHelper(f.v1) + " " + vertexRecordHelper(f.v2) + " " + vertexRecordHelper(f.v3));
                        }
                        pw.flush();
                        pw.close();
                      }
                  }
              }              
        });
}

void saveBinaryStl(File f) {
  try {
    FileOutputStream fos = new FileOutputStream(f);
    fos.write("Armas V1.0 STL Export".getBytes());
    fos.write(new byte[59]);
    ByteBuffer bb = ByteBuffer.allocate(4);
    bb.order(ByteOrder.LITTLE_ENDIAN);        
    bb.putInt(faces.size());
    fos.write(bb.array());
    for(int i = 0; i < faces.size(); ++i) {
      Face fa = faces.get(i);
      bb = ByteBuffer.allocate(50);
      bb.order(ByteOrder.LITTLE_ENDIAN);        
      bb.putFloat(fa.v1.hasNormal ? fa.v1.nx : 0.0);
      bb.putFloat(fa.v1.hasNormal ? fa.v1.ny : 0.0);
      bb.putFloat(fa.v1.hasNormal ? fa.v1.nz : 0.0);
      bb.putFloat(fa.v1.v.x);
      bb.putFloat(fa.v1.v.y);
      bb.putFloat(fa.v1.v.z);
      bb.putFloat(fa.v2.v.x);
      bb.putFloat(fa.v2.v.y);
      bb.putFloat(fa.v2.v.z);
      bb.putFloat(fa.v3.v.x);
      bb.putFloat(fa.v3.v.y);
      bb.putFloat(fa.v3.v.z);
      bb.putShort((short)0);
      fos.write(bb.array());
    }
    fos.flush();
    fos.close();
  } catch (Exception ex) {
  }
}

void loadBinaryStl(File f) {
  try {
    
    RandomAccessFile aFile = new RandomAccessFile
                (f.getAbsolutePath(), "r");
    FileChannel inChannel = aFile.getChannel();
    MappedByteBuffer buffer = inChannel.map(FileChannel.MapMode.READ_ONLY, 0, inChannel.size());
    buffer.order(ByteOrder.LITTLE_ENDIAN);
    buffer.load();
    
    byte[] header = new byte[80];
    buffer.get(header);
    
    int numTris = buffer.getInt();
    println("STL numTris = " + numTris);
    for(int i = 0; i < numTris; ++i) {
      Vector3f n = new Vector3f(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
      Vertex v1 = new Vertex(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
      Vertex v2 = new Vertex(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
      Vertex v3 = new Vertex(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
      short dummy = buffer.getShort();
      
      vertices.add(v1);
      vertices.add(v2);
      vertices.add(v3);
      
      Face fa = new Face(v1, v2, v3);
      faces.add(fa);
      fa.v1.setNormal(n.x, n.y, n.z);
      fa.v2.setNormal(n.x, n.y, n.z);
      fa.v3.setNormal(n.x, n.y, n.z);      
    }
    buffer.clear(); // do something with the data and clear/compact it.
    inChannel.close();
    aFile.close();
    } catch (Exception ex) {
  }
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
    println(boo);
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
