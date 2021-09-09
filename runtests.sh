#!/bin/bash

function runtest {
    echo
    echo "Executing q ${@} -q"
    if q "${@}" -q
    then echo "q ${@} succeeded."
    else
	echo "q ${@} FAILED"
	exit 1
    fi
}

runtest test_qtb2.q -q
runtest qtb2.q sample-qtb2.q -run 1
if cd msglib
then
    runtest ../qtb2.q dispatch.q  test_dispatch.q -run 1
    runtest ../qtb2.q msgclient.q test_msgclient.q -run 1
    runtest ../qtb2.q msgsrvr.q   test_msgsrvr.q -run 1
else
    echo "Failed to cd to msglib"
fi
