DECLARE @run bit = 0
DECLARE @tabledetails bit = 1

DECLARE @TablesToDelete TABLE (billingratetableid int, ratetableid uniqueidentifier, tablename nvarchar(255))

INSERT INTO @TablesToDelete
(billingratetableid)
SELECT t.billingratetableid
FROM dbo.BillingRateTables T
where t.billingratetableid <> 1

--SELECT * FROM BillingRateTables
--WHERE [NAME] LIKE '%OFFICE OF RISK MANAGEMENT%'
--SELECT * FROM BillingRateTables ORDER BY billingratetableid ASC


UPDATE T SET ratetableid = r.ratetableid
FROM @TablesToDelete T
INNER JOIN dbo.BillingRateTables R
	ON R.billingratetableid = T.billingratetableid
WHERE T.ratetableid IS NULL

UPDATE T SET billingratetableid = r.billingratetableid
FROM @TablesToDelete T
INNER JOIN dbo.BillingRateTables R
	ON R.ratetableid = T.ratetableid
WHERE T.billingratetableid IS NULL

UPDATE T SET tablename = r.name
FROM @TablesToDelete T
INNER JOIN dbo.BillingRateTables R
	ON R.billingratetableid = T.billingratetableid


DELETE T
FROM @TablesToDelete t
INNER JOIN dbo.BillingRateTables R
	ON R.billingratetableid = T.billingratetableid
	AND R.isdefaulttable = 1


IF (@run = 1)
BEGIN
	DELETE S
	FROM dbo.ObjectSettings S 
	INNER JOIN @TablesToDelete T
		ON CONVERt(varchar(50), t.ratetableid) = s.[data]
	WHERE S.ObjectKey = 'RateTableId'

	DELETE E
	FROM @TablesToDelete t
	INNER JOIN dbo.BillingRateTables R
		ON R.billingratetableid = T.billingratetableid
	INNER JOIN dbo.BillingRateTableVersions V
		oN V.ratetableid = R.ratetableid
	INNER JOIN dbo.BillingRateTableEntries E
		ON E.versionid = V.versionid

	DELETE V
	FROM @TablesToDelete t
	INNER JOIN dbo.BillingRateTables R
		ON R.billingratetableid = T.billingratetableid
	INNER JOIN dbo.BillingRateTableVersions V
		oN V.ratetableid = R.ratetableid

	DELETE R
	FROM @TablesToDelete t
	INNER JOIN dbo.BillingRateTables R
		ON R.billingratetableid = T.billingratetableid
END
ELSE
BEGIN
	IF (@tabledetails = 1)
	BEGIN
		SELECT O.objectid, O.name, O.inactive, T.billingratetableid, T.tablename
		FROM dbo.ObjectSettings S 
		INNER JOIN @TablesToDelete T
			ON CONVERt(varchar(50), t.ratetableid) = s.[data]
		INNER JOIN dbo.Objects O
			ON O.objectid = S.ObjectId
		WHERE S.ObjectKey = 'RateTableId'
		ORDER BY T.tablename, o.inactive, O.name
	END
	ELSE
	BEGIN
		SELECT T.billingratetableid, T.tablename
			, COUNT(CASE WHEN O.inactive = 1 THEN NULL ELSE 1 END) AS [ActiveCount]
			, COUNT(CASE WHEN O.inactive = 1 THEN 1 ELSE NULL END) AS [InactiveCount]
		FROM dbo.ObjectSettings S 
		INNER JOIN @TablesToDelete T
			ON CONVERt(varchar(50), t.ratetableid) = s.[data]
		INNER JOIN dbo.Objects O
			ON O.objectid = S.ObjectId
		WHERE S.ObjectKey = 'RateTableId'
		GROUP BY T.billingratetableid, T.tablename
		ORDER BY T.tablename
	END
END