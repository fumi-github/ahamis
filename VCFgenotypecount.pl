#!/usr/bin/env perl

use strict;
use warnings;

my %count = ();
while (<>) {
  chomp;
  my @a = split(/\t/);
  splice(@a, 0, 9);
  my @genotypes = ();
  foreach (@a) {
      /^([^:]*):/;
      push @genotypes, $1;
  }
  my $k = join(" ", @genotypes);

  if (exists $count{$k}) {
    $count{$k}++;
  } else {
    $count{$k} = 1;
  }
}
foreach my $k (sort(keys %count)) {
  print "$k $count{$k}\n";
}
