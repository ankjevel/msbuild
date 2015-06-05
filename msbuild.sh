#!/bin/bash
function msbuild() {
  vmInstallPath="/Applications/VMware Fusion.app"
  vm="${vmInstallPath}/Contents/Library/vmrun"
  fileRoot="$HOME/Documents/"
  vmImage="`"${vm}" list |grep \".vmx\"`"
  vmRoot="\\\\vmware-host\\Shared Folders\\Documents\\"
  vmFile="build.bat"
  vmLogFile="out.log"

  vmSolution=""
  password=""
  user=""
  buildT="/t:build"
  buildP="/property:Configuration=Debug"

  function help {
  cat <<EOF

  _           _ _     _
 | |__  _   _(_) | __| |
 |  _ \| | | | | |/ _  |
 | |_) | |_| | | | (_| |
 |_.__/ \__,_|_|_|\__,_|


usage: build [<args>]

Before running this script, be sure to share
your 'Documents' folder with the guest-vm

Logs will be pied to ${fileRoot}${vmLogFile}

args:
  p      Password for user
  u      User in vm image
  s      Solution file to build

  t      Build task [default: /t:build]
  p      Properties [default: /property:Configuration=Debug]

  h | ?  shows this help

EOF
  }

  while :; do
    printHelp=0
    OPTIND=1
    while getopts "p:u:s:t:p:?:h:" opt; do
      case "${opt}" in
        h|\?|help)
          printHelp=1
          break;
        ;;
        p) password=$OPTARG
        ;;
        u) user=$OPTARG
        ;;
        s) vmSolution="$OPTARG"
        ;;
        t) buildT="$OPTARG"
        ;;
        p) buildP="$OPTARG"
        ;;
      esac
    done

    if [ "$printHelp" == "1" ]; then
      help
      break;
    fi;

    # check host
    if [ -z "$vmImage" ]; then
      echo "host not running"
      break
    fi;

    # set user
    if [ -z "$user" ]; then
      echo -n "User:"
      read user
      if [ -z "$user" ]; then
        echo -n "no user"
        break
      fi;
    fi;

    # set password
    if [ -z "$password" ]; then
      echo -e "\n$user password:"
      read -s password
      if [ -z "$password" ]; then
        echo -n "no password"
        break
      fi;
    fi;

    if [ -z "$vmSolution" ]; then
      echo -e "\nsolution path (relative to ${fileRoot}): "
      read vmSolution
      if [ -z "$vmSolution" ]; then
        echo -n "plz, it gives solution path"
        break
      fi;
    fi;

    vmSolution=${vmSolution//${fileRoot}/}
    vmSolution="${vmSolution//\//\\}"

    # create files if not existing
    if [ ! -f "${fileRoot}${logFile}" ]; then
      `touch ${fileRoot}${logFile}`
    fi;

    # create file
    cat > ${fileRoot}${vmFile} <<EOL
c:\\
CALL "C:\Program Files (x86)\MSBuild\12.0\bin\MSBuild.exe" "${vmRoot}${vmSolution}" ${buildT} ${buildP} >> "${vmRoot}${vmLogFile}"
EOL

    if [[ ! "`cat \"${vmImage}\"`" =~ "$fileRoot" ]]; then
      echo "${fileRoot} not shared in ${vmImage}"
      break
    fi;

    # check if file exists, before running
    if [[ "`"${vm}" -gu \"${user}\" -gp \"${password}\" fileExistsInGuest \"${vmImage}\" \"${vmRoot}${vmFile}\"`" =~ "not" ]]; then
      echo "BAT (${vmRoot}${vmFile}) not in vm"
      break
    fi;

    if [[ "`"${vm}" -gu \"${user}\" -gp \"${password}\" fileExistsInGuest \"${vmImage}\" \"${vmRoot}${vmSolution}\"`" =~ "not" ]]; then
      echo "Solution (${vmRoot}${vmSolution}) not in vm"
      break
    fi;

    "${vm}" -gu ${user} -gp ${password} runScriptInGuest "${vmImage}" -noWait "" "cmd.exe /k \"${vmRoot}${vmFile}\""

    break

  done;
}
