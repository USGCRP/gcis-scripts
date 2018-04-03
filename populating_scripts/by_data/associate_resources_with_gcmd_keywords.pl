#!/usr/bin/env perl

=head1 NAME

associate_resources_with_gcmd_keywords.pl

=head1 SYNOPSIS

./associate_resources_with_gcmd_keywords.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--input>

CSV containing the GCIS URIs, GCIS Type, and GCMD UUIDs to connect

=item B<--max_update>

Max update (defaults to 10, to process all set to -1)

=item B<--dry_run>

Dry run

=back

=head1 EXAMPLES

./associate_resources_with_gcmd_keywords.pl \
  --url http://data-stage.globalchange.gov \
  --input nca4_resource_gcmds.csv

=cut

use Gcis::Client;
use Getopt::Long qw/GetOptions/;
use Pod::Usage;
use Data::Dumper;
use strict;
use v5.14;

GetOptions(
    'url=s'         => \(my $url),
    'input=s'       => \(my $input),
    'max_updates=i' => \(my $max_updates = -1),
    'dry_run|n'     => \(my $dry_run),
    'help|?'        => sub { pod2usage(verbose => 2) },
) or die pos2usage(verbose => 1);

pod2usage(msg => "missing url", verbose => 1) unless $url;
pod2usage(msg => "missing input", verbose => 1) unless $input;

{
    my $gcis = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    # TODO add code to open the CSV file and parse the contents

    my $n_processed = 0;
    say " Associating Resources with GCMD Keywords";
    say "     url : $url";
    say "     input : $input";
    say "     max_updates : $max_updates";
    say "     dry run" if $dry_run;

    while (<>) {
       # Check if max updates reached
       if ($max_updates != -1) {
           last if $max_updates <= $n_processed;
       }

       # testing code
       chomp;
       my $country_code;
       my ($uri, $gcmd, $type) = split ",";
       if (!($uri =~ /^\//)) { 
           $uri = "/".$uri;
       }
       say " uri : $uri";
       say "     - GCMD Keyword $gcmd";
       say "     - type $type";

       # Confirm resource exists
       my $result = $gcis->get("$uri?with_gcmd=1");
       if (!$result) {
           say "     - does not exist";
           $n_processed++;  
           next;
       }

       # Check if GCMD already Associated with Resource
       my $skip = 0;
       foreach my $existing_keyword (@{$result->{gcmd_keywords}}){
           if ($existing_keyword->{identifier} eq $gcmd) {
               say "     - GCMD Keyword  $gcmd already set, skipping.";
               $n_processed++;  
               $skip = 1;
               last;
           }
       }
       next if ( $skip );
       say "     - URI not associated with GCMD keyword, setting.";

       # Apply the keyword to resource
       if ($dry_run) {
           say "     - would associate GCMD $gcmd with URI, but dry run";
           $n_processed++;
           next;
       }

       my $rel_update = $uri;
       $rel_update =~ s[/$type/][/$type/rel/];
       # TODO set the update content
       my $updated_rel = { new_gcmd_keyword => $gcmd };
       $gcis->post($rel_update, $updated_rel) or 
           say "     ** update error **";
       say  "     - added GCMD relationship";
       $n_processed++;  
    }
    say " done";
}

1;

