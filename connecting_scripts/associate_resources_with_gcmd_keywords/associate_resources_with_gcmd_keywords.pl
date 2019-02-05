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
use Text::CSV;

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

    my $input_lines = intake_csv();
    my $n_processed = 0;
    say "Associating Resources with GCMD Keywords";
    say "     url : $url";
    say "     input : $input";
    say "     max_updates : $max_updates";
    say "     dry run" if $dry_run;
    say "-----------------------------------------";

    foreach my $row (@$input_lines) {
       say "-----------------------------------------";
       # Check if max updates reached
       if ($max_updates != -1) {
           last if $max_updates <= $n_processed;
       }

       my $uri = $row->{"GCIS URI"};
       my $gcmd = $row->{"GCMD Keyword UUID"};
       my $type = $row->{"Entity Type"};

       #skip empty lines
       next unless $uri;

       say " uri : $uri";
       say "     - GCMD Keyword $gcmd";
       say "     - type $type";
       say "     - notes $row->{Notes}" if $row->{Notes};

       # Confirm resource and gcmd exist
       my $result = $gcis->get("$uri?with_gcmd=1");
       my $gcmd_exists = $gcis->get("/gcmd_keyword/$gcmd");
       if (!$result) {
           say "     - URI does not exist";
           $n_processed++;
           next;
       }
       if (!$gcmd_exists) {
           say "     - GCMD does not exist";
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

       # Apply the keyword to resource
       say "     - URI not associated with GCMD keyword, setting.";
       if ($dry_run) {
           say "     - would associate GCMD $gcmd with URI, but dry run";
           $n_processed++;
           next;
       }

       my $rel_update = $result->{uri};
       $rel_update =~ s[/$type/][/$type/rel/];
       my $updated_rel = { new_gcmd_keyword => $gcmd };
       $gcis->post($rel_update, $updated_rel);
       say  "     - added GCMD relationship";
       $n_processed++;
    }
    say " done";
}

sub intake_csv {
    my @rows;
    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                    or die "Cannot use CSV: ".Text::CSV->error_diag ();
    open my $fh, "<:encoding(utf8)", $input or die "$input $!";
    while ( my $row = $csv->getline( $fh ) ) {
        push @rows, $row;
    }
    $csv->eof or $csv->error_diag();
    close $fh;

    my $required_columns = [ 'GCIS URI', 'GCMD Keyword UUID', 'Entity Type' ];
    my $columns = shift @rows;
    unless ( isSubset($required_columns,$columns) ) {
        say "BAD INPUT CSV: Input requires all columns in: " . join(", ", @$required_columns);
        exit;
    }
    say "Found Columns: " . join(", ", @$columns);
    my @input_lines;
    for my $row ( @rows ) {
        my %entry;
        my $index = 0;
        for my $col ( @$columns ) {
            $entry{$col} = $row->[$index];
            $index++;
        }
        push @input_lines, \%entry;
    }
    #say Dumper \@input_lines;
    return \@input_lines;
}

sub isSubset {
    my ($littleSet, $bigSet) = @_;
    my %hash;
    undef @hash{@$littleSet};  # add a hash key for each element of @$littleSet
    delete @hash{@$bigSet};    # remove all keys for elements of @$bigSet
    return !%hash;             # return false if any keys are left in the hash
}

1;

