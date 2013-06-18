function t {
  sh -e "RespectTest/usage_tests/$1"
  if [ "$?" = "0" ] ; then
    echo "$1 OK"
  else
    echo "$1 FAILED"
    exit 1
  fi
}

echo "Running usage tests:"
t help.sh
t error.sh
t cli.sh
t xcode.sh
t config.sh
t nodefault.sh
t dump.sh

