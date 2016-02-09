use v6;
use Test;
use lib 'lib';

use Test::Lab::Experiment;

class Fake is Test::Lab::Experiment {
  has $.published-result;
  has @!exceptions;
  method exceptions { @!exceptions }
  method died($op, $exception) {
    @!exceptions.push: ($op, $exception);
  }
  method is-enabled { True }
  method publish($result) {
    $.published-result = $result;
  }
}
my $ex = Fake.new();

subtest {
  my $ex = Test::Lab::Experiment.new('hello');
  isa-ok $ex, Test::Lab::Experiment, 'uses builtin defaults';
  is $ex.name, "hello", "default name properly set";
}, 'has a default implementation';

is Fake.new.name, "experiment", "properly defaults to 'experiment'";

subtest {
  plan 2;

  my class A is Test::Lab::Experiment {
    method new($name = 'experiment') {
      Test::Lab::Experiment.bless(:$name)
    }
  }
  my $a = A.new;

  try {
    CATCH { when X::StubCode { pass "is-enabled is a stub" }
            default { flunk "Caught the wrong error" } }
    $a.is-enabled;
    flunk "No error was thrown"
  }

  try {
    CATCH { when X::StubCode { pass "publish is a stub" }
            default { flunk "Caught the wrong error" } }
    $a.publish('result');
    flunk "No error was thrown"
  }

}, 'requires includers to implement «is-enabled» and «publish»';

subtest {
  plan 2;
  try {
    $ex.run;
    CATCH {
      when X::BehaviorMissing {
        pass 'properly throws BehaviorMissing exception';
        is 'control', $_.name, 'the missing behavior is the control';
      }
    }
  }
}, "can't be run without a control behavior";

subtest {
  $ex.use: { 'control' }
  is 'control', $ex.run;
}, 'is a straight pass-through with only a control behavior';

done-testing;
