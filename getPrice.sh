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
		# run basic price get
		runBasicGet
	fi
}

# Help display function
function show_help {
cat << EOF
Usage: ${0##*/:-} [OPTION...]
Getting Coin Value in Fiat Currency at set price

	Basic options
	======================================================
   -c Currency to watch (c:_)
			example: BTC
   -C Target Currecy to Display (_:t)
			example: USD
   -o How often should the message be send/shown
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
	
	Advance options (factory option)
	======================================================
   -f Path to file with multiple currency pair options 
		(see example factory.txt file for details)

	Message options
	======================================================
   -q Quiet - Turn off terninal output
   -t Send A Telegram Notice
   -s Send A SMS Notice
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

while getopts hc:C:o:v:B:A:baqtslf: opt; do
	case $opt in
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
	v)
		TargetValue=$OPTARG
		TargetAll=1
	;;
	B)
		TargetBelowValue=$OPTARG
		TargetBelow=1
	;;
	A)
		TargetAboveValue=$OPTARG
		TargetAbove=1
	;;
	b)
		BelowValue=1
	;;
	a)
		AboveValue=1
	;;
	q)
		allowEcho=0
	;;
	t)
		Telegram=1
	;;
	s)
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

# Run the script
main
