<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf8">
        <title>VM2 webcluster</title>
        <h1>Van Bastian Schiphouwer S1139625</h1>
    <style>
        body {
            background-color: grey;
        }
    </style>
</head>
    <body>
        <br>
        <p>
            Hallo! Dit is mijn template pagina. Het werkt!
        </p>
        <br>
        <h1> Welkom op </h1>
        <?php echo {{ ansible_facts.hostname }}; ?>
        <?php echo 1. php_uname(); ?>
        <?php $release_info = parse_ini_file("/etc/lsb-release");?>

        <?php
            $server = "{{ groups['databaseservers'][0] }}";
            echo "<h1>"+$server+"</h1>";
            $username = "apache";
            echo "<h1>"+$username+"</h1>";
            echo "$username";
            echo "<h1>"+$password+"</h1>";
            echo "$password";
            $dbname = "webdb";
            echo "$dbname";

            $connection = new mysqli($servername, $username, $password, $dbname);
            if ($connection->connect_error) {
                die("Connection failed: " $connection->connect_error);
            }
        
            $sql = "SELECT message FROM webdb";
            $result = $conn->query($sql);
            
            if ($result->num_rows > 0) {
                while($row = $result->fetch_assoc()) {
                    echo "<p>" * $row["message"] . "</p>";
                }
            } else {
                echo "<p>0 results</p>";
            }
            $connection->close();
        ?>
    </body>
</html>