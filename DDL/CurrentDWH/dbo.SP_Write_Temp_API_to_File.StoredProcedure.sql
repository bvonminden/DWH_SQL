USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Write_Temp_API_to_File]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Write_Temp_API_to_File
--
CREATE PROCEDURE [dbo].[SP_Write_Temp_API_to_File]
AS
--
-- This reads the temp_api table and writes each record to the api file

print 'Begin Procedure: SP_Write_Temp_API_to_File'

DECLARE @api_record	nvarchar(200)
DECLARE @api_record_ctr int

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

-- Calls file spWriteStringToFile utility with the following parms: data, path, filename
-- If the file exists, then it appends each line sent, otherwise, it creates the file.
-- Example call:
-- exec spWriteStringToFile @line,'\\nfpden.local\shares\CIS2009\DataWarehouse','testfile.txt'


-- ** Commented the delete function, to be done after actual API process,
--    Otherwise, will append new date to file upon next run.
-- print 'Delete file command: '+@delfilecmd
-- exec master..xp_cmdshell @delfilecmd
-- print 'continue'

----------------------------------------------------------------------------------------
-- Build an API cursor of Temp_API records
----------------------------------------------------------------------------------------
DECLARE APICursor Cursor for
Select api_record
  from dbo.temp_api;

OPEN APICursor

FETCH next from APICursor
      into @api_record


WHILE @@FETCH_STATUS = 0
BEGIN

   set @API_Record_Ctr = @API_Record_Ctr + 1

   set @API_Record = @API_Record +@carriage_return

   exec spWriteStringToFile @API_Record,@path,@filename


   FETCH next from APICursor
      into @api_record


END -- End of APICursor loop

CLOSE APICursor
DEALLOCATE APICursor


print 'API Records Written: ' +convert(varchar,@API_Record_CTR)

PRINT 'End of Procedure: SP_Write_Temp_API_to_File'
GO
