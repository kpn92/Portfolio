CREATE PROCEDURE [dbo].[Export_CallAttempts]
    @Offset2 INT,
    @BatchSize2 INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL AS NVARCHAR(MAX);
    DECLARE @LinkedServerName AS NVARCHAR(100);

    SELECT @LinkedServerName = 
        CASE 
            WHEN LTRIM(RTRIM(ConfigValue)) = '' OR ConfigValue IS NULL 
                THEN 'Company_Name'
            ELSE ConfigValue
        END
    FROM AppConfig 
    WHERE ConfigKey = 'PBX_LINKED_SERVER_NAME';

	DECLARE @sNm NVARCHAR(50);
	SET @sNm = (SELECT [Description] FROM Campaigns WHERE [Description] = 'Company_Name')

	DECLARE @sDTFrom NVARCHAR(100);
	SET @sDTFrom =  DATEADD(DAY, - 1,CAST(GETDATE() AS DATE))  -- Προηγούμενης Ημέρας
	-- CAST(GETDATE() AS DATE) -- Τρέχουσας Ημέρας
	-- DATEFROMPARTS(YEAR(GETDATE()), 1, 1) -- Τρέχων Έτος

	DECLARE @sDTTo NVARCHAR(100);
	SET  @sDTTo =  CAST(GETDATE() AS DATE) -- Προηγούμενης Ημέρας
	-- DATEADD(DAY, 1, CAST(GETDATE() AS DATE)) -- Τρέχουσας Ημέρας
	-- DATEFROMPARTS(YEAR(GETDATE()) + 1, 1, 1) -- Τρέχων Έτος

    SET @SQL = ' SELECT * FROM (
        SELECT 
			   ROW_NUMBER() OVER (ORDER BY Dialer.CallID) AS RowNum
			 , cl.ContractNumber  AS ContractNumber
             , Dialer.CampaignID  AS Campaign
             , Dialer.Created     AS InsertedOn
             , Dialer.PhoneNumber AS PhoneNumber
             , Dialer.CallID      AS UniqueID
             , Dialer.Disposition AS [State]
             , Dialer.SipResponse AS SipResponse
             , CASE WHEN ISAbandoned = 1 THEN N''Yes'' ELSE N''No'' END AS Abandoned
        FROM OPENQUERY([' + @LinkedServerName + '], 
            ''
              SELECT * 
              FROM opencomm_platform.ReportCallsDetailed 
			  WHERE Created >= STR_TO_DATE(''''' + CONVERT(VARCHAR, @sDTFrom, 120) + ''''', ''''%Y-%m-%d'''')
			  AND Created < STR_TO_DATE(''''' + CONVERT(VARCHAR, @sDTTo, 120) + ''''', ''''%Y-%m-%d'''')
            ''		  
        ) AS Dialer
        INNER JOIN Customers_NRG_MAIN C
            ON Dialer.ContactSourceId = C.CustomerID
        INNER JOIN ColProducts_NRG_MAIN cl
            ON cl.CustomerID = C.CustomerID
		) AS CallAttempts
		WHERE RowNum BETWEEN @Offset2 + 1 AND @Offset2 + @BatchSize2
		ORDER BY RowNum;
    ';

-- PRINT @SQL

	EXEC sp_executesql
        @SQL,
        N'@Offset2 INT, @BatchSize2 INT, @FromDate DATE, @ToDate DATE',
        @Offset2 = @Offset2,
        @BatchSize2 = @BatchSize2,
        @FromDate = @sDTFrom,
        @ToDate = @sDTTo

		WITH RESULT SETS 
(
    (
      RowNum INT,
      ContractNumber NVARCHAR(100),
	  Campaign  NVARCHAR(50),
	  InsertedOn NVARCHAR(50),
	  PhoneNumber NVARCHAR(50),
	  UniqueID NVARCHAR(50),
	  [State] NVARCHAR(50),
	  SipResponse NVARCHAR(50),
	  Abandoned NVARCHAR(10)
    ) 
);

END
