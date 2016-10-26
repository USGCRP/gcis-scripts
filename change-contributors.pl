#!/usr/bin/env perl

=head1 NAME

change-contributors.pl -- ORNL datasets Contributor update

=head1 DESCRIPTION

Finds all datasets in GCIS with 'ornl' in the title,
removes the Contributors associated with them and
adds the single Contributor 'organization/accenture'.


=head1 SYNOPSIS

./change-contributors.pl GCIS_URL

=head1 OPTIONS

=over

=item <GCIS_URL>

The host running our GCIS instance.

=back

=head1 EXAMPLES

./change-contributors.pl "https://data-stage.globalchange.gov"

=cut

use Gcis::Client;
use Data::Dumper;
use v5.14;

my $url = $ARGV[0] or die "missing url\nUsage : $0 [url]\n";
my $c = Gcis::Client->connect(url => $url);

# We will set this to be the sole organization.
my $new_organization = "/organization/accenture";

# Set limit as desired.
my $limit = 1;


# for each dataset
my $count = 0;
for my $dataset ($c->get('/dataset', { all => 1 })) {

    # Only include those with "ornl" in the identifier"
    next unless $dataset->{identifier} =~ /ornl/;
    say "dataset : $dataset->{identifier}";

    # Get info, including existing contributors
    my $info = $c->get("/dataset/$dataset->{identifier}");

    # Delete all existing contributors
    for my $contributor (@{ $info->{contributors} } ) {
        my $id = $contributor->{id};
        $c->post("/dataset/contributors/$dataset->{identifier}",
          {
              delete_contributor => $id
          }) or die $c->error;
    }

    # Add a new one.
    $c->post("/dataset/contributors/$dataset->{identifier}", {
               role => "data_archive",
               organization_identifier => $new_organization,
        }) or die $c->error;

    # Maybe we're done?
    last if ++$count >= $limit;
}


