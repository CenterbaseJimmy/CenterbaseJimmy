CREATE OR ALTER VIEW [PL].[CB_Contacts]
AS 
SELECT 
	C.crow_id AS [ClientId]
	, RTRIM([name]) AS [Client Name]
	, RTRIM(C.clt_code) AS [Client Number]
	, A.phone 
	, A.[EMAIL]
	, A.address1 AS [Address 1]
	, A.address2 AS [Address 2]
	, A.address3 AS [Address 3]
	, A.city
	, A.[state]
	, A.zip
	, C.notes
 	, CASE WHEN C.inactive = 1 THEN 'Inactive' ELSE 'Active' END AS [Active Status]
FROM dbo.client C
LEFT OUTER JOIN [address] A
ON A.clt_code = C.clt_code
AND LEN(TRIM(A.addr_code)) < 7

GO