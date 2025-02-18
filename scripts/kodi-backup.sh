#!/bin/bash

DIR="/var/lib/kodi-backup"

if [ `date +%d` == 01 ]; then
    DATE=`date +%m.%Y%m%d`
    rm -rf ${DIR}/KodiDB.`date +%m`.*.sql.gz ${DIR}/watched.movies.`date +%m`.*.json.gz ${DIR}/watched.tvshows.`date +%m`.*.json.gz
else
    DATE=`date +%w.%Y%m%d`
    rm -rf ${DIR}/KodiDB.`date +%w`.*.sql.gz ${DIR}/watched.movies.`date +%w`.*.json.gz ${DIR}/watched.tvshows.`date +%w`.*.json.gz
fi

sudo mysqldump --all-databases > /var/lib/kodi-backup/KodiDB.${DATE}.sql && gzip /var/lib/kodi-backup/KodiDB.${DATE}.sql && \
/usr/local/bin/texturecache.py watched tvshows backup /var/lib/kodi-backup/watched.tvshows.${DATE}.json @section=jacktv && \
/usr/local/bin/texturecache.py watched movies backup /var/lib/kodi-backup/watched.movies.${DATE}.json @section=jacktv && \
gzip /var/lib/kodi-backup/watched.tvshows.${DATE}.json && gzip /var/lib/kodi-backup/watched.movies.${DATE}.json && \
echo "Complete!"
