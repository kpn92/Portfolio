CREATE PROCEDURE [dbo].[Export_Activities]
    @Offset INT,
    @BatchSize INT
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @sNm NVARCHAR(50);
	SET @sNm = (SELECT [Description] FROM Campaigns WHERE [Description] = 'Company_Name')

	DECLARE @sDTFrom NVARCHAR(100);
	SET @sDTFrom = DATEADD(DAY, - 1,CAST(GETDATE() AS DATE)) 

	DECLARE @sDTTo NVARCHAR(100);
	SET  @sDTTo =  CAST(GETDATE() AS DATE) 

	DECLARE @SQL NVARCHAR(MAX);

	SET @SQL = N' SELECT * FROM (
     SELECT
		ROW_NUMBER() OVER (ORDER BY ch.CallID) AS RowNum,
        cl.ContractNumber AS ContractNumber,
        ch.CallID AS CallID,
		ISNULL(ch.CallDate,''1900-01-01 00:00:00.000'') + ISNULL(ch.TimeStartCall,''1900-01-01 00:00:00.000'') AS [Ημ/νία Ενέργειας],
        ch.phno AS [Τηλέφωνο],
        ct.CallType AS [Είδος],
        cr.CallResultID AS [CRID],
        cr.[Description] AS [Ενέργεια],
        DATEDIFF(SECOND, ISNULL(ch.TimeStartCall, ''''), ISNULL(ch.TimeEndCall, '''')) AS [Διάρκεια (sec)],
        ch.Notes AS [Σημειώσεις],
		pr.DatePromisePaid AS [Promise Payment Date],
        CONVERT(numeric(10, 2), pr.Amount) AS [Promise Amount],
        ps.PromiseStatus AS [Promise Status],
        CASE
            WHEN ssfa.[State] = 1000 THEN ''Pending''
            WHEN ssfa.[State] = 2000 THEN ''Approved''
            WHEN ssfa.[State] = 5000 THEN ''Rejected''
            ELSE ''''
        END AS [Servicer Approval State],
        ch.ReCallDateTime AS [Ημ/νία Επανάκλησης],
        ch.RecallPhoneNumber AS [Τηλέφωνο Επανάκλησης],
        ''['' + CONVERT(nvarchar, ch.AgentID) + ''] '' + ag.FirstName + '' '' + ag.LastName AS [Χειριστής],
        ch.CallUniqueId AS CallUniqueID,
        ch.CallHistoryRowStatusID AS [CallHistoryRowStatusID]
    FROM CallHistory_' + CAST(@sNm  AS NVARCHAR(MAX)) + N' ch
        LEFT JOIN CallResults_' + CAST(@sNm  AS NVARCHAR(MAX)) + N' cr ON ch.CallResultID = cr.CallResultID
        LEFT JOIN CallTypes ct ON ch.CallType = ct.ID
        LEFT JOIN Promises_' + CAST(@sNm  AS NVARCHAR(MAX)) + N' pr ON ch.CallID = pr.CallHID AND ch.ProductNumber = pr.ProductNumber
        LEFT JOIN PromiseStatus ps ON pr.[State] = ps.ID
        LEFT JOIN Agents ag ON ch.AgentID = ag.AgentID
        LEFT JOIN ServicerSettlementsForApproval ssfa ON ssfa.CallHistoryID = ch.CallID
        INNER JOIN ColProducts_' + CAST(@sNm  AS NVARCHAR(MAX)) + N' cl ON ch.colproductsid = cl.id
	WHERE ch.CallDate >= @FromDate AND ch.CallDate < @ToDate
	) AS Activities
	WHERE RowNum BETWEEN @Offset + 1 AND @Offset + @BatchSize
    ORDER BY RowNum;
	';

-- PRINT @SQL

	EXEC sp_executesql
        @SQL,
        N'@Offset INT, @BatchSize INT, @FromDate DATE, @ToDate DATE',
        @Offset = @Offset,
        @BatchSize = @BatchSize,
        @FromDate = @sDTFrom,
        @ToDate = @sDTTo

	WITH RESULT SETS 
(
    (
      RowNum INT,
      ContractNumber NVARCHAR(50),
      CallID BIGINT,
      [Ημ/νία Ενέργειας] DATETIME,
      [Τηλέφωνο] NVARCHAR(50),
      [Είδος] NVARCHAR(50),
      CRID INT,
      [Ενέργεια] NVARCHAR(100),
      [Διάρκεια (sec)] INT,
      [Σημειώσεις] NVARCHAR(500),
      [Promise Payment Date] DATETIME,
      [Promise Amount] DECIMAL(20, 4),
      [Promise Status] NVARCHAR(50),
      [Servicer Approval State] NVARCHAR(50),
      [Ημ/νία Επανάκλησης] DATETIME,
      [Τηλέφωνο Επανάκλησης] NVARCHAR(20),
      [Χειριστής] NVARCHAR(100),
      CallUniqueID NVARCHAR(80),
      CallHistoryRowStatusID INT
    )
);
END
