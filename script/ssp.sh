#! /bin/sh

#vraag klantnaam
read -p "Klantnaam: " _klantnaam
echo "dit is uw klantnnaam: $_klantnaam "

#vraag klantnummer
source klantnummer.sh
_klantnummer=$((_klantnummer+1))
echo "_klantnummer=$_klannntnummer" > klantnummer.sh

#maak mappen structuur aan
cd /home/VM2/klanten
mkdir "$_klantnaam"
cd "$_klantnaam"
mkdir "ontwikkel"
mkdir "test"
mkdir "acceptatie"
mkdir "productie"

#vraag om type omgeving
read -p "Wilt u een ontwikkel, test, acceptatie of productie omgeving?" _vraag
cd "$_vraag"

#update vagrant en voer uit
cp /home/VM2/omgevingen/Vagrantfile /home/VM2/klanten/"$_klantnaam-$_klantnummer"/"$_vraag"/Vagrantfile
sed -i "s/klantnaam/$_klantnaam-$_klantnummer-$_vraag/g" Vagrantfile
sed -i "s/ipaddress/$_klantnummer/g" Vagrantfile
vagrant up

#aanmaken inventory file
cp /