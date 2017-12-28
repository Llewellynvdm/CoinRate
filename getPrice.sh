#!/bin/bash
#/--------------------------------------------------------------------------------------------------------|  www.vdm.io  |------/
#    __      __       _     _____                 _                                  _     __  __      _   _               _
#    \ \    / /      | |   |  __ \               | |                                | |   |  \/  |    | | | |             | |
#     \ \  / /_ _ ___| |_  | |  | | _____   _____| | ___  _ __  _ __ ___   ___ _ __ | |_  | \  / | ___| |_| |__   ___   __| |
#      \ \/ / _` / __| __| | |  | |/ _ \ \ / / _ \ |/ _ \| '_ \| '_ ` _ \ / _ \ '_ \| __| | |\/| |/ _ \ __| '_ \ / _ \ / _` |
#       \  / (_| \__ \ |_  | |__| |  __/\ V /  __/ | (_) | |_) | | | | | |  __/ | | | |_  | |  | |  __/ |_| | | | (_) | (_| |
#        \/ \__,_|___/\__| |_____/ \___| \_/ \___|_|\___/| .__/|_| |_| |_|\___|_| |_|\__| |_|  |_|\___|\__|_| |_|\___/ \__,_|
#                                                        | |
#                                                        |_|
#/-------------------------------------------------------------------------------------------------------------------------------/
#
#	@author			Llewellyn van der Merwe <https://github.com/Llewellynvdm>
#	@copyright		Copyright (C) 2016. All Rights Reserved
#	@license		GNU/GPL Version 2 or later - http://www.gnu.org/licenses/gpl-2.0.html
#
#/-----------------------------------------------------------------------------------------------------------------------------/

# get script path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VDMHOME=~/

# load notify
. "$DIR/notify.sh"

# load sms
. "$DIR/sms.sh"

# main function
function main () {
	echo "................................................................................................"
	echo "...==========================================================================================..."
	echoTweak "Getting the current price of $Currency in $Target"
	echo "...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..."
	# get the price value
	value=$(get_Price "${API}${Currency}/${Target}")
	# set send key
	setSendKey
	# set target values and perform action if only TargetValue given
	if (( "$TargetBelowValue" == 0 && "$TargetAboveValue" == 0));
	then
		getTarget "$TargetValue" "$value" 'setAction'
	fi
	# set target values and perform action if TargetBelowValue given
	if (( "$TargetAboveValue" != 0 ));
	then
		getTarget "$TargetAboveValue" "$value" 'setActionAbove'
	fi
	# set target values and perform action if TargetBelowValue given
	if (( "$TargetBelowValue" != 0 ));
	then
		getTarget "$TargetBelowValue" "$value" 'setActionBelow'
	fi
	echo "...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..."
	# send Messages
	sendMessages
	echo "...==========================================================================================..."
	echo "................................................................................................"
}

function getTarget() {
	# set Args
	local target_value="$1"
	local current_value="$2"
	local funcName="$3"
	# do the work
	if [[ "$target_value" == *,* ]] ; then
		IFS=',' read -ra ADDR <<< "$target_value"
		for tValue in "${ADDR[@]}"; do
			# process "$tValue"
			$funcName "$current_value" "$tValue"
		done
	else
		$funcName "$current_value" "$target_value"
	fi
}

function setAction () {
	# set Args
	local current_value="$1"
	local target_value="$2"
	# should we do above
	setActionAbove "$current_value" "$target_value"
	# should we do below
	setActionBelow "$current_value" "$target_value"
}

function setActionAbove () {
	# set Args
	local current_value="$1"
	local target_value="$2"
	# should we do above
	if (( "$AboveValue" == 1 ));
	then
		# get action
		local action=$(echo "$current_value > $target_value" | bc -l)
		preform "$current_value" "$target_value" "$action" "above"
	fi
}

function setActionBelow () {
	# set Args
	local current_value="$1"
	local target_value="$2"
	# should we do below
	if (( "$BelowValue" == 1 ));
	then
		# get action
		local action=$(echo "$current_value < $target_value" | bc -l)
		preform "$current_value" "$target_value" "$action" "below"
	fi	
}

function preform () {
	# set Args
	local current_value="$1"
	local target_value="$2"
	local action="$3"
	local target_type="$4"
	# check if there is need of action
	if (( "$action" == 1 ));
	then
		# set message since we are above target value
		setMessage "$target_type" "$current_value" "$target_value"
	else
		echoTweak "Nothing to report at this time! ($target_value) "
	fi
}

# set message
function setMessage () {
	# set Args
	local target_type="$1"
	local current_value="$2"
	local target_value="$3"
	# build message
	message="${Currency} is ${target_type} ${target_value} ${Target} at ${current_value} ${Target}"
	# first send to comand line
	echoTweak "${message} - ${Datetimenow} "
	# is it send time
	sendTime "$target_type" "$target_value"
	# set to messages
	setMessages "$message" "$target_type" "$target_value"
}

# set messages
function setMessages () {
	# set Args
	local message="$1"
	local type="$2"
	local value="$3"
	# check if we should set messages
	if (( "$send" == 1 )); then
			# we can set message
			if [ "$type" == "below" ]; then
				# set below message
				belowMessages["$value"]="$message"
			elif [ "$type" == "above" ]; then
				# set above message
				aboveMessages["$value"]="$message"
			fi
	fi
}

# send messages
function sendMessages () {
	# filter messages to only send the lowest-below and the highest-above
	filterMessages
	# check if we have messages
	if [ ${#Messages[@]} -gt 0 ]; then
		# set to string
		IFS=$'\n'
		local messages="${Messages[*]}"
		# send Telegram messages if allowed
		sendTelegram "${messages}"
		# show linux messages if allowed
		showLinuxMessage "${messages}"
		# send SMS messages if allowed
		sendSMSMessage "${messages}"
	fi
}

# filter messages to only send the lowest-below and the highest-above
function filterMessages () {
	# check if lower value is found
	if [ ${#belowMessages[@]} -gt 0 ]; then
		# get lowest
		activeKey=$( getActiveBelowMessages )
		# set to messages
		Messages+=("${belowMessages[$activeKey]}")
	fi
	# check if higher value is found
	if [ ${#aboveMessages[@]} -gt 0 ]; then
		# get highest
		activeKey=$( getActiveAboveMessage )
		# set to messages
		Messages+=("${aboveMessages[$activeKey]}")
	fi
}

# array sort
function getActiveBelowMessages () {
	# start the search
	local keys+=$(for i in "${!belowMessages[@]}"
	do
		echo $i
	done | sort -n)
	# return keys
	echo $( echo "${keys}" | head -n1 )
}

# array sort
function getActiveAboveMessage () {
	# start the search
	local keys+=$(for i in "${!aboveMessages[@]}"
	do
		echo $i
	done | sort -rn)
	# return keys
	echo $( echo "${keys}" | head -n1 )
}

# show message in linux (will not work on server)
function showLinuxMessage () {
	# check if linux messages can be shown
	if (( "$LinuxNotice" == 1 )); then
		zenity --text="$1" --info 2> /dev/null
		echoTweak "Linux Message was shown"
	fi	
}

# send sms messages
function sendSMSMessage () {
	# check if we should send SMS
	if (( "$SMS" == 1 )); then
		smsMe "${messages}"
		echoTweak "SMS Message was send"
	fi
}

# send Telegram
function sendTelegram () {
	# check if we should send Telegram
	if (( "$Telegram" ==  1 )); then
		notifyMe "$1"
		echoTweak "Telegram Message was send"
	fi
}

# check if it is time to show/send the messages
function sendTime () {
	# set Args
	local target_type="$1"
	local target_value="$2"
	# build key send time
	keySendTime=$(echo -n "${target_type}${target_value}${sendKey}" | md5sum)
	# check if we should send
	if (( "$sendSwitch" == 2 ))
	then
		# send every time
		send=1
	elif grep -Fxq "$keySendTime" "$VDMHOME/.cointracker"
	then
		# Do not send notification (already send in time frame)
		send=0
	else
		# add key to file
		echo "$keySendTime" >> "$VDMHOME/.cointracker"
		# send notification if asked to
		send=1
	fi
	
}

# set the send key
function setSendKey () {
	# what is the cycle of send time
	if (( "$sendSwitch" == 1 ));
	then
		# once every hour
		sendKey=$(TZ=":ZULU" date +"%m/%d/%Y (%H)" )
	elif (( "$sendSwitch" == 3 ));
	then
		# show only once (ever)
		sendKey="showOnce"
	fi
	# default (once per day)
	# or send every time
}

# getting the price from CEX.io (API)
function get_Price () {
	# get price from API
    json=$(wget -q -O- "$1")
    value=($( echo "$json" | jq -r '.lprice'))
    echo "${value}"
}

# Some defaults
Currency="BTC"
Target="USD"
TargetValue="17000"
TargetBelowValue=0
TargetAboveValue=0
sendKey=$(TZ=":ZULU" date +"%m/%d/%Y" )
send=0
sendSwitch=0
BelowValue=0
AboveValue=0
Telegram=0
LinuxNotice=0
SMS=0
API="https://cex.io/api/last_price/"
VDMHOME=~/

# set some arrays
declare -A aboveMessages
declare -A belowMessages
Messages=()

# use UTC+00:00 time also called zulu
Datetimenow=$(TZ=":ZULU" date +"%m/%d/%Y @ %R (UTC)" )

# Help display function
function send_help {
cat << EOF
Usage: ${0##*/:-} [OPTION...]
Getting Coin Value in Fiat Currency at set price

   -c Currency to watch (c:_)
			example: BTC
   -t Target Currecy to Display (_:t)
			example: USD
   -s The cycle of time to follow
			0 = once per/day (default)
			1 = once per/hour
			2 = everyTime
			3 = only once
   -v Value (above or below) at which to send/send notice
			example: 17000 or 14000,15000
   -A Value Above at which to send notice
			example: 17000 or 19000,18000
   -B Value Below at which to send notice
			example: 14000 or 14000,15000
   -b Send Notice below target value once a day
   -a Send Notice above target value once a day (default)
   -n Send A Telegram Notice aswell (always sends comandline Notice)
   -m Send A SMS Notice aswell (always shows comandline Notice)
   -l Show A Linux Notice aswell (always shows comandline Notice)

EOF
exit 1
}

# getopts howtos: (mainly for me)
# http://www.theunixschool.com/2012/08/getopts-how-to-pass-command-line-options-shell-script-Linux.html
# http://mywiki.wooledge.org/BashFAQ/035
# http://wiki.bash-hackers.org/howto/getopts_tutorial

while getopts ":c:t:s:v:A:B:b :a :n :m :l :" opt; do
	case $opt in
	c)
		Currency=$OPTARG
	;;
	t)
		Target=$OPTARG
	;;
	s)
		sendSwitch=$OPTARG
	;;
	v)
		TargetValue=$OPTARG
	;;
	B)
		TargetBelowValue=$OPTARG
	;;
	A)
		TargetAboveValue=$OPTARG
	;;
	b)
		BelowValue=1
	;;
	a)
		AboveValue=1
	;;
	n)
		Telegram=1
	;;
	m)
		SMS=1
	;;
	l)
		LinuxNotice=1
	;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		echo
		show_help
	;;
	esac
done

# little echo tweak
function echoTweak () {
	echoMessage="$1"
	chrlen="${#echoMessage}"
	if [ $# -eq 2 ] 
	then
		mainlen="$2"
	else
		mainlen=70
	fi	
	increaseBy=$((20+mainlen-chrlen))
	tweaked=$(repeat "$increaseBy")
	echo ".... $echoMessage $tweaked"
}

# little repeater
function repeat () {
	head -c $1 < /dev/zero | tr '\0' '\056'
}

# make sure the tracker file is set
if [ ! -f "$VDMHOME/.cointracker" ] 
then
	> "$VDMHOME/.cointracker"
fi

# Run the script
main
