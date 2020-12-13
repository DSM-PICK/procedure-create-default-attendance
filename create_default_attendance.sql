USE pick;

DROP PROCEDURE IF EXISTS TEACHER_FROM_FLOOR;
DROP PROCEDURE IF EXISTS SET_TEACHER;
DROP PROCEDURE IF EXISTS CREATE_DEFAULT_ATTENDANCE;

DELIMITER $$
CREATE PROCEDURE TEACHER_FROM_FLOOR(IN floor INT, OUT teacher VARCHAR(16))
    BEGIN
        DECLARE today DATE DEFAULT CURDATE();

        CASE floor
            WHEN 1 THEN
                SET teacher = NULL;
            WHEN 2 THEN
                SELECT second_floor_teacher_id FROM activity WHERE date = today INTO teacher;
            WHEN 3 THEN
                SELECT third_floor_teacher_id FROM activity WHERE date = today INTO teacher;
            WHEN 4 THEN
                SELECT forth_floor_teacher_id FROM activity WHERE date = today INTO teacher;
        END CASE;
    end $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SET_TEACHER(IN schedule VARCHAR(28), OUT teacher VARCHAR(16))
    BEGIN
        DECLARE floor INT;

        IF schedule = 'club' THEN
            SELECT floor FROM club_location
                WHERE location = (SELECT location FROM club INNER JOIN student
                    ON student.club_name = club.name) INTO floor;

            CALL TEACHER_FROM_FLOOR(floor, teacher);
        ELSEIF schedule = 'after-school' THEN
            SET teacher = NULL;
        ELSEIF schedule = 'self-study' THEN
            SELECT floor FROM class INNER JOIN student WHERE student.class_name = class.name INTO floor;

            CALL TEACHER_FROM_FLOOR(floor, teacher);
        END IF;
    end $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE CREATE_DEFAULT_ATTENDANCE (IN day CHAR(3))
    BEGIN
        DECLARE today DATE DEFAULT CURDATE();
        DECLARE student_count INT DEFAULT 0;

        DECLARE all_student_number INT;
        DECLARE schedule VARCHAR(28);

        DECLARE student_number CHAR(4);
        DECLARE teacher VARCHAR(16);

        SELECT COUNT(*) FROM student INTO all_student_number;
        SELECT schedule FROM activity WHERE date = today INTO schedule;

        WHILE student_count < all_student_number DO
            SELECT num FROM student LIMIT student_count, 1 INTO student_number;

            CALL SET_TEACHER(schedule, teacher);

            SET student_count = student_count + 1;
        END WHILE;
    END $$
DELIMITER ;
