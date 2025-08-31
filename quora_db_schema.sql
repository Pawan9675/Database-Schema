-- Simple Quora-like App Database Schema

-- 1. Users table - stores all user account information
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique user identifier
    username VARCHAR(50) UNIQUE NOT NULL,           -- Display name for user
    email VARCHAR(100) UNIQUE NOT NULL,             -- Login email (must be unique)
    password_hash VARCHAR(255) NOT NULL,            -- Encrypted password
    full_name VARCHAR(100),                         -- User's real name (optional)
    bio TEXT,                                       -- User profile description
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- When account was created
);

-- 2. Topics table - stores categories/subjects for questions
CREATE TABLE topics (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique topic identifier
    name VARCHAR(100) UNIQUE NOT NULL,              -- Topic name (e.g., "Technology", "Sports")
    description TEXT,                               -- Brief topic description
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- When topic was created
);

-- 3. Questions table - stores all user questions
CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique question identifier
    user_id INT NOT NULL,                           -- Who asked the question
    title VARCHAR(255) NOT NULL,                    -- Question title/headline
    content TEXT,                                   -- Detailed question description (optional)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When question was posted
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last edited
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE -- Delete question if user deleted
);

-- 4. Answers table - stores answers to questions
CREATE TABLE answers (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique answer identifier
    question_id INT NOT NULL,                       -- Which question this answers
    user_id INT NOT NULL,                           -- Who wrote the answer
    content TEXT NOT NULL,                          -- Answer content (required)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When answer was posted
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last edited
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE, -- Delete if question deleted
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE -- Delete if user deleted
);

-- 5. Comments table - handles both answer comments and comment replies
CREATE TABLE comments (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique comment identifier
    user_id INT NOT NULL,                           -- Who wrote the comment
    answer_id INT NULL,                             -- If commenting on an answer (use this)
    parent_comment_id INT NULL,                     -- If replying to another comment (use this)
    content TEXT NOT NULL,                          -- Comment content
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When comment was posted
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last edited
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (answer_id) REFERENCES answers(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    -- Ensure comment is either on an answer OR replying to another comment (not both)
    CHECK ((answer_id IS NOT NULL AND parent_comment_id IS NULL) OR 
           (answer_id IS NULL AND parent_comment_id IS NOT NULL))
);

-- 6. Likes table - handles likes for questions, answers, and comments
CREATE TABLE likes (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique like identifier
    user_id INT NOT NULL,                           -- Who gave the like
    question_id INT NULL,                           -- If liking a question (use this)
    answer_id INT NULL,                             -- If liking an answer (use this)
    comment_id INT NULL,                            -- If liking a comment (use this)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When like was given
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    FOREIGN KEY (answer_id) REFERENCES answers(id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    -- Ensure like is for exactly one type of content (question OR answer OR comment)
    CHECK ((question_id IS NOT NULL AND answer_id IS NULL AND comment_id IS NULL) OR
           (question_id IS NULL AND answer_id IS NOT NULL AND comment_id IS NULL) OR
           (question_id IS NULL AND answer_id IS NULL AND comment_id IS NOT NULL)),
    -- Prevent duplicate likes from same user on same content
    UNIQUE KEY unique_question_like (user_id, question_id),
    UNIQUE KEY unique_answer_like (user_id, answer_id),
    UNIQUE KEY unique_comment_like (user_id, comment_id)
);

-- 7. Question-Topics mapping - links questions to topics (many-to-many relationship)
CREATE TABLE question_topics (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique mapping identifier
    question_id INT NOT NULL,                       -- Which question
    topic_id INT NOT NULL,                          -- Which topic it belongs to
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When topic was added to question
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE KEY unique_question_topic (question_id, topic_id) -- Prevent duplicate topic assignments
);

-- 8. User follows - tracks when users follow other users
CREATE TABLE user_follows (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique follow relationship identifier
    follower_id INT NOT NULL,                       -- User who is following (the follower)
    following_id INT NOT NULL,                      -- User being followed (the one followed)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When follow relationship started
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE,
    -- Prevent users from following themselves
    CHECK (follower_id != following_id),
    -- Prevent duplicate follows (same user following same person twice)
    UNIQUE KEY unique_follow (follower_id, following_id)
);

-- 9. Topic follows - tracks when users follow specific topics
CREATE TABLE topic_follows (
    id INT PRIMARY KEY AUTO_INCREMENT,              -- Unique topic follow identifier
    user_id INT NOT NULL,                           -- User who is following the topic
    topic_id INT NOT NULL,                          -- Topic being followed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When user started following topic
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    -- Prevent duplicate topic follows (same user following same topic twice)
    UNIQUE KEY unique_topic_follow (user_id, topic_id)
);

-- Sample Queries to demonstrate functionality:

-- Get all questions for a specific topic (filter by topic)
-- SELECT q.* FROM questions q 
-- JOIN question_topics qt ON q.id = qt.question_id 
-- JOIN topics t ON qt.topic_id = t.id 
-- WHERE t.name = 'Technology';

-- Get questions from users you follow (personalized feed)
-- SELECT q.* FROM questions q 
-- JOIN user_follows uf ON q.user_id = uf.following_id 
-- WHERE uf.follower_id = [your_user_id];

-- Get questions from topics you follow (topic-based feed)
-- SELECT DISTINCT q.* FROM questions q 
-- JOIN question_topics qt ON q.id = qt.question_id 
-- JOIN topic_follows tf ON qt.topic_id = tf.topic_id 
-- WHERE tf.user_id = [your_user_id];

-- Count likes for a question (popularity metric)
-- SELECT COUNT(*) as like_count FROM likes 
-- WHERE question_id = [question_id];

-- Get all comments for an answer including nested replies (conversation thread)
-- SELECT c1.*, c2.content as reply_content 
-- FROM comments c1 
-- LEFT JOIN comments c2 ON c1.id = c2.parent_comment_id 
-- WHERE c1.answer_id = [answer_id] AND c1.parent_comment_id IS NULL;