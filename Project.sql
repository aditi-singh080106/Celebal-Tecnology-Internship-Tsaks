CREATE TABLE counttotalworkinhours (
    START_DATE DATE,
    END_DATE DATE,
    NO_OF_HOURS INT
);
DELIMITER //

CREATE PROCEDURE GetWorkHours(
    IN in_start_date DATE,
    IN in_end_date DATE
)
BEGIN
    DECLARE current_date DATE;
    DECLARE total_days INT DEFAULT 0;
    DECLARE dow INT;
    DECLARE sat_count INT;
    DECLARE temp_date DATE;

    SET current_date = in_start_date;

    WHILE current_date <= in_end_date DO
        SET dow = DAYOFWEEK(current_date); 

        SET sat_count = 0;

        IF dow = 7 THEN  
            SET temp_date = DATE_FORMAT(current_date, '%Y-%m-01');  

            WHILE temp_date <= current_date DO
                IF DAYOFWEEK(temp_date) = 7 THEN
                    SET sat_count = sat_count + 1;
                END IF;
                SET temp_date = DATE_ADD(temp_date, INTERVAL 1 DAY);
            END WHILE;
        END IF;

        IF (
              (dow = 1 AND current_date NOT IN (in_start_date, in_end_date)) 
              OR
              (dow = 7 AND sat_count IN (1,2) AND current_date NOT IN (in_start_date, in_end_date)) 
           ) THEN
        ELSE
            SET total_days = total_days + 1;
        END IF;

        SET current_date = DATE_ADD(current_date, INTERVAL 1 DAY);
    END WHILE;

    INSERT INTO counttotalworkinhours (START_DATE, END_DATE, NO_OF_HOURS)
    VALUES (in_start_date, in_end_date, total_days * 24);
END;
//

DELIMITER ;
CALL GetWorkHours('2023-07-01', '2023-07-17');
CALL GetWorkHours('2023-07-12', '2023-07-13');


SELECT * FROM counttotalworkinhours;
