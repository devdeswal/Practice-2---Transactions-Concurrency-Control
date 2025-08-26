-- =============================
-- Part A: Prevent Duplicate Enrollments
-- =============================

DROP TABLE IF EXISTS StudentEnrollments;

CREATE TABLE StudentEnrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(100) NOT NULL,
    course_id VARCHAR(10) NOT NULL,
    enrollment_date DATE NOT NULL,
    CONSTRAINT unique_enrollment UNIQUE(student_name, course_id)
);

-- Insert initial sample data
INSERT INTO StudentEnrollments (student_name, course_id, enrollment_date)
VALUES 
('Ashish', 'CSE101', '2024-07-01'),
('Smaran', 'CSE102', '2024-07-01'),
('Vaibhav', 'CSE101', '2024-07-01');

-- ✅ Try inserting a duplicate (will fail due to unique constraint)
-- User 1 (works)
START TRANSACTION;
INSERT INTO StudentEnrollments (student_name, course_id, enrollment_date)
VALUES ('Ashish', 'CSE101', '2024-07-01');
COMMIT;

-- User 2 (fails - duplicate entry)
START TRANSACTION;
INSERT INTO StudentEnrollments (student_name, course_id, enrollment_date)
VALUES ('Ashish', 'CSE101', '2024-07-01');
-- Expect: ERROR 1062 Duplicate entry
ROLLBACK;


-- =============================
-- Part B: Row Locking with SELECT FOR UPDATE
-- =============================

-- Session 1 (User A):
START TRANSACTION;
SELECT * FROM StudentEnrollments
WHERE student_name = 'Ashish' AND course_id = 'CSE101'
FOR UPDATE;
-- Row is locked until COMMIT/ROLLBACK

-- (Pause here - keep transaction open)

-- Session 2 (User B tries while User A’s tx is open):
START TRANSACTION;
UPDATE StudentEnrollments
SET enrollment_date = '2024-07-05'
WHERE student_name = 'Ashish' AND course_id = 'CSE101';
-- 🚨 This will be BLOCKED until User A commits/rollbacks

-- Session 1 (User A finishes):
COMMIT;

-- Now Session 2 query executes and can COMMIT.


-- =============================
-- Part C: Locking Preserves Consistency
-- =============================

-- Session 1 (User A):
START TRANSACTION;
SELECT * FROM StudentEnrollments
WHERE student_name = 'Ashish' AND course_id = 'CSE101'
FOR UPDATE;

UPDATE StudentEnrollments
SET enrollment_date = '2024-07-10'
WHERE student_name = 'Ashish' AND course_id = 'CSE101';

COMMIT;

-- Session 2 (User B runs in parallel):
START TRANSACTION;
SELECT * FROM StudentEnrollments
WHERE student_name = 'Ashish' AND course_id = 'CSE101'
FOR UPDATE;
-- 🚨 Waits until User A commits

UPDATE StudentEnrollments
SET enrollment_date = '2024-07-15'
WHERE student_name = 'Ashish' AND course_id = 'CSE101';

COMMIT;

-- ✅ Final Result:
-- enrollment_date = '2024-07-15'
-- Changes are serialized → no lost updates.
