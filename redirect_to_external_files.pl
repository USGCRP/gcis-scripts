#!/usr/bin/env perl

=head1 NAME

redirect_to_external_files.pl - redo the location of assets

=head1 DESCRIPTION

redirect_to_external_files - given a report, a location, and a new name
scheme, update the file paths for that report's assets.

=head1 SYNOPSIS

./redirect_to_external_files.pl --report="report-identifier" --location="shared-base-url" [OPTIONS]

=head1 OPTIONS

=over

=item B<--client>

The GCIS instance you would like to interact with (e.g. https://data-stage.globalchange.gov)

=item B<--location>

The base URL for the new location of the assets. WIll end up in the 'location' field
for the report's files.

=item B<--report>

The report identifier whos assets are being modified

=item B<--dry-run>

Don't actually make the DB changes, but report out what they would be.

=back

=head1 EXAMPLES

Make all of the 2016 Health Assessment assets point to the S3 buckets.

./redirect_to_external_files.pl --report="usgcrp-climate-human-health-assessment-2016" --location="https://climatehealth2016.s3.amazonaws.com/climatehealth2016/gcis-figures"

NB: Each report requires a new subfunction that knows the naming scheme of the files in their new location.

=cut

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Gcis::Exim;
use YAML;
use Data::Dumper;
use IO::File;

use strict;
use v5.14;

GetOptions(
  'client=s'   => \(my $gcis_url), 
  'report=s'   => \(my $report), 
  'location=s' => \(my $location),
  'dry-run'    => \(my $dry),
  'help|?'      => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

## Add your report file naming scheme subfunction reference here
my $file_paths = {
    'usgcrp-climate-human-health-assessment-2016' => \&health_2016,
};

my $SEP=",";
my $time = time;
my $filename = "/tmp/2016_health_renames" . $time . ".sql";
my $checker = "/tmp/2016_health_checker" . $time . ".csv";

&main;

sub main {

    die pod2usage( -msg => "You must specify a report\n", -verbose => 2) unless $report;
    die pod2usage( -msg => "You must specify a location\n", -verbose => 2) unless $location;
    say "Going to generate update locations for the report $report";
    say "New location base is: $location";
    die pod2usage( -msg => "You must create a renaming function found for '$report'\n", -verbose => 2) unless exists $file_paths->{$report};

    my $gcis_client = Gcis::Client->new(url => $gcis_url);

    my $chapters = $gcis_client->get("/report/$report/chapter") or die " no resource";

    my $fh = IO::File->new("> $filename");
    die "Bad file handle!" if ! defined $fh;
    print $fh "-- Moving all of the 2016 Health report files to point at the S3";
    my $chk_fh = IO::File->new("> $checker");
    die "Bad file handle!" if ! defined $chk_fh;
    print $chk_fh "Chapter ID$SEP File ID $SEP Current URL $SEP New URL\n";

    #say "Got chapters:";
    foreach my $chapter ( @$chapters ) {
        my $chapter_id = $chapter->{'identifier'};
        my $figures = $gcis_client->get("/report/$report/chapter/$chapter_id/figure") or die " no resource";
        if ( ! @$figures ) {
            #say "No figures for chapter $chapter_id";
            next;
        }
        #say "Figures for $chapter_id:";
        for my $figure_listed ( @$figures ) {
            my $figure_id = $figure_listed->{'identifier'};
            my $figure = $gcis_client->get("/report/$report/chapter/$chapter_id/figure/$figure_id") or die " no resource";
            #print "\tChapter >" . $figure->{'chapter'}->{'identifier'} . "<\t" .  'figure_ordinal >' . $figure->{'ordinal'} . '<';
            my $rename = health_2016(
                'chapter' => $figure->{'chapter'}->{'identifier'},
                'figure_ordinal' => $figure->{'ordinal'},
            );
            #       say "$chapter_id$SEP$rename$SEP$figure_id$SEP$figure->{'files'}->[0]->{href}";
            #say "\t# Files for figure $figure_id: " . scalar @{$figure->{files}};
            my $file_id = $figure->{files}->[0]->{identifier};
            print $chk_fh "$chapter_id$SEP$file_id$SEP$figure->{'files'}->[0]->{href}$SEP$location/$rename\n";
            print $fh "-- Chapter $chapter_id, Figure $figure_id, Existing Path: $figure->{'files'}->[0]->{file}\n";
            print $fh "-- File ID:$file_id\tNew Location:$location\tNew File ID:$rename\n";
            print $fh qq{UPDATE file SET file="$rename", location="$location" where identifier="$file_id"\n\n};

            #        say Dumper $figure_files;
        }
    }

    my $images = $gcis_client->get("/report/$report/image?all=1") or die " no resource";
    #say "Found " . scalar @$images . " for the report";
    #say Dumper $images;
    #say "Image name, Chapter ID, rename, Figure Name, Figure Ordinal, current href ";
    foreach my $image_listed ( @$images ) {
        my $image_id = $image_listed->{'identifier'};
        my $image = $gcis_client->get("/image/$image_id") or die " no resource";
        #say Dumper $image;
        my $image_files = $image->{'files'};
        for my $figure ( @{$image->{figures}} ) {
            my $chapter_id = $figure->{chapter_identifier};
            next if $chapter_id eq 'executive-summary'; # These files live in other chapters...
            my $figure_ordinal = $figure->{ordinal};
            my $rename = health_2016(
                'chapter' => $chapter_id,
                'figure_ordinal' => $figure_ordinal,
                'image'           => $image->{files}->[0]->{file},
            );
            #say "$image->{identifier}$SEP$chapter_id$SEP$rename$SEP$figure->{identifier}$SEP$figure_ordinal$SEP$image->{'files'}->[0]->{href}";
            my $file_id = $image->{files}->[0]->{identifier};
            print $chk_fh "$chapter_id$SEP$file_id$SEP$image->{'files'}->[0]->{href}$SEP$location/$rename\n";
            print $fh "-- Chapter: $chapter_id Figure: $figure->{identifier} (Ordinal $figure_ordinal) Existing Path: $image->{'files'}->[0]->{file}\n";
            print $fh "-- File ID:$file_id\tNew Location:$location\tNew File ID:$rename\n\n";
            print $fh qq{UPDATE file SET file="$rename", location="$location" where identifier="$file_id"\n};
        }
    }

    say "Printing SQL to $filename";
    say "Printing checklist to $checker";
    exit;
}

sub health_2016 {
    my ( %args ) = @_;
    my $chapter = $args{'chapter'} // die;
    my $ordinal = $args{'figure_ordinal'} // 1;
    my $image = $args{'image'};

    #say "Rename subfunction got $chapter, $ordinal, $sub_image!";
    $chapter =~ s/-/_/g;
    #say "Rename now has got $chapter, $ordinal, $sub_image!";
    my $chapter_mappings = {
        'front_matter'                                                            => 'F',
        'executive_summary'                                                       => '0',
        'climate_change_and_human_health'                                         => '1',
        'temperature_related_death_and_illness'                                   => '2',
        'air_quality_impacts'                                                     => '3',
        'extreme_events'                                                          => '4',
        'vectorborne_diseases'                                                    => '5',
        'water_related_illnesses'                                                 => '6',
        'food_safety_nutrition_and_distribution'                                  => '7',
        'mental_health_and_well_being'                                            => '8',
        'populations_of_concern'                                                  => '9',
        'appendix_1__technical_support_document'                                  => 'A1',
        'appendix_2__process_for_literature_review'                               => 'A2',
        'appendix_3__report_requirements_development_process_review_and_approval' => 'A3',
        'appendix_4__documenting_uncertainty_confidence_and_likelihood'           => 'A4',
        'appendix_5__glossary_and_acronyms'                                       => 'A5',
    };
    die "Bad Chapter! >$chapter<" if ! defined $chapter_mappings->{$chapter};

    my $rename =  "Figure-" . $chapter_mappings->{"$chapter"} . ".$ordinal";

    if ( $image ) {
        if ( $image =~ /\d+-\d+_([a-z])\.(.*)$/ ) {
             $rename .= "_$1.$2";
        }
    }
    else {
        $rename .= '.png';
    }

    return $rename;
}

1;

