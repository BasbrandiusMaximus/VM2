#!/bin/bash

#klantgegevens doorsturen
nieuwe_omgeving() {

    #Vraag $_klantnaam en $_klantnummer
    read -p "Klantnaam: " _klantnaam
    source /home/VM2/klanten/klantnummer.sh
    _klantnummer=$((_klantnummer+1))
    echo "_klantnummer=$_klantnummer" > /home/VM2/klanten/klantnummer.sh

    #vraag om type en maak mappen structuur aan
    read -p "Omgeving type [ontwikkel/test/acceptatie/productie]: " _type
    echo

    #Webservers configureren
    read -p "Wilt u webservers [true/false] ?: " WEB
    if [ $WEB == "true" ]; then
        read -p "Hoeveel webservers?: " WEB_AANTAL
        read -p "Hoeveel geheugen wilt u?: " WEB_MEMORY
    else
        WEB_AANTAL=0
        WEB_MEMORY=0
    fi
    echo

    #loadbalancers configureren (ontwikkel en test krijgen geen loadbalancers)
    if [ "$_type" == "acceptatie" ] || [ "$_type" == "productie" ]; then
        read -p "Wilt u loadbalancers [true/false] ?: " LB
        if [ $LB == "true" ]; then
            read -p "Hoeveel loadbalancers?: " LB_AANTAL
            read -p "Hoeveel geheugen wilt u?: " LB_MEMORY
            read -p "Op welke poort draait de loadbalancer?: " LB_PORT
            read -p "Op welke poort draait de stats van de loadbalancer?: " LB_STATS_PORT
        else
            LB_AANTAL=0
            LB_MEMORY=0
            LB_PORT=80
            LB_STATS_PORT=8080
        fi
    fi
    echo

    #databases configureren
    read -p "Wilt u databaseservers [true/false] ?: " DB
    if [ $DB == "true" ]; then
        read -p "Hoeveel databaseservers?: " DB_AANTAL
        read -p "Hoeveel geheugen wilt u?: " DB_MEMORY
    else
        DB_AANTAL=0
        DB_MEMORY=0
    fi
    echo

    #netwerk configuratie
    DESTINATION="/home/VM2/klanten/$_klantnaam-$_klantnummer"/"$_type"
    cd /home/VM2/klanten
    mkdir "$_klantnaam-$_klantnummer"
    cd "$_klantnaam-$_klantnummer"
    mkdir "$_type"
    cd "$_type"
    cp /home/VM2/template-omgeving/config.txt /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"

}

#map aanmaken en omgeving kopieren
copy_files() {
    cp /home/VM2/template-omgeving/Vagrantfile /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
    sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" Vagrantfile
    sed -i "s/ipaddress/$_klantnummer/g" Vagrantfile
    cp /home/VM2/template-omgeving/ansible.cfg /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/ansible.cfg

    inventoryfile

    #sla properties op in settings.txt
    echo "ENVIRONMENT=$_type" >>$DESTINATION/config.txt
    # echo "=$" >>$DESTINATION/config.txt
    echo "WEB=$WEB" >>$DESTINATION/config.txt
    echo "WEB_AANTAL=$WEB_AANTAL" >>$DESTINATION/config.txt
    echo "WEB_MEMORY=$WEB_MEMORY" >>$DESTINATION/config.txt
    echo "LB=$LB" >>$DESTINATION/config.txt
    echo "LB_AANTAL=$LB_AANTAL" >>$DESTINATION/config.txt
    echo "LB_MEMORY=$LB_MEMORY" >>$DESTINATION/config.txt
    echo "LB_PORT=$LB_PORT" >>$DESTINATION/config.txt
    echo "LB_STATS_PORT=$LB_STATS_PORT" >>$DESTINATION/config.txt
    echo "DB=$DB" >>$DESTINATION/config.txt
    echo "DB_AANTAL=$DB_AANTAL" >>$DESTINATION/config.txt
    echo "DB_MEMORY=$DB_MEMORY" >>$DESTINATION/config.txt
}

#Vagrant file web-variabelen veranderen
webservers(){
    sed -i "s/{{ web }}/$WEB/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ web_aantal }}/$WEB_AANTAL/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ web_memory }}/$WEB_MEMORY/g" "$DESTINATION/Vagrantfile"
}

#Vagrant file lb-variabelen veranderen
loadbalancers(){
    sed -i "s/{{ lb }}/$LB/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ lb_aantal }}/$LB_AANTAL/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ lb_memory }}/$LB_MEMORY/g" "$DESTINATION/Vagrantfile"
}

#Vagrant file db-variabelen veranderen
databaseservers(){
    sed -i "s/{{ db }}/$DB/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ db_aantal }}/$DB_AANTAL/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ db_memory }}/$DB_MEMORY/g" "$DESTINATION/Vagrantfile"
}

#Inventory.ini aanmaken
inventoryfile(){
    if [ -f "$DESTINATION/inventory.ini" ]; then
        echo "Inventory file bestaat nog, de oude wordt verwijderd."
        rm $DESTINATION/inventory.ini
    fi
    
    #aanmaken inventory file
    # cp /home/VM2/template-omgeving/inventory.ini /home/VM2/klanten/$_klantnaam-$_klantnummer/$_type"/inventory.ini
    # sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" inventory.ini
    # sed -i "s/ipaddress/$_klantnummer/g" inventory.ini

    #aanmaken inventory file
    touch $DESTINATION/inventory.ini

    #Add web to Inventory
    if [ $WEB == "true" ]; then
        echo "[webservers]" >>$DESTINATION/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $WEB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.2$COUNTER" >>$DESTINATION/inventory.ini
        done
        echo "" >>$DESTINATION/inventory.ini
    fi

    #Add lb to Inventory
    if [ $LB == "true" ]; then
        echo "[loadbalancers]" >>$DESTINATION/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $LB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.3$COUNTER" >>$DESTINATION/inventory.ini
        done
        echo "" >>$DESTINATION/inventory.ini
        echo "[loadbalancers:vars]" >>$DESTINATION/inventory.ini
        echo "bind_port=$LB_PORT" >>$DESTINATION/inventory.ini
        echo "stats_port=$LB_STATS_PORT" >>$DESTINATION/inventory.ini
        echo "" >>$DESTINATION/inventory.ini
    fi

    #Add db to Inventory
    if [ $DB == "true" ]; then
        echo "[databaseservers]" >>$DESTINATION/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $DB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.4$COUNTER" >>$DESTINATION/inventory.ini
        done
        echo "" >>$DESTINATION/inventory.ini
    fi
}

#voor verwijderen omgeving
vagrant_destroy(){
    read -p "Wat is uw klantnaam?: " _bestaandeklantnaam
    read -p "Wat is uw klantnummer: " _bestaandeklantnummer
    _bestaandeklant="$_bestaandeklantnaam-_$bestaandeklantnummer"
    read -p "Welke omgeving wilt u verwijderen [ontwikkel, test, acceptatie, productie]? " _omgevingverwijderen
    (cd "/home/VM2/klanten/$_bestaandeklant"/"$_omgevingverwijderen" && vagrant destroy)
    rm -r "/home/VM2/klanten/$_bestaandeklant"
    exit 0
}

#voor aanpassingen
vagrant_edit(){
    read -p "Wat is uw klantnaam?: " _editklantnaam
    read -p "Wat is uw klantnummer: " _editklantnummer
    _editklant="$_editklantnaam-$_editklantnummer"
    read -p "Welke omgeving wilt u aanpassen [test, acceptatie, productie]? " _editomgeving

    #Set Destination naar huidige klant
    DESTINATION="/home/VM2/klanten/$_editklant/$_editomgeving"

    #kopieer information from config.txt
    source "$DESTINATION/config.txt"
    WEB_AANTAL_OLD=$WEB_AANTAL
    LB_AANTAL_OLD=$LB_AANTAL
    DB_AANTAL_OLD=$DB_AANTAL

    #Verander klant webserver
    read -p "Wilt u de webservers aanpassen? [true/false]: " _edit_web

    if [ $_edit_web == "true" ]; then
        read -p "Hoeveel webservers wilt u? [Op dit moment zijn er $WEB_AANTAL] " WEB_AANTAL
        read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $WEB_MEMORY] " WEB_MEMORY
    fi

    #Verander klant loadbalancer
    if [ "$_editomgeving" == "acceptatie" ] || [ "$_editomgeving" == "productie" ]; then
        read -p "Wilt u de loadbalancers aanpassen? [true/false]: " _edit_lb
        if [ $edit_LB == "true" ]; then
            read -p "Hoeveel loadbalancers wilt u? [Op dit moment zijn er $LB_AANTAL] " LB_AANTAL
            read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $LB_MEMORY] " LB_MEMORY
            read -p "Op welke poort wilt u de loadbalancer? [Op dit moment staat hij op $LB_PORT] " LB_PORT
            read -p "Op welke poort wilt u de loadbalancer stats? [Op dit moment staat hij op $LB_STATS_PORT] " LB_STATS_PORT
        fi
    fi

    #Change customers databaseservers
    read -p "Wilt u de databaseservers aanpassen? [true/false]: " edit_lb

    if [ $edit_db == "true" ]; then
        read -p "Hoeveel databaseservers wilt u? [Op dit moment zijn er $DB_AANTAL] " DB_AANTAL
        read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $DB_MEMORY] " DB_MEMORY
    fi

    while [ $WB_AANTAL -lt $WB_AANTAL_OLD ]; do
        (cd $DESTINATION && vagrant destroy "$editklant-$editomgeving-web$WB_AANTAL_OLD" -f)
        WB_AANTAL_OLD=$(expr $WB_AANTAL_OLD - 1)
    done

    while [ $LB_AANTAL -lt $LB_AANTAL_OLD ]; do
        (cd $DESTINATION && vagrant destroy "$editklant-$editomgeving-loadbalancer$LB_AANTAL_OLD" -f)
        LB_AANTAL_OLD=$(expr $LB_AANTAL_OLD - 1)
    done

    while [ $DB_AANTAL -lt $DB_AANTAL_OLD ]; do
        (cd $DESTINATION && vagrant destroy "$editklant-$editomgeving-database$DB_AANTAL_OLD" -f)
        DB_AANTAL_OLD=$(expr $DB_AANTAL_OLD - 1)
    done

    rm "$DESTINATION/Vagrantfile"
    rm "$DESTINATION/config.txt"
    rm "$DESTINATION/inventory.ini"
    rm "$DESTINATION/ansible.cfg"
    copy_files
    sed -i "s/{{ hostname_default }}/$editklant-$editomgeving-/g" "$DESTINATION/Vagrantfile"
    sed -i "s/ipaddress/$_editklantnummer/g" "$DESTINATION/Vagrantfile"
    webservers
    loadbalancers
    databaseservers
    (cd $DESTINATION && vagrant reload)
    (cd $DESTINATION && vagrant up)
    sleep 1m
    (cd $DESTINATION && ansible-playbook /home/VM2/playbooks/production.yml)
    exit 0
}

#Voor nieuwe klanten
vagrant_main(){
    nieuwe_omgeving
    copy_files
    #sed -i "s/{{ hostname_default }}/$
    #sed subnet
        # cp /home/VM2/template-omgeving/Vagrantfile /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
        # sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" Vagrantfile
        # sed -i "s/ipaddress/$_klantnummer/g" Vagrantfile"
    echo
    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####    $_type omgeving wordt aangemaakt      #####"
    echo "####################################################"
    echo
    webservers
    loadbalancers
    databaseservers
    (cd $DESTINATION && vagrant up)
    (cd $DESTINATION && ansible-playbook /home/VM2/playbooks/playbook.yml)
}

#----------------------------------------------------------------------------
#deprecated code
# echo "Heeft u al een account of bent u nieuw hier?"
# echo "(optie 1)nieuw  of (optie 2)bestaand"
# read -p "Optie: " _optie
# echo "$_optie"

# if [ "$_optie" -eq "1" ]
# then
#proces voor bestaande klanten start

    #provisionen op basis van type omgeving

        #SSH-keys aanmaken
        # echo "SSH-keys aanmaken"
        # echo "192.168.$_klantnummer.21  $_klantnaam-$_klantnummer-$_type-web1" | sudo tee -a /etc/hosts > /dev/null
        # ssh-keyscan $_klantnaam-$_klantnummer-$_type-web1 192.168.$_klantnummer.21 >> ~/.ssh/known_hosts
        # ssh-keyscan $_klantnaam-$_klantnummer-$_type-web2 192.168.$_klantnummer.22 >> ~/.ssh/known_hosts
        # ssh-keyscan $_klantnaam-$_klantnummer-$_type-lb1 192.168.$_klantnummer.31 >> ~/.ssh/known_hosts
        # ssh-keyscan $_klantnaam-$_klantnummer-$_type-db1 192.168.$_klantnummer.41 >> ~/.ssh/known_hosts


        #uitvoeren ansible op basis van type voor ieder aanwezige type
        # cp /home/VM2/template-omgeving/ansible.cfg /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/ansible.cfg
        #web
        # ansible-playbook /home/VM2/playbooks/web.yml
        # #lb
        # ansible-playbook /home/VM2/playbooks/lb.yml
        # #db
        # # ansible-playbook -i inventory.yml /home/VM2/playbooks/db.yml

# elif then
    #proces voor bestaande klanten start
#     echo "Bestaande-klant functie nog niet aanwezig"

#     #naam vragen
#     echo"Wat is uw naam en nummer?"
#     read -p "Naam: " _klantnaam
#     read -p "Nummer: " _klantnummer
#     echo "welkom $_klantnaam-$_klantnummer"

#     #opties vragen
#     echo"Wat wilt u doen?"
#     echo"Omgeving: (optie 1) verwijderen, (optie 2) wijzigen, (optie 3) uitbreiden"
#     read -p "Naam: " _aanvraag
#     if ["$_aanvraag" -eq "verwijderen"]
#     then
#         #bestaande omgeving verwijderen
#         echo "#######################################"
#         echo "####     omgeving verwijderen     #####"
#         echo "#######################################"
#     elif ["$_aanvraag" -eq "wijzigen"]
#     then
#         #bestaande omgeving aanpassen
#         echo "#######################################"
#         echo "####      omgeving wijzigen       #####"
#         echo "#######################################"
#     else
#         #geen beschikbare optie dus ongeldig
#         echo "ongeldige keuze"
#     fi

# # else
#     #niet nieuw of bestaande klant dus ongeldig
#     echo "ongeldige optie"
# fi

#------------------------------------------------------------------------------------------------------------------------
echo
echo "######################################"
echo "#####    Bastian's SSP script    #####"
echo "######################################"
echo

# Main Menu
echo "Welkom bij het Self-Service-Portal"
echo "1.) Nieuwe Klant"
echo "2.) Verwijder Klant"
echo "3.) Pas bestaande klant aan"
read -p "Kies welke service u nodig heeft: " KEUZE
echo

if [ $KEUZE == "1" ]; then
    vagrant_main
elif [ $KEUZE == "2" ]; then
    vagrant_destroy
elif [ $KEUZE == "3" ]; then
    vagrant_edit
else
    exit 0
fi

#afsluiting uitrol
echo
echo "#######################################"
echo "####  einde Bastian's SSP script  #####"
echo "#######################################"
echo