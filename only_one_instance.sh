#!/bin/bash
RUNINST=$(ps -ef | grep -v grep | grep -c $(basename $0))
if [[ "$RUNINST" > 2 ]]; then
    echo "ALREADY RUNNING"
    exit 0
else

### start
<script>
### stop

fi
