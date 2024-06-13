<?php

// Include necessary files
include_once ('FUConfig.php');
$pageRequest = new PageRequest($_REQUEST);
include_once ('includes/defaults.php');
include_once ('includes/db.php');

$request = $_GET['request'];
$namespace = 'default'; // Set the appropriate namespace
$labelSelector = 'app=asterisk'; // Label used to identify the Asterisk pod

// Function to get the name of the Asterisk pod
function getAsteriskPodName($namespace, $labelSelector) {
    $command = "kubectl get pods -n $namespace -l $labelSelector -o jsonpath='{.items[0].metadata.name}'";
    $podName = shell_exec($command);
    return trim($podName);
}

// Function to execute a command in the Asterisk container
function execCommandInContainer($namespace, $podName, $command) {
    $execCommand = "kubectl exec -n $namespace $podName -- $command";
    $result = shell_exec($execCommand);
    return $result;
}

try {
    $podName = getAsteriskPodName($namespace, $labelSelector);

    if ($request == "reload") {
        $xml = new SimpleXMLElement('<xml/>');
        $phoneid = $_GET['phone_id'];

        $getPhoneSerialQry = "SELECT * FROM phones WHERE phone_id = ?;";
        $getPhoneSerial = $pdo->prepare($getPhoneSerialQry);
        $getPhoneSerial->execute([$phoneid]);

        $serial = $getPhoneSerial->fetch()['phone_serial'];

        $reloadcmd = 'asterisk -x "sccp reload device ' . $serial . '"';
        $result = execCommandInContainer($namespace, $podName, $reloadcmd);

        $xml->addChild("result", $result);
        $xml->addChild("phoneid", $phoneid);

        OutputXML($xml);
    } else if ($request == "restart") {
        $xml = new SimpleXMLElement('<xml/>');
        $phoneid = $_GET['phone_id'];

        $getPhoneSerialQry = "SELECT * FROM phones WHERE phone_id = ?;";
        $getPhoneSerial = $pdo->prepare($getPhoneSerialQry);
        $getPhoneSerial->execute([$phoneid]);

        $serial = $getPhoneSerial->fetch()['phone_serial'];

        $restartcmd = 'asterisk -x "sccp restart ' . $serial . '"';
        $result = execCommandInContainer($namespace, $podName, $restartcmd);

        $xml->addChild("result", $result);
        $xml->addChild("phoneid", $phoneid);

        OutputXML($xml);
    } else if ($request == "redo") {
        $phone = Phone::LoadPhoneByID($pageRequest->phone_id);

        // Remove the phone and reload it.
        $sccpProcessor = new SccpProcessor();
        $sccpProcessor->DeletePhoneAsterisk($phone);
        $sccpProcessor->AddPhoneAsterisk($phone);
        $sccpProcessor->ReloadPhone($phone);

        $xml = new SimpleXMLElement('<xml/>');
        $result = new Result();
        $result->phone_id = $phone->phone_id;
        $result->result = "Phone is redone, except for any lines.";
        $result->AddResultToXml($xml);
        OutputXML($xml);
    }
} catch (Exception $e) {
    error_log('Error: ' . $e->getMessage());
    http_response_code(500);
    echo 'Internal Server Error';
}

?>
