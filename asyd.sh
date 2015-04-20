#!/bin/sh
name="${0}"
cmd="${1}"
PIDFile=".asyd.pid"

case ${cmd} in
  start)
  unicorn -c unicorn.conf.rb -D
  echo "ASYD Started"
  ;;
  stop)
  kill -3 $(<"$PIDFile")
  echo "ASYD Stopped"
  ;;
  restart)
  kill -3 $(<"$PIDFile")
  unicorn -c unicorn.conf.rb -D
  echo "ASYD Restarted"
  ;;
  *)
  echo "Usage: ${name} {start|stop|restart}"
  exit 1
  ;;
esac
