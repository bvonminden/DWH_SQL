USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[CONTACT_POSITIONS_INIT_LOAD_REMDT1]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.CONTACT_POSITIONS_INIT_LOAD_REMDT1
--
CREATE PROCEDURE [dbo].[CONTACT_POSITIONS_INIT_LOAD_REMDT1]
AS
--
-- This script controls updates to the DW tables: Contact_Positions
--   for initial loading from contacts --> IA_Staff --> organizations --> Positions --> Staff_update_Survey

--   ** This is a temporary process until the NSO Contact maintenance forms are in place.


-- History:
--   20130719: New Procedure
--   20130923: Added WorkGroup_Id, changed reference for Org_ID as actual organization (such as IA).
--   20131028: Amendments to table (add/drop columns).
--   20140929: Amended to write to REM-DT1 for the test instance.

DECLARE @Contact_ID	  int
DECLARE @Primary_Entity_ID	int
DECLARE @Entity_ID	  int
DECLARE @position_Name1   nvarchar(100)
DECLARE @position_Name2   nvarchar(100)
DECLARE @position_ID1     int
DECLARE @position_ID2     int

DECLARE @Site_ID	int
DECLARE @Team_ID	int
DECLARE @Program_ID	int
DECLARE @Dtl_Count	int
DECLARE @survey_recs_processed	int
DECLARE @Last_Org_ID_processed int

DECLARE @dtl_SurveyResponseID	int
DECLARE @dtl_SurveyDate		smalldatetime
DECLARE @dtl_AuditDate		smalldatetime
DECLARE @dtl_SiteID		int
DECLARE @dtl_ProgramID		int
DECLARE @dtl_Org_ID		int
DECLARE @dtl_WorkGroup_ID	int
DECLARE @dtl_Nurse_Status_0_Change_Start_Date	smalldatetime
DECLARE @dtl_Nurse_Status_0_Change_Leave_Start	smalldatetime
DECLARE @dtl_Nurse_Status_0_Change_Leave_End	smalldatetime
DECLARE @dtl_Nurse_Status_0_Change_Terminate_Date	smalldatetime
DECLARE @dtl_New_Role		nvarchar(2000)
DECLARE @dtl_Home_Visitor_FTE	numeric(18,5)
DECLARE @dtl_Supervisor_FTE	numeric(18,5)
DECLARE @dtl_Admin_Asst_FTE	numeric(18,5)
DECLARE @dtl_Other_FTE		numeric(18,5)
DECLARE @dtl_Total_FTE		numeric(18,5)
DECLARE @dtl_Disposition_Code				smallint


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'CONTACT_POSITIONS_INIT_LOAD'

DECLARE @CRM_coursedate_cutover	datetime
set @CRM_coursedate_cutover = convert(datetime,'20101013',112)

print 'Starting: CONTACT_POSITIONS_INIT_LOAD_REMDT1'
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
         ,Action = 'Start'
         ,Phase = null
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process


----------------------------------------------------------------------------------------
print '  Cont: CONTACT_POSITIONS_INIT_LOAD - Cursor of Contacts/Positions'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Inserting New Contact'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

DECLARE Contacts_Cursor Cursor for
select Contacts.Contact_ID
      ,contacts.DataSource_ID as Primary_Entity_ID
      ,IA_Staff.Entity_ID
      ,Positions1.Position_ID as Position_ID1
      ,IA_Staff.NURSE_0_PROGRAM_POSITION1
      ,Positions2.Position_ID as Position_ID2
      ,IA_Staff.NURSE_0_PROGRAM_POSITION2
  from [REM-DT1].DataWarehouse.dbo.Contacts
  inner join dbo.IA_Staff on Contacts.Datasource_ID = IA_Staff.Entity_ID
  left  join [REM-DT1].DataWarehouse.dbo.Positions Positions1 on replace(IA_Staff.NURSE_0_PROGRAM_POSITION1,' / ','/') = Positions1.Position_Name
  left  join [REM-DT1].DataWarehouse.dbo.Positions Positions2 on replace(IA_Staff.NURSE_0_PROGRAM_POSITION2,' / ','/') = Positions2.Position_Name

OPEN Contacts_Cursor

FETCH next from Contacts_Cursor
      into @Contact_ID
          ,@Primary_Entity_ID
          ,@Entity_ID
          ,@Position_ID1
          ,@Position_Name1
          ,@Position_ID2
          ,@Position_Name2

WHILE @@FETCH_STATUS = 0
BEGIN

----------------------------------------------------------------------------------------------
-- Process Staff_Update_Survey
----------------------------------------------------------------------------------------------


      set @survey_recs_processed = 0

      DECLARE Staff_Updates_Cursor Cursor for
      select Organizations.Org_ID
            ,sus.SurveyResponseID
            ,sus.SurveyDate
            ,sus.AuditDate
            ,sus.SiteID
            ,sus.ProgramID
            ,sus.Nurse_Status_0_Change_Start_Date
            --,sus.Nurse_Status_0_Change_Leave_Start
            --,sus.Nurse_Status_0_Change_Leave_END
            ,sus.Nurse_Status_0_Change_Terminate_Date
            ,sus.Nurse_Professional_1_New_Role
            ,sus.Nurse_Professional_1_Home_Visitor_FTE
            ,sus.Nurse_Professional_1_Supervisor_FTE
            ,sus.Nurse_Professional_1_Admin_Asst_FTE
            ,sus.Nurse_Professional_1_Other_FTE
            ,sus.Nurse_Professional_1_Total_FTE
            ,sus.disposition_code_0
            ,(select max(WG.WorkGroup_id)
                from dbo.programs
                inner join dbo.WorkGroups WG on programs.CRM_new_nfpagencylocationid = WG.crm_id
               where dbo.FN_DW_Entity_Supervised_Program_ID(@Primary_Entity_ID) is not null
                 and programs.Program_ID = dbo.FN_DW_Entity_Supervised_Program_ID(@Primary_Entity_ID))
               as WorkGroup_id
        from dbo.Staff_Update_Survey sus
        left  join dbo.Agencies on SUS.SiteID = Agencies.Site_ID
        left  join [REM-DT1].DataWarehouse.dbo.organizations on Agencies.Entity_ID = Organizations.Source_Entity_ID
       where sus.CL_EN_GEN_ID = @Entity_ID
         and (sus.Nurse_Professional_1_Home_Visitor_FTE is not null or
              sus.Nurse_Professional_1_Supervisor_FTE is not null or
              sus.Nurse_Professional_1_Admin_Asst_FTE is not null or
              sus.Nurse_Professional_1_Other_FTE is not null)
       order by Organizations.Org_ID, sus.SurveyResponseID desc

      OPEN Staff_Updates_Cursor

      FETCH next from Staff_Updates_Cursor
            into  @dtl_Org_ID
                 ,@dtl_SurveyResponseID
                 ,@dtl_SurveyDate
                 ,@dtl_AuditDate
                 ,@dtl_SiteID
                 ,@dtl_ProgramID
                 ,@dtl_Nurse_Status_0_Change_Start_Date
                 --,@dtl_Nurse_Status_0_Change_Leave_Start
                 --,@dtl_Nurse_Status_0_Change_Leave_END
                 ,@dtl_Nurse_Status_0_Change_Terminate_Date
                 ,@dtl_New_Role
                 ,@dtl_Home_Visitor_FTE
                 ,@dtl_Supervisor_FTE
                 ,@dtl_Admin_Asst_FTE
                 ,@dtl_Other_FTE
                 ,@dtl_Total_FTE
                 ,@dtl_disposition_code
                 ,@dtl_WorkGroup_ID

      WHILE @@FETCH_STATUS = 0
      BEGIN

         IF @survey_recs_processed = 0 or
            isnull(@Last_Org_ID_Processed,987654321) != isnull(@dtl_Org_ID,987654321)
         BEGIN
            IF @Position_ID1 is not null
            BEGIN
               insert into [REM-DT1].DataWarehouse.dbo.Contact_Positions 
                      ( Contact_ID, Org_ID, WorkGroup_ID, Position_ID, Job_Title
                       ,FTE, Supervised_By_ID, Disposition_Code)
                Values( @Contact_ID, @dtl_Org_ID, @dtl_WorkGroup_ID, @Position_ID1, null
                       ,case when @Position_name1 in ('Nurse Home Visitor','IA Nurse Home Visitor') then @dtl_Home_Visitor_FTE
                             when @Position_name1 in ('Nurse Supervisor','NFP Supervisor','IA Nurse Supervisor'
                                                     ,'IA Supervisor') then @dtl_Supervisor_FTE
                             when @Position_name1 in ('IA Administrative Assistant') then @dtl_Supervisor_FTE
                             when @Position_ID2 is null then isnull(@dtl_Home_Visitor_FTE,0) + isnull(@dtl_Supervisor_FTE,0)
                             else null 
                             END

                       ,null
                       ,@dtl_disposition_code)
            END
            IF @Position_ID2 is not null and (@Position_ID2 != @Position_ID1)
            BEGIN
               insert into [REM-DT1].DataWarehouse.dbo.Contact_Positions 
                      ( Contact_ID, Org_ID, WorkGroup_ID, Position_ID, Job_Title
                       ,FTE, Supervised_By_ID, Disposition_Code)
                Values( @Contact_ID, @dtl_Org_ID, @dtl_WorkGroup_ID, @Position_ID2, null
                       ,case when @Position_name2 in ('Nurse Home Visitor','IA Nurse Home Visitor') then @dtl_Home_Visitor_FTE
                             when @Position_name2 in ('Nurse Supervisor','NFP Supervisor','IA Nurse Supervisor'
                                                     ,'IA Supervisor') then @dtl_Supervisor_FTE
                             when @Position_name2 in ('IA Administrative Assistant') then @dtl_Supervisor_FTE
                             when @Position_ID1 is null then isnull(@dtl_Home_Visitor_FTE,0) + isnull(@dtl_Supervisor_FTE,0)
                                                     + isnull(@dtl_Admin_Asst_FTE,0) + isnull(@dtl_Other_FTE,0)
                             else null 
                             END
                       , null
                       ,@dtl_disposition_code)
            END

         END

         set @survey_recs_processed = @survey_recs_processed + 1
         set @Last_Org_ID_Processed = @dtl_Org_ID

      FETCH next from Staff_Updates_Cursor
            into  @dtl_Org_ID
                 ,@dtl_SurveyResponseID
                 ,@dtl_SurveyDate
                 ,@dtl_AuditDate
                 ,@dtl_SiteID
                 ,@dtl_ProgramID
                 ,@dtl_Nurse_Status_0_Change_Start_Date
                 --,@dtl_Nurse_Status_0_Change_Leave_Start
                 --,@dtl_Nurse_Status_0_Change_Leave_END
                 ,@dtl_Nurse_Status_0_Change_Terminate_Date
                 ,@dtl_New_Role
                 ,@dtl_Home_Visitor_FTE
                 ,@dtl_Supervisor_FTE
                 ,@dtl_Admin_Asst_FTE
                 ,@dtl_Other_FTE
                 ,@dtl_Total_FTE
                 ,@dtl_disposition_code
                 ,@dtl_WorkGroup_ID

      
      END -- End of  Detals_Cursor While Loop
      CLOSE Staff_Updates_Cursor
      DEALLOCATE Staff_Updates_Cursor




----------------------------------------------------------------------------------------
-- continue in Contacts cursor
----------------------------------------------------------------------------------------

   FETCH next from Contacts_Cursor
         into @Contact_ID
             ,@Primary_Entity_ID
             ,@Entity_ID
             ,@Position_ID1
             ,@Position_Name1
             ,@Position_ID2
             ,@Position_Name2

END -- End of  Contacts_Cursor While Loop

CLOSE Contacts_Cursor
DEALLOCATE Contacts_Cursor


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

print 'End of Process: CONTACT_POSITIONS_INIT_LOAD'
GO
