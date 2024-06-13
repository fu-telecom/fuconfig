#set -ex

if [ $# -lt 5 ] ; then
	echo "Command requires arguments. <macaddr> <phone_number> <callerid name (no spaces)> <listed name (no spaces)> <optional directory number>"
	echo "  Directory List"
	echo "  1) Theme Camp Directory"
	echo "  2) FUT Corporate"
	echo "  3) Volunteer Departments"
	echo "  4) Art Cars"
	echo "  5) Pay Phones"
	echo "  6) Public Address"
	echo "  7) Ranger"
	echo "  -- Or leave empty for unlisted."
	echo ""

        exit 127
fi

MACADDR=$1
PHONENUM=$2
CALLERIDNAME=$3
LISTEDNAME=$4
DIRECTORY=$5

DIRECTORY_FILE[1]='campdirectory.xml'
DIRECTORY_FILE[2]='FUTcorpdirectory.xml'
DIRECTORY_FILE[3]='departmentdirectory.xml'
DIRECTORY_FILE[4]='artcarsdirectory.xml'
DIRECTORY_FILE[5]='payphonedirectory.xml'
DIRECTORY_FILE[6]='PAdirectory.xml'
DIRECTORY_FILE[7]='rangerdirectory.xml'

echo "I'm executing your fucking phone install script, already. Fuck you."
echo "MAC: SEP$MACADDR"
echo "Number: $PHONENUM"
echo "Caller ID Name: $CALLERIDNAME"
if [ -z $DIRECTORY ]
then
	echo "Unlisted In Directory"
else
	echo "Directory File Name: ${DIRECTORY_FILE[$DIRECTORY]}"
fi
echo ""
echo "Now wait 5 seconds..."
sleep 5




cp /etc/asterisk/extensions-phones.conf /etc/asterisk/extensions-phones.conf.backup
cp /etc/asterisk/sccp-phones.conf /etc/asterisk/sccp-phones.conf.backup
cp /etc/asterisk/voicemail-phones.conf /etc/asterisk/voicemail-phones.conf.backup
if ! [ -z $DIRECTORY ]
then
	cp /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]} /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}.backup
fi
cp /tftproot/SEPdefault.cnf.xml /tftproot/SEP$MACADDR.cnf.xml

# Add to Dial Plan
echo "" >> /etc/asterisk/extensions-phones.conf
#Now putting it in its own hints file... echo "exten => $PHONENUM,hint,SCCP/$PHONENUM" >> /etc/asterisk/extensions-phones.conf
echo "exten => $PHONENUM,1,Dial(SCCP/$PHONENUM, \${RINGTIME})" >> /etc/asterisk/extensions-phones.conf
echo "exten => $PHONENUM,n,VoiceMail($PHONENUM@default,u)" >> /etc/asterisk/extensions-phones.conf
echo "" >> /etc/asterisk/extensions-phones.conf

# Add to Hints File
echo "exten => $PHONENUM,hint,SCCP/$PHONENUM" >> /etc/asterisk/extensions-hints.conf


# Add to SCCP Conf
echo "" >> /etc/asterisk/sccp-phones.conf
echo "[SEP$MACADDR]" >> /etc/asterisk/sccp-phones.conf
echo "description = $LISTEDNAME" >> /etc/asterisk/sccp-phones.conf
echo "type = device" >> /etc/asterisk/sccp-phones.conf
echo "devicetype = 7940" >> /etc/asterisk/sccp-phones.conf
echo "button = line, $PHONENUM  , default" >> /etc/asterisk/sccp-phones.conf
echo "button = speeddial, \"Fuck You\", 0, 0@hints " >> /etc/asterisk/sccp-phones.conf
echo "[$PHONENUM]" >> /etc/asterisk/sccp-phones.conf
echo "type = line" >> /etc/asterisk/sccp-phones.conf
echo "label = $PHONENUM - $LISTEDNAME" >> /etc/asterisk/sccp-phones.conf
echo "description = $LISTEDNAME" >> /etc/asterisk/sccp-phones.conf
echo "mailbox = $PHONENUM@default" >> /etc/asterisk/sccp-phones.conf
echo "cid_name = $CALLERIDNAME" >> /etc/asterisk/sccp-phones.conf
echo "cid_num = $PHONENUM" >> /etc/asterisk/sccp-phones.conf
echo ";callgroup=1,3-4  ; might be useful for god line" >> /etc/asterisk/sccp-phones.conf
echo ";pickupgroup=1,3-5  ; might be useful for god line" >> /etc/asterisk/sccp-phones.conf
echo "context = default" >> /etc/asterisk/sccp-phones.conf
echo "incominglimit = 2" >> /etc/asterisk/sccp-phones.conf
echo ";transfer = on" >> /etc/asterisk/sccp-phones.conf
echo "vmnum = 2000  ;; Number to dial to get to the users Mailbox" >> /etc/asterisk/sccp-phones.conf
echo "trnsfvm = $PHONENUM@default  ; extension to redirect the caller to for voice mail" >> /etc/asterisk/sccp-phones.conf
echo "mwilamp = on" >> /etc/asterisk/sccp-phones.conf
echo "" >> /etc/asterisk/sccp-phones.conf

echo "$PHONENUM => ,$LISTEDNAME,$PHONENUM@main.fuckyou" >> /etc/asterisk/voicemail-phones.conf

# Add todirectory
if ! [ -z $DIRECTORY ]
then
# remove last line from $DIRECTORY file
sed "s#</CiscoIPPhoneDirectory>##" /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]} > /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}.2
mv /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}.2 /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}

echo " " >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "<DirectoryEntry>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "    <Name>$LISTEDNAME</Name>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "    <Telephone>$PHONENUM</Telephone>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "</DirectoryEntry>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "</CiscoIPPhoneDirectory>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}

# Put Number In Plaintext List for Random Call Script
echo "$PHONENUM" >> /tftproot/scripts/extensions-list.txt

# Plaintext Directory for Phone List
echo "$LISTEDNAME $CALLERIDNAME $PHONENUM ${DIRECTORY_FILE[$DIRECTORY]}" >> /tftproot/directory/plaintext_directory.txt
fi 


# Put Info In Button List
echo "button = speeddial, $LISTEDNAME, $PHONENUM, $PHONENUM@hints" >> /tftproot/scripts/buttons-list.txt 

# Generate Buttons List
/tftproot/scripts/buttons-list-7965.sh
/tftproot/scripts/buttons-list-7960.sh

echo "Reloading Asterisk"

sleep 1

asterisk -x "sccp reload"
asterisk -x "dialplan reload"

sleep 90

asterisk -x "sccp reload device SEP$MACADDR"

echo "Fucking done."
