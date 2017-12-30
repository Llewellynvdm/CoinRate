# Coin Rate Watcher
The Bash script gets current values for cryptocurrencies from a variety of Exchange APIs, and then calculates if various notifications should be send based on above or below price margins. All dynamically set by command options or file, you can now stay informed of any changes in the market with this coin rate watching script.

## The Get Method (getPrice.sh)

..... more info soon

## Features

* hmmm many

## Getting started

First, clone the repository using git:

```bash
   $git clone https://github.com/vdm-io/CoinRate.git
```

Then give the execution permission to this file:

```bash
   $chmod +x getPrice.sh
```

Set your sms details (if required):

Read [sms.txt](https://github.com/vdm-io/CoinRate/blob/master/sms.txt) for more details.

Set your Telegram details (if required):

Read [notify.txt](https://github.com/vdm-io/CoinRate/blob/master/notify.txt) for more details.

Set your Factory details (if you want to do build checks):

Read [factory.txt](https://github.com/vdm-io/CoinRate/blob/master/factory.txt) for more details.

## Usage GET

The syntax is quite simple:

```
 $./getPrice.sh <PARAMETERS>

<%%>: Required param
```

**Parameters:**  
```text
API options
======================================================
-I Select the api to query 
	Options:
	1 = [cex] cex.io - (default)
	2 =	[shapeshift] 
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
```

**Examples (CEX API):**
```bash
# Get Linux & SMS & Telegram notice when BTC is above 10000 USD (every time command is run)
    ./getPrice.sh -c BTC -C USD -av 10000 -lst

# Get Telegram notice when BTC is [above 15000,16000,17000 USD] & [below 14000,13000,12000 USD] (every hour - if run in crontab)
    ./getPrice.sh -c BTC -C USD -aA 15000,16000,17000 -bB 14000,13000,12000 -to 1

# Get SMS notice when XRP is [above 2.50,2.60,3 USD] & [below 2.50,2.40,2.30 USD] (only once - if run in crontab)
    ./getPrice.sh -c XRP -C USD -aA 2.50,2.60,3 -bB 2.50,2.40,2.30 -so 3

# Get Telegram notice when any curracy pair in file meets criteria (once a day - if run in crontab)
    ./getPrice.sh -f /home/coin/factory -to 0
```

**To use shapeshift API ad the `-I 2` command:***
```bash
# Get Linux & SMS & Telegram notice when BTC is above 10000 USD (every time command is run)
    ./getPrice.sh -c BTC -C USD -av 10000 -lst -I 2
```

## Tested Environments

* GNU Linux

If you have successfully tested this script on others systems or platforms please let me know!

## Running as cron job (ubuntu)

First, open crontab:

```bash
   $crontab -e
```

Add the following line at bottom of the file (adapting to your script location!!!):

```bash
* * * * * /home/bitnami/coin/getPrice.sh -f /home/bitnami/coin/factory -to 1 -I 2 >> /home/bitnami/coin/coin.log
```
or
```bash
* * * * * /home/bitnami/coin/getPrice.sh -c BTC -C USD -aA 15000,16000,17000 -bB 14000,13000,12000 -to 1 -q
* * * * * /home/bitnami/coin/getPrice.sh -c XRP -C USD -aA 2.50,2.60,3 -bB 2.50,2.40,2.30 -so 3 -q -I 2
```
   
## BASH, JQ, curl and bc installation

**Debian & Ubuntu Linux:**
```bash
    $sudo apt-get install bash (Probably BASH is already installed on your system)
	$sudo apt-get install bc (Probably bc is already installed on your system)
	$sudo apt-get install curl
    $sudo apt-get install jq
```

## Donations

Come on buy me a coffee :)
 * PayPal: [paypal.me/payvdm](https://www.paypal.me/payvdm)
 * Bitcoin: 18vURxYpPFjvNk8BnUy1ovCAyQmY3MzkSf
 * Ethereum: 0x9548144662b47327c954f3e214edb96662d51218
