#!/bin/env perl

use strict;
use warnings;
use File::Basename;

die "Usage: perl calculate_F1_score.pl [benchmarking summary output(s) ...]\n" if scalar @ARGV < 1;

my %counts;
my @libName;
my @totalF1;
my @geneF1;
my @TEF1;
my $currFeature;

foreach my $infile (@ARGV){
  my $label = basename($infile, ".txt");
  $label =~ s/_comparison_summary//;
  push @libName, $label;
  open my $ifh, "<", $infile or die $!;
  while(my $line = <$ifh>){
    chomp $line;
    my @tmp = split "\t", $line;
    if($tmp[0] =~ /^Category/){
      if($tmp[0] =~ /all/){
	$currFeature = "total";
      }
      elsif($tmp[0] =~ /Gene/){
	$currFeature = "gene";
      }
      elsif($tmp[0] =~ /TE/){
	$currFeature = "TE";
      }
      else{
	die "Invalid category line\n";
      }
      next;
    }
    $counts{$currFeature}{$tmp[0]} = $tmp[1];
  }
  close $ifh or die $!;
  undef $currFeature;
  my @featureTypes = ("total","gene","TE");
  foreach my $feature (@featureTypes){
    my $F1score = calculateF1($counts{$feature}{"Exact"},
			      $counts{$feature}{"Within15pc"},
			      $counts{$feature}{"Overcount"},
			      $counts{$feature}{"Undercount"},
			      $counts{$feature}{"FalsePositive"},
			      $counts{$feature}{"FalseNegative"},
			     );
    push @totalF1, $F1score if $feature eq "total";
    push @geneF1, $F1score if $feature eq "gene";
    push @TEF1, $F1score if $feature eq "TE";
  }
}

print "FeatureType\t",join("\t",@libName), "\n";
print "Total\t",join("\t",@totalF1), "\n";
print "Genes\t",join("\t",@geneF1), "\n";
print "TE\t",join("\t",@TEF1), "\n";

sub calculateF1{
  my ($exact,$within15pc,$over,$under,$fp,$fn) = @_; 
  my $accurate = $exact + $within15pc;
  my $precision = $accurate / ($accurate + $over + $under + $fp);
  my $sensitivity = $accurate / ($accurate + $over + $under + $fn);
  my $F1 = (2 * $precision * $sensitivity) / ($precision + $sensitivity);
  return $F1;
}
