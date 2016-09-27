#!/bin/bash
LOG_FILE=/var/log/ixtheo/java_mem_stats.log
echo "$(date +%F%T) $(jstat -gccapacity $(jps -v | grep -- -Djetty.port=8080 | cut -f1 -d' ') 2>/dev/null)"   >> "$LOG_FILE" 
