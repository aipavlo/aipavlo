import cx_Oracle
import csv
import datetime

# Connect to Oracle (replace with your credentials)
connection = cx_Oracle.connect('user/pass@hostname:port/service_name')
cursor = connection.cursor()

# Define your SQL query (modify as needed)
sql = "SELECT * FROM your_table WHERE DT = :day"

# Iterate over days and create CSV files
for day in range(1, 32):  # Assuming days in a month
    formatted_day = datetime.date.today().replace(day=day).strftime("%Y%m%d")
    filename = f"schema.table.{formatted_day}.csv"
    with open(filename, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["column1", "column2", ...])  # Write column headers
        cursor.execute(sql, day=day)
        writer.writerows(cursor.fetchall())  # Write data rows

# Close the cursor and connection
cursor.close()
connection.close()
