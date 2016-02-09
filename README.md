# :microscope: Test::Lab

A port of Github's [Scientist](https://github.com/github/scientist) to Perl 6.

```perl6fe
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
