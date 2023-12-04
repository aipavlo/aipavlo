# CHECK FIRST ROW OF CSV.GZ FILE
 zcat dwh.csv.gz | head -n 1

 
### VSQL ###
# stop on error
\set ON_ERROR_STOP on
# Executes a shell command and returns the output to vsql.
vsql -A -t -d your_database -U your_user -h your_host -w your_password -f /file_to_import/adhoc.sql -o /file_to_import/result.txt -- execute script and have all output in file withou header and footer

# check hostname
hostname
# check public IP
wget -qO- http://ipecho.net/plain
