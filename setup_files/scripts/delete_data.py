"""
Gets images from the database that are older than the specified number of days
and removes them from both the database and disk.

IMPORTANT: DO NOT RUN THIS IN PRODUCTION
"""

import os
import sys
import argparse

from configparser import ConfigParser
from datetime import date, timedelta

# This is not a great practice, don't do this
sys.path.append("/var/www/api.helioviewer.org/scripts")
from utils.database_pager import DatabasePager
from utils import database

GET_AGED_FILES_SQL = "SELECT filepath, filename FROM data WHERE date < '%s'"
DELETE_AGED_ROWS_SQL = "DELETE FROM data WHERE date < '%s'"

def _parse_args():
    parser = argparse.ArgumentParser(description='Validates image information on disk against information in the database')
    parser.add_argument('-c', '--creds', type=str, required=True,
                        help='ini file that contains database login credentials in the database section')
    parser.add_argument('-d', '--data', type=str, required=True,
                        help='Path to images folder')
    parser.add_argument('--days', type=int, required=True,
                        help='Number of days of data to keep. Anything older than this many days will be removed')

    args = parser.parse_args()
    config = ConfigParser()
    config.read(args.creds)
    args.creds = config
    return args

def _get_cutoff_date_string(cutoff_days=31):
    """
    Returns a date timestamp string (i.e. "2021-12-03 00:00:00") that represents
    today - cutoff_days.
    """
    today = date.today()
    delta = timedelta(days=cutoff_days)
    cutoff = today - delta
    cutoff_str = cutoff.isoformat() + " 00:00:00"
    return cutoff_str

def delete_aged_files(cursor, datapath, cutoff_date):
    """
    Deletes all files older than cutoff date.

    - cursor: Database cursor object
    - datapath: String path to image data
    - cutoff_date: Date string representing the cutoff date in this format (YYYY-MM-DD 00:00:00)
    """
    pager = DatabasePager(cursor, GET_AGED_FILES_SQL % cutoff_date)

    query_list = pager.get_all()
    for row in query_list:
        image_path = row[0] + os.sep + row[1]
        # Concatenate the db file path with the data directory
        full_image_path = datapath + image_path
        print("Removing %s" % full_image_path)
        try:
            os.remove(full_image_path)
        except Exception as e:
            print("Failed to remove %s: %s" % (full_image_path, str(e)))

def delete_aged_rows(cursor, cutoff):
    cursor.execute(DELETE_AGED_ROWS_SQL % cutoff)

def main():
    args = _parse_args()
    credentials = args.creds['database']
    cursor = database.get_dbcursor(dbname=credentials['database'], dbuser=credentials['username'], dbpass=credentials['password'])
    cutoff = _get_cutoff_date_string(args.days)
    delete_aged_files(cursor, args.data, cutoff)
    delete_aged_rows(cursor, cutoff)

    # Close db connection
    cursor.close()

if __name__ == "__main__":
    main()
