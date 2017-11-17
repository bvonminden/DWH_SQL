USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Cleanup_Logs]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Cleanup_Logs
--
CREATE PROCEDURE [dbo].[SP_Cleanup_Logs]
AS
--
-- This script controls updates to the Agency table in the Data Warehouse.
-- Processing ETO Entities identified as Non-Individuals.
--
-- Table effected - dbo.Agencies
--
-- Insert: select and insert when ETO agency entity is found to be missing in the DW.
-- Update: select and update when ETO agency entity exists in DW and has been changed in ETO.
--
-- Database Links:
-- CRM: [192.168.1.228].newtestcrm.  (test)


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_CLEANUP_LOGS'

DECLARE @FromDate	datetime

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

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @FromDate = datediff(day,15,getdate())
print 'Processing SP_Cleanup_Logs - deleting logs older than ' +convert(varchar,@FromDate,112)

delete from dbo.CRM_Contacts_Log
 where logdate < @FromDate

delete from dbo.LMS_Student_Log
 where logdate < @FromDate

delete from dbo.LMS_ClassReg_Log
 where logdate < @FromDate

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


print '  End of Process: SP_Cleanup_Logs'
GO
