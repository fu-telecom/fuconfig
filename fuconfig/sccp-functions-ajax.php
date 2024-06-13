<?php

require 'vendor/autoload.php';

use Maclof\Kubernetes\Client as KubernetesClient;

include_once('FUConfig.php');

$pageRequest = new PageRequest($_REQUEST);

include_once('includes/defaults.php');
include_once('includes/db.php');

$request = $_GET['request'];
$namespace = 'default'; // Set the appropriate namespace
$labelSelector = 'app=asterisk'; // Label used to identify the Asterisk pod
$containerName = 'asterisk-container'; // Set the name of the container running Asterisk

$k8sClient = new KubernetesClient([
    'master' => 'https://kubernetes.default.svc', // Kubernetes API endpoint
    'token' => file_get_contents('/var/run/secrets/kubernetes.io/serviceaccount/token'),
    'ca_cert' => '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
]);

function getAsteriskPodName($k8sClient, $namespace, $labelSelector) {
    $pods = $k8sClient->pods()->setLabelSelector($labelSelector)->setNamespace($namespace)->find();
    if (count($pods) > 0) {
        return $pods[0]['metadata']['name'];
    }
    throw new Exception('Asterisk pod not found');
}

function execCommandInContainer($k8sClient, $namespace, $podName, $containerName, $command) {
    $exec = $k8sClient->podExec();
    $response = $exec->execute($namespace, $podName, $containerName, $command, 'POST');
    return $response->getBody();
}

try {
    $podName = getAsteriskPodName($k8sClient, $namespace, $labelSelector);

    if ($request == "reload") {
        $xml = new SimpleXMLElement('<xml/>');
        $phoneid = $_GET['phone_id'];

        $getPhoneSerialQry = "SELECT * FROM phones WHERE phone_id = ?;";
        $getPhoneSerial = $pdo->prepare($getPhoneSerialQry);
        $getPhoneSerial->execute([$phoneid]);

        $serial = $getPhoneSerial->fetch()['phone_serial'];
        if (!$serial) {
            throw new Exception('Phone serial not found for phone_id: ' . $phoneid);
        }

        $reloadcmd = 'asterisk -x "sccp reload device ' . $serial . '"';
        error_log('Executing command: ' . $reloadcmd);
        $result = execCommandInContainer($k8sClient, $namespace, $podName, $containerName, $reloadcmd);
        error_log('Command result: ' . $result);

        $xml->addChild("result", htmlspecialchars($result));
        $xml->addChild("phoneid", $phoneid);

        OutputXML($xml);
    } else if ($request == "restart") {
        $xml = new SimpleXMLElement('<xml/>');
        $phoneid = $_GET['phone_id'];

        $getPhoneSerialQry = "SELECT * FROM phones WHERE phone_id = ?;";
        $getPhoneSerial = $pdo->prepare($getPhoneSerialQry);
        $getPhoneSerial->execute([$phoneid]);

        $serial = $getPhoneSerial->fetch()['phone_serial'];
        if (!$serial) {
            throw new Exception('Phone serial not found for phone_id: ' . $phoneid);
        }

        $restartcmd = 'asterisk -x "sccp restart ' . $serial . '"';
        error_log('Executing command: ' . $restartcmd);
        $result = execCommandInContainer($k8sClient, $namespace, $podName, $containerName, $restartcmd);
        error_log('Command result: ' . $result);

        $xml->addChild("result", htmlspecialchars($result));
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
