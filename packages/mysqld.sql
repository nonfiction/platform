ALTER USER 'root'@'localhost' IDENTIFIED BY 'x';
CREATE DATABASE IF NOT EXISTS nonfiction;
CREATE USER 'nonfiction'@'localhost' IDENTIFIED BY 'x';
GRANT ALL PRIVILEGES ON nonfiction.* TO 'nonfiction'@'localhost';
FLUSH PRIVILEGES;
