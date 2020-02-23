
HashMap<String, Thunk> commands = new HashMap<String, Thunk> ();


void executeCommand() {
  String c = commandBox.t;
  println("'" + c + "'");
  Thunk t = commands.get(c);
  if(t != null) {
    println("go");
    t.apply();
  }
  commandBox.caretPos = 0;
  commandBox.t = "";
}


void registerCommands() {
  registerCommand("randompoints", new Thunk() { @Override public void apply() { randomPoints(); } } );
}

void registerCommand(String s, Thunk t) {
  commands.put(s, t);
}

void randomPoints() {
  for(int i = 0; i < 100; ++i) {
    makeVertex(random(0.0, 1.0), random(0.0, 1.0), random(0.0, 1.0));
  }
}
