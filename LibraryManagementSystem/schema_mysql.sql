-- ====================================================================
-- BEL Library Management System - MySQL Database Schema (SQLyog Compatible)
-- UTF-8 / Kannada Unicode Supported (utf8mb4)
-- ====================================================================

CREATE DATABASE IF NOT EXISTS LibraryDb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE LibraryDb;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'Staff',
    staff_number VARCHAR(50) DEFAULT '9876543210',
    staff_internal_number VARCHAR(50) DEFAULT 'BEL-EXT-101',
    perm_books TINYINT(1) DEFAULT 1,
    perm_requests TINYINT(1) DEFAULT 1,
    perm_borrowings TINYINT(1) DEFAULT 1,
    perm_authors TINYINT(1) DEFAULT 0,
    perm_categories TINYINT(1) DEFAULT 0,
    perm_feedback TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Authors Table
CREATE TABLE IF NOT EXISTS Authors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    bio TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS Categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Books Table
CREATE TABLE IF NOT EXISTS Books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(50) NOT NULL UNIQUE,
    publisher VARCHAR(150),
    author_id INT,
    category_id INT,
    copies_available INT DEFAULT 1,
    is_available TINYINT(1) DEFAULT 1,
    price DECIMAL(10,2) DEFAULT 350.00,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES Authors(id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Borrowings Table
CREATE TABLE IF NOT EXISTS Borrowings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    user_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status VARCHAR(50) DEFAULT 'Borrowed',
    FOREIGN KEY (book_id) REFERENCES Books(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. BookRequests Table
CREATE TABLE IF NOT EXISTS BookRequests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    user_id INT NOT NULL,
    staff_name VARCHAR(100),
    staff_number VARCHAR(50),
    staff_internal_number VARCHAR(50),
    book_name VARCHAR(255),
    author_name VARCHAR(100),
    price DECIMAL(10,2) DEFAULT 0.00,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending',
    approved_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES Books(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Feedbacks & Reviews Table (Max 150 words comment enforced)
CREATE TABLE IF NOT EXISTS Feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NULL,
    feedback_type VARCHAR(50) NOT NULL DEFAULT 'website', -- 'website' or 'book'
    rating INT NOT NULL DEFAULT 5,
    comment TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- Initial Seed Data
-- ====================================================================

-- Seed Users with Default Permissions
INSERT INTO Users (username, email, password_hash, role, staff_number, staff_internal_number, perm_books, perm_requests, perm_borrowings, perm_authors, perm_categories, perm_feedback) VALUES
('Admin User', 'admin@bel.com', 'Password123!', 'Admin', '9876543210', 'BEL-ADM-001', 1, 1, 1, 1, 1, 1),
('Librarian Sarah', 'librarian@bel.com', 'Password123!', 'Librarian', '9876543211', 'BEL-LIB-002', 1, 1, 1, 1, 1, 1),
('John Doe', 'john.doe@bel.com', 'Password123!', 'Staff', '9876543212', 'BEL-EXT-101', 1, 1, 1, 0, 0, 1),
('Jane Smith', 'jane.smith@bel.com', 'Password123!', 'Staff', '9876543213', 'BEL-EXT-102', 1, 1, 1, 0, 0, 1)
ON DUPLICATE KEY UPDATE username=VALUES(username), role=VALUES(role);

-- Seed English & Kannada Authors
INSERT INTO Authors (name, bio) VALUES
('Robert C. Martin', 'Software Engineer and Author of Clean Code'),
('Andrew Hunt', 'Co-author of The Pragmatic Programmer'),
('Erich Gamma', 'Co-author of Design Patterns'),
('ಕುವೆಂಪು (Kuvempu)', 'K. V. Puttappa - Legendary Kannada Poet & Jnanapith Laureate'),
('ಎಸ್. ಎಲ್. ಭೈರಪ್ಪ (S. L. Bhyrappa)', 'Renowned Kannada Novelist and Scholar'),
('ಡಾ. ಕೆ. ಶಿವರಾಮ ಕಾರಂತ (Dr. K. Shivarama Karanth)', 'Kannada Writer, Environmentalist, and Jnanapith Laureate');

-- Seed Categories
INSERT INTO Categories (name, description) VALUES
('Software Engineering', 'Books about software development principles and patterns'),
('Computer Science', 'Foundational computer science, algorithms, and logic'),
('Database Management', 'Relational database systems, SQL optimization, and architecture'),
('ಕನ್ನಡ ಸಾಹಿತ್ಯ (Kannada Literature)', 'Classic and modern Kannada literature, novels, and poetry');

-- Seed English & Kannada Books
INSERT INTO Books (title, isbn, publisher, author_id, category_id, copies_available, is_available, price) VALUES
('Clean Code', '978-0132350884', 'Prentice Hall', 1, 1, 5, 1, 450.00),
('The Pragmatic Programmer', '978-0201616224', 'Addison-Wesley', 2, 1, 3, 1, 520.00),
('Design Patterns', '978-0201633610', 'Addison-Wesley', 3, 2, 2, 1, 380.00),
('ಕಾನೂರು ಹೆಗ್ಗಡಿತಿ (Kanooru Heggadithi)', '978-8128001015', 'Sapna Book House', 4, 4, 4, 1, 450.00),
('ಮಲೆಗಳಲ್ಲಿ ಮದುಮಗಳು (Malegalalli Madumagalu)', '978-8128001022', 'Vasantha Prakashana', 4, 4, 5, 1, 520.00),
('ಪರ್ವ (Parva)', '978-8172860100', 'Sahitya Bhandara', 5, 4, 3, 1, 380.00),
('ಮೂಕಜ್ಜಿಯ ಕನಸುಗಳು (Mookajjiya Kanasugalu)', '978-8172860117', 'SBS Publishers', 6, 4, 2, 1, 400.00);

-- Seed Sample Feedback & Book Review
INSERT INTO Feedbacks (user_id, book_id, feedback_type, rating, comment) VALUES
(3, NULL, 'website', 5, 'The library management web system is very clean, fast, and easy to use!'),
(3, 4, 'book', 5, 'ಕಾನೂರು ಹೆಗ್ಗಡಿತಿ ಕಾದಂಬರಿ ಕನ್ನಡ ಸಾಹಿತ್ಯದ ಅತ್ಯುತ್ತಮ ಕೃತಿಗಳಲ್ಲೊಂದು. (Kanooru Heggadithi is a masterpiece of Kannada literature!)');
