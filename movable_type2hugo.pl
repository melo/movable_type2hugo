#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Getopt::Long;
use Path::Tiny;
use Time::Moment;

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

sub collect_posts_from_mt_db {
  my $dbh = DBI->connect("dbi:SQLite:$opts{db}") or fatal("could not open DB '$opts{db}'");

  return $dbh->selectall_arrayref(
    q{
    SELECT e.entry_basename, e.entry_keywords, e.entry_status, e.entry_text,
           e.entry_text_more, e.entry_title, e.entry_created_on,
           c.category_label
      FROM mt_entry e
           LEFT JOIN mt_category c ON (c.category_id=e.entry_category_id)
     WHERE e.entry_blog_id=?
  }, { Slice => {} }, $opts{blog}
  );
}

sub generate_hugo_post {
  my ($post) = @_;

  my $date = eval { Time::Moment->from_string("$post->{entry_created_on}Z", lenient => 1) };
  fatal("could not parse post date '$post->{entry_created_on}'") unless $date;

  my $path =
    path($opts{hugo_dir}, 'content', 'notes', $date->year, $date->strftime('%m'), "$post->{entry_basename}.md");
  $path->parent->mkpath;
  my $fh = $path->openw;

  print $fh "+++\n";
  print $fh 'title = ',       quote($post->{entry_title}) . "\n";
  print $fh 'date = ',        quote($date->to_string), "\n";
  print $fh 'categories = [', quote($post->{category_label}), "]\n" if $post->{category_label};

  if (my $tags = $post->{entry_keywords}) {
    print $fh "tags = [", join(', ', map { quote($_) } split(m/[,\s]+/, $tags)), "]\n";
  }

  print $fh 'alias = ',
    quote(join('/', qw( notes archive ), $date->year, $date->strftime('%m'), "$post->{entry_basename}.html")), "\n";
  print $fh "draft = true\n" if $post->{entry_status} != 2;
  print $fh "+++\n\n";

  print $fh $post->{entry_text},      "\n\n" if $post->{entry_text};
  print $fh $post->{entry_text_more}, "\n\n" if $post->{entry_text_more};

  $fh->close();
}

sub quote {
  my ($t) = @_;
  $t =~ s/"/\\"/g;
  return qq{"$t"};
}

#################
# Options parsing

sub parse_options {
  my %opts = (blog => 1);

  GetOptions(\%opts, 'help|?', 'blog=i', 'verbose') or usage();
  usage() if delete $opts{help};

  usage('missing required parameters: DB File, Hugo Directory') if @ARGV != 2;
  usage("file '$opts{db}' not found")       unless -e ($opts{db}       = $ARGV[0]);
  usage("path '$opts{hugo_dir}' not found") unless -e ($opts{hugo_dir} = $ARGV[1]);
  usage("path '$opts{hugo_dir}' is not a directory") unless -d $opts{hugo_dir};

  return %opts;
}


#############
# Tiny logger

sub debug {
  return unless $opts{verbose};
  print STDERR "[DEBUG] @_\n";
}

sub fatal {
  print STDERR "[FATAL] @_\n";
  exit(1);
}
