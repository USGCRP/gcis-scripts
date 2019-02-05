#!/usr/bin/env perl

=head1 NAME

create_generic_from_reference.pl - creates & links generic pubs to refs

=head1 SYNOPSIS

create_generic_from_reference [options]

  Options:
    --url refers to the URL of the GCIS instance.
    --max_update is the maximum number of entries to update. 
    --dry_run is a flag that indicates a dry run.
    --help provides a brief help message.

=head1 OPTIONS

=over 8

=item B<--file>

the file containing the references to generate generic publications for

=item B<--url>

the URL of the GCIS instance (default is the dev instance)

=item B<--max_update>

the maximum number of entries to update (default is 1 entry)

=item B<--dry_run>

a flag that indicates a dry run (default is to update the instance)

=item B<--help>

prints a help message and exits

=back

=head1 DESCRIPTION

B<create_generic_from_reference.pl> creates child publications of class
'generic' for reference types of nonstandard reference type classes.  The child
pubs are subsequently associcated with these references.  The program is
designed to allow users to select how many new child pubs to create, and
displays the title and UUID pertaining to each new child pub entry generated.

=cut

use v5.14;
use Gcis::Client;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use IO::File;
use strict;
binmode(STDOUT, ":utf8");

$| = 1;
my $url   = "https://data-stage.globalchange.gov";
my $reference_file;
my $max_update = 100;
my $dry_run = 0;
my $help = 0;

my $result = GetOptions (
    "url=s"          => \$url,
    "file=s"         => \$reference_file,
    "max_update=i"   => \$max_update,
    "dry_run"        => \$dry_run,
    'help|?'         => \$help
);

pod2usage(-verbose => 2) if $help;

die "Reference file required" unless $reference_file;
say " url $url";
say " max update : $max_update";
say " dry run" if $dry_run;

my $references = load_reference_file();

my $g = $dry_run ? Gcis::Client->new(    url => $url)
                 : Gcis::Client->connect(url => $url);
my $n = @$references;
say " number of  references : $n";
my $n_update = 0;
my $n_existing = 0;
my $i=0;

foreach my $ref_id (@$references) {

    my $ref = $g->get("/reference/$ref_id");
    if ($ref->{child_publication}) {
        say "Existing Ref & Pub title : $ref->{attrs}->{Title}, ref uri : $ref->{uri}, child pub uri: $ref->{child_publication}";
        $n_existing++;
        next;
    }
    $n_update++;
    last if $n_update > $max_update;

     my $generic_pub = {};
     _copy($ref, $generic_pub);

     say "Connecting Ref & Generic title : $ref->{attrs}->{Title}, uri : $ref->{uri}";

    if ($dry_run) {
        say "would have updated this reference";
        next;
    }

    my $new_pub = $g->post("/generic", $generic_pub) or error $g->error;
    connect_reference_and_child($ref, $new_pub->{uri});
}

sub connect_reference_and_child {
    my ($ref, $child_pub_uri) = @_;

    $g->post("/reference/$ref->{identifier}.json", {
        child_publication_uri => $child_pub_uri,
        identifier => $ref->{identifier},
        attrs => $ref->{attrs}}
    ) or error $g->error;
}

sub _copy {
    my ($ref, $pub) = @_;
    for my $attr ( keys %{ $ref->{attrs} } ) {
        $pub->{attrs}->{$attr} = $ref->{attrs}->{$attr};
    }

    return;
}


sub load_reference_file {
    my @references;
    my $fh = IO::File->new($reference_file, "r");
    if (defined $fh) {
        chomp(@references = <$fh>);
        $fh->close;
    }
    return \@references;
}
say "Existing References with Child Pubs: $n_existing";
say "References given Generic Child Pubs: $n_update";
say "done";

__END__

