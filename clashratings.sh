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

users=$(curl -s $url | grep ui__blueLink |cut -d">" -f 2 | cut -d"<" -f 1 | tr -d ' ')
donations=$(curl -s $url | grep clan__donation |cut -d">" -f2 |cut -d"<" -f1 |tail -n +2)
cups=$(curl -s $url | grep clan__cup |cut -d">" -f2 |cut -d"<" -f1)
crowns=$(curl -s $url | grep clan__crown |cut -d">" -f2 |cut -d"<" -f1)

temp_file=$(mktemp)
out_file=ratings.txt

paste <(echo "$users") <(echo "$cups") <(echo "$donations") <(echo "$crowns") > $temp_file

let approved=0
let suspense=0
let expulsions=0

echo "User Cups Donations Crowns Rating Comment" > $out_file

while read lines
do

	user=$(echo $lines | cut -d ' ' -f1)
	ucup=$(echo $lines | cut -d ' ' -f2)  
	udon=$(echo $lines | cut -d ' ' -f3)  
	ucro=$(echo $lines | cut -d ' ' -f4)  
	
	if [ $ucup -ge 6000 ]
		then
		let ucup=6000
	fi
	
	if [ $udon -ge 840 ]
		then
		let udon=840
	fi
	
	if [ $ucro -ge 30 ]
		then
		let ucro=30
	fi
	
	#La fórmula de la nota semanal a seguir será:
	#Nota semanal = (Copas*0,2) /600 +(Donaciones*0,4)/84 + (Coronas*0,4)/3
	rating=$(echo print "round($ucup*0.2/600 + $udon*0.4/84 + $ucro*0.4/3,3)" | python)
	
	let aux=$(echo $rating | cut -d "." -f1)
	
	if [ $aux -ge 5 ]
		then
		comment="GoodJob"
		let approved=$approved+1
		elif [ $aux -lt 5 ]
		then
		comment="Suspense"
		let suspense=$suspense+1
	fi
	
	if [ $aux -lt 2 ]
		then
		let expulsions=$expulsions+1
		expelled=$expelled" "$user
		comment="EXPELLED"
	fi
	
	echo $user $ucup $udon $ucro $rating $comment 
done < $temp_file >> $out_file

echo -e >> $out_file
echo -e >> $out_file
echo "Approved "$approved >> $out_file
echo "Suspended "$suspense >> $out_file
echo "Expulsions "$expulsions :$expelled >> $out_file
