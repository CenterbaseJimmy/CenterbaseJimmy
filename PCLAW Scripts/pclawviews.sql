-- Make sure the new schema exists
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA S WHERE S.SCHEMA_NAME = 'PcLaw'))
	EXEC sp_executesql N'CREATE SCHEMA [PcLaw]';

GO
    
-- Builds an appropriately formatted name using the specified name parts (first, middle, last)
CREATE OR ALTER FUNCTION [dbo].[fn_AddStrings]
	(@string1 nvarchar(255)
	,@string2 nvarchar(255)
    , @separator nvarchar(10) = ' '
	)
RETURNS nvarchar(255)
AS
BEGIN 
	IF (LEN(@string1) > 0)
	BEGIN
		IF (LEN(@string2) > 0)
            RETURN @string1 + @separator + @string2
		ELSE
			RETURN @string1
	END
    ELSE IF (LEN(@string2) > 0)
    BEGIN
        RETURN @string2
    END

    RETURN ''
END
GO

CREATE OR ALTER FUNCTION [dbo].[fn_AddMultipleStrings]
	(@string1 nvarchar(255)
	,@string2 nvarchar(255)
    , @separator nvarchar(10) = ' '
    , @string3 nvarchar(255) = NULL
    , @string4 nvarchar(255) = NULL
    , @string5 nvarchar(255) = NULL
    , @string6 nvarchar(255) = NULL
    , @string7 nvarchar(255) = NULL
    , @string8 nvarchar(255) = NULL
    , @string9 nvarchar(255) = NULL)
RETURNS nvarchar(MAX)
AS
BEGIN

DECLARE @result nvarchar(MAX)

SET @result = dbo.fn_AddStrings( @string1, @string2, @separator);
SET @result = dbo.fn_AddStrings( @result, @string3, @separator);
SET @result = dbo.fn_AddStrings( @result, @string4, @separator);
SET @result = dbo.fn_AddStrings( @result, @string5, @separator);
SET @result = dbo.fn_AddStrings( @result, @string6, @separator);
SET @result = dbo.fn_AddStrings( @result, @string7, @separator);
SET @result = dbo.fn_AddStrings( @result, @string8, @separator);
SET @result = dbo.fn_AddStrings( @result, @string9, @separator);

RETURN @result  

END
GO

-- Builds an appropriately formatted name using the specified name parts (first, middle, last)
CREATE OR ALTER FUNCTION [dbo].[fn_BuildName]
	(@title nvarchar(255)
    ,@firstName nvarchar(255)
	,@middleName nvarchar(255)
	,@lastName nvarchar(255)
    ,@suffix nvarchar(255))
RETURNS nvarchar(255)
AS
BEGIN 
    DECLARE @ret nvarchar(255)

    SET @title = TRIM(@title)
    SET @firstName = TRIM(@firstName)
    SET @middleName = TRIM(@middleName)
    SET @lastName = TRIM(@lastName)
    SET @suffix = TRIM(@suffix)

    RETURN DBO.fn_AddMultipleStrings(
        @title, @firstName, ' '
        , @middleName
        , @lastName
        , @suffix, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
END
GO

-- Matters with A* matter number are info status 1, P* are info status 2, need to look into this

--

CREATE OR ALTER VIEW [PcLaw].[LawyerList] AS

SELECT L.LawyerID, L.LawInfNickName AS [UserName], L.LawInfInitials AS [Initials], L.LawInfLawyerName AS [DisplayName]
FROM LawInf L

GO

CREATE OR ALTER VIEW [PcLaw].[Contacts] AS

SELECT  C.ContactID, c.PersonID, CLNT.ClientInfoClientID, CLNT.ClientInfoClientNum
	, C.ContactStatus
	, P.PersonInfoStatus
	, CLNT.ClientInfoStatus
    , CLNT.ClientInfoDocumentPath
    --, C.ContactSortName
    , CASE WHEN LEN(C.ContactSortName) > 0 THEN C.ContactSortName
        ELSE dbo.fn_BuildName(A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix)
        END AS [Name]
    , C.ContactFirmName
    , l.LawInfNickName AS [LawyerNickname], l.LawInfLawyerName AS [LawyerName]
    , P.PersonInfoType, C.ContactMainContactType
	, CT.CtctTypeDescription [ContactType]
    , P.PersonInfoMainAddressID
	, A1.AddressInfoCompany
    , A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix, A1.AddressInfoAlias
    , A1.AddressInfoAddrType
    , A1.AddressInfoAddrLine1, A1.AddressInfoAddrLine2, A1.AddressInfoCity, A1.AddressInfoProv, A1.AddressInfoCode, A1.AddressInfoCountry
    , A1.AddressInfoBusPhone, A1.AddressInfoCellPhone, A1.AddressInfoHomePhone, A1.AddressInfoFaxPhone, A1.AddressInfoInternetAddr AS [EmailAddress]

    /*
    , A2.AddressInfoTitle, A2.AddressInfoFirst, A2.AddressInfoMiddle, A2.AddressInfoLastName, A2.AddressInfoSuffix, A2.AddressInfoAlias
    , A2.AddressInfoAddrType
    , A2.AddressInfoAddrLine1, A2.AddressInfoAddrLine2, A2.AddressInfoCity, A2.AddressInfoProv, A2.AddressInfoCode, A2.AddressInfoCountry
    , A2.AddressInfoBusPhone, A2.AddressInfoCellPhone, A2.AddressInfoHomePhone, A2.AddressInfoFaxPhone, A2.AddressInfoInternetAddr AS [EmailAddress]

    , A3.AddressInfoTitle, A3.AddressInfoFirst, A3.AddressInfoMiddle, A3.AddressInfoLastName, A3.AddressInfoSuffix, A3.AddressInfoAlias
    , A3.AddressInfoAddrType
    , A3.AddressInfoAddrLine1, A3.AddressInfoAddrLine2, A3.AddressInfoCity, A3.AddressInfoProv, A3.AddressInfoCode, A3.AddressInfoCountry
    , A3.AddressInfoBusPhone, A3.AddressInfoCellPhone, A3.AddressInfoHomePhone, A3.AddressInfoFaxPhone, A3.AddressInfoInternetAddr AS [EmailAddress]

    , A4.AddressInfoTitle, A4.AddressInfoFirst, A4.AddressInfoMiddle, A4.AddressInfoLastName, A4.AddressInfoSuffix, A4.AddressInfoAlias
    , A4.AddressInfoAddrType
    , A4.AddressInfoAddrLine1, A4.AddressInfoAddrLine2, A4.AddressInfoCity, A4.AddressInfoProv, A4.AddressInfoCode, A4.AddressInfoCountry
    , A4.AddressInfoBusPhone, A4.AddressInfoCellPhone, A4.AddressInfoHomePhone, A4.AddressInfoFaxPhone, A4.AddressInfoInternetAddr AS [EmailAddress]
    */
FROM dbo.Contact C
LEFT OUTER JOIN [dbo].[Person] P
	ON P.PersonInfoId = C.PersonID
LEFT OUTER JOIN [dbo].[ClntInf] CLNT
    ON CLNT.PersonID = C.PersonID
LEFT OUTER JOIN dbo.AddrInf a1
    ON A1.AddressID = P.PersonInfoMainAddressID
/*
LEFT OUTER JOIN dbo.AddrInf A2
    ON A2.AddressID = P.PersonInfoAddressID2
LEFT OUTER JOIN dbo.AddrInf A3
    ON A3.AddressID = P.PersonInfoAddressID3
LEFT OUTER JOIN dbo.AddrInf A4
    ON A4.AddressID = P.PersonInfoAddressID4
*/
LEFT OUTER JOIN dbo.LawInf L
    ON L.LawyerID = Clnt.LawyerID
LEFT OUTER JOIN DBO.CtctType CT
	ON C.ContactMainContactType=CT.TypeID

GO

CREATE OR ALTER VIEW [PcLaw].[ContactsNoPersonTable] AS

SELECT T.ContactID, T.ClientInfoClientNum
    , T.Name
    , CASE WHEN LEN(C.ContactFirmName) > 0 AND C.ContactFirmName <> T.Name THEN C.ContactFirmName END AS [ContactFirmName]
    , t.LawyerNickname, t.LawyerName
    , t.ContactMainContactType, t.ContactMainAddressID
    , t.AddressInfoTitle, t.AddressInfoFirst, t.AddressInfoMiddle, t.AddressInfoLastName, t.AddressInfoSuffix, t.AddressInfoAlias
    , t.AddressInfoAddrType
    , t.AddressInfoAddrLine1, t.AddressInfoAddrLine2, t.AddressInfoCity, t.AddressInfoProv, t.AddressInfoCode, t.AddressInfoCountry
    , t.AddressInfoBusPhone, t.AddressInfoCellPhone, t.AddressInfoHomePhone, t.AddressInfoFaxPhone, t.EmailAddress
FROM (
    SELECT  C.ContactID, C.ClientInfoClientNum
        --, C.
        --, C.ContactSortName
        , CASE WHEN LEN(C.ClientInfoDisplayAs) > 0 THEN C.ClientInfoDisplayAs
            WHEN LEN(C.ContactSortName) > 0 THEN C.ContactSortName
            WHEN LEN(dbo.fn_BuildName(A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix)) > 0 THEN dbo.fn_BuildName(A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix)
            ELSE C.ContactFirmName
            END AS [Name]
        , l.LawInfNickName AS [LawyerNickname], l.LawInfLawyerName AS [LawyerName]
        , C.ContactMainContactType
        , c.ContactMainAddressID

        , A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix, A1.AddressInfoAlias
        , A1.AddressInfoAddrType
        , A1.AddressInfoAddrLine1, A1.AddressInfoAddrLine2, A1.AddressInfoCity, A1.AddressInfoProv, A1.AddressInfoCode, A1.AddressInfoCountry
        , A1.AddressInfoBusPhone, A1.AddressInfoCellPhone, A1.AddressInfoHomePhone, A1.AddressInfoFaxPhone, A1.AddressInfoInternetAddr AS [EmailAddress]

        /*
        , A2.AddressInfoTitle, A2.AddressInfoFirst, A2.AddressInfoMiddle, A2.AddressInfoLastName, A2.AddressInfoSuffix, A2.AddressInfoAlias
        , A2.AddressInfoAddrType
        , A2.AddressInfoAddrLine1, A2.AddressInfoAddrLine2, A2.AddressInfoCity, A2.AddressInfoProv, A2.AddressInfoCode, A2.AddressInfoCountry
        , A2.AddressInfoBusPhone, A2.AddressInfoCellPhone, A2.AddressInfoHomePhone, A2.AddressInfoFaxPhone, A2.AddressInfoInternetAddr AS [EmailAddress]

        , A3.AddressInfoTitle, A3.AddressInfoFirst, A3.AddressInfoMiddle, A3.AddressInfoLastName, A3.AddressInfoSuffix, A3.AddressInfoAlias
        , A3.AddressInfoAddrType
        , A3.AddressInfoAddrLine1, A3.AddressInfoAddrLine2, A3.AddressInfoCity, A3.AddressInfoProv, A3.AddressInfoCode, A3.AddressInfoCountry
        , A3.AddressInfoBusPhone, A3.AddressInfoCellPhone, A3.AddressInfoHomePhone, A3.AddressInfoFaxPhone, A3.AddressInfoInternetAddr AS [EmailAddress]

        , A4.AddressInfoTitle, A4.AddressInfoFirst, A4.AddressInfoMiddle, A4.AddressInfoLastName, A4.AddressInfoSuffix, A4.AddressInfoAlias
        , A4.AddressInfoAddrType
        , A4.AddressInfoAddrLine1, A4.AddressInfoAddrLine2, A4.AddressInfoCity, A4.AddressInfoProv, A4.AddressInfoCode, A4.AddressInfoCountry
        , A4.AddressInfoBusPhone, A4.AddressInfoCellPhone, A4.AddressInfoHomePhone, A4.AddressInfoFaxPhone, A4.AddressInfoInternetAddr AS [EmailAddress]
        */
    FROM dbo.Contact C
    LEFT OUTER JOIN dbo.AddrInf a1
        ON A1.AddressID = C.ContactMainAddressID
    /*
    LEFT OUTER JOIN dbo.AddrInf A2
        ON A2.AddressID = P.PersonInfoAddressID2
    LEFT OUTER JOIN dbo.AddrInf A3
        ON A3.AddressID = P.PersonInfoAddressID3
    LEFT OUTER JOIN dbo.AddrInf A4
        ON A4.AddressID = P.PersonInfoAddressID4
    */
    LEFT OUTER JOIN dbo.LawInf L
        ON L.LawyerID = C.ClientInfoLawyerID
    LEFT OUTER JOIN dbo.LawInf L2
        ON L2.LawyerID = C.ContactLawyerID
) T
INNER JOIN dbo.Contact C
    ON C.ContactID = T.ContactID

GO

CREATE OR ALTER VIEW [PcLaw].[Matters] AS

SELECT M.MatterID
    , case when len(C.ClientInfoClientNum) < 3 then RIGHT(REPLICATE('0', 3) + C.ClientInfoClientNum, 3) else C.ClientInfoClientNum END AS [ClientNumber]
    , C.ClientInfoClientNum
    , TRIM(REPLACE(REPLACE(REPLACE(REPLACE(M.MatterInfoMatterNum, 'P*', ''), 'A*', ''), '  1', ''), '  2', '')) AS [MatterNumber]
    , case when CHARINDEX('-', M.MatterInfoMatterNum) = 0 then M.MatterInfoMatterNum ELSE SUBSTRING(M.MatterInfoMatterNum, CHARINDEX('-', M.MatterInfoMatterNum)+1, 3) END AS [MatterSeqNumber]
    , M.MatterInfoMatterNum
    , M.ClientInfoClientID
    , C.Name AS [ClientName]
    , M.MatterInfoFileDesc AS [MatterDescription]
    --, CASE M.MatterInfoStatus 
    --    WHEN 0 THEN 'Active' 
    --    WHEN 1 THEN 'Archived'
    --    WHEN 2 THEN 'Purged'
    --    END AS [MatterStatus]
	, CASE WHEN matterinfostatus=0 AND MatterInfoCrossReference='' THEN 'Active'
		WHEN matterinfostatus=0 AND MatterInfoCrossReference!='' THEN 'Inactive'
		WHEN matterinfostatus=1 THEN 'Archived'
		WHEN M.MatterInfoStatus=2 THEN 'Purged'
		ELSE '????' END AS [MatterStatus]
    , dbo.fn_AddMultipleStrings(
        TRIM(REPLACE(REPLACE(REPLACE(REPLACE(M.MatterInfoMatterNum, 'P*', ''), 'A*', ''), '  1', ''), '  2', ''))
        , TRIM(C.Name)
        , ' - '
        , TRIM(M.MatterInfoFileDesc)
        , DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)  AS [MatterName]
    , M.MatterInfoDocumentPath
    , Lresp.LawInfNickName AS [ResponsibleNickname], Lresp.LawInfLawyerName AS [ResponsibleName]
    , Lref.LawInfNickName AS [RefNickname], Lref.LawInfLawyerName AS [RefName]
	, M.MatterInfoReferredBy
	, C1.ContactSortName AS [ReferredBy]
    , dbo.fn_AddMultipleStrings(
        TRIM(A1.AddressInfoTitle), TRIM(A1.AddressInfoFirst), ' '
        , TRIM(A1.AddressInfoMiddle), TRIM(A1.AddressInfoLastName), TRIM(A1.AddressInfoSuffix)
        , DEFAULT, DEFAULT, DEFAULT, DEFAULT
      ) AS [BillToContact]
    , A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix, A1.AddressInfoAlias
    , A1.AddressInfoAddrLine1, A1.AddressInfoAddrLine2, A1.AddressInfoCity, A1.AddressInfoProv, A1.AddressInfoCode, A1.AddressInfoCountry
    , A1.AddressInfoInternetAddr AS [BillToEmail]
    , TRY_CONVERT(date, CONVERT(varchar, M.MatterInfoOpenDate)) AS [OpenDate]
	, M.MatterInfoOpenDate
    , MatterInfoDefRateType
	, AL.AreaOfLawName [PRACTICE AREA]
    --, m.*
	FROM dbo.MattInf M
    LEFT OUTER JOIN PcLaw.Contacts C
        ON C.ClientInfoClientID = m.ClientInfoClientID
	LEFT OUTER JOIN [dbo].[Contact] C1
		ON M.MatterInfoReferredBy = CAST(C1.ContactID as varchar)
	LEFT OUTER JOIN dbo.AddrInf A1
		ON A1.AddressID = m.MatterInfoBillAddID
		and c.PersonInfoMainAddressID <> m.MatterInfoBillAddID
	LEFT OUTER JOIN Dbo.LawInf Lresp
		ON Lresp.LawyerID = M.MatterInfoRespLwyr
	LEFT OUTER JOIN Dbo.LawInf Lref
		ON Lref.LawyerID = M.MatterInfoRefLwyr
	LEFT OUTER JOIN DBO.AreaLaw AL ON M.MatterInfoTypeofLaw=AL.AreaOfLawID

GO

CREATE OR ALTER VIEW [PcLaw].[MattersNoPersonTable] AS

SELECT M.MatterID
    , case when len(C.ClientInfoClientNum) < 3 then RIGHT(REPLICATE('0', 3) + C.ClientInfoClientNum, 3) else C.ClientInfoClientNum END AS [ClientNumber]
    , C.ClientInfoClientNum
    , TRIM(REPLACE(REPLACE(REPLACE(REPLACE(M.MatterInfoMatterNum, 'P*', ''), 'A*', ''), '  1', ''), '  2', '')) AS [MatterNumber]
    , case when CHARINDEX('-', M.MatterInfoMatterNum) = 0 then M.MatterInfoMatterNum ELSE SUBSTRING(M.MatterInfoMatterNum, CHARINDEX('-', M.MatterInfoMatterNum)+1, 3) END AS [MatterSeqNumber]
    , M.MatterInfoMatterNum
    , M.ClientInfoClientID
    , C.Name AS [ClientName]
    , M.MatterInfoFileDesc AS [MatterDescription]
    , CASE M.MatterInfoStatus 
        WHEN 0 THEN 'Active' 
        WHEN 1 THEN 'Archived'
        WHEN 2 THEN 'Purged'
        END AS [MatterStatus]
    , dbo.fn_AddMultipleStrings(
        TRIM(REPLACE(REPLACE(REPLACE(REPLACE(M.MatterInfoMatterNum, 'P*', ''), 'A*', ''), '  1', ''), '  2', ''))
        , C.Name
        , ' - '
        , M.MatterInfoFileDesc
        , DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)  AS [MatterName]
    , M.MatterInfoDocumentPath
    , Lresp.LawInfNickName AS [ResponsibleNickname], Lresp.LawInfLawyerName AS [ResponsibleName]
    , Lref.LawInfNickName AS [RefNickname], Lref.LawInfLawyerName AS [RefName]
	, M.MatterInfoReferredBy
	, C1.ContactSortName AS [ReferredBy]
    , dbo.fn_AddMultipleStrings(
        TRIM(A1.AddressInfoTitle), TRIM(A1.AddressInfoFirst), ' '
        , TRIM(A1.AddressInfoMiddle), TRIM(A1.AddressInfoLastName), TRIM(A1.AddressInfoSuffix)
        , DEFAULT, DEFAULT, DEFAULT, DEFAULT
      ) AS [BillToContact]
    , A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix, A1.AddressInfoAlias
    , A1.AddressInfoAddrLine1, A1.AddressInfoAddrLine2, A1.AddressInfoCity, A1.AddressInfoProv, A1.AddressInfoCode, A1.AddressInfoCountry
    , A1.AddressInfoInternetAddr AS [BillToEmail]
    , CONVERT(date, CONVERT(varchar, M.MatterInfoOpenDate)) AS [OpenDate]
    , MatterInfoDefRateType
    --, m.*
	FROM dbo.MattInf M
    LEFT OUTER JOIN PcLaw.Contacts C
        ON C.ContactID = m.ClientInfoClientID
	LEFT OUTER JOIN [dbo].[Contact] C1
		ON M.MatterInfoReferredBy = CAST(C1.ContactID as varchar)
	LEFT OUTER JOIN dbo.AddrInf A1
		ON A1.AddressID = m.MatterInfoBillAddID
		and c.ContactMainAddressID <> m.MatterInfoBillAddID
	LEFT OUTER JOIN Dbo.LawInf Lresp
		ON Lresp.LawyerID = M.MatterInfoRespLwyr
	LEFT OUTER JOIN Dbo.LawInf Lref
		ON Lref.LawyerID = M.MatterInfoRefLwyr

GO

CREATE OR ALTER VIEW [PcLaw].[MatterCustomFields] AS

SELECT M.MatterID, M.MatterInfoSortName
    , T9.Template AS [LedesFormat]
    , F9_1.FieldValue AS [InvoiceDescription]
    , F9_2.FieldValue AS [ClientMatterId]
    , F20000_1.FieldValue AS [ClaimsProfessional]
    , F20000_2.FieldValue AS [InsuranceCompany]
    , F20000_3.FieldValue AS [PolicyNumber]
    , F20000_4.FieldValue AS [ClaimNumber]
    , F20000_5.FieldValue AS [Claimant]
    , F20000_6.FieldValue AS [DateOfLoss]
    , F20000_7.FieldValue AS [Insured]
    , F20000_8.FieldValue AS [Tax ID]
    , CASE WHEN LEN(F20000_9.FieldValue) > 0 AND LEN(F20000_10.FieldValue) > 0 THEN F20000_9.FieldValue + CHAR(10) + CHAR(13) + F20000_10.FieldValue
        WHEN LEN(F20000_9.FieldValue) > 0 THEN F20000_9.FieldValue
        WHEN LEN(F20000_10.FieldValue) > 0 THEN F20000_10.FieldValue
        END AS [BillingRules]
    --, F20000_9.FieldValue AS [BillingRules]
    --, F20000_10.FieldValue AS [BillingRules2]
FROM dbo.MattInf M
LEFT OUTER JOIN dbo.LnkCstTb T9 ON T9.LnkEntID = m.MatterID AND T9.TabID = 9
LEFT OUTER JOIN dbo.LnkCstfL F9_1 ON F9_1.LinkID= T9.LinkID AND F9_1.FieldID = 1
LEFT OUTER JOIN dbo.LnkCstfL F9_2 ON F9_2.LinkID= T9.LinkID AND F9_2.FieldID = 2
--LEFT OUTER JOIN dbo.LnkCstTb T29 ON T29.LnkEntID = m.MatterID AND T29.TabID = 29
LEFT OUTER JOIN dbo.LnkCstTb T20000 ON T20000.LnkEntID = m.MatterID AND T20000.TabID = 20000
LEFT OUTER JOIN dbo.LnkCstfL F20000_1 ON F20000_1.LinkID= T20000.LinkID AND F20000_1.FieldID = 1
LEFT OUTER JOIN dbo.LnkCstfL F20000_2 ON F20000_2.LinkID= T20000.LinkID AND F20000_2.FieldID = 2
LEFT OUTER JOIN dbo.LnkCstfL F20000_3 ON F20000_3.LinkID= T20000.LinkID AND F20000_3.FieldID = 3
LEFT OUTER JOIN dbo.LnkCstfL F20000_4 ON F20000_4.LinkID= T20000.LinkID AND F20000_4.FieldID = 4
LEFT OUTER JOIN dbo.LnkCstfL F20000_5 ON F20000_5.LinkID= T20000.LinkID AND F20000_5.FieldID = 5
LEFT OUTER JOIN dbo.LnkCstfL F20000_6 ON F20000_6.LinkID= T20000.LinkID AND F20000_6.FieldID = 6
LEFT OUTER JOIN dbo.LnkCstfL F20000_7 ON F20000_7.LinkID= T20000.LinkID AND F20000_7.FieldID = 7
LEFT OUTER JOIN dbo.LnkCstfL F20000_8 ON F20000_8.LinkID= T20000.LinkID AND F20000_8.FieldID = 8
LEFT OUTER JOIN dbo.LnkCstfL F20000_9 ON F20000_9.LinkID= T20000.LinkID AND F20000_9.FieldID = 9
LEFT OUTER JOIN dbo.LnkCstfL F20000_10 ON F20000_10.LinkID= T20000.LinkID AND F20000_10.FieldID = 10
WHERE EXISTS (SELECT * FROM dbo.LnkCstTb T WHERE T.LinkID = M.MatterID)

GO

CREATE OR ALTER VIEW [PcLaw].[BillableTime] AS

SELECT E.TimeId, E.EntryDate, E.TimeAdvisorID, e.TranIndexEntryType
    , E.ClientNumber, E.ClientName
    , E.MatterID, E.MatterNumber, E.MatterName
    , E.LawyerID, E.LawInfNickName, E.LawInfInitials, E.LawInfLawyerName
    , E.ActualHours
    , CASE WHEN E.Amount = 0 THEN E.BillingHours
        WHEN convert(decimal(18,2), E.BillingHours * E.ActualRate) <> E.Amount THEN 1
        ELSE E.BillingHours
        END AS [BillableHours]
    , CASE WHEN E.Amount = 0 THEN E.ActualRate
        WHEN convert(decimal(18,2), E.BillingHours * E.ActualRate) <> E.Amount THEN E.Amount
        ELSE E.ActualRate 
        END AS [Price]
    , E.InternalRate
    , E.IsFlatRate, E.IsNonBillable, CONVERT(decimal(18,2), E.Amount) AS [Amount]
    , CASE WHEN E.ACTIVITYCODESID IS NOT NULL THEN CONCAT(E.ACTIVITYCODESNAME, E.Description) ELSE E.Description END [DESCRIPTION]
    , E.InvoiceId, E.InvoiceDate, E.InvoiceNumber
    , E.AreaOfLawID, E.AreaOfLawNickName, E.AreaOfLawName
    , E.ActivityCodesID, E.ActivityCodesNickname, E.ActivityCodesName
	, E.TimeEntryHoldFlag
	, CASE WHEN E.ACTIVITYCODESID IS NOT NULL THEN CONCAT('TA-', E.ActivityCodesID) END [ActivityCodeImportID]
FROM (
	SELECT 
		EntryID AS [TimeId]
		, TRY_CONVERT(date, CONVERT(varchar(100), TimeEntryDate)) AS [EntryDate]
		, TA.TimeAdvisorID, X.TranIndexEntryType
		, CASE WHEN E.TimeEntryInvID <> 0 THEN CONVERT(varchar(50), E.TimeEntryInvID)
				-- If we have an invoice date, that shows that the expense is billed, even if the bill isn't in the system
			   WHEN E.TimeEntryInvDate > 0 THEN CONVERT(varchar(50), m.MatterID) + ':' + CONVERT(varchar(50), ISNULL(e.TimeEntryInvNumber, 0))
			   END AS [InvoiceId]
        , CASE WHEN E.TimeEntryInvDate > 0 THEN TRY_CONVERT(date, CONVERT(varchar(100), TimeEntryInvDate)) END AS [InvoiceDate]
        , CASE WHEN E.TimeEntryInvNumber <> 0 THEN TimeEntryInvNumber END AS [InvoiceNumber]
		, M.ClientNumber, M.ClientName
		, M.MatterID, M.MatterNumber, M.MatterName
		, L.LawyerID, L.LawInfNickName, L.LawInfInitials, L.LawInfLawyerName--, L.*
		, CONVERT(decimal(18,8), E.TimeEntryActualHours) / 3600 AS [ActualHours]
		, CASE WHEN TimeEntryAmount > 0 AND E.TimeEntryBillingHours = 0 THEN 1 ELSE CONVERT(decimal(18,8), E.TimeEntryBillingHours) / 3600 END AS [BillingHours]
		, CONVERT(decimal(18,8), CASE WHEN TimeEntryAmount > 0 AND E.TimeEntryActualRate = 0 THEN TimeEntryAmount ELSE E.TimeEntryActualRate END ) AS [ActualRate]
		, CONVERT(decimal(18,8), TimeEntryInternalRate) AS [InternalRate]
		, CASE WHEN TimeEntryAmount > 0 AND E.TimeEntryBillingHours = 0 THEN 1 ELSE 0 END AS [IsFlatRate]
		, CASE WHEN TimeEntryBillingHours <> 0 AND TimeEntryActualRate <> 0 AND TimeEntryAmount = 0 THEN 1 ELSE 0 END AS [IsNonBillable]
		, CONVERT(decimal(18,2), TimeEntryAmount) AS [Amount]
		, E.TimeEntryExplanation AS [Description]
		, A.AreaOfLawID, A.AreaOfLawNickName, A.AreaOfLawName
		, AC.ActivityCodesID, AC.ActivityCodesNickname, AC.ActivityCodesName
		, E.TimeEntryHoldFlag
	FROM [dbo].[TimeEnt] E
    INNER JOIN dbo.TranIDX X
        ON X.TranIndexSequenceID = E.EntryID
        and X.TranIndexStatus = 0
        and X.TranIndexEntryType NOT IN (999, 201) -- 999 = Write Off, 201 = Flat Fee summary (this one doubles up with type 200 which we DO include)
	INNER JOIN PcLaw.Matters M
		ON M.MatterID = E.MatterID
	LEFT OUTER JOIN dbo.TimeAdvr TA
		ON TA.TimeAdvisorEntryID = E.EntryID
	LEFT OUTER JOIN dbo.LawInf L
		ON L.LawyerID = E.LawyerID
	LEFT OUTER JOIN dbo.AreaLaw A
		ON A.AreaOfLawID = E.AreaOfLawID
	LEFT OUTER JOIN dbo.ActCode AC
		ON AC.ActivityCodesID = E.TimeEntryActivity
	where TimeEntryStatus = 0
) E

GO

CREATE OR ALTER VIEW [PcLaw].[BillableExpenses] AS

        SELECT 
            --E.tbl_PK_id AS [ExpenseId]
            CONVERT(varchar(50), GBankAllocInfCheckID) + '-' + CONVERT(varchar(50), GBankAllocInfAllocID) AS [ExpenseId]
        -- Adding all of these types, even though many are not expenses.  That way we have a single place to see all of the types we know about
        , E.GBankAllocInfEntryType
        , CASE GBankAllocInfEntryType
            WHEN 1101 THEN 'Rcpt'
            WHEN 1102 THEN 'Add to Retainer for a Matter'
            WHEN 1103 THEN 'Apply Retainer to Bill'
            WHEN 1104 THEN 'Retainers Carried Forward'
            WHEN 1400 THEN 'Billable Expense on a Check'
            WHEN 1600 THEN 'Billable Expense with no AP'
            WHEN 6500 THEN 'Billable Expense on a Vendor Bill'
            END AS TypeName
        , CASE WHEN C.GBankCommInfDate IS NOT NULL THEN CONVERT(date, CONVERT(varchar(100), C.GBankCommInfDate))
            WHEN v.APInvoiceEntryDate IS NOT NULL THEN CONVERT(date, CONVERT(varchar(100), v.APInvoiceEntryDate))
            END AS [EntryDate]
        , c.GBankCommInfCheck AS [ReferenceNumber]
        , C.GBankCommInfPaidTo AS [Payee]
        , V.APInvoiceID AS [VendorBillId]
        , V.APInvoiceInvNumr AS [VendorBillNumber]
		, M.ClientNumber, M.ClientName
        , E.MatterID, M.MatterNumber, M.MatterName
		, CASE WHEN E.GBankAllocInfInvID <> 0 THEN CONVERT(varchar(50), E.GBankAllocInfInvID)
			   END AS [InvoiceId]
        , CASE WHEN E.GBankAllocInfInvDate > 0 THEN CONVERT(date, CONVERT(varchar(100), GBankAllocInfInvDate)) END AS [InvoiceDate]
        , CASE WHEN E.GBankAllocInfInvNumber <> 0 THEN GBankAllocInfInvNumber END AS [InvoiceNumber]
        , 1 AS [Quantity]
        , CONVERT(decimal(18,2), E.GBankAllocInfAmount) AS [Amount]
		, CASE WHEN e.GBankAllocInfTaskID = 0 THEN NULL ELSE E.GBankAllocInfTaskID END AS [TaskId], T.TaskListNickName, T.TaskListName
		, CASE WHEN e.GBankAllocInfActivityID = 0 THEN NULL ELSE E.GBankAllocInfActivityID END AS [ActivityId], A.ActivityCodesNickname, A.ActivityCodesName
        , CASE WHEN E.GBankAllocInfActivityID IS NOT NULL THEN CONCAT(A.ActivityCodesName, ' ', E.GBankAllocInfExplanation) ELSE E.GBankAllocInfExplanation END AS [Description]

      ,[GBankAllocInfCheckID]
--      ,[GBankAllocInfAllocID]
--      ,[GBankAllocInfGLID]
--      ,[GBankAllocInfGSTCat]		-- STUDY THIS
--      ,[GBankAllocInfTaxStatus] -- only 17, same as adv id rows, all have ID 16 as value
--      ,[GBankAllocInfAdvID]		-- only 16
		, E.GBankAllocInfHoldFlag
		, CASE WHEN E.GBankAllocInfActivityID IS NOT NULL THEN CONCAT('EA-', E.GBankAllocInfActivityID) END [ActivityCodeImportID]
    FROM dbo.GBAlloc E
    LEFT OUTER JOIN dbo.GBComm C
        ON E.GBankAllocInfEntryType IN (1600,1400) AND C.GBankCommInfID = E.GBankAllocInfCheckID
    LEFT OUTER JOIN dbo.APInv V
        ON E.GBankAllocInfEntryType = 6500 AND V.APInvoiceID = E.GBankAllocInfCheckID
    INNER JOIN PcLaw.Matters M
        oN M.MatterID = E.MatterID
	LEFT OUTER JOIN dbo.TaskList T
		ON T.TaskListID = E.GBankAllocInfTaskID
	LEFT OUTER JOIN dbo.ActCode A
		ON A.ActivityCodesID = E.GBankAllocInfActivityID
	WHERE e.GBankAllocInfStatus = 0
 		AND E.MatterID <> 0
        AND E.GBankAllocInfEntryType IN (6500,1600,1400) -- These are the types we know about for expenses

GO

CREATE OR ALTER VIEW [PCLAW].[BillingCodes] AS

SELECT DISTINCT ActivityCodeImportID
, BT.ActivityCodesName
, BT.ActivityCodesNickname
, 'Time' [TYPE]
, 'PCLaw Time Activity Codes' [CLASS]
FROM PCLAW.BillableTime BT
WHERE ActivityCodeImportID IS NOT NULL
UNION ALL
SELECT DISTINCT ActivityCodeImportID
, BE.ActivityCodesName
, BE.ActivityCodesNickname
, 'Expense' [TYPE]
, 'PCLaw Expense Activity Codes' [CLASS]
FROM PCLAW.BillableExpenses BE
WHERE ActivityCodeImportID IS NOT NULL

GO

CREATE OR ALTER VIEW [PcLaw].[Invoices] AS

    SELECT I.InvoiceID
		, try_CONVERT(date, CONVERT(varchar(100), I.ARInvoiceDate)) AS [IssueDate]
		, I.ARInvoiceInvNumber AS [InvoiceNumber]
		, CONVERT(decimal(18,8), I.ARInvoiceHours) / 3600 AS [InvoiceHours]
        --, t.BillingHours
		--, -t.CourtesyDiscount AS [Discount]
        , CONVERT(decimal(18,2), i.ARInvoiceFees) AS [TotalFees]
        --, t.TotalFees
        , CONVERT(decimal(18,2), i.ARInvoiceDisbs) AS [TotalExpenses]
        --, e.TotalExpenses
        , i.ARInvoiceFees + i.ARInvoiceDisbs AS [Total]
        , ISNULL(P.TotalPaid, 0) AS [TotalPaid], P.LastPayment
        , ISNULL(C.TotalWriteOff, 0) AS [TotalWriteOff], C.LastCredit
        , CONVERT(decimal(18,2), i.ARInvoiceFees + i.ARInvoiceDisbs - ISNULL(P.TotalPaid, 0) - ISNULL(C.TotalWriteOff, 0)) AS [Balance]
		, M.ClientInfoClientID AS [ClientId], M.ClientNumber, M.ClientName
		, M.MatterID, M.MatterNumber, M.MatterName, m.MatterStatus
		, L.LawyerID, L.LawInfNickName, L.LawInfInitials, L.LawInfLawyerName--, L.*
        , A.AreaOfLawID, A.AreaOfLawNickName, A.AreaOfLawName
--        , I.ARInvoiceGSTGLID
    FROM dbo.ARInv I
	INNER JOIN PcLaw.Matters M
		ON M.MatterID = I.MatterID
    INNER JOIN dbo.TranIDX X
        ON X.TranIndexSequenceID = I.InvoiceID
        AND X.TranIndexStatus = 0
    LEFT OUTER JOIN dbo.LawInf L
        ON L.LawyerID = I.ARInvoiceCollLwyrID
    LEFT OUTER JOIN dbo.AreaLaw A
        ON A.AreaOfLawID = I.ARInvoiceTypeofLaw
    LEFT OUTER JOIN (
        SELECT P.GBankARRcptAllocInvID, sum(p.GBankARRcptAllocAmount) AS [TotalPaid], MAX(P.GBankARRcptAllocDate) AS [LastPayment]
        FROM dbo.GBRcptA p
        WHERE P.GBankARRcptAllocStatus = 0
		AND P.GBankARRcptAllocEntryType <> 5
        GROUP BY P.GBankARRcptAllocInvID
    ) P
        ON P.GBankARRcptAllocInvID = I.InvoiceID
    LEFT OUTER JOIN (
        SELECT C.ARWriteOffInvID, sum(d.DistributionTotal) AS [TotalWriteOff], MAX(C.ARWriteOffDate) AS [LastCredit]
        FROM dbo.ARWO C
        LEFT OUTER JOIN (
            SELECT D.WOID, -SUM(D.ARLawyerSplitAmount) AS [DistributionTotal]
            FROM ARLwySpl D
            WHERE D.WOID <> 0
            GROUP BY D.WOID
        ) D
            ON D.WOID = C.WOID
        WHERE C.ARWriteOffStatus = 0
        GROUP BY C.ARWriteOffInvID
    ) C
        ON c.ARWriteOffInvID = I.InvoiceID
 --   LEFT OUTER JOIN (
 --       SELECT T.InvoiceId
 --           --, ISNULL(D.CourtesyDiscount, 0.00) AS [CourtesyDiscount]
 --           , sum(t.BillableHours) AS [BillingHours], SUM(T.ActualHours) AS [ActualHours]
 --           , sum(convert(DECIMAL(18,2), t.Amount)) AS [TotalFees]
 --       FROM PcLaw.BillableTime T
 --       --LEFT OUTER JOIN (
 --       --    SELECT T.TimeEntryInvID, T.EntryID AS [EOMEntry], T.TimeEntryAmount AS [CourtesyDiscount]
 --       --    FROM dbo.TimeEnt T
 --       --    WHERE T.TimeEntryEOMFlag = 2
 --       --        AND T.TimeEntryStatus = 0
 --       --) D
 --       --    ON D.TimeEntryInvID = T.InvoiceId
 --       WHERE T.InvoiceId <> 0
 --           --AND (D.EOMEntry IS NULL OR T.TimeId < D.EOMEntry)
 --       GROUP BY T.InvoiceId--, D.CourtesyDiscount
 --   ) T
 --       ON T.InvoiceId = I.InvoiceID
	--LEFT OUTER JOIN (
	--	SELECT E.InvoiceId
	--		, SUM(CONVERT(decimal(18,2), E.Amount)) AS [TotalExpenses]
	--	FROM PcLaw.BillableExpenses E          -- This table stores expenses and payments
	--	WHERE E.MatterID <> 0
	--		AND E.InvoiceId <> 0
 --       GROUP BY E.InvoiceId
	--) E
	--	ON E.InvoiceId = I.InvoiceID
    where i.ARInvoiceStatus = 0


GO

CREATE OR ALTER VIEW [PcLaw].[TrustTransactions] AS

    SELECT 
    T.[TBankAllocInfAllocID] AS [TransactionId]
		, CONVERT(date, CONVERT(varchar(100), c.TBankCommInfDate)) AS [TransactionDate]
      ,T.[TBankAllocInfoEntryType]
    , CASE T.[TBankAllocInfoEntryType] 
        WHEN 2050 THEN 'Deposit'
        WHEN 2400 THEN 'Deposit' -- Opening balances
        WHEN 2049 THEN 'Disburse Funds'
        WHEN 2053 THEN 'Disburse Funds'
        WHEN 2052 THEN 'Transfer'
        END AS [TypeName]
    , CONVERT(decimal(18,2), 
        CASE WHEN T.[TBankAllocInfoEntryType] IN (2049, 2053) THEN t.TBankAllocInfoAmount
        WHEN T.[TBankAllocInfoEntryType] = 2052 AND t.TBankAllocInfoAmount > 0 THEN ABS(T.TBankAllocInfoAmount)
        ELSE 0
        END) AS [Debit]
    , CONVERT(decimal(18,2), CASE WHEN T.[TBankAllocInfoEntryType] IN (2050, 2400) THEN t.TBankAllocInfoAmount
        WHEN T.[TBankAllocInfoEntryType] = 2052 AND t.TBankAllocInfoAmount < 0 THEN abs(T.TBankAllocInfoAmount)
        ELSE 0
        END) AS [Credit]
    , CONVERT(decimal(18,2), CASE WHEN T.[TBankAllocInfoEntryType] IN (2049, 2053) THEN -t.TBankAllocInfoAmount
        WHEN T.[TBankAllocInfoEntryType] = 2052 THEN -t.TBankAllocInfoAmount
        ELSE T.TBankAllocInfoAmount
        END) AS [Value]
	, M.ClientNumber, M.ClientName
	, M.MatterID, M.MatterNumber, M.MatterName
		, CASE WHEN T.TBankAllocInfInvID <> 0 THEN CONVERT(varchar(50), T.TBankAllocInfInvID)
				-- If we have an invoice date, that shows that the expense is billed, even if the bill isn't in the system
			   WHEN T.TBankAllocInfInvDate > 0 THEN CONVERT(varchar(50), T.TBankAllocInfInvDate) + ':' + CONVERT(varchar(50), ISNULL(T.TBankAllocInfInvNumber, 0))
			   END AS [InvoiceId]
        , CASE WHEN T.TBankAllocInfInvDate > 0 THEN CONVERT(date, CONVERT(varchar(100), T.TBankAllocInfInvDate)) END AS [InvoiceDate]
        , CASE WHEN T.TBankAllocInfInvNumber <> 0 THEN T.TBankAllocInfInvNumber END AS [InvoiceNumber]

		, CASE WHEN t.TBankAllocInfTaskID = 0 THEN NULL ELSE T.TBankAllocInfTaskID END AS [TaskId], TL.TaskListNickName, TL.TaskListName
		, CASE WHEN T.TBankAllocInfActivityID = 0 THEN NULL ELSE t.TBankAllocInfActivityID END AS [ActivityId], A.ActivityCodesNickname, A.ActivityCodesName
      , CASE WHEN LEN(T.[TBankAllocInfExplanation]) > 0 THEN T.[TBankAllocInfExplanation]
        ELSE C.TBankCommInfPaidTo END AS [Description]
      , C.TBankCommInfPaidTo AS [PayTo]
      , TA.TBankAcctInfGLAccountID, TA.TBankAcctInfBank, TA.TBankAcctInfBranch, TA.TBankAcctInfAccountNumber
      , ta.TBankAcctInfBankAccountID, ta.TBankAcctInfNickName
      ,T.[TBankAllocInfGLID]
      ,T.[TBankAllocInfoEOMFlag]
      ,T.[TBankAllocInfGSTCat]
      , T2.[TBankAllocInfAllocID] AS [TransferTransactionId]
      --, C.*
  FROM [dbo].[TBAlloc]  T
  INNER JOIN dbo.TBComm C
        ON C.TBankCommInfSequenceID = T.TBankAllocInfoCheckID
        AND C.TBankCommInfStatus = 0
    LEFT OUTER JOIN dbo.TBAcctI TA
        ON TA.TBankAcctInfBankAccountID = C.TBankCommInfAccountID
  LEFT OUTER JOIN PcLaw.Matters M
    ON M.MatterID = T.MatterID
	LEFT OUTER JOIN dbo.TaskList TL
		ON TL.TaskListID = T.TBankAllocInfTaskID
	LEFT OUTER JOIN dbo.ActCode A
		ON A.ActivityCodesID = T.TBankAllocInfActivityID
  LEFT OUTER JOIN dbo.TBAlloc T2
    ON T.[TBankAllocInfoEntryType] = 2052
    AND T2.TBankAllocInfoEntryType = T.TBankAllocInfoEntryType
    AND T.TBankAllocInfoCheckID = T2.TBankAllocInfoCheckID
    AND t2.[TBankAllocInfAllocID] <> T.[TBankAllocInfAllocID]
  WHERE T.TBankAllocInfoStatus = 0

GO

CREATE OR ALTER VIEW [PcLaw].[SummaryTrustBalance] AS

SELECT MatterID, MatterNumber, MatterName, ClientName, T.TBankAcctInfNickName, TBankAcctInfBank, SUM(T.Value) AS [TrustBalance], MAX(t.TransactionDate) AS [LastTransaction]
FROM PcLaw.TrustTransactions T
GROUP BY MatterID, MatterNumber, MatterName, ClientName, T.TBankAcctInfNickName, TBankAcctInfBank
HAVING SUM(T.Value) <> 0

go

CREATE OR ALTER VIEW [PcLaw].[TrustReplenishmentSettings] AS

SELECT M.MatterID, M.ClientNumber, M.ClientName
	, M.MatterNumber, M.MatterName, b.MatterBillSettingsMinRetainerBalance AS [MinBalance], MatterBillSettingsSpareAmount1 AS [TargetBalance]
FROM PcLaw.Matters M
INNER JOIN dbo.MattInf M2
    oN M2.MatterID = M.MatterID
INNER JOIN dbo.MattBill B
    ON B.MatterBillSettingsSeqID = M2.MatterInfoSpareLong2
    and b.MatterBillSettingsMinRetainerBalance <> 0

GO

CREATE OR ALTER VIEW [PcLaw].[RateTables] AS

-- No effective date, only most recent rates
SELECT RateInfName AS [RateTableName], LawInfNickName AS [UserName], NULL AS [GroupName], LawRateAmount AS [Rate], NULL AS [EffectiveDate]
FROM (
    -- This ensures that we only get the most recent rates for each Rate Table + Lawyer combo
    SELECT  LR.RateID, LR.LawyerID, LR.LawRateInternalAmount, ROW_NUMBER() OVER (PARTITION BY RateID, LawyerID ORDER BY LawRateInternalAmount DESC) AS [RowNumber]
    FROM DBO.LawRate LR
) T
INNER JOIN dbo.LawRate LR
    ON LR.RateID = T.RateID
    AND LR.LawyerID = T.LawyerID
    AND LR.LawRateInternalAmount = T.LawRateInternalAmount
INNER JOIN dbo.RateInf R
    ON R.RateID = LR.RateID
INNER JOIN dbo.LawInf L
    ON L.LawyerID = LR.LawyerID
WHERE T.RowNumber = 1

GO


CREATE OR ALTER VIEW [PcLaw].[MatterRateTables] AS

SELECT m.MatterID AS [ImportID], R.RateInfName AS [RateTableName]
FROM PcLaw.Matters M
INNER JOIN dbo.RateInf R
    ON R.RateID = M.MatterInfoDefRateType

GO


CREATE OR ALTER VIEW [PcLaw].[MatterRateExceptions] AS

SELECT c.MatterID AS [ImportID], l.LawInfNickName AS [UserName], NULL AS [GroupName], C.CaseLawyerRateAmt AS [Rate], NULL AS [EffectiveDate]
from dbo.CaseLwyr C
INNER JOIN dbo.LawInf L
    ON L.LawyerID = C.LawyerID
WHERE C.CaseLawyerInfoType = 1

GO

CREATE OR ALTER VIEW [PcLaw].[PaymentDistributions] AS

SELECT CONVERT(varchar(20), P.GBankARRcptAllocCheckID) + '-' + CONVERT(varchar(20), M.MatterID) + '-' + CONVERT(varchar(20), P.GBankARRcptAllocInvID) AS [DistributionID]
    , CONVERT(varchar(20), P.GBankARRcptAllocCheckID) + '-' + CONVERT(varchar(20), M.MatterID) + '-' + CONVERT(VARCHAR(20), P.GBankARRcptAllocDate) AS [PaymentID]
    --, P.GBankARRcptAllocCheckID
    , P.GBankARRcptAllocInvID AS [InvoiceId]
	, M.MatterID 
    , CONVERT(date, CONVERT(varchar(100), P.GBankARRcptAllocDate)) AS [PaymentDate]
    , sum(convert(DECIMAL(18,2), p.GBankARRcptAllocAmount)) AS [TotalPaid]
FROM dbo.GBRcptA p
INNER JOIN dbo.ARInv I
    ON I.InvoiceID = P.GBankARRcptAllocInvID
INNER JOIN PcLaw.Matters M
	ON M.MatterID = I.MatterID
WHERE P.GBankARRcptAllocStatus = 0
AND P.GBankARRcptAllocEntryType <> 5
GROUP BY P.GBankARRcptAllocCheckID, P.GBankARRcptAllocInvID, P.GBankARRcptAllocDate, M.MatterID
having sum(convert(DECIMAL(18,2), p.GBankARRcptAllocAmount)) <> 0

GO

CREATE OR ALTER VIEW [PcLaw].[Payments] AS

SELECT P.PaymentID, P.PaymentDate, P.PaymentAmount, P.DistributionCount
	, M.ClientInfoClientID AS [ClientId], M.ClientNumber, M.ClientName
	, M.MatterID, M.MatterNumber, M.MatterName, m.MatterStatus
FROM (
    SELECT P.PaymentID, P.MATTERID, P.PaymentDate, SUM(P.TotalPaid) AS [PaymentAmount], COUNT(*) AS [DistributionCount]
    FROM (
        SELECT CONVERT(varchar(20), P.GBankARRcptAllocCheckID) + '-' + CONVERT(varchar(20), I.MatterID) + '-' + CONVERT(VARCHAR(20), P.GBankARRcptAllocDate) AS [PaymentID]
            , P.GBankARRcptAllocCheckID, I.MatterID, P.GBankARRcptAllocInvID
            , CONVERT(date, CONVERT(varchar(100), P.GBankARRcptAllocDate)) AS [PaymentDate]
            , sum(convert(DECIMAL(18,2), p.GBankARRcptAllocAmount)) AS [TotalPaid]
        FROM dbo.GBRcptA p
        INNER JOIN dbo.ARInv I
            ON I.InvoiceID = P.GBankARRcptAllocInvID
        WHERE P.GBankARRcptAllocStatus = 0
		AND P.GBankARRcptAllocEntryType <> 5
        GROUP BY P.GBankARRcptAllocCheckID, P.GBankARRcptAllocInvID, P.GBankARRcptAllocDate, I.MatterID
        having sum(convert(DECIMAL(18,2), p.GBankARRcptAllocAmount)) <> 0
    ) P
    GROUP BY P.PaymentID, P.MATTERID, P.PaymentDate
) P
INNER JOIN PcLaw.Matters M
	ON M.MatterID = P.MatterID
WHERE P.PaymentAmount <> 0

GO

CREATE OR ALTER VIEW [PcLaw].[Credits] AS

 SELECT c.WOID
	, M.ClientInfoClientID AS [ClientId], M.ClientNumber, M.ClientName
	, M.MatterID, M.MatterNumber, M.MatterName, m.MatterStatus
    , C.ARWriteOffInvID AS [InvoiceID]
    , CONVERT(date, CONVERT(varchar(100), c.ARWriteOffDate)) AS [CreditDate]
    , d.DistributionTotal AS [CreditAmount]
    , C.ARWriteOffExplanation
    --, sum(d.DistributionTotal) AS [TotalWriteOff]
FROM dbo.ARWO C
INNER JOIN PcLaw.Matters M
	ON M.MatterID = C.MatterID
LEFT OUTER JOIN (
    SELECT D.WOID, -SUM(D.ARLawyerSplitAmount) AS [DistributionTotal]
    FROM ARLwySpl D
    WHERE D.WOID <> 0
    GROUP BY D.WOID
) D
    ON D.WOID = C.WOID
WHERE C.ARWriteOffStatus = 0

GO

CREATE OR ALTER VIEW [PcLaw].[Vendors] AS

select V.APVendorListID
    , V.APVendorListStatus AS [ActiveStatus]
    , V.APVendorListNickName AS [VendorNum]
    , V.APVendorListSortName AS [Name]
    , V.APVendorList1099BoxNum AS [BoxNum]
    , V.APVendorListID1099, V.APVendorListType1099, V.APVendorListAcctNum
    , A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix, A1.AddressInfoAlias
    , A1.AddressInfoAddrType
    , A1.AddressInfoAddrLine1, A1.AddressInfoAddrLine2, A1.AddressInfoCity, A1.AddressInfoProv, A1.AddressInfoCode, A1.AddressInfoCountry
    , A1.AddressInfoBusPhone, A1.AddressInfoCellPhone, A1.AddressInfoHomePhone, A1.AddressInfoFaxPhone, A1.AddressInfoInternetAddr AS [EmailAddress]
FROM [dbo].[APVendLi] V
LEFT OUTER JOIN dbo.Person P
    ON P.PersonInfoID = V.APVendorListPersonID
LEFT OUTER JOIN dbo.AddrInf a1
    ON A1.AddressID = P.PersonInfoMainAddressID

GO 

CREATE OR ALTER VIEW [PcLaw].[VendorsNoPersonTable] AS

select V.APVendorListID
    , V.APVendorListStatus AS [ActiveStatus]
    , V.APVendorListNickName AS [VendorNum]
    , V.APVendorListSortName AS [Name]
    , V.APVendorList1099BoxNum AS [BoxNum]
    , V.APVendorListID1099, V.APVendorListType1099, V.APVendorListAcctNum
    , A1.AddressInfoTitle, A1.AddressInfoFirst, A1.AddressInfoMiddle, A1.AddressInfoLastName, A1.AddressInfoSuffix, A1.AddressInfoAlias
    , A1.AddressInfoAddrType
    , A1.AddressInfoAddrLine1, A1.AddressInfoAddrLine2, A1.AddressInfoCity, A1.AddressInfoProv, A1.AddressInfoCode, A1.AddressInfoCountry
    , A1.AddressInfoBusPhone, A1.AddressInfoCellPhone, A1.AddressInfoHomePhone, A1.AddressInfoFaxPhone, A1.AddressInfoInternetAddr AS [EmailAddress]
FROM [dbo].[APVendLi] V
LEFT OUTER JOIN dbo.Contact P
    ON P.ContactID = V.APVendorListPersonID
LEFT OUTER JOIN dbo.AddrInf a1
    ON A1.AddressID =  P.ContactMainAddressID

GO 

CREATE OR ALTER VIEW [PcLaw].[ChartOfAccounts] AS

SELECT A.GLAcctID, GLAccountStatus
    , GLAccountType
    , CASE WHEN GLAccountType = 1000 THEN 'Bank'
        WHEN GLAccountType = 2000 THEN 'Fixed Asset'
        WHEN GLAccountType = 3000 THEN 'Current Liability'
        WHEN GLAccountType = 3500 THEN 'Long Term Liability'
        WHEN GLAccountType = 4000 THEN 'Equity Contributions'
        WHEN GLAccountType = 5000 THEN 'Equity Withdrawals'
        WHEN GLAccountType = 6000 THEN 'Income'
        WHEN GLAccountType = 7000 THEN 'Expense'
        END AS [AccountType]
    , CASE WHEN GLAccountType IN (1000,2000,7000) THEN 'Debit'
        WHEN GLAccountType IN (3000,3500,4000,5000,6000) THEN 'Credit'
        END AS [ToIncrease]
    , GLAccountNickName, GLAccountAcctName
FROM GLAcct A
WHERE A.GLAccountStatus = 0

GO


CREATE OR ALTER VIEW [PcLaw].[ChartOfAccountsImport] AS

SELECT GLAccountAcctName AS [AccountName], GLAccountNickName AS [CBAccountNumber]
    , NULL AS [ParentAccountName], AccountType, NULL AS [AccountSubType]
    , NULL AS [FinancialInstitution], NULL AS [RoutingNumber], NULL AS [BankAccountNumber]
    , NULL AS [NextCheckNumber], NULL AS [Description], NULL AS [OpeningBalance]
    , ToIncrease
FROM PcLaw.ChartOfAccounts

GO
/*

--SELECT * FROM PcLaw.Invoices
--SELECT * FROM PcLaw.BillableExpenses
--SELECT MatterID, MatterNumber, MatterName, T.TypeName, Debit, Credit, Value
--    , TransferTransactionId
--FROM pclaw.trusttransactions T
--ORDER BY T.TypeName, abs(t.Value)

SELECT MatterID, MatterNumber, MatterName, SUM(T.Value)
FROM PcLaw.TrustTransactions T
GROUP BY MatterID, MatterNumber, MatterName
HAVING SUM(T.Value) <> 0
ORDER BY SUM(T.Value)

SELECT * FROM DBO.TBAlloc T 
  LEFT OUTER JOIN dbo.TBComm C
    ON C.TBankCommInfSequenceID = T.TBankAllocInfoCheckID
    WHERE T.MatterID IN (2130, 2121, 2628, 2153, 2127) AND T.TBankAllocInfoStatus = 0
ORDER BY MatterID

SELECT * FROM PcLaw.TrustTransactions T WHERE T.MatterID IN (2130, 2121, 2628, 2153, 2127)
ORDER BY MatterID

SELECT * FROM DBO.TBAlloc T 
  LEFT OUTER JOIN dbo.TBComm C
    ON C.TBankCommInfSequenceID = T.TBankAllocInfoCheckID
    WHERE T.[TBankAllocInfAllocID] IN (112317, 112318)
ORDER BY MatterID

SELECT * FROM PcLaw.TrustTransactions T WHERE T.TransactionId IN (112317, 112318)
ORDER BY MatterID


--SELECT * FROM dbo.ARWO

--SELECT * FROM PcLaw.UnbilledTime

--SELECT * FROM PcLaw.BillableTime*
*/

/*
SELECT T.TransactionId, T.TransactionDate, T.TypeName, T.Debit, T.Credit, T.Value
    , T.MatterID, T.MatterNumber, T.MatterName, T.Description, T.PayTo, T.TBankAcctInfBank, TransferTransactionId
FROM PcLaw.TrustTransactions T
order by t.TransactionId

SELECT T.MatterID, T.ClientNumber, t.ClientName, T.MatterNumber, T.MatterName, M.ResponsibleNickname
    --, T.LawInfNickName, T.LawInfLawyerName
    , SUM(t.ActualHours), SUM(t.BillableHours), SUM(t.Amount)
FROM PcLaw.BillableTime T
INNER JOIN PcLaw.Matters M
    ON M.MatterID = T.MatterID
WHERE T.InvoiceId IS NULL
group by T.MatterID, T.ClientNumber, t.ClientName, T.MatterNumber, T.MatterName, M.ResponsibleNickname
    --, T.LawInfNickName, T.LawInfLawyerName
having sum(t.amount) <> 0
ORDER BY ClientName


SELECT *
FROM PcLaw.Invoices I
LEFT OUTER JOIN (
    SELECT T.InvoiceId, SUM(T.Amount) AS [TotalFees]
    FROM PcLaw.BillableTime T
    GROUP BY T.InvoiceId
) T
    ON T.InvoiceId = I.InvoiceID
LEFT OUTER JOIN (
    SELECT E.InvoiceId, SUM(E.Amount) AS [TotalExpenses]
    FROM PcLaw.BillableExpenses E
    GROUP BY E.InvoiceId
) E
    ON E.InvoiceId = I.InvoiceID
where i.TotalFees <> isnull(t.TotalFees, 0) OR i.TotalExpenses <> isnull(E.TotalExpenses, 0)

*/

