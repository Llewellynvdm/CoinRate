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
#                           GETPRICE
#=================================================================================================================================

# get script path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VDMHOME=~/

# add the main file
. "$DIR/main.sh"

# main function
function main () {
	# run factory
	if (( "$Factory" == 1 )); then
		# run the factory
		runFactory
	else
		# if Percentage is active update above and below based on history
		if (( "$PercentSwitch" == 1 )); then
			setPercentage
		fi
		# run basic price get
		runBasicGet
	fi
}

# Help display function
function show_help {
cat << EOF
Usage: ${0##*/:-} [OPTION...]
Getting Coin Value in Fiat Currency at set price

	API options
	======================================================
   -I Select the api to query 
		Options:
		1 = [cex] cex.io - (default)
		2 = [shapeshift] shapeshift.io
		3 = [bitfinex] bitfinex.com
		4 = [gate] gate.io
		5 = [luno] luno.com
   -x Hide API name from message

	Basic options
	======================================================
   -c Currency to watch (c:_)
		example: BTC
   -C Target Currecy to Display (_:t)
		example: USD
   -o How often should the message be send/shown
		0 = once per/day
		1 = once per/hour
		2 = everyTime (default)
		3 = only once
   -p The percentage up or down at which to send/show notice
   -v Value (above or below) at which to send/show notice
		example: 17000 or 14000,15000
   -A Value Above at which to send notice
		example: 17000 or 19000,18000
   -B Value Below at which to send notice
		example: 14000 or 14000,15000
   -b Send Notice below target value once a day
   -a Send Notice above target value once a day (default)
   -k show the above value and below value in the result string
	
	Advance options (factory option)
	======================================================
   -f Path to file with multiple currency pair options (Fixed values)
		(see example factory.txt file for details)
   -P Path to file with multiple currency pair options (Percentages)
		(see example dynamic.txt file for details)

	Message options
	======================================================
   -q Quiet - Turn off terminal output
   -t Send A Telegram Notice
   -T Set notify Line number to use (first line is default)
   -s Send A SMS Notice
   -M Set sms Line number to use (first line is default)
   -S Set smsto Line number to use (first line is default)
   -l Show A Linux Notice via zenity

   -h display this help menu

	======================================================
               Vast Development Method (vdm.io)
	======================================================
EOF
exit 1
}

# getopts howtos: (mainly for me)
# http://www.theunixschool.com/2012/08/getopts-how-to-pass-command-line-options-shell-script-Linux.html
# http://mywiki.wooledge.org/BashFAQ/035
# http://wiki.bash-hackers.org/howto/getopts_tutorial

while getopts hc:C:o:v:B:A:baqtT:sS:M:lf:I:kp:P: opt; do
	case $opt in
	I)
		if (( "$OPTARG" == 2 )); then
			API_target="shapeshift"
			API_urlname="shapeshift.io"
		elif (( "$OPTARG" == 3 )); then
			API_target="bitfinex"
			API_urlname="bitfinex.com"
		elif (( "$OPTARG" == 4 )); then
			API_target="gate"
			API_urlname="gate.io"
		elif (( "$OPTARG" == 5 )); then
			API_target="luno"
			API_urlname="luno.com"
		fi
	;;
	x)
		API_show=0
	;;
	h)
		show_help >&2
		exit 1
	;;
	c)
		Currency=$OPTARG
	;;
	C)
		Target=$OPTARG
	;;
	o)
		sendSwitch=$OPTARG
	;;
	p)
		Percentage=$OPTARG
		PercentSwitch=1
	;;
	P)
		FilePath=$OPTARG
		# make sure we have a file
		if [ ! -f "$FilePath" ] 
		then
			echo "File path ($FilePath) does not exist, please add correct path"
			show_help >&2
			exit 1
		fi
		Factory=1
		# reset all basic settings
		Currency="BTC"
		Target="USD"
		TargetValue=0
		TargetBelowValue=0
		TargetAboveValue=0
		TargetAll=0
		TargetBelow=0
		TargetAbove=0
		BelowValue=0
		AboveValue=0
		# percentage switch
		PercentSwitch=1
	;;
	v)
		TargetValue=$OPTARG
		TargetAll=1
	;;
	B)
		TargetBelowValue=$OPTARG
		TargetBelow=1
		BelowValue=1
	;;
	A)
		TargetAboveValue=$OPTARG
		TargetAbove=1
		AboveValue=1
	;;
	b)
		BelowValue=1
	;;
	a)
		AboveValue=1
	;;
	k)
		showAB=1
	;;
	q)
		allowEcho=0
	;;
	t)
		Telegram=1
	;;
	T)
		TelegramID=$OPTARG
		Telegram=1
	;;
	s)
		SMS=1
	;;
	S)
		smstoID=$OPTARG
		SMS=1
	;;
	M)
		smsID=$OPTARG
		SMS=1
	;;
	l)
		LinuxNotice=1
	;;
	f)
		FilePath=$OPTARG
		# make sure we have a file
		if [ ! -f "$FilePath" ] 
		then
			echo "File path ($FilePath) does not exist, please add correct path"
			show_help >&2
			exit 1
		fi
		Factory=1
		# reset all basic settings
		Currency="BTC"
		Target="USD"
		TargetValue=0
		TargetBelowValue=0
		TargetAboveValue=0
		TargetAll=0
		TargetBelow=0
		TargetAbove=0
		BelowValue=0
		AboveValue=0
	;;
	*)
		show_help >&2
		exit 1
	;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		echo
		show_help >&2
		exit 1
	;;
	esac
done

# set call ID
CALL_ID=$(echo -n "${API_target}${smsID}${smstoID}${TelegramID}" | md5sum | sed 's/ .*$//')

# BUILD Cointracker file per/API (user)
COINTracker="${VDMHOME}/.cointracker_${CALL_ID}"
# make sure the tracker file is set
if [ ! -f "$COINTracker" ] 
then
	> "$COINTracker"
fi

# only set if we have percentage
if (( "$PercentSwitch" == 1 )); then
	# BUILD Coin value tracker file per/API (user)
	COINvaluePath="${VDMHOME}/.coinvalue_${CALL_ID}"
	# make sure the tracker file is set
	if [ ! -f "$COINvaluePath" ] 
	then
		> "$COINvaluePath"
	fi
fi
# Run the script
main
