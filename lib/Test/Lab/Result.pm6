#| The immutable result of running an experiment
unit class Test::Lab::Result;

#| An array of candidate Observations.
has @!candidates;

#| The control Observation to which the rest are compared.
has $!control;

#| An Experiment.
has $!experiment;

#| An array of observations which didn't match the control,
#| but where ignored.
has @!ignored;

#| An array of observations which didn't make the control.
has @!mismatched;

#| An array of observations in execution order.
has @!observations;

submethod BUILD(:$!experiment, :@!observations, :$!control) {
  @!candidates = gather {
    @!observations.map({ if $_ !=== $!control { take $_ } })
  }
  self.evaluate-candidates;
}

#| The experiment's context
method context { $!experiment.context }

#| The name of the experiment
method experiment-name { $!experiment.name }

#| Was the result a match between all behaviors?
method is-matched { @!mismatched.elems == 0 && self.any-ignored }

#| Were there mismatches in the behaviors?
method any-mismatched { @!mismatched.any }

#| Where there any ignored mismatches?
method any-ignored { @!ignored.any }

#| Evaluate the candidates to find mismatched and
#| ignored resuls.
#|
#| Sets @!ignored and @!mismatched with the ignored
#| and mismatched candidates.
method evaluate-candidates {
  my @ms = gather {
    for @!candidates {
      if not $!experiment.obs-are-equiv($!control, $_) { take $_ }
    }
  }
  for @ms {
    if $!experiment.ignore-mismatched-obs($!control, $_) { @!ignored.push: $_ }
    else { @!mismatched.push: $_ }
  }
}
