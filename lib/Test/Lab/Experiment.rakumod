#| This role provides shared behavior for experiments.
#| Includers must implement C<is-enabled> and
#| C<publish(result)>.
#|
#| Override Test::Lab::Experiment.new to set your own class
#| which includes and implements Test::Lab::Experiment's
#| interface.
class Test::Lab::Experiment {

  use Test::Lab::Error;
  use Test::Lab::Observation;
  use Test::Lab::Result;

=head1 Attributes

  #| Define a sub to run before an experiment begins, if the
  #| experiment is enabled.
  #|
  #| The sub takes no arguments.
  has &.before is rw;


  #| A Hash of behavior subs, keyed by String name. Register
  #| behavior subs with the `try` and `use` methods.
  has Code %.behaviors(Str);

  #| A sub to clean an observed value for publishing or
  #| storing.
  #|
  #| The sub takes one argument, the observed value which
  #| will be cleaned.
  has &.cleaner is rw;

  #| A sub which compares two experimental values.
  #|
  #| The sub must take two arguments, the control value and a
  #| candidate value, and return true or false.
  has &.comparator is rw;

  #| A sub which compares two experimental values.
  #|
  #| The sub must take two arguments, the control Error and a
  #| candidate Error, and return true or false.
  has &.error-comparator is rw;

  has %!context;

  has Code @!ignorables;

  #| A sub that determines whether or not the experiment should run.
  has &.run-if is rw;

  #| The String name of this experiment. Default is
  #| "experiment". See Test::Lab::Default for an example
  #| of how to override this default.
  has $.name = 'experiment';


  #| Whether to die when the control and candidate mismatch.
  #| If this is Nil, $!raise-on-mismatches class attribute is
  #| used instead.
  our $raise-on-mismatches;
  has Bool $!raise-on-mismatches;

=head1 Methods

  #| Internal: Clean a value with the configured clean sub,
  #| or return the value if no clean sub is configured.
  #|
  #| Rescues and reports exceptions in the clean sub if
  #| they occur.
  method clean-value($value) {
    CATCH { default { self.thrown("clean", $_); return $value } }
    with &!cleaner { &!cleaner($value) } else { $value }
  }

  #| Adds extra experiment data to the %!context
  method context(*%ctx) {
    return %!context unless %ctx.elems > 0;
    for %ctx.kv -> $key, $data { %!context{$key} = $data }
    %!context
  }

  #| Called when an exception throws while running an
  #| internal operation, like &publish. Override this method
  #| to track these exceptions. The default implementation
  #| re-throws the exception.
  method thrown($operation, Exception $error) { die $error; }

  #| Configure this experiment to ignore an observation
  #| with the given sub.
  #|
  #| The sub takes two arguments, the control observation
  #| and the candidate observation which didn't match the
  #| control. If the sub returns true, the mismatch is
  #| disregarded.
  #|
  #| This can be called more than once with different subs
  #| to use.
  method ignore(&ignorable) { @!ignorables.push: &ignorable }

  #| Internal: ignore a mismatched observation?
  #|
  #| Iterates through the configured ignore subs and
  #| calls each of them with the given control and
  #| mismatched candidate observations.
  #|
  #| Returns true or false.
  method ignore-mismatched-obs($control, $candidate) {
    return False unless @!ignorables;
    my @ignore-map = @!ignorables.clone;
    for @ignore-map <-> $ignore {
      CATCH { default {
        self.thrown('ignore', $_); $ignore = False; next
      } }
      $ignore = $ignore($control.value, $candidate.value).so;
      last if $ignore;
    };
    @ignore-map.any.so;
  }

  #| Internal: compare two observations, using the
  #| configured compare block if present.
  method obs-are-equiv(Test::Lab::Observation $a, Test::Lab::Observation $b) {
    CATCH { default { self.thrown('compare', $_) } }
    with &.comparator       { return $a.equiv-to($b, $_) }
    with &.error-comparator { return $a.equiv-to($b, $_) }
    else                    { return $a.equiv-to($b) }
  }

  #| Internal: Run all the behaviors for this experiment, observing each and
  #| publishing the results. Return the result of the named behavior, default
  #| "control".
  method run(Str:D $name = 'control') {
    # TODO: Figure out how to model a `freeze` pattern on hashes
    my $behaviors = Map.new(%!behaviors);
    my $ctx = Map.new(%!context);
    my &block = $behaviors{$name};

    without &block {
      die X::Test::Lab::BehaviorMissing.new(:experiment(self), :name($name));
    }

    return &block() unless self.should-experiment-run;

    with &!before { $_() }

    my $result = self.generate-result($name, $behaviors);

    try {
      self.publish($result);
      CATCH { default { self.thrown('publish', $_) } }
    }

    if self.raise-on-mismatches() && $result.any-mismatched {
      die X::Test::Lab::Mismatch.new(:$!name, :result($result));
    }

    die $result.control.exception if $result.control.thrown;
    return $result.control.value;
  }

  #| Does a &!run-if sub allow the experiment to run?
  #|
  #| Rescues and reports exceptions in a run-if sub if
  #| they occur.
  method run-if-sub-allows {
    CATCH { default { self.thrown('run-if', $_); return False } }
    &!run-if.defined ?? &!run-if() !! True;
  }

  #| Determine whether or not an experiment should run.
  #|
  #| Catches and reports exceptions in the enabled method
  #| if they occur.
  method should-experiment-run returns Bool {
    CATCH { default { self.thrown('enabled', $_) } }
    %!behaviors.elems > 1 && self.is-enabled && self.run-if-sub-allows;
  }

  multi method raise-on-mismatches(Test::Lab::Experiment:U : Bool $flag?) {
    with $flag { Test::Lab::Experiment::<$raise-on-mismatches> = $flag }
    else { Test::Lab::Experiment::<$raise-on-mismatches> // False }
  }
  multi method raise-on-mismatches(Test::Lab::Experiment:D : Bool $flag?) {
    with $flag { $!raise-on-mismatches = $flag }
    else { $!raise-on-mismatches // Test::Lab::Experiment.raise-on-mismatches }
  }

  #| Register a named behavior for this experiment
  method try(&sub, :$name = "candidate") {
    if %!behaviors{$name}.defined {
      die X::Test::Lab::BehaviorNotUnique.new(:experiment(self), :$name);
    }
    %!behaviors{$name} = &sub;
  }

  #| Register the control behavior for this experiment;
  method use(&sub) { self.try: &sub, :name('control'); }

  method is-enabled { True }

  method publish($result) {  }



  method generate-result($name, $behaviors) returns Test::Lab::Result:D {
    my @observations;
 
    $behaviors.keys.pick(*).map: -> $key {
      my &block = $behaviors{$key};
      @observations.push: Test::Lab::Observation.new(
        :name($key),
        :experiment(self),
        :&block
      );
    }

    my $control = @observations.first: *.name eq $name;

    return Test::Lab::Result.new(
      :experiment(self),
      :@observations,
      :$control
    );
  }
}
