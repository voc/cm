## ingest role
Used for accepting external streams

- creates nginx-rtmp endpoints for every stream in {{ rtmp_ingest_streams }}
- creates icecast-mkv endpoints for every stream in {{ icecast_additional_mounts }}