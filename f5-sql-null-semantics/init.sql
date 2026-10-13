CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    archived BOOLEAN
);

INSERT INTO users (email, archived) VALUES
 ('a@example.com', false),
 ('b@example.com', NULL),
 ('c@example.com', false),
 ('d@example.com', NULL),
 ('e@example.com', true),
 ('f@example.com', NULL),
 ('g@example.com', false),
 ('h@example.com', NULL);
