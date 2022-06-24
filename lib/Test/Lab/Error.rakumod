unit module Test::Lab::Error;

role X::Test::Lab::BadBehavior is Exception is export {
  has $.experiment;
  has $.name;
  method message { ... }
}

class X::Test::Lab::BehaviorMissing does X::Test::Lab::BadBehavior is export {
  method message { "{$.experiment.name} missing $.name behavior" }
}

class X::Test::Lab::BehaviorNotUnique does X::Test::Lab::BadBehavior is export {
  method message { "{$.experiment.name} already has $.name behavior" }
}

class X::Test::Lab::NoValue does X::Test::Lab::BadBehavior is export {
  has $.observation is readonly;
  method message { "{$!observation.name} didn't return a value" }
}

#| A mismatch, dies when $!throw-on-mismatches is enabled.
class X::Test::Lab::Mismatch is Exception is export {
  has $.name is readonly;
  has $.result is readonly;
  method message { "experiment $!name observations mismatched" }
  method Str {
    "{self.message}:\n" ~
    "{fmt-obs($!result.control)}\n" ~
    (fmt-obs($_) for $!result.candidates).join("\n") ~
    "\n";
  }
  sub fmt-obs($observation) {
    "{$observation.name}:\n" ~ do if $observation.thrown {
      "  {$observation.exception.perl}\n" ~
      $observation.exception.backtrace.Str.lines.map({"    $_"}).join("\n")
    } else {
      "  {$observation.value.perl}"
    }
  }
}
