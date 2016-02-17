use v6;
use lib 'lib';

use Test::Lab;
use Test::Lab::Experiment;

class PartitionExperiment is Test::Lab::Experiment {
  method is-enabled { True }
  method publish($result) {
    say $result.control.name ~ "\t" ~ $result.control.duration;
    for $result.candidates.sort({ $^a.name cmp $^b.name }) {
      say $_.name ~ "\t" ~ $_.duration
    }
  }
  method new($name) { PartitionExperiment.bless(:$name) }
}

Test::Lab::<$experiment-class> = PartitionExperiment;

my @ls = 'a'..'e';
my @parts;
lab 'head-tail-partitions', -> $e {
  $e.use: {
    @parts = (
      (('a'), ('b', 'c', 'd', 'e')),
      (('a', 'b'), ('c', 'd', 'e')),
      (('a', 'b', 'c'), ('d', 'e')),
      (('a', 'b', 'c', 'd'), ('e'))
    )
  }
  $e.try: {
    @parts = (@ls[^$_, $_..*] for 1..^@ls)
  }, :name<a>;
  $e.try: {
    @parts = (1..^@ls).map: {@ls[^$_, $_..*]}
  }, :name<b>;
  $e.try: {
    @parts = (@ls.rotor($_, ∞, :partial) for 1..^@ls)
  }, :name<c>;
  $e.try: {
    @parts = @ls[0..*-2].keys.map: {@ls[0..$_, $_^..*]} # same as b
  }, :name<d>;
  $e.try: {
    @parts = (1..^@ls).map: {@ls.rotor: $_, ∞, :partial}
  }, :name<e>;
  $e.try: {
    @parts = (@ls.head($_), @ls.tail(@ls - $_) for 1..^@ls)
  }, :name<f>;
  $e.try: {
    @parts = (|@ls.rotor: $_, @ls - $_ for 1..^@ls).rotor: 2
  }, :name<g>;
  $e.try: {
    @parts = @ls.keys.map: {@ls[0..$_, $_^..*] if $_ < @ls.end}
  }, :name<h>;
  $e.try: {
    @parts = @ls.keys.map: {@ls.head($_), @ls.tail(@ls - $_) if $_}
  }, :name<i>;
  $e.try: {
    @parts = @ls.rotor(|(1..^@ls Z (@ls-1…0) »=>» -@ls), ∞).rotor: 2
  }, :name<j>;
  $e.try: {
    @parts = ([\,] @ls) Z (([\,] @ls[1..*].reverse)».reverse).reverse
  }, :name<k>;
}

=begin Result
control	0.00202569
a	0.0078597
b	0.0108403
c	0.002460
d	0.0078202
e	0.0025787
f	0.00251268
g	0.00915744
h	0.0084628
i	0.0029928
j	0.0144855
k	0.0061237
=end Result
