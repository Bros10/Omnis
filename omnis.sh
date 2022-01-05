#!/bin/bash

while getopts d:m: flag
do
	case "${flag}" in 
		d) domain=${OPTARG};;
		m) mode=${OPTARG};;
	esac
done




RED="\033[1;31m"
RESET="\033[0m"
subdomain_path=$domain/subdomains

if [ ! -d "$domain" ];then
	    mkdir $domain
fi


if [ ! -d "$subdomain_path" ];then
	    mkdir $subdomain_path
fi

go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go get -u github.com/tomnomnom/assetfinder
go get -u github.com/tomnomnom/httprobe

echo -e "${RED} [+] Launching subfinder...${RESET}"
subfinder -d $domain > $subdomain_path/found.txt

echo -e "${RED} [+] Running assetfinder...${RESET}"
assetfinder $domain | grep $domain >> $subdomain_path/found.txt

echo -e "${RED} [+] Running Amass. This could take a while...${RESET}"
amass enum -d $domain >> $subdomain_path/found.txt

echo -e "${RED} [+] Checking what's alive...${RESET}"
cat $subdomain_path/found.txt | grep $domain | sort -u | httprobe -prefer-https | grep https | sed 's/https\?:\/\///' | tee -a $subdomain_path/alive.txt

echo -e "${RED} [+] Taking dem screenshotz...${RESET}"
gowitness file -f $subdomain_path/alive.txt -P $screenshot_path/ --no-http
