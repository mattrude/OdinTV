#!/bin/bash

rm -f /tmp/MyVideos.db
DBNAME="`ssh root@10.0.0.10 ls /storage/.kodi/userdata/Database/MyVideos*.db`"
rsync root@10.0.0.10:${DBNAME} /tmp/MyVideos.db
echo "SELECT c00 as Name, strftime('%Y',premiered) as "Year" FROM movie ORDER BY c00 COLLATE NOCASE ASC;" |sqlite3 /tmp/MyVideos.db |sed 's/|/ (/g' |sed 's/$/)/g' > /var/www/html/movies.txt
echo "SELECT c00 as Name, strftime('%Y',c05) as "Year" FROM tvshow ORDER BY c00 COLLATE NOCASE ASC;" |sqlite3 /tmp/MyVideos.db |sed 's/|/ (/g' |sed 's/$/)/g' > /var/www/html/tvshows.txt
rm -f /tmp/MyVideos.db
