#!/usr/local/bin/ksh

#lastmodified: 10/21/2011 2:25 pm

START=$(date +%s)
print "Content-type: text/html\n\n"
print "\n<hr><br>\n"
mypath='/usr/www/users/pl1321/cgi-bin'
myOutpath='/usr/home/pl1321/JSAdmin/log'

THROTTLE=`echo "$QUERY_STRING" | grep -oE "(^|[?&])throttle=[0-9]+" | cut -f 2 -d "=" | head -n1`

if [ "$THROTTLE" -gt "0" ]
then
THROTTLE="-throttle $THROTTLE"
fi

eval $(stat -s /usr/home/pl1321/boxes/joeschedule.com/joemail)
#echo $st_size $st_mtimespec

if [ "$st_size" -le "600" ]
then
   echo "\t\t No Mail! $(date)"
   exit 0
fi


cd $mypath

if /usr/bin/perl -wt $mypath/testmymbox03.pl $THROTTLE -s "joemailweb"  -o \
$myOutpath/mymaillog.txt  | /usr/bin/grep -i "joemailweb" -A2 -B2 
then
 echo "<br><h1>Yes we can continue version 9-14-11  $(date)</h1>"

/usr/bin/perl $mypath/myexp02.pl           $myOutpath/mymaillog.txt     > $myOutpath/mymaillog22a.txt
/usr/bin/perl $mypath/testmyexptags05.pl   $myOutpath/mymaillog22a.txt  > $myOutpath/err0.txt
/usr/bin/perl $mypath/myhtoe02.pl          $myOutpath/err0.txt          > $myOutpath/err.txt

/usr/bin/perl $mypath/mysend04.pl          $myOutpath/err.txt

/usr/www/users/pl1321/cgi-bin/gocleanmbox.sh

echo  "<br/>test3 "
elif /usr/bin/perl -wt $mypath/testmymbox03.pl $THROTTLE -bmymail -s '.' \
-log $myOutpath/mymaillog.raw.txt \
-o $myOutpath/mymaillog.txt | /usr/bin/grep -i "." -A2 -B2
then
 echo "joeping any subject google etc!"
/usr/bin/perl $mypath/myhtoe.pl           $myOutpath/mymaillog.txt  > $myOutpath/err.txt
/usr/bin/perl $mypath/mysend04.pl         $myOutpath/err.txt

/usr/www/users/pl1321/cgi-bin/gocleanmbox.sh

else
 echo "No joemailweb mail(test)!"
 echo "<br/>-------------<br/>"
fi
chmod 666 /usr/home/pl1321/boxes/joeschedule.com/joemail^/.imap/joemail/sent88
print "<br/>Done! 05"

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $DIFF seconds"

