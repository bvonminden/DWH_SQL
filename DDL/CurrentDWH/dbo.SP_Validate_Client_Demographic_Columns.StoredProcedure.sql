USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Validate_Client_Demographic_Columns]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Validate_Client_Demographic_Columns
CREATE PROCEDURE [dbo].[SP_Validate_Client_Demographic_Columns]
  @p_debug_level  smallint = 0
AS

-- This procedure validates that all Master Demographic Attributes exist as columns in the Data Warehouse Table. 
-- If they do no, than a new column is added with the master field attributes for the defined pseudonym.
--
-- History:
--   20110722 - New Procedure created.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_VALIDATE_Client_Demographic_COLUMNS'


DECLARE @tablename	varchar(50)
DECLARE @CDID		int
DECLARE @CxDTypeID	int
DECLARE @RecordAsNumeric	bit
DECLARE @RecordAsArbitraryText	bit
DECLARE @IsProgramSpecific  bit
DECLARE @Pseudonym          nvarchar(50)
DECLARE @dw_extend_NonExclusive_columns bit
DECLARE @ColumnName         nvarchar(50)
DECLARE @ColumnNameExtended nvarchar(50)
DECLARE @ColumnAttribute    nvarchar(50)
DECLARE @mstr_CDDTVID	    int
DECLARE @mstr_ChoiceSequenceOrder smallint
DECLARE @return_stat        int
DECLARE @SQL                varchar(8000)


print 'Starting procedure SP_Validate_Client_Demographic_Columns'

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
----------------------------------------------------------------------------------------
-- Build a cursor of Master Demographic attributes
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

DECLARE AttributeCursor Cursor for
select mcd.CDID
      ,mcd.CxDTypeID
      ,mcd.RecordAsNumeric
      ,mcd.RecordAsArbitraryText
      ,mcd.IsProgramSpecific
      ,mcd.Pseudonym
      ,mcd.dw_extend_NonExclusive_columns
  from dbo.Mstr_Client_Demographics mcd
 where mcd.CxDTypeID in (1,2,3,4,5,6)
   and mcd.Pseudonym is not null;

-- CXDTypeID: 1=Boolean, 2=Numeric, 3=Arbitrary Text, 4=Defined Text Values,
--            5=Non-Exclusive Choices, 6= Date

OPEN AttributeCursor

FETCH next from AttributeCursor
      into @CDID
          ,@CxDTypeID
          ,@RecordAsNumeric
          ,@RecordAsArbitraryText
          ,@IsProgramSpecific
          ,@Pseudonym
          ,@dw_extend_NonExclusive_columns

WHILE @@FETCH_STATUS = 0
BEGIN

   set @TableName = 'Clients'
   set @ColumnName = @Pseudonym

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing pseudonym'
      ,comment = @tablename +'.' +@Pseudonym
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

   IF @CxDTypeID = 1
      set @ColumnAttribute = 'bit null'
   IF @CxDTypeID = 2
      set @ColumnAttribute = 'numeric(15,5) null'
   IF @CxDTypeID IN (3,4,5)
      set @ColumnAttribute = 'nvarchar(2000) null'
   IF @CxDTypeID = (6)
      set @ColumnAttribute = 'datetime null'

   IF @p_debug_level = 3
      print 'Processing Attribute CDID=' +convert(varchar,@CDID) +', Pseudonym=' +@Pseudonym

-- Check for existing table column, add one if not already found:
   EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @tablename,@ColumnName,@ColumnAttribute

----------------------------------------------------------------------------------------
-- process for non-exclusive attributes that are recorded as unique columns
----------------------------------------------------------------------------------------
   IF (@CxDTypeID = 5) and (@dw_extend_NonExclusive_columns = 1)
      BEGIN


         DECLARE ChoiceCursor  Cursor for
         select CDDTVID
               ,CxAttributesDefinedTextValues.SequenceOrder
           from dbo.Mstr_Client_Demographics Client_Demographics
           left join ETOSRVR.etosolaris.dbo.CxAttributesDefinedTextValues CxAttributesDefinedTextValues
                  on Client_Demographics.CDID = CxAttributesDefinedTextValues.CDID
          where Client_Demographics.CDID = @CDID
            and CxAttributesDefinedTextValues.Disabled = 0
          order by SequenceOrder;

         OPEN ChoiceCursor

         FETCH next from ChoiceCursor
               into @mstr_CDDTVID
                   ,@mstr_ChoiceSequenceOrder

         WHILE @@FETCH_STATUS = 0
         BEGIN

            IF @mstr_ChoiceSequenceOrder is not null
               BEGIN

                  set @ColumnNameExtended = @ColumnName +'_' +convert(varchar,@mstr_ChoiceSequenceOrder)

--                Check for existing table column, add one if not already found:
                  EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column  @tablename,@ColumnNameExtended,@ColumnAttribute

               END

            FETCH next from ChoiceCursor
                  into @mstr_CDDTVID
                      ,@mstr_ChoiceSequenceOrder

         END -- End while loop for choices

         CLOSE ChoiceCursor
         DEALLOCATE ChoiceCursor

      END -- End process for non-exclusive


   FETCH next from AttributeCursor
         into @CDID
             ,@CxDTypeID
             ,@RecordAsNumeric
             ,@RecordAsArbitraryText
             ,@IsProgramSpecific
             ,@Pseudonym
             ,@dw_extend_NonExclusive_columns

END -- End While for AttributeCursor loop

CLOSE AttributeCursor
DEALLOCATE AttributeCursor


---------------------------------------------
--   wrapup with update to Process Log     --
---------------------------------------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'EOJ - SP_Validate_Client_Demographic_Columns'

GO
