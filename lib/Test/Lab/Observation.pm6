unit class Test::Lab::Observation;

#| The experiment this observation is for
has $.experiment is readonly;

#| The instant observation began.
has Instant $.now is readonly;

#| The String name of the behavior.
has Str $.name is readonly;

#| The value returned, if any.
has $.value is readonly;

#| The raised exception, if any.
has $.exception is readonly;

#| The Rat seconds elapsed.
has $.duration is readonly;

submethod BUILD(:$!name, :$!experiment, :&block) {
  $!now = DateTime.now.Instant;
  try {
    CATCH { default { $!exception = $! } }
    $!value = &block();
  }
  $!duration = (DateTime.now.Instant - $!now)
}

#| Return a cleaned value suitable for publishing. Uses the
#| experiment's defined cleaner block to clean the observed
#| value.
method cleaned-value {
  if $!value.defined { $!experiment.clean-value($!value) }
}

method equiv-to($other, &comparator?) {
  my $values-are-equal = False;
  my $both-dead = $other.did-die and self.did-die;
  my $neither-dead = not $other.did-die and not self.did-die;

  if $neither-dead and &comparator.defined {
    $values-are-equal = &comparator($!value, $other.value);
  } else {
    $values-are-equal = $!value === $other.value;
  }

  # TODO: everywhere else: s/Exception::class/Exception::cls/
  my $exceptions-are-equivalent = $both-dead and
    $other.exception.WHAT    == $!exception.WHAT and
    $other.exception.message == $!exception.message;

  ($neither-dead and $values-are-equal) or
    ($both-dead and $exceptions-are-equivalent)
}

method hash {
  [$!value, $!exception, self.WHAT].map({ .hash }).reduce: * +^ *;
}

method did-die { $!exception.defined }
