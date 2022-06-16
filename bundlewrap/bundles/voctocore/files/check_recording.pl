#!/usr/bin/env perl

use v5.14;
use warnings;

use File::Find;

my $threshold = 60;

my $okay = 0;
my $delta_okay;
my $name_okay;

sub test {
        my $name = $File::Find::name;

        return unless -f $name;
        return unless $name =~ /\.(dv|ts)/i;

        my $mtime = (stat($name))[9];

        my $delta = time - $mtime;

        if($delta < $threshold) {
                $okay = 1;
                $delta_okay = $delta;
                $name_okay = $name;
        }
}

{
        no warnings;
        find({no_chdir => 1, wanted => \&test}, $ARGV[0]);
}

if($okay) {
        say "OK delta is $delta_okay (current file: $name_okay)";
        exit 0;
} else {
        say "CRITICAL no recordings for more than $threshold seconds";
        exit 2;
}
