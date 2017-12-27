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

# main function
function main () {
	echoTweak "Getting the current price of $Currency in $Target"
	echo
	# get the price value
	value=$(get_Price "${API}${Currency}/${Target}")
	# set show key
	setShowKey
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
	# show linux messages if any were loaded
	showLinuxMessage
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
		# send message since we are above target value
		sendMessage "$target_type" "$current_value" "$target_value"
	else
		echoTweak "Nothing to report at this time! ($target_value)"
	fi
	echo
}

# send message
function sendMessage () {
	# set Args
	local target_type="$1"
	local current_value="$2"
	local target_value="$3"
	# build message
	message="${Currency} is ${target_type} ${target_value}${Target} at ${current_value}${Target}"
	# first send to comand line
	echoTweak "${message} - ${Datetimenow}"
	# is it show time
	showTime "$target_type" "$target_value"
	# send to telegram
	sendTelegram "$message"
	# set Linux messages
	setLinuxMessage "$message"
}

# check if we already showed the message today
function showTime () {
	# set Args
	local target_type="$1"
	local target_value="$2"
	# build key show time
	keyShowTime=$(echo -n "${target_type}${target_value}${showKey}" | md5sum)
	if grep -Fxq "$keyShowTime" "$VDMHOME/.cointracker"
	then
		# Do not send notification (already send in time frame)
		show=0
	else
		# add key to file
		echo "$keyShowTime" >> "$VDMHOME/.cointracker"
		# send notification if asked to
		show=1
	fi
	
}

# set the show key
function setShowKey () {
	# what is the cycle of show time
	if (( "$showSwitch" == 1 ));
	then
		# once every hour
		showKey=$(TZ=":ZULU" date +"%m/%d/%Y (%H)" )
	elif (( "$showSwitch" == 2 ));
	then
		# on every run
		showKey=$((1 + RANDOM % 1000000))
	elif (( "$showSwitch" == 3 ));
	then
		# only once ever
		showKey="OnlyOnce"
	fi
	# default (once per day)
}

# use UTC+00:00 time also called zulu
Datetimenow=$(TZ=":ZULU" date +"%m/%d/%Y @ %R (UTC)" )

# getting the data from yahoo
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
showKey=$(TZ=":ZULU" date +"%m/%d/%Y" )
show=0
showSwitch=0
BelowValue=0
AboveValue=0
Telegram=0
linuxMessages=()
LinuxNotice=0
API="https://cex.io/api/last_price/"
VDMHOME=~/

# Help display function
function show_help {
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
   -v Value (above or below) at which to show/send notice
			example: 17000 or 14000,15000
   -A Value Above at which to show/send notice
			example: 17000 or 19000,18000
   -B Value Below at which to show/send notice
			example: 14000 or 14000,15000
   -b Send Notice below target value once a day
   -a Send Notice above target value once a day (default)
   -n Send A Telegram Notice aswell (always shows comandline Notice)
   -l Show A Linux Notice aswell (always shows comandline Notice)

EOF
exit 1
}

# getopts howtos: (mainly for me)
# http://www.theunixschool.com/2012/08/getopts-how-to-pass-command-line-options-shell-script-Linux.html
# http://mywiki.wooledge.org/BashFAQ/035
# http://wiki.bash-hackers.org/howto/getopts_tutorial

while getopts ":c:t:s:v:A:B:b :a :n :l :" opt; do
	case $opt in
	c)
		Currency=$OPTARG
	;;
	t)
		Target=$OPTARG
	;;
	s)
		showSwitch=$OPTARG
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
	echo -n "$echoMessage$tweaked"
}

# little repeater
function repeat () {
	head -c $1 < /dev/zero | tr '\0' '\056'
}

# set linux messages
function setLinuxMessage () {
	# check if we should show linux messages
	if (( "$LinuxNotice" == 1 && "$show" == 1 ));
		then
		linuxMessages+=("$1")
	fi
}

# show message in linux
function showLinuxMessage () {
	# check if we have messages to show
	if [ ${#linuxMessages[@]} -gt 0 ]; then
		IFS=$'\n'
		messages="${linuxMessages[*]}"
		zenity --text="${messages}" --info 2> /dev/null
	fi
}

# send Telegram
function sendTelegram () {
	# check if we should send telegram
	if (( "$Telegram" ==  1 && "$show" == 1 ));
	then
		notifyMe "$1"
	fi
}

# make sure the tracker file is set
if [ ! -f "$VDMHOME/.cointracker" ] 
then
	> "$VDMHOME/.cointracker"
fi

# Run the script
main
