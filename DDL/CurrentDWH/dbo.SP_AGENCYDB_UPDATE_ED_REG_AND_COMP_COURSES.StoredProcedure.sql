USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_UPDATE_ED_REG_AND_COMP_COURSES]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_UPDATE_ED_REG_AND_COMP_COURSES
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_UPDATE_ED_REG_AND_COMP_COURSES]
 (@p_datasource      nvarchar(10) = null)
AS
--
-- This script controls the update of the AgencyDB Education Registrations and Completed Courses
-- from the Data Warehouse.  Expects a parameter for DataSource to process.
--
--
-- Table effected - LMS.Tracker_ClassStudentAssignment      (read)
--                  DW.DW_Completed_Courses                 (read)
--                  AgencyDB.Education_Registration_Survey  (write)
--                  AgencyDB.DW_Completed_Courses           (write)
----
-- History:
--   20141007 - New Procedure.


DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_UPDATE_ED_REG_AND_COMP_COURSES'
set @DW_Tablename = null
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)

print 'Processing SP_AGENCYDB_UPDATE_ED_REG_AND_COMP_COURSES: AgencyDB = ' +isnull(@p_datasource,'NULL')
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
print 'Cont: Check for run inhibit trigger'

IF dbo.FN_Check_Process_Inhibitor (@process, @p_datasource, null) is not null 

BEGIN
   set @stop_flag = 'X';
   print 'Process Inhibited via Process_Inhibitor Table, job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'Process Inhibited via Process_Inhibitor Table, job stopped'
      ,LogDate = getdate()
 where Process = @process
END

IF @stop_flag is null
BEGIN
   print 'Validate datasource DBSrvr from LOV tables'

   set @AgencyDB = null;
   select @AgencyDB = Value
     from dbo.View_LOV
    where Name = 'AGENCYDB_BY_DATASOURCE'
      and lOV_Item = @p_datasource

   IF @AgencyDB is null
   BEGIN
      set @stop_flag = 'X';
      print 'Unable to retrieve LOV AgencyDB for datasource=' +isnull(@AgencyDB,'') +', job stopped'
      set nocount on
      update dbo.process_log 
      set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
         ,LogDate = getdate()
    where Process = @process
   END
END 

IF @stop_flag is null 
BEGIN


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ''
print 'Cont: Process Completed Courses (Delete all AgencyDB recs / Re-add from DW)'


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Completed_Courses'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' delete from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DW_Completed_Courses'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DW_Completed_Courses'
    +' (RecID'
    +' ,Entity_ID'
    +' ,ContactID'
    +' ,CRM_Course_Nbr'
    +' ,LMS_StudentCourseID'
    +' ,Course_Name'
    +' ,Completion_date'
    +' ,Reason_for_Education'
    +' ,dwcc.LMS_LongName'
    +' ,dwcc.LMS_Comments)'
set @SQL2 = 
     'SELECT dwcc.RecID'
    +' ,dwcc.Entity_ID'
    +' ,dwcc.ContactID'
    +' ,dwcc.CRM_Course_Nbr'
    +' ,dwcc.LMS_StudentCourseID'
    +' ,dwcc.Course_Name'
    +' ,dwcc.Completion_date'
    +' ,dwcc.Reason_for_Education'
    +' ,dwcc.LMS_LongName'
    +' ,dwcc.LMS_Comments'
+'
 from dbo.DW_Completed_Courses dwcc'
+' inner join dbo.ia_staff on dwcc.entity_id = ia_staff.entity_id'
+' inner join dbo.AgencyDB_Sites_By_DataSource asds on ia_staff.Site_ID = asds.Site_ID'
+' where asds.DataSource = ''' +@p_datasource +''''

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Education_Registration'


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Education_Registration'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------




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

END /* end of stop validation */

print 'End of Process: SP_AGENCYDB_UPDATE_ED_REG_AND_COMP_COURSES'
GO
