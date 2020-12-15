USE pick;

DROP PROCEDURE IF EXISTS GET_TEACHER_FROM_FLOOR;
DROP PROCEDURE IF EXISTS SET_TEACHER;

DROP PROCEDURE IF EXISTS DIVIDE_STATE_FROM_PERIOD;
DROP PROCEDURE IF EXISTS SET_STATE;

DROP PROCEDURE IF EXISTS SET_DEFAULT_STATE;
DROP PROCEDURE IF EXISTS CREATE_DEFAULT_ATTENDANCE;

DELIMITER $$
CREATE PROCEDURE GET_TEACHER_FROM_FLOOR(IN current_floor INT, OUT teacher VARCHAR(16))
    BEGIN
        CASE current_floor
            WHEN 1 THEN
                SET teacher = NULL;
            WHEN 2 THEN
                SELECT second_floor_teacher_id FROM activity WHERE date = @TODAY INTO teacher;
            WHEN 3 THEN
                SELECT third_floor_teacher_id FROM activity WHERE date = @TODAY INTO teacher;
            WHEN 4 THEN
                SELECT forth_floor_teacher_id FROM activity WHERE date = @TODAY INTO teacher;
        END CASE;
    END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SET_TEACHER(IN student_number CHAR(4), OUT teacher VARCHAR(16))
    BEGIN
        DECLARE current_floor INT DEFAULT 0;

        DECLARE today_schedule VARCHAR(28);

        SELECT schedule FROM activity WHERE date = @TODAY INTO today_schedule;

        IF today_schedule = 'club' THEN
            SELECT floor FROM club_location
                WHERE location = (SELECT location from club
                    WHERE name = (SELECT club_name FROM student WHERE num = student_number)) INTO current_floor;
        ELSEIF today_schedule = 'self-study' THEN
            SELECT floor FROM class WHERE name = (SELECT class_name FROM student WHERE num = student_number) INTO current_floor;
        ELSEIF today_schedule = 'after-school' THEN
            SET teacher = NULL;
        END IF;

        IF current_floor != 0 THEN
            CALL GET_TEACHER_FROM_FLOOR(current_floor, teacher);
        END IF;
    end $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE DIVIDE_STATE_FROM_PERIOD(IN pre_absence_id INT)
    BEGIN
        DECLARE tmp_state CHAR(4) DEFAULT NULL;

        DECLARE _start_period INT;
        DECLARE _end_period INT;

        SELECT start_period FROM tmp_absence WHERE id = pre_absence_id INTO _start_period;
        SELECT end_period FROM tmp_absence WHERE id = pre_absence_id INTO _end_period;
        SELECT state FROM tmp_absence WHERE id = pre_absence_id INTO tmp_state;

        WHILE _start_period <= _end_period DO
            CASE _start_period
                WHEN 7 THEN
                    SET @STATE_7 = tmp_state;
                WHEN 8 THEN
                    SET @STATE_8 = tmp_state;
                WHEN 9 THEN
                    SET @STATE_9 = tmp_state;
                WHEN 10 THEN
                    SET @STATE_10 = tmp_state;
                ELSE BEGIN END;
            END CASE;

            SET _start_period = _start_period + 1;
        END WHILE;
    END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SET_STATE(IN student_number CHAR(4))
    BEGIN
        DECLARE pre_absence_count INT DEFAULT 0;

        DECLARE all_pre_absence_number INT;

        DECLARE pre_absence_id INT;

        INSERT INTO tmp_absence (SELECT id, start_period, end_period, state FROM pre_absence
                                    WHERE student_num = student_number AND
                                          @TODAY BETWEEN start_date AND end_date);

        SELECT COUNT(*) FROM tmp_absence INTO all_pre_absence_number;

        WHILE pre_absence_count < all_pre_absence_number DO
            SELECT id FROM tmp_absence LIMIT pre_absence_count, 1 INTO pre_absence_id;

            CALL DIVIDE_STATE_FROM_PERIOD(pre_absence_id);

            SET pre_absence_count = pre_absence_count + 1;
        END WHILE;

        DELETE FROM tmp_absence WHERE TRUE;
    END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SET_DEFAULT_STATE()
    BEGIN
        SET @STATE_7 = '출석';
        SET @STATE_8 = '출석';
        SET @STATE_9 = '출석';
        SET @STATE_10 = '출석';
    END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE CREATE_DEFAULT_ATTENDANCE (IN day INT)
    BEGIN
        DECLARE student_count INT DEFAULT 0;

        DECLARE all_student_number INT;

        DECLARE student_number CHAR(4);
        DECLARE teacher VARCHAR(16);

        CALL SET_DEFAULT_STATE();

        SET @TODAY = CURDATE();

        DROP TABLE IF EXISTS tmp_absence;
        CREATE TEMPORARY TABLE tmp_absence(id INT, start_period INT, end_period INT, state CHAR(4));

        SELECT COUNT(*) FROM student INTO all_student_number;

        IF day = 0 THEN
            SET day = DAYOFWEEK(@TODAY);
        END IF;

        WHILE student_count < all_student_number DO
            SELECT num FROM student LIMIT student_count, 1 INTO student_number;

            CALL SET_TEACHER(student_number, teacher);
            CALL SET_STATE(student_number);

            IF day = 6 THEN
                INSERT INTO attendance (date, student_num, period, teacher_id, state)
                    VALUES (@TODAY, student_number, 7, teacher, @STATE_7);
            END IF;

            INSERT INTO attendance (date, student_num, period, teacher_id, state)
                    VALUES (@TODAY, student_number, 8, teacher, @STATE_8);
            INSERT INTO attendance (date, student_num, period, teacher_id, state)
                    VALUES (@TODAY, student_number, 9, teacher, @STATE_9);
            INSERT INTO attendance (date, student_num, period, teacher_id, state)
                    VALUES (@TODAY, student_number, 10, teacher, @STATE_10);

            CALL SET_DEFAULT_STATE();

            SET student_count = student_count + 1;
        END WHILE;

        DROP TABLE tmp_absence;
    END $$
DELIMITER ;
