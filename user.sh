#!/bin/bash
source cabecalho
SCPdir="/etc/newadm"
SCPusr="${SCPdir}/ger-user"
USRdatabase="/etc/ADMuser"
# Open VPN
newclient () {
#Nome #Senha
usermod -p $(openssl passwd -1 $2) $1
  while [[ ${newfile} != @(s|S|y|Y|n|N) ]]; do
   read -p "Criar Arquivo Openvpn? [S/N]: " -e -i S newfile
   tput cuu1 && tput dl1
  done
if [[ ${newfile} = @(s|S) ]]; then
cp /etc/openvpn/client-common.txt $HOME/$1.ovpn
echo "<key>
$(cat /bin/openvpn/client-key.pem)
</key>
<cert>
$(cat /bin/openvpn/client-cert.pem)
</cert>
<ca>
$(cat /etc/openvpn/ca.pem)
</ca>" >> $HOME/$1.ovpn
  while [[ ${ovpnauth} != @(s|S|y|Y|n|N) ]]; do
    read -p "Colocar Autenticacao de Usuario no Arquivo? [S/N]: " -e -i S ovpnauth
    tput cuu1 && tput dl1
  done
  [[ ${ovpnauth} = @(n|N) ]] && sed -i "s;auth-user-pass;<auth-user-pass>\n$1\n$2\n</auth-user-pass>;g" $HOME/$1.ovpn
  cd $HOME
  zip ./$1.zip ./$1.ovpn > /dev/null 2>&1
  rm ./$1.ovpn > /dev/null 2>&1
  echo -e "\033[1;31mArquivo Criado em: ($HOME/$1.zip)"
 fi
}
block_userfun () {
local USRloked="/etc/newadm-userlock"
local LIMITERLOG="${USRdatabase}/Limiter.log"
if [[ $2 = "-loked" ]]; then
[[ $(cat ${USRloked}|grep -w "$1") ]] && return 1
echo "USER: $1 (LOKED - MULTILOGUIN) $(date +%r)"
fi
if [[ $(cat ${USRloked}|grep -w "$1") ]]; then
usermod -U "$1" &>/dev/null
[[ -e ${USRloked} ]] && {
   newbase=$(cat ${USRloked}|grep -w -v "$1")
   [[ -e ${USRloked} ]] && rm ${USRloked}
   for value in `echo ${newbase}`; do
   echo $value >> ${USRloked}
   done
   }
[[ -e ${LIMITERLOG} ]] && [[ $(cat ${LIMITERLOG}|grep -w "$1") ]] && {
   newbase=$(cat ${LIMITERLOG}|grep -w -v "$1")
   [[ -e ${LIMITERLOG} ]] && rm ${LIMITERLOG}
   for value in `echo ${newbase}`; do
   echo $value >> ${LIMITERLOG}
   done
}
return 1
else
usermod -L "$1" &>/dev/null
echo $1 >> ${USRloked}
return 0
fi
}
block_user () {
local USRloked="/etc/newadm-userlock"
[[ ! -e ${USRloked} ]] && touch ${USRloked}
usuarios_ativos=($(mostrar_usuarios))
if [[ -z ${usuarios_ativos[@]} ]]; then
echo -e "\033[1;33m Ningun  Usuario Creado"
return 1
else
echo -e "\033[1;32m Usuarios Actualmente Activos en su  Servidor"
Numb=0
for us in $(echo ${usuarios_ativos[@]}); do
if [[ $(cat ${USRloked}|grep -w "${us}") ]]; then
echo -ne "[$Numb] ->" && echo -e "\033[1;33m ${us} \033[1;31mLoked"
else
echo -ne "[$Numb] ->" && echo -e "\033[1;33m ${us} \033[1;32mUnlocked"
fi
let Numb++
done
fi
echo -e "\033[1;33mEscriba el nombre o Selecione un  Usuario"
unset selection
while [[ ${selection} = "" ]]; do
echo -ne "\033[1;37mSelect: " && read selection
tput cuu1 && tput dl1
done
if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
usuario_del="${usuarios_ativos[$selection]}"
else
usuario_del="$selection"
fi
[[ -z $usuario_del ]] && {
     echo -e "\033[1;31m Error, Usuario Invalido"
     return 1
     }
[[ ! $(echo ${usuarios_ativos[@]}|grep -w "$usuario_del") ]] && {
     echo -e "\033[1;31m Error, Usuario Invalido"
     return 1
     }
echo -e "\033[1;33m Usuario Selecionado: " && echo -ne "$usuario_del "
block_userfun "$usuario_del" && echo -e "Bloqueado]" || echo -e "Desbloqueado]"
}
add_user () {
#nome senha Dias limite
[[ $(cat /etc/passwd |grep $1: |grep -vi [a-z]$1 |grep -v [0-9]$1 > /dev/null) ]] && return 1
valid=$(date '+%C%y-%m-%d' -d " +$3 days") && datexp=$(date "+%F" -d " + $3 days")
useradd -M -s /bin/false $1 -e ${valid} > /dev/null 2>&1 || return 1
(echo $2; echo $2)|passwd $1 2>/dev/null || {
    userdel --force $1
    return 1
    }
[[ -e ${USRdatabase} ]] && {
   newbase=$(cat ${USRdatabase}|grep -w -v "$1")
   echo "$1|$2|${datexp}|$4" > ${USRdatabase}
   for value in `echo ${newbase}`; do
   echo $value >> ${USRdatabase}
   done
   } || echo "$1|$2|${datexp}|$4" > ${USRdatabase}
}
renew_user_fun () {
#nome dias
datexp=$(date "+%F" -d " + $2 days") && valid=$(date '+%C%y-%m-%d' -d " + $2 days")
chage -E $valid $1 2> /dev/null || return 1
[[ -e ${USRdatabase} ]] && {
   newbase=$(cat ${USRdatabase}|grep -w -v "$1")
   useredit=$(cat ${USRdatabase}|grep -w "$1")
   pass=$(echo $useredit|cut -d'|' -f2)
   limit=$(echo $useredit|cut -d'|' -f4)
   echo "$1|$pass|${datexp}|$limit" > ${USRdatabase}
   for value in `echo ${newbase}`; do
   echo $value >> ${USRdatabase}
   done
   }
}
edit_user_fun () {
#nome senha dias limite
(echo "$2" ; echo "$2" ) |passwd $1 > /dev/null 2>&1 || return 1
datexp=$(date "+%F" -d " + $3 days") && valid=$(date '+%C%y-%m-%d' -d " + $3 days")
chage -E $valid $1 2> /dev/null || return 1
[[ -e ${USRdatabase} ]] && {
   newbase=$(cat ${USRdatabase}|grep -w -v "$1")
   echo "$1|$2|${datexp}|$4" > ${USRdatabase}
   for value in `echo ${newbase}`; do
   echo $value >> ${USRdatabase}
   done
   } || echo "$1|$2|${datexp}|$4" > ${USRdatabase}
}
rm_user () {
#nome
userdel --force "$1" &>/dev/null || return 1
[[ -e ${USRdatabase} ]] && {
   newbase=$(cat ${USRdatabase}|grep -w -v "$1")
   for value in `echo ${newbase}`; do
   echo $value >> ${USRdatabase}
   done
   }
}
mostrar_usuarios () {
for u in `awk -F : '$3 > 900 { print $1 }' /etc/passwd | grep -v "nobody" |grep -vi polkitd |grep -vi system-`; do
echo "$u"
done
}
dropbear_pids () {
local pids
local port_dropbear=`ps aux | grep dropbear | awk NR==1 | awk '{print $17;}'`
cat /var/log/auth.log|grep "$(date|cut -d' ' -f2,3)" > /var/log/authday.log
# cat /var/log/auth.log|tail -1000 > /var/log/authday.log
local log=/var/log/authday.log
local loginsukses='Password auth succeeded'
[[ -z $port_dropbear ]] && return 1
for port in `echo $port_dropbear`; do
 for pidx in $(ps ax |grep dropbear |grep "$port" |awk -F" " '{print $1}'); do
  pids="${pids}$pidx\n"
 done
done
for pid in `echo -e "$pids"`; do
  pidlogs=`grep $pid $log |grep "$loginsukses" |awk -F" " '{print $3}'`
  i=0
    for pidend in $pidlogs; do
    let i++
    done
    if [[ $pidend ]]; then
    login=$(grep $pid $log |grep "$pidend" |grep "$loginsukses")
    PID=$pid
    user=`echo $login |awk -F" " '{print $10}' | sed -r "s/'//g"`
    waktu=$(echo $login |awk -F" " '{print $2"-"$1,$3}')
    [[ -z $user ]] && continue
    echo "$user|$PID|$waktu"
    fi
done
}
openvpn_pids () {
#nome|#loguin|#rcv|#snd|#time
  byte () {
   while read B dummy; do
   [[ "$B" -lt 1024 ]] && echo "${B} bytes" && break
   KB=$(((B+512)/1024))
   [[ "$KB" -lt 1024 ]] && echo "${KB} Kb" && break
   MB=$(((KB+512)/1024))
   [[ "$MB" -lt 1024 ]] && echo "${MB} Mb" && break
   GB=$(((MB+512)/1024))
   [[ "$GB" -lt 1024 ]] && echo "${GB} Gb" && break
   echo $(((GB+512)/1024)) terabytes
   done
   }
for user in $(mostrar_usuarios); do
user="$(echo $user|sed -e 's/[^a-z0-9 -]//ig')"
[[ ! $(sed -n "/^${user},/p" /etc/openvpn/openvpn-status.log) ]] && continue
i=0
unset RECIVED; unset SEND; unset HOUR
 while read line; do
 IDLOCAL=$(echo ${line}|cut -d',' -f2)
 RECIVED+="$(echo ${line}|cut -d',' -f3)+"
 SEND+="$(echo ${line}|cut -d',' -f4)+"
 DATESEC=$(date +%s --date="$(echo ${line}|cut -d',' -f5|cut -d' ' -f1,2,3,4)")
 TIMEON="$(($(date +%s)-${DATESEC}))"
  MIN=$(($TIMEON/60)) && SEC=$(($TIMEON-$MIN*60)) && HOR=$(($MIN/60)) && MIN=$(($MIN-$HOR*60))
  HOUR+="${HOR}h:${MIN}m:${SEC}s\n"
  let i++
 done <<< "$(sed -n "/^${user},/p" /etc/openvpn/openvpn-status.log)"
RECIVED=$(echo $(echo ${RECIVED}0|bc)|byte)
SEND=$(echo $(echo ${SEND}0|bc)|byte)
HOUR=$(echo -e $HOUR|sort -n|tail -1)
echo -e "$user|$i|$RECIVED|$SEND|$HOUR"
done
}
err_fun () {
     case $1 in
     1)echo -e "${cor[1]} Usuario Vacio"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     2)echo -e "${cor[1]} Usuario Con Nombre Muy Corto"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     3)echo -e "${cor[1]} Usuario Con Nombre Muy Grande"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     4)echo -e "${cor[1]} Contrasena Vacia"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     5)echo -e "${cor[1]} Contraseña Muy Corta"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     6)echo -e "${cor[1]} Contraseña Muy Grande"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     7)echo -e "${cor[1]} Duracion Vacia"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     8)echo -e "${cor[1]} Duracion invalida use numeros"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     9)echo -e "${cor[1]} Duracion Maxima es de un año"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     11)echo -e "${cor[1]} Limite Vacio"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     12)echo -e "${cor[1]} Limite invalido use numeros"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     13)echo -e "${cor[1]} Limite maximo es de 999"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     14)echo -e "${cor[1]} Usuario Ya Existe"; sleep 2s; tput cuu1; tput dl1; tput cuu1; tput dl1;;
     esac
}
new_user () {
usuarios_ativos=($(mostrar_usuarios))
if [[ -z ${usuarios_ativos[@]} ]]; then
echo -e "\033[1;33m Ningun  Usuario Creado"
else
echo -e "\033[1;32m Usuarios Actualmente Activos"
for us in $(echo ${usuarios_ativos[@]}); do
echo -ne "User: " && echo "${us}"
done
fi
while true; do
     echo -ne "\033[1;32m Nombre de Usuario:\033[1;37m";read nomeuser
     nomeuser="$(echo $nomeuser|sed -e 's/[^a-z0-9 -]//ig')"
     if [[ -z $nomeuser ]]; then
     err_fun 1 && continue
     elif [[ "${#nomeuser}" -lt "4" ]]; then
     err_fun 2 && continue
     elif [[ "${#nomeuser}" -gt "24" ]]; then
     err_fun 3 && continue
     elif [[ "$(echo ${usuarios_ativos[@]}|grep -w "$nomeuser")" ]]; then
     err_fun 14 && continue
     fi
     break
done
while true; do
     echo -ne "\033[1;32m Contraseña Nuevo Usuario:\033[1;37m";read  senhauser
     if [[ -z $senhauser ]]; then
     err_fun 4 && continue
     elif [[ "${#senhauser}" -lt "6" ]]; then
     err_fun 5 && continue
     elif [[ "${#senhauser}" -gt "20" ]]; then
     err_fun 6 && continue
     fi
     break
done
while true; do
     echo -ne "\033[1;32m TIEMPO DE DURACION:\033[1;37m";read diasuser
     if [[ -z "$diasuser" ]]; then
     err_fun 7 && continue
     elif [[ "$diasuser" != +([0-9]) ]]; then
     err_fun 8 && continue
     elif [[ "$diasuser" -gt "360" ]]; then
     err_fun 9 && continue
     fi 
     break
done
while true; do
     echo -ne "\033[1;32mLimite de Conexion:\033[1;37m";read limiteuser
     if [[ -z "$limiteuser" ]]; then
     err_fun 11 && continue
     elif [[ "$limiteuser" != +([0-9]) ]]; then
     err_fun 12 && continue
     elif [[ "$limiteuser" -gt "999" ]]; then
     err_fun 13 && continue
     fi
     break
done
     tput cuu1 && tput dl1
     tput cuu1 && tput dl1
     tput cuu1 && tput dl1
     tput cuu1 && tput dl1
     echo -e "${cor[2]} °\033[1;37m IP:\033[1;32m$__IP"
echo -e "${cor[2]} °\033[1;37m Nombre De usuario:\033[1;32m$nomeuser"
echo -e "${cor[2]} °\033[1;37m Contrasena:\033[1;32m$senhauser"
echo -e "${cor[2]} °\033[1;37m Limite:\033[1;32m$limiteuser"
echo -e "${cor[2]} °\033[1;37m Vence el dia:\033[1;32m$diasuser"
mine_port
add_user "${nomeuser}" "${senhauser}" "${diasuser}" "${limiteuser}" && echo -e "Usuario Criado Com Sucesso" || echo -e "Erro, Usuario nao criado"
[[ $(dpkg --get-selections|grep -w "openvpn"|head -1) ]] && [[ -e /etc/openvpn/openvpn-status.log ]] && newclient "$nomeuser" "$senhauser"
}
remove_user () {
usuarios_ativos=($(mostrar_usuarios))
if [[ -z ${usuarios_ativos[@]} ]]; then
echo -e "\033[1;33m Ningun Usuario Creado $fin"
return 1
else
echo -e "\033[1;32m Usuarios Actualmente Activos $fin"
i=0
for us in $(echo ${usuarios_ativos[@]}); do
echo -ne "[$i] ->" && echo -e "\033[1;33m ${us}"
let i++
done
fi
echo -e "\033[1;33m Escriba o Seleccione Un Usuario"
unset selection
while [[ -z ${selection} ]]; do
echo -ne "\033[1;37mSelecione A Opcao: " && read selection
tput cuu1 && tput dl1
done
if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
usuario_del="${usuarios_ativos[$selection]}"
else
usuario_del="$selection"
fi
[[ -z $usuario_del ]] && {
     echo -e "\033[1;31m Error, Usuario Invalido"
     return 1
     }
[[ ! $(echo ${usuarios_ativos[@]}|grep -w "$usuario_del") ]] && {
     echo -e "\033[1;37m Error, Usuario Invalido"
     return 1
     }
echo -e "Usuario Selecionado:"  && echo -ne "$usuario_del"
rm_user "$usuario_del" && echo -e "Removido]" || echo -e "Nao Removido]"
}
renew_user () {
usuarios_ativos=($(mostrar_usuarios))
if [[ -z ${usuarios_ativos[@]} ]]; then
echo -e "\033[1;33m Ningun  Usuario Creado $fin"
return 1
else
echo -e "\033[1;32m Usuarios Actualmente Activos $fin"
i=0
for us in $(echo ${usuarios_ativos[@]}); do
echo -ne "[$i] ->" && echo -e "\033[1;33m ${us}"
let i++
done
fi
echo -e "\033[1;33m Escriba o Seleccione un Usuario $fin"
unset selection
while [[ -z ${selection} ]]; do
echo -ne "\033[1;33m Seleccione Una Opción: " && read selection
tput cuu1
tput dl1
done
if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
useredit="${usuarios_ativos[$selection]}"
else
useredit="$selection"
fi
[[ -z $useredit ]] && {
     echo -e "\033[1;31m Error, Usuario Invalido"
     return 1
     }
[[ ! $(echo ${usuarios_ativos[@]}|grep -w "$useredit") ]] && {
     echo -e "Erro, Usuario Invalido"
     return 1
     }
while true; do
     echo -ne "\033[1;33m Nuevo Tiempo de Duracion de: $useredit"
     read -p ": " diasuser
     if [[ -z "$diasuser" ]]; then
     echo -e '\n\n\n'
     err_fun 7 && continue
     elif [[ "$diasuser" != +([0-9]) ]]; then
     echo -e '\n\n\n'
     err_fun 8 && continue
     elif [[ "$diasuser" -gt "360" ]]; then
     echo -e '\n\n\n'
     err_fun 9 && continue
     fi
     break
done
renew_user_fun "${useredit}" "${diasuser}" && echo -e "Usuario Modificado Com Sucesso" || echo -e "Erro, Usuario nao Modificado"
}
edit_user () {
usuarios_ativos=($(mostrar_usuarios))
if [[ -z ${usuarios_ativos[@]} ]]; then
echo -e "\033[1;33m Ningun Usuario Creado $fin"
return 1
else
echo -e "\033[1;32m Usuarios Atualmente Ativos no Servidor"
i=0
for us in $(echo ${usuarios_ativos[@]}); do
echo -ne "[$i] ->" && echo -e "\033[1;33m ${us}"
let i++
done
fi
echo -e "\033[1;33m Escriba o Seleccione un Usuario $fin"
unset selection
while [[ -z ${selection} ]]; do
echo -ne "\033[1;37m Seleccione Una Opción: " && read selection
tput cuu1; tput dl1
done
if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
useredit="${usuarios_ativos[$selection]}"
else
useredit="$selection"
fi
[[ -z $useredit ]] && {
     echo -e "\033[1;37m Error, Usuario Invalido $fin"
     return 1
     }
[[ ! $(echo ${usuarios_ativos[@]}|grep -w "$useredit") ]] && {
     echo -e "Erro, Usuario Invalido"
     return 1
     }
while true; do
echo -e "Usuario Selecionado: " && echo -e "$useredit"
     echo -e "Nova Senha de: $useredit"
     read -p ": " senhauser
     if [[ -z "$senhauser" ]]; then
     err_fun 4 && continue
     elif [[ "${#senhauser}" -lt "6" ]]; then
     err_fun 5 && continue
     elif [[ "${#senhauser}" -gt "20" ]]; then
     err_fun 6 && continue
     fi
     break
done
while true; do
     echo -e "\033[1;33m Dias de Duracion de: $useredit $fin"
     read -p ": " diasuser
     if [[ -z "$diasuser" ]]; then
     err_fun 7 && continue
     elif [[ "$diasuser" != +([0-9]) ]]; then
     err_fun 8 && continue
     elif [[ "$diasuser" -gt "360" ]]; then
     err_fun 9 && continue
     fi
     break
done
while true; do
     echo -e "\033[1;32m Nuevo Limite de Conexion de: $useredit $fin"
     read -p ": " limiteuser
     if [[ -z "$limiteuser" ]]; then
     err_fun 11 && continue
     elif [[ "$limiteuser" != +([0-9]) ]]; then
     err_fun 12 && continue
     elif [[ "$limiteuser" -gt "999" ]]; then
     err_fun 13 && continue
     fi
     break
done
     tput cuu1 && tput dl1
     tput cuu1 && tput dl1
     tput cuu1 && tput dl1
     tput cuu1 && tput dl1
     echo -e "Usuario: " && echo -e "$useredit"
     echo -e "Senha: " && echo -e "$senhauser"
     echo -e "Dias de Duracao: " && echo -e "$diasuser"
     echo -e "Data de Expiracao: " && echo -e "$(date "+%F" -d " + $diasuser days")"
     echo -e "Limite de Conexao: " && echo -e "$limiteuser"
edit_user_fun "${useredit}" "${senhauser}" "${diasuser}" "${limiteuser}" && echo -e "Usuario Modificado Com Sucesso" || echo -e "Erro, Usuario nao Modificado"
msg -bar
}
detail_user () {
red=$(tput setaf 1)
gren=$(tput setaf 2)
yellow=$(tput setaf 3)
if [[ ! -e "${USRdatabase}" ]]; then
echo -e "Nao Foi Identificado uma Database Com Usuarios"
echo -e "Os Usuarios a Seguir Nao Contem Nenhuma Informacao"
fi
txtvar=$(printf '%-16s' "USER")
txtvar+=$(printf '%-16s' "PASS")
txtvar+=$(printf '%-16s' "DATE")
txtvar+=$(printf '%-6s' "LIMIT")
echo -e "\033[1;33m${txtvar}"
VPSsec=$(date +%s)
while read user; do
unset txtvar
data_user=$(chage -l "$user" |grep -i co |awk -F ":" '{print $2}')
txtvar=$(printf '%-21s' "${yellow}$user")
if [[ -e "${USRdatabase}" ]]; then
  if [[ $(cat ${USRdatabase}|grep -w "${user}") ]]; then
    txtvar+="$(printf '%-21s' "${yellow}$(cat ${USRdatabase}|grep -w "${user}"|cut -d'|' -f2)")"
    DateExp="$(cat ${USRdatabase}|grep -w "${user}"|cut -d'|' -f3)"
    DataSec=$(date +%s --date="$DateExp")
    if [[ "$VPSsec" -gt "$DataSec" ]]; then    
    EXPTIME="${red}[Exp]"
    else
    EXPTIME="${gren}[$(($(($DataSec - $VPSsec)) / 86400))]"
    fi
    txtvar+="$(printf '%-26s' "${yellow}${DateExp}${EXPTIME}")"
    txtvar+="$(printf '%-11s' "${yellow}$(cat ${USRdatabase}|grep -w "${user}"|cut -d'|' -f4)")"
    else
    txtvar+="$(printf '%-21s' "${red}???")"
    txtvar+="$(printf '%-21s' "${red}???")"
    txtvar+="$(printf '%-11s' "${red}???")"
  fi
fi
echo -e "$txtvar"
done <<< "$(mostrar_usuarios)"
}
monit_user () {
yellow=$(tput setaf 3)
gren=$(tput setaf 2)
echo -e "Monitor de Conexoes de Usuarios"
txtvar=$(printf '%-13s' "USER")
txtvar+=$(printf '%-19s' "CONNECTION")
txtvar+=$(printf '%-16s' "TIME/ON")
echo -e "\033[1;33m${txtvar}"
while read user; do
 _=$(
PID="0+"
[[ $(dpkg --get-selections|grep -w "openssh"|head -1) ]] && PID+="$(ps aux|grep -v grep|grep sshd|grep -w "$user"|grep -v root|wc -l)+"
[[ $(dpkg --get-selections|grep -w "dropbear"|head -1) ]] && PID+="$(dropbear_pids|grep -w "${user}"|wc -l)+"
[[ $(dpkg --get-selections|grep -w "openvpn"|head -1) ]] && [[ -e /etc/openvpn/openvpn-status.log ]] && [[ $(openvpn_pids|grep -w "$user"|cut -d'|' -f2) ]] && PID+="$(openvpn_pids|grep -w "$user"|cut -d'|' -f2)+"
PID+="0"
TIMEON="${TIMEUS[$user]}"
[[ -z $TIMEON ]] && TIMEON=0
MIN=$(($TIMEON/60))
SEC=$(($TIMEON-$MIN*60))
HOR=$(($MIN/60))
MIN=$(($MIN-$HOR*60))
HOUR="${HOR}h:${MIN}m:${SEC}s"
[[ -z $(cat ${USRdatabase}|grep -w "${user}") ]] && MAXUSER="?" || MAXUSER="$(cat ${USRdatabase}|grep -w "${user}"|cut -d'|' -f4)"
[[ $(echo $PID|bc) -gt 0 ]] && user="$user [\033[1;32mON\033[0m${yellow}]" || user="$user [\033[1;31mOFF\033[0m${yellow}]"
TOTALPID="$(echo $PID|bc)/$MAXUSER"
 while [[ ${#user} -lt 45 ]]; do
 user=$user" "
 done
 while [[ ${#TOTALPID} -lt 13 ]]; do
 TOTALPID=$TOTALPID" "
 done
 while [[ ${#HOUR} -lt 8 ]]; do
 HOUR=$HOUR" "
 done
echo -e "${yellow}$user $TOTALPID $HOUR" >&2
) &
pid=$!
sleep 0.5s
done <<< "$(mostrar_usuarios)"
while [[ -d /proc/$pid ]]; do
sleep 1s
done
}
rm_vencidos () {
red=$(tput setaf 1)
gren=$(tput setaf 2)
yellow=$(tput setaf 3)
txtvar=$(printf '%-25s' "USER")
txtvar+=$(printf '%-20s' "VALID")
echo -e "\033[1;33m${txtvar}"
expired="${red}Expirado"
valid="${gren}Usuario Valido"
never="${yellow}Usuario Ilimitado"
removido="${red}Removido"
DataVPS=$(date +%s)
while read user; do
DataUser=$(chage -l "${user}" |grep -i co|awk -F ":" '{print $2}')
usr=$user
 while [[ ${#usr} -lt 20 ]]; do
 usr=$usr" "
 done
[[ "$DataUser" = " never" ]] && {
   echo -e "${yellow}$usr $never"
   continue
   }
DataSEC=$(date +%s --date="$DataUser")
if [[ "$DataSEC" -lt "$DataVPS" ]]; then
echo -ne "${yellow}$usr $expired"
rm_user "$user" && echo -e "($removido)"
else
echo -e "${yellow}$usr $valid"
fi
done <<< "$(mostrar_usuarios)"
msg -bar
}
verif_fun () {
# DECLARANDO VARIAVEIS PRIMARIAS
    local conexao
    local limite
    local TIMEUS
    declare -A conexao
    declare -A limite
    declare -A TIMEUS
    local LIMITERLOG="${SCPusr}/Limiter.log"
    [[ $(dpkg --get-selections|grep -w "openssh"|head -1) ]] && local SSH=ON || local SSH=OFF
    [[ $(dpkg --get-selections|grep -w "dropbear"|head -1) ]] && local DROP=ON || local DROP=OFF
    [[ $(dpkg --get-selections|grep -w "openvpn"|head -1) ]] && [[ -e /etc/openvpn/openvpn-status.log ]] && local OPEN=ON || local OPEN=OFF
    while true; do
    unset EXPIRED
    unset ONLINES
    [[ -e ${MyTIME} ]] && source ${MyTIME}
    local TimeNOW=$(date +%s)
    # INICIA VERIFICA��O
    while read user; do
           echo -ne "\033[1;33mUSUARIO: \033[1;32m$user "
           if [[ ! $(echo $(mostrar_usuarios)|grep -w "$user") ]]; then
              echo -e "\033[1;31mNAO EXISTE"
              continue
           fi
           local DataUser=$(chage -l "${user}" |grep -i co|awk -F ":" '{print $2}')
           if [[ ! -z "$(echo $DataUser|grep never)" ]]; then
               echo -e "\033[1;31mILIMITADO" 
               continue
           fi
           local DataSEC=$(date +%s --date="$DataUser")
           if [[ "$DataSEC" -lt "$TimeNOW" ]]; then
              EXPIRED="1+"          
              block_userfun $user -loked && echo "USER: $user (LOKED - EXPIRED) $(date +%r)" >> $LIMITERLOG
              echo -e "\033[1;31m EXPIRADO"
              continue
           fi
           local PID="0+"
           [[ $SSH = ON  ]] && PID+="$(ps aux|grep -v grep|grep sshd|grep -w "$user"|grep -v root|wc -l 2>/dev/null)+"
           [[ $DROP = ON  ]] && PID+="$(dropbear_pids|grep -w "$user"|wc -l 2>/dev/null)+"
           [[ $OPEN = ON  ]] && [[ $(openvpn_pids|grep -w "$user"|cut -d'|' -f2) ]] && PID+="$(openvpn_pids|grep -w "$user"|cut -d'|' -f2)+"
           local ONLINES+="$(echo ${PID}0|bc)+"
           local conexao[$user]="$(echo ${PID}0|bc)"
            if [[ ${conexao[$user]} -gt '0' ]]; then #CONTADOR DE TEMPO ONLINE
              [[ -z "${TIMEUS[$user]}" ]] && local TIMEUS[$user]=0
              [[ "${TIMEUS[$user]}" != +([0-9]) ]] && local TIMEUS[$user]=0
              local TIMEUS[$user]="$((2+${TIMEUS[$user]}))"
              local VARS="$(cat ${MyTIME}|grep -w -v "$user")"
              echo "TIMEUS[$user]='${TIMEUS[$user]}'" > ${MyTIME}
              for variavel in $(echo ${VARS}); do echo "${variavel}" >> ${MyTIME}; done
            fi           
           local limite[$user]="$(cat ${USRdatabase}|grep -w "${user}"|cut -d'|' -f4)"
           [[ -z "${limite[$user]}" ]] && continue
           [[ "${limite[$user]}" != +([0-9]) ]] && continue
           if [[ "${conexao[$user]}" -gt "${limite[$user]}" ]]; then
           local lock=$(block_userfun $user -loked)
           echo "$lock" >> $LIMITERLOG
           echo -e "\033[1;31m ULTRAPASSOU LIMITE"
           continue
           fi
           echo -e "\033[1;33m OK! \033[1;31m${conexao[$user]} CONEXOES"
    done <<< "$(mostrar_usuarios)"
    echo "${ONLINES}0"|bc > ${SCPdir}/USRonlines
    echo "${EXPIRED}0"|bc > ${SCPdir}/USRexpired
    sleep 2s # TEMPO DE ESPERA DO LOOP
    clear
    done
}
backup_fun () {
msg -ama "$(fun_trans "FERRAMENTA DE BACKUP DE USUARIOS")"
msg -bar
menu_func "CRIAR BACKUP" "RESTAURAR BACKUP"
msg -bar
unset selection
while [[ ${selection} != @([1-2]) ]]; do
echo -ne "\033[1;37m$(fun_trans "Selecione A Opcao"): " && read selection
tput cuu1 && tput dl1
done
case ${selection} in
1)
cp ${USRdatabase} $HOME/Backup-adm
msg -azu "$(fun_trans "Procedimento Feito")"
echo -e "\033[1;31mBACKUP > [\033[1;32m$HOME/Backup-adm\033[1;31m]"
;;
2)
while [[ ! -e ${dirbackup} ]]; do
echo -ne "\033[1;37m$(fun_trans "Digite o Local Do Backup"): " && read dirbackup
tput cuu1 && tput dl1
done
VPSsec=$(date +%s)
while read line; do
nome=$(echo ${line}|cut -d'|' -f1)
[[ $(echo $(mostrar_usuarios)|grep -w "$nome") ]] && {
  msg -verm "$nome [ERROR]"
  continue
  }
senha=$(echo ${line}|cut -d'|' -f2)
DateExp=$(echo ${line}|cut -d'|' -f3)
DataSec=$(date +%s --date="$DateExp")
[[ "$VPSsec" -lt "$DataSec" ]] && dias="$(($(($DataSec - $VPSsec)) / 86400))" || dias="30"
limite=$(echo ${line}|cut -d'|' -f4)
add_user "$nome" "$senha" "$dias" "$limite" && msg -verd "$nome [OK]" || msg -verm "$nome [ERROR]"
done < ${dirbackup}
;;
esac
msg -bar
}
verif_funx () {
PIDVRF="$(ps aux|grep "${SCPusr}/usercodes verificar"|grep -v grep|awk '{print $2}')"
if [[ -z $PIDVRF ]]; then
cd ${SCPusr}
screen -dmS very ${SCPusr}/usercodes verificar
else
for pid in $(echo $PIDVRF); do
kill -9 $pid &>/dev/null
done
[[ -e ${SCPdir}/USRonlines ]] && rm ${SCPdir}/USRonlines
[[ -e ${SCPdir}/USRexpired ]] && rm ${SCPdir}/USRexpired
fi
}
baner_fun () {
b="\033[1;37m"
v="\033[1;32m"
Ver="\033[1;36m"
m="\033[0;34m"
mv -f /tmp/ssh-conf /etc/ssh/sshd_config
echo "Banner /etc/bannerssh" >> /etc/ssh/sshd_config
local="/etc/bannerssh"
clear
echo -e "\E[47;1;31m  BIENVENIDOS CREADOR DE BANNER VPS-BARBA\033[0m \E[0m"
echo -ne "\033[1;33mCUAL ES SU MENSAJE \033[1;32m --->>\033[1;37m : "; read ban_ner
echo -e " \033[1;32m[1] >\033[1;32m VERDE"
echo -e " \033[1;32m[2] >\033[1;31m ROJO"
echo -e " \033[1;32m[3] >\033[1;34m AZUL"
echo -e " \033[1;32m[4] >\033[1;33m AMARILLO"
echo -e " \033[1;32m[5] >\033[1;35m PURPURA"
echo -e " \033[1;32m[6] >\033[1;37m ROSA"
echo -ne "\033[1;33mELIJA UN COLOR \033[1;32m --->>\033[1;37m : "; read ban_ner_cor
echo '<h1><font>=============================</font></h1>' > $local
if [[ "$ban_ner_cor" = "1" ]]; then
echo '<h1><font color="green">' >> $local
elif [[ "$ban_ner_cor" = "2" ]]; then
echo '<h1><font color="red">' >> $local
elif [[ "$ban_ner_cor" = "3" ]]; then
echo '<h1><font color="blue">' >> $local
elif [[ "$ban_ner_cor" = "4" ]]; then
echo '<h1><font color="yellow">' >> $local
elif [[ "$ban_ner_cor" = "5" ]]; then
echo '<h1><font color="purple">' >> $local
elif [[ "$ban_ner_cor" = "6" ]]; then
echo '<h1><font color="pink">' >> $local
else
echo '<h1><font color="blue">' >> $local
fi
echo "$ban_ner" >> $local
echo '</font></h1>' >> $local
echo '<h1><font>=============================</font></h1>' >> $local
txt_font () {
echo -ne  "\033[1;33mESCRIBA SU SIGUIENTE MENSAJE: " && read ban_ner2
echo -e " \033[1;32m[1] >\033[1;32m VERDE"
echo -e " \033[1;32m[2] >\033[1;31m ROJO"
echo -e " \033[1;32m[3] >\033[1;34m AZUL"
echo -e " \033[1;32m[4] >\033[1;33m AMARILLO"
echo -e " \033[1;32m[5] >\033[1;35m ROJO"
echo -e " \033[1;32m[6] >\033[1;37m ROSA"
echo -ne "\033[1;33mELIJA UN COLOR: " && read ban_ner2_cor
if [ "$ban_ner2_cor" = "1" ]; then
echo '<h6><font color="green">' >> $local
elif [ "$ban_ner2_cor" = "2" ]; then
echo '<h6><font color="red">' >> $local
elif [ "$ban_ner2_cor" = "3" ]; then
echo '<h6><font color="blue">' >> $local
elif [ "$ban_ner2_cor" = "4" ]; then
echo '<h6><font color="yellow">' >> $local
elif [ "$ban_ner2_cor" = "5" ]; then
echo '<h6><font color="purple">' >> $local
elif [[ "$ban_ner_cor" = "6" ]]; then
echo '<h1><font color="pink">' >> $local
else
echo '<h6><font color="red">' >> $local
fi
echo "$ban_ner2" >> $local
echo "</h6></font>" >> $local
}
while true; do
echo -ne "\033[1;36mAGREGAR OTRO MENSAJE? [S/N]: " && read sin_nao
if [[ "$sin_nao" = @(s|S|y|Y) ]]; then
txt_font
elif [[ "$sin_nao" = @(n|N) ]]; then
break
fi
done
echo '</h8><font color="red">vps-barba</font></h8>' >> $local
#echo '<h1><font>=============================</font></h1>' >> $local
if [[ -e "$local2" ]]; then
rm $local2  > /dev/null 2>&1
cp $local $local2 > /dev/null 2>&1
fi
echo -e "\E[47;1;31m  MENSAJE CREADO CON EXITO\E[0m"
service ssh restart > /dev/null 2>&1 &
service sshd restart > /dev/null 2>&1 &
service dropbear restart > /dev/null 2>&1 &
}



# Execução
if [[ "$1" = "verificar" ]]; then
verif_fun
exit
fi
[[ -z ${VERY} ]] && verificar="\033[1;31m[Off]" || verificar="\033[1;32m[On]"
echo -e "${cor[3]} MENU DE USUARIOS ${cor[2]}  VPS-BARBA"
echo -e "$barra"
echo -e "\033[1;31m[\033[91;32m01\033[1;31m]\033[1;36m CRIAR NOVO USUARIO\033[0m"
echo -e "\033[1;31m[\033[91;32m02\033[1;31m]\033[1;36m REMOVER USUARIO\033[0m"
echo -e "\033[1;31m[\033[91;32m03\033[1;31m]\033[1;36m BLOQUEAR OU DESBLOQUEAR USUARIO\033[0m"
echo -e "\033[1;31m[\033[91;32m04\033[1;31m]\033[1;36m EDITAR USUARIO\033[0m"
echo -e "\033[1;31m[\033[91;32m05\033[1;31m]\033[1;36m RENOVAR USUARIO\033[0m"
echo -e "\033[1;31m[\033[91;32m06\033[1;31m]\033[1;36m DETALHES DE TODOS USUARIOS\033[0m"
echo -e "\033[1;31m[\033[91;32m07\033[1;31m]\033[1;36m MONITORAR USUARIOS CONECTADOS\033[0m"
echo -e "\033[1;31m[\033[91;32m08\033[1;31m]\033[1;36m ELIMINAR USUARIOS EXPIRADOS\033[0m"
echo -e "\033[1;31m[\033[91;32m09\033[1;31m]\033[1;36m BACKUP USUARIOS\033[0m"
echo -e "\033[1;31m[\033[91;32m10\033[1;31m]\033[1;36m BAN_NER SSH\033[0m"
echo -e "\033[1;31m[\033[91;32m11\033[1;31m]\033[1;36m VERIFICACOES ${verificar}"; [[ -e ${SCPusr}/Limiter.log ]] && echo -ne " [12]  VER LOG DO LIMITER"
echo -e "\033[1;31m[\033[91;32m00\033[1;31m]\033[1;36m VOLTAR*"
echo -e "$barra"
echo -ne "\033[1;32m OPCION: \033[1;37m" ; read _selecao
case $_selecao in
0)exit ;;
1)new_user;;
2)remove_user;;
3)block_user;;
4)edit_user;;
5)renew_user;;
6)detail_user;;
7)monit_user;;
8)rm_vencidos;;
9)backup_fun;;
10)baner_fun;;
11)verif_funx;;
12)
[[ -e "${SCPusr}/Limiter.log" ]] && {
 cat ${SCPusr}/Limiter.log
 }
;;
esac
