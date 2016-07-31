#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Getopt::Long;

sub usage {
  print "FATAL: @_\n\n" if @_;

  print <<EOU;
Usage: movable_type2hugo.pl [options] dbfile

  Converts a Movable Type blog to a Hugo-powered site.

  Support SQLite DB's for now. Tested with MT 3.x.

  Options:

    --blogid=<ID>        ID of the blog to convert, defaults to 1
    --category=<name>    Adds all categories as  field <name> in the article
                         front matter

    --help, -?  this message
    --verbose   enable verbose/debug mode
EOU

  exit(1);
}


############
# just do it

my %opts = parse_options();
convert_db_to_hugo();


####################
# Conversion process

sub convert_db_to_hugo {
  my $posts = collect_posts_from_mt_db();

  for my $p (@$posts) {
    generate_hugo_post($p);
  }
}


#################
# Options parsing

sub parse_options {
  my %opts;

  GetOptions(\%opts, 'help|?', 'verbose') or usage();
  usage() if delete $opts{help};

  usage('missing required DB file') if @ARGV == 0;
  usage('received more than a single DB file') if @ARGV > 1;
  usage("file '$opts{db}' not found") unless -e ($opts{db} = $ARGV[0]);

  return;
}


#############
# Tiny logger

sub debug {
  return unless $opts{verbose};
  print STDERR "[DEBUG] @_\n";
}
