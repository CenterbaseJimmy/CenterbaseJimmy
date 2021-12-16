CREATE OR ALTER VIEW [PL].[CB_Matters]
AS 

SELECT
	M.mrow_id [MatterID]
	, C.crow_id [ClientID]
	, CONCAT(RTRIM(C.[name]),' - ', RTRIM(M.[name]),' - ',RTRIM(M.clt_code),'-',FORMAT(TRY_CONVERT(INT,mat_code),'D3')) AS [Matter Name]
	, RTRIM(M.[name]) AS [Short Description]
	, A.address1 AS [Address 1]
	, A.address2 AS [Address 2]
	, A.address3 AS [Address 3]
	, A.city
	, A.[state]
	, A.zip
	, [start_date] AS [Date Opened]
	, [closed] AS [Date Closed]
	, bill_atty AS [Responsible Attorney]
	, init_atty AS [Originating Attorney]
	, std_rate AS [Rate Table]
	, over_rate AS [Rate Exceptions]
	, over_rate2 AS [Rate Exceptions 2]
	, CONCAT(RTRIM(M.clt_code),'-',FORMAT(TRY_CONVERT(int,mat_code),'D3')) [Matter Number]
	, FORMAT(TRY_CONVERT(int,mat_code),'D3') AS [Matter Sequence Number]
	, RTRIM(M.clt_code) AS [Client Number]
	, RTRIM(C.[name]) AS [Client Name]
	--, email_bill AS [Email Bills?]
	, CASE 
		WHEN M.class = 'FF' THEN 'Flat Fee' 
		ELSE 'Hourly'
		END AS [Fee Arrangement]
	, M.Notes AS [Notes]
	, CL.name [Practice Area]
	, O.descrip [Office]
	, CASE WHEN email_bill=1 THEN 'TRUE' ELSE 'FALSE' END [CLIENT ACCEPTS BILL VIA EMAIL]
	, init_fc [Fee Credits]
	, M.MATMINTRST [Matter Minimum Trust]
FROM dbo.matter M
INNER JOIN client C
	ON C.clt_code = M.clt_code
LEFT OUTER JOIN [address] A
	ON A.addr_code = M.addr_code
LEFT JOIN class CL
	ON M.class=CL.cls_code
LEFT JOIN office O
	ON M.off_code=O.off_code

GO