#!/usr/bin/perl -w
use Getopt::Long;
use Pod::Usage;
use Mail::Box::Manager;

use Mail::Box::Mbox;

use strict 'vars';

#-----------
# prototypes
#-----------
sub get_options();
sub usage($);

my %option = (verbose => 0,
              werr => 0,
             );
get_options;

usage 0 if $option{help};

my $help = 0;
my $argMymail    = $option{bmymail}   || 0;
my $argDebug     = $option{debug}     || 0;
my $argThrottle  = $option{throttle}  || 0;
my $removeMsg    = $option{removeMsg} || '';
my $and          = $option{and}       || '';
my $argFrom      = $option{from}      ||'';
my $argSubject   = $option{subject}   || '';
my $argOut       = $option{out}       || "/usr/home/pl1321/JSAdmin/log/mymaillog.txt";
my $argLog       = $option{log}       || "/usr/home/pl1321/JSAdmin/log/mymaillog.raw.txt";

# un taint user input.
if ($argLog =~ m/^([A-Z0-9_.\-\/]+)$/ig) {
        $argLog = $1;                   # $data now untainted
    } else {
        die "Bad data in '$argLog'";    # log this somewhere
    }

if ($argOut =~ m/^([A-Z0-9_.\-\/]+)$/ig) {
        $argOut = $1;                   # $data now untainted
    } else {
        die "Bad data in '$argOut'";    # log this somewhere
    }

open(FLOG, ">>$argLog") || die print "joemailweb can not open($argLog)$!";
open(FOUT, ">$argOut") || die print "can not open($argOut)$!\n";

my $filename="/usr/home/pl1321/boxes/joeschedule.com/joemail";
#my $mgr    = Mail::Box::Manager->new;
#my $folder = $mgr->open($filename);

my $folder = Mail::Box::Mbox->new(folder => $filename, lock_type => 'none');

my $cnt=0;
foreach my $msg ($folder->messages) {

    if($msg->head->get('From') =~/MAILER-DAEMON\@www3.pairlite.com/i){next;}

    # Throttle - cheesy fix for now.  Fixes when there are many messages and google script times out.
    if ($argThrottle != 0)
    {
       if ($cnt == $argThrottle) {last;}
    }

#    print $msg->head->get('Subject');
#print "\neeeeeeeeeeeeeeeeeeeeeeeeeee\n";


print FLOG "______________\n";
print FLOG $msg->string;
print FLOG "\n";

    if($msg->head->get('Subject') !~ /$argSubject/i)
    {
my $subject = $msg->head->get('Subject');
print "$subject\n"  unless !$argDebug;
       next;
    }

    print $msg->head->get('Subject');

#FM 10/15/11    print FOUT "\n<MYMAIL>\n";

if ($argDebug)
{
print "\ndebug 11\n";
print $msg->cc;
print $msg->head->get('Cc');
print "\ndebug 22\n";

print "\nreply 11\n";
#my $cc =  $msg->head->get('Cc') || "";

my $reply = $msg->reply(    
#prelude         => "No spam, please!\n\n"
Cc => $msg->head->get('Cc') || "",
#Cc => $msg->head->get('Cc')
);
print $reply->head;
print "\nreply 22\n";

}

if (!$argMymail)
{
    print FOUT "\n<MYMAIL>\n";
}
else
{
   print FOUT "\n<MESSAGE>$cnt</MESSAGE>\n";
}    
    $cnt++;

print "\ndddddddddddd $cnt  ddddddddddddddd\n";

    my $body22; 

if($msg->isMultipart)
{
   foreach my $part ($msg->parts)
   {
      #$body22 .= "$part->body->size\n";
      $body22 = $part->decoded;
=comment
      $body22 = $part->string;
 my $content_type = $part->body->type;
 my $transfer_encoding = $part->body->transferEncoding;
print "\n $content_type \n  $transfer_encoding  \n";
 my $encoded = $part->body->encode(mime_type => 'text/html',
    charset => 'us-ascii', transfer_encoding => 'none');\n";
 my $decoded = $part->body->decoded;
=cut

   }
}
else
{
    $body22 = $msg->decoded;
}

    print "\n";    

my Mail::Message $reply = $msg->reply(Cc => $msg->head->get('Cc') || "");

my $ct = $msg->get('Content-Type');
$reply->head->delete('Content-Type');
$reply->head->add('Content-Type: text/html; charset="UTF-8"');

   my $head = $reply->head;

   if (!$argMymail)
   {
      print FOUT "<HEADER>\n"
   }

   print FOUT "$head";

if (!$argMymail)
{
   print FOUT "</HEADER>\n";
}

   print FOUT "$body22";

if (!$argMymail)
{
   print FOUT "\n</MYMAIL>"
}

 }
 $folder->close;
exit(0);

sub get_options() {
    use Getopt::Long;
    my $res = GetOptions(\%option,
                    'throttle=s',
                    'subject=s',
                    'from=s',
                    'removeMsg=s',
                    'out=s',
                    'log=s',
                    'and',
                    'debug',
                    'bmymail',
                    'werr',
                    'verbose',
                    'help|?');
}

sub usage($)
{   my $rc = shift;

    warn <<USAGE;
Usage: $0 [options]
options:
    --throttle number of msgs to read.
    --bmymail does NOT wrap messages w/ mymail tags.
    --subject Subject to search for uses regex.
    --from && subject must match.
    --removeMsg remove message.
    --Output file.
    --log       log the sh__
    --debug     debug mode
    --verbose   print what is done including warnings etc.
    --help  -?  show this help
USAGE

    exit $rc;
}

__END__
