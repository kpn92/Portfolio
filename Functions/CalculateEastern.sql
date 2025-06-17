CREATE FUNCTION dbo.CalcEastern (@year INT)
RETURNS DATE
AS
BEGIN
    DECLARE @EasterOffset INT;
    DECLARE @easterIndex INT;
    DECLARE @month INT;
    DECLARE @day INT;

    -- Calculate the full moon offset
    SET @EasterOffset = (19 * (@year % 19) + 16) % 30;

    -- Calculate the index for Easter Sunday based on the year and offset
    SET @easterIndex = @EasterOffset 
                     + (2 * (@year % 4) 
                     + 4 * (@year % 7) 
                     + 6 * @EasterOffset) % 7 + 3;

    -- Determine the actual calendar month and day
    IF @easterIndex > 30
    BEGIN
        SET @month = 5;
        SET @day = @easterIndex - 30;
    END
    ELSE
    BEGIN
        SET @month = 4;
        SET @day = @easterIndex;
    END

    -- Return the final calculated Easter date
    RETURN DATEFROMPARTS(@year, @month, @day);
END
GO
