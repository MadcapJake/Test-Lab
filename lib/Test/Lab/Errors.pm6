unit module Test::Lab::Errors;

class X::BehaviorMissing is Exception is export {
  has $.experiment;
  has $.name;
  method message() { "{$!experiment.name} missing $!name behavior" }
}

class X::BehaviorNotUnique is Exception is export {
  has $.experiment is readonly;
  has $.name is readonly;
  method message { "{$.experiment.name} already has $.name behavior" }
}

class X::NoValue is Exception is export {
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
    "{$!result.candidates.map: { fmt-obs($_) }.join("\n")}\n";
  }
  sub fmt-obs($observation) {
    "{$observation.name}:\n" ~ do if $observation.is-raised {
      "  {$observation.exception.perl}\n" ~
      $observation.exception.backtrace.map({"    $_"}).join("\n")
    } else {
      "  {$observation.value.perl}"
    }
  }
}
