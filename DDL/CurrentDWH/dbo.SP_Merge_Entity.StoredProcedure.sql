USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Merge_Entity]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Merge_Entity
--
CREATE PROCEDURE [dbo].[SP_Merge_Entity]
 (@p_new_entity_id       int = null,
  @p_old_entity_id       int = null)
AS
--
-- This script controls the merge process between two Entity_IDs
--
-- History:
--   20140110 - New Procedure.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_MERGE_ENTITY'


DECLARE @Entity_ID_new		int
DECLARE @Entity_ID_old		int
DECLARE @ContactID_new		uniqueidentifier
DECLARE @ContactID_old		uniqueidentifier
DECLARE @StudentID_new		int
DECLARE @StudentID_old		int
DECLARE @Crs_Hist_Cnt_new	int
DECLARE @Crs_Hist_Cnt_old	int
DECLARE @disabled_new		int
DECLARE @disabled_old		int
DECLARE @datasource_new		varchar(10)
DECLARE @datasource_old		varchar(10)
DECLARE @full_name_new		varchar(200)
DECLARE @full_name_old		varchar(200)
DECLARE @email_new		varchar(50)
DECLARE @email_old		varchar(50)



print 'Processing SP_Merge_Entity'
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
         ,index_1 = @p_new_entity_id
         ,index_2 = @p_old_entity_id
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
-- Evaluation / Validation Process:

set @Entity_ID_new = null
set @Entity_ID_old = null

-- Find new Entity information
BEGIN 
   select @Entity_ID_new = IA_Staff.Entity_ID
         ,@full_name_new = IA_Staff.full_name
         ,@email_new = IA_Staff.email
         ,@ContactID_new = IA_Staff.CRM_COntactID
         ,@StudentID_new = IA_Staff.LMS_StudentID
         ,@disabled_new = IA_Staff.Disabled
         ,@datasource_new = IA_Staff.Datasource
         ,@Crs_Hist_Cnt_new = (select count(*) 
                                 from dbo.DW_Completed_Courses 
                                where Entity_ID = IA_Staff.Entity_ID)
     from dbo.IA_Staff
    where IA_Staff.Entity_ID = @p_new_entity_id
END;

-- Find Old Entity information
BEGIN 
   select @Entity_ID_old = IA_Staff.Entity_ID
         ,@full_name_old = IA_Staff.full_name
         ,@email_old = IA_Staff.email
         ,@ContactID_old = IA_Staff.CRM_COntactID
         ,@StudentID_old = IA_Staff.LMS_StudentID
         ,@disabled_old = IA_Staff.Disabled
         ,@datasource_old = IA_Staff.Datasource
         ,@Crs_Hist_Cnt_old = (select count(*) 
                                 from dbo.DW_Completed_Courses 
                                where Entity_ID = IA_Staff.Entity_ID)
     from dbo.IA_Staff
    where IA_Staff.Entity_ID = @p_old_entity_id
END;

-- report comparisons:
print ' '
print space(5) +left('Entity_ID' +space(10),10) +'|' +left('Full_Name' +space(25),25) +'|'
     +left('Datasource' +space(10),10) +'|' +left('Disabled' +space(8),8) +'|'
     +left('CRM_ContactID' +space(36),36) +'|' +left('StudentID' +space(10),10) +'|'
     +left('Crs_Hist' +space(8),8)

print 'New: ' +left(isnull(convert(varchar,@p_new_entity_id),' ') +space(10),10) +'|' +left(isnull(@full_name_new,' ') +space(25),25) 
     +'|' +left(isnull(@datasource_new,' ') +space(10),10) +'|' +left(isnull(convert(char,@disabled_new),' ') +space(8),8) 
     +'|' +left(isnull(convert(varchar(36),@contactid_new),' ') +space(36),36) +'|' +left(isnull(convert(char,@studentid_new),' ') +space(10),10)
     +'|' +left(isnull(convert(varchar,@crs_hist_cnt_new),' ') +space(8),8) 

print 'Old: ' +left(isnull(convert(varchar,@p_old_entity_id),' ') +space(10),10) +'|' +left(isnull(@full_name_old,' ') +space(25),25)
     +'|' +left(isnull(@datasource_old,' ') +space(10),10) +'|' +left(isnull(convert(char,@disabled_old),' ') +space(8),8)
     +'|' +left(isnull(convert(varchar(36),@contactid_old),' ') +space(36),36) +'|' +left(isnull(convert(char,@studentid_old),' ') +space(10),10)
     +'|' +left(isnull(convert(varchar,@crs_hist_cnt_old),' ') +space(8),8) 






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
print '  End of Process: SP_Merge_Entity'
GO
