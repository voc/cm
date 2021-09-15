## ingest role
Used for accepting external streams

- automatically forwards every rtmp stream to the internal icecast (governed by rtmp-auth)
- creates icecast-mkv endpoints for every stream in {{ icecast_additional_mounts }}