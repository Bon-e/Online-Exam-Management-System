
--  Table Definitions with Sequences and Triggers


CREATE TABLE Users (
    User_ID NUMBER PRIMARY KEY,
    Name VARCHAR2(100),
    Email VARCHAR2(100) UNIQUE NOT NULL,
    Password VARCHAR2(100) NOT NULL,
    Role VARCHAR2(20) CHECK (Role IN ('Student', 'Instructor', 'Admin'))
);
CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_users
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
  SELECT seq_users.NEXTVAL INTO :NEW.User_ID FROM dual;
END;
/


CREATE TABLE Courses (
    Course_ID NUMBER PRIMARY KEY,
    Course_Name VARCHAR2(100) NOT NULL,
    Instructor_ID NUMBER,
    CONSTRAINT fk_course_instructor FOREIGN KEY (Instructor_ID) REFERENCES Users(User_ID)
);
CREATE SEQUENCE seq_courses START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_courses
BEFORE INSERT ON Courses
FOR EACH ROW
BEGIN
  SELECT seq_courses.NEXTVAL INTO :NEW.Course_ID FROM dual;
END;
/


CREATE TABLE Enrollments (
    Enrollment_ID NUMBER PRIMARY KEY,
    User_ID NUMBER,
    Course_ID NUMBER,
    Enrollment_Date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_enroll_user FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
    CONSTRAINT fk_enroll_course FOREIGN KEY (Course_ID) REFERENCES Courses(Course_ID)
);
CREATE SEQUENCE seq_enrollments START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_enrollments
BEFORE INSERT ON Enrollments
FOR EACH ROW
BEGIN
  SELECT seq_enrollments.NEXTVAL INTO :NEW.Enrollment_ID FROM dual;
END;
/


CREATE TABLE Exams (
    Exam_ID NUMBER PRIMARY KEY,
    Course_ID NUMBER,
    Exam_Title VARCHAR2(100),
    Exam_Date DATE,
    Start_Time TIMESTAMP,
    End_Time TIMESTAMP,
    Duration NUMBER,
    CONSTRAINT fk_exam_course FOREIGN KEY (Course_ID) REFERENCES Courses(Course_ID)
);
CREATE SEQUENCE seq_exams START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_exams
BEFORE INSERT ON Exams
FOR EACH ROW
BEGIN
  SELECT seq_exams.NEXTVAL INTO :NEW.Exam_ID FROM dual;
END;
/


CREATE TABLE Questions (
    Question_ID NUMBER PRIMARY KEY,
    Exam_ID NUMBER,
    Question_Text VARCHAR2(500),
    Difficulty_Level VARCHAR2(10) CHECK (Difficulty_Level IN ('Easy', 'Medium', 'Hard')),
    Correct_Option_ID NUMBER,
    CONSTRAINT fk_question_exam FOREIGN KEY (Exam_ID) REFERENCES Exams(Exam_ID)
);
CREATE SEQUENCE seq_questions START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_questions
BEFORE INSERT ON Questions
FOR EACH ROW
BEGIN
  SELECT seq_questions.NEXTVAL INTO :NEW.Question_ID FROM dual;
END;
/


CREATE TABLE Options (
    Option_ID NUMBER PRIMARY KEY,
    Question_ID NUMBER,
    Option_Text VARCHAR2(300),
    CONSTRAINT fk_option_question FOREIGN KEY (Question_ID) REFERENCES Questions(Question_ID)
);
CREATE SEQUENCE seq_options START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_options
BEFORE INSERT ON Options
FOR EACH ROW
BEGIN
  SELECT seq_options.NEXTVAL INTO :NEW.Option_ID FROM dual;
END;
/


ALTER TABLE Questions ADD CONSTRAINT fk_correct_option FOREIGN KEY (Correct_Option_ID) REFERENCES Options(Option_ID);


CREATE TABLE Exam_Attempts (
    Attempt_ID NUMBER PRIMARY KEY,
    User_ID NUMBER,
    Exam_ID NUMBER,
    Start_Time TIMESTAMP,
    End_Time TIMESTAMP,
    Score NUMBER,
    Status VARCHAR2(20),
    CONSTRAINT fk_attempt_user FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
    CONSTRAINT fk_attempt_exam FOREIGN KEY (Exam_ID) REFERENCES Exams(Exam_ID)
);
CREATE SEQUENCE seq_attempts START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_attempts
BEFORE INSERT ON Exam_Attempts
FOR EACH ROW
BEGIN
  SELECT seq_attempts.NEXTVAL INTO :NEW.Attempt_ID FROM dual;
END;
/


CREATE TABLE Answers (
    Answer_ID NUMBER PRIMARY KEY,
    Attempt_ID NUMBER,
    Question_ID NUMBER,
    Selected_Option_ID NUMBER,
    Is_Correct CHAR(1) CHECK (Is_Correct IN ('Y', 'N')),
    CONSTRAINT fk_answer_attempt FOREIGN KEY (Attempt_ID) REFERENCES Exam_Attempts(Attempt_ID),
    CONSTRAINT fk_answer_question FOREIGN KEY (Question_ID) REFERENCES Questions(Question_ID),
    CONSTRAINT fk_answer_option FOREIGN KEY (Selected_Option_ID) REFERENCES Options(Option_ID)
);
CREATE SEQUENCE seq_answers START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_answers
BEFORE INSERT ON Answers
FOR EACH ROW
BEGIN
  SELECT seq_answers.NEXTVAL INTO :NEW.Answer_ID FROM dual;
END;
/


CREATE TABLE Logs (
    Log_ID NUMBER PRIMARY KEY,
    User_ID NUMBER,
    Login_Time TIMESTAMP,
    Logout_Time TIMESTAMP,
    Session_Change VARCHAR2(10),
    CONSTRAINT fk_log_user FOREIGN KEY (User_ID) REFERENCES Users(User_ID)
);
CREATE SEQUENCE seq_logs START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_logs
BEFORE INSERT ON Logs
FOR EACH ROW
BEGIN
  SELECT seq_logs.NEXTVAL INTO :NEW.Log_ID FROM dual;
END;
/


CREATE TABLE Result_Reports (
    Report_ID NUMBER PRIMARY KEY,
    Exam_ID NUMBER,
    User_ID NUMBER,
    Percentile NUMBER,
    Rank NUMBER,
    Feedback VARCHAR2(300),
    CONSTRAINT fk_report_exam FOREIGN KEY (Exam_ID) REFERENCES Exams(Exam_ID),
    CONSTRAINT fk_report_user FOREIGN KEY (User_ID) REFERENCES Users(User_ID)
);
CREATE SEQUENCE seq_reports START WITH 1 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trg_reports
BEFORE INSERT ON Result_Reports
FOR EACH ROW
BEGIN
  SELECT seq_reports.NEXTVAL INTO :NEW.Report_ID FROM dual;
END;
/

-- the code after this is tha writen in PL/SQL procedure to login_user

CREATE OR REPLACE PROCEDURE login_user (
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_role OUT VARCHAR2
) AS
BEGIN
    SELECT Role INTO p_role
    FROM Users
    WHERE Email = p_email AND Password = p_password;

    -- Log the login
    INSERT INTO LoginLog (Email, Role)
    VALUES (p_email, p_role);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_role := 'Invalid';
END;
/

SET SERVEROUTPUT ON;

DECLARE
    v_role VARCHAR2(20);
BEGIN
    exam_user.login_user('charlie@example.com', 'charliepass', v_role);
    DBMS_OUTPUT.PUT_LINE('Role: ' || v_role);
END;
/

--cretating login table,and modifying the procedure to log succesful logins
    LogID NUMBER PRIMARY KEY,
    Email VARCHAR2(100),
    Role VARCHAR2(20),
    LoginTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
/

CREATE SEQUENCE LoginLog_seq START WITH 1 INCREMENT BY 1;
/

CREATE OR REPLACE TRIGGER trg_LoginLog_before_insert
BEFORE INSERT ON LoginLog
FOR EACH ROW
BEGIN
    SELECT LoginLog_seq.NEXTVAL INTO :NEW.LogID FROM dual;
END;
/
CREATE OR REPLACE PROCEDURE login_user (
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_role OUT VARCHAR2
) AS
BEGIN
    SELECT Role INTO p_role
    FROM Users
    WHERE Email = p_email AND Password = p_password;

    INSERT INTO LoginLog (Email, Role)
    VALUES (p_email, p_role);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_role := 'Invalid';
END;
/
INSERT INTO Users (Name, Email, Password, Role)
VALUES ('Charlie', 'charlie@example.com', 'charliepass', 'Student');
COMMIT;
/
SET SERVEROUTPUT ON;

DECLARE
    v_role VARCHAR2(20);
BEGIN
    exam_user.login_user('charlie@example.com', 'charliepass', v_role);
    DBMS_OUTPUT.PUT_LINE('Returned role: ' || v_role);
END;
/
SELECT * FROM LoginLog ORDER BY LoginTime DESC;

-- now we are going to create course registration procedure
--by checking if the user and course exist,check if already registered, insert into registration table
CREATE OR REPLACE PROCEDURE register_course (
    p_user_id   IN NUMBER,
    p_course_id IN NUMBER,
    p_result    OUT VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    -- 1) Check if already enrolled
    SELECT COUNT(*) INTO v_count
      FROM Enrollments
     WHERE User_ID   = p_user_id
       AND Course_ID = p_course_id;

    IF v_count > 0 THEN
        p_result := 'Already enrolled';
        RETURN;
    END IF;

    -- 2) Enroll the student
    INSERT INTO Enrollments (User_ID, Course_ID)
    VALUES (p_user_id, p_course_id);

    COMMIT;

    p_result := 'Enrollment successful';

EXCEPTION
    WHEN OTHERS THEN
        -- Capture unexpected errors
        p_result := 'Error: ' || SQLERRM;
END register_course;
/

SET SERVEROUTPUT ON;

DECLARE
    v_result VARCHAR2(50);
BEGIN
    -- Try enrolling Charlie (User_ID = 3) into Intro to Databases (Course_ID = 1)
    exam_user.register_course(3, 1, v_result);
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/

INSERT INTO Users (User_ID, Name, Email, Password, Role)
VALUES (3, 'Charlie', 'charlie@example.com', 'charliepass', 'Student');

INSERT INTO Courses (Course_ID, CourseName, Instructor)
VALUES (1, 'Intro to Databases', 'Dr. Smith');

COMMIT;
/

SET SERVEROUTPUT ON;

DECLARE
    v_result VARCHAR2(200);
BEGIN
    exam_user.register_course(3, 1, v_result);
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/

-- to list the enrolled courses by using procedural
CREATE OR REPLACE PROCEDURE test_output AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello from Oracle 11g!');
END;
/
SET SERVEROUTPUT ON;
BEGIN
    test_output;
END;
/
CREATE OR REPLACE PROCEDURE get_enrollments_by_user (
    p_user_id IN NUMBER
) AS
BEGIN
    FOR r IN (
        SELECT Course_ID FROM Enrollments WHERE User_ID = p_user_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Enrolled Course ID: ' || r.Course_ID);
    END LOOP;
END;
/
BEGIN
    exam_user.get_enrollments_by_user(3);
END;
/
--to list all courses procedure,just users can also see what's available
CREATE OR REPLACE PROCEDURE list_courses AS
BEGIN
  FOR rec IN (
    SELECT Course_ID, CourseName, Instructor FROM Courses
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(
      'ID: '  rec.Course_ID  ', Name: '  rec.CourseName  ', Instructor: ' || rec.Instructor
    );
  END LOOP;
END;
/

-- drop course this query removes a record from the enrollments table
CREATE OR REPLACE PROCEDURE drop_course (
    p_user_id IN NUMBER,
    p_course_id IN NUMBER,
    p_result OUT VARCHAR2
) AS
BEGIN
    DELETE FROM Enrollments
    WHERE User_ID = p_user_id AND Course_ID = p_course_id;

    IF SQL%ROWCOUNT > 0 THEN
        p_result := 'Dropped Successfully';
    ELSE
        p_result := 'Enrollment Not Found';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_result := 'Error: ' || SQLERRM;
END;
/
-- testing it
SET SERVEROUTPUT ON;
DECLARE
    v_result VARCHAR2(50);
BEGIN
    drop_course(3, 1, v_result); -- Example: Charlie drops Course 1
    DBMS_OUTPUT.PUT_LINE(v_result);
END;
/
-- view student enrollment
CREATE OR REPLACE PROCEDURE get_user_enrollments (
    p_user_id IN NUMBER
) AS
BEGIN
    FOR rec IN (
        SELECT c.Title, c.Instructor
        FROM Enrollments e
        JOIN Courses c ON e.Course_ID = c.Course_ID
        WHERE e.User_ID = p_user_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Course: '  rec.Title  ', Instructor: ' || rec.Instructor);
    END LOOP;
END;
/
-- view all courses
CREATE OR REPLACE PROCEDURE get_user_enrollments (
    p_user_id IN NUMBER
) AS
BEGIN
    FOR rec IN (
        SELECT c.Title, c.Instructor
        FROM Enrollments e
        JOIN Courses c ON e.Course_ID = c.Course_ID
        WHERE e.User_ID = p_user_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Course: '  rec.Title  ', Instructor: ' || rec.Instructor);
    END LOOP;
END;
/
-- view all students in a course
CREATE OR REPLACE PROCEDURE list_students_by_course (
    p_course_id IN NUMBER
) AS
BEGIN
    FOR rec IN (
        SELECT u.FullName, u.Email
        FROM Enrollments e
        JOIN Users u ON e.User_ID = u.User_ID
        WHERE e.Course_ID = p_course_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Student: '  rec.FullName  ', Email: ' || rec.Email);
    END LOOP;
END;
/
-- to view all loging logs
CREATE OR REPLACE PROCEDURE show_login_logs IS
BEGIN
    FOR rec IN (
        SELECT LogID, Email, Role, TO_CHAR(LoginTime, 'YYYY-MM-DD HH24:MI:SS') AS Time
        FROM LoginLog
        ORDER BY LoginTime DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('['  rec.Time  '] '  rec.Email  ' ('  rec.Role  ')');
    END LOOP;
END;
/
-- populating data( sample enties)
-- Users
INSERT INTO Users (User_ID, FullName, Email, Password, Role) VALUES (1, 'Alice Johnson', 'alice@example.com', 'alicepass', 'Student');
INSERT INTO Users (User_ID, FullName, Email, Password, Role) VALUES (2, 'Bob Smith', 'bob@example.com', 'bobpass', 'Instructor');
INSERT INTO Users (User_ID, FullName, Email, Password, Role) VALUES (3, 'Charlie Brown', 'charlie@example.com', 'charliepass', 'Student');

-- Courses
INSERT INTO Courses (Course_ID, Title, Instructor) VALUES (1, 'Intro to Databases', 'Dr. Smith');
INSERT INTO Courses (Course_ID, Title, Instructor) VALUES (2, 'PL/SQL Basics', 'Dr. Alice');

COMMIT;

















