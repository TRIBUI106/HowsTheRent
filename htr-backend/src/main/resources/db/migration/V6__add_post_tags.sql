-- Free-text tags/categories for posts. No separate Tag entity/admin CRUD --
-- filtering happens client-side over the already-fetched post list.
CREATE TABLE IF NOT EXISTS post_tags (
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL
);
