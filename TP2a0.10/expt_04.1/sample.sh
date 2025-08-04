#!/bin/bash

# Capture the output of the command
output=$(./check_hycom.sh)

# Check if the output is empty
if [ -z "$output" ]; then
  cd $P
  echo "GOODRUN" > log/hycom_ens.stop
else
  cd $P
  echo "GOODRUN" > log/hycom_ens.stop
fi
