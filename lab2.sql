-- Database creation
CREATE DATABASE IF NOT EXISTS school_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE school_db;

-- Table: instructor
CREATE TABLE IF NOT EXISTS instructor (
    instructor_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    birth_date DATE NULL,
    CONSTRAINT chk_instructor_name CHECK (LENGTH(last_name) > 0)
) ENGINE=InnoDB;

-- Table: course
CREATE TABLE IF NOT EXISTS course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    code CHAR(13) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    instructor_ref INT NOT NULL,
    CONSTRAINT fk_course_instructor FOREIGN KEY (instructor_ref)
        REFERENCES instructor(instructor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_course_code CHECK (code REGEXP '^[0-9]{13}$')
) ENGINE=InnoDB;

-- Table: student
CREATE TABLE IF NOT EXISTS student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    email_address VARCHAR(150) NOT NULL UNIQUE,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT chk_student_email CHECK (email_address LIKE '%@%.%')
) ENGINE=InnoDB;

-- Table: enrollment
CREATE TABLE IF NOT EXISTS enrollment (
    course_ref INT NOT NULL,
    student_ref INT NOT NULL,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completion_date DATE NULL,
    PRIMARY KEY (course_ref, student_ref, start_date),
    CONSTRAINT fk_enrollment_course FOREIGN KEY (course_ref)
        REFERENCES course(course_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_enrollment_student FOREIGN KEY (student_ref)
        REFERENCES student(student_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_enrollment_dates CHECK (completion_date IS NULL OR completion_date >= start_date)
) ENGINE=InnoDB;

-- Additional Indexes
ALTER TABLE course ADD INDEX idx_course_active (is_active);
ALTER TABLE enrollment ADD INDEX idx_enrollment_completion (completion_date);

-- Trigger: Insert Enrollment
DELIMITER $$

CREATE TRIGGER trg_enrollment_insert BEFORE INSERT ON enrollment
FOR EACH ROW
BEGIN
    IF (SELECT is_active FROM course WHERE course_id = NEW.course_ref) = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The requested course is not active.';
    END IF;

    UPDATE course SET is_active = FALSE WHERE course_id = NEW.course_ref;
END$$

DELIMITER ;

-- Trigger: Update Enrollment
DELIMITER $$

CREATE TRIGGER trg_enrollment_update AFTER UPDATE ON enrollment
FOR EACH ROW
BEGIN
    IF NEW.completion_date IS NOT NULL THEN
        UPDATE course SET is_active = TRUE WHERE course_id = NEW.course_ref;
    END IF;
END$$

DELIMITER ;
