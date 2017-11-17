USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_survey_Responses_Part_B_local]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_survey_Responses_Part_B_local
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_survey_Responses_Part_B_local]
  @p_surveyid         int,
  @p_surveyResponseID int,
  @p_debug_level smallint = 0,
  @p_pseudonym   nvarchar(50)
AS
-- This script processes the the Survey Elemnents for specific Survey Table and ResponseID.
-- ** This is a sub process called from the main procedure **
--
-- Parameters:
--   p_surveyid = SurveyID, if 0, will process all surveys flatfile tables
--   p_debug_level = null, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code

-- Processing Steps:
--   Build table of Surveys to process, then for each Survey:
--     Add a non-existing DW Survey entry for the ETO response
--       (qualify response will have an existing DW Agency, Entity, Client record)
--     For all DW responses that have a false ElementsProcessed flag, process elements.
--
-- Special processing flag: ElementsProcessed, is set to 1 (processed) when 
-- all elements have been updated for an individual survey response.  This inhibits
-- it from being processed again.  (Updates are not required, becuase ETO maintains 
-- surveys by deleting the old response adding a new updated survey response).
--
-- History: 20101205 - New SUbpart
--   20111010 - Updated for ETO upgrade, replacing SurveyElementResponseText with
--              dbo.SurveyElementResponseNumeric for Numeric fields
--              dbo.SurveyElementResponseArbText for text fields
--   20120118 - Added DW_AuditDate for runtime stamp
--   20120228 - Changed final update for to update dw_auditdate for refreshes
--   20120320 - Changed how non-exclusive answers are processed, creating a string answers
--              first, then updating the column.  This is to clear the field during a refresh
--              instead of appending selected choices on to the tail end of the column.
--   20120515 - Modified to remove embedded quotes from non-exclusive choices, caused errors in sql string.
--   20121001 - Added parm for processing just one pseudonym, used during refreshing on specified columns.
--   20130418 - Changed the stripping of single quotes from choice values, to use an MS-Word apostrophe.
--   20130422 - Added logic to excluded specific sites via the dbo.Sites_Excluded table.
--   20130522 - Added logic to strip tab char(9) and linefeed char(10) from text columns.
--   20131105 - Added logic to strip carriage return char(13)  from text columns.
--   20150416 - Added call to sub proc for custom data calculations per specific DW_Tablename:
--              Alternative_Encounter and Home_Visit_Encounter: populate Time_Start / Time_End columns
--              based upon individual component columns, also calculate duration:
--              dbo.SP_DW_Data_Calc_Alternative_Encounter_Survey
--              dbo.SP_DW_Data_Calc_Home_Visit_Encounter_Survey

DECLARE @p_ETOSRVRDB	nvarchar(50)
--set @p_ETOSRVRDB = 'etosolaris'
set @p_ETOSRVRDB = 'etosolaris'

DECLARE @runtime 	datetime
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_TO_DW_SURVEY_RESPONSES_PART_B_LOCAL'
set @runtime = getdate()

DECLARE @SurveyID	int
DECLARE @SurveyType	nvarchar(10)
DECLARE @DW_TableName	nvarchar(50)
DECLARE @SurveyResponseID	int
DECLARE @SurveyElementID	int
DECLARE @SurveyElementTypeID	smallint
DECLARE @SequenceOrder	smallint
DECLARE @Pseudonym	nvarchar(100)
DECLARE @DW_record_choice_as_seqnbr bit
DECLARE @DW_Extend_NonExclusive_Columns bit
DECLARE @Column		nvarchar(100)
DECLARE @Select_Fields	nvarchar(1900)
DECLARE @Surveys_Ctr	int
DECLARE @begdate	datetime
DECLARE @enddate	datetime
DECLARE @sql            nvarchar(4000)
DECLARE @count		smallint
declare @answers 	nvarchar(3000)

set @Surveys_Ctr = 0

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
         ,index_1 = @p_SurveyResponseID
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
-- Process the elements for the specified Survey Response ID
-- (updated from ETO to the master DW tbl)
----------------------------------------------------------------------------------------
IF @p_debug_level = 3
   print 'Start Process: SP_ETO_to_DW_Survey_Responses_Part_B_local'

set @SurveyID = @p_SurveyID

select @SurveyType = SurveyType
      ,@DW_TableName = DW_TableName
  from dbo.Mstr_surveys
 where SurveyID = @p_surveyID;


----------------------------------------------------------------------------------------
-- Process the survey elements, updating all DW Survey records
-- that have the ElementsProcessed bit still set to null
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Processing Elements for '
       +@DW_TableName +', SurveyID=' +convert(varchar,@SurveyID)

-- Build select fields for dynamic element fields using cursor:

   DECLARE ElementCursor Cursor for
   select SurveyElementID
         ,Pseudonym
         ,SurveyElementTypeID
         ,SequenceOrder
         ,DW_record_choice_as_seqnbr
         ,DW_Extend_NonExclusive_Columns
     from dbo.Mstr_SurveyElements
    where SurveyID = @SurveyID
      and Pseudonym is not null
      and Pseudonym = isnull(@p_pseudonym,Pseudonym)
      and SurveyElementTypeID <= 12;

   set @Select_fields = '';

   OPEN  ElementCursor 

   FETCH next from  ElementCursor 
         into @SurveyElementID
             ,@Pseudonym
             ,@SurveyElementTypeID
             ,@SequenceOrder
             ,@DW_record_choice_as_seqnbr
             ,@DW_Extend_NonExclusive_Columns

   WHILE @@FETCH_STATUS = 0
   BEGIN

      set nocount on
      update dbo.process_log 
         set Phase = 'Element'
            ,index_2 = @SurveyElementID
            ,LogDate = getdate()
       where Process = @process

      IF @p_debug_level = 3
         print 'Processing Element Cursor Loop: elementID=' +Convert(varchar,@surveyElementID) +', type=' +convert(varchar,@SurveyElementTypeID)

      Set @Column = @Pseudonym

      If @SurveyElementTypeID in (1)
         BEGIN
         --NON-EXLUSIVE

         set @SQL = ''
         IF @p_debug_Level = 0
            set @SQL = 'set nocount on '

         set @answers = null
         Declare AvailableAnswers cursor for
         Select left(SurveyElementChoices.Choice,1000) as ChoiceText
           FROM  etosolaris.dbo.SurveyResponses
           INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
                   ON SurveyResponses.SurveyResponseID = SurveyElementResponses.SurveyResponseID 
           INNER JOIN etosolaris.dbo.SurveyElementResponseChoice SurveyElementResponseChoice
                   on SurveyElementResponseChoice.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
           INNER JOIN etosolaris.dbo.SurveyElementChoices SurveyElementChoices
                   on SurveyElementResponseChoice.SurveyElementChoiceID = SurveyElementChoices.SurveyElementChoiceID 
           Where SurveyResponses.SurveyResponseID = @p_SurveyResponseID
             and SurveyElementResponses.SurveyElementID = @SurveyElementID
							
         Declare @Choice varchar(1000)
         Open AvailableAnswers
							
         Fetch next from AvailableAnswers into @Choice
							
         While @@FETCH_STATUS = 0
         Begin 

            IF @DW_record_choice_as_seqnbr = 1
               BEGIN
                  set @answers = LEFT(ISNULL(@answers +'; ','') +convert(varchar,@SequenceOrder),3000)
               END
            ELSE
               BEGIN
                  set @answers = LEFT(ISNULL(@answers +'; ','') +replace(@Choice,char(39),'’'),3000)
               END

            Fetch next from AvailableAnswers into @Choice

         End
							
         CLOSE AvailableAnswers
         DEALLOCATE AvailableAnswers


         set @SQL = @SQL +' Update ' + @DW_TableName + '  set [' + Left(@Column,100)+ '] =  LEFT(''' +  @answers +''',3000)
            Where SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)

         IF @p_debug_level = 3
            Print @SQL
         exec (@SQL)


         --TO HANDLE BUG 2310	
--         IF LEN(@SurveyCommentStimulus) > 0
--            BEGIN
--               Set @SQL = 'set nocount on Update ' + @TableName + ' set '
--               Set @SQL = @SQL + ' ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--               Set @SQL = @SQL + ' FROM  ' + @TableName + ' 	
--                 INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses 
--                 INNER JOIN etosolaris.dbo.SurveyElementResponseChoice SurveyElementResponseChoice
--                 INNER JOIN etosolaris.dbo.SurveyElementChoices SurveyElementChoices 
--                         on SurveyElementResponseChoice.SurveyElementChoiceID = SurveyElementChoices.SurveyElementChoiceID 
--                         on SurveyElementResponseChoice.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
--                         on SurveyElementResponses.SurveyResponseID =  ' + @TableName + '.SurveyResponseID  
--                        and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID)
--               --Print @SQL
--               exec (@SQL)
--            END	
					
      END


      If @SurveyElementTypeID in (2)
         BEGIN
            -- Exclusive Choice
            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '
            Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = left(SurveyElementChoices.Choice,1000)'

--            IF LEN(@SurveyCommentStimulus) > 0
--               BEGIN
--                  Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--               END	
				
            Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
                INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
                INNER JOIN etosolaris.dbo.SurveyElementResponseChoice SurveyElementResponseChoice
                INNER JOIN etosolaris.dbo.SurveyElementChoices SurveyElementChoices
                        on SurveyElementResponseChoice.SurveyElementChoiceID = SurveyElementChoices.SurveyElementChoiceID
                        on SurveyElementResponseChoice.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
                        on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID
                       and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)
            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)
         END


      IF @SurveyElementTypeID in (3,4) 
         BEGIN
         --Arbitrary Text, Arbitrary Prose

            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '
            Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = '
            set @SQL = @SQL +'left(replace(replace(replace(SurveyElementResponseArbText.TextValue,char(9),''''),char(10),''''),char(13),''''),3000)'

     --       IF LEN(@SurveyCommentStimulus) > 0
     --          BEGIN
     --             Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
     --          END	
		
            Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
               INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
                  on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID
                 and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               INNER JOIN etosolaris.dbo.SurveyElementResponseArbText SurveyElementResponseArbText
                  on SurveyElementResponseArbText.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)

            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)

         END


      IF @SurveyElementTypeID in (6,7,8) 
         BEGIN

            --Percent/Money/Number
            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '
            Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = 
                 SurveyElementResponseNumeric.NumericValue'

--            IF LEN(@SurveyCommentStimulus) > 0
--               BEGIN
--                  Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--            END	
		
            Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
                INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
                INNER JOIN etosolaris.dbo.SurveyElementResponseNumeric SurveyElementResponseNumeric
                        on SurveyElementResponseNumeric.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
                        on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID 
                       and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)
            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)

         END


      IF @SurveyElementTypeID = 9
         BEGIN
		
            --Boolean
            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '
            Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = SurveyElementResponseBoolean.Boolean'

--            IF LEN(@SurveyCommentStimulus) > 0
--               BEGIN
--                  Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--               END	
		
            Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
                INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
                INNER JOIN etosolaris.dbo.SurveyElementResponseBoolean SurveyElementResponseBoolean 
                        on SurveyElementResponseBoolean.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
                        on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID 
                       and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)
            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)

         END


     IF @SurveyElementTypeID = 10 
        BEGIN

           --Date
           set @SQL = ''
           IF @p_debug_Level = 0
              set @SQL = 'set nocount on '
           Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = SurveyElementResponseDate.DateValue'
--           IF LEN(@SurveyCommentStimulus) > 0
--              BEGIN
--                 Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--              END	
		
           Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
               INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
               INNER JOIN etosolaris.dbo.SurveyElementResponseDate SurveyElementResponseDate
               on SurveyElementResponseDate.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
               on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID 
               and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)
           IF @p_debug_level = 3
               Print @SQL
           exec (@SQL)

        End


      If @SurveyElementTypeID in (11)
         BEGIN
            --PCR
            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '
            Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = ' 
            -- NFP 20100817: retain ID, don't replace with name:
            +'SurveyElementResponsePCR.CLID'
            -- left(Clients.Lname + '', '' + Clients.FName,1000)'

--            IF LEN(@SurveyCommentStimulus) > 0
--               BEGIN
--                  Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--               END
	
            Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
                INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses 
                INNER JOIN etosolaris.dbo.SurveyElementResponsePCR SurveyElementResponsePCR
                INNER JOIN etosolaris.dbo.Clients Clients
                        on SurveyElementResponsePCR.CLID = Clients.CLID 
                        on SurveyElementResponsePCR.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
                        on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID  
                        and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)
            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)
         END

      If @SurveyElementTypeID in (12)
         BEGIN
            --ECR
            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '
            Set @SQL = @SQL +'Update ' + @DW_TableName + ' set [' + Left(@Column,100)+ '] = ' 
            -- NFP 20100817: retain ID, don't replace with name:
            +'SurveyElementResponseECR.EntityID'
            -- = left(Entities.EntityName ,1000)'

--            IF LEN(@SurveyCommentStimulus) > 0
--               BEGIN
--                  Set @SQL = @SQL + ',  ['  + Left(@Column,50)+  '_' + Left(@SurveyCommentStimulus,50)+ '] = SurveyElementResponses.CommentText'
--               END	
				
            Set @SQL = @SQL + ' FROM  ' + @DW_TableName + '
                INNER JOIN etosolaris.dbo.SurveyElementResponses SurveyElementResponses
                INNER JOIN etosolaris.dbo.SurveyElementResponseECR SurveyElementResponseECR 
                INNER JOIN etosolaris.dbo.Entities Entities 
                        on SurveyElementResponseECR.EntityID = Entities.EntityID 
                        on SurveyElementResponseECR.SurveyElementResponseID = SurveyElementResponses.SurveyElementResponseID 
                        on SurveyElementResponses.SurveyResponseID =  ' + @DW_TableName + '.SurveyResponseID  
                       and SurveyElementResponses.SurveyElementID = ' + Convert(varchar(10),@SurveyElementID) +'
               Where ' + @DW_TableName + '.SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)

            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)
         END


      FETCH next from  ElementCursor 
            into @SurveyElementID
                ,@Pseudonym
                ,@SurveyElementTypeID
                ,@SequenceOrder
                ,@DW_record_choice_as_seqnbr
                ,@DW_Extend_NonExclusive_Columns

   END -- while loop for dynamic fields

   CLOSE ElementCursor 
   DEALLOCATE ElementCursor 


----------------------------------------------------------------------------------------
-- Custom Data Calculations based upon specific DW_Tablename
-- exclude if the runtime parm for single p_pseudonym is specified.
----------------------------------------------------------------------------------------
   IF @p_pseudonym is null and
      @DW_TableName in ('ALTERNATIVE_ENCOUNTER_SURVEY','HOME_VISIT_ENCOUNTER_SURVEY')
   BEGIN

      IF @p_debug_level = 3
         print 'Cont: SP_ETO_to_DW_Survey_Responses - Custom Data Calculations'

      set nocount on
      update dbo.process_log 
         set Phase = 'Custom Data Calculations'
            ,LogDate = getdate()
       where Process = @process
       
      IF @DW_TableName = 'ALTERNATIVE_ENCOUNTER_SURVEY'
         exec SP_DW_Data_Calc_Alternative_Encounter_Survey @p_surveyResponseID,0

      IF @DW_TableName = 'HOME_VISIT_ENCOUNTER_SURVEY'
         exec SP_DW_Data_Calc_Home_Visit_Encounter_Survey @p_surveyResponseID, 0

   END

----------------------------------------------------------------------------------------
-- Update the Survey Response just processed, setting the ElementsProcessed = 1 (true)
--  (only update if the the entire set of columns were processed)
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Updating Survey as Processed'

   set nocount on
   update dbo.process_log 
      set Phase = 'Updating Survey as processed'
         ,LogDate = getdate()
    where Process = @process

   IF @p_pseudonym is null 
   BEGIN
      Set @SQL ='set nocount on
         update dbo.' +@DW_TableName 
         +' set ElementsProcessed = 1'
         +' ,DW_AuditDate = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
         +' where SurveyResponseID = ' +convert(varchar,@p_SurveyResponseID)
         --+' and isnull(ElementsProcessed,0) != 1'
       IF @p_debug_level = 3
          Print @SQL
       EXEC (@SQL)
   END


set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process

IF @p_debug_level = 3
   print 'End Process: SP_ETO_to_DW_Survey_Responses_Part_B_local'
GO
