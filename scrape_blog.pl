#!/usr/bin/env perl

use strictures 2;
use Getopt::Long;
use Path::Tiny;
use Time::Moment;
use Web::Scraper;

sub usage {
  print "FATAL: @_\n\n" if @_;

  print <<EOU;
Usage: scrape_blog.pl [options] <dbfile> <hugo_dir>

  Converts a Movable Type blog to a Hugo-powered site.

  Scrapes the archive/ folder of a static MT blog.

  Options:

    --prefix    prefix to generate the URL aliases

    --help, -?  this message
    --verbose   enable verbose/debug mode
EOU

  exit(1);
}


###########
# Scrape it

my $scraper = scraper {
  process 'h3.entry-header',   title       => 'TEXT';
  process 'div.entry-body',    body        => 'html';
  process 'div.entry-more',    body_more   => 'html';
  process 'span.post-footers', author_date => 'TEXT';
};

my %opts = parse_options();
scrape_blog();

sub scrape_blog {
  my $blog_dir = path($opts{blog_dir});
  my $it = $blog_dir->iterator({ recurse => 1 });
  while (my $page = $it->()) {
    my $rel = $page->relative($blog_dir);
    next unless my @slug = $rel->stringify =~ m{^((\d\d\d\d)/(\d\d)/(.+)\.html)$};
    next if $rel->stringify =~ m{/index\.html$};

    next if $opts{match} and $rel->stringify !~ m{$opts{match}};

    my $post = scrape_post($page);
    generate_hugo_post($post, \@slug);
  }
}

sub scrape_post {
  my ($page) = @_;
  my %months = (
    January   => 1,
    February  => 2,
    March     => 3,
    April     => 4,
    May       => 5,
    June      => 6,
    July      => 7,
    August    => 8,
    September => 9,
    October   => 10,
    November  => 11,
    December  => 12
  );

  my $post = $scraper->scrape($page->slurp);

  my @m = $post->{author_date} =~ m{Posted by (.+?) on (\w+) (\d+), (\d+) (\d+):(\d+) (AM|PM)};

  for my $f (qw( body body_more )) {
    next unless $post->{$f};
    $post->{$f} =~ s{(</?h)(\d+)\b}{$1.($2+1)}ge;
    $post->{$f} =~ s{</p><p>}{</p>\n\n<p>}g;
    $post->{$f} =~ s{(<h\d+>)}{\n\n$1}g;
    $post->{$f} =~ s{(</h\d+>)}{$1\n}g;
  }

  $m[4] += ($m[6] eq 'PM' ? 12 : 0);
  $m[4] = 0 if $m[4] == 24;

  $post->{author} = $m[0];
  $post->{date}   = Time::Moment->new(
    year   => $m[3],
    month  => $months{ $m[1] },
    day    => $m[2],
    hour   => $m[4],
    minute => $m[5],
    second => int(rand(60)),
  );

  $post->{path} = $page;

  return $post;
}

sub generate_hugo_post {
  my ($post, $slug) = @_;
  my $path = path($opts{hugo_dir}, 'content', 'notes', $slug->[1], $slug->[2], "$slug->[3].md");
  if (!is_scraped_page($path)) {
    debug("skipping '$path', not a scraped page");
    return;
  }

  debug("Writting '$post->{title}' on $post->{date} (via $post->{path})");

  $path->parent->mkpath;
  my $fh = $path->openw_utf8;

  print $fh "+++\n";
  print $fh "via = \"scrape\"\n";
  print $fh 'title = ',    quote($post->{title}) . "\n";
  print $fh 'date = ',     quote($post->{date}->to_string), "\n";
  print $fh 'aliases = [', quote("$opts{prefix}$slug->[0]"), "]\n";
  print $fh "+++\n\n";

  print $fh $post->{body},      "\n\n" if $post->{body};
  print $fh $post->{body_more}, "\n\n" if $post->{body_more};

  $fh->close();
}

sub quote {
  my ($t) = @_;
  $t =~ s/"/\\"/g;
  return qq{"$t"};
}

sub is_scraped_page {
  my ($path) = @_;

  return 1 unless $path->exists;

  my $content = $path->slurp;
  return 1 if $content =~ m/^via = "scrape"/gsm;

  return 0;
}


#################
# Options parsing

sub parse_options {
  my %opts = (prefix => '/');

  GetOptions(\%opts, 'help|?', 'prefix=s', 'match=s', 'verbose') or usage();
  usage() if delete $opts{help};

  usage('missing required parameters: MT Directory, Hugo Directory') if @ARGV != 2;
  usage("path '$opts{blog_dir}' not found") unless -e ($opts{blog_dir} = $ARGV[0]);
  usage("path '$opts{blog_dir}' is not a directory") unless -d $opts{blog_dir};
  usage("path '$opts{hugo_dir}' not found")          unless -e ($opts{hugo_dir} = $ARGV[1]);
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
