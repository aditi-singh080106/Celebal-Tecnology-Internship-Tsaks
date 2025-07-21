-- SCD type 0 (fixied no changes allowed)
CREATE PROCEDURE sp_SCD_Type_0
AS
BEGIN
    INSERT INTO dim_customer (CustomerID, Name, Address, PhoneNumber)
    SELECT s.CustomerID, s.Name, s.Address, s.PhoneNumber
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL;
END;
-- SCD type 1 (overwrite )
CREATE PROCEDURE sp_SCD_Type_1
AS
BEGIN
    MERGE dim_customer AS target
    USING stg_customer AS source
    ON target.CustomerID = source.CustomerID
    WHEN MATCHED AND (
        target.Name <> source.Name OR
        target.Address <> source.Address OR
        target.PhoneNumber <> source.PhoneNumber
    )
    THEN
        UPDATE SET
            target.Name = source.Name,
            target.Address = source.Address,
            target.PhoneNumber = source.PhoneNumber
    WHEN NOT MATCHED BY TARGET
    THEN
        INSERT (CustomerID, Name, Address, PhoneNumber)
        VALUES (source.CustomerID, source.Name, source.Address, source.PhoneNumber);
END;
-- SCD tyoe 2 ( history of new row)
CREATE PROCEDURE sp_SCD_Type_2
AS
BEGIN
    DECLARE @CurrentDate DATETIME = GETDATE();


    UPDATE dim_customer
    SET ExpiryDate = @CurrentDate, IsCurrent = 0
    FROM dim_customer d
    JOIN stg_customer s ON d.CustomerID = s.CustomerID
    WHERE d.IsCurrent = 1 AND (
        d.Name <> s.Name OR
        d.Address <> s.Address OR
        d.PhoneNumber <> s.PhoneNumber
    );


    INSERT INTO dim_customer (CustomerID, Name, Address, PhoneNumber, EffectiveDate, ExpiryDate, IsCurrent)
    SELECT s.CustomerID, s.Name, s.Address, s.PhoneNumber, @CurrentDate, NULL, 1
    FROM stg_customer s
    LEFT JOIN dim_customer d
    ON s.CustomerID = d.CustomerID AND d.IsCurrent = 1
    WHERE d.CustomerID IS NULL OR (
        d.Name <> s.Name OR
        d.Address <> s.Address OR
        d.PhoneNumber <> s.PhoneNumber
    );
END;
-- SCD type 3 ( limited history)
CREATE PROCEDURE sp_SCD_Type_3
AS
BEGIN
    MERGE dim_customer AS target
    USING stg_customer AS source
    ON target.CustomerID = source.CustomerID
    WHEN MATCHED AND target.Address <> source.Address
    THEN
        UPDATE SET
            target.PreviousAddress = target.Address,
            target.Address = source.Address
    WHEN NOT MATCHED BY TARGET
    THEN
        INSERT (CustomerID, Name, Address, PreviousAddress)
        VALUES (source.CustomerID, source.Name, source.Address, NULL);
END;
-- SCD  type 4 ( histoy in sep. table)
CREATE PROCEDURE sp_SCD_Type_4
AS
BEGIN
    INSERT INTO hist_customer (CustomerID, Name, Address, PhoneNumber, SnapshotDate)
    SELECT d.CustomerID, d.Name, d.Address, d.PhoneNumber, GETDATE()
    FROM dim_customer d
    JOIN stg_customer s ON d.CustomerID = s.CustomerID
    WHERE d.Name <> s.Name OR d.Address <> s.Address OR d.PhoneNumber <> s.PhoneNumber;

    UPDATE dim_customer
    SET Name = s.Name,
        Address = s.Address,
        PhoneNumber = s.PhoneNumber
    FROM dim_customer d
    JOIN stg_customer s ON d.CustomerID = s.CustomerID;

    INSERT INTO dim_customer (CustomerID, Name, Address, PhoneNumber)
    SELECT s.CustomerID, s.Name, s.Address, s.PhoneNumber
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL;
END;

-- SCD type 6 ( hybrid)
CREATE PROCEDURE sp_SCD_Type_6
AS
BEGIN
    DECLARE @CurrentDate DATETIME = GETDATE();

    UPDATE dim_customer
    SET ExpiryDate = @CurrentDate, IsCurrent = 0
    FROM dim_customer d
    JOIN stg_customer s ON d.CustomerID = s.CustomerID
    WHERE d.IsCurrent = 1 AND (
        d.Name <> s.Name OR
        d.Address <> s.Address OR
        d.PhoneNumber <> s.PhoneNumber
    );

    INSERT INTO dim_customer (CustomerID, Name, Address, PreviousAddress, PhoneNumber, EffectiveDate, ExpiryDate, IsCurrent)
    SELECT 
        s.CustomerID, s.Name, s.Address, d.Address, s.PhoneNumber,
        @CurrentDate, NULL, 1
    FROM stg_customer s
    JOIN dim_customer d ON s.CustomerID = d.CustomerID AND d.IsCurrent = 0
    WHERE s.Address <> d.Address;
END;
