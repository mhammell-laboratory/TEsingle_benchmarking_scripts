#!/bin/env perl

use strict;
use warnings;

die "Usage: perl process_MATES_output.pl [MATES TE_MTX.csv]\n" if scalar @ARGV < 1;

my $infile = shift @ARGV;
open my $ifh, "<", $infile or die $!;
my @libnames;
while(my $line = <$ifh>){
  chomp $line;
  if($line =~ /^,/){
    @libnames = split ",", $line;
  }
  else{
    my @tmp = split ",", $line;
    next if $tmp[0] =~ /-rich/;
    next if $tmp[0] =~ /^\(/;
    for(my $x = 1; $x < scalar @tmp; $x ++){
      next if $tmp[$x] =~ /^$/;
      next if $tmp[$x] == 0;
      print $libnames[$x], "-1;", $tmp[0], ":TE\t", $tmp[$x], "\n";
    }
  }
}
close $ifh or die $!;
