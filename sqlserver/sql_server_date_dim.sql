/********************************************************************************************/
--Adapted from http://www.codeproject.com/Articles/647950/Create-and-Populate-Date-Dimension-for-Data-Wareho
--for Australian dates and holidays
--Does not handle Easter & Queens Bday. Separate python script creates UPDATE statements for Easter.

BEGIN TRY
	DROP TABLE [dbo].[calendar]
END TRY

BEGIN CATCH
	/*No Action*/
END CATCH

/**********************************************************************************/

CREATE TABLE [dbo].[calendar] (
  [DateKey] INT primary key,
	[Date] DATETIME,
	[FullDateAUS] CHAR(10), -- Date in DD-MM-YYYY format
	[DayOfMonth] VARCHAR(2), -- Field will hold day number of Month
	[DaySuffix] VARCHAR(4), -- Apply suffix as 1st, 2nd ,3rd etc
	[DayName] VARCHAR(9), -- Contains name of the day, Sunday, Monday
	[DayOfWeekAUS] CHAR(1),-- First Day Sunday=1 and Saturday=7
	[DayOfWeekInMonth] VARCHAR(2), --1st Monday or 2nd Monday in Month
	[DayOfWeekInYear] VARCHAR(2),
	[DayOfQuarter] VARCHAR(3),
	[DayOfYear] VARCHAR(3),
	[WeekOfMonth] VARCHAR(1),-- Week Number of Month
	[WeekOfQuarter] VARCHAR(2), --Week Number of the Quarter
	[WeekOfYear] VARCHAR(2),--Week Number of the Year
	[Month] VARCHAR(2), --Number of the Month 1 to 12
	[MonthName] VARCHAR(9),--January, February etc
	[MonthOfQuarter] VARCHAR(2),-- Month Number belongs to Quarter
	[Quarter] CHAR(1),
	[QuarterName] VARCHAR(9),--First,Second..
	[Year] CHAR(4),-- Year value of Date stored in Row
	[YearName] CHAR(7), --CY 2012,CY 2013
	[MonthYear] CHAR(10), --Jan-2013,Feb-2013
	[MMYYYY] CHAR(6),
	[FirstDayOfMonth] DATETIME,
	[LastDayOfMonth] DATETIME,
	[FirstDayOfQuarter] DATETIME,
	[LastDayOfQuarter] DATETIME,
	[FirstDayOfYear] DATETIME,
	[LastDayOfYear] DATETIME,
	[IsHolidayAUS] BIT,-- Flag 1=National Holiday, 0-No National Holiday
	[IsWeekday] BIT,-- 0=Weekend ,1=Weekday
	[HolidayAUS] VARCHAR(50),--Name of Holiday in AUS
)

--Specify Start Date and End date here
--Value of Start Date Must be Less than Your End Date

DECLARE @StartDate AS DATETIME
SET @StartDate = '1901-01-01' --Starting value of Date Range
DECLARE @EndDate AS DATETIME
SET @EndDate = '2999-12-31' --End Value of Date Range

--Temporary Variables To Hold the Values During Processing of Each Date of Year
DECLARE
	@DayOfWeekInMonth INT,
	@DayOfWeekInYear INT,
	@DayOfQuarter INT,
	@WeekOfMonth INT,
	@CurrentYear INT,
	@CurrentMonth INT,
	@CurrentQuarter INT

/*Table Data type to store the day of week count for the month and year*/
DECLARE @DayOfWeek TABLE (
  DOW INT,
  MonthCount INT,
  QuarterCount INT,
  YearCount INT
)

INSERT INTO @DayOfWeek VALUES (1, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (2, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (3, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (4, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (5, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (6, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (7, 0, 0, 0)

--Extract and assign various parts of Values from Current Date to Variable

DECLARE @CurrentDate AS DATETIME
SET @CurrentDate = @StartDate
SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

/********************************************************************************************/
--Proceed only if Start Date(Current date ) is less than End date you specified above

WHILE @CurrentDate < @EndDate
BEGIN

/*Begin day of week logic*/

  /*Check for Change in Month of the Current date if Month changed then
  Change variable value*/
	IF @CurrentMonth != DATEPART(MM, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET MonthCount = 0
		SET @CurrentMonth = DATEPART(MM, @CurrentDate)
	END

  /* Check for Change in Quarter of the Current date if Quarter changed then change
   Variable value*/
	IF @CurrentQuarter != DATEPART(QQ, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET QuarterCount = 0
		SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)
	END

        /* Check for Change in Year of the Current date if Year changed then change
         Variable value*/
	IF @CurrentYear != DATEPART(YY, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET YearCount = 0
		SET @CurrentYear = DATEPART(YY, @CurrentDate)
	END

        -- Set values in table data type created above from variables
	UPDATE @DayOfWeek
	SET
		MonthCount = MonthCount + 1,
		QuarterCount = QuarterCount + 1,
		YearCount = YearCount + 1
	WHERE DOW = DATEPART(DW, @CurrentDate)

	SELECT
		@DayOfWeekInMonth = MonthCount,
		@DayOfQuarter = QuarterCount,
		@DayOfWeekInYear = YearCount
	FROM @DayOfWeek
	WHERE DOW = DATEPART(DW, @CurrentDate)

/*End day of week logic*/


/* Populate Your Dimension Table with values*/

	INSERT INTO [dbo].[calendar]
	SELECT
		CONVERT (char(8),@CurrentDate,112) as DateKey,
		@CurrentDate AS "Datetime",
		CONVERT (char(10),@CurrentDate,103) as FullDateAUS,
		DATEPART(DD, @CurrentDate) AS DayOfMonth,
		--Apply Suffix values like 1st, 2nd 3rd etc..
		CASE
			WHEN DATEPART(DD,@CurrentDate) IN (11,12,13)
			THEN CAST(DATEPART(DD,@CurrentDate) AS VARCHAR) + 'th'
			WHEN RIGHT(DATEPART(DD,@CurrentDate),1) = 1
			THEN CAST(DATEPART(DD,@CurrentDate) AS VARCHAR) + 'st'
			WHEN RIGHT(DATEPART(DD,@CurrentDate),1) = 2
			THEN CAST(DATEPART(DD,@CurrentDate) AS VARCHAR) + 'nd'
			WHEN RIGHT(DATEPART(DD,@CurrentDate),1) = 3
			THEN CAST(DATEPART(DD,@CurrentDate) AS VARCHAR) + 'rd'
			ELSE CAST(DATEPART(DD,@CurrentDate) AS VARCHAR) + 'th'
			END AS DaySuffix,

		DATENAME(DW, @CurrentDate) AS DayName,
		DATEPART(DW, @CurrentDate) AS DayOfWeekAUS,

		@DayOfWeekInMonth AS DayOfWeekInMonth,
		@DayOfWeekInYear AS DayOfWeekInYear,
		@DayOfQuarter AS DayOfQuarter,
		DATEPART(DY, @CurrentDate) AS DayOfYear,
		DATEPART(WW, @CurrentDate) + 1 - DATEPART(WW, CONVERT(VARCHAR,		DATEPART(MM, @CurrentDate)) + '/1/'
+ CONVERT(VARCHAR,		DATEPART(YY, @CurrentDate))) AS WeekOfMonth,
		(DATEDIFF(DD, DATEADD(QQ, DATEDIFF(QQ, 0, @CurrentDate), 0),
		@CurrentDate) / 7) + 1 AS WeekOfQuarter,
		DATEPART(WW, @CurrentDate) AS WeekOfYear,
		DATEPART(MM, @CurrentDate) AS Month,
		DATENAME(MM, @CurrentDate) AS MonthName,
		CASE
			WHEN DATEPART(MM, @CurrentDate) IN (1, 4, 7, 10) THEN 1
			WHEN DATEPART(MM, @CurrentDate) IN (2, 5, 8, 11) THEN 2
			WHEN DATEPART(MM, @CurrentDate) IN (3, 6, 9, 12) THEN 3
			END AS MonthOfQuarter,
		DATEPART(QQ, @CurrentDate) AS Quarter,
		CASE DATEPART(QQ, @CurrentDate)
			WHEN 3 THEN 'First'
			WHEN 4 THEN 'Second'
			WHEN 1 THEN 'Third'
			WHEN 2 THEN 'Fourth'
			END AS QuarterName,
		DATEPART(YEAR, @CurrentDate) AS Year,
		'CY ' + CONVERT(VARCHAR, DATEPART(YEAR, @CurrentDate)) AS YearName,
		LEFT(DATENAME(MM, @CurrentDate), 3) + '-' + CONVERT(VARCHAR,
		DATEPART(YY, @CurrentDate)) AS MonthYear,
		CONVERT(char(8),@CurrentDate,112)/100 AS YYYYMM,
		CONVERT(DATETIME, CONVERT(DATETIME, DATEADD(DD, - (DATEPART(DD,
		@CurrentDate) - 1), @CurrentDate))) AS FirstDayOfMonth,
		CONVERT(DATETIME, CONVERT(DATETIME, DATEADD(DD, - (DATEPART(DD,
		(DATEADD(MM, 1, @CurrentDate)))), DATEADD(MM, 1,
		@CurrentDate)))) AS LastDayOfMonth,
		DATEADD(QQ, DATEDIFF(QQ, 0, @CurrentDate), 0) AS FirstDayOfQuarter,
		DATEADD(QQ, DATEDIFF(QQ, -1, @CurrentDate), -1) AS LastDayOfQuarter,
		CONVERT(DATETIME, '01/01/' + CONVERT(VARCHAR, DATEPART(YY,
		@CurrentDate))) AS FirstDayOfYear,
		CONVERT(DATETIME, '12/31/' + CONVERT(VARCHAR, DATEPART(YY,
		@CurrentDate))) AS LastDayOfYear,
		NULL AS IsHolidayAUS,
		CASE DATEPART(DW, @CurrentDate)
			WHEN 1 THEN 0
			WHEN 2 THEN 1
			WHEN 3 THEN 1
			WHEN 4 THEN 1
			WHEN 5 THEN 1
			WHEN 6 THEN 1
			WHEN 7 THEN 0
			END AS IsWeekday,
		NULL AS HolidayAUS

	SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END

/********************************************************************************************/


/*Update HOLIDAY fields of AUS as per Govt. Declaration of National Holiday*/


-- Good Friday  (TODO)

-- Easter Monday  (TODO)

-- Queen's Birthday  (TODO)

/* Austalia Day and Public Holiday */
-- Australia Day  January 26
UPDATE [dbo].[calendar]
	SET HolidayAUS = 'Australia Day'
WHERE [Month] = 1
  AND [DayOfMonth]  = 26


-- From 31/12/11 when Australia Day (26 January) falls on a Saturday or Sunday, the following Monday will be declared a public holiday.
UPDATE [dbo].[calendar]
	SET HolidayAUS = 'Australia Day (Additional)'
WHERE [Date] IN (
  SELECT
    CASE Hol.[DayName]
      WHEN 'Saturday' THEN DATEADD(day, 2, Hol.[Date])
      WHEN 'Sunday' THEN DATEADD(day, 1, Hol.[Date])
    END AS AdditionalHoliday
	FROM [dbo].[calendar] Hol
	WHERE Hol.[Month] = 1
    AND Hol.[DayOfMonth] = 26
    AND Hol.[IsWeekday] = 0
    AND Hol.[Date] > '2011-12-31'
)


/* Christmas & Boxing Day */

-- Christmas Day, December 25
UPDATE [dbo].[calendar]
	SET HolidayAUS = 'Christmas Day'
WHERE [Month] = 12
  AND [DayOfMonth]  = 25

-- From 31/12/11, the Holiday Act provides for an extra public holiday to be added when Christmas Day falls on a weekend.
UPDATE [dbo].[calendar]
	SET HolidayAUS = 'Christmas Day (Additional)'
WHERE [Date] IN (
  SELECT CASE Hol.[DayName]
    WHEN 'Saturday' THEN DATEADD(day, 2, Hol.[Date])
    WHEN 'Sunday' THEN DATEADD(day, 1, Hol.[Date])
  END AS AdditionalHoliday
  FROM [dbo].[calendar] Hol
  WHERE Hol.[Month] = 12
    AND Hol.[DayOfMonth] = 25
    AND Hol.[IsWeekday] = 0
    AND Hol.[Date] > '2011-12-31'
)


-- Boxing Day, December 26
UPDATE [dbo].[calendar]
	SET HolidayAUS = 'Boxing Day'
WHERE [Month] = 12
  AND [DayOfMonth]  = 26

--From 31/12/11, the Holiday Act provides for an extra public holiday to be added when Boxing Day falls on a weekend.
UPDATE [dbo].[calendar]
	SET HolidayAUS = 'Boxing Day (Additional)'
WHERE [Date] IN (
  SELECT
    CASE Hol.[DayName]
      WHEN 'Saturday' THEN DATEADD(day, 2, Hol.[Date])
      WHEN 'Sunday' THEN DATEADD(day, 1, Hol.[Date])
    END AS AdditionalHoliday
 	FROM [dbo].[calendar] Hol
  WHERE Hol.[Month] = 12
    AND Hol.[DayOfMonth] = 26
    AND Hol.[IsWeekday] = 0
    AND Hol.[Date] > '2011-12-31'
)


/* New Years */
-- New Years Day, 1st January
UPDATE [dbo].[calendar]
	SET HolidayAUS  = 'New Year''s Day'
WHERE [Month] = 1
  AND [DayOfMonth] = 1


-- From 31/12/11, the Holiday Act provides for an extra public holiday to be added when New Year's Day falls on a weekend
UPDATE [dbo].[calendar]
	SET HolidayAUS  = 'New Year''s Day (Additional)'
WHERE [Date] IN (
  SELECT CASE Hol.[DayName]
  WHEN 'Saturday' THEN DATEADD(day, 2, Hol.[Date])
  WHEN 'Sunday' THEN DATEADD(day, 1, Hol.[Date])
  END AS AdditionalHoliday
	FROM [dbo].[calendar] Hol
WHERE Hol.[Month] = 1
AND Hol.[DayOfMonth] = 1
AND Hol.[IsWeekday] = 0
AND Hol.[Date] > '2011-12-31')

--Update flag for AUS Holidays 1= Holiday, 0=No Holiday
UPDATE [dbo].[calendar]
	SET IsHolidayAUS = CASE WHEN HolidayAUS IS NULL
THEN 0 WHEN HolidayAUS IS NOT NULL THEN 1 END
