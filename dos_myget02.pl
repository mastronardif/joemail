#!/usr/bin/perl

#use CGI qw(:standard escapeHTML);

=comment
File: .pl

Purpose: 
last Modified: 10/20/11
=cut

require 5;
use strict;
use strict 'vars';
use URI;
require LWP::UserAgent;
use HTTP::Cookies;
use URI::Escape;
use HTML::TokeParser;
use HTML::TreeBuilder;
use HTML::Parse;
use HTML::FormatText;
use Getopt::Long;
use Pod::Usage;

my $VERSION = '1.019';

#-----------
# prototypes
#-----------
sub get_options();
sub usage($);

sub get_urls();
#sub surpress_werr();
#sub trace($);

my %option = (verbose => 0,
              werr => 0,
             );
get_options;

usage 2 if not @ARGV;
usage 0 if $option{help};

my @Urls = &get_urls();

usage 22 unless get_options;
usage 0  if $option{help};



open STDERR, ">/dev/null" if not $option{verbose};

#$option{ae} = "KeepEverythingExtractor" unless $option{ae};

if ($option{debug})
{
   print "\n$0 begin\n";
   printf "url: %s\n",$option{url};
   while( my ($k, $v) = each %option ) {
           print "key: $k, value: $v\n";
   }
   
   print "\nURLS to get:\n";
   print join "\n", @Urls;
   print "\n";
   print "\n$0 end\n";
}

my $url = $option{url};

my %ae = ('a' => 'ArticleExtractor',
          'l' => 'LargestContentExtractor',
          'd' => 'DefaultExtractor',
          'c' => 'CanolaExtractor',
          'k' => 'KeepEverythingExtractor',
         );

my $strategy = $ae{$option{ae}} || "";

my $html   = ""; 

 my $ua = LWP::UserAgent->new;
 $ua->cookie_jar(HTTP::Cookies->new(file => "lwpcookies.txt",
                                      autosave => 1));

$ua->timeout(10);
$ua->env_proxy;
$ua->max_redirect(21);

use HTTP::Request::Common qw(GET);
# cheesyness for boilerpipe remove the url=___ which boilerpipe uses.
if($strategy && $Urls[0] =~ m/url\?/i)
{
   $Urls[0] =~ s/.*http/http/i;
   $Urls[0] =~ s/&.*//;
}

#my $strategy = $argStrategy; ## 'LargestContentExtractor';
my $boil22 = "http://boilerpipe-web.appspot.com/extract?url=". uri_escape($Urls[0]) . "&extractor=" . $strategy . "&output=htmlFragment";

if (!$strategy)
{
   $boil22 = $Urls[0];
}

  my $response = $ua->get($boil22);
  my $BASE; 
  
  if ($response->is_success) {
     #print "blank for now. FM\n"; ##$response->decoded_content;  # or whatever
     my $rt = HTML::TreeBuilder->new;
     $BASE = $response->base;
     my $h = $rt->parse($response->decoded_content);
     $h->traverse(\&expand_urls, 1);
     print $h->as_HTML;
  }
  else {
     print "FMDebug bad response for ($boil22)\n"; #die $response->status_line;
     #print $response->message;
     print $response->status_line;
  }

exit(0);

sub expand_urls
{
   my($e, $start) = @_;

   my  %link_elements =
   (
      'a'    => 'href',
      'img'  => 'src',
      'form' => 'action',
      'link' => 'href',
   );

   return 1 unless $start;   
   
   my $attr = $link_elements{$e->tag};
   return 1 unless defined $attr;


if ($link_elements{$e->tag} =~ /src/i)
{
   $e->delete();
   return;
}

   my $url = $e->attr($attr);
   
   return 1 unless defined $url;

   $url = URI->new_abs($url, $BASE);
   
   $e->attr($attr, $url);
}


sub get_urls() {
   my @Urls = ();
    for my $item (@ARGV) {
       push @Urls, $item;
    
    }
    return @Urls;
}

sub get_options() {
    use Getopt::Long;
    my $res = GetOptions(\%option,
                    'url=s',
                    'log=s',
                    'ae=s',
                    'debug',
                    'werr',
                    'verbose',
                    'help|?');
}

sub usage($)
{   my $rc = shift;

    warn <<USAGE;
Usage: $0 [options] url
options:
    --url       url to get
    --ae        extraction strategy
                A full-text extractor which is tuned towards news articles
    --log       log the sh__
    --debug     debug mode
    --verbose   print what is done including warnings etc.
    --help  -?  show this help
USAGE

    exit $rc;
}
