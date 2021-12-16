CREATE OR ALTER VIEW [PL].[CB_RelatedParties]
AS 
SELECT 
	event_code AS [PartyId]
	, RTRIM(party_code) AS [Party Name]
	, specialty AS [Specialty]
	, homeph AS [Home Phone]
	, mobileph AS [Mobile Phone]
	, workph AS [Work Phone]
	, faxph AS [Fax]
	, email_addr AS [Email]
	, street_add AS [Address 1]
	, street_ad1 AS [Address 2]
	, street_ad3 AS [Address 3]
	, city
	, [state]
	, zip
	, notes
	, beeperph
	, employer
	, mail_list
	, gender
	, dbo.fn_BuildName(mrmrs, first, middle, name, NULL) [Full Name]
FROM dbo.party P
WHERE LEN(TRIM(P.event_code)) = 7

GO

CREATE OR ALTER VIEW [PL].[CB_RelatedParties_Matter]
AS 
SELECT 
	event_code AS [PartyId]
	, RTRIM(party_code) AS [Party Name]
	, M.clt_code AS [Client Number]
	, M.mat_code AS [Matter Sequence Number]
	, M.mrow_id AS [MatterId]
	, CONCAT(RTRIM(C.[name]),' - ', RTRIM(M.[name]),' - ',RTRIM(M.clt_code),'-',FORMAT(TRY_CONVERT(INT,M.mat_code),'D3')) AS [Matter Name]
FROM dbo.party P
INNER JOIN relparty R
ON R.related = P.event_code
INNER JOIN matter M
ON M.clt_code = R.clt_code
AND M.mat_code = R.mat_code
INNER JOIN client C
ON C.clt_code = M.clt_code
WHERE LEN(TRIM(P.event_code)) = 7

GO