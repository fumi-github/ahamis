#!/usr/bin/env perl

use strict;
use warnings;

### genotype patterns given manually
#         S   P   S   S   S   W   WGlaW   W   1pW9P   P   WWky
# my $outf = 'SHR_WKYexclGla_vs_SP_WKYGla';
# my $p1 = '0/0 1/1 0/0 0/0 0/0 0/0 1/1 0/0 0/0 1/1 1/1 1/1 0/0';
# my $outf = 'SHR_WKYGla_vs_SP_WKYexclGla';
# my $p1 = '0/0 1/1 0/0 0/0 0/0 1/1 0/0 1/1 1/1 1/1 1/1 1/1 1/1';
# my $outf = 'SHR_WKYexclWky_vs_SP_WKYWky';
# my $p1 = '0/0 1/1 0/0 0/0 0/0 0/0 0/0 0/0 0/0 1/1 1/1 1/1 1/1';
# my $outf = 'SHR_WKYWky_vs_SP_WKYexclWky';
# my $p1 = '0/0 1/1 0/0 0/0 0/0 1/1 1/1 1/1 1/1 1/1 1/1 1/1 0/0';
my $outf = 'SHR_SPexcl1pW9_vs_SP1pW9_WKY';
my $p1 = '0/0 0/0 0/0 0/0 0/0 1/1 1/1 1/1 1/1 1/1 0/0 0/0 1/1';
$outf = 'WKYvariants13.minGQ10_minDP4.maskhetgenotype.max-missing-count0.genotype.' .
    $outf;

### genotype pattern given by command argument
if (my $pattern = shift) {
    $outf = $pattern;
    $pattern =~ s/(\d)/$1\/$1/g;
    $pattern =~ s/_/ /g;
    $p1 = $pattern; # 0 1
}


open OUT, '>', $outf;

my $p2 = $p1; $p2 =~ s/0/z/g; $p2 =~ s/1/0/g; $p2 =~ s/z/1/g; # 1 0
my $p3 = $p2; $p3 =~ s/1/2/g;                                 # 2 0
my $p4 = $p3; $p4 =~ s/0/1/g;                                 # 2 1
my $p5 = $p4; $p5 =~ s/1/o/g; $p5 =~ s/2/1/g; $p5 =~ s/o/2/g; # 1 2
my $p6 = $p5; $p6 =~ s/1/0/g;                                 # 0 2
my @ps = ($p1, $p2, $p3, $p4, $p5, $p6);

while (<>) {
  chomp;
  my @a = split(/\t/);
  my $chrom = $a[0];
  my $pos = $a[1];
  splice(@a, 0, 9);
  my @genotypes = ();
  foreach (@a) {
      /^([^:]*):/;
      push @genotypes, $1;
  }
  my $k = join(" ", @genotypes);
  if (grep(/^${k}$/, @ps)) {
      print OUT "$chrom\t$pos\n";
  }
}
close OUT;
