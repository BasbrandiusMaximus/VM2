<html>
    <head>
        <title>VM2 webcluster <?php echo gethostname(); ?></title>
        <h1>Van Bastian Schiphouwer S1139625</h1>
    <style>
        body {
            background-color: grey;
            background-size: cover;
        }
    </style>
</head>
    <body>
        <br>
        <p>
            Hallo! Dit is mijn template pagina. Het werkt!
        </p>
        <br>
        <h1> Welkom op <?php echo gethostname(); ?></h1>
        <h2><?php echo php_uname(); ?></h2>
        <h2><?php $release_info = parse_ini_file("/etc/lsb-release");?>Distribution is: <?php echo $release_info["DISTRIB_DESCRIPTION"];?></h2>

        <?php
            $servername = "{{ groups['databaseservers'][0] }}";
            $username = "vagrant";
            $password = "vagrant";
            $dbname = "template-database.sql";

            $connection = new mysqli($servername, $username, $password, $dbname);
            if ($conn->connect_error){
                die("Connection failed: " $conn->connect_error);
            }
        ?>
        
        <br>
        <form method=post>
            <label>Klantnaam: </label><br>
            <input type="text" name="klantnaam" placeholder="Klant" required><br><br>
            <label>Klantnummer: </label><br>
            <input type="text" name="klantnummer" placeholder="001" required><br><br>
            <label>Omgeving: </label><br>
            <input type="text" name="omgeving" placeholder="ontwikkel" required><br><br>
            <label>Aantal omgevingen: </label><br>
            <input type="int" name="aantal_omgevingen" placeholder="1" required><br><br>
            <label>Servernaam: </label><br>
            <input type="text" name="servernaam" placeholder="klant1-ontwikkel-web1" required><br><br>
            <input type="submit" name="add" value="versturen">
        </form>

        <?php
        $sql = "SELECT klantnummer, klantnaam, omgeving, aantal_omgevingen, servernaam FROM Klanten";
        $result = $conn->query($sql);

        ?>

        <table>
            <th>
                Klantnummer
            </th>
            <th>
                Klantnaam
            </th>
            <th>
                Omgeving
            </th>
            <th>
                
            </th>
            <th>
                Klantnummer
            </th>
        </table>
    </body>
</html>