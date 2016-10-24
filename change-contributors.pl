#!/usr/bin/env perl

=head1 NAME

[FILENAME] -- [ONE LINE DESCRIPTION]

=head1 DESCRIPTION

[FULL EXPLANATION OF THE SCRIPT. Remember to explain the
'Why' and 'How' as well as the 'What'. Make note of any
externalities, such as GCIS (very common), CrossRef.org,
IO files, etc ]


=head1 SYNOPSIS

[GENERIC SCRIPT RUN e.g.: "./FILENAME [OPTIONS] < FOO.TXT"]

=head1 OPTIONS

=over

=item <stdin>

[STDIN DESCRIPTION (if used)]

=item B<--[FOO]>

[FOO DESCRIPTION]

=item B<--BAR>

[BAR DESCRIPTION]

=item B<--verbose>

Verbose option [IF USED; HIGHLY ENCOURAGED]

=item B<--dry_run>

Dry run [IF USED; HIGHLY ENCOURAGED]

=back

=head1 EXAMPLES

[REALISTIC SCRIPT RUN e.g. `./FILENAME --foo --verbose <input.txt`]

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


