-- Airbnb-like App Database Schema

-- Users table - stores all user account information (both guests and hosts)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique user identifier
    email VARCHAR(100) UNIQUE NOT NULL,         -- user email address
    password_hash VARCHAR(255) NOT NULL,        -- encrypted password
    first_name VARCHAR(50) NOT NULL,            -- user's first name
    last_name VARCHAR(50) NOT NULL,             -- user's last name
    phone VARCHAR(15),                          -- user's phone number
    profile_image VARCHAR(255),                 -- profile picture URL
    date_of_birth DATE,                         -- user's birth date
    is_host BOOLEAN DEFAULT FALSE,              -- whether user is a host
    is_verified BOOLEAN DEFAULT FALSE,          -- account verification status
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when account was created
);

-- Cities table - stores city information
CREATE TABLE cities (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique city identifier
    name VARCHAR(100) NOT NULL,                 -- city name (e.g., "Mumbai", "Delhi")
    state VARCHAR(100),                         -- state/province name
    country VARCHAR(100) NOT NULL,             -- country name
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when city was added
);

-- Property Types table - stores different property categories
CREATE TABLE property_types (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique property type identifier
    name VARCHAR(50) NOT NULL,                  -- type name (e.g., "Apartment", "House", "Villa")
    description TEXT,                           -- type description
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when type was added
);

-- Properties table - stores all property listings
CREATE TABLE properties (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique property identifier
    host_id INT NOT NULL,                       -- who owns/manages this property
    property_type_id INT NOT NULL,              -- what type of property it is
    city_id INT NOT NULL,                       -- which city property is in
    title VARCHAR(255) NOT NULL,               -- property listing title
    description TEXT,                          -- detailed property description
    address TEXT NOT NULL,                     -- full property address
    latitude DECIMAL(10, 8),                   -- GPS latitude coordinate
    longitude DECIMAL(11, 8),                  -- GPS longitude coordinate
    bedrooms INT DEFAULT 1,                    -- number of bedrooms
    bathrooms INT DEFAULT 1,                   -- number of bathrooms
    max_guests INT DEFAULT 2,                  -- maximum guests allowed
    price_per_night DECIMAL(10, 2) NOT NULL,  -- nightly rate
    cleaning_fee DECIMAL(10, 2) DEFAULT 0,    -- one-time cleaning fee
    is_active BOOLEAN DEFAULT TRUE,            -- whether property is available for booking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when property was listed
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- last update
    FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (property_type_id) REFERENCES property_types(id),
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

-- Property Images table - stores multiple images for each property
CREATE TABLE property_images (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique image identifier
    property_id INT NOT NULL,                   -- which property this image belongs to
    image_url VARCHAR(255) NOT NULL,           -- image file URL
    is_primary BOOLEAN DEFAULT FALSE,          -- whether this is the main image
    caption VARCHAR(255),                      -- image description/caption
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when image was uploaded
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

-- Amenities table - stores available amenities
CREATE TABLE amenities (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique amenity identifier
    name VARCHAR(100) NOT NULL,                 -- amenity name (e.g., "WiFi", "Pool", "Parking")
    icon VARCHAR(50),                           -- icon identifier for UI
    category VARCHAR(50),                       -- amenity category (e.g., "Basic", "Safety", "Entertainment")
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- when amenity was added
);

-- Property Amenities table - links properties to their amenities (many-to-many)
CREATE TABLE property_amenities (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique relationship identifier
    property_id INT NOT NULL,                   -- which property
    amenity_id INT NOT NULL,                    -- which amenity
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (amenity_id) REFERENCES amenities(id) ON DELETE CASCADE,
    UNIQUE KEY unique_property_amenity (property_id, amenity_id)  -- prevent duplicate amenities
);

-- Bookings table - stores all reservation information
CREATE TABLE bookings (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique booking identifier
    property_id INT NOT NULL,                   -- which property is booked
    guest_id INT NOT NULL,                      -- who made the booking
    check_in_date DATE NOT NULL,               -- start date of stay
    check_out_date DATE NOT NULL,              -- end date of stay
    guests INT NOT NULL,                       -- number of guests
    nights INT NOT NULL,                       -- number of nights (calculated)
    price_per_night DECIMAL(10, 2) NOT NULL,  -- rate at time of booking
    cleaning_fee DECIMAL(10, 2) DEFAULT 0,    -- cleaning fee at time of booking
    total_amount DECIMAL(10, 2) NOT NULL,     -- total cost of booking
    booking_status ENUM('pending', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending',  -- booking status
    payment_status ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',     -- payment status
    booking_reference VARCHAR(50) UNIQUE,      -- unique booking reference code
    special_requests TEXT,                     -- guest's special requests
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- when booking was made
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- last status update
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id) REFERENCES users(id) ON DELETE CASCADE,
    -- Check-out must be after check-in
    CHECK (check_out_date > check_in_date),
    -- Guests must be positive and within property limits
    CHECK (guests > 0)
);

-- Property Reviews table - stores guest reviews for properties
CREATE TABLE property_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique review identifier
    property_id INT NOT NULL,                   -- which property is being reviewed
    guest_id INT NOT NULL,                      -- who wrote the review
    booking_id INT NOT NULL,                    -- which booking this review is for
    overall_rating INT NOT NULL,               -- overall rating (1-5)
    cleanliness_rating INT,                    -- cleanliness rating (1-5)
    communication_rating INT,                  -- host communication rating (1-5)
    checkin_rating INT,                        -- check-in process rating (1-5)
    accuracy_rating INT,                       -- listing accuracy rating (1-5)
    location_rating INT,                       -- location rating (1-5)
    value_rating INT,                          -- value for money rating (1-5)
    comment TEXT,                              -- written review
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when review was posted
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    -- One review per booking
    UNIQUE KEY unique_booking_review (booking_id),
    -- Ratings should be between 1-5
    CHECK (overall_rating >= 1 AND overall_rating <= 5),
    CHECK (cleanliness_rating >= 1 AND cleanliness_rating <= 5),
    CHECK (communication_rating >= 1 AND communication_rating <= 5),
    CHECK (checkin_rating >= 1 AND checkin_rating <= 5),
    CHECK (accuracy_rating >= 1 AND accuracy_rating <= 5),
    CHECK (location_rating >= 1 AND location_rating <= 5),
    CHECK (value_rating >= 1 AND value_rating <= 5)
);

-- Host Reviews table - stores host reviews for guests
CREATE TABLE host_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique review identifier
    host_id INT NOT NULL,                       -- who wrote the review (host)
    guest_id INT NOT NULL,                      -- who is being reviewed (guest)
    booking_id INT NOT NULL,                    -- which booking this review is for
    rating INT NOT NULL,                        -- guest rating (1-5)
    comment TEXT,                               -- written review about guest
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when review was posted
    FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    -- One review per booking from host perspective
    UNIQUE KEY unique_host_booking_review (booking_id, host_id),
    -- Rating should be between 1-5
    CHECK (rating >= 1 AND rating <= 5)
);

-- Wishlists table - stores user saved/favorite properties
CREATE TABLE wishlists (
    id INT PRIMARY KEY AUTO_INCREMENT,           -- unique wishlist identifier
    user_id INT NOT NULL,                       -- who owns this wishlist
    property_id INT NOT NULL,                   -- which property is saved
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- when property was saved
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    -- Prevent duplicate saves
    UNIQUE KEY unique_user_property_wishlist (user_id, property_id)
);

-- Indexes for better query performance
CREATE INDEX idx_properties_city_id ON properties(city_id);           -- fast lookup by city
CREATE INDEX idx_properties_host_id ON properties(host_id);           -- fast lookup by host
CREATE INDEX idx_properties_type_id ON properties(property_type_id);  -- fast lookup by type
CREATE INDEX idx_properties_price ON properties(price_per_night);     -- fast sorting by price
CREATE INDEX idx_properties_active ON properties(is_active);          -- fast filtering active properties
CREATE INDEX idx_bookings_property_id ON bookings(property_id);       -- fast lookup of property bookings
CREATE INDEX idx_bookings_guest_id ON bookings(guest_id);             -- fast lookup of user bookings
CREATE INDEX idx_bookings_dates ON bookings(check_in_date, check_out_date);  -- fast date range queries
CREATE INDEX idx_bookings_status ON bookings(booking_status);         -- fast filtering by status
CREATE INDEX idx_reviews_property_id ON property_reviews(property_id); -- fast lookup of property reviews
CREATE INDEX idx_property_images_property_id ON property_images(property_id); -- fast lookup of property images

-- Sample queries to demonstrate usage

-- 1. Search properties in a city with filters
/*
SELECT p.*, pt.name as property_type, c.name as city_name,
       AVG(pr.overall_rating) as avg_rating,
       COUNT(pr.id) as review_count
FROM properties p
JOIN property_types pt ON p.property_type_id = pt.id
JOIN cities c ON p.city_id = c.id
LEFT JOIN property_reviews pr ON p.id = pr.property_id
WHERE c.name = 'Mumbai'
AND p.is_active = TRUE
AND p.max_guests >= 2
AND p.price_per_night BETWEEN 1000 AND 5000
GROUP BY p.id
HAVING avg_rating >= 4.0 OR avg_rating IS NULL
ORDER BY p.price_per_night ASC;
*/

-- 2. Check property availability for dates
/*
SELECT p.*
FROM properties p
WHERE p.id = 123
AND p.is_active = TRUE
AND p.id NOT IN (
    SELECT DISTINCT property_id 
    FROM bookings 
    WHERE booking_status IN ('confirmed', 'pending')
    AND ((check_in_date <= '2024-12-25' AND check_out_date > '2024-12-20')
         OR (check_in_date < '2024-12-30' AND check_out_date >= '2024-12-25'))
);
*/

-- 3. Get property details with amenities and images
/*
SELECT p.*, 
       GROUP_CONCAT(a.name SEPARATOR ', ') as amenities,
       pi.image_url as primary_image
FROM properties p
LEFT JOIN property_amenities pa ON p.id = pa.property_id
LEFT JOIN amenities a ON pa.amenity_id = a.id
LEFT JOIN property_images pi ON p.id = pi.property_id AND pi.is_primary = TRUE
WHERE p.id = 123
GROUP BY p.id;
*/

-- 4. Get user's booking history
/*
SELECT b.*, p.title, p.address, c.name as city_name,
       CONCAT(h.first_name, ' ', h.last_name) as host_name
FROM bookings b
JOIN properties p ON b.property_id = p.id
JOIN cities c ON p.city_id = c.id
JOIN users h ON p.host_id = h.id
WHERE b.guest_id = 1
ORDER BY b.created_at DESC;
*/

-- 5. Get host's properties with booking stats
/*
SELECT p.*, 
       COUNT(b.id) as total_bookings,
       AVG(pr.overall_rating) as avg_rating,
       SUM(CASE WHEN b.booking_status = 'confirmed' THEN b.total_amount ELSE 0 END) as total_earnings
FROM properties p
LEFT JOIN bookings b ON p.id = b.property_id
LEFT JOIN property_reviews pr ON p.id = pr.property_id
WHERE p.host_id = 1
GROUP BY p.id
ORDER BY total_earnings DESC;
*/

-- 6. Create a booking
/*
INSERT INTO bookings (
    property_id, guest_id, check_in_date, check_out_date, 
    guests, nights, price_per_night, cleaning_fee, total_amount,
    booking_reference
) VALUES (
    123, 456, '2024-12-20', '2024-12-25',
    2, 5, 2000.00, 500.00, 10500.00,
    'BK' + UNIX_TIMESTAMP() + RAND()
);
*/