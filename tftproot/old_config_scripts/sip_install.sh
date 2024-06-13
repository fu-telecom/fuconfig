set -ex

if [ $# -lt 3 ] ; then
       echo "Command requires arguments. <macaddr> <phone_number> <name (no spaces)>"
       echo "Do not use spaces in any field! (Or you will fuck it all up.)"
        exit 127
fi

MACADDR=$1
EXTENSION=$2
NAME=$3

echo "I'm executing your fucking phone install script, already. Fuck you."
echo "MAC: SEP$MACADDR"
echo "Extension: $EXTENSION"
echo "Name: $NAME"
echo "I also set up voicemail. You can thank me later."
echo ""

SIPFILE=/etc/asterisk/sip.conf
DIALFILE=/etc/asterisk/extensions.conf

echo "" >> $SIPFILE
echo "[$MACADDR](softphone,my-codecs)" >> $SIPFILE
echo "secret=$MACADDR" >> $SIPFILE
echo "callerid=$NAME <$EXTENSION>" >> $SIPFILE
echo "" >> $SIPFILE

echo "" >> $DIALFILE
echo "exten => $EXTENSION,hint,SIP/$MACADDR" >> $DIALFILE
echo "exten => $EXTENSION,1,Dial(SIP/$MACADDR, \${RINGTIME})" >> $DIALFILE
echo "" >> $DIALFILE

asterisk -x "sip reload"
asterisk -x "dialplan reload"
