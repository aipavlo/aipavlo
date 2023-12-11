docker exec -it vertica-ce bash
opt/vertica/bin/vbr --task init -c backup_test/db_backup.ini

export VBR_BACKUP_STORAGE_ACCESS_KEY_ID=<key>
export VBR_BACKUP_STORAGE_SECRET_ACCESS_KEY=<secret-key>

opt/vertica/bin/vbr --task backup -c backup_test/db_backup.ini
