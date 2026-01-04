-- create extra user + db example
CREATE USER joplin WITH PASSWORD 'joplin';
CREATE DATABASE joplin OWNER joplin;

-- optional: grant privileges on existing db
GRANT ALL PRIVILEGES ON DATABASE joplin TO joplin;