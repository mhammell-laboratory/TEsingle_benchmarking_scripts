#!/bin/env perl

use warnings;
use strict;

die "Usage: compare_run_to_simulated_truth.pl [ground truth + simulation results]\n" if scalar @ARGV < 1;

my $infile = shift @ARGV;
open my $ifh, "-|", "gunzip", "-cf", $infile or die $!;

my %count = ("FP" => 0,
	     "FN" => 0,
	     "exact" => 0,
	     "NC" => 0,
	     "within15pc" => 0,
	     "over" => 0,
	     "under" => 0,
	     "total" => 0,
	    );

while(my $line = <$ifh>){
  chomp $line;
  if($line =~ /^key/){
    print $line, "\tresult\n";
    next;
  }
  else{
    $count{"total"} ++;
    my $res;
    my @tmp = split "\t", $line;
    my ($bc,$annot) = split ";", $tmp[0];
    if(! defined $annot){
      $annot = $bc;
      undef $bc;
    }
    (defined $bc) ? ($tmp[0] = $bc . ";" . $annot) : ($tmp[0] = $annot);
    $tmp[1] = round($tmp[1]);
    $tmp[2] = round($tmp[2]);
    if($tmp[1] == 0){
      ($tmp[2] != 0) ? ($res = "FP") : ($res = "NC");
    }    
    else{
      ($tmp[2] == 0) ? ($res = "FN") : ($res = $tmp[2]/$tmp[1]);
    }
    print join("\t",@tmp), "\t$res\n";
#    decide_result($res);
  }
}
close $ifh or die $!;

#make_summary();

sub round{
  my $value = shift @_;
  return $value if $value == 0;
  if(($value + 0.5) == int($value + 0.5)){
      (int($value) % 2 == 1) ? ($value = int($value + 0.5)) : ($value = int($value));
  }
  else{    
      $value = int($value + 0.5) if $value != 0.5;
  }
  return $value;
}

sub make_summary{
  open my $ofh, ">", "comparison_summary.txt" or die $!;
  print {$ofh} "Category\tAnalysis\tanalysis_pct\n";
  print {$ofh} "Exact\t";
  get_line("exact");
  print {$ofh} "ExactWithNoCounts\t";
  get_line("NC");
  print {$ofh} "Within15pc\t";
  get_line("within15pc");
  print {$ofh} "Overcount\t";
  get_line("over");
  print {$ofh} "Undercount\t";
  get_line("under");
  print {$ofh} "FalsePositive\t";
  get_line("FP");
  print {$ofh} "FalseNegative\t";
  get_line("FN");
  close $ofh or die $!;
}

sub get_line{
  my $category = shift @_;
#  print {$ofh} $count{$category},"\t",
#    sprintf("%.2f",($count{$category} / $count{"total"} * 100)), "\n";
}

sub decide_result{
  my $result = shift @_;
  if($result eq "FP"){
    $count{"FP"} ++;
  }
  elsif($result eq "FN"){
    $count{"FN"} ++;
  }
  elsif($result eq "NC"){
    $count{"NC"} ++;
  }
  elsif($result == 1){
    $count{"exact"} ++;
    }
  elsif($result > 1.15){
    $count{"over"} ++;
  }
  elsif($result < 0.85){
    $count{"under"} ++;
  }
  else{
    $count{"within15pc"} ++;
  }
}
