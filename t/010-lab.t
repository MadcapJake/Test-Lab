use v6;
use Test;
use lib 'lib';

use Test::Lab;

use-ok 'Test::Lab';

{
  my class A does Test::Lab {}
  my $a = A.new;
  my $r = $a.lab: 'test', -> $e {
    $e.use: { 'control'   }
    $e.try: { 'candidate' }
  }
  is $r, 'control', 'provides a helper to instantiate and run experiments';
}

{
  my class A does Test::Lab {}
  my $a = A.new;

  is-deeply Hash.new, $a.context, "provides an empty default context";
}

{
  my class A does Test::Lab {}
  my $a = A.new;
  $a.context.push: (:default);

  my $experiment;
  $a.lab: 'test', -> $e {
    $experiment := $e;
    $e.context :inline;
    $e.use: -> { }
  }

  ok $experiment.defined, "experiment can be bound out of a lab procedure";
  ok $experiment.context<default>, 'pre-procedure context is kept';
  ok $experiment.context<inline>, 'intra-procedure context is kept';
}

{
  my class A does Test::Lab {}
  my $a = A.new;

  my $experiment;
  my $result = $a.lab: 'test', -> $e {
    $experiment := $e;

    $e.try: -> { True  }, :name<first-way>;
    $e.try: -> { False }, :name<secnd-way>;
  }, :run<first-way>;

  ok $result, 'Runs the named test instead of the control';
}

{
  my class A does Test::Lab {}
  my $a = A.new;

  my $experiment;
  my $result = $a.lab: 'test', -> $e {
    $experiment := $e;

    $e.use: -> { True  };
    $e.try: -> { False }, :name<second-way>;
  }, :name(Nil);

  ok $result, 'Runs control when there is a Nil named test';
}

done-testing;
