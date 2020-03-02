
Vector3f rgbToHsb(Vector3f c) {  
  Vector3f r = new Vector3f();
  float V = max(max(r.x, r.y), r.z);
  float min = min(min(r.x, r.y), r.z);
  float S = (V == 0.0) ? 0.0 : ((V - min) / V);
  float H = 0.0;
  if(V == r.x) {
    H = 60 * (c.y - c.z) / (V - min);
  } else if (V == r.y) {
    H = 60 * (2 + (c.z - c.x) / (V - min));
  } else {
    H = 60 * (4 + (c.x - c.y) / (V - min));
  }
  r.x = H;
  r.y = S;
  r.z = V;
  return r;
}

Vector3f hsvToRgb(Vector3f c) {
  Vector3f r = new Vector3f();
  if(c.y <= 0.0) {       
      r.x = c.z * 255;
      r.y = c.z * 255;
      r.z = c.z * 255;
      return r;
  }
  float hh = c.x;
  if(hh >= 360.0) hh = 0.0;
  hh /= 60.0;
  int i = (int)hh;
  float ff = hh - i;
  float p = c.z * (1.0 - c.y);
  float q = c.z * (1.0 - (c.y * ff));
  float t = c.z * (1.0 - (c.y * (1.0 - ff)));

  switch(i) {
  case 0:
      r.x = c.z * 255;
      r.y = t * 255;
      r.z = p * 255;
      break;
  case 1:
      r.x = q * 255;
      r.y = c.z * 255;
      r.z = p * 255;
      break;
  case 2:
      r.x = p * 255;
      r.y = c.z * 255;
      r.z = t * 255;
      break;
  case 3:
      r.x = p * 255;
      r.y = q * 255;
      r.z = c.z * 255;
      break;
  case 4:
      r.x = t * 255;
      r.y = p * 255;
      r.z = c.z * 255;
      break;
  case 5:
  default:
      r.x = c.z * 255;
      r.y = p * 255;
      r.z = q * 255;
      break;
  }
  return r;     
}
