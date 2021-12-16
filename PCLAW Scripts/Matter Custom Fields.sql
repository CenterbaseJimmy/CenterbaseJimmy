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