-- Active users report. Should list everyone who is not archived.
SELECT email FROM users WHERE archived != true ORDER BY id;
