CREATE TABLE items (id SERIAL PRIMARY KEY, body TEXT NOT NULL);

ALTER SEQUENCE items_id_seq RESTART WITH 40;

INSERT INTO items (body) VALUES
 ('alpha'),('bravo'),('charlie'),('delta'),('echo'),
 ('foxtrot'),('golf'),('hotel'),('india'),('juliet');
