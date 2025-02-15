CREATE FUNCTION dbo.WorkDays(@StartDate DATE, @EndDate DATE)
RETURNS INT
AS
BEGIN

    DECLARE @WorkDays INT = 0;
    DECLARE @Year INT = YEAR(@StartDate);
    DECLARE @Easter DATE;

    -- Create a temporary table for holidays
    DECLARE @Holidays TABLE (HolidayDate DATE, HolidayName NVARCHAR(50));

    WHILE @Year <= YEAR(@EndDate)
    BEGIN

        -- Calculate the date of Orthodox Easter
        SET @Easter = dbo.CalcEastern(@Year);


        -- Insertion of fixed and movable holidays into the table
		INSERT INTO @Holidays (HolidayDate,HolidayName)
		VALUES 
		-- Fixed holidays
		(DATEFROMPARTS(@Year, 1, 1),N'Πρωτοχρονιά'),		-- (New Year's Day): January 1
		(DATEFROMPARTS(@Year, 1, 6),N'Θεοφάνεια'),		-- (Epiphany): January 6
		(DATEFROMPARTS(@Year, 3, 25),N'25η Μαρτίου'),		-- (Annunciation of the Virgin Mary): March 25
		(DATEFROMPARTS(@Year, 5, 1),N'Πρωτομαγιά'),		-- (Labour Day): May 1
		(DATEFROMPARTS(@Year, 8, 15),N'Κοίμηση Θεοτόκου'),	-- (Dormition of the Virgin Mary): August 15
		(DATEFROMPARTS(@Year, 10, 28),N'28η Οκτωβρίου'),	-- (Ochi Day): October 28
		(DATEFROMPARTS(@Year, 12, 25),N'Χριστούγεννα'),		-- (Christmas Day): December 25
		(DATEFROMPARTS(@Year, 12, 26),N'Σύναξη Θεοτόκου'),	-- (Synaxis of the Virgin Mary): December 26
		-- Movable holidays
		(DATEADD(DAY, -48, @Easter),N'Καθαρά Δευτέρα'),		-- (Clean Monday): The first day of Lent, 48 days before Easter.
		(DATEADD(DAY, -2, @Easter),N'Μεγάλη Παρασκευή'),	-- (Good Friday): The Friday before Easter.
		(@Easter,N'Κυριακή του Πάσχα'),				-- (Easter Sunday): Orthodox Easter, calculated based on the lunar calendar.
		(DATEADD(DAY, 1, @Easter),N'Δευτέρα του Πάσχα'),	-- (Easter Monday): The day after Easter Sunday.
		(DATEADD(DAY, 50, @Easter),N'Αγίου Πνεύματος');		-- (Holy Spirit Monday): 50 days after Easter (Pentecost Monday).


        SET @Year += 1;

    END;

    -- Create a temporary table for date range calculation
    DECLARE @Range TABLE (NameDay NVARCHAR(50), CodeDay INT, CalcDate DATE);
    DECLARE @CalcDate DATE = @StartDate;
    DECLARE @NameDay NVARCHAR(15);

    WHILE @CalcDate < DATEADD(DAY, 1, @EndDate)
    BEGIN
        DECLARE @DayOfWeek INT;
        SELECT @DayOfWeek = ((DATEPART(WEEKDAY, @CalcDate) + @@DATEFIRST - 2) % 7) + 1;
        SET @NameDay = DATENAME(WEEKDAY, @CalcDate);

        INSERT INTO @Range (NameDay, CodeDay, CalcDate)
        VALUES (@NameDay, @DayOfWeek, @CalcDate);

        SET @CalcDate = DATEADD(DAY, 1, @CalcDate);
    END;

    -- Calculate working days excluding holidays and weekends
    SELECT @WorkDays = COUNT(*)
    FROM @Range r
    WHERE NOT EXISTS (SELECT 1 FROM @Holidays h WHERE h.HolidayDate = r.CalcDate) 
    AND r.CodeDay NOT IN (6, 7);

    -- Return the number of working days
    RETURN @WorkDays;

END;
