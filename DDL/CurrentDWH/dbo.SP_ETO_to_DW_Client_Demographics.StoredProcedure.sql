USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_Client_Demographics]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_Client_Demographics
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_Client_Demographics]
  @p_client_id    int = null,
  @p_debug_level  smallint = 0
AS

--  *** test version ***


-- Script to extract all Client custom Demographics as flattened row:
-- ClientID, followed by Demographics collumns
-- 
--
-- Steps:
-- Define variables used in process.
-- Defines a query for the basic Demographics master indexes.
-- Define an Inner query that extracts the actual attributes.
-- Build a cursor to read and format a list of Demographics indexes.
-- Execute a main query (with all the other pieces) extracting a pivot of Demographics:

-- Uses DW dbo.view_ETO_Client_Demographics to consolidate attribute fields by ClientID,cdid
-- For non-exclusive attributes, the DW attribute may be flagged to extend the
-- columns out for each available choice.

-- History:
--   20110211 - Changed the Demographic_last_update to = max(auditdate) for eto demographics instead of curr sysdate.
--              problems would arise from ETO changes continuing before this process was actually run, 
--              thus never getting updated to the DW client record.
--   20110721 - Re-write of original process (sp_eto_to_dw_client_demographics) to process by client
--              utilizing the new date field: Clients.Last_Demog_Update.  This will force an entire
--              update to the client record for anytime any of their demographic attributes change, 
--              and to allow for re-sync.
--   20110901 - Changed to not record attribute sequence nbr, record only the text value.
--   20120510 - Fixed problem where attributes are not matched to a dw column by pseudonym.  They 
--              were being written to the last pseudonym.   Will now bypass the attribute.
--   20130111 - Fixed problem with non-exclusive attribute not getting a closing quote when last field processed
--              did not have a pseudonym.  Changed to qualify only demographics that have a pseudonym defined.
--   20130422 - Added logic to exclude specific sites via dbo.Sites_Excluded table.
--   20130910 - Checks the text value, replacing quotes with an ms-word style quote.
--   20160225 - Added processing for boolean data.
--   20160520 - Changed the @vecd_datevalue from a smalldatetime datatype to a datetime (reflecting changes from SSG).


--  ** can't qualify just one pseudonym for an update because of the severe performance impact in 
--     query retrieving the view data linked to the pseudonym.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_TO_DW_CLIENT_DEMOGRAPHICS'

DECLARE @Client_ID	int
DECLARE @Site_ID	int
DECLARE @CDID		smallint
DECLARE @Last_CDID      smallint
DECLARE @CxDTypeID	smallint
DECLARE @Hdr_CxDTypeID	smallint
DECLARE @SequenceOrder	int
DECLARE @RecordAsNumeric	bit
DECLARE @RecordAsArbitraryText	bit
DECLARE @IsProgramSpecific  bit
DECLARE @Pseudonym          nvarchar(50)
DECLARE @dw_extend_NonExclusive_columns bit
DECLARE @DW_record_choice_as_seqnbr	bit
DECLARE @vecd_clientid      int
DECLARE @vecd_textvalue     nvarchar(2000)
DECLARE @vecd_datevalue     datetime
DECLARE @vecd_choicesequence  smallint
DECLARE @vecd_TextSequence    smallint
DECLARE @HdrDtl             smallint
DECLARE @Last_Demog_Update datetime
DECLARE @max_Demog_Auditdate datetime
DECLARE @TableName          nvarchar(50)
DECLARE @ColumnName         nvarchar(50)
DECLARE @ColumnNameExtended nvarchar(50)
DECLARE @ColumnAttribute    nvarchar(50)
DECLARE @return_stat        int
DECLARE @SQL                varchar(4000)
DECLARE @SQL2               varchar(2000)
DECLARE @SQL3               varchar(2000)
DECLARE @concatfield        varchar(2000)
DECLARE @colctr             int
DECLARE @fldctr             int
DECLARE @itemctr            int
DECLARE @recs_processed_ctr int

print 'Starting procedure SP_ETO_to_DW_Client Demographics p_client_id='+convert(varchar,@p_client_Id)

----------------------------------------------------------------------------------------
-- Initiate the Process Log
----------------------------------------------------------------------------------------

-- Check for existance for this process, if not found, add one:
select @count = count(*) from dbo.process_log where Process = @Process

set nocount on
set @recs_processed_ctr = 0

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
         ,index_2 = @recs_processed_ctr
         ,index_3 = null
    where Process = @process

-- Validate that all columns exist for demographich attributes/choices, if not process will add column.
exec dbo.SP_Validate_Client_Demographic_Columns 

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Build a cursor of clients that have demographic attributes found to have been 
-- changed since the last_demog_update 
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

DECLARE ClientCursor Cursor for
select Clients.client_ID
      ,CASE when @p_client_id is not null then CONVERT(datetime,'19690101',112)
            else isnull(Clients.Last_Demog_Update,CONVERT(datetime,'19690101',112)) END
      ,isnull(MAX(vecd.auditdate),CONVERT(datetime,'19690101',112))
      ,clients.site_id
  from dbo.Clients 
  inner join dbo.View_ETO_Client_Demographics vecd
          on Clients.Client_ID = vecd.CLID
 where isnull(@p_client_id,99999999) in (99999999,Clients.Client_ID)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Clients.Site_Id)
 group by Clients.Client_ID, clients.site_id, Last_Demog_Update ;


OPEN ClientCursor

FETCH next from ClientCursor
      into @client_id
          ,@last_demog_update
          ,@max_demog_auditdate
          ,@Site_ID

WHILE @@FETCH_STATUS = 0
BEGIN

-- go / no go check:

IF @p_client_id is not null or
   @last_demog_update < @max_demog_auditdate
   BEGIN

--------- update Process Log ----------------
set nocount on
set @recs_processed_ctr = @recs_processed_ctr + 1
update dbo.process_log 
   set Phase = 'Processing Client'
      ,comment = null
      ,LogDate = getdate()
      ,Index_1 = @client_id
      ,index_2 = @recs_processed_ctr
 where Process = @process
---------------------------------------------

----------------------------------------------------------------------------------------
-- Build and process cursor for all Client Demographics
-- (updated from ETO to the master DW tbl)
----------------------------------------------------------------------------------------

-- Initilize the beginning of the SQL statement, zero column counter:

set @SQL = ''

IF @p_debug_Level = 0
   set @SQL = 'set nocount on '

set @SQL= @SQL +'UPDATE  dbo.Clients set '
set @SQL2 = ''
set @SQL3 = ''
set @colctr = 0
set @Last_CDID = 0 
set @Hdr_CxDTypeID = 0


DECLARE DemographicsCursor Cursor for
select * from
(
select CDID
      ,0 as hdr_dtl
      ,CxDTypeID
      ,SequenceOrder
      ,RecordAsNumeric
      ,RecordAsArbitraryText
      ,IsProgramSpecific
      ,Pseudonym
      ,dw_extend_NonExclusive_columns
      ,DW_record_choice_as_seqnbr
      ,null as textvalue
      ,null as datevalue
      ,null as textsequence
  from dbo.Mstr_Client_Demographics Client_Demographics
 where CxDTypeID in (1,2,3,4,5,6)
   and Pseudonym is not null
   and isnull(SiteID,@site_id) = @site_id
union all
select vecd.CDID
      ,1 as hdr_dtl
      ,null as CxDTypeID
      ,null as SequenceOrder
      ,null as RecordAsNumeric
      ,null as RecordAsArbitraryText
      ,null as IsProgramSpecific
      ,null as Pseudonym
      ,null as dw_extend_NonExclusive_columns
      ,null as DW_record_choice_as_seqnbr
      ,vecd.textvalue
      ,vecd.datevalue
      ,vecd.textsequence
 from dbo.View_ETO_Client_Demographics vecd 
 inner join dbo.Mstr_Client_Demographics mcd on vecd.CDID = mcd.CDID
 where vecd.CLID = @client_id
   and mcd.Pseudonym is not null
) clx
 order by CDID,hdr_dtl;

-- CXDTypeID: 1=Boolean, 2=Numeric, 3=Arbitrary Text, 4=Defined Text Values,
--            5=Non-Exclusive Choices, 6= Date

OPEN DemographicsCursor

FETCH next from DemographicsCursor
      into @CDID
          ,@HdrDtl
          ,@CxDTypeID
          ,@SequenceOrder
          ,@RecordAsNumeric
          ,@RecordAsArbitraryText
          ,@IsProgramSpecific
          ,@Pseudonym
          ,@dw_extend_NonExclusive_columns
          ,@DW_record_choice_as_seqnbr
          ,@vecd_textvalue
          ,@vecd_datevalue
          ,@vecd_textsequence

WHILE @@FETCH_STATUS = 0
BEGIN

-- This is a process of reading the cursor, which consists of many records, in two record pairs of header/detail,
--   which are paired up into pseudonym and value.  
-- The pseudonym is identified as the header record (@hdrdtl=0), retrieved from the master_client_demographics
--    using the pseudonym as the dbo.client.columnname. 
-- The corresponnding attribute value is the detail record (@hdrdtl=1), retreived from the etosolaris db.
-- One long SQL command strinc is created for a single dbo.client record, encompasing the entire update
--   for all paired column psudonym / attribute field values (each being appended onto the SQL string).
-- When the cursor has completed, the SQL string is executed, writing the final update record.

 IF @HdrDtl = 1 and
    (@Last_CDID = 0 or @Last_CDID != @CDID)
    -- no detail for previous header, and/or no header for current detail, bypass:
   set @fldctr = 0
 ELSE
 BEGIN
   -- continue with valid record pairing

   IF @HdrDtl = 0 
   BEGIN
      IF @Last_CDID != 0
         -- wrapup last column into SQL statement:
         BEGIN
           set @SQL = @SQL +@SQL2 

           IF @SQL3 != ''
           BEGIN
              IF @fldctr != 0
              BEGIN
                 -- (@fldctr is used for the multiple non exclusive choices attributes)
                 -- add closing quote (only if data has been suppied)
                 set @SQL3 = @SQL3 +''''
              END
              set @colctr = @colctr + 1
              IF @colctr != 1
                 set @SQL = @SQL +',' +@SQL3
              ELSE
                 set @SQL = @SQL +@SQL3
           END
         END

      -- Initialize for new header/dtl series
      set @SQL3 = ''
      set @SQL2 = ''
      set @fldctr = 0
      set @Hdr_CxDTypeID = @CxDTypeID
      set @ColumnName = @Pseudonym
      IF @CxDTypeID = 1
         set @ColumnAttribute = 'bit null'
      IF @CxDTypeID = 2
         set @ColumnAttribute = 'numeric(15,5) null'
      IF @CxDTypeID IN (3,4,5)
         set @ColumnAttribute = 'nvarchar(2000) null'
      IF @CxDTypeID = (6)
         set @ColumnAttribute = 'datetime null'
   END

   set @last_CDID = @CDID

   IF @p_debug_level != 0
      print 'Processing Demographics CDID=' +convert(varchar,@CDID) +', Pseudonym=' +@Pseudonym

----------------------------------------------------------------------------------------
-- process for non-exclusive Demographics:
--       Initialize the basic update SQL statement and concatenated work field.
--       Then when build a cursor of selected choices, creating either one concatenated field
--         or multiple SQL 'set' statetments for corresponding columns per choice.
--       Once cursor is completed, finalize the update SQL statement and execute it.
----------------------------------------------------------------------------------------
   IF (@Hdr_CxDTypeID = 5) 
      BEGIN

--       Build and process cursor for choices
--       then then concatenate the choices into one  field,
--       also if flagged to extend the choices as individual columns,
--       create indiividual SQL set statements where for each unique column/choice:


         IF @HdrDtl = 0
           BEGIN
             -- initialize default value for column if in case no detail is found
             set @SQL3 = '[' + Left(@ColumnName,100) +'] = NULL'
             set @concatfield = ''
           END

         ELSE
           BEGIN




               -- update choice, appended into one main field (SQL3 field)
               set @fldctr = @fldctr + 1

               IF @fldctr = 1
                  -- initialize with column name to update
                  set @SQL3 = ' [' + Left(@ColumnName,100)+ '] = ''' 
               ELSE
                  -- multiple fields being concatenated, add colon separator within concatenation
                  set @SQL3 = @SQL3 +';' 

               IF @DW_record_choice_as_seqnbr = 1 and @vecd_textsequence is not null
                  set @SQL3 = @SQL3 + convert(varchar,@vecd_textsequence)
               ELSE
                  set @SQL3 = @SQL3 + @vecd_TextValue



           END  -- detail fork

      END -- End process for non-exclusive

----------------------------------------------------------------------------------------
-- process for all other Demographics types:
----------------------------------------------------------------------------------------
   ELSE
      BEGIN

--       CXDTypeID: 1=Boolean, 2=Numeric, 3=Arbitrary Text, 4=Defined Text Values, 6= Date
--                  5=Non-Exclusive Choices (already prepared)

         IF @HdrDtl = 0
          BEGIN
            set @colctr = @colctr + 1
            IF @colctr != 1
               -- not the first column in SQL statement, add comma separator
               set @SQL =  @SQL + ','

            set @SQL = @SQL +'[' + Left(@ColumnName,100)+ '] = '
            set @SQL2 = 'NULL'
          END
         ELSE
          BEGIN
               IF @Hdr_CxDtypeID in (1)
                 set @SQL2 = '''' +left(@vecd_TextValue ,1) +''''
               IF @Hdr_CxDtypeID in (2)
                 set @SQL2 =convert(varchar,dbo.fnCleanNumericString(@vecd_TextValue))
               IF @Hdr_CxDtypeID in (3,5)
                 set @SQL2 = '''' +replace(@vecd_TextValue,char(39),'’') +''''
               IF @Hdr_CxDtypeID = 6
                 set @SQL2 = 'convert(datetime,''' +convert(varchar,@vecd_DateValue,120) +''',120)'
               IF @Hdr_CxDtypeID in (4)
                 --set @SQL2 = '''' +isnull(convert(varchar,@vecd_TextSequence),@vecd_TextValue) +''''
                 set @SQL2 = '''' +@vecd_TextValue +''''
          END  -- HdrDtl fork

      END -- End process for all other attributes
  END -- End for validation of unmatched hdr/dtl pairing

   FETCH next from DemographicsCursor
         into @CDID
             ,@HdrDtl
             ,@CxDTypeID
             ,@SequenceOrder
             ,@RecordAsNumeric
             ,@RecordAsArbitraryText
             ,@IsProgramSpecific
             ,@Pseudonym
             ,@dw_extend_NonExclusive_columns
             ,@DW_record_choice_as_seqnbr
             ,@vecd_textvalue
             ,@vecd_datevalue
             ,@vecd_textsequence

END -- End of DemographicsCursor loop

CLOSE DemographicsCursor
DEALLOCATE DemographicsCursor


-- wrapup the SQL statement, the execute:
-- (add Last_Demog_Update with the max demographic attribute change date)

         
   IF @colctr != 0 or @sql3 != ''
   BEGIN
       -- wrapup last column into SQL statement:
       set  @SQL = @SQL +@SQL2

           IF @SQL3 != ''
           BEGIN
              IF @fldctr != 0
              BEGIN
                 -- add closing quote (only if data has been suppied)
                 set @SQL3 = @SQL3 +''''
              END
              set @colctr = @colctr + 1
              IF @colctr != 1
                 set @SQL = @SQL +',' +@SQL3
              ELSE
                 set @SQL = @SQL +@SQL3
           END

       set @SQL = @SQL +',Last_Demog_Update = ' 
           +'convert(datetime,''' +convert(varchar,@max_demog_auditdate,113) +''',113)'
           +' FROM  dbo.Clients where Client_ID = ' +convert(varchar, @client_id)
             
       IF @p_debug_level = 3
           Print @SQL
       exec (@SQL)
   END

END  -- go/no go validation prior to demographics cursor, for selected client or actual auditdate change

-------------------------------------
-- Continue with next Client Record:
-------------------------------------

FETCH next from ClientCursor
      into @client_id
          ,@last_demog_update
          ,@max_demog_auditdate
          ,@Site_ID


END -- End While for ClientCursorloop

CLOSE ClientCursor
DEALLOCATE ClientCursor

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

print 'EOJ - SP_ETO_to_DW_Client_Demographics'

GO
