#!/bin/bash

if [ $# -eq 1 ]
	then
		regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
		url=$1
		if [[ ! $url =~ $regex ]]
			then
				echo "$url is not a valid URL">&2
				echo "Usage : $0 URL">&2
				exit 1
		fi
	else
		url=https://statsroyale.com/clan/89Q998Y
fi

usuarios=$(curl -s $url | grep ui__blueLink |cut -d">" -f 2 | cut -d"<" -f 1 | tr -d ' ')
donaciones=$(curl -s $url | grep clan__donation |cut -d">" -f2 |cut -d"<" -f1 |tail -n +2)
copas=$(curl -s $url | grep clan__cup |cut -d">" -f2 |cut -d"<" -f1)
coronas=$(curl -s $url | grep clan__crown |cut -d">" -f2 |cut -d"<" -f1)

fichero_temporal=$(mktemp)
fichero_salida=$(echo "notas"$(date +%d-%m-%Y)".txt")

paste <(echo "$usuarios") <(echo "$copas") <(echo "$donaciones") <(echo "$coronas") > $fichero_temporal

let aprobados=0
let suspensos=0
let expulsiones=0

while read lines
do

	user=$(echo $lines | cut -d ' ' -f1)
	ucop=$(echo $lines | cut -d ' ' -f2)  
	udon=$(echo $lines | cut -d ' ' -f3)  
	ucor=$(echo $lines | cut -d ' ' -f4)  
	
	
	if [ $ucop -ge 6000 ]
		then
		let ucop=6000
	fi
	
	if [ $udon -ge 840 ]
		then
		let udon=840
	fi
	
	if [ $ucor -ge 30 ]
		then
		let ucor=30
	fi
	
	#La fórmula de la nota semanal a seguir será:
	#Nota semanal = (Copas*0,2) /600 +(Donaciones*0,4)/84 + (Coronas*0,4)/3
	nota=$(echo print "round($ucop*0.2/600 + $udon*0.4/84 + $ucor*0.4/3,3)" | python)
	
	let aux=$(echo $nota | cut -d "." -f1)
	
	if [ $aux -ge 5 ]
		then
		observacion="BuenTrabajo"
		let aprobados=$aprobados+1
		elif [ $aux -lt 5 ]
		then
		observacion="Suspenso"
		let suspensos=$suspensos+1
	fi
	
	if [ $aux -lt 2 ]
		then
		let expulsiones=$expulsiones+1
		expulsados=$expulsados" "$user
		observacion="EXPULSION"
	fi
	
	echo $user $ucop $udon $ucor $nota $observacion 
done < $fichero_temporal > $fichero_salida


cat $fichero_salida | sort -k5 -r > $fichero_temporal

echo "Usuario Copas Donaciones Coronas Nota Observacion" > $fichero_salida

cat $fichero_temporal >> $fichero_salida

echo -e >> $fichero_salida
echo -e >> $fichero_salida
echo "Aprobados "$aprobados >> $fichero_salida
echo "Suspensos "$suspensos >> $fichero_salida
echo "Expulsiones "$expulsiones >> $fichero_salida