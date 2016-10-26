#!/usr/bin/env perl

=head1 NAME

get-files.pl -- get files for a report from gcis instance

=head1 DESCRIPTION

get-files.pl -- gets the files for an entire report from the original gcis 
instance.  The report source is a yaml file (see export-report.pl).  The gcis 
instance is the one specified in the report.  The files are stored in a local
directory.

If the file already exists in the local directory, it is skipped.

=head1 SYNOPSIS

./get-files.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--log_file>

Log file (/tmp/gcis-get-files.log)

=item B<--log_level>

Log level (see Mojo::Log)

=item B<--input>

Input (source) report (yaml file, defaults to STDIN)

=item B<--local>

Directory to store file (defaults to ".")

=item B<--dry_run>

Set to perform dry run (no actual download)

=back

=head1 EXAMPLES

./get-files.pl --file=report.yaml --local=./tmp

=cut

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Gcis::Exim;
use YAML;
use Data::Dumper;

use strict;
use v5.14;

# local $YAML::Indent = 2;

GetOptions(
  'log_file=s'  => \(my $log_file = '/tmp/gcis-get-files.log'),
  'log_level=s' => \(my $log_level = "info"),
  'input=s'     => \(my $input),
  'local=s'     => \(my $local = '.'),
  'dry_run|n'   => \(my $dry_run),
  'help|?'      => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

my $n = 0;
&main;

sub main {

    say " importing files for a report";
    say "     log file : $log_file";
    say "     log level : $log_level";
    say "     input : $input" if $input;
    say "     local : $local";
    say "     dry run" if $dry_run;

    my $a = Exim->new("no url");
    $a->load($input);

    my $b = Mojo::UserAgent->new;
    $b = $b->max_redirects(3);

    my $base = $a->{base};
    say " base : $base";

    my $logger = Mojo::Log->new($log_file eq '-' ? () : (path => $log_file));
    $logger->level($log_level);
    $a->logger($logger);
    $a->logger_info("starting: ".$base);

    for (keys %{ $a->{files} }) {
        my $obj = $a->{files}->{$_};
        my $url = $obj->{url};
        my $name = ($obj->{file} =~ s[.*/][]r);
        my $loc = "$local/$name";
        if ($url =~ m[^http:]) {
            say " warning - external file not read : $url";
            next;
        }
        my $org =  "$base$url";
        if (-f $loc) {
            say " warning - file already exists : $loc";
            next;
        }
        if ($dry_run) {
            say " would download file : $org";
            say "     to : $loc";
            next;
        }
        say " downloading file : $org";
        say "     to : $loc";
        my $tx = $b->get($org);
        $tx->res->content->asset->move_to($loc);
    }

    $a->logger_info("done");

    return;
}

1;

