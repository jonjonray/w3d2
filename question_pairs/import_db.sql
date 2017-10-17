DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL,
);


DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);


DROP TABLE IF EXISTS questions_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id = INTEGER NOT NULL,
  question_id = INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);



DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  reply_body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
)


DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
)

INSERT INTO
  users(fname,lname)
VALUES
  ('Jonathan','Ray'),
  ('Christina','K');


INSERT INTO
  questions(title,body,author_id)
VALUES
  ('Very confused by SQL','Somebody plz help',(SELECT id FROM users WHERE fname = 'Jonathan')),
  ('Still very confused by SQL','I''m dying',(SELECT id FROM users WHERE fname = 'Christina'));

INSERT INTO
  question_follows(user_id, question_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 1),
  (2, 2);

INSERT INTO
  replies(question_id, parent_id, user_id, reply_body)
VALUES
  (1, NULL, 2, 'Me too'),
  (1, 1, 1, 'Yeah, it sucks');

INSERT INTO 
  likes(question_id, user_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 1),
  (2, 2);
