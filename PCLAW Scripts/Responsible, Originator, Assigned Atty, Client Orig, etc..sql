SELECT MATTERID
, ResponsibleNickname [RESP ATTY]
, RefNickname [ASSIGNED ATTY]
, C.LawyerNickname [CLIENT ORIG]
FROM PCLAW.Matters M
JOIN PCLAW.Contacts C 
	ON M.ClientInfoClientID=C.ClientInfoClientID

--matter originators
SELECT CL.MatterID
, LL.UserName [OriginatorCode]
, CaseLawyerCasePct [OriginationPercent]
FROM CaseLwyr CL
JOIN PCLAW.LawyerList LL ON CL.LawyerID=LL.LawyerID
WHERE CaseLawyerInfoType=2