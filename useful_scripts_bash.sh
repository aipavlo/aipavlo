# CHECK FIRST ROW OF CSV.GZ FILE
 zcat dwh.csv.gz | head -n 1

 
### VSQL ###
# stop on error
\set ON_ERROR_STOP on
# Executes a shell command and returns the output to vsql.
vsql -A -t -d your_database -U your_user -h your_host -w your_password -f /file_to_import/adhoc.sql -o /file_to_import/result.txt -- execute script and have all output in file without header and footer

# define variable with query result
CHECK_CONDITION="SELECT (COUNT(DISTINCT batch_id) > 1)::integer FROM test_schema.test_table;"
CHECK_RESULT=$(/opt/vertica/bin/vsql -A -t -X -d $VERTICA_DB -U $ETL_VSQL_USER -c "$CHECK_CONDITION")
if [ $CHECK_RESULT -eq 1 ]
then
 echo 1
else
 echo 0
fi

# check hostname
hostname
# check public IP
wget -qO- http://ipecho.net/plain
curl ipinfo.io

export DBNAME=dbname
tail -n 500 /data/vertica/${DBNAME}/v_${DBNAME}_node0001_catalog/vertica.log
