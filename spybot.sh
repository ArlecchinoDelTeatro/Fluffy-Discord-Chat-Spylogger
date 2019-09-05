clear

logo() {
	echo ""
	echo "  ███████╗██╗     ██╗   ██╗███████╗███████╗██╗   ██╗"
	echo "  ██╔════╝██║     ██║   ██║██╔════╝██╔════╝╚██╗ ██╔╝"
	echo "  █████╗  ██║     ██║   ██║█████╗  █████╗   ╚████╔╝ "
	echo "  ██╔══╝  ██║     ██║   ██║██╔══╝  ██╔══╝    ╚██╔╝  "
	echo "  ██║     ███████╗╚██████╔╝██║     ██║        ██║   "
	echo "  ╚═╝     ╚══════╝ ╚═════╝ ╚═╝     ╚═╝        ╚═╝   "
	echo "                         Arlecch1no@PwnSec - 2019"
	echo ""
}

logo

check_if_root() {
	if [[ "$(whoami)" == "root" ]];
	then
		echo " [Fluffy] User Root [OK]"
	else
		echo " [Fluffy] User Root [PROBLEM]"
		echo " [Fluffy] Are u root ?"
		exit
	fi
}

check_if_root

check_lines() {
	if [[ $(cat temp_logs.txt | wc -l) -gt 10 ]];
	then
		rm -r temp_logs.txt
		touch temp_logs.txt
	else
		echo ""
		echo " [Fluffy] Lines $(cat temp_logs.txt | wc -l)"
		check_cred
	fi
}




email=$(cat config.txt | grep "<fluffy_email>" | sed "s/<fluffy_email>//g" | sed -n 1p)
echo " [Fluffy] Username: [Hidden]"
password=$(cat config.txt | grep "<fluffy_password>" | sed "s/<fluffy_password>//g" | sed -n 1p)
echo " [Fluffy] Password: [Hidden]"
room=$(cat config.txt | grep "<fluffy_room_id>" | sed "s/<fluffy_room_id>//g" | sed -n 1p)
echo " [Fluffy] RoomID: "$room

check_cred() {
	if [[ $(echo "$username" | wc -c) > 1 ]];
	then
		echo " [Fluffy] Status for username [OK]"
	elif [[ $(echo "$password" | wc -c) > 1 ]];
	then
		echo " [Fluffy] Status for password [OK]"
	elif [[ $(echo "$room" | wc -c) > 1 ]];
	then
		echo "[Fluffy] Status for Room [OK]"
	else 
		echo " [Fluffy] Empty Strings ?"
		exit
	fi
}

check_cred

check_for_tools() {

	if [[ -f /usr/bin/http ]];
	then
		echo " [Fluffy] Status for httpie [OK]"
	else
		echo " [Fluffy] Status for httpie [PROBLEM]"
		exit
	fi
	if [[ -f /usr/bin/ping ]];
	then
		echo " [Fluffy] Status for ping [OK]"
	else
		echo " [Fluffy] Status for ping [PROBLEM]"
		exit
	fi
}

check_for_tools

check_internet() {
	if [[ "$(ping google.ro -c 1)" =~ "bytes from" ]];
	then
		echo " [Fluffy] Status for internet [OK]"
	else
		echo " [Fluffy] Status for internet [PROBLEMS]"
		exit
	fi
}

check_internet

login_discord() {

	# Get Cookie
	get_cookie=$(http POST https://discordapp.com/api/v6/auth/login -h | sed -n 6p)

	# Login 
	login_tester=$(http POST https://discordapp.com/api/v6/auth/login \
	'Host: discordapp.com' \
	'Connection: close' \
	'Accept-Language: en-US' \
	'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.75 Safari/537.36' \
	'Origin: https://discordapp.com' \
	'Content-Type: application/json' \
	'Accept: */*' \
	"$get_cookie" \
	'Referer: https://discordapp.com/login' \
	email=$email\
	password=$password \
	undelete=false \
	captcha_key=null \
	login_source=null)
	token=$(echo "$login_tester" | jq -r '.token')
	echo " [Fluffy] Status for Token [Hidden]"
 
	# Check the json reponse
	if [[ "$login_tester" =~ "Password does not match." ]];
	then
		echo " [Fluffy] Status [Password does not match]"
		exit
	elif [[ "$login_tester" =~ "Not a well formed email address" ]];
	then
		echo " [Fluffy] Status [Not a well formed email address]"
		exit
	elif [[ "$login_tester" =~ "You are being rate limited" ]];
	then
		delay=$(echo "$login_tester" | jq -r '.retry_after')
		echo " [Fluffy] Status [You are being rate limited] [$delay]"
		login_discord
	else
		echo " [Fluffy] Status for Login [OK]"
	fi
}

login_discord

get_message() {

	get_last_message=$(http GET https://discordapp.com/api/v6/channels/$room/messages?limit=1 \
	'Connection: keep-alive' \
	'Authorization: '$token \
	'Accept-Language: en-US' \
	'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.75 Safari/537.36' \
	'Accept: */*')
	if [[ "$get_last_message" =~ "401: Unauthorized" ]];
	then
		echo " [Fluffy] Status [Invalid Token]"
		exit
	elif [[ "$get_last_message" =~ "Unknown Channel" ]];
	then
		echo " [Fluffy] Status [Unknown Channel]"
		exit
	else
		echo " [Fluffy] Status for Token [OK]"

	fi
}

get_message

get_message_json () {

	get_msg=$(echo "$get_last_message" | jq -r '.[].content')
	echo " [Fluffy] Last Message: "$get_msg
}

get_message_json

no_repeat() {
	if [[ "$(cat temp_logs.txt | tail -1)" == "$get_msg" ]];
	then 
		echo " [Fluffy] Already exist"
	else
		echo " [Fluffy] Sending message to logs..."
		echo $get_msg >> temp_logs.txt

		content=$(echo "$get_last_message" | jq -r '.[].content')
		username=$(echo "$get_last_message" | jq -r '.[].author.username')
		discriminator=$(echo "$get_last_message" | jq -r '.[].author.discriminator')
		timestamp=$(echo "$get_last_message" | jq -r '.[].timestamp')
		echo " TIMESTAMP: $timestamp USERNAME: $username DISCRIMINATOR: $discriminator CONTENT: $content" >> permanent_logs.txt
	fi
}


while true;do
	clear
	check_lines
	logo
	no_repeat
	get_message
	get_message_json
done
