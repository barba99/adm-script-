fun_bar () {
comando[0]="$1"
comando[1]="$2"
 (
[[ -e $HOME/fim ]] && rm $HOME/fim
${comando[0]} -y > /dev/null 2>&1
${comando[1]} -y > /dev/null 2>&1
touch $HOME/fim
 ) > /dev/null 2>&1 &
sp="/-\|"
unset a
while [[ ! -e $HOME/fim ]]; do
  for((i=0; i<5; i++)); do
    echo -ne "\033[1;33m ["
    a+="#"
    echo -ne "\033[1;31m${a}"
    echo -ne "\033[1;33m]"
    echo -ne " - \033[1;33m[\033[1;32m"
    echo -ne "${sp:i%${#sp}:1}"
    echo -e "\033[1;33m]"
    sleep 1
    tput cuu1
    tput dl1
  done
done
echo -e " \033[1;33m[\033[1;31m${a}\033[1;33m] - \033[1;33m[\033[1;32m100%\033[1;33m]\033[0m"
rm $HOME/fim
}

cor[2]="\033[1;37m"
text="Instalando"
echo -e "${cor[2]} $text Curl"
fun_bar 'apt-get install screen' 'apt-get install python'
echo -e "${cor[2]} $text Nmap"
fun_bar 'apt-get install lsof' 'apt-get install python3-pip'
echo -e "${cor[2]} $text Lsof"
fun_bar 'apt-get install python' 'apt-get install unzip'
echo -e "${cor[2]} $text Python3"
fun_bar 'apt-get install zip' 'apt-get install apache2'
echo -e "${cor[2]} $text Unzip"
fun_bar 'apt-get install ufw' 'apt-get install nmap'
echo -e "${cor[2]} $text Screen"
fun_bar 'apt-get install figlet' 'apt-get install bc'
echo -e "${cor[2]} $text Apache2"
fun_bar 'apt-get install lynx' 'apt-get install curl'
sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
service apache2 restart > /dev/null 2>&1
