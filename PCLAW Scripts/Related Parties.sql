	SELECT P.PartyID
, P.MatterID [MATTER ID]
, P.PartySplitMatterID [CONTACT ID]
, C.Name [CONTACT NAME]
, M.MatterName [MATTER NAME]
, CT.CtctTypeDescription [RELATIONSHIP]
, CONCAT(TRIM(C.NAME), ' - ', TRIM(CT.CtctTypeDescription)) [RELATED PARTY NAME]
--, *
FROM Party P
JOIN PCLAW.Matters M ON P.MatterID=M.MatterID
JOIN PCLAW.Contacts C ON C.ContactID=P.PartySplitMatterID
LEFT JOIN CtctType CT ON P.PartySpareLong=CT.TypeID