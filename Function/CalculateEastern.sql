CREATE FUNCTION [dbo].[CalcEastern](@pYear INT)
RETURNS DATETIME
AS
BEGIN
    DECLARE @D INT
    DECLARE @E INT

    -- Calculate the date of Easter using the algorithm
    SET @D = (19 * (@pYear % 19) + 16) % 30
    SET @E = @D + (2 * (@pYear % 4) + 4 * (@pYear % 7) + 6 * @D) % 7 + 3

    DECLARE @RetYear INT
    SET @RetYear = @pYear

    DECLARE @RetMonth INT
    DECLARE @RetDay INT

    -- Determine the month and day based on the calculated value of @E
    IF @E > 30
    BEGIN
        -- If @E is greater than 30, Easter is in May
        SET @RetMonth = 5
        SET @RetDay = @E % 30
    END
    ELSE
    BEGIN
        -- Otherwise, Easter is in April
        SET @RetMonth = 4
        SET @RetDay = @E
    END

    -- Return the calculated date as a DATETIME object
    RETURN DATEFROMPARTS(@RetYear, @RetMonth, @RetDay)
END
GO
