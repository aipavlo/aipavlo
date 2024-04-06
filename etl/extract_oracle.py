import cx_Oracle
import csv
import datetime
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

# Constants
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOSTNAME = os.getenv('DB_HOSTNAME')
DB_PORT = os.getenv('DB_PORT')
DB_SERVICE_NAME = os.getenv('DB_SERVICE_NAME')
PRIVATE_KEY_PATH = 'your_private_key_path'
TABLE_NAME = 'your_table'

class DataExporter:
    def __init__(self, start_date, end_date):
        self.start_date = start_date
        self.end_date = end_date

    @staticmethod
    def get_db_connection():
        """
        Establishes a connection to the Oracle database using the connection details stored in environment variables.
        Returns the connection object if successful, otherwise raises an exception.
        """
        if not all([DB_USER, DB_PASSWORD, DB_HOSTNAME, DB_PORT, DB_SERVICE_NAME]):
            raise ValueError("One or more database connection parameters are not set.")
        try:
            return cx_Oracle.connect(f'{DB_USER}/{DB_PASSWORD}@{DB_HOSTNAME}:{DB_PORT}/{DB_SERVICE_NAME}')
        except cx_Oracle.DatabaseError as e:
            logging.error(f"Failed to connect to the database: {e}")
            raise

    @staticmethod
    def compute_hash(filename):
        """
        Compute the hash of a file.
        """
        hash_func = hashlib.sha256()
        with open(filename, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_func.update(chunk)
        return hash_func.hexdigest()

    @staticmethod
    def push_to_server(filename, hostname, username, password, private_key_path):
        """
        Push a file to a server using SSH.
        """
        ssh = SSHClient()
        ssh.load_system_host_keys()
        private_key = RSAKey(filename=private_key_path, password=password)
        with ssh:
            ssh.connect(hostname, username=username, pkey=private_key)
            with SCPClient(ssh.get_transport()) as scp:
                scp.put(filename + '.zip')
            stdin, stdout, stderr = ssh.exec_command(f"sha256sum {filename}.zip")
            hash_after = stdout.read().split()[0].decode()
            logging.info(f'Hash after receiving: {hash_after}')
        return hash_after

    @staticmethod
    def export_to_csv(db_connect, table_name, start_date, end_date):
        """
        Export data from Oracle database to CSV files.
        """
        sql = f"SELECT * FROM {table_name} WHERE DT BETWEEN :start_day AND :end_day"
        with db_connect as connection:
            with connection.cursor() as cursor:
                for single_date in (start_date + datetime.timedelta(n) for n in range(int((end_date - start_date).days))):
                    formatted_day = single_date.strftime("%Y%m%d")
                    filename = f"{table_name}.{formatted_day}.csv"
                    try:
                        with open(filename, "w", newline="", encoding="utf-8") as csvfile:
                            writer = csv.writer(csvfile, quoting=csv.QUOTE_NONNUMERIC)
                            cursor.execute(sql, start_day=start_date, end_day=end_date)
                            column_names = [column[0] for column in cursor.description]
                            writer.writerow(column_names)
                            while True:
                                rows = cursor.fetchmany(1000)
                                if not rows:
                                    break
                                writer.writerows(rows)
                    except IOError as e:
                        logging.error(f"Failed to open file: {e}")
                        raise
                    shutil.make_archive(filename, 'zip', '.', filename)
                    hash_before = DataExporter.compute_hash(filename + '.zip')
                    print(f'Hash before sending: {hash_before}')
                    hash_after = DataExporter.push_to_server(filename, 'hostname', 'username', 'password', PRIVATE_KEY_PATH)
                    if hash_before == hash_after:
                        print('The file was transferred successfully.')
                    else:
                        print('The file was corrupted during transfer.')

if __name__ == "__main__":
    start_date = datetime.date(2024, 1, 1)
    end_date = datetime.date(2024, 12, 31)
    exporter = DataExporter(start_date, end_date)
    try:
        with exporter.get_db_connection() as db_connect:
            exporter.export_to_csv(db_connect, TABLE_NAME, start_date, end_date)
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
