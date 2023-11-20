#!/bin/bash

# Define directories
INCOMING_DIR="/path/to/incoming_files"
PROCESSING_DIR="/path/to/processing"
ARCHIVE_DIR="/path/to/archive"
ERROR_DIR="/path/to/archive_errors"

# Define SQL script
SQL_SCRIPT="/path/to/insert_from_ext_table.sql"

# Define log file
LOG_FILE="/path/to/log_file.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Check if directories exist
for dir in $INCOMING_DIR $PROCESSING_DIR $ARCHIVE_DIR $ERROR_DIR; do
    if [ ! -d "$dir" ]; then
        log_message "Directory $dir does not exist. Creating it now."
        mkdir -p "$dir"
    fi
done

# Check if there are .csv.gz files in INCOMING_DIR
if [ $(ls $INCOMING_DIR/*.csv.gz 2> /dev/null | wc -l) -eq 0 ]; then
    log_message "No .csv.gz files found in $INCOMING_DIR. Exiting."
    exit 0
fi

# Move .csv.gz files from INCOMING_DIR to PROCESSING_DIR and count them
CSV_FILES=($INCOMING_DIR/*.csv.gz)
NUM_FILES=${#CSV_FILES[@]}
if mv $INCOMING_DIR/*.csv.gz $PROCESSING_DIR; then
    log_message "Moved $NUM_FILES .csv.gz files from $INCOMING_DIR to $PROCESSING_DIR"
else
    log_message "Error moving files from $INCOMING_DIR to $PROCESSING_DIR"
    exit 1
fi

# Execute SQL script with vsql command
if vsql -f $SQL_SCRIPT; then
    log_message "SQL script $SQL_SCRIPT executed successfully"
    # Move .csv.gz files from PROCESSING_DIR to ARCHIVE_DIR
    if mv $PROCESSING_DIR/*.csv.gz $ARCHIVE_DIR; then
        log_message "Moved $NUM_FILES .csv.gz files from $PROCESSING_DIR to $ARCHIVE_DIR"
    else
        log_message "Error moving files from $PROCESSING_DIR to $ARCHIVE_DIR"
        exit 1
    fi
else
    log_message "Error executing SQL script $SQL_SCRIPT"
    # Move .csv.gz files from PROCESSING_DIR to ERROR_DIR
    if mv $PROCESSING_DIR/*.csv.gz $ERROR_DIR; then
        log_message "Moved $NUM_FILES .csv.gz files from $PROCESSING_DIR to $ERROR_DIR due to error"
    else
        log_message "Error moving files from $PROCESSING_DIR to $ERROR_DIR"
        exit 1
    fi
fi
