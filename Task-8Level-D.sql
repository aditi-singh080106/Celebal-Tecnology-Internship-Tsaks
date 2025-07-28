CREATE TABLE DateDimension (
    SKDate INT PRIMARY KEY,
    KeyDate DATE,
    [Date] DATE,
    CalendarDay INT,
    CalendarMonth INT,
    CalendarQuarter INT,
    CalendarYear INT,
    DayNameLong VARCHAR(20),
    DayNameShort VARCHAR(5),
    DayNumberOfWeek INT,
    DayNumberOfYear INT,
    DaySuffix VARCHAR(5),
    FiscalWeek INT,
    FiscalPeriod INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalYearPeriod VARCHAR(10)
);
CREATE PROCEDURE PopulateDateDimension
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    WITH DateCTE AS (
        SELECT @StartDate AS [Date]
        UNION ALL
        SELECT DATEADD(DAY, 1, [Date])
        FROM DateCTE
        WHERE [Date] < @EndDate
    )
    INSERT INTO DateDimension (
        SKDate, KeyDate, [Date], CalendarDay, CalendarMonth, CalendarQuarter,
        CalendarYear, DayNameLong, DayNameShort, DayNumberOfWeek, DayNumberOfYear,
        DaySuffix, FiscalWeek, FiscalPeriod, FiscalQuarter, FiscalYear, FiscalYearPeriod
    )
    SELECT
        CONVERT(INT, FORMAT([Date], 'yyyyMMdd')) AS SKDate,
        [Date] AS KeyDate,
        [Date],
        DAY([Date]) AS CalendarDay,
        MONTH([Date]) AS CalendarMonth,
        DATEPART(QUARTER, [Date]) AS CalendarQuarter,
        YEAR([Date]) AS CalendarYear,
        DATENAME(WEEKDAY, [Date]) AS DayNameLong,
        LEFT(DATENAME(WEEKDAY, [Date]), 3) AS DayNameShort,
        DATEPART(WEEKDAY, [Date]) AS DayNumberOfWeek,
        DATEPART(DAYOFYEAR, [Date]) AS DayNumberOfYear,
        CAST(DAY([Date]) AS VARCHAR) + 
            CASE 
                WHEN DAY([Date]) IN (11,12,13) THEN 'th'
                WHEN DAY([Date]) % 10 = 1 THEN 'st'
                WHEN DAY([Date]) % 10 = 2 THEN 'nd'
                WHEN DAY([Date]) % 10 = 3 THEN 'rd'
                ELSE 'th'
            END AS DaySuffix,
        DATEPART(WEEK, [Date]) AS FiscalWeek,
        MONTH([Date]) AS FiscalPeriod,
        DATEPART(QUARTER, [Date]) AS FiscalQuarter,
        YEAR([Date]) AS FiscalYear,
        CAST(YEAR([Date]) AS VARCHAR) + RIGHT('0' + CAST(MONTH([Date]) AS VARCHAR), 2) AS FiscalYearPeriod
    FROM DateCTE
    OPTION (MAXRECURSION 366);
END;
EXEC PopulateDateDimension '2020-07-14';
