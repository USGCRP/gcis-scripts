package Refs;

use Mojo::DOM;
use Path::Class qw/file/;
use Data::Dumper;
use strict;
use v5.14;

my %multi_element_names = (
    author                     => 'Author',
    title                      => 'Title',
    abstract                   => 'Abstract',
    secondary_author           => 'Secondary Author',
    tertiary_author            => 'Tertiary Author',
    translated_author          => 'Translated Author',
    subsidiary_author          => 'Subsidiary Author',
    keywords                   => 'Keywords',
    pub_dates                  => 'Date',
    urls                       => 'URL',
    #copyright_dates            => 'Copyright Dates',
    #web_urls                   => 'Web URL',
    #pdf_urls                   => 'Pdf URL',
    #text_urls                  => 'Text URL',
    #image_urls                 => 'Image URL',
);

my %singular_element_names = (
    reftype_id                 => '.reference_type',
    record_number              => '_record_number',
    reftype                    => 'reftype',
    author_address             => 'Author Address',
    #author_affiliation         => 'Author Affiliation',
    secondary_title            => 'Secondary Title',
    tertiary_title             => 'Tertiary Title',
    alt_title                  => 'Alternate Title',
    short_title                => 'Short Title',
    translated_title           => 'Translated Title',
    #periodical_title           => 'Periodical Title',
    #periodical_abbr_1          => 'Periodical Abbreviation 1',
    #periodical_abbr_2          => 'Periodical Abbreviation 2',
    #periodical_abbr_3          => 'Periodical Abbreviation 3',
    pages                      => 'Pages',
    volume                     => 'Volume',
    number                     => 'Number',
    #issue                      => 'Issue',
    #secondary_volume           => 'Secondary Volume',
    #secondary_issue            => 'Secondary Issue',
    num_volumes                => 'Number of Volumes',
    edition                    => 'Edition',
    section                    => 'Section',
    reprint_edition            => 'Reprint Edition',
    year                       => 'Year',
    pub_location               => 'Place Published',
    publisher                  => 'Publisher',
    original_publication       => 'Original Publication',
    isbn                       => 'ISBN/ISSN',
    accession_number           => 'Accession Number',
    call_number                => 'Call Number',
    #report_id                  => 'Report Id',
    #coden                      => 'Coden',
    doi                        => 'DOI',
    label                      => 'Label',
    #image                      => 'Image',
    caption                    => 'Caption',
    notes                      => 'Notes',
    research_notes             => 'Research Notes',
    work_type                  => 'Type of Work',
    reviewed_item              => 'Reviewed Item',
    #availability               => 'Availability',
    #remote_source              => 'Remote Source',
    #meeting_place              => 'Meeting Place',
    #work_location              => 'Work Location',
    #work_extent                => 'Work Extent',
    #pack_method                => 'Pack Method',
    #size                       => 'Size',
    #repro_ratio                => 'Repro Ratio',
    remote_database_name       => 'Name of Database',
    remote_database_provider   => 'Database Provider',
    language                   => 'Language',
    custom1                    => 'Custom 1',
    custom2                    => 'Custom 2',
    custom3                    => 'Custom 3',
    ref_key                    => '_uuid',
    custom5                    => 'Custom 5',
    custom6                    => 'Custom 6',
    custom7                    => 'Custom 7',
    custom8                    => 'Custom 8',
    #misc1                      => 'Misc 1',
    #misc2                      => 'Misc 2',
    #misc3                      => 'Misc 3',
);

my %elements = (
    reftype_id                 => 'ref-type',
    record_number              => 'rec-number',
    reftype                    => sub { shift->find('ref-type')->[0]->attr('name')},

    author                     => 'contributors > authors > author > style',
    secondary_author           => 'contributors > secondary-authors > author > style',
    tertiary_author            => 'contributors > tertiary-authors > author > style',
    translated_author          => 'contributors > translated-authors > author > style',
    subsidiary_author          => 'contributors > subsidiary-authors > author > style',
    author_address             => 'auth-address > style',
    #author_affiliation         => 'auth-affiliation > style',

    title                      => 'titles > title > style',
    secondary_title            => 'titles > secondary-title > style',
    tertiary_title             => 'titles > tertiary-title > style',
    alt_title                  => 'titles > alt-title > style',
    short_title                => 'titles > short-title > style',
    translated_title           => 'titles > translated-title > style',

    #periodical_title           => 'periodical > full-title > style',
    #periodical_abbr_1          => 'periodical > abbr-1 > style',
    #periodical_abbr_2          => 'periodical > abbr-2 > style',
    #periodical_abbr_3          => 'periodical > abbr-3 > style',

    pages                      => 'pages > style',

    volume                     => 'volume > style',
    number                     => 'number > style',
    #issue                      => 'issue  > style',
    #secondary_volume           => 'secondary-volume > style',
    #secondary_issue            => 'secondary-issue > style',
    num_volumes                => 'num-vols > style',
    edition                    => 'edition  > style',
    section                    => 'section  > style',
    reprint_edition            => 'reprint-edition  > style',

    keywords                   => 'keywords > keyword > style',

    year                       => 'dates > year > style',
    pub_dates                  => 'dates > pub-dates > date > style',
    #copyright_dates            => 'dates > copyright-dates > date > style',

    pub_location               => 'pub-location > style',
    publisher                  => 'publisher > style',
    original_publication       => 'orig-pub > style',

    isbn                       => 'isbn > style',
    accession_number           => 'accession-num > style',
    call_number                => 'call-num > style',
    #report_id                  => 'report-id > style',
    #coden                      => 'coden > style',
    doi                        => 'electronic-resource-num > style',

    abstract                   => 'abstract > style',
    label                      => 'label > style',
    #image                      => 'image > name',
    caption                    => 'caption > style',
    notes                      => 'notes > style',
    research_notes             => 'research-notes > style',

    work_type                  => 'work-type > style',
    reviewed_item              => 'reviewed-item > style',
    #availability               => 'availability > style',
    #remote_source              => 'remote-source > style',
    #meeting_place              => 'meeting-place > style',
    #work_location              => 'work-location > style',
    #work_extent                => 'work-extent > style',
    #pack_method                => 'pack-method > style',
    #size                       => 'size > style',
    #repro_ratio                => 'repro-ratio > style',
    remote_database_name       => 'remote-database-name > style',
    remote_database_provider   => 'remote-database-provider > style',
    language                   => 'language > style',

    urls                       => 'urls > related-urls > url > style',
    #web_urls                   => 'urls > web-urls > url > style',
    #pdf_urls                   => 'urls > pdf-urls > url > style',
    #text_urls                  => 'urls > text-urls > url > style',
    #image_urls                 => 'urls > image-urls > url > style',

    custom1                    => 'custom1 > style',
    custom2                    => 'custom2 > style',
    custom3                    => 'custom3 > style',
    ref_key                    => 'custom4 > style',
    custom5                    => 'custom5 > style',
    custom6                    => 'custom6 > style',
    custom7                    => 'custom7 > style',
    custom8                    => 'custom8 > style',
    #misc1                      => 'misc1 > style',
    #misc2                      => 'misc2 > style',
    #misc3                      => 'misc3 > style',
);

sub new {
    my $class = shift;
    my $s;
    my $s->{records};
    my $s->{n_max} = -1;
    bless $s, $class;
    return $s;
}

sub load {
    my $s = shift;
    my $file = shift;
    -e $file or die "$file : $!";
    my $c = file($file)->slurp(iomode => '<:encoding(UTF-8)');
    my $dom = Mojo::DOM->new->xml(1)->parse($c);
    $s->{dom} = $dom;
    my $i = 0;
    for my $rec ($s->{dom}->find('record')->each) {
        # say " rec :\n".Dumper($rec) unless $i != 0;
        push @{ $s->{records} }, $s->_parse_record($rec);
        $i++;
        if ($s->{n_max} > 0 && $i >= $s->{n_max}) {
            warn " only reading $s->{n_max} records";
            last;
        }
    }
    return $s;
}

sub _parse_record {
    my $s = shift;
    my $rec = shift;
    my %data;
    for (keys %elements) {
        my $spec = $elements{$_};
        my @found = (ref $spec eq 'CODE' ? $spec->($rec) : 
                     map $_->text, $rec->find($spec)->each);
        next unless @found;
        $data{$_} = \@found;
    }
    s/,(\S)/, $1/ for @{ $data{author} };
    return \%data;
}

sub type_counts {
    my $s = shift;
    return $s->{type_counts} if $s->{type_counts};
    my %types;
    for my $record (@{ $s->{records} }) {
        my $type = $record->{reftype}->[0];
        $types{$type}++;
    }
    $s->{type_counts} = \%types;
    return $s->{type_counts};
}

sub types {
    return keys %{ shift->type_counts };
}

sub counts {
    my $s = shift;
    my $type = shift;
    return $s->type_counts->{$type};
}

sub multi_element {
    my $s = shift;
    my $key = shift;
    return defined $multi_element_names{$key};
}

sub single_element {
    my $s = shift;
    my $key = shift;
    return defined $singular_element_names{$key};
}

sub element_names {
    my %element_names = (%singular_element_names, %multi_element_names);
    return \%element_names;
}

1;
