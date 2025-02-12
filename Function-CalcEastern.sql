CREATE FUNCTION	[dbo].[CalcEastern](@pYear int)
		RETURNS DATETIME
		AS
		BEGIN
			DECLARE	@D	int
			DECLARE	@E	int
		
			
			SET	@D = (19 * (@pYear % 19) + 16) % 30
			SET	@E = @D + (2 * (@pYear % 4) + 4 * (@pYear % 7) + 6 * @D) % 7 + 3
		
			DECLARE	@RetYear	VARCHAR(4)
			SET	@RetYear = CONVERT(VARCHAR(4), @pYear)
		
			DECLARE	@RetMonth	VARCHAR(2)
			DECLARE	@RetDay		VARCHAR(2)
		
			IF @E > 30
				BEGIN
					SET	@RetMonth = '05'
					SET	@RetDay = CONVERT(VARCHAR(2), @E % 30)
				END
			ELSE
				BEGIN
					SET	@RetMonth = '04'
					SET	@RetDay = CONVERT(VARCHAR(2), @E)
				END
			
			IF LEN(@RetDay) = 1
				SET	@RetDay = '0' + @RetDay
		
			RETURN @RetYear + @RetMonth + @RetDay
		END
GO


