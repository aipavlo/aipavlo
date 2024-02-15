# check volumes
docker volume ls
# import to docker
docker cp /home/debian/file_to_import/dwh.csv.gz vert-ce:/file_to_import/dwh.csv.gz
# export from docker
docker cp vert-ce:/file_to_export/dwh.csv.gz  /home/debian/file_to_export/dwh.csv.gz
