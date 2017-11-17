USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_LMS_Student_Lookup_by_Name]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop proc dbo.SP_LMS_Student_Lookup_by_Name
CREATE procedure [dbo].[SP_LMS_Student_Lookup_by_Name]
 (@p_lastname       varchar(50),
  @p_firstname      varchar(50),
  @p_middlename     varchar(50) = null,
  @p_organizationid varchar(50) = null,
  @p_email          varchar(200) = null)
AS
-- This procedure returns a LMS StudentID based upon a name lookup.
-- 
-- References LMSsrvr.Tracker3 db

-- Steps:
--   Build a Student Cursor loaded with posible matches.
--   Parse cursor for most likely match and return the LMS StudentID

DECLARE @StudentID	varchar(36)
DECLARE @LastName	nvarchar(50)
DECLARE @FirstName	nvarchar(50)
DECLARE @MiddleInitial	nvarchar(50)
DECLARE @OrganizationID	nvarchar(100)
DECLARE @Email  	nvarchar(200)

DECLARE @SQL            nvarchar(2000)
DECLARE @return_id      int
DECLARE @qualified_ctr  smallint

SET @return_id = null
SET @qualified_ctr = 0

--print 'parms: '+@p_lastname +','+@p_firstname
----------------------------------------------------------------------------------------
-- Build and process cursor
----------------------------------------------------------------------------------------
DECLARE StudentCursor Cursor for
select Tracker_Students.StudentID
      ,Tracker_Students.LastName
      ,Tracker_Students.FirstName
      ,Tracker_Students.MiddleInitial
      ,Tracker_Students.OrganizationID
      ,Tracker_Students.EMail
  from LMSsrvr.Tracker3.dbo.Tracker_Students Tracker_Students
--  left join dbo.Tracker_Organizations
--         on Tracker_Students.StudentID = ContactExtensionBase.StudentID 
 where upper(Tracker_Students.LastName) = upper(@p_lastname)
   and upper(Tracker_Students.FirstName) = upper(@p_firstname);

OPEN StudentCursor

FETCH next from StudentCursor
      into @StudentID
          ,@LastName
          ,@FirstName
          ,@MiddleInitial
          ,@OrganizationID
          ,@Email

WHILE @@FETCH_STATUS = 0
BEGIN

--   print 'Found: Last='+@LastName +', First=' +@FirstName +', Middle=' +isnull(@MiddleInitial,'')
--     +', Organization=' +convert(varchar,@OrganizationID)
--     +', StudentID=' +convert(varchar,@StudentID)

   IF isnull(upper(substring(@p_middlename,1,1)),'@') in ('@',upper(substring(@MiddleInitial,1,1))) and
      isnull(upper(@p_email),'@') in ('@',upper(@Email)) and
      isnull(@p_organizationid,'@') in ('@',@OrganizationID)
      BEGIN
         set @return_id = @StudentID
         set @qualified_ctr = @Qualified_ctr + 1
      END


   FETCH next from StudentCursor
         into @StudentID
             ,@LastName
             ,@FirstName
             ,@MiddleInitial
             ,@OrganizationID
             ,@Email

END -- End of StudentCursor loop

CLOSE StudentCursor
DEALLOCATE StudentCursor

IF @qualified_ctr > 1
   set @return_id = 99999999

IF @return_id is null
   set @return_id = 0

--print @return_id
RETURN @return_id
GO
