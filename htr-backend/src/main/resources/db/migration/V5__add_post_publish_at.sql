-- Lets an admin schedule a post to auto-publish at a future date/time
-- instead of only "publish now". Nullable: unset means no schedule.
ALTER TABLE posts ADD COLUMN publish_at TIMESTAMP;
