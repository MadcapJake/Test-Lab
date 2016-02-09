use v6;
use Test;
use lib 'lib';

use Test::Lab;

use-ok 'Test::Lab';

class A does Test::Lab {}
my $a = A.new;
my $r = $a.lab: 'test', -> $e {
  $e.use: { 'control' }
  $e.try: { 'candidate' }
}
is $r, 'control', 'provides a helper to isntantiate and run experiments';

done-testing;
