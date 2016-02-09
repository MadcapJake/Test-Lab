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
