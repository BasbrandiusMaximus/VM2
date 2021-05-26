#!/bin/bash

#klantgegevens doorsturen
nieuwe_omgeving(){

    #Vraag $_klantnaam en $_klantnummer
    read -p "Klantnaam: " _klantnaam
    source /home/VM2/klanten/klantnummer.sh
    _klantnummer=$((_klantnummer+1))
    echo "_klantnummer=$_klantnummer" > /home/VM2/klanten/klantnummer.sh

    #vraag om type en maak mappen structuur aan
    read -p "Omgeving type [ontwikkel/test/acceptatie/productie] [default acceptatie]: " _type
        if [ $_type -eq ""]; then
            _type="acceptatie"
        fi
    echo

    #Webservers vraag
    read -p "Wilt u webservers [true/false] [DEFAULT true]?: " WEB
        if [ $WEB -eq ""]; then
            WEB="true"
        fi
    if [ "$WEB" == "true" ]; then
        read -p "Hoeveel webservers [DEFAULT 2]?: " WEB_AANTAL
            if [ $WEB_AANTAL -eq ""]; then
                WEB_AANTAL="2"
            fi
        read -p "Hoeveel geheugen wilt u [DEFAULT 1024]?: " WEB_MEMORY
            if [ $WEB_MEMORY -eq ""]; then
                WEB_MEMORY="1024"
            fi
    else
        WEB_AANTAL=0
        WEB_MEMORY=0
    fi
    echo

    #loadbalancers vraag (ontwikkel en test krijgen geen loadbalancers)
    if [ "$_type" == "acceptatie" ] || [ "$_type" == "productie" ]; then
        read -p "Wilt u loadbalancers [true/false] [DEFAULT true]?: " LB
            if [ $LB -eq ""]; then
                LB="true"
            fi
        if [ "$LB" == "true" ]; then
            read -p "Hoeveel loadbalancers [DEFAULT 1]?: " LB_AANTAL
                if [ $LB_AANTAL -eq ""]; then
                    LB_AANTAL="1"
                fi
            read -p "Hoeveel geheugen wilt u [DEFAULT 1024]?: " LB_MEMORY
                if [ $LB_MEMORY -eq ""]; then
                    LB_MEMORY="1024"
                fi
            read -p "Op welke poort draait de loadbalancer [DEFAULT 80]?: " LB_PORT
                if [ $LB_PORT -eq ""]; then
                    LB_PORT="80"
                fi
            read -p "Op welke poort draait de stats van de loadbalancer [DEFAULT 8080]?: " LB_STATS_PORT
                if [ $LB_STAT_PORT -eq ""]; then
                    LB_STATS_PORT="8080"
                fi
        else
            LB_AANTAL=0
            LB_MEMORY=0
            LB_PORT=80
            LB_STATS_PORT=8080
        fi
    fi
    echo

    #databases vraag
    read -p "Wilt u databaseservers [true/false] [DEFAULT true]?: " DB
        if [ $DB -eq ""]; then
            DB="true"
        fi
    if [ $DB == "true" ]; then
        read -p "Hoeveel databaseservers [DEFAULT 1]?: " DB_AANTAL
            if [ $DB_AANTAL -eq ""]; then
                DB_AANTAL="1"
            fi
        read -p "Hoeveel geheugen wilt u [DEFAULT 2048]?: " DB_MEMORY
            if [ $DB_MEMORY -eq ""]; then
                DB_MEMORY="2048"
            fi
    else
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
    cp /home/VM2/template-omgeving/config.txt /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"
}

#map aanmaken en omgeving kopieren
copy_file(){
    cp /home/VM2/template-omgeving/Vagrantfile /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
    sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" Vagrantfile
    sed -i "s/ipaddress/$_klantnummer/g" Vagrantfile
    cp /home/VM2/template-omgeving/ansible.cfg /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/ansible.cfg

    inventory_file

    #sla properties op in settings.txt
    echo "ENVIRONMENT=$_type" >>$_klantdir/config.txt
    # echo "=$" >>$_klantdir/config.txt
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

#Inventory.ini aanmaken
inventory_file(){
    if [ -f "$_klantdir/inventory.ini" ]; then
        echo "Inventory file bestaat nog, de oude wordt verwijderd."
        rm $_klantdir/inventory.ini
    fi
    
    #aanmaken inventory file
    # cp /home/VM2/template-omgeving/inventory.ini /home/VM2/klanten/$_klantnaam-$_klantnummer/$_type"/inventory.ini
    # sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" inventory.ini
    # sed -i "s/ipaddress/$_klantnummer/g" inventory.ini

    #aanmaken inventory file
    touch $_klantdir/inventory.ini

    #Add web to Inventory
    if [ $WEB == "true" ]; then
        echo "[webservers]" >>$_klantdir/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $WEB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.2$COUNTER" >>$_klantdir/inventory.ini
        done
        echo "" >>$_klantdir/inventory.ini
    fi

    #Add lb to Inventory
    if [ $LB == "true" ]; then
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

    #Add db to Inventory
    if [ $DB == "true" ]; then
        echo "[databaseservers]" >>$_klantdir/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $DB_AANTAL ]; do
            COUNTER=$(expr $COUNTER + 1)
            echo "192.168.$_klantnummer.4$COUNTER" >>$_klantdir/inventory.ini
        done
        echo "" >>$_klantdir/inventory.ini
    fi
}

#Vagrant file web/lb/db-variabelen veranderen
vagrant_file(){
    sed -i "s/{{ web }}/$WEB/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ web_aantal }}/$WEB_AANTAL/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ web_memory }}/$WEB_MEMORY/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ lb }}/$LB/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ lb_aantal }}/$LB_AANTAL/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ lb_memory }}/$LB_MEMORY/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ db }}/$DB/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ db_aantal }}/$DB_AANTAL/g" "$_klantdir/Vagrantfile"
    sed -i "s/{{ db_memory }}/$DB_MEMORY/g" "$_klantdir/Vagrantfile"
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
    read -p "Welke omgeving wilt u aanpassen [test, acceptatie, productie]? " _type

    #Set _klantdir naar huidige klant
    _klantdir="/home/VM2/klanten/$_editklant/$_type"

    #kopieer informatie from config.txt
    source "$_klantdir/config.txt"
    WEB_AANTAL_OLD=$WEB_AANTAL
    LB_AANTAL_OLD=$LB_AANTAL
    DB_AANTAL_OLD=$DB_AANTAL

    #Verander klant-webserver
    read -p "Wilt u de webservers aanpassen? [true/false]: " _edit_web

    if [ $_edit_web == "true" ]; then
        read -p "Hoeveel webservers wilt u? [Op dit moment zijn er $WEB_AANTAL] " WEB_AANTAL
        read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $WEB_MEMORY] " WEB_MEMORY
    fi

    #Verander klant-loadbalancer
    if [ "$_type" == "acceptatie" ] || [ "$_type" == "productie" ]; then
        read -p "Wilt u de loadbalancers aanpassen? [true/false]: " _edit_lb
        if [ $edit_LB == "true" ]; then
            read -p "Hoeveel loadbalancers wilt u? [Op dit moment zijn er $LB_AANTAL] " LB_AANTAL
            read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $LB_MEMORY] " LB_MEMORY
            read -p "Op welke poort wilt u de loadbalancer? [Op dit moment staat hij op $LB_PORT] " LB_PORT
            read -p "Op welke poort wilt u de loadbalancer stats? [Op dit moment staat hij op $LB_STATS_PORT] " LB_STATS_PORT
        fi
    fi

    #verander klant-database
    read -p "Wilt u de databaseservers aanpassen? [true/false]: " edit_lb

    if [ $edit_db == "true" ]; then
        read -p "Hoeveel databaseservers wilt u? [Op dit moment zijn er $DB_AANTAL] " DB_AANTAL
        read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $DB_MEMORY] " DB_MEMORY
    fi
    while [ $WB_AANTAL -lt $WB_AANTAL_OLD ]; do
        (cd $_klantdir && vagrant destroy "$_editklant-$_type-web$WB_AANTAL_OLD" -f)
        WB_AANTAL_OLD=$(expr $WB_AANTAL_OLD - 1)
    done
    while [ $LB_AANTAL -lt $LB_AANTAL_OLD ]; do
        (cd $_klantdir && vagrant destroy "$_editklant-$_type-loadbalancer$LB_AANTAL_OLD" -f)
        LB_AANTAL_OLD=$(expr $LB_AANTAL_OLD - 1)
    done
    while [ $DB_AANTAL -lt $DB_AANTAL_OLD ]; do
        (cd $_klantdir && vagrant destroy "$_editklant-$_type-database$DB_AANTAL_OLD" -f)
        DB_AANTAL_OLD=$(expr $DB_AANTAL_OLD - 1)
    done

    rm "$_klantdir/Vagrantfile"
    rm "$_klantdir/config.txt"
    rm "$_klantdir/inventory.ini"
    rm "$_klantdir/ansible.cfg"
    copy_file
    sed -i "s/{{ hostname_default }}/$_editklant-$_type-/g" "$_klantdir/Vagrantfile"
    sed -i "s/ipaddress/$_editklantnummer/g" "$_klantdir/Vagrantfile"
    echo
    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####    $_type omgeving wordt aangepast      #####"
    echo "####################################################"
    echo
    vagrant_file
    (cd $_klantdir && vagrant reload)
    (cd $_klantdir && vagrant up)
    sleep 1m
    (cd $_klantdir && ansible-playbook /home/VM2/playbooks/playbook.yml)
    exit 0
}

#Voor nieuwe klanten
vagrant_nieuw(){
    nieuwe_omgeving
    copy_file
    echo
    echo "####################################################"
    echo "#####             Even geduld a.u.b.           #####"
    echo "#####    $_type omgeving wordt aangemaakt      #####"
    echo "####################################################"
    echo
    vagrant_file
    (cd $_klantdir && vagrant up)
    (cd $_klantdir && ansible-playbook /home/VM2/playbooks/playbook.yml)
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
echo "#####    S1139625                #####"
echo "######################################"
echo

# Startmenu
echo "Welkom bij mijn Self-Service-Portal"
echo "1.) Nieuwe Klant"
echo "2.) Pas bestaande klant aan"
echo "3.) Verwijder Klant"
read -p "Kies welke service u nodig heeft [default 1]: " _keuze
    if [ $_keuze == "" ]; then
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