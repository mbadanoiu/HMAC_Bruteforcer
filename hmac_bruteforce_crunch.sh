#!/bin/bash

### Modify Depending on Computing Power
thread_limit=50

### Env checks
if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
	echo -e "\n\tUsage: $0 <Length> <HMAC> <md4/md5/sha1/sha256/sha512> <Message_File>\n"
	exit
fi

mode_arr=("md4" "md5" "sha1" "sha256" "sha512") ##Probable is not the full list
if [[ ! "${mode_arr[@]}" =~ "$3" ]]; then
	echo -e "\n\tInvalid hash type selected!\n\tOptions: md4, md5, sha1, sha256, sha512\n"
	exit
fi

if [[ ! -s "$4" ]]; then
	echo -e "\n\tFile $4 doesn't exist or is empty\n"
	exit
fi

if [[ ! "$(which crunch)" ]]; then
	echo -e "\n\tCrunch is not install, or not in $PATH\n"
	exit
fi

if [[ ! "$(which openssl)" ]]; then
	echo -e "\n\tOpenssl is not install, or not in $PATH\n"
	exit
fi
### Env checks

length="$1"
hmac="$2"
mode="$3"
file="$4"

PID=$$

threads=0

function hmac {
	pass="$1"
#	echo "$threads: $pass"
	res=$(openssl dgst -"$mode" -hmac "$pass" "$file" | cut -d" " -f2)
#	echo "$res"
	if [[ ${res,,} == ${hmac,,} ]]; then
		echo "################RESULT################"
		echo "Key: '$pass'"
		echo "################RESULT################"
		kill -TERM -- -"$PID" &> /dev/null
	fi
}

function multithread {
	threads=$(("$threads"+1))
	pass="$1"
	hmac "$pass" &
	if (( "$threads" >= "$thread_limit" )); then
		wait
		threads=0
	fi
}

while read i; do
	multithread "$i"
done <<< "$(crunch $length $length -f /usr/share/crunch/charset.lst mixalpha-numeric-all-space; echo Done generating wordlist! Running hmac-$mode 1>&2)"

wait
echo "No result found"
