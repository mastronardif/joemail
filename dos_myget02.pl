#!/usr/bin/perl

#use CGI qw(:standard escapeHTML);

=comment
File: .pl

Purpose: 
=cut

require 5;
use strict;
use strict 'vars';

use URI;
require LWP::UserAgent;
use HTTP::Cookies;

#use LWP::Simple;
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

#my $url = $ARGV[0];
my $url = $option{url};
#my $strategy = $option{ae} || "LargestContentExtractor"; # or strait get url if boilplate reaches quota.

my %ae = ('a' => 'ArticleExtractor',
          'l' => 'LargestContentExtractor',
          'd' => 'DefaultExtractor',
          'c' => 'CanolaExtractor',
          'k' => 'KeepEverythingExtractor',
         );

my $strategy = $ae{$option{ae}} || "";


#my $url = $ARGV[0] || "http://www.google.com/url?sa=X&q=http://www.style.com/stylefile/2011/08/bernie-madoffs-pants-now-available-for-your-ipad/&ct=ga&cad=CAcQAhgAIAEoATAEOABAws-F8gRIAVgAYgVlbi1VUw&cd=GPz95wmTMrU&usg=AFQjCNFDeVJECiALh2Utp0TwJixJCh8CiQ";
#my $argStrategy = $ARGV[1] || "KeepEverythingExtractor";
#print "url($url)\n"; exit(0);

my $html   = ""; 
#get($url) || print "Couldn't get ($url)!"; #die "Couldn't get ($url)!";

#exit(0);	

 my $ua = LWP::UserAgent->new;
 $ua->cookie_jar(HTTP::Cookies->new(file => "lwpcookies.txt",
                                      autosave => 1));

 $ua->timeout(10);
 $ua->env_proxy;
$ua->max_redirect(21);
#print "ua->max_redirect" . $ua->max_redirect ."\n";

 ##my $response = $ua->get($url);
 
 
 
 # 8/17/11 begin
  use HTTP::Request::Common qw(GET);
#print "\n-2-2-2-2-2-2\n$Urls[0]\n 111111111111111111 \n";
# cheesyness for boilerpipe remove the url=___ which boilerpipe uses.
if($strategy && $Urls[0] =~ m/url\?/i)
{
   $Urls[0] =~ s/.*http/http/i;
   $Urls[0] =~ s/&.*//;
}

#print "\n--------\n$Urls[0]\n nnnnnnnnnnnnnnnnnnnnnnn\n"; exit(0);
  #my $strategy = $argStrategy; ## 'LargestContentExtractor';
  my $boil22 = "http://boilerpipe-web.appspot.com/extract?url=". uri_escape($Urls[0]) . "&extractor=" . $strategy . "&output=htmlFragment";

#if ($option{ae} eq 'n')
my $response;
my $BASE; 

my $nTrys = 0;
LINE: while($nTrys < 3) 
{
   $nTrys++;
if (!$strategy)
{
   $boil22 = $Urls[0];
}
#print "\n\n--------\n$boil22\n AAAAAAAAAAAAAAAAA \n";


  #  my $req = GET 'http://boilerpipe-web.appspot.com/extract?url=http://yahoo.com&extractor=CanolaExtractor&output=htmlFragment';
  #my $req = GET $boil22;
  #my $res = $ua->request($req);
  #print $res->decoded_content;
   
  $response = $ua->get($boil22);
  
  if ($response->is_success) {
     #print "blank for now. FM\n"; ##$response->decoded_content;  # or whatever
     my $rt = HTML::TreeBuilder->new;
     $BASE = $response->base;
     my $h = $rt->parse($response->decoded_content);
     $h->traverse(\&expand_urls, 1);
     print $h->as_HTML;
     last;
  }
  else {
        #try default if not tried.
      if ($strategy && $nTrys == 1)
      {
         $strategy = ""; # default no strategy
         #$nTrys = 2;
        
         next LINE;
      }

  
     print "FMDebug bad response for ($boil22)\n"; #die $response->status_line;
     #print $response->message;
     print $response->status_line;
     last;
  }
  
} 
  #print "\nTry($nTrys)\n";  
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


# FM begin 8/11/11 remove images
if ($link_elements{$e->tag} =~ /src/i)
{
#my $dummy = "BOBO";
##print "FMDEBUG(1)  ". $link_elements{$e->tag} . "\n";
#$e->attr("FFFFF");
	#$e->attr($link_elements{$e->tag}, $dummy);
$e->delete();

return;
}
# FM end 8/11/11

   my $url = $e->attr($attr);
   
   return 1 unless defined $url;
   

   #return 1 unless ($e->attr($attr) !~ /mailto:/i);

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
