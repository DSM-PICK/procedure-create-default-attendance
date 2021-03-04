SET GLOBAL event_scheduler = ON;
DROP EVENT IF EXISTS default_attendance;
DELIMITER $$
CREATE EVENT IF NOT EXISTS default_attendance
    ON SCHEDULE
        EVERY 1 DAY STARTS CONCAT(CURDATE(), ' ', '15:00:00')
    ON COMPLETION PRESERVE ENABLE
        COMMENT '기본 출석 데이터 삽입 스케줄러'
    DO
    BEGIN
        CALL CREATE_DEFAULT_ATTENDANCE(0, false);
    END $$
DELIMITER ;
