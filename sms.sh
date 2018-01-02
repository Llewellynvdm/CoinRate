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

# clickatell sms HTTP
function smsMe() {
	# check if sms details are set
	if [ ! -f "$DIR/sms" ] 
	then
		echo "Please set the details for clickatell found in sms.txt"
		exit 1
	fi
	# check if phone numbers are set
	if [ ! -f "$DIR/smsto" ] 
	then
		echo "Please set the phone numbers as found in smsto.txt"
		exit 1
	fi
	# set Args
	local message="$1"
	# little fix just incase
	message="${message//▲/(up)}"
	message="${message//▼/(down)}"
	# get first line
	local SMSd=$(sed -n "${smsID}p" <  "$DIR/sms")
	local to=$(sed -n "${smstoID}p" <  "$DIR/smsto")
	# get the keys
	IFS=$'	'
	local keyss=( $SMSd )
	# set user, password & api_id
	local username="${keyss[0]}"
	local password="${keyss[1]}"
	local api_id="${keyss[2]}"
	# send the sms's
	curl -s --data "user=${username}&password=${password}&api_id=${api_id}&to=${to}&text=${message}" "https://api.clickatell.com/http/sendmsg" > /dev/null
}
