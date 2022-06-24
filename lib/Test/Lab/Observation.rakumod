unit class Test::Lab::Observation;

#| The experiment this observation is for
has $.experiment is readonly;

#| The instant observation began.
has Instant $.now is readonly;

#| The String name of the behavior.
has Str $.name is readonly;

#| The value returned, if any.
has $.value is readonly;

#| The thrown exception, if any.
has $.exception is readonly;

#| The Rat seconds elapsed.
has $.duration is readonly;

submethod BUILD(:$!name, :$!experiment, :&block) {
  $!now = DateTime.now.Instant;
  try {
    CATCH { default { $!exception = $_ } }
    $!value = &block();
  }
  $!duration = (DateTime.now.Instant - $!now)
}

#| Return a cleaned value suitable for publishing. Uses the
#| experiment's defined cleaner block to clean the observed
#| value.
method cleaned-value { with $!value { $!experiment.clean-value($_) } }

#| Is this observation equivalent to another?
#|
#| other            - the other Observation in question
#| comparator       - an optional comparison block. This observation's value and the
#|                    other observation's value are passed to this to determine
#|                    their equivalency. Block should return true/false.
#| error_comparator - an optional comparison block. This observation's Error and the
#|                    other observation's Error are passed to this to determine
#|                    their equivalency. Block should return true/false.
#|
#| Returns true if:
#|
#| * The values of the observation are equal (using `==`)
#| * The values of the observations are equal according to a comparison
#|   block, if given
#| * The exceptions thrown by the obeservations are equal according to the
#|   error comparison block, if given.
#| * Both observations thrown an exception with the same class and message.
#|
#| Returns false otherwise.
method equiv-to($other, &comparator?, &error-comparator?) returns Bool {
  return False unless $other ~~ Test::Lab::Observation:D;

  if self.thrown or $other.thrown {
    with &error-comparator { return &error-comparator($!exception, $other.exception) }
    else {
      return ((.WHAT, .message) with $other.exception) eqv ($!exception.WHAT, $!exception.message);
    }
  }

  with &comparator { &comparator($!value, $other.value) }
  else { $!value === $other.value }
}

method hash {
  [$!value, $!exception, self.WHAT].map({ .hash }).reduce: * +^ *;
}

method thrown { $!exception.defined }