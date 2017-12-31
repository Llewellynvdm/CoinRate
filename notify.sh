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

# Telegram notify
function notifyMe() {
	# check if notify is set
	if [ ! -f "$DIR/notify" ] 
	then
		echo "Please set the details for Telegram found in notify.txt"
		exit 1
	fi
	# get first line
	local NOTIFY=$(sed -n "${TelegramID}p" <  "$DIR/notify")

	# get the keys
	IFS=$'	'
	local keys=( $NOTIFY )

	# set chatid & token
	local chatid="${keys[0]}"
	local token="${keys[1]}"
	local default_message="notify!"

	if [ -z "$@" ]
	then
		curl -s --data-urlencode "text=$default_message" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null
	else
		curl -s --data-urlencode "text=$@" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null
	fi
}
