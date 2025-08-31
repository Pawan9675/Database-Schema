-- Movie Booking App Database Schema

-- Users table - stores all user account information
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique user identifier
    username VARCHAR(50) UNIQUE NOT NULL,       -- unique username for login
    email VARCHAR(100) UNIQUE NOT NULL,         -- user email address
    password_hash VARCHAR(255) NOT NULL,        -- encrypted password
    full_name VARCHAR(100),                     -- user's full name
    phone VARCHAR(15),                          -- user's phone number
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when account was created
);

-- Cities table - stores city information
CREATE TABLE cities (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique city identifier
    name VARCHAR(100) NOT NULL,                 -- city name (e.g., "Mumbai", "Delhi")
    state VARCHAR(100),                         -- state/province name
    country VARCHAR(100) DEFAULT 'India',      -- country name
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when city was added
);

-- Theatres table - stores theatre information
CREATE TABLE theatres (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique theatre identifier
    name VARCHAR(150) NOT NULL,                 -- theatre name (e.g., "PVR Cinemas")
    address TEXT,                               -- theatre full address
    city_id INT NOT NULL,                       -- which city theatre is in
    phone VARCHAR(15),                          -- theatre contact number
    total_screens INT DEFAULT 1,               -- number of screens in theatre
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when theatre was added
    FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE CASCADE  -- delete theatre if city deleted
);

-- Movies table - stores movie information
CREATE TABLE movies (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique movie identifier
    title VARCHAR(255) NOT NULL,               -- movie title
    description TEXT,                          -- movie plot/description
    duration_minutes INT,                      -- movie length in minutes
    genre VARCHAR(100),                        -- movie genre (e.g., "Action", "Comedy")
    language VARCHAR(50),                      -- movie language
    release_date DATE,                         -- when movie was released
    rating VARCHAR(10),                        -- movie rating (e.g., "PG-13", "R")
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when movie was added to system
);

-- Movie Showtimes table - stores when movies play at theatres
CREATE TABLE showtimes (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique showtime identifier
    movie_id INT NOT NULL,                      -- which movie is playing
    theatre_id INT NOT NULL,                   -- which theatre is showing it
    show_date DATE NOT NULL,                   -- date of the show
    show_time TIME NOT NULL,                   -- time of the show (e.g., "14:30")
    screen_number INT,                         -- which screen in the theatre
    total_seats INT DEFAULT 100,              -- total seats available
    available_seats INT DEFAULT 100,          -- seats still available
    ticket_price DECIMAL(10,2),               -- price per ticket
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when showtime was created
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (theatre_id) REFERENCES theatres(id) ON DELETE CASCADE
);

-- Bookings table - stores all ticket bookings
CREATE TABLE bookings (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique booking identifier
    user_id INT NOT NULL,                       -- who made the booking
    showtime_id INT NOT NULL,                   -- which showtime was booked
    seats_booked INT NOT NULL,                  -- number of seats booked
    total_amount DECIMAL(10,2),                -- total amount for booking
    booking_status ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'pending',  -- booking status
    payment_status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',     -- payment status
    booking_reference VARCHAR(50) UNIQUE,      -- unique booking reference code
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- when booking was made
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- last status update
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (showtime_id) REFERENCES showtimes(id) ON DELETE CASCADE
);

-- Movie Reviews table - stores user reviews for movies
CREATE TABLE movie_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique review identifier
    user_id INT NOT NULL,                       -- who wrote the review
    movie_id INT NOT NULL,                      -- which movie is being reviewed
    rating INT NOT NULL,                        -- rating from 1-5 or 1-10
    comment TEXT,                               -- written review/comment
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- when review was posted
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- last edit time
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    -- One review per user per movie
    UNIQUE KEY unique_user_movie_review (user_id, movie_id),
    -- Rating should be between 1-10
    CHECK (rating >= 1 AND rating <= 10)
);

-- Theatre Reviews table - stores user reviews for theatres
CREATE TABLE theatre_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique review identifier
    user_id INT NOT NULL,                       -- who wrote the review
    theatre_id INT NOT NULL,                    -- which theatre is being reviewed
    rating INT NOT NULL,                        -- rating from 1-10
    comment TEXT,                               -- written review/comment
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- when review was posted
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- last edit time
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (theatre_id) REFERENCES theatres(id) ON DELETE CASCADE,
    -- One review per user per theatre
    UNIQUE KEY unique_user_theatre_review (user_id, theatre_id),
    -- Rating should be between 1-10
    CHECK (rating >= 1 AND rating <= 10)
);

-- Indexes for better query performance
CREATE INDEX idx_theatres_city_id ON theatres(city_id);           -- fast lookup of city's theatres
CREATE INDEX idx_showtimes_movie_id ON showtimes(movie_id);       -- fast lookup of movie showtimes
CREATE INDEX idx_showtimes_theatre_id ON showtimes(theatre_id);   -- fast lookup of theatre showtimes
CREATE INDEX idx_showtimes_date ON showtimes(show_date);          -- fast filtering by date
CREATE INDEX idx_bookings_user_id ON bookings(user_id);          -- fast lookup of user's bookings
CREATE INDEX idx_bookings_status ON bookings(booking_status);    -- fast filtering by booking status
CREATE INDEX idx_movie_reviews_movie_id ON movie_reviews(movie_id);     -- fast lookup of movie reviews
CREATE INDEX idx_theatre_reviews_theatre_id ON theatre_reviews(theatre_id); -- fast lookup of theatre reviews

-- Sample queries to demonstrate usage

-- 1. Get all movies playing in a specific city
/*
SELECT DISTINCT m.*, t.name as theatre_name
FROM movies m
JOIN showtimes s ON m.id = s.movie_id
JOIN theatres t ON s.theatre_id = t.id
JOIN cities c ON t.city_id = c.id
WHERE c.name = 'Mumbai'
AND s.show_date >= CURDATE();
*/

-- 2. Get all theatres in a city showing a specific movie
/*
SELECT DISTINCT t.*, c.name as city_name
FROM theatres t
JOIN cities c ON t.city_id = c.id
JOIN showtimes s ON t.id = s.theatre_id
JOIN movies m ON s.movie_id = m.id
WHERE c.name = 'Delhi' 
AND m.title = 'Avengers: Endgame'
AND s.show_date >= CURDATE();
*/

-- 3. Get all showtimes for a movie at a specific theatre
/*
SELECT s.*, m.title, t.name as theatre_name
FROM showtimes s
JOIN movies m ON s.movie_id = m.id
JOIN theatres t ON s.theatre_id = t.id
WHERE m.title = 'Spider-Man' 
AND t.name = 'PVR Cinemas'
AND s.show_date >= CURDATE()
ORDER BY s.show_date, s.show_time;
*/

-- 4. Get user's booking history
/*
SELECT b.*, m.title, t.name as theatre_name, s.show_date, s.show_time
FROM bookings b
JOIN showtimes s ON b.showtime_id = s.id
JOIN movies m ON s.movie_id = m.id
JOIN theatres t ON s.theatre_id = t.id
WHERE b.user_id = 1
ORDER BY b.created_at DESC;
*/

-- 5. Get movie reviews with average rating
/*
SELECT m.title,
       AVG(mr.rating) as average_rating,
       COUNT(mr.id) as total_reviews
FROM movies m
LEFT JOIN movie_reviews mr ON m.id = mr.movie_id
WHERE m.id = 1
GROUP BY m.id, m.title;
*/

-- 6. Update booking status (e.g., confirm after payment)
/*
UPDATE bookings 
SET booking_status = 'confirmed', 
    payment_status = 'completed',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 123;
*/

-- 7. Cancel a booking
/*
UPDATE bookings 
SET booking_status = 'cancelled',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 123;

-- Also update available seats
UPDATE showtimes 
SET available_seats = available_seats + (
    SELECT seats_booked FROM bookings WHERE id = 123
)
WHERE id = (SELECT showtime_id FROM bookings WHERE id = 123);
*/