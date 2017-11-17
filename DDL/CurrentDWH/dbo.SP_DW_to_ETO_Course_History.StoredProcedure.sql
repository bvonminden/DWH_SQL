USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_DW_to_ETO_Course_History]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_DW_to_ETO_Course_History
--
CREATE PROCEDURE [dbo].[SP_DW_to_ETO_Course_History]
 (@p_site_id       int = null)
AS
--
-- This process reads the DW completed courses staging table, extracting all records with a
-- null Sync_Phase (new).  The records are then formatted into a CSV formatted flatfile,
-- which is then sent to the ETO completed course survey via an API. 

-- Sync_PHases:
--   null - New Completed Course
--   1    - Extracted to API for ETO Survey Update
--   2    - Success Survey Received from ETO

-- History: 
--    20101209- added option to run by site for go-live processes of smaller batches.
--    20110224: changed hard coding of API directory to pull in LOV value.
--    20120304: Added qualifier to process only the ETO Entities (datasource = null)
--    20121105: Added print of file record before calling function to actually write to file (troubleshooting)
--    20121119: Problem with writing more than 255 records to the file.  Therefore, a break has been created
--              to stop/wrapup the process at 250 records.  This leaves the remaining dw_completed_courses
--              in a null sync_phase to be picked up on the next run.

print 'Begin Procedure: SP_DW_to_ETO_Course_History'

DECLARE @RecID		int
DECLARE @Entity_ID	int
DECLARE @Site_ID	int
DECLARE @Course_Name	nvarchar(80)
DECLARE @Completion_Date	datetime
DECLARE @Reason_For_Education nvarchar(40)
DECLARE @API_Record	nvarchar(200)
DECLARE @API_Record_Ctr	int

-- File information:
DECLARE @path		nvarchar(100)
DECLARE @filename	nvarchar(100)
DECLARE @delfilecmd	nvarchar(200)
DECLARE @carriage_return	nvarchar(10)
set @carriage_return = '
'

-- set @path = '\\nfpden.local\shares\CIS2009\DataWarehouse\API_ETO_Survey'
BEGIN
   select @path = LOVV.value
     from dbo.LOV_Names LOVN
     inner join dbo.LOV_Values LOVV
        on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID
    where LOVN.Name = 'INTEGRATION_PARMS'
      and LOVV.LOV_Item = 'API_File_Directory';
END

set @filename = 'api_course_history.txt'
set @delfilecmd = 'DEL ' +@path +'\' +@filename

Set @API_Record_Ctr = 0
set nocount on

--Record example:
--EntityID,22060,22061,35445
--3556,"UNIT2","2009-01-14","Hired at a New Site"
--3532,"UNIT2","2009-01-12","Hired at a New Site"


-- Calls file spWriteStringToFile utility with the following parms: data, path, filename
-- If the file exists, then it appends each line sent, otherwise, it creates the file.
-- Example call:
-- exec spWriteStringToFile @line,'\\nfpden.local\shares\CIS2009\DataWarehouse','testfile.txt'

-- ** Commented the delete function, to be done after actual API process,
--    Otherwise, will append new date to file upon next run.
-- print 'Delete file command: '+@delfilecmd
-- exec master..xp_cmdshell @delfilecmd
-- print 'continue'

-- Clear Temp_API table:
delete from dbo.temp_API

----------------------------------------------------------------------------------------
-- Build an API cursor of new Completed Courses
----------------------------------------------------------------------------------------
DECLARE APICursor Cursor for
Select DWCC.RecID
      ,DWCC.Entity_ID
      ,DWCC.Course_Name
      ,DWCC.Completion_Date
      ,DWCC.Reason_For_Education
      ,IA_Staff.Site_ID
  from dbo.DW_Completed_Courses DWCC
  inner join dbo.IA_Staff
     on DWCC.Entity_ID = IA_Staff.Entity_ID
 where DWCC.Sync_Phase is null
   and DWCC.Course_Name != ''
   and IA_STAFF.DataSource is null
   and isnull(@p_site_id,'99999999') in ('99999999',ia_staff.site_id);

OPEN APICursor

FETCH next from APICursor
      into @RecID
          ,@Entity_ID
          ,@Course_Name
          ,@Completion_Date
          ,@Reason_For_Education
          ,@Site_ID


WHILE @@FETCH_STATUS = 0
BEGIN

   set @API_Record_Ctr = @API_Record_Ctr + 1

   IF @API_Record_Ctr = 250
      break;

   IF @API_Record_CTR = 1
      BEGIN
--    Write Header Record:
      set @API_Record = 'EntityID,22060,22061,35445'
      --print @API_Record
      insert into dbo.temp_API (API_Record) Values (@API_Record)
      print @api_record
      set @API_Record =  @API_Record +@carriage_return
      exec spWriteStringToFile @API_Record,@path,@filename,'Y'
      END



-- Format Detail Record:
   set @API_Record = convert(varchar,@Entity_ID)
       +',"' +isnull(@Course_Name,'') +'"'
       +',"' +replace(convert(varchar(10),@Completion_Date,102),'.','-') +'"'
       +',"' +isnull(@Reason_For_Education,'') +'"'


   insert into dbo.temp_API (API_Record) Values (@API_Record)

   update dbo.DW_Completed_Courses
      set Sync_Phase = '1'
    where RecID = @RecID


   print @api_record
   set @API_Record =  @API_Record +@carriage_return
   exec spWriteStringToFile @API_Record,@path,@filename


   FETCH next from APICursor
         into @RecID
             ,@Entity_ID
             ,@Course_Name
             ,@Completion_Date
             ,@Reason_For_Education
             ,@Site_ID


END -- End of APICursor loop

CLOSE APICursor
DEALLOCATE APICursor


print 'API Records Created: ' +convert(varchar,@API_Record_CTR)

PRINT 'End of Procedure: SP_DW_to_ETO_Course_History'
GO
