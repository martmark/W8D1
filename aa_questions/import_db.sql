-- rm questions.db
-- cat import_db.sql | sqlite3 questions.db
DROP TABLE question_likes;
DROP TABLE replies;
DROP TABLE question_follows;
DROP TABLE questions;
DROP TABLE users;

PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT,
    author_id INTEGER NOT NULL, 

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_id INTEGER,
    user_id INTEGER NOT NULL,
    body TEXT NOT NULL,

    FOREIGN KEY (parent_id) REFERENCES replies(id),
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
    users (fname, lname)
VALUES
    ('Valery', 'Nguyen'),
    ('Martin', 'Markaj');

INSERT INTO
    questions (title, body, author_id)
VALUES
    ('Lunch', 'What time is lunch?', 2),
    ('SQL all tables?', 'how to display all tables in database in sqlite3?', 1);

INSERT INTO
    question_follows (question_id, user_id)
VALUES
    (1, 1),
    (2, 2);

INSERT INTO
    replies (question_id, parent_id, user_id, body)
VALUES
    (2, NULL, 2, 'Use SELECT * from NAME of table');

INSERT INTO
    question_likes (question_id, user_id)
VALUES
    (1, 1);