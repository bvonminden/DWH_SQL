USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_CRM_TEAMS_PROGRAMS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_CRM_TEAMS_PROGRAMS
--
CREATE PROCEDURE [dbo].[SP_CRM_TEAMS_PROGRAMS]
AS
--
-- This script controls the integration Teams and Programs between CRM and the DataWarehouse.
-- This is to accommodate new and updated data from CRM.
--
--   as of 1/20/2016, will only effect non-ETO site teams.
--
-- This procedure is dependent upon the dbo.sp_programs_main to have already been run after a new team had been added to CRM.
-- It is the dbo.sp_programs_main which populates the dbo.CRM_Team_Locations table which interfaces between CRM and DW.
--
-- History:
--   20160120 - New Procedure.  
--   20170504 - Fixed issue where team programs where not assigned to the correct correlating team.program_id... (suprv, nhv, referral).


DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_CRM_TEAMS_PROGRAMS'
set @DW_Tablename     = 'TEAMS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @new_nfpagencylocationid uniqueidentifier
DECLARE @New_Name                nvarchar(300)
DECLARE @New_NFPOrganizationID   uniqueidentifier
DECLARE @Site_ID                 int
DECLARE @Team_ID                 int
DECLARE @Program_ID              int
DECLARE @Program_Name            nvarchar(50)
DECLARE @Sequence_Nbr            int
DECLARE @New_Program_Ctr         int
DECLARE @Program_ID_Staff_Supervision    int
DECLARE @Program_ID_NHV                  int
DECLARE @Program_ID_Referrals            int


print 'Processing SP_CRM_TEAMS_PROGRAMS'
----------------------------------------------------------------------------------------
-- Initiate the Process Log
----------------------------------------------------------------------------------------

-- Check for existance for this process, if not found, add one:
select @count = count(*) from dbo.process_log where Process = @Process

set nocount on

IF @count = 0 
   insert into dbo.process_log (Process, LogDate, BegDate, EndDate, Action, Phase, Comment)
      Values (@Process, getdate(),getdate(),null,'Starting',null,null)
ELSE
   update dbo.process_log 
      set BegDate = getdate()
         ,EndDate = null
         ,LogDate = getdate()
         ,Action = 'Start Validation AgencyDB'
         ,Phase = null
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process


----------------------------------------------------------------------------------------
print ''
print 'Cont: Processing Teams'

DECLARE CRM_Team_Locations_Cursor Cursor for
select new_nfpagencylocationid, new_name, new_NFPOrganizationID
      ,teams.Team_Id, agencies.site_id
  from dbo.CRM_Team_Locations ctltbl
  left join dbo.Teams on ctltbl.new_nfpagencylocationid = Teams.CRM_ID
  left join dbo.Agencies on ctltbl.new_NFPOrganizationID = Agencies.CRM_AccountID
 where exists (select Site_ID from dbo.Sites_Excluded ex2
                 where ex2.Site_Id = Agencies.Site_Id)


OPEN CRM_Team_Locations_Cursor

FETCH next from CRM_Team_Locations_Cursor
      into @new_nfpagencylocationid 
          ,@New_Name
          ,@New_NFPOrganizationID 
          ,@Team_ID
          ,@Site_ID

WHILE @@FETCH_STATUS = 0
BEGIN

   IF @Team_ID is null
   BEGIN

print 'new team: ' +convert(varchar(36),@new_nfpagencylocationid )

      -- get / set the next Team_ID from the sequences table:
      select @Sequence_Nbr = Sequence_Nbr
        from dbo.Mstr_Sequences
       where Sequence_Name = 'NON-ETO_TEAM_ID'

      set @Team_ID = @Sequence_Nbr + 1

      update dbo.Mstr_Sequences set Sequence_Nbr = @Team_ID
       where Sequence_Name = 'NON-ETO_TEAM_ID'

      insert into dbo.teams
         (Team_id
         ,Team_Name
         ,Site_ID
         ,Team_effective_date
         ,Team_End_Date
         ,Address1
         ,Address2
         ,City
         ,State
         ,ZipCode
         ,County
         ,Phone1
         ,CRM_ID
         ,DataSource
         ,Entity_Disabled
         ,Date_Created
         ,Audit_Date)
      select @Team_ID
            ,@New_Name
            ,@Site_ID
            ,null --Team_Effective_Date
            ,null --Team_End_Date
            ,nfpaleb.New_Addres1
            ,nfpaleb.New_Address2
            ,nfpaleb.New_city
            ,sm.value  --State Code
            ,nfpaleb.New_zipCode
            ,null --County
            ,nfpaleb.New_MainPhone
            ,@new_nfpagencylocationid
            ,'CRM'
            ,0
            ,nfpalb.CreatedOn
            ,nfpalb.ModifiedOn
        from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.new_nfpagencylocationbase nfpalb
        left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.new_nfpagencylocationextensionbase nfpaleb
             on nfpalb.new_nfpagencylocationid = nfpaleb.new_nfpagencylocationid
        left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap sm
             on nfpaleb.new_st = sm.attributevalue
             and sm.attributename = 'new_state'
       where nfpalb.new_nfpagencylocationid = @new_nfpagencylocationid 



      -- Log New Teams Matched to CRM:
      insert into Teams_Log
             (Team_ID, LogDate, team_name, Action, Status, Comment, CRM_New_NFPAgencyLocationID, Site_ID)
       select @Team_ID, getdate(), @New_name
              ,'New Team',null
              ,'Non-ETO Team from CRM'
              ,@New_nfpagencylocationid
              ,@Site_ID


      ----------------------------------------------------------------------------------------
      -- Create the 3 basic programs attached to the new team:

      set @New_Program_Ctr = 0;
      set @Program_ID_Staff_Supervision = null
      set @Program_ID_NHV = null
      set @Program_ID_Referrals = null

      WHILE @New_Program_Ctr < 3
      BEGIN

         set @New_Program_Ctr = @New_Program_Ctr + 1

         -- get / set the next Program_ID from the sequences table:
         select @Sequence_Nbr = Sequence_Nbr
           from dbo.Mstr_Sequences
          where Sequence_Name = 'NON-ETO_PROGRAM_ID'

         set @Program_ID = @Sequence_Nbr + 1

         update dbo.Mstr_Sequences set Sequence_Nbr = @Program_ID
          where Sequence_Name = 'NON-ETO_PROGRAM_ID'


         IF @New_Program_Ctr = 1
         BEGIN
            set @program_name = LEFT('Staff Supervision-' +@new_Name,50)
            set @Program_ID_Staff_Supervision = @Program_ID
         END
         IF @New_Program_Ctr = 2
         BEGIN
            set @program_name = LEFT('Nurse Home Visiting-' +@new_Name,50)
            set @Program_ID_NHV = @Program_ID
         END
         IF @New_Program_Ctr = 3
         BEGIN
            set @program_name = LEFT('Referral and Intake-' +@new_Name,50)
            set @Program_ID_Referrals = @Program_ID
         END

         insert into dbo.Programs
            (Program_ID
            ,Program_Name
            ,Site_ID
            ,Supervisor_ID
            ,AuditDate
            ,Team_Group_Name
            ,CRM_new_nfpagencylocationid
            ,Team_ID)
          values (@Program_ID
                 ,@program_name
                 ,@Site_ID
                 ,null --Supervisor_ID
                 ,@runtime
                 ,null --Team_Group
                 ,@new_nfpagencylocationid
                 ,@Team_ID)


      END -- new programs while loop

     update dbo.Teams 
        set Program_ID_Staff_Supervision = @Program_ID_Staff_Supervision
           ,Program_ID_NHV = @Program_ID_NHV
           ,Program_ID_Referrals = @Program_ID_Referrals
           ,Programs_Audit_Date = @runtime
      where Team_ID = @Team_ID

   END  -- Team_ID being null (new Team)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Continue Cursor:
   FETCH next from CRM_Team_Locations_Cursor
         into @new_nfpagencylocationid 
             ,@New_Name
             ,@New_NFPOrganizationID  
             ,@Team_ID
             ,@Site_ID

END -- End of CRM_Team_Locations_Cursor loop

CLOSE CRM_Team_Locations_Cursor
DEALLOCATE CRM_Team_Locations_Cursor

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print ' '
print 'End of Process: SP_CRM_TEAMS_PROGRAMS'
GO
