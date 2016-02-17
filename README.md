# :microscope: Test::Lab

Careful refactoring of critical paths. A port of Github's [Scientist](https://github.com/github/scientist) to Perl 6.

## How do I start a lab?
Use the lab sub to build a default experiment for you:

```perl6
use Test::Lab;

class MyWidget {
  method is-allowed($user) {
    lab 'widget-permissions', -> $e {
      $e.use: { $!model.check-user($user).is-valid } # old way
      $e.try: { $user.can('read', $!model) } # new way
    }
  }
}
```

Use the `Test::Lab::Experiment` class to instantiate a default experiment:
```perl6
use Test::Lab::Experiment;

class MyWidget {
  method allows($user) {
    my $experiment = Test::Lab::Experiment.new("widget-permissions");
    $experiment.use: { $!model.check-user($user).is-valid } # old way
    $experiment.try: { $user.can :$!model :read } # new way

    $experiment.run;
  }
}
```
