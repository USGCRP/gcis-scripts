#!/usr/bin/env perl

=head1 NAME

=head1 SYNOPSIS

./set-country-on-organizations.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item <stdin>

List of uri/country pairs to add (comma separated, one per line)
   Note: use "#" at start of line to denote a commment (not deleted)

=item B<--max_update>

Max update (defaults to 10, to process all set to -1)

=item B<--dry_run> or B<--n>

Dry run

=back

=head1 EXAMPLES

# add a set of countries from a list

./set-country-on-organizations.pl -u http://data-stage.globalchange.gov < country_list.txt

=cut

use Gcis::Client;
use Getopt::Long qw/GetOptions/;
use Pod::Usage;
use Data::Dumper;
use strict;
use v5.14;

GetOptions(
    'url=s'         => \(my $url),
    'max_updates=i' => \(my $max_updates = 10),
    'dry_run|n'     => \(my $dry_run),
    'help|?'        => sub { pod2usage(verbose => 2) },
) or die pos2usage(verbose => 1);

pod2usage(msg => "missing url", verbose => 1) unless $url;

{
    my $a = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    my $n_processed = 0;
    say " adding countries";
    say "     url : $url";
    say "     max_updates : $max_updates";
    say "     dry run" if $dry_run;

    while (<>) {
       last if $max_updates <= $n_processed;
       chomp;
       my ($uri, $country_code) = split ",";
       if (!($uri =~ /^\//)) { 
           $uri = "/".$uri;
       }
       say " uri : $uri";
       say "     - country $country_code";
       if ($uri =~ /^# /) {
           say "     - skipping uri";
           next;
       }
       my $f = $uri;
       $f =~ s[/organization/][/organization/form/update/];
       say $f;
       my $r = $a->get($f);
       say Dumper $r;
       if (!$r) {
           say "     - does not exist";
           $n_processed++;  
           next;
       }
       if ($r->{country_code}) {
           if ($r->{country_code} eq $country_code) {
               say "     - country_code already set to $country_code, skipping.";
               $n_processed++;  
               next;
           } else {
               say "     - country_code had value $r->{country_code}, replacing.";
           }
       } else {
           say "     - country_code had no value, setting.";
       }
       if ($dry_run) {
           say "     - would add country_code $country_code, but dry run";
           $n_processed++;
           next;
       }
       else {
           say "not dry run";
           exit;
       }
       $r->{country_code} = $country_code;
       $a->post($uri, $r) or 
           say "     ** update error **";
       say  "     - added country_code";
       next if $max_updates == -1;
       $n_processed++;  
    }
    say " done";
}

1;

