package Exim;

use Gcis::Client;
use strict;
use Data::Dumper;
use YAML::XS;
use v5.14;
use Encode;
use Clone::PP qw(clone);
use utf8;

$YAML::XS::Indent = 2;  # this does not work for YAML::XS

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';

my @item_list = qw(
    reports
    chapters
    figures
    images
    tables
    arrays
    findings
    references
    publications
    journals
    activities
    datasets
    contributors
    people
    organizations
    files
    );

my @has_parents = qw(
    figures
    images
    tables
    arrays
    findings
    publications
    journals
    datasets
    );

my @publication_types = qw(
    article
    book
    generic
    report
    webpage
    );

my @has_relatives = (qw(
    report
    figure
    image
    table
    array
    finding
    journal
    dataset
    ),
    @publication_types);

my @common_ignore_src_items = qw(
    cited_by
    contributor_uris
    file_uris
    parents
    references
    );

my @common_ignore_dst_items = qw(
    cited_by
    contributors
    files
    parents
    references
    );

my $compare_say_same = 0;  # turns on full output (same as well as differences)

sub extract_type_from_uri {
    my $s = shift;
    my $uri = shift;
    my $type;

    $uri = "/$uri" unless $uri =~ m[^/];
    $uri = "$uri/" unless $uri =~ m[/$];
    my @split_uri = split('/', $uri);
    ## Check for a wildcard type
    return 'article' if $split_uri[1] eq 'article';

    # even split means we have a group URI, take the last non-blank item
    if ( scalar @split_uri % 2 == 0 ) {
        return $split_uri[-1];
    }
    # specific URI, take the second to last non-blank item
    else {
        return $split_uri[-2];
    }
}

sub _update_item_href {
    my $s = shift;
    my $v = shift;
    my $subtype = shift;

    my $base = quotemeta $s->{base};
    $v->{href} =~ s[//.*:.*@][//];
    $v->{href} =~ s/^$base/base:/;
    delete $v->{href} if !$v->{href}  ||  $v->{href} =~ /^base:/;
    return 0 unless $subtype;

    return 0 unless $v->{$subtype};
    ref $v->{$subtype} eq 'ARRAY' or die "must be an array : $subtype";
    
    for (@{ $v->{$subtype} }) {
        $_->{href} =~ s/^$base/base:/;
        delete $_->{href} if !$_->{href} ||  $_->{href} =~ /^base:/;
    }

    return 0;
}

sub update_href {
    my $s = shift;
    my $type = shift;
    my $subtype = shift;

    for (keys %{ $s->{$type} }) {
        $s->_update_item_href($s->{$type}->{$_}, $subtype);
    }
    return 0;
}

sub compare_hash {
    my $s = shift;
    my $a = shift;
    my $b = shift;

    my %v;
    for my $k (keys %$a) {
        next unless defined $a->{$k};
        next if defined $b->{$k};
        $v{$k} = 'src_only';
    }
    for my $k (keys %$b) {
        next unless defined $b->{$k};
        next if defined $a->{$k};
        $v{$k} = 'dst_only';

    }

    my @common_keys = grep defined $b->{$_}, keys %$a;
    for my $k (@common_keys) {

        if (ref $a->{$k} eq 'ARRAY') {
            ref $b->{$k} eq 'ARRAY' or 
                $v{$k} = 'diff - src array, dst not';
            my $comp = $s->_compare_array($k, $a->{$k}, $b->{$k});
            $v{$k} = $comp if $comp;
            next;
        } elsif (ref $b->{$k} eq 'ARRAY') {
            $v{$k} = 'diff - dst array, src not';
            next;
        }

        if (ref $a->{$k} eq 'HASH') {
            ref $b->{$k} eq 'HASH' or
                $v{$k} = 'diff - src hash, dst not';
            my $comp = $s->compare_hash($a->{$k}, $b->{$k});
            $v{$k} = $comp if $comp;
            next;
        } elsif (ref $b->{$k} eq 'HASH') {
            $v{$k} = 'diff - dst hash, src not';
            next;
        }

        if ($a->{$k} ne $b->{$k}) { 
            $v{$k} = {diff => {src => $a->{$k}, dst => $b->{$k}}};
        } else {
            $v{$k} = 'same' if $compare_say_same;
        }
    }

    return %v ? \%v : 0;
}

sub _compare_array {
    my $s = shift;
    my $array = shift;
    my $a = shift;
    my $b = shift;

    my @v;
    my $n_a = @$a;
    my $n_b = @$b;
    return 0 if ($n_a == 0 && $n_b == 0);

    my %id_list = (
        chapters => 'uri',
        figures => 'uri',
        tables => 'uri',
        arrays => 'uri',
        findings => 'uri',
        references => 'uri',
        files => 'uri',
        publications => '',
        articles => 'uri',
        chapter_uris => '',
        figure_uris => '',
        image_uris => '',
        table_uris => '',
        array_uris => '',
        finding_uris => '',
        file_uris => '',
        contributor_uris => '',
        publication_maps => 'activity_identifier',
        parents => 'label',
        aliases => '', 
        contributors => 'id',
        sub_publication_uris => '',
        kindred_figures => '',
        rows => '',
        children => 'id', 
        instrument_measurements => 'instrument_identifier', 
    );

    exists $id_list{$array} or die "unknown array type : $array";
    my $id = $id_list{$array};
    if ($id) {
        my %a_objs;
        my %b_objs;
        if ($array ne 'publication_maps') {
            %a_objs = map {$_->{$id} => $_} @{ $a };
            %b_objs = map {$_->{$id} => $_} @{ $b };
        } else {
            %a_objs = map {$_->{$id}."|".$_->{parent_uri}."|".$_->{child_uri} 
                           => $_} @{ $a };
            %b_objs = map {$_->{$id}."|".$_->{parent_uri}."|".$_->{child_uri} 
                           => $_} @{ $b };
        }

        my $m = 0;
        for (keys %a_objs) {
            next if defined $b_objs{$_};
            $v[$m]->{_location} = 'src_only';
            $v[$m]->{$id} = $_;
            $m++;
        }
        for (keys %b_objs) {
            next if defined $a_objs{$_};
            $v[$m]->{_location} = 'dst_only';
            $v[$m]->{$id} = $_;
            $m++;
        }
        my @common_keys = grep defined $b_objs{$_}, keys %a_objs;
        for (@common_keys) {
            my $comp = $s->compare_hash($a_objs{$_}, $b_objs{$_});
            $comp or next;
            $v[$m]->{_location} = 'common' if $compare_say_same;
            $v[$m]->{$id} = $_;
            map {$v[$m]->{$_} = $comp->{$_}} keys %$comp;
            $m++;
        }
    } elsif ($array eq 'rows') {
        my $same = 1;
        if ($n_a != $n_b) {
            $same = 0;
            $v[0] = 'different number of rows in arrays';
        } else {
            my $m = 0;
            for my $i (0..($n_a - 1)) {
                my $av = @{ $a }[$i];
                my $bv = @{ $b }[$i];
                my $nv_a = @$av;
                my $nv_b = @$bv;
                if ($nv_a != $nv_b) {
                    $v[$m]->{i} = $i;
                    $v[$m]->{reason} = 'different number of values';
                    $same = 0;
                    next;
                }
                for my $j (0..($nv_a - 1)) {
                    # say " v[$i][$j]  av : @$av[$j]  bv : @$bv[$j]";
                    next if @$av[$j] == @$bv[$j];
                    $v[$m]->{item} = "$i, $j";
                    $v[$m]->{reason} = 'different values';
                    $v[$m]->{src} = @$av[$j];
                    $v[$m]->{dst} = @$bv[$j];
                    $same = 0;
                    last;
                }
            }
        }
        $v[0] = 'same' if ($same  &&  $compare_say_same);
    } else {
        my %vals;
        for (0..($n_a - 1)) {
            $vals{@$a[$_]} = 'src_only';
        }
        for (0..($n_b - 1)) {
            $vals{@$b[$_]} = defined $vals{@$b[$_]} ? 'both' : 'dst_only';
        }
        my $m = 0;
        for (keys %vals) {
            next if $vals{$_} eq 'both';
            $v[$m] = "$vals{$_} : $_";
            $m++;
        }
        $v[0] = 'same' if ($m == 0  &&  $compare_say_same);
    }

    return @v ? \@v : 0;
}

sub _check_relative {
    my $s = shift;
    my $uri = shift;

    return 1 if ($uri eq $s->{report_uri});

    my ($type) = ($uri =~ /^\/(.*?)\//);
    grep $type eq $_, @has_relatives or 
        die "relative not allowed : $uri";

    my $types = (grep $type eq $_, @publication_types) ?  
                "publications" : $s->plural_type($type);

    return defined $s->{$types}->{$uri};
}

sub _name_key {
    my $s = shift;
    my $p = shift;

    my $first_initial = substr $p->{first_name}, 0, 1;
    my $n = uc "$p->{last_name}_$first_initial";

    return $n;
}

sub _fix_uri {
    my $s = shift;
    my $u = shift;

    return 0 unless $$u =~ m/%/;

    my %list = (
        '%28' => '(', '%29' => ')',
        '%3A' => ':', '%3B' => ';',
        '%3C' => '<', '%3E' => '>',
        '%5B' => '[', '%5D' => ']',
        );
    for (keys %list) {
        next unless $$u =~ m/$_/;
        $$u =~ s/$_/$list{$_}/g;
    }

    return 0;
}

sub new {
    my $class = shift;
    my $base = shift;
    my $access = shift;

    my $s;
    if ($base) {
        if ($access eq 'update') {
            $s->{gcis} = Gcis::Client->connect(url => $base);
        } else {
            $s->{gcis} = Gcis::Client->new(url => $base);
        }
    } else {
        $s->{gcis} = 'no url';
    }
    $s->{base} = $base;
    $s->{all} = '?all=1';
    $s->{local} = '.';
    $s->{access} = $access;

    bless $s, $class;
    return $s;
}

sub not_all {
    my $s = shift;
    $s->{all} = '';
    return 0;
}

sub local {
    my $s = shift;
    $s->{local} = shift;
    return 0;
}

sub get {
    my $s = shift;
    my $uri = shift;

    my $v = $s->{gcis}->get($uri);
    return wantarray && ref($v) eq 'ARRAY' ? @$v : $v;
}

sub post {
    my $s = shift;
    my $what = shift;
    my $obj = shift;

    my $v = $s->{gcis}->post($what, $obj);
    return wantarray && ref($v) eq 'ARRAY' ? @$v : $v;
}

sub logger {
    my $s = shift;
    my $logger = shift;

    $s->{gcis}->logger($logger);
    return 0;
}

sub logger_info {
    my $s = shift;
    my $message = shift;
    $s->{gcis}->logger->info($message);
    return 0;
}

sub get_full_report {
    my $s = shift;
    my $uri = shift;

    for (qw(
        report
        chapters
        figures
        images
        tables
        findings
        references
        publications
        journals
        parents_1
        relatives
        parents_2
        )) {
        my ($type, $m) = split /_/;
        my $sub = \&{"Exim::get_$type"};
        if ($type eq 'report') {
            $s->$sub($uri);
            say " got report";
        } elsif ($type eq 'parents') {
            my @a = ($m == 1 ? @has_parents : 'datasets');
            for (@a) {
                $s->$sub($_);
                say " got parents for $_";
            }
        } else {
            $s->$sub;
            my $t1;
            if ($type eq 'journal') {
                $t1 = scalar keys %{ $s->{publications} };
            } elsif ($type eq 'relatives') {
                $t1 = '';
            } else { 
                $t1 = scalar keys %{ $s->{$type} };
            }
            say " got $type : $t1";
        }
    }
        
    for (qw(
        reports
        chapters
        figures
        images
        tables
        arrays
        findings
        publications
        journals
        datasets
        )) {
        $s->get_contributors($_);
        $s->get_files($_);
        say " got contributors and files for $_";
    }

    $s->update_href($_, 'references') for qw(
        reports
        chapters
        figures
        images
        tables
        arrays
        findings
        publications
        journals
        datasets
        );

    $s->update_href($_) for qw(
        references
        activities
        contributors
        people
        organizations
        files
        );
    say " updatted hrefs";

    return 0;
}

sub get_report {
    my $s = shift;
    my $uri = shift;

    my $report = $s->get($uri) or die "no report : $uri";
    $s->{report_uri} = $uri;
    $s->{reports}->{$uri} = $report;
    for (qw(figure finding table)) {
        delete $report->{"report_".$_."s"};
        $report->{$_."_uris"} = [];
    }

    return 0;
}

sub get_chapters {
    my $s = shift;

    my $rep_uri = $s->{report_uri};
    my $rep = $s->{reports}->{$rep_uri};

    my $n = 0;
    for (@{ $rep->{chapters} }) {
        my $uri = $_->{uri};
        my $chapter = $s->get($uri) or die "no chapter : $uri";
        $rep->{chapter_uris}[$n++] = $uri;
        delete $chapter->{$_} for qw(figures findings tables);
        $chapter->{$_} = [] for qw(figure_uris finding_uris table_uris);
        $s->{chapters}->{$uri} = $chapter;
    }
    delete $rep->{chapters};

    return 0;
}

sub get_figures {
    my $s = shift;

    my $rep_uri = $s->{report_uri};
    my $rep = $s->{reports}->{$rep_uri};

    my $obj_uri = $rep->{uri}."/figure".$s->{all};
    my @objs = $s->get($obj_uri) or return 1;
    for (@objs) {
        my $uri = $_->{uri};
        my $obj = $s->get($uri) or die "no figure : $uri";

        my $chapter_id = $_->{chapter_identifier};
        my $ref_loc = $rep;
        if ($chapter_id) {
            my $chapter_uri = $rep->{uri}."/chapter/".$chapter_id;
            $ref_loc = $s->{chapters}->{$chapter_uri} or
                die "no chapter : $chapter_uri";
        }
        my $n = @{ $ref_loc->{figure_uris} };
        $ref_loc->{figure_uris}[$n] = $uri;

        delete $obj->{chapter};
        $s->{figures}->{$uri} = $obj;
    }

    return 0;
}

sub get_images {
    my $s = shift;

    for (keys %{ $s->{figures} }) {
        my $fig = $s->{figures}->{$_};
        my $images = $fig->{images};
        my $n = 0;
        for my $img (@$images) {
            my $uri = "/image/$img->{identifier}";
            my $image = $s->get($uri) or die "no image : $uri";
            $fig->{image_uris}[$n++] = $uri;
            delete $image->{figures};
            $s->{images}->{$uri} = $image;
        }
        delete $fig->{images};
    }

    return 0;
}

sub get_tables {
    my $s = shift;

    my $rep_uri = $s->{report_uri};
    my $rep = $s->{reports}->{$rep_uri};

    my $obj_uri = $rep->{uri}."/table".$s->{all};
    my @objs = $s->get($obj_uri) or return 1;
    for (@objs) {
        my $uri = $_->{uri};
        my $obj = $s->get($uri) or die "no table : $uri";

        my $chapter_id = $_->{chapter_identifier};
        my $ref_loc = $rep;
        if ($chapter_id) {
            my $chapter_uri = $rep->{uri}."/chapter/".$chapter_id;
            $ref_loc = $s->{chapters}->{$chapter_uri} or
                die "no chapter : $chapter_uri";
        }
        my @ref_loc_uris = $ref_loc->{table_uris};
        my $n = @ref_loc_uris;
        $ref_loc_uris[$n] = $uri;

        delete $obj->{chapter};
        $s->{tables}->{$uri} = $obj;
    }

    return 0;
}

sub get_arrays {
    my $s = shift;

    for (keys %{ $s->{tables} }) {
        my $tab = $s->{tables}->{$_};
        my $arrays = $tab->{arrays};
        my $n = 0;
        for my $arr (@$arrays) {
            my $uri = "/array/$arr->{identifier}";
            my $array = $s->get($uri) or die "no array : $uri";
            $tab->{array_uris}[$n++] = $uri;
            delete $array->{tables};
            $s->{arrays}->{$uri} = $array;
        }
        delete $tab->{arrays};
    }

    return 0;
}

sub get_findings {
    my $s = shift;

    my $rep_uri = $s->{report_uri};
    my $rep = $s->{reports}->{$rep_uri};

    my $obj_uri = $rep->{uri}."/finding".$s->{all};
    my @objs = $s->get($obj_uri) or return 1;
    for (@objs) { 
        my $uri = $_->{uri};
        my $obj = $s->get($uri) or die "no finding : $uri";

        my $chapter_id = $_->{chapter_identifier};
        my $ref_loc = $rep;
        if ($chapter_id) {
            my $chapter_uri = $rep->{uri}."/chapter/".$chapter_id;
            $ref_loc = $s->{chapters}->{$chapter_uri} or 
                die "no chapter : $chapter_uri";
        }
        my @ref_loc_uris = $ref_loc->{finding_uris};
        my $n = @ref_loc_uris;
        $ref_loc_uris[$n] = $uri;

        delete $obj->{chapter};
        $s->{findings}->{$uri} = $obj;
    }

    return 0;
}

sub get_references {
    my $s = shift;

    my $rep_uri = $s->{report_uri};
    my $rep = $s->{reports}->{$rep_uri};

    my $obj_uri = $rep->{uri}."/reference".$s->{all};
    my @objs = $s->get($obj_uri) or return 1;
    for (@objs) {
        my $uri = $_->{uri};
        next if $s->{references}->{$uri};

        my $obj = $s->get($uri) or die "no reference : $uri";
        my $child_pub_uri = $obj->{child_publication};
        delete $obj->{$_} for qw(chapter child_publication);
        $obj->{child_publication_uri} = $child_pub_uri;
        $s->{references}->{$uri} = $obj;
    }

    return 0;
}

sub get_publications {
    my $s = shift;

    for (keys %{ $s->{references} }) {
        my $ref = $s->{references}->{$_};
        if (my $uri = $ref->{child_publication_uri}) {
            next if $uri =~ m[^$s->{report_uri}];
            next if $s->{publication}->{$uri};

            my $pub = $s->get($uri) or die "no publication : $uri";
            $s->{publications}->{$uri} = $pub;

            my ($type) = ($uri =~ /^\/(.*?)\//);
            next unless $type eq 'report';
            $pub->{parents} = [];
            $pub->{contributors} = [];
            my @v = split '/', $uri;
            my $sub_type = $v[3] if scalar @v == 5;
            if (!$sub_type) {
                for (qw(figure finding table)) {
                    delete $pub->{"report_".$_."s"};
                    $pub->{$_."_uris"} = [];
                }
                $pub->{chapters} = [];
                next;
            } 
            die " invalid subtype (of report) : $sub_type" 
                unless $sub_type eq 'chapter';
            for (qw(figure finding table)) {
                delete $pub->{$_."s"};
                $pub->{$_."_uris"} = [];
            }

        }
    }

    return 0;
}

sub get_journals {
    my $s = shift;

    for (keys %{ $s->{publications} }) {
        my $pub = $s->{publications}->{$_};
        if (my $id = $pub->{journal_identifier}) {
            my $uri = "/journal/$id";
            next if $s->{journals}->{$uri};
            my $jou = $s->get($uri) or die "no journal : $uri";
            $jou->{articles} = [];
            $s->{journals}->{$uri} = $jou;
        }
    }

    return 0;
}

sub get_parents {
    my $s = shift;
    my $type = shift;

    for (keys %{ $s->{$type} }) {
        my $obj = $s->{$type}->{$_};
        my $parents = $obj->{parents};
        for my $par (@$parents) {
            if ($par->{url}) {
                my ($parent_type) = ($par->{url} =~ /^\/(.*?)\//);
                my $p_type;
                if (grep $parent_type eq $_, @publication_types) {
                    $p_type = 'publications';
                } elsif ($parent_type eq 'dataset') {
                    $p_type = 'datasets';
                } else {
                    say "warning - parent url not publication or dataset : ".
                        "$parent_type, $par->{url}";
                }
                my $pub = $s->get($par->{url}) or die "parent url not uri";
                if ($parent_type eq 'report') {
                    delete $pub->{$_} for qw(report_figures report_findings
                                             report_tables);
                } elsif ($parent_type eq 'dataset') {
                    delete $pub->{$_} for qw(aliases);
                }
                $s->{$p_type}->{$pub->{uri}} = $pub unless
                    $pub->{uri} =~ m[^$s->{report_uri}];
            }
            my $act_uri = $par->{activity_uri} or next;
            my $activity = $s->get($act_uri) or 
                die "no activity : $act_uri";
            my $pub_maps = $activity->{publication_maps};

            for my $pub_map (@$pub_maps) {
                my $child_uri = $pub_map->{child_uri};
                my $child = $s->get($child_uri) or 
                    die "no child : $child_uri";
                $pub_map->{child_uri} = $child->{uri};
                delete $pub_map->{child};

                my $parent_uri = $pub_map->{parent_uri};
                my $parent = $s->get($parent_uri) or 
                    die "no parent : $parent_uri";
                $pub_map->{parent_uri} = $parent->{uri};
                delete $pub_map->{parent};
            }
            $s->{activities}->{$act_uri} = $activity;
        }
    }

    return 0;
}

sub get_relatives {
    my $s = shift;

    for (keys %{ $s->{activities} }) {
        my $obj = $s->{activities}->{$_};
        my $pub_maps = $obj->{publication_maps};
        for my $pub_map (@$pub_maps) {
            my $child_uri = $pub_map->{child_uri};
            $s->_check_relative($child_uri) or do {
                say "warning - no child in list : $child_uri"
            };

            my $parent_uri = $pub_map->{parent_uri};
            my ($parent_type) = ($parent_uri =~ /^\/(.*?)\//);
            $parent_type eq 'dataset' or die "parent not a dataset";
            next if $s->{datasets}->{$parent_uri};
            my $parent = $s->get($parent_uri) or die "no parent : $parent_uri";
            $s->{datasets}->{$parent_uri} = $parent;
        }
    }

    return 0;
}

sub get_contributors {
    my $s = shift;
    my $type = shift;

    my @k = $type eq 'report' ? '_REPORT_' : keys %{ $s->{$type} };
    for (@k) {
        my $obj = ($type eq 'report' ? $s->{$type} : $s->{$type}->{$_});
        my $contributors = $obj->{contributors};
        my $n = 0;
        $obj->{contributor_uris} = [];
        for my $con (@$contributors) {
            my $con_uri = $con->{uri};

            if (my $org_uri = $con->{organization_uri}) {
                if (!$s->{organizations}->{$org_uri}) {
                    my $org = $s->get($org_uri) or 
                        die "no organizaton : $org_uri";
                    delete $con->{organization};
                    delete $org->{id};
                    $s->{organizations}->{$org_uri} = $org;
                }
            }

            if (my $per_uri = $con->{person_uri}) {
                if (!$s->{people}->{$per_uri}) {
                    my $per = $s->get($per_uri) or die "no person : $per_uri";
                    delete $per->{contributors};
                    delete $per->{id};
                    $s->{people}->{$per_uri} = $per;
                }
            }
            delete $con->{person};
            delete $con->{person_id};
            delete $con->{id};

            $obj->{contributor_uris}[$n++] = $con_uri;
            $s->{contributors}->{$con_uri} = $con;
        }
        delete $obj->{contributors};
    }

    return 0;
}

sub import_report {
    my $s = shift;
    my $r = shift;

    my $uri = $r->{report_uri};
    my $src = clone($r->{reports}->{$uri});

    my @ignore_src_items = (@common_ignore_src_items, qw(chapter_uris
                            figure_uris finding_uris table_uris));
    my @ignore_dst_items = (@common_ignore_dst_items, qw(chapters 
                            report_figures report_findings report_tables));
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    $s->post("/report", $src) or die "unable to import : $uri";
    return 0;
}

sub import_chapter {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_src_items = (@common_ignore_src_items, 
                            qw(figure_uris finding_uris table_uris));
    my @ignore_dst_items = (@common_ignore_dst_items, 
                            qw(figures findings tables));
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    my $report_uri = "/report/$src->{report_identifier}";
    $s->post("$report_uri/chapter", $src) or die "unable to import : $uri";
    return 0;
}

sub import_figure {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_src_items = (@common_ignore_src_items, 
                            qw(image_uris kindred_figures));
    my @ignore_dst_items = (@common_ignore_dst_items, 
                            qw(chapter images kindred_figures));
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    my $report_uri = "/report/$src->{report_identifier}";
    my $chapter_uri = $src->{chapter_identifier};
    $chapter_uri = "/chapter/$chapter_uri" if $chapter_uri;
    $s->post("$report_uri$chapter_uri/figure", $src) or 
        die "unable to import : $uri";

    my $image_uris = $src_orig->{image_uris};
    return 0 if !$image_uris;
    for (@$image_uris) {
        s/^\/image\///;
        say " image : $_";
        my $rel = ($uri =~ s/\/figure\//\/figure\/rel\//r);
        $s->post($rel, {add_image_identifier => $_}) or
            die "unable to add image to figure : $uri";
    }
    return 0;
}

sub import_image {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_src_items = (@common_ignore_src_items, qw(figure_uris));
    my @ignore_dst_items = (@common_ignore_dst_items, qw(figures));

    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    $s->post("/image", $src) or die "unable to import : $uri";
    return 0;
}

sub import_table {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_src_items = (@common_ignore_src_items, qw(arrays));
    my @ignore_dst_items = (@common_ignore_dst_items, qw(arrays chapter));

    my $same = 0;
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        $same = 1;
    }

    if (!$same) {
        if ($s->{access} ne 'update') {
            say " would import item : $uri";
            return 0;
        }
        say " importing item : $uri";
        delete $src->{$_} for ('uri', @ignore_src_items);
        my $report_uri = "/report/$src->{report_identifier}";
        say " report_uri : $report_uri";
        my $chapter_uri = $src->{chapter_identifier};
        $chapter_uri = "/chapter/$chapter_uri" if $chapter_uri;
        $s->post("$report_uri$chapter_uri/table", $src) or 
            die "unable to import : $uri";
    }

    return 0 if !$src_orig->{arrays};
    for (@{ $src_orig->{arrays} }) {
        $s->import_array($_);
        my $array_id =~ $_->{identifier};
        my ($rel) = ($uri =~ s/\/table\//\/table\/rel\//r);
        $s->post($rel, {add_array_identifier => $array_id}) or
            die "unable to add array to figure : $uri";
    }
    return 0;
}

sub import_array {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri;
    if ($src->{uri}) {
        $uri = $src->{uri};
    } else {
        $uri = "/array/$src->{identifier}";
        $src->{uri} = $uri;
    }

    my @ignore_src_items = (@common_ignore_src_items, qw(table_uris));
    my @ignore_dst_items = (@common_ignore_dst_items, qw(tables));

    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    $s->post("/array", $src) or die "unable to import : $uri";
    return 0;
}

sub import_finding {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @common_ignore_src_items;
        delete $dst->{$_} for (@common_ignore_dst_items, qw(chapter));
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @common_ignore_src_items);
    my $report_uri = "/report/$src->{report_identifier}";
    my $chapter_uri = $src->{chapter_identifier};
    $chapter_uri = "/chapter/$chapter_uri" if $chapter_uri;
    $s->post("$report_uri$chapter_uri/finding", $src) or 
        die "unable to import : $uri";
    return 0;
}

sub import_reference {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my $child_pub_uri = $src->{child_publication_uri};
    $src->{child_publication} = $child_pub_uri;
    $s->_fix_uri(\$child_pub_uri);
    delete $src->{child_publication_uri};
    my @ignore_src_items = qw(publications);
    my @ignore_dst_items = qw(publications);
    my $dst = $s->get($uri);
    my $same = 0;
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        $same = 1;
    }

    if ($s->{access} ne 'update') {
        return 0 if $same;
        say " would import item : $uri";
        return 0;
    }

    if (!$same) {
        say " importing item : $uri";
        delete $src->{$_} for ('uri', @ignore_src_items);
        $s->post("/reference", $src) or
            die "unable to import : $uri";
    }

    if ($child_pub_uri) {
        $s->post($uri, {
            identifier => $src->{identifier},
            attrs => $src->{attrs}, 
            child_publication_uri => $child_pub_uri,
            }) or 
            die "unable to set child pub : $uri";
    }

    return 0 unless $src_orig->{publications};
    for (@{ $src_orig->{publications} }) {
        $s->post($uri, {
            identifier => $src->{identifier},
            attrs => $src->{attrs},
            publication => $_,
            }) or
            die "unable to set publication : $uri";
    }
    
    return 0;
}

sub import_publication {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my ($type) = ($uri =~ /^\/(.*?)\//);
    grep $type eq $_, @publication_types or
        die "invalid publication type : $uri";

    my @ignore_src_items = @common_ignore_src_items;
    my @ignore_dst_items = @common_ignore_dst_items;

    my $sub_type;
    if ($type eq 'report') {
       my @v = split '/', $uri;
       $sub_type = $v[3] if scalar @v == 5;
       if (!$sub_type) {
           @ignore_src_items = (@ignore_src_items, qw(
               chapters figure_uris finding_uris table_uris));
           @ignore_dst_items = (@ignore_dst_items, qw(
               chapters report_figures report_findings report_tables));
       } elsif ($sub_type eq 'chapter') {
           @ignore_src_items = (@ignore_src_items, qw(
               figure_uris finding_uris table_uris
               figures findings tables));
           @ignore_dst_items = (@ignore_dst_items, qw(
               figures findings tables));
       } else {
           die " sub type (of differnet report) not supported : $sub_type";
       }
    }

    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    $s->post("/$type", $src) or die "unable to import : $uri";
    return 0;
}

sub import_journal {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_src_items = (@common_ignore_src_items, qw(articles));
    my @ignore_dst_items = (@common_ignore_dst_items, qw(articles));

    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    $s->post("/journal", $src) or die "unable to import : $uri";
    return 0;
}

sub import_activity {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    # note: publication_maps are just parents of other items

    my @ignore_items = qw(methodologies publication_maps);
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_items;
        delete $dst->{$_} for @ignore_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_items);
    $s->post("/activity", $src) or die "unable to import : $uri";
    return 0;
}

sub import_dataset {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_src_items = (@common_ignore_src_items, 
                            qw(instrument_measurements aliases));
    my @ignore_dst_items = (@common_ignore_dst_items,
                            qw(instrument_measurements aliases));
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_src_items;
        delete $dst->{$_} for @ignore_dst_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{$_} for ('uri', @ignore_src_items);
    $s->post("/dataset", $src) or die "unable to import : $uri";
    return 0;
}

sub _close_person {
    my $s = shift;
    my $src = shift;

    my $last_src = lc $src->{last_name};
    my $close = $s->{gcis}->get("/autocomplete?q=$last_src&type=person");
    # my $close = $s->{gcis}->get('/autocomplete',
    #                    { q =>$name, items => 15, type => 'person' } );
    return 0 unless @$close;

    my $first_initial_src = lc substr $src->{first_name}, 0, 1;

    for (@$close) {
        my ($item, $id, $first_dst, $last_dst) = split;
        next unless $item eq '[person]';
        next unless (lc $last_dst) eq $last_src;
        my $first_initial_dst = lc substr $first_dst, 0, 1;
        next unless $first_initial_src eq $first_initial_dst;
        $id =~ s/\{|\}//g;
        say " person(s) with same last name and first initial found";
        say "   id : $id, last name : $last_dst, first : $first_dst";
        die "will not automatically add new person with close name";
    }

    return 0;
}

sub import_person {
    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $dst->{$_} for qw(id contributors aliases);
        delete $src->{$_} for qw(contributors aliases);
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if ($comp);
        say " same item already in dst : $uri";
        return 0;
    }

    $s->_close_person($src);

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{uri};
    $s->post("/person", $src) or die "unable to import : $uri";
    return 0;
}

sub _contrib_uri {
    my $a = shift;

    my @us = split /\//, $a;
    my $nv = @us;
    my $loc = 2;
    while (1) {
        last unless $us[1] eq 'report';
        last if $nv < 5;
        my @f = qw(array figure finding image table);
        if (grep $us[3] eq $_, @f) {
            $loc = 4;
            last;
        }
        last if $us[3] ne 'chapter';
        $loc = 4;
        last if $nv < 7;
        last unless grep $us[5] eq $_, @f;
        $loc  = 6;
        last;
    }
    splice @us, $loc, 0, 'contributors';
    my $u = join '/', @us;

    return $u;
}

sub link_contributors {
    my $s = shift;
    my $type = shift;
    my $src_orig = shift;
    my $cons = shift;

    say " type : $type";

    return if !$cons;
    return if !$src_orig->{contributor_uris};

    my $src = clone($src_orig);

    for (@{ $src->{contributor_uris} }) {
        my $c = $cons->{$_} or die;

        my $con_uri = $c->{uri};

        my $org_uri = $c->{organization_uri};
        if ($org_uri) {
            my $dst_org = $s->get($org_uri) or 
                die "organization does not already exist : $org_uri";
        }
        my $per_uri = $c->{person_uri};
        if ($per_uri) {
            my $dst_per = $s->get($per_uri) or 
                die "person does not already exist : $per_uri";
        }

        if ($s->{access} ne 'update') {
            say " would link contributor : $con_uri";
            next;
        }

        say " adding contributor link : $con_uri";
        my $new_con = {
            role => $c->{role_type_identifier},
            organization_identifier => $c->{organization_uri},
            person_id => ($c->{person_uri} =~ s[^/.*/][]r),
        };
        my $u1 = _contrib_uri($src->{uri});
        $s->post($u1, $new_con) 
            or die "unable to link : $src->{uri}";
    }

    return 0;
}

sub link_parents {
    my $s = shift;
    my $type = shift;
    my $report_uri = shift;
    my $src = shift;

    return 0 if !$src->{parents};
    my $id = $src->{identifier} or die "no identifier";

    my $uri = $src->{uri};
    for (@{ $src->{parents} }) {
        my $act = ($_->{activity_uri} =~ s/^\/activity\///r);
        my $p = {
            parent_uri   => $_->{url},
            parent_rel   => $_->{relationship},
            note         => $_->{note},
            activity     => $act, 
            };
        if ($s->{access} ne 'update') {
            say " would link item to parents : $uri";
            next;
        }
        say " adding link to parent for : $uri";
        my $pre;
        if (grep $type eq $_, qw(figure table finding)) {
            $pre = "$report_uri/$type";
        } else {
            ($pre) = ($uri =~ /^(\/.*?)\//);
        }
        $s->post("$pre/prov/$id", $p) or
            die "unable to link parents : $uri";
    }

    return 0;
}

sub import_files {
    my $s = shift;
    my $type = shift;
    my $src = shift;
    my $all_src = shift;

    return 0 if !$src->{file_uris};

    my $uri = $src->{uri};
    $s->_fix_uri(\$uri);

    my %new_file;
    for (@{ $src->{file_uris} }) {

        my $src_file = $all_src->{files}->{$_};
        my $dst_file = $s->get($_);
        if ($dst_file) {
            $s->_update_item_href($dst_file);
            delete $dst_file->{$_} for qw(thumbnail thumbnail_href);
            my $comp = $s->compare_hash($src_file, $dst_file);
            say " comp :\n".Dumper($comp) if $comp;
            die "different item already in dst : $uri" if $comp;
            say " same item already in dst : $uri";

            my $res = $s->get($uri) or 
                die " existing item does not exist : $uri";
            my $exists = 0;
            for my $f (@{ $res->{files} }) {
                next if $_ ne $f->{uri}; 
                say " link already exists : $uri, $_";
                $exists = 1;
                last;
            }
            next if $exists;

            my $u = $uri;
            $u =~ s[/$type/][/$type/files/];
            if ($s->{access} ne 'update') {
                say " would link item to existing file : $uri";
                next;
            }
            say " linking to existing file : $uri, $_";
            $s->post($u, {add_existing_file => $_}) or 
                 die "unable to link to existing file : $_";
            next;
        }

        my $src_file = $all_src->{files}->{$_};
        my $f = ($src_file->{file} =~ s[.*/][]r);
        my $f1 = "$s->{local}/$f";
        -f $f1 or die "file does not exist : $f1";
        my $u = "$uri/$f";
        $u =~ s[/$type/][/$type/files/];
        if ($s->{access} ne 'update') {
            say " would upload file : $_";
            next;
        }
        say " uploading and linking file : $uri, $_";
        $s->{gcis}->put_file($u, $f1) or
            die "unable to upload file : $_";
        $new_file{$_}->{sha1} = $src_file->{sha1};
    }
    return 0 if !keys %new_file;

    my $dst = $s->get($uri) or die "can not get : $uri";
    for (@{ $dst->{files} }) {
        my $dst_file_uri = $_->{uri};
        my $dst_file = $s->get($dst_file_uri) or die "new file does not exist";
        my ($src_file_uri) = grep $new_file{$_}->{sha1} eq $dst_file->{sha1}, 
                                  keys %new_file;
        $new_file{$src_file_uri}->{dst_uri} = $dst_file_uri;
        delete $all_src->{files}->{$src_file_uri};
        delete $dst_file->{$_} for qw(href thumbnail thumbnail_href);
        $all_src->{files}->{$dst_file_uri} = $dst_file;
    }

    for my $item (@item_list) {
        next if $item eq 'files';
        for (keys %{ $all_src->{$item} }) {
            my $obj = $all_src->{$item}->{$_};
            next unless $obj->{file_uris};
            my $i = 0;
            for (@{ $obj->{file_uris} }) {
                $obj->{file_uris}[$i] = $new_file{$_}->{dst_uri} 
                    if $new_file{$_};
                $i++;
            }
        }
    }

    return 0;
}

sub import_organization {

    my $s = shift;
    my $src_orig = shift;

    my $src = clone($src_orig);
    my $uri = $src->{uri};

    my @ignore_items = qw(id aliases parents children);
    my $dst = $s->get($uri);
    if ($dst) {
        $s->_update_item_href($dst);
        delete $src->{$_} for @ignore_items;
        delete $dst->{$_} for @ignore_items;
        my $comp = $s->compare_hash($src, $dst);
        say " comp :\n".Dumper($comp) if $comp;
        die "different item already in dst : $uri" if $comp;
        say " same item already in dst : $uri";
        return 0;
    }

    if ($s->{access} ne 'update') {
        say " would import item : $uri";
        return 0;
    }
    say " importing item : $uri";
    delete $src->{uri};
    $s->post("/organization", $src) or die "unable to import : $uri";
    return 0;
}

sub get_files {
    my $s = shift;
    my $type = shift;

    my @k = $type eq 'report' ? '_REPORT_' : keys %{ $s->{$type} };
    for (@k) {
        my $obj = ($type eq 'report' ? $s->{$type} : $s->{$type}->{$_});
        my $files = $obj->{files};
        my $n = 0;
        $obj->{file_uris} = [];
        for my $f (@$files) {
            my $f_uri = $f->{uri};
            $f_uri or die " no file uri for $obj->{uri}";
            $obj->{file_uris}[$n++] = $f_uri;
            my $file = $s->get($f_uri) or die "no file";
            delete $file->{$_} for qw(thumbnail thumbnail_href);
            $s->{files}->{$f_uri} = $file;
        }
        delete $obj->{files};
    }

    return 0;
}

sub count {
   my $s = shift;
   my $type = shift;

   my @k = keys %{ $s->{$type} };
   my $n = @k;

   return $n;
}

sub dump {
   my $s = shift;
   my $file = shift;

   my $e->{base} = $s->{base};
   $e->{items}->{base} = 1;

   my $rep_uri = $s->{report_uri};
   if ($s->{reports}->{$rep_uri}) {
       $e->{report} = $s->{reports}->{$rep_uri}; 
       $e->{items}->{report} = 1;
   }

   for my $item (@item_list) {
       next if $item eq 'reports';
       my $n = $s->count($item);
       $e->{items}->{$item} = $n if $n > 0;
       my $n = 0;
       for (keys %{ $s->{$item} }) {
           $e->{$item}[$n++] = $s->{$item}->{$_};
       }
   }

   if (!$file) {
      say Dump($e) or die "unable to export report";
   } else {
      open my $f, '>', $file or die "can't open file";
      say $f Dump($e);
   }

   return;
}

sub load {
    my $s = shift;
    my $file = shift;

    my $e;
    if (!$file) {
       my $yml = do { local $/; <> };
       utf8::encode($yml);
       $e = Load($yml);
    } else {
       open my $f, '<:encoding(UTF-8)', $file or die "can't open file";
       my $yml = do { local $/; <$f> };
       utf8::encode($yml);
       $e = Load($yml);
    }

    for my $k (keys %{ $e }) {
        grep $k eq $_, (@item_list, 'report', 'items', 'base')
            or die "invalid item in input file : $k";
    }
    ref $e->{base} ne 'ARRAY' or die "only one base allowed";
    $s->{base} = $e->{base};

    if ($e->{report}) {
        ref $e->{report} ne 'ARRAY' or die "only one report allowed";
        my $rep_uri = $e->{report}->{uri} or die "no report uri";
        $s->{report_uri} = $rep_uri;
        $s->{reports}->{$rep_uri} = $e->{report};
    }

    for my $items (@item_list) {
        $e->{$items} or next;
        next if $items eq 'reports';
	ref($e->{$items}) eq 'ARRAY' or die "must be an array : $items";
        for (@{ $e->{$items} }) {
            $_->{uri} or die "items must have a uri : $items";
            $s->{$items}->{$_->{uri}} = $_;
        }
    }

    return;   
}

sub _flip_mapping {
    my $s = shift;
    my $a_base = shift;
    my $b_base = shift;

    $a_base =~ s/^.*?\/\///;
    $b_base =~ s/^.*?\/\///;

    my $map_src = $s->{base}->{src};
    my $map_dst = $s->{base}->{dst};
    $map_src =~ s/^.*?\/\///;
    $map_dst =~ s/^.*?\/\///;

    if ($a_base eq $map_src) {
        $b_base eq $map_dst or die "map src found, map dst not found";
        return 0;
    }
    $b_base eq $map_src or die "map src not found";
    $a_base eq $map_dst or die "map src found, map dst not found";

    return 1;
}

sub set_up_map {
    my $s = shift;
    my $a = shift;
    my $b_base = shift;

    die "remapping report not allowed" if $s->{reports};
    die "remapping chapters not allowed" if $s->{chapters};

    my $a_base = $a->{base};
    my $flip_map = $s->_flip_mapping($a_base, $b_base);

    if ($flip_map) { 
    for my $item (@item_list) {
            next if !$s->{$item};
            my $t = $s->{$item};
            for (keys %{ $t }) {
                my $src = $t->{$_}->{uri};
                my $dst = $t->{$_}->{dst};
                !$t->{$dst} or die "destination already exists";
                $t->{$dst}->{uri} = $dst;
                $t->{$dst}->{dst} = $src;
                delete $t->{$_};
            }
        }
    }

    $s->_map_objs($_, $a) for (@item_list);
    
    return 0;
}

sub plural_type {
    my $s = shift;
    my $type = shift;

    my %plural = (
        person => 'people', 
        );
    my $t = $plural{$type};
    return $t if $t;
    $t = ($type  =~ s/ty$/ties/r);
    return $t if $t ne $type;
    return $type.'s';
}

sub single_type {
    my $s = shift;
    my $type = shift;

    my %single = (
        people => 'person',
        );
    my $t = $single{$type};
    return $t if $t;
    $t = ($type  =~ s/ties$/ty/r);
    return $t if $t ne $type;
    return ($type =~ s/s$//r);
}

sub _map_uris {
    my $s = shift;
    my $obj = shift;

    for (keys %$obj) {
        $_ =~ /^uri$|_uri$|_uris$/ or next;
        my $a = $obj->{$_} or next;

        my $type;
        if ($_ =~ /_uris$/) {
            ($type) = ($_ =~ /(.*)_uris$/);
        } else { 
            ($type) = ($a =~ /^\/(.*?)\//);
        }
        $type or die "no type for uri : $a";

        $type = 'publication' if grep $type eq  $_,
            @publication_types, qw(child_publication sub_publication);
        my $types = $s->plural_type($type);
        my $m = $s->{$types} or next;

        if (!($_ =~ /_uris$/)) {
            $m->{$a} or next;
            $obj->{$_} = $m->{$a}->{dst};
            next;
        }
        for (my $i = 0; $i < scalar @$a; $i++) {
            my $src_uri = @$a[$i];
            $m->{$src_uri} or next;
            @$a[$i] = $m->{$src_uri}->{dst};
        }
    }

    return 0;
}

sub _map_ids {
    my $s = shift;
    my $obj = shift;

    my $uri = $obj->{uri};
    for (keys %$obj) {
        $_ =~ /_identifier$/ or next;
        next if $_ =~ /_type_identifier$/;
        my $src_id = $obj->{$_} or next;

        my ($type) = ($_ =~ /(.*?)_/) or
            die "no type for identifier : $uri";

        next if grep $type eq $_, qw(report chapter);

        $type = 'publication' if grep $type eq $_, @publication_types;
        my $types = $s->plural_type($type);

        my $m = $s->{$types} or next;
        my $src_uri = "/$type/$src_id";
        $m->{$src_uri} or next;
        my $dst_uri = $m->{$src_uri}->{dst};
        my $dst_id = ($dst_uri =~ s[^/.*/][]r);
        $obj->{$_} = $dst_id or die "no new identifier : $dst_uri";
    }

    return 0;
}

sub _map_pubs {
    my $s = shift;
    my $obj = shift;

    return 0 unless $obj->{publication_maps};

    my $uri = $obj->{uri};

    for (@{ $obj->{publication_maps} }) {

        if (my $src_id = $_->{activity_identifier} and 
            my $m = $s->{activities}) {
            my $src_uri = "/activity/$src_id";
            if ($m->{$src_uri}) {
                my $dst_uri = $m->{$src_uri}->{dst};
                my $dst_id = ($dst_uri =~ s[^/.*/][]r);
                $_->{activity_identifier} = $dst_id or 
                    die "no new identifier : $dst_uri";
            }
        }

        for my $type_uri (qw(parent_uri child_uri)) {
            my $src_uri = $_->{$type_uri} or next;
            my ($type) = ($src_uri =~ /^\/(.*?)\//) or
                die "no type for identifier : $src_uri";
            $type = 'publication' if grep $type eq $_, @publication_types;
            my $types = $s->plural_type($type);

            my $m = $s->{$types} or next;
            $m->{$src_uri} or next;
            $_->{$type_uri} = $m->{$src_uri}->{dst};
        }

    }

    return 0;
}

sub _map_parents {
    my $s = shift;
    my $obj = shift;

    return 0 unless $obj->{parents};

    my $uri = $obj->{uri};

    for (@{ $obj->{parents} }) {

        if (my $src_uri = $_->{activity_uri} and
            my $m = $s->{activities}) {
            $_->{activity_uri} = $m->{$src_uri}->{dst} if $m->{$src_uri};
        }

        my $url = $_->{url} or next;

        my $type = $_->{publication_type_identifier} or next;
        $type = 'publication' if grep $type eq $_, @publication_types;
        my $types = $s->plural_type($type);

        my $m = $s->{$types} or next;
        $m->{$url} or next;
        $_->{url} = $m->{$url}->{dst};

    }
    return 0;
}

sub _map_objs {
    my $s = shift;
    my $type = shift;
    my $a = shift;

    for (keys %{ $a->{$type} }) {
        my $obj = $a->{$type}->{$_};

        my $m = $s->{$type};
        if ($m->{$_}) {
            my $dst_uri = $m->{$_}->{dst};
            die "destination already exists" if $s->{$type}->{$dst_uri};
            $a->{$type}->{$dst_uri} = clone($obj);
            delete $a->{$type}->{$_};
            $obj = $a->{$type}->{$dst_uri};
            if ($obj->{identifier}) {
                my $id = ($dst_uri =~ s[^/.*/][]r);
                $obj->{identifier} = $id or die "no new identifier : $dst_uri";
            }
        }

        $s->_map_uris($obj);
        $s->_map_ids($obj);
        $s->_map_pubs($obj);
        $s->_map_parents($obj);
    }

    return;
}

sub compare {
    my $s = shift;
    my $type = shift;
    my $a = shift;
    my $b = shift;
    my $map = shift;


    $a->{report_uri} eq $b->{report_uri} or 
        die "must compare same report";

    $s->{base} = {
        src => $a->{base},
        dst => $b->{base}};

    my %a_objs = %{ $a->{$type} } if $a->{$type};
    my %b_objs = %{ $b->{$type} } if $b->{$type};

    my $v;

    for (keys %a_objs) {
        next if $b_objs{$_};
        $v->{$_}->{uri} = $_;
        $v->{$_}->{_location} = 'src_only';
    }
    for (keys %b_objs) {
        next if $a_objs{$_};
        $v->{$_}->{uri} = $_;
        $v->{$_}->{_location} = 'dst_only';
    }

    my @common_keys = grep exists($b_objs{$_}), keys %a_objs;
    for (@common_keys) {
        my $comp = $s->compare_hash($a_objs{$_}, $b_objs{$_});
        $comp or next;
        my $d = { uri => $_ };
        $d->{_location} = 'common' if $compare_say_same;
        map {$d->{$_} = $comp->{$_}} keys %$comp;
        $v->{$_} = $d;
    }
    $s->{$type} = $v if $v;

    return 0;
}

1;
