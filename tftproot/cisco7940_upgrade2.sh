if [ $# -lt 1 ] ; then
       echo "Command requires arguments. <macaddr>"
        exit 127
fi

echo "I'm executing your fucking phone upgrade script, already. Fuck you."
echo "MAC: SEP$MACADDR"
echo ""

MACADDR=$1

cp /tftproot/SEPupgrade2.cnf.xml /tftproot/SEP$MACADDR.cnf.xml


echo "Fucking done. Reboot the fucking phone if it's not already. Dont unplug it till it's done."
 
