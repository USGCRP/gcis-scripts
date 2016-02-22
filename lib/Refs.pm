package Refs;

use Mojo::DOM;
use Path::Class qw/file/;
use Data::Dumper;
use strict;
use v5.14;

my %elements = (
    author           => 'contributors > authors > author > style',
    secondary_author => 'contributors > secondary-authors > author > style',
    volume           => 'volume > style',
    year             => 'dates > year > style',
    pub_dates        => 'dates > pub-dates > date > style',
    pub_location     => 'pub-location > style',
    urls             => 'urls > related-urls > url > style',
    reftype_id       => 'ref-type',
    record_number    => 'rec-number',
    title            => 'titles > title > style',
    secondary_title  => 'titles > secondary-title > style',
    pages            => 'pages > style',
    number           => 'number > style',
    isbn             => 'isbn > style',
    doi              => 'electronic-resource-num > style',
    keywords         => 'keywords > keyword > style',
    abstract         => 'abstract > style',
    notes            => 'notes > style',
    language         => 'language > style',
    publisher        => 'publisher > style',
    reftype          => sub { shift->find('ref-type')->[0]->attr('name')},
    ref_key          => 'custom4 > style',
    pub_title        => 'periodical > full-title > style', 
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
    for my $e (keys %elements) {
        my $spec = $elements{$e};
        my @found = (ref $spec eq 'CODE' ? $spec->($rec) : 
                     map $_->text, $rec->find($spec)->each);
        $data{$e} = \@found;
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

1;
