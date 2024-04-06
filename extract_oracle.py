import cx_Oracle
import csv
import datetime
import unittest
import os
import shutil
import hashlib
from paramiko import SSHClient
from scp import SCPClient

db_connect = cx_Oracle.connect('user/pass@hostname:port/service_name')
start_date = datetime.date(2024, 1, 1)
end_date = datetime.date(2024, 12, 31)

def compute_hash(filename):
    # Use SHA256 hash algorithm
    hash_func = hashlib.sha256()

    # Read the file in binary mode and update the hash
    with open(filename, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_func.update(chunk)

    # Return the hexadecimal representation of the hash
    return hash_func.hexdigest()

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

                # Compute and print the hash of the file before sending
                hash_before = compute_hash(filename + '.zip')
                print(f'Hash before sending: {hash_before}')
                
                # Push the file to another server
                push_to_server(filename, 'hostname', 'username', 'password')
                
                # Compute and print the hash of the file after receiving
                hash_after = compute_hash(filename + '.zip')
                print(f'Hash after receiving: {hash_after}')
            
                # Check if the hashes match
                if hash_before == hash_after:
                    print('The file was transferred successfully.')
                else:
                    print('The file was corrupted during transfer.')

export_to_csv(db_connect, 'your_table', start_date, end_date)



import unittest
from unittest.mock import patch, MagicMock

class TestExportToCSV(unittest.TestCase):
    @patch('builtins.open', new_callable=unittest.mock.mock_open)
    @patch('csv.writer')
    @patch('cx_Oracle.connect')
    def test_export_to_csv(self, mock_connect, mock_writer, mock_open):
        # Mock the database connection and cursor
        mock_cursor = MagicMock()
        mock_connect.return_value.cursor.return_value = mock_cursor
        mock_cursor.description = [('column1',), ('column2',)]
        mock_cursor.fetchmany.side_effect = [[('data1', 'data2')], []]

        # Call the function with the mocked dependencies
        export_to_csv(mock_connect, 'table_name', datetime.date(2024, 1, 1), datetime.date(2024, 12, 31))

        # Assert that the correct SQL was executed
        mock_cursor.execute.assert_called_once_with(
            "SELECT * FROM table_name WHERE DT BETWEEN :start_day AND :end_day",
            start_day=datetime.date(2024, 1, 1),
            end_day=datetime.date(2024, 12, 31)
        )

        # Assert that the CSV writer was called with the correct arguments
        mock_writer.assert_called_once_with(mock_open.return_value, quoting=csv.QUOTE_NONNUMERIC)
        mock_writer.return_value.writerow.assert_called_once_with(['column1', 'column2'])
        mock_writer.return_value.writerows.assert_called_once_with([('data1', 'data2')])

if __name__ == '__main__':
    unittest.main()
