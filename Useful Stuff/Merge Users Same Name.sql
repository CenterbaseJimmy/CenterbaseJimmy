DECLARE @fix bit = 0;
DECLARE @deleteDupeUser bit = 0;


IF (OBJECT_ID('tempdb..#UsersToMerge') IS NOT NULL) DROP TABLE #UsersToMerge
CREATE TABLE #UsersToMerge
(
    mainuserid uniqueidentifier
    , dupeuserid uniqueidentifier
	, mainsqlid int
	, dupesqlid int
    , PRIMARY KEY (mainuserid,dupeuserid)        -- Gives faster performance for various join operations
    , UNIQUE (mainuserid,dupeuserid)
)


-- Get a "trimmed" version of the user list where we can ignore extra spaces when looking for duplicates
DECLARE @TrimmedUsers TABLE (userid uniqueidentifier, username nvarchar(255), inactive bit)
INSERT INTO @TrimmedUsers
(userid, username, inactive)
SELECT U.userid, RTRIM(LTRIM(REPLACE(U.username, '  ', ' '))), U.inactive
FROM dbo.UserView U
where u.type = 1


-- Find main/dupe users by username
DECLARE @DupeUsers TABLE (username nvarchar(255), dupecnt int, mainuserid uniqueidentifier)

INSERT INTO @DupeUsers (username, dupecnt)
SELECT U.username, COUNT(*)
FROM @TrimmedUsers U
GROUP BY U.username
HAVING COUNT(*) > 1

-- Find the main user when there is only one active and one or more inactive
UPDATE D SET mainuserid = U.userid
FROM (
	SELECT D.username
	FROM @DupeUsers D
	INNER JOIN @TrimmedUsers U
		ON U.username = D.username AND ISNULL(U.inactive, 0) = 0
	GROUP BY D.username
	HAVING COUNT(*) = 1
) T
INNER JOIN @DupeUsers D
	ON D.username = T.username
INNER JOIN @TrimmedUsers U
	ON U.username = D.username AND ISNULL(U.inactive, 0) = 0

-- Pick a "main" user when all users are inactive
UPDATE D SET mainuserid = t.userid
FROM (
	 SELECT U.username, U.userid, ROW_NUMBER() OVER (PARTITION BY D.username ORDER BY U.userid) AS [rownum]
	FROM @DupeUsers D
	INNER JOIN @TrimmedUsers U
		ON U.username = D.username
	WHERE NOT EXISTS (sELECT * FROM dbo.objects O WHERE O.type = 1 AND O.name = D.username AND ISNULL(O.inactive, 0) = 0)
) T
INNER JOIN @DupeUsers D
	ON D.username = T.username AND T.rownum = 1

INSERT INTO #UsersToMerge
(dupeuserid, mainuserid)
SELECT u.userid, d.mainuserid
FROM @DupeUsers D
INNER JOIN @TrimmedUsers U
	ON U.username = D.username AND U.userid <> D.mainuserid
WHERE D.mainuserid IS NOT NULL



---- Hard coded user IDs
--INSERT INTO #UsersToMerge (dupeuserid, mainuserid)
--VALUES
--('195cfc55-a49c-49a3-9129-65a6e8d6abf1','683F4BA5-EBEC-41F6-B9B6-73E01C2AC2F2')
--('0210E74A-1010-4ABF-857A-175F34A389C8','191445D2-24A3-4268-A696-237568D0356A'),
--('7FCDF737-170B-4938-9BB0-1546A2C2F5A0','6059177F-0338-4F61-9F31-64F5C8CA9FD6'),
--('17539F65-48FF-4B6D-943F-A6A26707D4B8','13CD211D-45A3-4FD5-B5DB-9880A505DB34')



UPDATE T SET dupesqlid = U.sqlid
FROM #UsersToMerge T
INNER JOIN dbo.UserView U
	ON U.userid = T.dupeuserid
	AND U.type = 1

UPDATE T SET mainsqlid = U.sqlid
FROM #UsersToMerge T
INNER JOIN dbo.UserView U
	ON U.userid = T.mainuserid
	AND U.type = 1

IF (NOT EXISTS (SELECT * FROM #UsersToMerge))
BEGIN
	SELECT U.userid, U.username, U.contactdisplayname, U.webdisplayname, U.inactive, U.isadmin, T.DupeCount
	FROM (
		SELECT U.username, COUNT(*) AS [DupeCount]
		FROM dbo.UserView U
		WHERE U.type = 1
		GROUP BY U.username HAVING COUNT(*) > 1
		--ORDER BY U.username--, U.inactive
	) t
	INNER JOIN dbo.UserView U
		ON U.username = T.username
		AND U.type = 1
	ORDER BY U.username, U.inactive

	SELECT U.userid, U.username, U.contactdisplayname, U.webdisplayname, U.inactive, U.isadmin, O.encryptedpwd
	FROM dbo.UserView U
	INNER JOIN dbo.Objects O
		ON O.objectid = U.userid
    WHERE U.type = 1
	ORDER BY U.username, U.inactive
END
ELSE IF (@fix = 1)
BEGIN
	--SELECT top 10 *
	----UPDATE O SET creatorid = t.mainuserid
	--FROM #UsersToMerge T
	--INNER JOIN dbo.Objects O
	--	ON O.creatorid = T.dupeuserid

	--SELECT top 10 *
	----UPDATE O SET ownerid = t.mainuserid, ownersqlid = t.mainsqlid
	--FROM #UsersToMerge T
	--INNER JOIN dbo.Objects O
	--	ON O.ownerid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE O SET O.creatorid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.Objects O
	    ON O.creatorid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE O SET O.ownerid = t.mainuserid, O.ownersqlid = t.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.Objects O
	    ON O.ownerid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE L SET L.userid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.AuditLog L
	    ON L.userid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE L SET L.userid = t.mainuserid, L.sqlid = t.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.DeleteLog L
	    ON L.userid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE R SET R.userid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.ActivityReminders R
	    ON R.userid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET creatorid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.Addresses A
	    ON A.creatorid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET ownerid = t.mainuserid, ownersqlid = T.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.Addresses A
	    ON A.ownerid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET creatorid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.EmailAddresses A
	    ON A.creatorid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET ownerid = t.mainuserid, ownersqlid = T.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.EmailAddresses A
	    ON A.ownerid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET creatorid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.PhoneNumbers A
	    ON A.creatorid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET ownerid = t.mainuserid, ownersqlid = T.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.PhoneNumbers A
	    ON A.ownerid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE L SET L.objectid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.ObjectLookups L
	    ON L.objectid = T.dupeuserid

	--SELECT TOP 10 *
	DELETE X
	FROM #UsersToMerge T INNER JOIN dbo.ObjectXRef X
	    ON X.objectid2 = T.dupeuserid
		AND (   EXISTS ( SELECT * FROM dbo.ObjectXRef X1 WHERE X1.objectid1 = X.objectid1 AND X1.objectid2 = t.mainuserid)
			 OR EXISTS ( SELECT * FROM dbo.ObjectXRef X1 WHERE X1.objectid2 = X.objectid1 AND X1.objectid1 = t.mainuserid) )

	--SELECT TOP 10 *
	DELETE X
	FROM #UsersToMerge T INNER JOIN dbo.ObjectXRef X
	    ON X.objectid1 = T.dupeuserid
		AND (   EXISTS ( SELECT * FROM dbo.ObjectXRef X1 WHERE X1.objectid1 = X.objectid2 AND X1.objectid2 = t.mainuserid)
			 OR EXISTS ( SELECT * FROM dbo.ObjectXRef X1 WHERE X1.objectid2 = X.objectid2 AND X1.objectid1 = t.mainuserid) )

	--SELECT TOP 10 *
	UPDATE X SET X.objectid2 = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.ObjectXRef X
	    ON X.objectid2 = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE X SET X.objectid1 = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.ObjectXRef X
	    ON X.objectid1 = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE P SET P.roleid = t.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.Permission P
	    ON P.roleid = T.dupesqlid
		AND NOT EXISTS ( SELECT * FROM dbo.Permission P2 WHERE P2.objectid = P.objectid AND P2.roleid = t.mainsqlid)
		
	--SELECT TOP 10 *
	UPDATE R SET R.defaultownerid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.MesaSysUserRights R
	    ON R.defaultownerid = T.dupeuserid
		AND R.userid <> R.defaultownerid

	--SELECT TOP 10 *
	UPDATE S SET S.roleid = t.mainsqlid
	FROM #UsersToMerge T INNER JOIN dbo.DefaultSecurity S
	    ON S.roleid = T.dupesqlid
		AND S.sqlid <> S.roleid
		AND NOT EXISTS ( SELECT * FROM dbo.DefaultSecurity S2 WHERE S2.userid = S.userid AND S2.objecttype = S.objecttype AND S2.roleid = t.mainsqlid)

	--SELECT TOP 10 *
	UPDATE V SET V.value = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.DefaultValues V
	    ON V.value = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE E SET E.userid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.BillingEntries E
	    ON E.userid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE K SET K.UserId = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.BillableTimekeepers K
	    ON K.userid = T.dupeuserid

	--SELECT TOP 10 *
	UPDATE A SET A.userid = t.mainuserid
	FROM #UsersToMerge T INNER JOIN dbo.BillingObjectAllocations A
	    ON A.type = 1 AND A.userid = T.dupeuserid

	--SELECT a.*
	UPDATE A SET A.userid = t.mainuserid
	FROM #UsersToMerge T 
	INNER JOIN dbo.BillingRateTableEntries A
		ON A.userid = T.dupeuserid
	WHERE NOT EXISTS (sELECT * FROM BillingRateTableEntries A2 WHERE A2.versionid = A.versionid AND A2.userid = T.mainuserid)
		AND NOT EXISTS (sELECT * FROM BillingRateTableEntries A2 WHERE A2.objectid = A.objectid AND A2.userid = T.mainuserid)

	IF (@deleteDupeUser = 1)
	BEGIN
	-- DELETES ALL USERS THAT ARE INACTIVE
		-- Drop and create a table to hold the items that will be deleted
		IF (OBJECT_ID('tempdb..#RemoveMultiple') IS NOT NULL) DROP TABLE #RemoveMultiple
		CREATE TABLE #RemoveMultiple (deleteid uniqueidentifier)
		INSERT INTO #RemoveMultiple (deleteid) 
		SELECT T.dupeuserid
		FROM #UsersToMerge T
	
		-- NEVER EVER allow them to delete the sys admin account
		DELETE FROM #RemoveMultiple 
		WHERE deleteid = 'A3F13D51-9F5A-4088-BF5E-F701CD31BC59'
	
	
		-- Delete the lookup fields both ways
		DELETE L
		FROM #RemoveMultiple D
		INNER JOIN dbo.ObjectLookups L
			ON L.parentid = D.deleteid

		DELETE L
		FROM #RemoveMultiple D
		INNER JOIN dbo.ObjectLookups L
			ON L.objectid = D.deleteid

		--  Delete Related Objects XRef
		DELETE X
		FROM #RemoveMultiple D
		INNER JOIN dbo.ObjectXRef X
			ON X.objectid1 = D.deleteid

		DELETE X
		FROM #RemoveMultiple D
		INNER JOIN dbo.ObjectXRef X
			ON X.objectid2 = D.deleteid            
    
		-- Delete all of the bulk fields for the items
		DELETE I
		FROM #RemoveMultiple D
		INNER JOIN dbo.ItemsBulk I
			ON I.objectid = D.deleteid
    
		-- Delete all of the fields for the items
		DELETE I
		FROM #RemoveMultiple D
		INNER JOIN dbo.ObjectItemXRef I
			ON I.objectid = D.deleteid            
    
		-- Now delete the items
		DELETE O
		FROM #RemoveMultiple D
		INNER JOIN dbo.Objects O
			ON O.objectid = D.deleteid

		-- Finally remove all security settings from the items that were deleted
		DELETE P
		FROM #RemoveMultiple D
		INNER JOIN dbo.Permission P
			ON P.objectid = D.deleteid
    
    
		-- Drop and create a table to hold the users that will be deleted
		IF (OBJECT_ID('tempdb..#RemoveUsers') IS NOT NULL)
			DROP TABLE #RemoveUsers
    
		CREATE TABLE #RemoveUsers (
			deleteid uniqueidentifier, 
			deletesqlid int, 
			deletetype int, 
			deletelogin sysname)

		INSERT INTO #RemoveUsers
		(deleteid, deletesqlid, deletetype, deletelogin)
		SELECT U.userid, U.sqlid, U.[type], U.sqllogin
		FROM dbo.UserInformation U
		INNER JOIN #RemoveMultiple D
			ON D.deleteid = U.userid
		ORDER BY U.[type] desc

		-- If we have a role id, this is a role and we need to do additional things.
		IF (@@ROWCOUNT > 0)
		BEGIN
    
			-- Remove the user's change log entries
			DELETE L
			FROM #RemoveUsers U
			INNER JOIN dbo.AuditLog L
				ON L.userid = U.deleteid
        
			DELETE L
			FROM #RemoveUsers U
			INNER JOIN dbo.DeleteLog L
				ON L.userid = U.deleteid
        
    
			-- Remove the user's chart pages and chart page settings
			DELETE C
			FROM #RemoveUsers U
			INNER JOIN dbo.ChartPages C
				ON C.userid = U.deleteid
    
			DELETE C
			FROM #RemoveUsers U
			INNER JOIN dbo.ChartPageSettings C
				ON C.userid = U.deleteid
    
			--  If it's a user, remove the user's rights
			DELETE M
			FROM #RemoveUsers D
			INNER JOIN dbo.MesaSysUserRights M
				ON M.userid = D.deleteid
    
			--Update the default security if this was used as a default owner
			UPDATE M
			SET M.defaultownerid = M.userid
			FROM #RemoveUsers D
			INNER JOIN dbo.MesaSysUserRights M
				ON M.defaultownerid = D.deleteid
    
			--Remove any permission the role had
			DELETE P
			FROM #RemoveUsers D
			INNER JOIN dbo.Permission P 
				ON D.deletesqlid = P.roleid
    
			--Delete the user's default security settings
			DELETE S
			FROM #RemoveUsers D
			INNER JOIN dbo.DefaultSecurity S
				ON D.deletesqlid = S.sqlid

			--Delete the user's default value settings
			DELETE V
			FROM #RemoveUsers D
			INNER JOIN dbo.DefaultValues V
				ON D.deletesqlid = V.sqlid

			-- Make ADMIN the owner/creator of anything this user owned/created
			DECLARE @adminSqlId int
			SET @adminSqlId = dbo.fn_GetSqlId('A3F13D51-9F5A-4088-BF5E-F701CD31BC59')

			UPDATE O 
			SET O.ownerid = 'A3F13D51-9F5A-4088-BF5E-F701CD31BC59', 
				O.ownersqlid = @adminSqlId 
			FROM #RemoveUsers D
			INNER JOIN dbo.Objects O
				ON O.ownersqlid = D.deletesqlid

			UPDATE O
			SET O.creatorid = 'A3F13D51-9F5A-4088-BF5E-F701CD31BC59'
			FROM #RemoveUsers D
			INNER JOIN dbo.Objects O
				ON O.creatorid = D.deleteid


			DECLARE @type int
			DECLARE @sqlLogin sysname
			DECLARE @roleid int
			DECLARE @result int
			DECLARE @currentUsersTable TABLE (sqllogin sysname)
			DECLARE @userName sysname

			WHILE ((SELECT COUNT(*) FROM #RemoveUsers) > 0)
			BEGIN
				SELECT TOP 1 @roleid = deletesqlid, @type = deletetype, @sqlLogin = deletelogin 
				FROM #RemoveUsers 

				IF (@type = 1)
				BEGIN
					-- Remove the user's FindResults table first
					EXEC dbo.cb_Utils_DropTempTable @sqlLogin, 'FindResults'

					IF (EXISTS (SELECT * from sysusers where name = @sqlLogin))
						EXEC @result = sp_dropuser @sqlLogin

					IF (@result = 0 AND EXISTS (select loginname from master.dbo.syslogins where loginname = @sqlLogin))
						EXEC @result = sp_droplogin @sqlLogin
				END

				DELETE FROM #RemoveUsers WHERE deletesqlid = @roleid

				--Remove the role from the UserInformation table
				DELETE FROM dbo.UserInformation 
				WHERE sqlid = @roleid

				--Remove them from any groups they were in 
				--or remove all users from the group that was deleted
				DELETE FROM dbo.Membership 
				WHERE sqlid = @roleid

				DELETE FROM dbo.Membership 
				WHERE roleid = @roleid
			END
		END

		DROP TABLE #RemoveUsers
		DROP TABLE #RemoveMultiple
	END
END
ELSE
BEGIN
	SELECT t.dupeuserid, UD.webdisplayname, UD.inactive
		, t.mainuserid, Um.webdisplayname, um.inactive
		, CASE WHEN t.dupesqlid IS NULL AND T.mainsqlid IS NULL THEN 'Both IDs are invalid'
			WHEN t.dupesqlid IS NULL THEN 'Dupe user ID is invalid'
			WHEN T.mainsqlid IS NULL THEN 'Main user ID is invalid'
			WHEN ISNULL(ud.inactive, 0) = 0 THEN 'Dupe User IS ACTIVE'
			WHEN UM.inactive = 1 THEN 'Main User IS INACTIVE'
			END AS [Status]
	FROM #UsersToMerge T
	LEFT OUTER JOIN dbo.UserView Ud
		ON Ud.userid = T.dupeuserid
	LEFT OUTER JOIN dbo.UserView Um
		ON Um.userid = T.mainuserid
	ORDER BY [Status], UM.webdisplayname, UD.webdisplayname
END