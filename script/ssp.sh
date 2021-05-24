echo "######################################"
echo "#####    Bastian's SSP script    #####"
echo "######################################"
echo
echo "Heeft u al een account of bent u nieuw hier?"
echo "(optie 1)nieuw  of (optie 2)bestaand"
read -p "Optie: " _optie
echo "$_optie"

if [ "$_optie" -eq "1" ]
then
#proces voor bestaande klanten start

    #vraag klantnaam
    read -p "Klantnaam: " _klantnaam
    echo "dit is uw klantnaam: $_klantnaam "

    #vraag klantnummer
    source /home/VM2/script/klantnummer.sh
    _klantnummer=$((_klantnummer+1))
    echo "_klantnummer=$_klantnummer" > klantnummer.sh

    #maak mappen structuur aan
    cd /home/VM2/klanten
    mkdir "$_klantnaam-$_klantnummer"
    cd "$_klantnaam-$_klantnummer"
    mkdir "ontwikkel"
    mkdir "test"
    mkdir "acceptatie"
    mkdir "productie"

    #vraag om type omgeving
    read -p "Wilt u een ontwikkel, test, acceptatie of productie omgeving? " _type
    cd "$_type"

    #provisionen op basis van type omgeving
        echo "####################################################"
        echo "#####             Even geduld a.u.b.           #####"
        echo "#####    $_type omgeving wordt aangemaakt      #####"
        echo "####################################################"

        #update vagrant en voer uit
        cp /home/VM2/template-omgeving/Vagrantfile /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/Vagrantfile
        sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" Vagrantfile
        sed -i "s/ipaddress/$_klantnummer/g" Vagrantfile
        vagrant up
        #aanmaken inventory file
        cp /home/VM2/template-omgeving/inventory.yml /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/inventory.yml
        sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_type/g" inventory.yml
        sed -i "s/ipaddress/$_klantnummer/g" inventory.yml
        #SSH-keys aanmaken
        echo
        # echo "SSH-keys aanmaken"
        # echo "192.168.$_klantnummer.21  $_klantnaam-$_klantnummer-$_type-web1" | sudo tee -a /etc/hosts > /dev/null
        ssh-keyscan $_klantnaam-$_klantnummer-$_type-web1 192.168.$_klantnummer.21 >> ~/.ssh/known_hosts
        echo
        ssh-keyscan $_klantnaam-$_klantnummer-$_type-web2 192.168.$_klantnummer.22 >> ~/.ssh/known_hosts
        echo
        ssh-keyscan $_klantnaam-$_klantnummer-$_type-lb1 192.168.$_klantnummer.31 >> ~/.ssh/known_hosts
        echo
        ssh-keyscan $_klantnaam-$_klantnummer-$_type-db1 192.168.$_klantnummer.41 >> ~/.ssh/known_hosts


        #uitvoeren ansible op basis van type voor ieder aanwezige type
        cp /home/VM2/template-omgeving/ansible.cfg /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_type"/ansible.cfg
        #web
        ansible-playbook /home/VM2/playbooks/web.yml
        #lb
        ansible-playbook /home/VM2/playbooks/lb.yml
        #db
        # ansible-playbook -i inventory.yml /home/VM2/playbooks/db.yml
    

elif [ "$_optie" -eq "2" ]
then
    #proces voor bestaande klanten start
    echo "Bestaande-klant functie nog niet aanwezig"

    #naam vragen
    echo"Wat is uw naam en nummer?"
    read -p "Naam: " _klantnaam
    read -p "Nummer: " _klantnummer
    echo "welkom $_klantnaam-$_klantnummer"

    #opties vragen
    echo"Wat wilt u doen?"
    echo"Omgeving: (optie 1) verwijderen, (optie 2) wijzigen, (optie 3) uitbreiden"
    read -p "Naam: " _aanvraag
    if ["$_aanvraag" -eq "verwijderen"]
    then
        #bestaande omgeving verwijderen
        echo "#######################################"
        echo "####     omgeving verwijderen     #####"
        echo "#######################################"
    elif ["$_aanvraag" -eq "wijzigen"]
    then
        #bestaande omgeving aanpassen
        echo "#######################################"
        echo "####      omgeving wijzigen       #####"
        echo "#######################################"
    else
        #geen beschikbare optie dus ongeldig
        echo "ongeldige keuze"
    fi

else
    #niet nieuw of bestaande klant dus ongeldig
    echo "ongeldige optie"
fi


#afsluiting uitrol
echo
echo "#######################################"
echo "####  einde Bastian's SSP script  #####"
echo "#######################################"