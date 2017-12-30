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
#=================================================================================================================================
#                           FUNCTIONS
#=================================================================================================================================

# run with the advance field options
function runFactory () {
	# array of repos
	readarray -t currencypairs < "$FilePath"
	# check that the file has values
	if [ ${#currencypairs[@]} -gt 0 ]; then
		# display
		if (( "$allowEcho" == 1 )); then
			echo ".................................[ Vast Development Method ]...................................."
			echo "...========================================================================| www.vdm.io |====..."
			echoTweak "Getting all the prices from ${API_target}"
			echo "...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..."
		fi
		# now start parsing the values
		for cpairs in "${currencypairs[@]}"; do
			# convert line to array
			local currencypair=($cpairs)
			# check number of values
			if [ ${#currencypair[@]} == 4 ]; then
				# set globals
				Currency="${currencypair[0]}"
				Target="${currencypair[1]}"
				TargetValue="${currencypair[2]}"
				TargetAll=1
				if (( "${currencypair[3]}" == 1 )); then
					AboveValue=1
				else
					BelowValue=1
				fi
				# run the main functions
				runMain
			else
				echoTweak "Line missing values, see example factory.txt file for details"
			fi
		done
		# display
		if (( "$allowEcho" == 1 )); then
			echo "...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..."
		fi
		# send Messages
		sendMessages
		# display
		if (( "$allowEcho" == 1 )); then
			echo "...==========================================================================================..."
			echo "................................................................................................"
		fi
	else
		if (( "$allowEcho" == 1 )); then
			echo "The file supplied is empty, please add your options to the file (see example factory.txt file for details)"
			show_help >&2
			exit 1
		fi
	fi
}

# run with the basic options
function runBasicGet () {
	# display
	if (( "$allowEcho" == 1 )); then
		echo ".................................[ Vast Development Method ]...................................."
		echo "...========================================================================| www.vdm.io |====..."
		echoTweak "Getting the current price of $Currency in $Target"
		echo "...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..."
	fi
	# run the main functions
	runMain
	# display
	if (( "$allowEcho" == 1 )); then
		echo "...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..."
	fi
	# send Messages
	sendMessages
	# display
	if (( "$allowEcho" == 1 )); then
		echo "...==========================================================================================..."
		echo "................................................................................................"
	fi
}

# run main
function runMain () {
	# do some checks
	runValidation
	# get the active currency/target
	getActiveCurrencyTarget	
}

# get active currency target
function getActiveCurrencyTarget () {
	# get price if not already set
	get_Price
	# get the price value
	value="${CurrencyPair[${Currency}${Target}]}"
	# set send key
	setSendKey
	# set target values and perform action if only TargetValue given
	if (( "$TargetAll" == 1 && "$TargetBelow" == 0 && "$TargetAbove" == 0));
	then
		getTarget "$TargetValue" "$value" 'setAction'
	fi
	# set target values and perform action if TargetBelowValue given
	if (( "$TargetAbove" == 1 ));
	then
		getTarget "$TargetAboveValue" "$value" 'setActionAbove'
	fi
	# set target values and perform action if TargetBelowValue given
	if (( "$TargetBelow" == 1 ));
	then
		getTarget "$TargetBelowValue" "$value" 'setActionBelow'
	fi
}

# get the target
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

# action or all
function setAction () {
	# set Args
	local current_value="$1"
	local target_value="$2"
	# should we do above
	setActionAbove "$current_value" "$target_value"
	# should we do below
	setActionBelow "$current_value" "$target_value"
}

# action above
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

# action below
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

# performing the task
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
		echoTweak "${Currency} not ${target_type} ${target_value}${Target} at this time!"
	fi
}

# set message
function setMessage () {
	# set Args
	local target_type="$1"
	local current_value="$2"
	local target_value="$3"
	# build message
	message="${Currency} is ${target_type} ${target_value} ${Target} at ${current_value} ${Target}" &&
	# first send to comand line
	echoTweak "${message} - ${Datetimenow} " &&
	# is it send time
	sendTime "$target_type" "$target_value" &&
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
			belowMessages["${Currency}${Target}${value}"]="$message"
			# check if we have this array declared
			if [[ -z "${belowKeys[${Currency}${Target}]+unset}" ]]; then 
				# load the value
				belowKeys["${Currency}${Target}"]="$value"
			else
				# test if we should load the value
				local cValue="${belowKeys[${Currency}${Target}]}"
				local updateValue=$(echo "$cValue > $value" | bc -l)
				if (( "$updateValue" == 1 )); then
					belowKeys["${Currency}${Target}"]="$value"
				fi
			fi
		elif [ "$type" == "above" ]; then
			# set above message
			aboveMessages["${Currency}${Target}${value}"]="$message"
			# check if we have this array declared
			if [[ -z "${aboveKeys[${Currency}${Target}]+unset}" ]]; then 
				# load the value
				aboveKeys["${Currency}${Target}"]="$value"
			else
				# test if we should load the value
				local cValue="${aboveKeys[${Currency}${Target}]}"
				local updateValue=$(echo "$cValue < $value" | bc -l)
				if (( "$updateValue" == 1 )); then
					aboveKeys["${Currency}${Target}"]="$value"
				fi
			fi
		fi
	fi
}

# send messages
function sendMessages () {
	# filter messages to only send the lowest-below and the highest-above
	filterMessages
	# check if we have messages
	if [ ${#Messages[@]} -gt 0 ]; then
		# load the API being targeted
		if (( "$API_show" == 1 )); then
			Messages+=("(${API_target})")
		fi
		# set to string
		IFS=$'\n'
		local messages="${Messages[*]}"
		# send Telegram messages if allowed
		sendTelegram "${messages}" &&
		# show linux messages if allowed
		showLinuxMessage "${messages}" &&
		# send SMS messages if allowed
		sendSMSMessage "${messages}"
	fi
}

# filter messages to only send the lowest-below and the highest-above
function filterMessages () {
	# load a currency pair only once (above/below)
	declare -A oncePer
	# check if higher value is found
	if [ ${#aboveMessages[@]} -gt 0 ]; then
		for i in "${!aboveKeys[@]}"
		do
			# set it
			oncePer["$i"]="$i"
			# get the value
			local valKey="${aboveKeys[$i]}"
			# set to messages
			Messages+=("${aboveMessages[$i$valKey]}")
		done
	fi
	# check if lower value is found
	if [ ${#belowMessages[@]} -gt 0 ]; then
		for i in "${!belowKeys[@]}"
		do
			#check if it was set already
			if [[ -z "${oncePer[$i]+unset}" ]]; then 
				# get the value
				local valKey="${belowKeys[$i]}"
				# set to messages
				Messages+=("${belowMessages[$i$valKey]}")
			fi
		done
	fi
}

# show message in linux (will not work on server)
function showLinuxMessage () {
	# do some prep
	command -v zenity >/dev/null 2>&1 || { echoTweak "We require zenity to show linux notice, but it's not installed."; LinuxNotice=0; }
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
	elif grep -Fxq "$keySendTime" "$COINTracker"
	then
		# Do not send notification (already send in time frame)
		send=0
	else
		# add key to file
		echo "$keySendTime" >> "$COINTracker"
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
	# check if we already have this Currency Pair Value
	if [[ -z "${CurrencyPair[${Currency}${Target}]+unset}" ]]; then 
		# show what currency pair is being fetched
		if (( "$Factory" == 1 )); then
			echoTweak "Getting the current price of $Currency in $Target"
		fi
		# get price from API
		if [ "${API_target}" == "cex" ]; then
			local URL="${API_cex}${Currency}/${Target}"
		elif [ "${API_target}" == "shapeshift" ]; then
			local URL="${API_shapeshift}${Currency}_${Target}"
		fi
		# now get the json
		local json=$(wget -q -O- "$URL")
		# check if we have and error
		local error=($( echo "$json" | jq -r '.error'))
		if [ "${error}" != "null" ]; then
			echo "Currency Pair: $error"
			exit 1
		fi
		# set the value
		if [ "${API_target}" == "cex" ]; then
			local value=($( echo "$json" | jq -r '.lprice'))
		elif [ "${API_target}" == "shapeshift" ]; then
			local value=($( echo "$json" | jq -r '.rate'))
		fi
		# add value to global bucket
		CurrencyPair["${Currency}${Target}"]="$value"
	fi
}

# run some validation against the options given
function runValidation () {
	# check if above or below value is set
	if (( "$BelowValue" == 0 && "$AboveValue" == 0 )); then
		echo "Above or Below Switch are required!"
		show_help
		exit 1
	fi
	# check that value are set
	if (( "$BelowValue" == 1 && "$TargetAll" == 0 && "$TargetBelow" == 0)); then
		echo "A below value is required!"
		show_help
		exit 1
	fi
	# check that value are set
	if (( "$AboveValue" == 1 && "$TargetAll" == 0 && "$TargetAbove" == 0)); then
		echo "An above value is required!"
		show_help
		exit 1
	fi
	# check that value are set
	if (( "$TargetAll" == 0 && "$TargetBelow" == 0 && "$TargetAbove" == 0 )); then
		echo "A value is required!"
		show_help
		exit 1
	fi
}

# little echo tweak
function echoTweak () {
	if (( "$allowEcho" == 1 )); then
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
	fi
}

# little repeater
function repeat () {
	head -c $1 < /dev/zero | tr '\0' '\056'
}
