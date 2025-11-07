#!/bin/env perl

use strict;
use warnings;

die "Usage: process_scTE_results.pl [scTE csv]\n" if scalar @ARGV < 1;

my $infile = shift @ARGV;
open my $ifh, "<", $infile or die $!;

my @annotations;
while(my $line = <$ifh>){
  chomp $line;
  if($line =~ /^barcodes/){
    @annotations = split ",", $line;
    shift @annotations;
    next;
  }
  my @tmp = split ",", $line;
  my $bc = shift @tmp;
  $bc .= "-1" if $bc !~ /-1$/;
  for(my $x = 0; $x < scalar @tmp; $x ++){
    print "$bc;$annotations[$x]\t$tmp[$x]\n" if $tmp[$x] > 0;
  }
}
close $ifh or die $!;

  
