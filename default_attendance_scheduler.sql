SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS default_attendance;
DELIMITER $$
CREATE EVENT IF NOT EXISTS default_attendance
    ON SCHEDULE
        EVERY 1 DAY STARTS CONCAT(CURDATE() + INTERVAL 1 DAY, ' ', '00:00:00')
    ON COMPLETION PRESERVE ENABLE
        COMMENT '기본 출석 데이터 삽입 스케줄러'
    DO
    BEGIN
        DECLARE today INT DEFAULT DAYOFWEEK(CURDATE());

        IF today != 1 AND today != 7 THEN
            CALL CREATE_DEFAULT_ATTENDANCE(0);
        END IF;
    END $$
DELIMITER ;
