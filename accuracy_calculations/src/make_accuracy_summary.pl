#!/bin/env perl

use strict;
use warnings;

die "Usage: perl make_accuracy_summary.pl [results file]\n" if scalar @ARGV < 1;

my $infile = shift @ARGV;
open my $ifh, "<", $infile or die $!;

my %summary;

while(my $line = <$ifh>){
  next if $line =~ /^key/;
  chomp $line;
  my @tmp = split "\t", $line;
  my $feature;
  ($tmp[0] =~ /:TE$/) ? ($feature = "TE") : ($feature = "Gene");
  $summary{"total"}{$feature} ++;
  $summary{"total"}{"all"} ++;
  my $result = decide_result($tmp[3]);
  $summary{$result}{$feature}++;
  $summary{$result}{"all"}++;
}
close $ifh or die $!;

make_output("all");
if(defined $summary{"total"}{"Gene"}){
  make_output("Gene");
}
else{
  print "No Genes found\n";
}
if(defined $summary{"total"}{"TE"}){
  make_output("TE");
}
else{
  print "No TE found\n";
}

sub make_output{
  my $feature = shift @_;
  print "Category_($feature)\tAnalysis\tanalysis_pct\n";
  print "Exact\t";
  get_line("exact",$feature);
  print "ExactWithNoCount\t";
  get_line("NC",$feature);
  print "Within15pc\t";
  get_line("within15pc",$feature);
  print "Overcount\t";
  get_line("over",$feature);
  print "Undercount\t";
  get_line("under",$feature);
  print "FalsePositive\t";
  get_line("FP",$feature);
  print "FalseNegative\t";
  get_line("FN",$feature);
}

sub get_line{
  my $category = shift @_;
  my $grp = shift @_;
  $summary{$category}{$grp} = 0 if ! exists $summary{$category}{$grp};
  print $summary{$category}{$grp},"\t",
    sprintf("%.2f",($summary{$category}{$grp} / $summary{"total"}{$grp} * 100)), "\n";
}


sub decide_result{
  my $result = shift @_;
  return "FP" if $result eq "FP";
  return "FN" if $result eq "FN";
  return "NC" if $result eq "NC";
  return "exact" if $result == 1;
  return "over" if $result > 1.15;
  return "under" if $result < 0.85;
  return "within15pc";
}

