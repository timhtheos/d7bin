function parse_yaml(){
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
    -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
      printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
  }'
}

function stmsg(){
  strmsg="ABORTED"
  strspace="  "

  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  NORMAL=$(tput sgr0)

  strcolor=$RED

  if [ $1 = "ok" ]; then
    strmsg="OK"
    strspace="       "
    strcolor=$GREEN
  elif [ $1 = "cancelled" ]; then
    strmsg="CANCELLED"
    strspace=""
  elif [ $1 = "success" ]; then
    strmsg="SUCCESS"
    strspace="  "
    strcolor=$GREEN
  fi

  let COL=$(tput cols)-${#2}+${#strcolor}+${#NORMAL}
  printf "\n%s%${COL}s" "$2" "$strcolor[$strmsg]$NORMAL$strspace"
}
