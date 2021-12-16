	--DELETE S
	--SELECT *
	FROM dbo.ObjectSettings S 
	INNER JOIN BillingRateTables T
		ON CONVERt(varchar(50), t.ratetableid) = s.[data]
	WHERE S.ObjectKey = 'RateTableId'
	AND t.billingratetableid <> 1
