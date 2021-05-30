#!/bin/bash

#map aanmaken en omgeving kopieren
copy_file(){
    cp /home/VM2/template-omgeving/Vagrantfile /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
    sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
    sed -i "s/ipaddress/$_klantnummer/g" /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
    cp /home/VM2/template-omgeving/ansible.cfg /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/ansible.cfg

    #start met aanmaken van de inventoryfile
    if [ -f "$_klantdir/inventory.ini" ]; then
        echo "Inventory file bestaat nog, de oude wordt verwijderd."
        rm $_klantdir/inventory.ini
    fi
    
    #aanmaken inventory file
    touch $_klantdir/inventory.ini

    #voeg web toe aan inventory
    if [ $WEB == "true" ]; then
        echo "[webservers]" >>$_klantdir/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $WEB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.2$COUNTER" >>$_klantdir/inventory.ini
        done
        echo "" >>$_klantdir/inventory.ini
    fi

    #voeg lb toe aan inventory
    if [[ $LB == "true" ]]; then
        echo "[loadbalancers]" >>$_klantdir/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $LB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.3$COUNTER" >>$_klantdir/inventory.ini
        done
        echo "" >>$_klantdir/inventory.ini
        echo "[loadbalancers:vars]" >>$_klantdir/inventory.ini
        echo "bind_port=$LB_PORT" >>$_klantdir/inventory.ini
        echo "stats_port=$LB_STATS_PORT" >>$_klantdir/inventory.ini
        echo "" >>$_klantdir/inventory.ini
    fi

    #voeg db toe aan inventory
    if [ $DB == "true" ]; then
        echo "[databaseservers]" >>$_klantdir/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $DB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.4$COUNTER" >>$_klantdir/inventory.ini
        done
        echo "" >>$_klantdir/inventory.ini
    fi

    #sla properties op in config.txt
    echo "ENVIRONMENT=$_type" >>$_klantdir/config.txt
    echo "WEB=$WEB" >>$_klantdir/config.txt
    echo "WEB_AANTAL=$WEB_AANTAL" >>$_klantdir/config.txt
    echo "WEB_MEMORY=$WEB_MEMORY" >>$_klantdir/config.txt
    echo "LB=$LB" >>$_klantdir/config.txt
    echo "LB_AANTAL=$LB_AANTAL" >>$_klantdir/config.txt
    echo "LB_MEMORY=$LB_MEMORY" >>$_klantdir/config.txt
    echo "LB_PORT=$LB_PORT" >>$_klantdir/config.txt
    echo "LB_STATS_PORT=$LB_STATS_PORT" >>$_klantdir/config.txt
    echo "DB=$DB" >>$_klantdir/config.txt
    echo "DB_AANTAL=$DB_AANTAL" >>$_klantdir/config.txt
    echo "DB_MEMORY=$DB_MEMORY" >>$_klantdir/config.txt
}

#Vagrant file web/lb/db-variabelen veranderen
vagrant_file(){
    sed -i "s/{{ web_config }}/$WEB/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ web_aantal }}/$WEB_AANTAL/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ web_memory }}/$WEB_MEMORY/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ lb_config }}/$LB/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ lb_aantal }}/$LB_AANTAL/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ lb_memory }}/$LB_MEMORY/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ db_config }}/$DB/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ db_aantal }}/$DB_AANTAL/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ db_memory }}/$DB_MEMORY/g" "$_klantdir/Vagrantfile"
}

#voor verwijderen omgeving
vagrant_destroy(){
    read -p "Wat is uw klantnaam?: " _bestaandeklantnaam
    read -p "Wat is uw klantnummer: " _bestaandeklantnummer
    _bestaandeklant="$_bestaandeklantnaam-$_bestaandeklantnummer"
    read -p "Welke omgeving wilt u verwijderen [ontwikkel, test, acceptatie, productie]? " _omgevingverwijderen
    (cd "/home/VM2/klanten/$_bestaandeklant"/"$_omgevingverwijderen" && vagrant destroy -f)
    rm -r "/home/VM2/klanten/$_bestaandeklant"
    exit 0
}

#voor aanpassingen
vagrant_edit(){
    read -p "Wat is uw klantnaam?: " _klantnaam
    read -p "Wat is uw klantnummer: " _klantnummer
    _editklant="$_klantnaam-$_klantnummer"
    echo $_editklant
    read -p "Welke omgeving wilt u aanpassen [ontwikkel, test, acceptatie, productie]? " _type

    #Set _klantdir naar huidige klant
    _klantdir="/home/VM2/klanten/$_editklant"/"$_type"

    #kopieer informatie from config.txt
    source "$_klantdir/config.txt"
    WEB_AANTAL_OLD=$WEB_AANTAL
    WEB_MEMORY_OLD=$WEB_MEMORY
    LB_AANTAL_OLD=$LB_AANTAL
    LB_MEMORY_OLD=$LB_MEMORY
    LB_PORT_OLD=$LB_PORT
    LB_STATS_PORT_OLD=$LB_STATS_PORT
    DB_AANTAL_OLD=$DB_AANTAL
    DB_MEMORY_OLD=$DB_MEMORY


    #Verander klant-webserver
    read -p "Wilt u de webservers aanpassen? [true/false]: " _edit_web
    if [ $_edit_web == "true" ]; then
        read -p "Hoeveel webservers? [Er is/zijn nu $WEB_AANTAL] " WEB_AANTAL
        if [[ $WEB_AANTAL -eq "" ]]; then
            WEB_AANTAL="$WEB_AANTAL_OLD"
        fi
        read -p "Hoeveel geheugen? [Er is nu $WEB_MEMORY(MB)] " WEB_MEMORY
        if [[ $WEB_MEMORY -eq "" ]]; then
            WEB_MEMORY="$WEB_MEMORY_OLD"
        fi
    fi

    #Verander klant-loadbalancer
    if [ "$_type" == "acceptatie" ] || [ "$_type" == "productie" ]; then
        read -p "Wilt u de loadbalancers aanpassen? [true/false]: " _edit_lb
        if [[ $_edit_lb == "true" ]]; then
            read -p "Hoeveel loadbalancers? [Er is/zijn nu $LB_AANTAL] " LB_AANTAL
            if [[ $LB_AANTAL -eq "" ]]; then
                LB_AANTAL="$LB_AANTAL_OLD"
            fi
            read -p "Hoeveel geheugen? [Er is nu $LB_MEMORY(MB)] " LB_MEMORY
            if [[ $LB_MEMORY -eq "" ]]; then
                LB_MEMORY="$LB_MEMORY_OLD"
            fi
            read -p "Welke poort om de site te bereiken? [Het staat nu op poort $LB_PORT] " LB_PORT
            if [[ $LB_PORT -eq "" ]]; then
                LB_PORT="$LB_PORT_OLD"
            fi
            read -p "Welke poort om de stats te bereiken? [Het staat nu op poort $LB_STATS_PORT] " LB_STATS_PORT
            if [[ $LB_STATS_PORT -eq "" ]]; then
                LB_STATS_PORT="$LB_STATS_PORT_OLD"
            fi
        fi
    fi

    #verander klant-database
    read -p "Wilt u de databaseservers aanpassen? [true/false]: " _edit_db
    if [[ $edit_db == "true" ]]; then
        read -p "Hoeveel databaseservers? [Er is/zijn nu $DB_AANTAL] " DB_AANTAL
        if [[ $DB_AANTAL -eq "" ]]; then
            DB_AANTAL="$DB_AANTAL_OLD"
        fi
        read -p "Hoeveel geheugen? [Er is nu $DB_MEMORY(MB)] " DB_MEMORY
        if [[ $DB_MEMORY -eq "" ]]; then
            DB_MEMORY="$DB_MEMORY_OLD"
        fi
    fi

    while [ $WEB_AANTAL -lt $WEB_AANTAL_OLD ]; do
        (cd $_klantdir && vagrant destroy "$_editklant-$_type-web-$WEB_AANTAL_OLD" -f)
        WEB_AANTAL_OLD=$(expr $WEB_AANTAL_OLD - 1)
    done
    while [ $LB_AANTAL -lt $LB_AANTAL_OLD ]; do
        (cd $_klantdir && vagrant destroy "$_editklant-$_type-loadbalancer-$LB_AANTAL_OLD" -f)
        LB_AANTAL_OLD=$(expr $LB_AANTAL_OLD - 1)
    done
    while [ $DB_AANTAL -lt $DB_AANTAL_OLD ]; do
        (cd $_klantdir && vagrant destroy "$_editklant-$_type-database-$DB_AANTAL_OLD" -f)
        DB_AANTAL_OLD=$(expr $DB_AANTAL_OLD - 1)
    done

    rm "$_klantdir/Vagrantfile"
    rm "$_klantdir/config.txt"
    rm "$_klantdir/inventory.ini"
    rm "$_klantdir/ansible.cfg"
    copy_file
    sed -i "s/klantnaam/$_editklant-$_type/g" "$_klantdir/Vagrantfile"
    sed -i "s/ipaddress/$_klantnummer/g" "$_klantdir/Vagrantfile"

    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####   $_type omgeving wordt aangemaakt    #####"
    echo "####################################################"
    echo
    vagrant_file
    (cd $_klantdir && vagrant reload)
    (cd $_klantdir && vagrant up)
    sleep 1m
    echo
    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####   $_type omgeving wordt geconfigureerd    #####"
    echo "####################################################"
    echo
    (cd $_klantdir && ansible-playbook /home/VM2/playbooks/playbook.yml)
    exit 0
}

#Voor nieuwe klanten
vagrant_nieuw(){
    #Vraag $_klantnaam en $_klantnummer
    read -p "Klantnaam: " _klantnaam
    source /home/VM2/klanten/klantnummer.sh
    _klantnummer=$((_klantnummer+1))
    echo "_klantnummer=$_klantnummer" > /home/VM2/klanten/klantnummer.sh
    echo

    #vraag om type en maak mappen structuur aan
    echo "##### Type omgeving ###############"
    read -p "Omgeving type [ontwikkel/test/acceptatie/productie] [default acceptatie]: " _type
        if [[ $_type == "" ]]; then
            _type="acceptatie"
        fi
    echo

    #Webservers vraag
    echo "##### Webservers ##################"
    read -p "Wilt u webservers [true/false] [DEFAULT true]?: " WEB
        if [[ $WEB -eq "" ]]; then
            WEB="true"
        fi
    if [ "$WEB" == "true" ]; then
        read -p "Aantal webservers [DEFAULT 2]: " WEB_AANTAL
            if [[ $WEB_AANTAL -eq "" ]]; then
                WEB_AANTAL="2"
            fi
        read -p "Geheugen webservers [DEFAULT 1024(MB)]: " WEB_MEMORY
            if [[ $WEB_MEMORY -eq "" ]]; then
                WEB_MEMORY="1024"
            fi
    else
        WEB=false
        WEB_AANTAL=0
        WEB_MEMORY=0
    fi
    echo

    #loadbalancers vraag (ontwikkel en test krijgen geen loadbalancers)
    if [[ $_type == "acceptatie" ]]; then
        echo "##### Loadbalancers ###############"
        read -p "Wilt u loadbalancers [true/false] [DEFAULT true]?: " LB
            if [[ $LB == "" ]]; then
                LB="true"
            fi
            if [ "$LB" == "true" ]; then
            read -p "Aantal loadbalancers [DEFAULT 1]: " LB_AANTAL
                if [[ $LB_AANTAL -eq "" ]]; then
                    LB_AANTAL="1"
                fi
            read -p "Geheugen loadbalancers [DEFAULT 1024(MB)]: " LB_MEMORY
                if [[ $LB_MEMORY -eq "" ]]; then
                    LB_MEMORY="1024"
                fi
            read -p "Port loadbalancer [DEFAULT 80]: " LB_PORT
                if [[ $LB_PORT -eq "" ]]; then
                    LB_PORT="80"
                fi
            read -p "Port stats loadbalancer [DEFAULT 8080]: " LB_STATS_PORT
                if [[ $LB_STAT_PORT -eq "" ]]; then
                    LB_STATS_PORT="8080"
                fi
            fi
        else
            LB=false
            LB_AANTAL=0
            LB_MEMORY=0
            LB_PORT=80
            LB_STATS_PORT=8080
    fi
    echo

    #databases vraag
    echo "##### Databaseservers #############"
    read -p "Wilt u databaseservers [true/false] [DEFAULT true]?: " DB
        if [[ $DB -eq "" ]]; then
            DB="true"
        fi
    if [ $DB == "true" ]; then
        read -p "Aantal databaseservers [DEFAULT 1]: " DB_AANTAL
            if [[ $DB_AANTAL -eq "" ]]; then
                DB_AANTAL="1"
            fi
        read -p "Geheugen databaseservers [DEFAULT 2048(MB)]?: " DB_MEMORY
            if [[ $DB_MEMORY -eq "" ]]; then
                DB_MEMORY="2048"
            fi
    else
        DB=false
        DB_AANTAL=0
        DB_MEMORY=0
    fi
    echo

    #directory configureren en aanmaken
    _klantdir="/home/VM2/klanten/$_klantnaam-$_klantnummer"/"$_type"
    cd /home/VM2/klanten
    mkdir "$_klantnaam-$_klantnummer"
    cd "$_klantnaam-$_klantnummer"
    mkdir "$_type"
    cd "$_type"
    touch /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/config.txt

    #start met kopieren bestanden
    copy_file
    echo
    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####    $_type omgeving wordt aangemaakt      #####"
    echo "####################################################"
    echo
    vagrant_file
    (cd $_klantdir && vagrant up)
    echo
    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####   $_type omgeving wordt geconfigureerd    #####"
    echo "####################################################"
    echo
    (cd $_klantdir && ansible-playbook /home/VM2/playbooks/playbook.yml)
}

echo
echo "######################################"
echo "#####    Bastian's SSP script    #####"
echo "#####    S1139625                #####"
echo "######################################"
echo

# Startmenu
echo "Welkom bij mijn Self-Service-Portal"
echo "1] Nieuwe omgeving"
echo "2] Omgeving aanpassen/aanvullen"
echo "3] Omgeving verwijderen."
read -p "Kies welke service u nodig heeft [default 1]: " _keuze
    if [[ $_keuze -eq "" ]]; then
        _keuze="1"
    fi
echo

if [ $_keuze == "1" ]; then
    vagrant_nieuw
elif [ $_keuze == "2" ]; then
    vagrant_edit
elif [ $_keuze == "3" ]; then
    vagrant_destroy
else
    exit 0
fi

#afsluiting uitrol
echo
echo "#######################################"
echo "####  einde Bastian's SSP script  #####"
echo "#######################################"
echo