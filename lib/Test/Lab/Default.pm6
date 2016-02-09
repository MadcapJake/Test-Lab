class Test::Lab::Experiment { ... }

class Test::Lab::Experiment::Default is Test::Lab::Experiment {
  method is-enabled { True }
  method publish($result) { }
}
