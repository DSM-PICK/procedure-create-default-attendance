USE pick;

DROP PROCEDURE IF EXISTS GET_TEACHER_FROM_FLOOR;
DROP PROCEDURE IF EXISTS SET_TEACHER;

DROP PROCEDURE IF EXISTS SET_STATE;

DROP PROCEDURE IF EXISTS CREATE_DEFAULT_ATTENDANCE;

SET @@TODAY = CURDATE();

DELIMITER $$
CREATE PROCEDURE GET_TEACHER_FROM_FLOOR(IN floor INT, OUT teacher VARCHAR(16))
    BEGIN
        CASE floor
            WHEN 1 THEN
                SET teacher = NULL;
            WHEN 2 THEN
                SELECT second_floor_teacher_id FROM activity WHERE date = @TODAY INTO teacher;
            WHEN 3 THEN
                SELECT third_floor_teacher_id FROM activity WHERE date = @TODAY INTO teacher;
            WHEN 4 THEN
                SELECT forth_floor_teacher_id FROM activity WHERE date = @TODAY INTO teacher;
        END CASE;
    end $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SET_TEACHER(IN schedule VARCHAR(28), OUT teacher VARCHAR(16))
    BEGIN
        DECLARE floor INT DEFAULT 0;

        IF schedule = 'club' THEN
            SELECT floor FROM club_location
                WHERE location = (SELECT location FROM club INNER JOIN student
                    ON student.club_name = club.name) INTO floor;
        ELSEIF schedule = 'self-study' THEN
            SELECT floor FROM class INNER JOIN student WHERE student.class_name = class.name INTO floor;
        ELSEIF schedule = 'after-school' THEN
            SET teacher = NULL;
        END IF;

        IF floor != 0 THEN
            CALL GET_TEACHER_FROM_FLOOR(floor, teacher);
        END IF $$
    end $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE DIVIDE_STATE_FROM_PERIOD(IN pre_absence_id INT, OUT state_7 CHAR(4), state_8 CHAR(4), state_9 CHAR(4), state_10 CHAR(4))
BEGIN
    DECLARE start_period INT;
    DECLARE end_period INT;

    SELECT start_period FROM pre_absence WHERE id = pre_absence_id INTO start_period;
    SELECT end_period FROM pre_absence WHERE id = pre_absence_id INTO end_period;

    WHILE start_period <= end_period DO
        CASE start_period
            WHEN 7 THEN
                SELECT state FROM pre_absence WHERE id = pre_absence_id INTO state_7;
            WHEN 8 THEN
                SELECT state FROM pre_absence WHERE id = pre_absence_id INTO state_8;
            WHEN 9 THEN
                SELECT state FROM pre_absence WHERE id = pre_absence_id INTO state_9;
            WHEN 10 THEN
                SELECT state FROM pre_absence WHERE id = pre_absence_id INTO state_10;
        END CASE;

        SET start_period = start_period + 1;
    END WHILE;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SET_STATE(IN student_number CHAR(4), OUT state_7 CHAR(4), state_8 CHAR(4), state_9 CHAR(4), state_10 CHAR(4))
    BEGIN
        DECLARE pre_absence_count INT DEFAULT 0;

        DECLARE all_pre_absence_number INT;

        DECLARE pre_absence_id INT;

        CREATE TEMPORARY TABLE tmp_absence(id INT, start_period INT, end_period INT, state CHAR(4));

        INSERT INTO tmp_absence (SELECT id, start_period, end_period, state FROM pre_absence
                                    WHERE student_num = student_number AND
                                                        @TODAY BETWEEN start_date AND end_date);

        SELECT COUNT(*) FROM tmp_absence INTO all_pre_absence_number;

        WHILE pre_absence_count < all_pre_absence_number DO
            SELECT id FROM tmp_absence LIMIT pre_absence_count, 1 INTO pre_absence_id;

            CALL DIVIDE_STATE_FROM_PERIOD(pre_absence_id, state_7, state_8, state_9, state_10);

            SET pre_absence_count = pre_absence_count + 1;
        END WHILE;

        DROP TABLE tmp_absence;
    end $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE CREATE_DEFAULT_ATTENDANCE (IN day CHAR(3))
    BEGIN
        DECLARE student_count INT DEFAULT 0;

        DECLARE all_student_number INT;
        DECLARE schedule VARCHAR(28);

        DECLARE student_number CHAR(4);
        DECLARE teacher VARCHAR(16);

        DECLARE state_7 CHAR(4) DEFAULT '출석';
        DECLARE state_8 CHAR(4) DEFAULT '출석';
        DECLARE state_9 CHAR(4) DEFAULT '출석';
        DECLARE state_10 CHAR(4) DEFAULT '출석';

        SELECT COUNT(*) FROM student INTO all_student_number;
        SELECT schedule FROM activity WHERE date = @TODAY INTO schedule;

        WHILE student_count < all_student_number DO
            SELECT num FROM student LIMIT student_count, 1 INTO student_number;

            CALL SET_TEACHER(schedule, teacher);
            CALL SET_STATE(student_number, state_7, state_8, state_9, state_10);

            SET student_count = student_count + 1;
        END WHILE;
    END $$
DELIMITER ;
