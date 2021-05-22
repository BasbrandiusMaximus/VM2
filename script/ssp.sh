#! /bin/sh

#klantnaam
read -p "wat is uw klantnaam: " _klantnaam
echo "dit is uw klantnnaam: $_klantnaam "

#nummer
source klantnummer.sh
_klantnummer=$((_klantnummer+1))
echo "_klantnummer=$_klannntnummer" > klantnummer.sh

#mappen structuur
cd /home/student/vm2/klanten
mkdir "$_klantnaam"
cd "$_klantnaam"
mkdir "productie"
mkdir "acceptatie"
mkdir "test"


read -p "Wilt u een productie, test of acceptatie omgeving" _vraag
cd "$_vraag"
cp /home/student/vm2/omgevingen/Vagrantfile /home/student/vm2/klanten/"$_klantnaam"/"$_vraag"/Vagrantfile
sed -i "s/klantnaam/$_klantnaam/g" Vagrantfile
vagrant up
