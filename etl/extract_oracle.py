import cx_Oracle
import csv
import datetime
import unittest
import os
import shutil
import hashlib
import logging
from paramiko import SSHClient, RSAKey
from scp import SCPClient
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Set up logging
logging.basicConfig(filename='app.log', level=logging.INFO)

start_date = datetime.date(2024, 1, 1)
end_date = datetime.date(2024, 12, 31)
hostname = 'your_hostname'
username = 'your_username'
password = 'your_password'
private_key_path = 'your_private_key_path'
table_name = 'your_table'

class DataExporter:
    def __init__(self, start_date, end_date):
        self.start_date = start_date
        self.end_date = end_date

    def get_db_connection():
        """
        Establishes a connection to the Oracle database using the connection details stored in environment variables.
        Returns the connection object if successful, otherwise raises an exception.
        """
        user = os.getenv('DB_USER')
        password = os.getenv('DB_PASSWORD')
        hostname = os.getenv('DB_HOSTNAME')
        port = os.getenv('DB_PORT')
        service_name = os.getenv('DB_SERVICE_NAME')
        if not all([user, password, hostname, port, service_name]):
            raise ValueError("One or more database connection parameters are not set.")
        try:
            return cx_Oracle.connect(f'{user}/{password}@{hostname}:{port}/{service_name}')
        except cx_Oracle.DatabaseError as e:
            print(f"Failed to connect to the database: {e}")
            raise

    def compute_hash(filename):
        # Use SHA256 hash algorithm
        hash_func = hashlib.sha256()
    
        # Read the file in binary mode and update the hash
        with open(filename, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_func.update(chunk)
        return hash_func.hexdigest()

    def push_to_server(self, filename, hostname, username, password, private_key_path):
            ssh = SSHClient()
            ssh.load_system_host_keys()
            
            # Load the private key
            private_key = RSAKey(filename=private_key_path, password='your_password')
        
            with ssh:
                ssh.connect(hostname, username=username, pkey=private_key)
                with SCPClient(ssh.get_transport()) as scp:
                    scp.put(filename + '.zip')
        
                # Compute and print the hash of the file on the remote server
                stdin, stdout, stderr = ssh.exec_command(f"sha256sum {filename}.zip")
                hash_after = stdout.read().split()[0].decode()
                logging.info(f'Hash after receiving: {hash_after}')
        
            return hash_after

    def export_to_csv(db_connect, table_name, start_date, end_date):
        sql = f"SELECT * FROM {table_name} WHERE DT BETWEEN :start_day AND :end_day"
        # Connect to the database
        with db_connect as connection:
            with connection.cursor() as cursor:
                for single_date in (start_date + datetime.timedelta(n) for n in range(int ((end_date - start_date).days))):
                    formatted_day = single_date.strftime("%Y%m%d")
                    filename = f"{table_name}.{formatted_day}.csv"
                    try:
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
                    except IOError as e:
                        logging.error(f"Failed to open file: {e}")
                        raise
    
                    # Archive the file
                    shutil.make_archive(filename, 'zip', '.', filename)
    
                    # Compute and print the hash of the file before sending
                    hash_before = compute_hash(filename + '.zip')
                    print(f'Hash before sending: {hash_before}')
                    
                    # Push the file to another server and get the hash after receiving
                    hash_after = push_to_server(filename, 'hostname', 'username', 'password')
                
                    # Check if the hashes match
                    if hash_before == hash_after:
                        print('The file was transferred successfully.')
                    else:
                        print('The file was corrupted during transfer.')

if __name__ == "__main__":
    exporter = DataExporter(start_date, end_date)
    try:
        with exporter.get_db_connection() as db_connect:
            exporter.export_to_csv(db_connect, 'your_table')
    except Exception as e:
        logging.error(f"An error occurred: {e}")



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
