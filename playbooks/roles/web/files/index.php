<html>
    <head>
        <title>VM2 webcluster <?php echo gethostname(); ?></title>
    <style>
        body {
            background-color: blue;
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
            $servername = 
            $username = 
            $password = 
            $dbname = "template-database.sql"
        ?>
        
        <br>
        <? echo $_SERVER["REMOTE_ADDR"]; ?>
    </body>
</html>