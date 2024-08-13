#!/bin/bash

# Example input in YYYYDOY format
YYYYDOY=$1

# Convert to YYYY-MM-DD format
YYYYMMDD=$(date -d "${YYYYDOY:0:4}-01-01 +${YYYYDOY:4} days - 1 day" +%Y%m%d)

# Output the result
echo $YYYYMMDD
