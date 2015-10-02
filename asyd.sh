#!/bin/sh

# EXIT CODES
# 0 - Script ran successfully
# 1 - Illegal or no arguments specified
# 2 - Failed to start the daemon
# 3 - Failed to kill the daemon
# 4 - Failed to restart the daemon
# 128+ - Amount of ASYD processes running (subtract 128 to get the real number)

self="$0"
cmd="$1"
pidfile=".asyd.pid"
stopmaxwaititerations=60 # 30 seconds (0.5 seconds per iteration)
killmaxwaititerations=10 # 5 seconds
stopwaititerationsleep=0.5
killwaititerationsleep=0.5

case "$cmd" in
    start)
        echo -n "Waiting for ASYD to start ..."
        unicorn -c unicorn.conf.rb -D
        pid=$(cat "$pidfile" 2> /dev/null)
        if ! kill -0 "$pid" 2> /dev/null; then
            echo " FAILED (daemon not running after start attempt)"
            exit 2
        fi
        echo " done"
        ;;
    stop)
        pid=$(cat "$pidfile" 2> /dev/null)
        if ! kill -0 "$pid" 2> /dev/null; then
            echo "ASYD not running"
            exit 0
        fi
        kill -3 "$pid" 2> /dev/null
        echo -n "Waiting for ASYD ($pid) to be stopped ..."
        i=0
        while kill -0 "$pid" 2> /dev/null && [ "$i" != "$stopmaxwaititerations" ]; do
            echo -n .
            i="$(($i+1))"
            sleep "$stopwaititerationsleep"
        done
        if kill -0 "$pid" 2> /dev/null; then
            echo " FAILED"
            # We failed to gracefully shut down ASYD so we need to forcefully kill it
            echo -n "Waiting for ASYD ($pid) to be killed ..."
            kill -9 "$pid" 2> /dev/null
            i=0
            while kill -0 "$pid" 2> /dev/null && [ "$i" != "$stopmaxwaititerations" ]; do
                echo -n .
                i="$(($i+1))"
                sleep "$killwaititerationsleep"
            done
            if kill -0 "$pid" 2> /dev/null; then
                echo " FAILED"
                # We failed to forcefully kill ASYD, something is horribly wrong and the process is not dying!
                exit 3
            fi
        fi
        echo " done"
        ;;
    restart)
        sh "$self" stop && sh "$self" start || exit 4
        ;;
    pid)
        pid=$(cat "$pidfile" 2> /dev/null)
        echo "$pid"
        ;;
    status)
        echo -n "ASYD is "
        pid=$(cat "$pidfile" 2> /dev/null)
        kill -0 "$pid" 2> /dev/null && echo "running" || echo "stopped"
        ;;
    count)
		num=$(ps xh -ocommand | grep -E '^ASYD ' | wc -l)
        echo -n "$num"
        exit $((128+$num))
        ;;
    *)
        echo "Usage: $self {start|stop|restart|status|pid|count}"
        exit 1
        ;;
esac

exit 0