#!/bin/bash

mkdir -p /var/lib/kodi-backup
rm -f /var/lib/kodi-backup/watched.movies.json /var/lib/kodi-backup/watched.tvshows.json
/usr/local/bin/texturecache.py watched movies backup /var/lib/kodi-backup/watched.movies.json @section=jacktv
/usr/local/bin/texturecache.py watched tvshows backup /var/lib/kodi-backup/watched.tvshows.json @section=jacktv

exit 0

for site in jacktv
do
  if [ -f /var/lib/kodi-backup/watched.movies.json ]; then
    echo "- Starting on ${site} movies"
    /usr/local/bin/texturecache.py watched movies restore /var/lib/kodi-backup/watched.movies.json @section=${site}
  fi
  if [ -f /var/lib/kodi-backup/watched.tvshows.json ]; then
    echo "- Starting on ${site} tvshows"
    /usr/local/bin/texturecache.py watched tvshows restore /var/lib/kodi-backup/watched.tvshows.json @section=${site}
  fi
done
