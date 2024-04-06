import cx_Oracle
import csv
import datetime
import unittest
import os
import shutil
from paramiko import SSHClient
from scp import SCPClient

db_connect = cx_Oracle.connect('user/pass@hostname:port/service_name')
start_date = datetime.date(2024, 1, 1)
end_date = datetime.date(2024, 12, 31)

def push_to_server(filename, hostname, username, password):
    ssh = SSHClient()
    ssh.load_system_host_keys()
    ssh.connect(hostname, username=username, password=password)
    with SCPClient(ssh.get_transport()) as scp:
        scp.put(filename + '.zip')

def export_to_csv(db_connect, table_name, start_date, end_date):
    sql = f"SELECT * FROM {table_name} WHERE DT BETWEEN :start_day AND :end_day"
    # Connect to the database
    with db_connect as connection:
        with connection.cursor() as cursor:
            for single_date in (start_date + datetime.timedelta(n) for n in range(int ((end_date - start_date).days))):
                formatted_day = single_date.strftime("%Y%m%d")
                filename = f"{table_name}.{formatted_day}.csv"
                with open(filename, "w", newline="", encoding="utf-8") as csvfile:
                    writer = csv.writer(csvfile, quoting=csv.QUOTE_NONNUMERIC)
                    
                    # Execute the query
                    cursor.execute(sql, start_day=start_date, end_date=end_date)
                    
                    # Get column names
                    column_names = [column[0] for column in cursor.description]
                    writer.writerow(column_names)  # Write column headers
                    
                    # Fetch data in batches
                    while True:
                        rows = cursor.fetchmany(1000)  # Adjust size as needed
                        if not rows:
                            break
                        writer.writerows(rows)  # Write data rows

                # Archive the file
                shutil.make_archive(filename, 'zip', '.', filename)

                # Push the file to another server
                push_to_server(filename, 'hostname', 'username', 'password')

export_to_csv(db_connect, 'your_table', start_date, end_date)
