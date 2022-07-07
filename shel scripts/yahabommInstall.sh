#!/bin/bash
# -*- ENCODING: UTF-8 -*-
##
## For Log2RAM customising see this - https://github.com/azlux/log2ram
##
## Do not access this script as SUDO.
##
## ROUTINES
## Here at the beginning, a load of useful routines - see further down

# High Intensity
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIPurple='\e[1;95m'     # Purple
BIMagenta='\e[1;95m'    # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White
cancel=0;

#Array to store possible locations for temp read.
aFP_TEMPERATURE=(
'/sys/class/thermal/thermal_zone0/temp'
'/sys/devices/platform/sunxi-i2c.0/i2c-0/0-0034/temp1_input'
'/sys/class/hwmon/hwmon0/device/temp_label'
)
Obtain_Cpu_Temp(){
  for ((i=0; i<${#aFP_TEMPERATURE[@]}; i++)) do
    if [ -f "${aFP_TEMPERATURE[$i]}" ]; then
      CPU_TEMP_CURRENT=$(cat "${aFP_TEMPERATURE[$i]}")
      # - Some devices (pine) provide 2 digit output, some provide a 5 digit ouput.
      #       So, If the value is over 1000, we can assume it needs converting to 1'c
      if (( $CPU_TEMP_CURRENT >= 1000 )); then
        CPU_TEMP_CURRENT=$( echo -e "$CPU_TEMP_CURRENT" | awk '{print $1/1000}' | xargs printf "%0.0f" )
      fi
      if (( $CPU_TEMP_CURRENT >= 70 )); then
        CPU_TEMP_PRINT="\e[91mWarning: $CPU_TEMP_CURRENT'c\e[0m"
      elif (( $CPU_TEMP_CURRENT >= 60 )); then
        CPU_TEMP_PRINT="\e[38;5;202m$CPU_TEMP_CURRENT'c\e[0m"
      elif (( $CPU_TEMP_CURRENT >= 50 )); then
        CPU_TEMP_PRINT="\e[93m$CPU_TEMP_CURRENT'c\e[0m"
      elif (( $CPU_TEMP_CURRENT >= 40 )); then
        CPU_TEMP_PRINT="\e[92m$CPU_TEMP_CURRENT'c\e[0m"
      elif (( $CPU_TEMP_CURRENT >= 30 )); then
        CPU_TEMP_PRINT="\e[96m$CPU_TEMP_CURRENT'c\e[0m"
      else
        CPU_TEMP_PRINT="\e[96m$CPU_TEMP_CURRENT'c\e[0m"
      fi
      break
    fi
  done
}

LOGFILE=$HOME/$0-`date +%Y-%m-%d_%Hh%Mm`.log
AQUIET="-qq"
NQUIET="-s"
BPIMODEL=$(sudo cat /proc/device-tree/model | sed -e 's/[^A-Za-z0-9._-]//g')
# Another way - Xenial should come up in upper case in $DISTRO
. /etc/os-release
OPSYS=${ID^^}
#echo $OPSYS
ACTIVECORES=$(grep -c processor /proc/cpuinfo)
printl() {
  printf $1
  echo -e $1 >> $LOGFILE
}

printstatus() {
  Obtain_Cpu_Temp
  h=$(($SECONDS/3600));
  m=$((($SECONDS/60)%60));
  s=$(($SECONDS%60));
  printf "\r\n${BIGreen}==\r\n== ${BIYellow}$1"
  printf "\r\n${BIGreen}== ${IBlue}Total: %02dh:%02dm:%02ds Cores: $ACTIVECORES Temperature: $CPU_TEMP_PRINT \r\n${BIGreen}==${IWhite}\r\n\r\n"  $h $m $s;
  echo -e "############################################################" >> $LOGFILE
  echo -e $1 >> $LOGFILE
}

#Array to store possible valid models.
validModels=(
'sun8iw11p2'
'RaspberryPi3ModelBRev1.2'
'RaspberryPi4ModelBRev1.1'
)

validModel(){
  modelValid=0
  for model in "${validModels[@]}"; do
    #echo 'modelo valido |'$model'|' 
    #echo 
    #echo 'modelo escaneado |'$BPIMODEL'|'
    #sleep 4
    if [ $model == $BPIMODEL ]; then
      #echo 'modelo '$model 
      modelValid=1
      break
    fi 
  done 
  #echo 'validModel function returns '$modelValid
  #sleep 10
  echo $modelValid
}

yahaboomPython()
{
    printstatus "RGB Cooling HAT Python version"
    pyton_version=$(update-alternatives --list python);
    printstatus "Python version $pyton_version"
    #if [[ $pyton_version != "/usr/bin/python3"]]; then
    #    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10 >> $LOGFILE
    #fi 
    sudo apt-get $AQUIET -y  install libopenjp2-7 libtiff5 libatlas-base-dev >> $LOGFILE
    sudo apt-get $AQUIET -y  install i2c-tools python3-smbus python-dev >> $LOGFILE
    i2cInstalled=$( i2cdetect -F 1 | grep "I2C  " | awk -v FS=" " '{print $2}')
    #printf "\r\n${BIGreen}== ${IBlue}I2C enabled: $i2cInstalled ${IWhite}\r\n\r\n";
    if [[ $i2cInstalled != *"yes"* ]]; then 
      printstatus "Enabling 12c bus"
      # sleep 10
      sudo raspi-config #para habilitar i2c
    fi 
    python -m pip install -U pip setuptools wheel >> $LOGFILE
    pip install Adafruit-SSD1306 Pillow smbus >> $LOGFILE
    cd 
    if [ -d  "RGB_Cooling_HAT" ]; then
      rm -rf RGB_Cooling_HAT >> $LOGFILE
    fi 
    mkdir RGB_Cooling_HAT  #Crear directorio RGB_Cooling_HAT
    cd  ~/RGB_Cooling_HAT
    wget  -q https://github.com/YahboomTechnology/Raspberry-Pi-RGB-Cooling-HAT/raw/master/4.Python%20programming/RGB_Cooling_HAT.zip -a $LOGFILE
    unzip RGB_Cooling_HAT.zip >> $LOGFILE
    sed -i -e "s#pi#$USER#" install.sh
    sed -i -e "s#pi#$USER#" install.sh
    #echo "-----------install.sh---------------------"
    #cat install.sh
    #sleep 10
    chmod +x install.sh
    sudo ./install.sh >> $LOGFILE
    #echo "-----------------start.sh---------------"
    #cat start.sh 
    sed -i -e "s#pi#$USER#" start.sh 
    #echo "-----------------start.sh---------------"
    #cat start.sh 
    #sleep 5
    chmod +x start.sh

    cd /lib/systemd/system
    sudo rm RGB_Cooling_HAT.service | tee -a $LOGFILE
    sudo touch RGB_Cooling_HAT.service

    sudo echo "[Unit]" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "Description=Yahaboom RGB Cooling HAT python service" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "After=multi-user.target" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "[Service]" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "ExecStart=/home/$USER/RGB_Cooling_HAT/start.sh" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "User=$USER" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "[Install]" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    sudo echo "WantedBy=multi-user.target" | sudo tee -a RGB_Cooling_HAT.service > /dev/null 2>&1
    cd
    sudo systemctl daemon-reload
    #sudo systemctl enable RGB_Cooling_HAT.service 
    #cat /lib/systemd/system/RGB_Cooling_HAT.service
    #sleep 20
}
yahaboomCopt1()
{
    printstatus "RGB Cooling HAT Temperature control switch version"
    cd 
    if [ -d  "temp_control" ]; then
      rm -rf  temp_control > /dev/null 2>&1
    fi 
    mkdir temp_control > /dev/null 2>&1
    cd temp_control
    wget -q https://github.com/YahboomTechnology/Raspberry-Pi-RGB-Cooling-HAT/raw/master/3.C%20programming/1.Using_of_RGB_Cooling_HAT/1.Temperature_control_switch_version/temp_control.zip -a $LOGFILE
    unzip temp_control.zip >> $LOGFILE
    sed -i -e "s#pi#$USER#" install.sh
    sed -i -e "s#pi#$USER#" install.sh
    chmod +x install.sh
    sudo ./install.sh | tee -a $LOGFILE
    sed -i -e "s#pi#$USER#" start.sh
    chmod +x start.sh
    cd

    # creating service

    cd /lib/systemd/system
    sudo rm RGB_Cooling_HAT_C.service | tee -a $LOGFILE
    sudo touch RGB_Cooling_HAT_C.service | tee -a $LOGFILE

    sudo echo "[Unit]" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "Description=Yahaboom RGB Cooling HAT Temperature control switch version" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "After=multi-user.target" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "[Service]" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "ExecStart=/home/$USER/temp_control/start.sh" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "User=$USER" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "[Install]" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    sudo echo "WantedBy=multi-user.target" | sudo tee -a RGB_Cooling_HAT_C.service > /dev/null 2>&1
    cd
    sudo systemctl daemon-reload
    #sudo systemctl enable RGB_Cooling_HAT_C.service 
    #cat /lib/systemd/system/RGB_Cooling_HAT_C.service
    #sleep 20
}

yahaboomCopt2()
{
    cd 
    printstatus "RGB Cooling HAT Automatic temperature control version"
    if [ -d  "temp_control_1" ]; then
      rm -rf temp_control_1 > /dev/null 2>&1
    fi 
    mkdir temp_control_1 > /dev/null 2>&1
    cd temp_control_1
    wget  -q https://github.com/YahboomTechnology/Raspberry-Pi-RGB-Cooling-HAT/raw/master/3.C%20programming/1.Using_of_RGB_Cooling_HAT/2.Automatic_temperature_control_version/temp_control_1.zip -a $LOGFILE
    unzip temp_control_1.zip >> $LOGFILE
    sed -i -e "s#pi#$USER#" install_1.sh
    sed -i -e "s#pi#$USER#" install_1.sh
    chmod +x install_1.sh
    sudo ./install_1.sh | tee -a $LOGFILE
    sed -i -e "s#pi#$USER#" start_1.sh
    chmod +x start_1.sh
    cd

    # creating service

    cd /lib/systemd/system
    sudo rm RGB_Cooling_HAT_C_1.service | tee -a $LOGFILE
    sudo touch RGB_Cooling_HAT_C_1.service | tee -a $LOGFILE

    sudo echo "[Unit]" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "Description=Yahaboom RGB Cooling HAT Automatic temperature control version" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "After=multi-user.target" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "[Service]" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "ExecStart=/home/$USER/temp_control_1/start_1.sh" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "User=$USER" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "[Install]" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    sudo echo "WantedBy=multi-user.target" | sudo tee -a RGB_Cooling_HAT_C_1.service > /dev/null 2>&1
    cd
    sudo systemctl daemon-reload
    #sudo systemctl enable RGB_Cooling_HAT_C_1.service 
    #cat /lib/systemd/system/RGB_Cooling_HAT_C_1.service
    #sleep 20
}
if [[ $OPSYS == *"RASPBIAN"* ]]; then
    printstatus "O.S. detected $OPSYS. Model ${BPIMODEL}"
    if [ $(validModel) -eq 0 ] ; then
      echo -e "${IRed}!!!! Wrong model detected '${BPIMODEL}' Aborting!!! ${IWhite}\r\n"
      exit 0
    fi
fi


if [[ $USER == "root" ]]; then
    printf "\r\n${ICyan}Hello ROOT... ${IWhite}"
    printstatus "Leaving script as you are ROOT user."
    sleep 10
    exit
fi
printstatus "installing Yahaboom RGB Cooling HAT"
sleep 5 
printstatus "Grabbing some preliminaries..."

# test internet connection
if [[ "$(ping -c 1 23.1.68.60  | grep '100%' )" != "" ]]; then
  printl "${IRed}!!!! No internet connection available, aborting! ${IWhite}\r\n"
  exit 0
fi

printstatus "Installing pre-requisites (this could take some time)"
  sudo apt-get $AQUIET -y autoremove 2>&1 | tee -a $LOGFILE
  sudo apt-get $AQUIET  update 2>&1 | tee -a $LOGFILE
  sudo apt-get $AQUIET -y upgrade 2>&1 | tee -a $LOGFILE
  sudo apt-get install $AQUIET -y bash-completion unzip build-essential git python3-serial scons libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libsqlite3-dev subversion libcurl4-openssl-dev libusb-dev python-dev cmake curl telnet usbutils gawk jq pv samba samba-common samba-common-bin winbind dosfstools parted gcc python3-pip htop 2>&1 | tee -a $LOGFILE
  sudo pip -q install psutil 2>&1 | tee -a $LOGFILE
  #sudo pip -q install Adafruit-SSD1306 2>&1 | tee -a $LOGFILE
  sudo -H pip -q install feedparser 2>&1 | tee -a $LOGFILE
  installWiringPi="yes"
  if [ -d  ~/WiringPi ]; then
      if (whiptail --title "wiringPi" --yesno "~/wiringPi exists. overwrite it?" 8 78); then
        rmdir ~WiringPi > /dev/null 2>&1
        git clone https://github.com/WiringPi/WiringPi.git 2>&1 | tee -a $LOGFILE
      else
        #printl "${IRed}!!!! Wiringpi not installed! ${IWhite}\r\n"
        installWiringPi="no"
      fi
  else
        git clone https://github.com/WiringPi/WiringPi.git 2>&1 | tee -a $LOGFILE
  fi

  # if git fails or folder does not exist, abort+report
  if [ $? -eq 0 ] && [ -d WiringPi ] && [ $installWiringPi = "yes" ]; then
       cd ~/WiringPi
       ./build 2>&1 | tee -a $LOGFILE
  else
       printl "${IRed}!!!! Wiringpi not installed! ${IWhite}\r\n"
  fi
  
  MYMENUMISC=$(whiptail --title "Yahaboom RGB Cooling HAT installation" --radiolist \
        "\n Make your selections (SPACE) as required  then TAB to OK/Cancel" 13 80 5 \
        "python" "RGB Cooling HAT Python version" ON \
        "copt1" "RGB Cooling HAT Temperature control switch version" OFF \
        "copt2" "RGB Cooling HAT Automatic temperature control version" OFF \
        "all" "RGB Cooling HAT Automatic temperature control all versions" OFF 3>&1 1>&2 2>&3)
  printstatus "installing RGB Cooling HAT ${MYMENUMISC}"
  case $MYMENUMISC in
    python )
        yahaboomPython
    ;;
    copt1 )
        yahaboomCopt1
    ;;
    copt2 )
        yahaboomCopt2
    ;;
    all )
        yahaboomPython
        yahaboomCopt1
        yahaboomCopt2
    ;;
     "" )
    cancel=1;
  ;;
  esac
# activate service
if [ $cancel -eq 0 ]; then 
  MYMENUMISC=$(whiptail --title "Yahaboom RGB Cooling HAT service enabling" --radiolist \
        "\n Make your selections (SPACE) as required  then TAB to OK/Cancel" 13 80 4 \
        "python" "RGB Cooling HAT Python version" OFF \
        "copt1" "RGB Cooling HAT Temperature control switch version" OFF \
        "copt2" "RGB Cooling HAT Automatic temperature control version" ON \
        "disable" "Disable all RGB Cooling HAT services" OFF  3>&1 1>&2 2>&3)
  
  
  
  case $MYMENUMISC in
    disable )
        printstatus "Disabling RGB_Cooling_HAT services"
        sleep 10
        sudo service RGB_Cooling_HAT stop >> $LOGFILE
        sudo service RGB_Cooling_HAT_C stop >> $LOGFILE
        sudo service RGB_Cooling_HAT_C_1 stop >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT.service >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT_C.service >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT_C_1.service >> $LOGFILE
        sudo systemctl daemon-reload
    ;;
       python )
        printstatus "enabling RGB_Cooling_HAT.service"
        sleep 10
        sudo systemctl enable RGB_Cooling_HAT.service >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT_C.service >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT_C_1.service >> $LOGFILE
        sudo systemctl daemon-reload >> $LOGFILE 
        sudo service RGB_Cooling_HAT start  >> $LOGFILE
    ;;
    copt1 )
        printstatus "enabling RGB_Cooling_HAT_C.service"
        sleep 10
        sudo systemctl enable RGB_Cooling_HAT_C.service >> $LOGFILE 
        sudo systemctl disable RGB_Cooling_HAT.service >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT_C_1.service >> $LOGFILE
        sudo systemctl daemon-reload >> $LOGFILE
        sudo service RGB_Cooling_HAT_C start >> $LOGFILE
    ;;
    copt2 )
        printstatus "enabling RGB_Cooling_HAT_C_1.service"
        sleep 10
        sudo systemctl enable RGB_Cooling_HAT_C_1.service >> $LOGFILE 
        sudo systemctl disable RGB_Cooling_HAT_C.service >> $LOGFILE
        sudo systemctl disable RGB_Cooling_HAT.service >> $LOGFILE
        sudo systemctl daemon-reload >> $LOGFILE
        sudo service RGB_Cooling_HAT_C_1 start >> $LOGFILE
    ;;
  esac
fi
printstatus "All done."
#printf 'Current IP: %s  Hostname: %s\r\n' "$fixip" "$thehostname"
#echo -e Current IP: $fixip  Hostname: $thehostname >> $LOGFILE
printstatus  "ALL DONE - PLEASE REBOOT NOW THEN TEST"
cat $LOGFILE
rm $LOGFILE 