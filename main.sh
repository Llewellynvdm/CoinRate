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
#                           MAIN
#=================================================================================================================================

# main is loaded
MAINLOAD=1

# Do some prep work
command -v jq >/dev/null 2>&1 || { echo >&2 "We require jq for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "We require curl for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v bc >/dev/null 2>&1 || { echo >&2 "We require bc for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v sed >/dev/null 2>&1 || { echo >&2 "We require sed for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v md5sum >/dev/null 2>&1 || { echo >&2 "We require md5sum for this script to run, but it's not installed.  Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 "We require awk for this script to run, but it's not installed.  Aborting."; exit 1; }

# load notify
. "$DIR/functions.sh"

# load notify
. "$DIR/notify.sh"

# load sms
. "$DIR/sms.sh"

# Some global defaults
Factory=0

# basic settings
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
Percentage=0
PercentSwitch=0

# message settings
send=0
sendSwitch=2
showAB=0
sendKey=$(TZ=":ZULU" date +"%m/%d/%Y" )
allowEcho=1
Telegram=0
TelegramID=1
LinuxNotice=0
SMS=0
smsID=1
smstoID=1

# API Details
API_show=1
# defaults
API_target="cex"
API_urlname="cex.io"
# cex
API_cex="https://cex.io/api/last_price/" # (default)
API_json_cex="lprice"
API_error_cex="error"
API_error_value_cex="null"
# shapeshift
API_shapeshift="https://shapeshift.io/rate/"
API_json_shapeshift="rate"
API_error_shapeshift="error"
API_error_value_shapeshift="null"
# bitfinex
API_bitfinex="https://api.bitfinex.com/v1/pubticker/"
API_json_bitfinex="last_price"
API_error_bitfinex="message"
API_error_value_bitfinex="null"
# gate
API_gate="https://data.gate.io/api2/1/ticker/"
API_json_gate="last"
API_error_gate="message"
API_error_value_gate="null"

# file path to config
FilePath=''

# percentage values
COINvaluePath="null"
COINnewValue="null"
COINoldValue="null"
COINlineNr="null"
COINupdate=0

# Some Messages arrays
declare -A CurrencyPair
declare -A aboveMessages
declare -A aboveKeys
declare -A belowMessages
declare -A belowKeys
Messages=()

# use UTC+00:00 time also called zulu
Datetimenow=$(TZ=":ZULU" date +"%m/%d/%Y @ %R (UTC)" )
