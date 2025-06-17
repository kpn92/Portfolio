CREATE PROCEDURE [dbo].[Export_ExtraInfo]
    @Offset3 INT,
    @BatchSize3 INT
AS
BEGIN
    SET NOCOUNT ON;

-- Category Types
  DECLARE @CategoryTypes TABLE (
    ProductNumber VARCHAR(50),
    SourceID INT,
    ID INT,
    CustomerID INT,
    IsActive CHAR(1),
    OverdueFlag VARCHAR(20),
    Segment VARCHAR(20),
    BalanceRanking VARCHAR(20)
);

INSERT INTO @CategoryTypes
SELECT 
    p.ProductNumber,
    ct.SourceID,
    p.ID,
    p.CustomerID,
    CASE 
        WHEN p.IsActive = 1 THEN 'Y' 
        ELSE 'N' 
    END as IsActive,
    CASE 
        WHEN ISNULL(p.OutstandBalance, '0.00') = '0.00' THEN 'Non Overdue' 
        ELSE 'Overdue' 
    END AS OverdueFlag,
    CASE 
        WHEN EXISTS (SELECT 1 FROM LegalActionsHistory la WHERE la.CustomerID = ct.CustomerID) THEN 'Legal'
        WHEN t.Products < 3 THEN 'Low Priority'
        WHEN t.Products = 3 THEN 'Medium Priority'
        WHEN t.Products = 4 THEN 'High Priority'
        WHEN t.Products >= 5 THEN 'Red Alarm'
        ELSE 'No Segment'
    END AS Segment,
    CASE 
        WHEN p.OutstandBalance > 15000.01 THEN 'Asset'
        WHEN p.OutstandBalance > 5000.01 AND p.OutstandBalance <= 15000.00 THEN 'UltraHigh'
        WHEN p.OutstandBalance > 1500.01 AND p.OutstandBalance <= 5000.00 THEN 'SHigh Balance'
        WHEN p.OutstandBalance > 400.01 AND p.OutstandBalance <= 1500.00 THEN 'High Balance'
        WHEN p.OutstandBalance > 100.01 AND p.OutstandBalance <= 400.00 THEN 'Medium'
        WHEN p.OutstandBalance < 100.00 AND p.OutstandBalance >= 1.00 THEN 'LowBalance'
        WHEN p.OutstandBalance < 1.00 THEN 'No treatment'
        ELSE ''
    END AS BalanceRanking
FROM 
    (SELECT CustomerID, COUNT(*) AS Products FROM ColProducts_NRG_MAIN GROUP BY CustomerID) t
    INNER JOIN ColProducts_NRG_MAIN p ON t.CustomerID = p.CustomerID
    INNER JOIN Customers_NRG_MAIN ct ON ct.CustomerID = p.CustomerID
WHERE p.IsActive = 1;

-- ActivityGroup
DECLARE @ActivityGroup TABLE (
    LastCallResult INT,
    ActivityGroup VARCHAR(255),
    CustomerSid INT,
    ProductNumber VARCHAR(50),
    sCustomField01 VARCHAR(255),
    LastPaymentDate DATE NULL,
    LastPaidAmount DECIMAL(18,2),
    Flag CHAR(1)
);

INSERT INTO @ActivityGroup
SELECT * FROM (
SELECT 
    lpa.LastCallResult,
    crg.[Description] AS ActivityGroup,
    lpa.CustomerSid,
    lpa.ProductNumber,
    lpa.sCustomField01,
    CASE 
        WHEN lpa.LastPaymentDate = '1900-01-01' THEN NULL 
        ELSE lpa.LastPaymentDate 
    END AS LastPaymentDate,
    TRY_CONVERT(DECIMAL(18, 2), lpa.LastPaidAmount) AS LastPaidAmount,
    'Y' AS Flag
FROM LastProdAction_NRG_MAIN lpa
    LEFT JOIN CallResults_NRG_MAIN cr ON lpa.LastCallResult = cr.CallResultID
    LEFT JOIN CallResultGroups_NRG_MAIN crg ON cr.CallResultGroupId = crg.ID

UNION ALL

SELECT 
    lpar.LastCallResult,
    crg.[Description] AS ActivityGroup,
    lpar.CustomerSid,
    lpar.ProductNumber,
    lpar.sCustomField01,
    CASE 
        WHEN lpar.LastPaymentDate = '1900-01-01' THEN NULL 
        ELSE lpar.LastPaymentDate 
    END AS LastPaymentDate,
    TRY_CONVERT(DECIMAL(18, 2), lpar.LastPaidAmount) AS LastPaidAmount,
    'N' AS Flag
FROM LastProdActionR_NRG_MAIN lpar
    LEFT JOIN CallResults_NRG_MAIN cr ON lpar.LastCallResult = cr.CallResultID
    LEFT JOIN CallResultGroups_NRG_MAIN crg ON cr.CallResultGroupId = crg.ID
) ActiveActivityGroup
WHERE   Flag = 'Y';

-- Bills
DECLARE @Bills TABLE (
    CustomerID INT,
    ProductID INT,
    DueDate DATE
);

INSERT INTO @Bills
SELECT 
    T.CustomerID,
    T.ProductID,
    T.DueDate
FROM 
    (SELECT
        b.CustomerID, 
        b.ProductID, 
        b.DueDate, 
        ROW_NUMBER() OVER (PARTITION BY b.CustomerID, b.ProductID ORDER BY b.InsDate DESC) AS RNK
     FROM Bills_NRG_MAIN b
     INNER JOIN ColProducts_NRG_MAIN p ON b.CustomerID = p.CustomerID AND b.ProductID = p.ID
     INNER JOIN Customers_NRG_MAIN ct ON p.CustomerID = ct.CustomerID
    ) T
WHERE T.RNK = 1;

DECLARE @Temp TABLE (
    CustomerID INT,
    ExtExternal VARCHAR(255),
    ExExtExternal VARCHAR(255),
    ExternalAssignDate DATE,
    ExExternalAssignDate DATE,
    UnAssignDate DATE
);

WITH Temp AS (
    SELECT 
        ccsh.CustomerID,
        ccsh.InsDate,
        cs.ServicerName,
        ROW_NUMBER() OVER (PARTITION BY ccsh.CustomerID ORDER BY ccsh.InsDate DESC) AS RNK
    FROM ColCustomerServicerHistory ccsh
    INNER JOIN ColCustomerServicerHistoryDirection ccshd ON ccsh.ColCustomerServicerHistoryDirectionID = ccshd.ID
    INNER JOIN Customers_NRG_MAIN ct ON ccsh.CustomerID = ct.CustomerID
    INNER JOIN ColServicers cs ON cs.ID = ccsh.ColServicersID AND cs.CampaignID = 102
    WHERE ccsh.CampaignID = (SELECT CampaignID FROM Campaigns WHERE  [description] = 'NRG_MAIN') AND ccshd.ID = 1
),
Assign AS (
    SELECT 
        t1.CustomerID,
        t2.InsDate AS ExExternalAssignDate,
        t1.InsDate AS ExternalAssignDate,
        t2.ServicerName AS ExExtExternal,
        t1.ServicerName AS ExtExternal
    FROM Temp t1
    LEFT JOIN Temp t2 ON t1.CustomerID = t2.CustomerID AND t2.RNK = 2
    WHERE t1.RNK = 1
),
UnAssign AS (
    SELECT 
        ccsh.CustomerID,
        ccsh.InsDate,
        ccsh.ColServicersID,
        ROW_NUMBER() OVER (PARTITION BY ccsh.CustomerID ORDER BY ccsh.InsDate DESC) AS RNK
    FROM ColCustomerServicerHistory ccsh
    INNER JOIN ColCustomerServicerHistoryDirection ccshd ON ccsh.ColCustomerServicerHistoryDirectionID = ccshd.ID
    INNER JOIN Customers_NRG_MAIN ct ON ccsh.CustomerID = ct.CustomerID
    WHERE ccsh.CampaignID = (SELECT CampaignID FROM Campaigns WHERE  [description] = 'NRG_MAIN') AND ccshd.ID = 2
)

INSERT INTO @Temp
SELECT 
    ct.CustomerID,
    CASE WHEN a.ExternalAssignDate > ISNULL(ua.InsDate, '1900-01-01') THEN a.ExtExternal ELSE NULL END AS ExtExternal,
    CASE WHEN a.ExternalAssignDate > ISNULL(ua.InsDate, '1900-01-01') THEN a.ExExtExternal ELSE a.ExtExternal END AS ExExtExternal,
    CASE WHEN a.ExternalAssignDate > ISNULL(ua.InsDate, '1900-01-01') THEN a.ExternalAssignDate ELSE NULL END AS ExternalAssignDate,
    CASE WHEN a.ExternalAssignDate > ISNULL(ua.InsDate, '1900-01-01') THEN a.ExExternalAssignDate ELSE a.ExternalAssignDate END AS ExExternalAssignDate,
    CASE WHEN ISNULL(ua.InsDate, '1900-01-01') >= ISNULL(a.ExExternalAssignDate, a.ExternalAssignDate) THEN ua.InsDate ELSE NULL END AS UnAssignDate
FROM Customers_NRG_MAIN ct
LEFT JOIN Assign a ON ct.CustomerID = a.CustomerID
LEFT JOIN UnAssign ua ON ct.CustomerID = ua.CustomerID AND ua.RNK = 1;

-- temp_last_strongerstatus
DECLARE @temp_last_strongerstatus TABLE (
    CustomerID INT,
    ProductNumber VARCHAR(50),
    StrongerStatusID INT,
    RankedDate INT
);

INSERT INTO @temp_last_strongerstatus
SELECT * FROM (
SELECT 
    CustomerID AS CustomerID, 
    ProductNumber AS ProductNumber, 
    StrongerStatusID AS StrongerStatusID, 
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY InsDate DESC) AS RankedDate
FROM CallResultsStrongerStatusHistory
WHERE CampaignID = (SELECT CampaignID FROM Campaigns WHERE  [description] = 'NRG_MAIN')
) AS LastStrongerStatus
WHERE RankedDate = 1;

DECLARE @Results TABLE (
    [ContractNumber] NVARCHAR(100),
    [Assigment Bucket] NVARCHAR(100),
    [Current Category] NVARCHAR(100),
    [External Assignment Date] DATETIME,
    [Ex.External] NVARCHAR(255),
    [Ex.External Recall Date] DATETIME,
    [Ext.Servicer] NVARCHAR(255),
    [Ex.External Assignment Date] DATETIME,
    [Current Bucket] NVARCHAR(100),
    [Overdue Flag] NVARCHAR(50),
    [Stronger Status] NVARCHAR(100),
    [1st Month Bucket] NVARCHAR(100),
    [1st Month Overdue] NVARCHAR(50),
    [Risk Cluster] NVARCHAR(100),
    [Activity Group] NVARCHAR(255),
    [Delinquent Days] INT,
    [Bucket Καθυστέρησης] NVARCHAR(100),
    rn INT
);

INSERT INTO @Results
SELECT 
    p.ContractNumber,
    p.AssignmentBucket,
    c.Segment,
    temp.ExternalAssignDate,
    temp.ExExtExternal,
    temp.UnAssignDate,
    temp.ExtExternal,
    temp.ExExternalAssignDate,
    p.CurrentBucket,
    c.OverdueFlag,
    crsg.StrongerStatus,
    ISNULL(p.FirstMonthBucket, '0'),
    ISNULL(p.FirstMonthOverdue, '0.00'),
    p.RiskCluster,
    ISNULL(ag.ActivityGroup, ''),
    p.DelinquentDays,
    p.DelayedBucket,
    ROW_NUMBER() OVER (ORDER BY p.ID) AS rn
FROM ColProducts_NRG_MAIN               p
INNER JOIN Customers_NRG_MAIN           ct  ON p.CustomerID = ct.CustomerID
LEFT JOIN @temp_last_strongerstatus     tmp ON tmp.CustomerID = ct.CustomerID AND tmp.ProductNumber = p.ProductNumber
LEFT JOIN @CategoryTypes                c   ON c.ID = p.ID AND c.CustomerID = p.CustomerID
LEFT JOIN CampaignPortfolios            cp  ON cp.PortfolioID = ct.PortfolioID
LEFT JOIN CallResultsStrongerStatus     crsg ON crsg.ID = tmp.StrongerStatusID
LEFT JOIN @ActivityGroup                ag  ON ag.CustomerSID = ct.SourceID AND ag.ProductNumber = p.ProductNumber AND ag.sCustomField01 = p.ContractNumber
LEFT JOIN @Bills                        b   ON b.CustomerID = p.CustomerID AND b.ProductID = p.ID
LEFT JOIN @Temp                         temp ON temp.CustomerID = p.CustomerID
WHERE p.IsActive = 1;

SELECT *
FROM @Results
WHERE rn BETWEEN @Offset3 + 1 AND @Offset3 + @BatchSize3
ORDER BY rn;

END
