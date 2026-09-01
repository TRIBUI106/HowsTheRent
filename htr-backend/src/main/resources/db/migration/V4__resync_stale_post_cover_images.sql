-- Posts previously snapshotted their room's first image into cover_image_url
-- at create/update time and never resynced it when the room's photos later
-- changed. That snapshot is no longer taken (PostService now leaves
-- cover_image_url null unless the admin explicitly set one via the
-- dedicated upload endpoint, and resolves the effective cover image live
-- from the room at read time). Null out any existing value that still
-- matches one of the post's own room's images, since it was auto-derived
-- rather than explicitly uploaded, so it starts resolving live too.
UPDATE posts p
SET cover_image_url = NULL
WHERE cover_image_url IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM room_images ri
    WHERE ri.room_id = p.room_id
      AND ri.image_url = p.cover_image_url
  );
