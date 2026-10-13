CREATE TABLE quotes (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(128) NOT NULL,
    body TEXT NOT NULL,
    UNIQUE(slug)
);
