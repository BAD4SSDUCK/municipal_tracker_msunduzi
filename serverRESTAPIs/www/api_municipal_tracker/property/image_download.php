<?php
include '../connection.php';

$address = $_GET['address'];

$result = $conn->query("SELECT * FROM imageTable ORDER BY id DESC WHERE address ='$address'");
$list = array();
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $list[] = $row;
    }
    echo json_encode($list);
}
?>