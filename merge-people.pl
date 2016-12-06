#!/usr/bin/env perl

=head1 NAME

./merge-people.pl -- merge people

=head1 DESCRIPTION

Interactively merge two persons on the given GCIS instance.

=head1 SYNOPSIS

./merge-people.pl gcis_url person_id_1 person_id_2 [person_id_n]

=head1 OPTIONS

=over

=item [gcis_url]

The GCIS instance to connect to

=item [person_id]

Two or more Person IDs to merge

=back

=head1 EXAMPLES

./merge-people.pl https://data-stage.globalchange.gov 3041 2342 

=cut

use Gcis::Client 0.12;
use List::Util qw/min/;
use Data::Dumper;
use v5.16;

sub usage {
    if (my $msg = shift) { say $msg; };
    say "Usage: $0 <url> <id> <id> [<id> ]*....";
    exit;
}

# Set up
my $url = shift || usage('no url');
$url =~ /http/ or usage("bad url: $url");
my @ids = @ARGV;
usage("no ids") unless @ids;
my $gcis = Gcis::Client->connect(url => $url);

# Look up
my @people = map $gcis->get("/person/$_"), @ids;
my %seen;
@people = grep !$seen{$_->{id}}++, @people;

# Compute: save person with orcid or lowest id
my %action;
my $save = min map $_->{id}, @people;
if (my ($orc) = grep $_->{orcid}, @people) {
    $save = $orc->{id};
}
my @remove = map $_->{id}, grep { $_->{id} != $save } @people;
$action{$save} = 'save';
@action{@remove} = 'remove' x @remove;

# Announce
say "Person : $url/person/$_" for @ids;
say "-" x 80;
say sprintf('%-20s %-20s %6s %-20s %10s',qw[last_name first_name id orcid action]);
say "-" x 80;
say join "\n", map sprintf('%-20s %-20s %6d %20s %10s',@$_{qw[last_name first_name id orcid]},$action{$_->{id}}),
    sort {$a->{id} <=> $b->{id}} @people;
say "-" x 80;
unless ($save && @remove && (@people > 1)) {
    say "No merging possible.";
    exit;
}

# Confirm
say ">> press return to merge, x to abort";
chomp(my $ok = <STDIN>);
if ($ok && length($ok)) {
    say "aborting";
    exit;
}

# Go!
say "merging";
for my $person (@remove) {
    $gcis->delete("/person/$person", { replacement => "/person/$save" } );
}

say "Success, merged into $url/person/$save";

