#set -ex

if [ $# -lt 5 ] ; then
        echo "Command requires arguments. <devicename> <phone_number> <callerid name (no spaces)> <listed name (no spaces)> <optional directory number (use list number)>"
        echo "  Directory List"
        echo "  1) Theme Camp Directory"
        echo "  2) FUT Corporate"
        echo "  3) Volunteer Departments"
        echo "  4) Art Cars"
        echo "  5) Pay Phones"
        echo "  6) Public Address"
        echo "  -- Or leave empty for unlisted."
        echo ""

        exit 127
fi

DEVICENAME=$1
EXTENSION=$2
CALLERIDNAME=$3
LISTNAME=$4
DIRECTORY=$5

DIRECTORY_FILE[1]='campdirectory.xml'
DIRECTORY_FILE[2]='FUTcorpdirectory.xml'
DIRECTORY_FILE[3]='departmentdirectory.xml'
DIRECTORY_FILE[4]='artcarsdirectory.xml'
DIRECTORY_FILE[5]='payphonedirectory.xml'
DIRECTORY_FILE[6]='PAdirectory.xml'

echo "I'm executing your fucking phone install script, already. Fuck you."
echo "MAC: SEP$DEVICENAME"
echo "Extension: $EXTENSION"
echo "CallerID: $CALLERIDNAME"
echo "Listed Name: $LISTNAME"
if [ -z $DIRECTORY ]
then
        echo "Unlisted In Directory"
else
        echo "Directory File Name: ${DIRECTORY_FILE[$DIRECTORY]}"
fi
echo "I will also setup voicemail, the 7960/7965 buttons, and the random extensions list.  :P"
echo ""

SIPFILE=/etc/asterisk/sip-phones.conf
DIALFILE=/etc/asterisk/extensions-phones.conf
VOICEMAILFILE=/etc/asterisk/voicemail-phones.conf
HINTSFILE=/etc/asterisk/extensions-hints.conf

BUTTONS_LIST_FILE=/asterisk_scripts/buttons_list/buttons-list-cli.txt
EXTENIONS_LIST_FILE=/asterisk_scripts/extensions-list-cli.txt
PLAINTEXT_DIRECTORY_FILE=/tftproot/directory/plaintext_directory-cli.txt

#Create Backups
cp $DIALFILE $DIALFILE.backup
cp $SIPFILE $SIPFILE.backup
cp $VOICEMAILFILE $VOICEMAILFILE.backup
if ! [ -z $DIRECTORY ]
then
        cp /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]} /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}.backup
fi

echo "" >> $SIPFILE
echo "[$DEVICENAME](softphone,my-codecs)" >> $SIPFILE
echo "secret=$DEVICENAME" >> $SIPFILE
echo "callerid=$CALLERIDNAME <$EXTENSION>" >> $SIPFILE
echo "" >> $SIPFILE

echo "" >> $DIALFILE
echo ";SIP PHONE" >> $DIALFILE
echo "exten => $EXTENSION,hint,SIP/$DEVICENAME" >> $HINTSFILE
echo "exten => $EXTENSION,1,Dial(SIP/$DEVICENAME, \${RINGTIME})" >> $DIALFILE
echo "exten => $EXTENSION,n,VoiceMail($EXTENSION@default,u)" >> $DIALFILE

echo "" >> $DIALFILE

echo "$EXTENSION => ,$LISTNAME,$EXTENSION@main.fuckyou" >> $VOICEMAILFILE


# Add todirectory
if ! [ -z $DIRECTORY ]
then
# remove last line from $DIRECTORY file
sed "s#</CiscoIPPhoneDirectory>##" /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]} > /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}.2
mv /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}.2 /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}

echo " " >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "<DirectoryEntry>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "    <Name>$LISTNAME</Name>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "    <Telephone>$EXTENSION</Telephone>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "</DirectoryEntry>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}
echo "</CiscoIPPhoneDirectory>" >> /var/www/html/directory/${DIRECTORY_FILE[$DIRECTORY]}



# Put Number In Plaintext List for Random Call Script
echo "SIP/$EXTENSION" >> $EXTENIONS_LIST_FILE

# Plaintext Directory for Phone List
echo "$LISTNAME $CALLERIDNAME $EXTENSION ${DIRECTORY_FILE[$DIRECTORY]}" >> $PLAINTEXT_DIRECTORY_FILE
fi

# === Put Info In Button List
echo "button = speeddial, $LISTNAME, $EXTENSION, $EXTENSION@hints" >> $BUTTONS_LIST_FILE


# === Generate Buttons List
/asterisk_scripts/buttons_list/buttons-list-7965.sh
/asterisk_scripts/buttons_list/buttons-list-7960.sh




# === Asterisk Reload
echo "Reloading Asterisk, twice, because why the fuck not. Gimme 5."

asterisk -x "sip reload"
asterisk -x "sccp reload"
asterisk -x "dialplan reload"

#sleep 5

#asterisk -x "sccp reload"

echo "Fucking Done."
