<?php
// Include necessary files
include_once ('FUConfig.php');
$pageRequest = new PageRequest($_REQUEST);
include_once ('includes/defaults.php');
include_once ('includes/db.php');

$request = $_GET['request'];
$namespace = 'default'; // Set the appropriate namespace
$labelSelector = 'app=asterisk'; // Label used to identify the Asterisk pod
$kubectlPath = '/usr/bin/kubectl';
putenv('KUBECONFIG=/home/www-data/.kube/config');

// Function to get the name of the Asterisk pod
function getAsteriskPodName($namespace, $labelSelector, $kubectlPath) {
    // Add debugging statement
    $command = "$kubectlPath get pods -n $namespace -l $labelSelector -o jsonpath='{.items[0].metadata.name}' 2>&1";
    error_log("Running getAsteriskPodName with command: $command");
    $output = shell_exec($command);
    error_log("kubectl command output: $output");
    if (!$output) {
        throw new Exception('Asterisk pod not found');
    }
    return trim($output);
}

// Function to execute a command in the Asterisk container
function execCommandInContainer($namespace, $podName, $command, $kubectlPath) {
    // Add debugging statement
    $execCommand = "$kubectlPath exec -n $namespace $podName -- $command 2>&1";
    error_log("Running execCommandInContainer with command: $execCommand");
    $result = shell_exec($execCommand);
    error_log("Command output: $result");
    if (!$result) {
        throw new Exception('Command execution failed or returned no output');
    }
    if (strpos($result, 'Error') !== false) {
        throw new Exception('Error executing command: ' . $result);
    }
    return $result;
}

try {
    error_log("Request received: $request");
    $podName = getAsteriskPodName($namespace, $labelSelector, $kubectlPath);
    error_log("Asterisk pod name: $podName");

    if ($request == "reload") {
        $xml = new SimpleXMLElement('<xml/>');
        $phoneid = $_GET['phone_id'];
        error_log("Processing reload for phone_id: $phoneid");

        $getPhoneSerialQry = "SELECT * FROM phones WHERE phone_id = ?;";
        $getPhoneSerial = $pdo->prepare($getPhoneSerialQry);
        $getPhoneSerial->execute([$phoneid]);

        $serial = $getPhoneSerial->fetch()['phone_serial'];
        if (!$serial) {
            throw new Exception('Phone serial not found');
        }
        error_log("Phone serial: $serial");

        $reloadcmd = 'asterisk -x "sccp reload device ' . $serial . '"';
        $result = execCommandInContainer($namespace, $podName, $reloadcmd, $kubectlPath);

        $xml->addChild("result", $result);
        $xml->addChild("phoneid", $phoneid);

        OutputXML($xml);
    } else if ($request == "restart") {
        $xml = new SimpleXMLElement('<xml/>');
        $phoneid = $_GET['phone_id'];
        error_log("Processing restart for phone_id: $phoneid");

        $getPhoneSerialQry = "SELECT * FROM phones WHERE phone_id = ?;";
        $getPhoneSerial = $pdo->prepare($getPhoneSerialQry);
        $getPhoneSerial->execute([$phoneid]);

        $serial = $getPhoneSerial->fetch()['phone_serial'];
        if (!$serial) {
            throw new Exception('Phone serial not found');
        }
        error_log("Phone serial: $serial");

        $restartcmd = 'asterisk -x "sccp restart ' . $serial . '"';
        $result = execCommandInContainer($namespace, $podName, $restartcmd, $kubectlPath);

        $xml->addChild("result", $result);
        $xml->addChild("phoneid", $phoneid);

        OutputXML($xml);
    } else if ($request == "redo") {
        error_log("Processing redo for phone_id: " . $pageRequest->phone_id);
        $phone = Phone::LoadPhoneByID($pageRequest->phone_id);
        if (!$phone) {
            throw new Exception('Phone not found');
        }

        // Remove the phone and reload it.
        $sccpProcessor = new SccpProcessor();
        if (!$sccpProcessor->DeletePhoneAsterisk($phone)) {
            throw new Exception('Failed to delete phone from Asterisk');
        }
        if (!$sccpProcessor->AddPhoneAsterisk($phone)) {
            throw new Exception('Failed to add phone to Asterisk');
        }
        if (!$sccpProcessor->ReloadPhone($phone)) {
            throw new Exception('Failed to reload phone in Asterisk');
        }

        $xml = new SimpleXMLElement('<xml/>');
        $result = new Result();
        $result->phone_id = $phone->phone_id;
        $result->result = "Phone is redone, except for any lines.";
        $result->AddResultToXml($xml);
        OutputXML($xml);
    } else {
        throw new Exception('Invalid request type');
    }
} catch (Exception $e) {
    error_log('Error: ' . $e->getMessage());
    http_response_code(500);
    echo 'Internal Server Error';
}
?>
