if [ $# -lt 3 ] ; then
       echo "Command requires arguments. <macaddr> <phone_number> <name (no spaces)>"
       echo "Do not use spaces in any field!"
        exit 127
fi

echo "I'm executing your fucking phone install script, already. Fuck you."
echo "MAC: SEP$MACADDR"
echo "Number: $PHONENUM"
echo "Name: $CALLERIDNAME"
echo "I also set up voicemail. You can thank me later."
echo ""

MACADDR=$1
PHONENUM=$2
CALLERIDNAME=$3

cp /etc/asterisk/extensions.conf /etc/asterisk/extension.conf.backup
cp /etc/asterisk/sccp.conf /etc/asterisk/sccp.conf.backup
cp /etc/asterisk/voicemail.conf /etc/asterisk/voicemail.conf.backup

cp /tftproot/SEPdefault.cnf.xml /tftproot/SEP$MACADDR.cnf.xml

# Add to Dial Plan
echo "" >> /etc/asterisk/extensions.conf
echo "exten => $PHONENUM,hint,SCCP/$PHONENUM" >> /etc/asterisk/extensions.conf
echo "exten => $PHONENUM,1,Dial(SCCP/$PHONENUM, \${RINGTIME})" >> /etc/asterisk/extensions.conf
echo "exten => $PHONENUM,n,VoiceMail($PHONENUM@default,u)" >> /etc/asterisk/extensions.conf
echo "" >> /etc/asterisk/extensions.conf

# Add to SCCP Conf
echo "" >> /etc/asterisk/sccp.conf
echo "[SEP$MACADDR]" >> /etc/asterisk/sccp.conf
echo "description = $CALLERIDNAME" >> /etc/asterisk/sccp.conf
echo "type = device" >> /etc/asterisk/sccp.conf
echo "devicetype = 7940" >> /etc/asterisk/sccp.conf
echo "button = line, $PHONENUM  , default" >> /etc/asterisk/sccp.conf
echo "button = speeddial, \"Fuck You\", 0, 0@hints " >> /etc/asterisk/sccp.conf
echo "[$PHONENUM]" >> /etc/asterisk/sccp.conf
echo "type = line" >> /etc/asterisk/sccp.conf
echo "label = $PHONENUM - $CALLERIDNAME" >> /etc/asterisk/sccp.conf
echo "description = $CALLERIDNAME" >> /etc/asterisk/sccp.conf
echo "mailbox = $PHONENUM@default" >> /etc/asterisk/sccp.conf
echo "cid_name = $CALLERIDNAME" >> /etc/asterisk/sccp.conf
echo "cid_num = $PHONENUM" >> /etc/asterisk/sccp.conf
echo ";callgroup=1,3-4  ; might be useful for god line" >> /etc/asterisk/sccp.conf
echo ";pickupgroup=1,3-5  ; might be useful for god line" >> /etc/asterisk/sccp.conf
echo "context = default" >> /etc/asterisk/sccp.conf
echo "incominglimit = 2" >> /etc/asterisk/sccp.conf
echo ";transfer = on" >> /etc/asterisk/sccp.conf
echo "vmnum = 999  ;; Number to dial to get to the users Mailbox" >> /etc/asterisk/sccp.conf
echo "trnsfvm = $PHONENUM@default  ; extension to redirect the caller to for voice mail" >> /etc/asterisk/sccp.conf
echo "mwilamp = on" >> /etc/asterisk/sccp.conf
echo "" >> /etc/asterisk/sccp.conf

echo "$PHONENUM => ,$CALLERIDNAME,$PHONENUM@main.fuckyou" >> /etc/asterisk/voicemail.conf

asterisk -x "sccp reload"
asterisk -x "dialplan reload"

echo "Fucking done."

