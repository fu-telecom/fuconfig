set -ex

if [ $# -lt 5 ] ; then
       echo "Command requires arguments. <devicename> <phone_number> <callerid name (no spaces)> <listed name (no spaces)> <____directory.xml (or 'unlisted')>"
	   echo "As of FS2018 directories are: artcarsdirectory.xml campdirectory.xml departmentdirectory.xml FUTcorpdirectory.xml otherdirectory.xml"
       echo "Do not use spaces in any field! (Or you will fuck it all up.)"
        exit 127
fi

DEVICENAME=$1
EXTENSION=$2
CALLERIDNAME=$3
LISTNAME=$4
DIRECTORY=$5


echo "I'm executing your fucking phone install script, already. Fuck you."
echo "MAC: SEP$DEVICENAME"
echo "Extension: $EXTENSION"
echo "CallerID: $CALLERIDNAME"
echo "Listed Name: $LISTNAME"
echo "Directory: $DIRECTORY"
echo "I also set up voicemail and added you to $DIRECTORY  :P"
echo ""

cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup
cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.backup
cp /etc/asterisk/voicemail.conf /etc/asterisk/voicemail.conf.backup
cp /var/www/html/$DIRECTORY /var/www/html$DIRECTORY.backup


SIPFILE=/etc/asterisk/sip.conf
DIALFILE=/etc/asterisk/extensions.conf

echo "" >> $SIPFILE
echo "[$DEVICENAME](softphone,my-codecs)" >> $SIPFILE
echo "secret=$DEVICENAME" >> $SIPFILE
echo "callerid=$CALLERIDNAME <$EXTENSION>" >> $SIPFILE
echo "" >> $SIPFILE

echo "" >> $DIALFILE
echo "exten => $EXTENSION,hint,SIP/$DEVICENAME" >> $DIALFILE
echo "exten => $EXTENSION,1,Dial(SIP/$DEVICENAME, \${RINGTIME})" >> $DIALFILE
echo "exten => $EXTENSION,n,VoiceMail($EXTENSION@default,u)" >> $DIALFILE

echo "" >> $DIALFILE

echo "$EXTENSION => ,$LISTNAME,$EXTENSION@main.fuckyou" >> /etc/asterisk/voicemail.conf

# Add to directory

echo " " >> /var/www/html/$DIRECTORY
echo "<DirectoryEntry>" >> /var/www/html/$DIRECTORY
echo "<Name>$LISTNAME</Name>" >> /var/www/html/$DIRECTORY
echo "<Telephone>$PHONENUM</Telephone>" >> /var/www/html/$DIRECTORY
echo "</DirectoryEntry>" >> /var/www/html/$DIRECTORY
echo "</CiscoIPPhoneDirectory>" >> /var/www/html/$DIRECTORY

echo "$LISTNAME  $CALLERIDNAME $EXTENSION  $DIRECTORY" >> /tftproot/plaintext_directory.txt



asterisk -x "sip reload"
asterisk -x "dialplan reload"
