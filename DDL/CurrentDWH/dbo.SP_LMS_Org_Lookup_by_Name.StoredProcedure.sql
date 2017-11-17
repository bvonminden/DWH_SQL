USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_LMS_Org_Lookup_by_Name]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop proc dbo.SP_LMS_Org_Lookup_by_Name
CREATE procedure [dbo].[SP_LMS_Org_Lookup_by_Name]
 (@p_Organization   varchar(50),
  @p_City           varchar(50) = null,
  @p_State          varchar(20) = null,
  @p_ZipCode        varchar(20) = null,
  @p_Email          varchar(200) = null)
AS
-- This procedure returns a LMS OrganizationID based upon a name lookup.
-- 
-- References LMSsrvr.Tracker3

-- Steps:
--   Build a Student Cursor loaded with posible matches.
--   Parse cursor for most likely match and return the LMS StudentID

DECLARE @OrganizationID	int
DECLARE @Organization	nvarchar(150)
DECLARE @City		nvarchar(50)
DECLARE @State		nvarchar(2)
DECLARE @ZipCode	nvarchar(20)
DECLARE @Email  	nvarchar(200)

DECLARE @SQL            nvarchar(2000)
DECLARE @return_id      nvarchar(36)
DECLARE @qualified_ctr  smallint

SET @return_id = null
SET @qualified_ctr = 0

--print 'parms: '+@p_organization +','+@p_City +','+@p_State +','+@p_ZipCode +','+@p_Email
----------------------------------------------------------------------------------------
-- Build and process cursor
----------------------------------------------------------------------------------------
DECLARE OrgCursor Cursor for
select Tracker_Organizations.OrganizationID
      ,Tracker_Organizations.Organization
      ,Tracker_Organizations.City
      ,Tracker_Organizations.State
      ,Tracker_Organizations.ZipCode
      ,Tracker_Organizations.EMail
  from LMSsrvr.Tracker3.dbo.Tracker_Organizations Tracker_Organizations
 where upper(Tracker_Organizations.Organization) = upper(@p_Organization);

OPEN OrgCursor

FETCH next from OrgCursor
      into @OrganizationID
          ,@Organization
          ,@City
          ,@State
          ,@ZipCode
          ,@Email

WHILE @@FETCH_STATUS = 0
BEGIN

--   print 'Found: ID='+@OganizationId +', ' +@Oganization +', City=' +City
--     +', State=' +@State +', Zip=' +@ZipCode +', Email=' +@Email

   IF isnull(upper(@p_City),'@') in ('@',upper(@City)) and
      isnull(upper(@p_State),'@') in ('@',upper(@State)) and
      isnull(upper(@p_ZipCode),'@') in ('@',upper(@ZipCode)) and
      isnull(upper(@p_email),'@') in ('@',upper(@Email))
      BEGIN
         set @return_id = @OrganizationID
         set @qualified_ctr = @Qualified_ctr + 1
      END


   FETCH next from OrgCursor
         into  @OrganizationID
              ,@Organization
              ,@City
              ,@State
              ,@ZipCode
              ,@Email

END -- End of OrgCursor loop

CLOSE OrgCursor
DEALLOCATE OrgCursor

IF @qualified_ctr > 1
   set @return_id = '*MULTIPLE*'

IF @return_id is null
   set @return_id = '0'
   
--print @return_id
RETURN @return_id
GO
