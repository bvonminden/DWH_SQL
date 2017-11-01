USE [dwh_test]
GO
/****** Object:  Schema [survey_views]    Script Date: 11/1/2017 5:05:03 PM ******/
CREATE SCHEMA [survey_views]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_hash_field]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [survey_views].[f_hash_field]
(
	@p_Requested_Hash	bit,
	@p_Value_To_Hash	varchar(4000)
)
RETURNS varchar(4000)
AS
BEGIN
	
	if @p_Requested_Hash=0
	begin
		return 	@p_Value_To_Hash;	
	end;


	return hashbytes('SHA1',@p_Value_To_Hash);
	
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_list_survey_questions]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_list_survey_questions]
(
	@p_survey_name varchar(100),
	@p_survey_time_period varchar (100)
)
RETURNS 
@t_result TABLE 
(
	survey_time_period varchar(75),
	question_number smallint,
	question varchar(3400)
)
AS
BEGIN
-- displays the list of questions asked for a given survey
	
insert into @t_result (survey_time_period, question_number, question)
Select
	sq.time_period,
	sq.question_number,
	sq.question
from dbo.dim_survey_question sq
where
	sq.survey_name=@p_survey_name
	and
	sq.time_period = case when @p_survey_time_period='*' then sq.time_period else  @p_survey_time_period	end
order by 
	question_number;

return;	
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_list_surveys]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_list_surveys]
(
)
RETURNS 
@t_response table
(
	
	survey_unique_name varchar(200) not null primary key,
	survey_name varchar(100) not null,
	survey_time_period varchar(75) not null
)
AS
BEGIN
-- awnsers the question - what surveys do we have loaded ?
	insert into @t_response (survey_unique_name, survey_name, survey_time_period) 
	select 
		distinct
	
		--convert(varchar,(survey_question_key)) + ':' + 
		survey_name + ' (' + time_period + ')',
		survey_name,
		time_period

	from dbo.dim_survey_question sq
	order by 
		survey_name;

	return;
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_replace_chars]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_replace_chars]
(
	@p_input_string varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	
	if (@p_input_string is null or @p_input_string='') return null;

	return replace(replace(replace(@p_input_string,char(13),' '),char(9),' '),char(10),' ');
END
GO
/****** Object:  View [survey_views].[Agency_Profile_Update]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Agency_Profile_Update] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'AGENCY_FUNDING01_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING01_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING02_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING03_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING04_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING05_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING06_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING07_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING08_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING09_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING10_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING11_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING12_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING13_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING14_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING15_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING16_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING17_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING18_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING19_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_0_FUNDER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_DF_GRANT_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_FUNDER_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_MEDICAID_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_FUNDING20_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_INFO_1_CONTRACT_CAPACITY_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_INFO_1_CONTRACT_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_1_FUNDED_CAPACITY_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_INFO_1_FUNDED_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE01 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE01,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE02 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE02,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE03 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE03,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE04 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE04,
max(case sq.pseudonym when 'AGENCY_RESEARCH_0_INVOLVEMENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH_0_INVOLVEMENT,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_0_PROJECT_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH01_0_PROJECT_NAME,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_APPROVAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH01_1_APPROVAL,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_END_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PI1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH01_1_PI1,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_RESEARCH01_1_START_DATE


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Agency Profile-Update'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Alternative_Encounter]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [survey_views].[Alternative_Encounter] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ALT_0_COMMENTS_ALT ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ALT_0_COMMENTS_ALT,
	max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT,
	max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_FRNDFAM_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_LIFECOURSE_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_MATERNAL_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_TOTAL_ALT,
	max(case sq.pseudonym when 'CLIENT_NO_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NO_REFERRAL,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCREENED_SRVCS,
	max(case sq.pseudonym when 'CLIENT_TALKED_0_WITH_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TALKED_0_WITH_ALT,
	max(case sq.pseudonym when 'CLIENT_TALKED_1_WITH_OTHER_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TALKED_1_WITH_OTHER_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_0_START_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_0_START_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_1_DURATION_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_END_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_1_END_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_FROM_AMPM_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_FROM_HR_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_FROM_MIN_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_TO_AMPM_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_HR_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_TO_HR_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN_ALT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_TO_MIN_ALT,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Alternative Encounter'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[ASQ_3]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [survey_views].[ASQ_3] as

select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_COMM,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_FMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_GMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_PSOLVE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_COMM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_FINE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'ASQ-3'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Client_and_Infant_Health_or_TCM_Medicaid]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Client_and_Infant_Health_or_TCM_Medicaid] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_COMM,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_FMOTOR,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_GMOTOR,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_PSOLVE,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_COMM,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_FINE,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Client and Infant Health or TCM Medicaid'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Client_Funding_Source]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [survey_views].[Client_Funding_Source] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_COM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_PFS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_0_SOURCE_PFS,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_COM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_FORM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_TRIBAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_PFS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_END_PFS,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_COM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_FORM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_TRIBAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_PFS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_FUNDING_1_START_PFS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Client Funding Source'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Clinical_IPV_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Clinical_IPV_Assessment] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST  ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST ,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'IPV_AFRAID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_AFRAID,
max(case sq.pseudonym when 'IPV_CHILD_SAFETY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_CHILD_SAFETY,
max(case sq.pseudonym when 'IPV_CONTROLING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_CONTROLING,
max(case sq.pseudonym when 'IPV_FORCED_SEX ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_FORCED_SEX,
max(case sq.pseudonym when 'IPV_INDICATED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_INDICATED,
max(case sq.pseudonym when 'IPV_INSULTED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_INSULTED,
max(case sq.pseudonym when 'IPV_PHYSICALLY_HURT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_PHYSICALLY_HURT,
max(case sq.pseudonym when 'IPV_PRN_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_PRN_REASON,
max(case sq.pseudonym when 'IPV_Q1_4_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_Q1_4_SCORE,
max(case sq.pseudonym when 'IPV_SCREAMED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_SCREAMED,
max(case sq.pseudonym when 'IPV_THREATENED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_THREATENED,
max(case sq.pseudonym when 'IPV_TOOL_USED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as IPV_TOOL_USED,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Clinical IPV Assessment'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Community_Advisory_Board_Meeting]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Community_Advisory_Board_Meeting]  as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CAB_MTG_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CAB_MTG_DATE


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Community Advisory Board Meeting'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Course_Completion]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Course_Completion]  as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'COURSE_COMPLETION_0_DATE1-11 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [COURSE_COMPLETION_0_DATE1-11],
max(case sq.pseudonym when 'COURSE_COMPLETION_0_NAME1-11 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [COURSE_COMPLETION_0_NAME1-11]


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Course Completion'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[DANCE_Coding_Sheet]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [survey_views].[DANCE_Coding_Sheet]  as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ACTIVITY_DURATION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ACTIVITY_DURATION,
	max(case sq.pseudonym when 'CLIENT_CAC_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_CAC_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAC_NA,
	max(case sq.pseudonym when 'CLIENT_CAC_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAC_PER,
	max(case sq.pseudonym when 'CLIENT_CHILD_AGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHILD_AGE,
	max(case sq.pseudonym when 'CLIENT_CHILD_DURATION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHILD_DURATION,
	max(case sq.pseudonym when 'CLIENT_CI_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CI_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_CI_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CI_NA,
	max(case sq.pseudonym when 'CLIENT_CI_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CI_PER,
	max(case sq.pseudonym when 'CLIENT_EPA_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_EPA_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPA_NA,
	max(case sq.pseudonym when 'CLIENT_EPA_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPA_PER,
	max(case sq.pseudonym when 'CLIENT_LS_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LS_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_LS_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LS_NA,
	max(case sq.pseudonym when 'CLIENT_LS_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LS_PER,
	max(case sq.pseudonym when 'CLIENT_NCCO_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NCCO_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NCCO_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NCCO_NA,
	max(case sq.pseudonym when 'CLIENT_NCCO_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NCCO_PER,
	max(case sq.pseudonym when 'CLIENT_NI_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NI_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NI_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NI_NA,
	max(case sq.pseudonym when 'CLIENT_NI_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NI_PER,
	max(case sq.pseudonym when 'CLIENT_NT_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NT_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NT_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NT_NA,
	max(case sq.pseudonym when 'CLIENT_NT_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NT_PER,
	max(case sq.pseudonym when 'CLIENT_NVC_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NVC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NVC_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NVC_NA,
	max(case sq.pseudonym when 'CLIENT_NVC_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NVC_PER,
	max(case sq.pseudonym when 'CLIENT_PC_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PC_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PC_NA,
	max(case sq.pseudonym when 'CLIENT_PC_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PC_PER,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PO_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PO_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PO_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PO_NA,
	max(case sq.pseudonym when 'CLIENT_PO_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PO_PER,
	max(case sq.pseudonym when 'CLIENT_PRA_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PRA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PRA_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PRA_NA,
	max(case sq.pseudonym when 'CLIENT_PRA_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PRA_PER,
	max(case sq.pseudonym when 'CLIENT_RD_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_RD_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_RD_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_RD_NA,
	max(case sq.pseudonym when 'CLIENT_RD_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_RD_PER,
	max(case sq.pseudonym when 'CLIENT_RP_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_RP_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_RP_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_RP_NA,
	max(case sq.pseudonym when 'CLIENT_RP_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_RP_PER,
	max(case sq.pseudonym when 'CLIENT_SCA_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_SCA_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCA_NA,
	max(case sq.pseudonym when 'CLIENT_SCA_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCA_PER,
	max(case sq.pseudonym when 'CLIENT_SE_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SE_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_SE_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SE_NA,
	max(case sq.pseudonym when 'CLIENT_SE_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SE_PER,
	max(case sq.pseudonym when 'CLIENT_VE_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VE_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VE_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VE_NA,
	max(case sq.pseudonym when 'CLIENT_VE_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VE_PER,
	max(case sq.pseudonym when 'CLIENT_VEC_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VEC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VEC_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VEC_NA,
	max(case sq.pseudonym when 'CLIENT_VEC_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VEC_PER,
	max(case sq.pseudonym when 'CLIENT_VISIT_VARIABLES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VISIT_VARIABLES,
	max(case sq.pseudonym when 'CLIENT_VQ_COMMENTS ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VQ_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VQ_NA ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VQ_NA,
	max(case sq.pseudonym when 'CLIENT_VQ_PER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VQ_PER,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'DANCE Coding Sheet'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Demographics]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [survey_views].[Demographics]  as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'ADULTS_1_CARE_10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_10,
	max(case sq.pseudonym when 'ADULTS_1_CARE_20 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_20,
	max(case sq.pseudonym when 'ADULTS_1_CARE_30 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_30,
	max(case sq.pseudonym when 'ADULTS_1_CARE_40 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_40,
	max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_LESS10,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_COMPLETE_GED,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_COMPLETE_HS,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_COMPLETE_HS_NO,
	max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_ASSOCIATE,
	max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_BACHELOR,
	max(case sq.pseudonym when 'ADULTS_1_ED_MASTER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_MASTER,
	max(case sq.pseudonym when 'ADULTS_1_ED_NONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_NONE,
	max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_POSTGRAD,
	max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_SOME_COLLEGE,
	max(case sq.pseudonym when 'ADULTS_1_ED_TECH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_TECH,
	max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_UNKNOWN,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ENROLL_FT,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ENROLL_NO,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ENROLL_PT,
	max(case sq.pseudonym when 'ADULTS_1_INS_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_INS_NO,
	max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_INS_PRIVATE,
	max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_INS_PUBLIC,
	max(case sq.pseudonym when 'ADULTS_1_WORK_10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_10,
	max(case sq.pseudonym when 'ADULTS_1_WORK_20 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_20,
	max(case sq.pseudonym when 'ADULTS_1_WORK_37 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_37,
	max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_LESS10,
	max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_UNEMPLOY,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ URGENT_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_OTHER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_HOSP,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_OTHER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_PURPOSE,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ED_PROG_TYPE,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_0_HS_GED,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
	max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_0_HH_INCOME,
	max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_1_HH_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
	max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_AMOUNT,
	max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_IN_KIND,
	max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_INKIND_OTHER,
	max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_OTHER_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INSURANCE,
	max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_0_WITH,
	max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_1_WITH_OTHERS,
	max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_HOMELESS,
	max(case sq.pseudonym when 'CLIENT_LIVING_WHERE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_WHERE,
	max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MARITAL_0_STATUS,
	max(case sq.pseudonym when 'CLIENT_MILITARY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MILITARY,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED,
	max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PROVIDE_CHILDCARE,
	max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCHOOL_MIDDLE_HS,
	max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
	max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
	max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Demographics'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Demographics_Update]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Demographics_Update] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'ADULTS_1_CARE_10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_10,
max(case sq.pseudonym when 'ADULTS_1_CARE_20 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_20,
max(case sq.pseudonym when 'ADULTS_1_CARE_30 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_30,
max(case sq.pseudonym when 'ADULTS_1_CARE_40 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_40,
max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_CARE_LESS10,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_COMPLETE_GED,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_COMPLETE_HS,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_COMPLETE_HS_NO,
max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_ASSOCIATE,
max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_BACHELOR,
max(case sq.pseudonym when 'ADULTS_1_ED_MASTER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_MASTER,
max(case sq.pseudonym when 'ADULTS_1_ED_NONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_NONE,
max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_POSTGRAD,
max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_SOME_COLLEGE,
max(case sq.pseudonym when 'ADULTS_1_ED_TECH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_TECH,
max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ED_UNKNOWN,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ENROLL_FT,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ENROLL_NO,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_ENROLL_PT,
max(case sq.pseudonym when 'ADULTS_1_INS_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_INS_NO,
max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_INS_PRIVATE,
max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_INS_PUBLIC,
max(case sq.pseudonym when 'ADULTS_1_WORK_10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_10,
max(case sq.pseudonym when 'ADULTS_1_WORK_20 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_20,
max(case sq.pseudonym when 'ADULTS_1_WORK_37 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_37,
max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_LESS10,
max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as ADULTS_1_WORK_UNEMPLOY,
max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_BC_0_USED_6MONTHS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BC_0_USED_6MONTHS,
max(case sq.pseudonym when 'CLIENT_BC_1_FREQUENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BC_1_FREQUENCY,
max(case sq.pseudonym when 'CLIENT_BC_1_NOT_USED_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BC_1_NOT_USED_REASON,
max(case sq.pseudonym when 'CLIENT_BC_1_TYPES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BC_1_TYPES,
max(case sq.pseudonym when 'CLIENT_BC_1_TYPES_NEXT6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BC_1_TYPES_NEXT6,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_1_TIME_WITH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_BIO_DAD_1_TIME_WITH,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_HOSP,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_ER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CARE_0_URGENT_TIMES,
max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ED_PROG_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_0_HS_GED,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_0_HH_INCOME,
max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_1_HH_SOURCES,
max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_AMOUNT,
max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_IN_KIND,
max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_INKIND_OTHER,
max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES  ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_OTHER_SOURCES ,
max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INCOME_SOURCES,
max(case sq.pseudonym when 'CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INSURANCE,
max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INSURANCE_OTHER,
max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INSURANCE_TYPE,
max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_0_WITH,
max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_1_WITH_OTHERS,
max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_HOMELESS,
max(case sq.pseudonym when 'CLIENT_LIVING_WHERE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LIVING_WHERE,
max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MARITAL_0_STATUS,
max(case sq.pseudonym when 'CLIENT_MILITARY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MILITARY,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PROVIDE_CHILDCARE,
max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCHOOL_MIDDLE_HS,
max(case sq.pseudonym when 'CLIENT_SECOND_0_CHILD_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_0_CHILD_DOB,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_GRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_BW_GRAMS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_MEASURE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_BW_MEASURE,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_OZ ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_BW_OZ,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_BW_POUNDS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_GENDER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_GENDER,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_NICU ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_NICU,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_NICU_DAYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SECOND_1_CHILD_NICU_DAYS,
max(case sq.pseudonym when 'CLIENT_SUBPREG ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG,
max(case sq.pseudonym when 'CLIENT_SUBPREG_0_BEEN_PREGNANT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_0_BEEN_PREGNANT,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_BEGIN_MONTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_1_BEGIN_MONTH,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_BEGIN_YEAR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_1_BEGIN_YEAR,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_EDD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_1_EDD,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_GEST_AGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_1_GEST_AGE,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_OUTCOME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_1_OUTCOME,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_PLANNED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBPREG_1_PLANNED,
max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
max(case sq.pseudonym when 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_1_WORKED_SINCE_BIRTH,
max(case sq.pseudonym when 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Demographics Update'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Edinburgh_Postnatal_Depression_Scale]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Edinburgh_Postnatal_Depression_Scale] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ABLE_TO_LAUGH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_ABLE_TO_LAUGH,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ANXIOUS_WORRIED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_ANXIOUS_WORRIED,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_BEEN_CRYING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_BEEN_CRYING,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_BLAME_SELF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_BLAME_SELF,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_DIFFICULTY_SLEEPING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_DIFFICULTY_SLEEPING,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ENJOY_THINGS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_ENJOY_THINGS,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_HARMING_SELF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_HARMING_SELF,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_SAD_MISERABLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_SAD_MISERABLE,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_SCARED_PANICKY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_SCARED_PANICKY,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_THINGS_GETTING_ON_TOP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPDS_1_THINGS_GETTING_ON_TOP,
	max(case sq.pseudonym when 'CLIENT_EPS_TOTAL_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EPS_TOTAL_SCORE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Edinburgh Postnatal Depression Scale'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Education_Registration]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Education_Registration] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'EDUC_REGISTER_0_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as EDUC_REGISTER_0_REASON

	
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Education Registration'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Education_Registration_V2]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Education_Registration_V2] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'EDUC_REGISTER_0_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as EDUC_REGISTER_0_REASON

	
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Education Registration'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[GAD_7]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[GAD_7] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_GAD7_AFRAID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_AFRAID,
max(case sq.pseudonym when 'CLIENT_GAD7_CTRL_WORRY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_CTRL_WORRY,
max(case sq.pseudonym when 'CLIENT_GAD7_IRRITABLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_IRRITABLE,
max(case sq.pseudonym when 'CLIENT_GAD7_NERVOUS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_NERVOUS,
max(case sq.pseudonym when 'CLIENT_GAD7_PROBS_DIFFICULT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_PROBS_DIFFICULT,
max(case sq.pseudonym when 'CLIENT_GAD7_RESTLESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_RESTLESS,
max(case sq.pseudonym when 'CLIENT_GAD7_TOTAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_TOTAL,
max(case sq.pseudonym when 'CLIENT_GAD7_TRBL_RELAX ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_TRBL_RELAX,
max(case sq.pseudonym when 'CLIENT_GAD7_WORRY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GAD7_WORRY,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

	
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'GAD-7'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Goodwill_Indy_Additional_Referral_Data]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Goodwill_Indy_Additional_Referral_Data] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_DIMISSAL_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_ADDITIONAL_DIMISSAL_REASON,
max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_NOTES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_ADDITIONAL_NOTES,
max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_SOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_ADDITIONAL_SOURCE

	
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Goodwill Indy Additional Referral Data'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Health_Habits]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Health_Habits] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_ALCOHOL_0_14DAY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_ALCOHOL_0_14DAY,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_0_DURING_PREG ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_CIG_0_DURING_PREG,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_1_LAST_48 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_CIG_1_LAST_48,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_1_PRE_PREG ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_CIG_1_PRE_PREG,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_COCAINE_0_14DAY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_COCAINE_0_14DAY,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_NICOTINE_0_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_NICOTINE_0_OTHER,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_OTHER_0_14DAY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_OTHER_0_14DAY,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_POT_0_14DAYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_POT_0_14DAYS,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME_LAST


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Health Habits'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Home_Visit_Encounter]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Home_Visit_Encounter] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ATTENDEES_0_AT_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ATTENDEES_0_AT_VISIT,
	max(case sq.pseudonym when 'CLIENT_ATTENDEES_0_OTHER_VISIT_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ATTENDEES_0_OTHER_VISIT_DESC,
	max(case sq.pseudonym when 'CLIENT_CHILD_DEVELOPMENT_CONCERN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHILD_DEVELOPMENT_CONCERN,
	max(case sq.pseudonym when 'CLIENT_CHILD_INJURY_0_PREVENTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHILD_INJURY_0_PREVENTION,
	max(case sq.pseudonym when 'CLIENT_COMPLETE_0_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLETE_0_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONFLICT_0_CLIENT_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CONFLICT_0_CLIENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONFLICT_1_GRNDMTHR_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CONFLICT_1_GRNDMTHR_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONFLICT_1_PARTNER_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CONFLICT_1_PARTNER_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONT_HLTH_INS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CONT_HLTH_INS,
	max(case sq.pseudonym when 'CLIENT_CONTENT_0_PERCENT_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CONTENT_0_PERCENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_FRNDFAM_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_LIFECOURSE_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_MATERNAL_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSHLTH_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_PERSHLTH_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DOMAIN_0_TOTAL_VISIT,
	max(case sq.pseudonym when 'CLIENT_INVOLVE_0_CLIENT_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INVOLVE_0_CLIENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_INVOLVE_1_GRNDMTHR_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INVOLVE_1_GRNDMTHR_VISIT,
	max(case sq.pseudonym when 'CLIENT_INVOLVE_1_PARTNER_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_INVOLVE_1_PARTNER_VISIT,
	max(case sq.pseudonym when 'CLIENT_IPV_0_SAFETY_PLAN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_0_SAFETY_PLAN,
	max(case sq.pseudonym when 'CLIENT_LOCATION_0_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LOCATION_0_VISIT,
	max(case sq.pseudonym when 'CLIENT_NO_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_NO_REFERRAL,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PLANNED_VISIT_SCH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PLANNED_VISIT_SCH,
	max(case sq.pseudonym when 'CLIENT_PRENATAL_VISITS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PRENATAL_VISITS,
	max(case sq.pseudonym when 'CLIENT_PRENATAL_VISITS_WEEKS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PRENATAL_VISITS_WEEKS,
	max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SCREENED_SRVCS,
	max(case sq.pseudonym when 'CLIENT_TIME_0_START_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_0_START_VISIT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_1_DURATION_VISIT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_END_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_1_END_VISIT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_FROM_AMPM,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_FROM_HR,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_FROM_MIN,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_TO_AMPM,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_HR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_TO_HR,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TIME_TO_MIN,
	max(case sq.pseudonym when 'CLIENT_UNDERSTAND_0_CLIENT_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNDERSTAND_0_CLIENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT,
	max(case sq.pseudonym when 'CLIENT_UNDERSTAND_1_PARTNER_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNDERSTAND_1_PARTNER_VISIT,
	max(case sq.pseudonym when 'CLIENT_VISIT_SCHEDULE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_VISIT_SCHEDULE,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_0_HAD_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_REASON1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_REASON2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_REASON3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHERDT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHERDT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHERDT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_0_HAD_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_R2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_PROVIDER_0_APPT_R2,
	max(case sq.pseudonym when 'NURSE_MILEAGE_0_VIS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_MILEAGE_0_VIS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Home Visit Encounter'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Infant_Birth]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Infant_Birth] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_WEIGHT_0_PREG_GAIN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_WEIGHT_0_PREG_GAIN,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO2,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO3,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_ER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_0_CLIENT_ER,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_ER_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_0_CLIENT_ER_TIMES,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_URGENT CARE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [INFANT_BIRTH_0_CLIENT_URGENT CARE],
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES],
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_0_DOB,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_0_DOB2,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_0_DOB3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_DELIVERY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_DELIVERY,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_GEST_AGE,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_GEST_AGE2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_GEST_AGE3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_HEARING_SCREEN,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_HEARING_SCREEN2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_HEARING_SCREEN3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_LABOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_LABOR,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_MULTIPLE_BIRTHS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_MULTIPLE_BIRTHS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_DAYS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_DAYS_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_DAYS_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_DAYS_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_DAYS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_DAYS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NICU3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NURSERY_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NURSERY_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_NURSERY_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_COSLEEP,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_COSLEEP2,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_COSLEEP3,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_READ,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_READ2,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_READ3,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BACK,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BACK2,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BACK3,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BEDDING,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BEDDING2,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BEDDING3,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_0_EVER_BIRTH,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_0_EVER_BIRTH2,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_0_EVER_BIRTH3,
	max(case sq.pseudonym when 'INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_OTHER2,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_OTHER3,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_TYPE2,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_TYPE3,
	max(case sq.pseudonym when 'INFANT_INSURANCE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE2,
	max(case sq.pseudonym when 'INFANT_INSURANCE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE3,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_ETHNICITY,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_ETHNICITY2,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_ETHNICITY3,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [INFANT_PERSONAL_0_FIRST NAME],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [INFANT_PERSONAL_0_FIRST NAME2],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [INFANT_PERSONAL_0_FIRST NAME3],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_GENDER,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_GENDER2,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_GENDER3,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_LAST NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [INFANT_PERSONAL_0_LAST NAME],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_RACE,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_RACE2,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_RACE3,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Infant Birth'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Infant_Health_Care]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Infant_Health_Care] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_0_VERSION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_0_VERSION,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_COMM,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_FMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_GMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_1_PSOLVE,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_SE_0_EMOTIONAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_SE_0_EMOTIONAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_SE_VERSION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_AGES_STAGES_SE_VERSION,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_0_DOB,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_COSLEEP,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_READ,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BACK,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BIRTH_SLEEP_BEDDING,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_IHC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_0_EVER_IHC,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_AGE_STOP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_1_AGE_STOP,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_CONT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_1_CONT,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_EXCLUSIVE_WKS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_1_EXCLUSIVE_WKS,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_WEEK_STOP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_BREASTMILK_1_WEEK_STOP,
	max(case sq.pseudonym when 'INFANT_HEALTH_DENTAL_SOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_DENTAL_SOURCE,
	max(case sq.pseudonym when 'INFANT_HEALTH_DENTIST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_DENTIST,
	max(case sq.pseudonym when 'INFANT_HEALTH_DENTIST_STILL_EBF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_DENTIST_STILL_EBF,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_0_HAD_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_INJ_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_REASON1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_REASON2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHER_REASON3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHERDT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHERDT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_OTHERDT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_ER_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEAD_0_CIRC_INCHES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HEAD_0_CIRC_INCHES,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEAD_1_REPORT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HEAD_1_REPORT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_0_INCHES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HEIGHT_0_INCHES,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_1_PERCENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HEIGHT_1_PERCENT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_1_REPORT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HEIGHT_1_REPORT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_0_HAD_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_HOSP_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_0_UPDATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_IMMUNIZ_0_UPDATE,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_1_RECORD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_IMMUNIZ_1_RECORD,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_UPDATE_NO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_IMMUNIZ_UPDATE_NO,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_UPDATE_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_IMMUNIZ_UPDATE_YES,
	max(case sq.pseudonym when 'INFANT_HEALTH_LEAD_0_TEST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_LEAD_0_TEST,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_COMM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_FINE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_TOTAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_NO_ASQ_TOTAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_PROVIDER_0_APPT,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_R2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_PROVIDER_0_APPT_R2,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_PRIMARY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_PROVIDER_0_PRIMARY,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_0_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_OUNCES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_WEIGHT_1_OUNCES,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_OZ ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_WEIGHT_1_OZ,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_PERCENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_WEIGHT_1_PERCENT,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_REPORT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HEALTH_WEIGHT_1_REPORT,
	max(case sq.pseudonym when 'INFANT_HOME_0_TOTAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_0_TOTAL,
	max(case sq.pseudonym when 'INFANT_HOME_1_ACCEPTANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_1_ACCEPTANCE,
	max(case sq.pseudonym when 'INFANT_HOME_1_EXPERIENCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_1_EXPERIENCE,
	max(case sq.pseudonym when 'INFANT_HOME_1_INVOLVEMENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_1_INVOLVEMENT,
	max(case sq.pseudonym when 'INFANT_HOME_1_LEARNING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_1_LEARNING,
	max(case sq.pseudonym when 'INFANT_HOME_1_ORGANIZATION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_1_ORGANIZATION,
	max(case sq.pseudonym when 'INFANT_HOME_1_RESPONSIVITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_HOME_1_RESPONSIVITY,
	max(case sq.pseudonym when 'INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_SSN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_SSN,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_0_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_0_REFERRAL,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON3,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REASON1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON1_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REASON1_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REASON2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON2_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REASON2_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REASON3,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON3_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REASON3_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE3,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Infant Health Care'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Joint_Visit_Observation]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Joint_Visit_Observation] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NURSE_JVSCALE_GUIDE_0_LINES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_GUIDE_0_LINES,
max(case sq.pseudonym when 'NURSE_JVSCALE_GUIDE_1_LINES_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_GUIDE_1_LINES_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_MOTIV_1_INTERVIEW ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_MOTIV_1_INTERVIEW,
max(case sq.pseudonym when 'NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_PC_0_INTERVENTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_PC_0_INTERVENTION,
max(case sq.pseudonym when 'NURSE_JVSCALE_PC_1_INTERVENTION_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_PC_1_INTERVENTION_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_SELF_0_EFFICACY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_SELF_0_EFFICACY,
max(case sq.pseudonym when 'NURSE_JVSCALE_SELF_1_EFFICACY_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_SELF_1_EFFICACY_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_THERAPEUTIC_0_CHAR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_THERAPEUTIC_0_CHAR,
max(case sq.pseudonym when 'NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Joint Visit Observation'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Joint_Visit_Observation_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Joint_Visit_Observation_Form] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'JVO_ADDITIONAL_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_ADDITIONAL_REASON,
max(case sq.pseudonym when 'JVO_CLIENT_CASE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_CLIENT_CASE,
max(case sq.pseudonym when 'JVO_CLIENT_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_CLIENT_NAME,
max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_CLINICAL_CHART_CONSISTENT,
max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT_COMMENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_CLINICAL_CHART_CONSISTENT_COMMENTS,
max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_HVEF_CONSISTENT,
max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT_COMMENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_HVEF_CONSISTENT_COMMENTS,
max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_COMMENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_MI_CLIENT_PRIN_COMMENTS,
max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_MI_CLIENT_PRIN_SCORE,
max(case sq.pseudonym when 'JVO_OBSERVER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_OBSERVER_NAME,
max(case sq.pseudonym when 'JVO_OBSERVER_NAME_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_OBSERVER_NAME_OTHER,
max(case sq.pseudonym when 'JVO_OTHER_OBSERVATIONS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_OTHER_OBSERVATIONS,
max(case sq.pseudonym when 'JVO_PARENT_CHILD_COMMENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_PARENT_CHILD_COMMENTS,
max(case sq.pseudonym when 'JVO_PARENT_CHILD_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_PARENT_CHILD_SCORE,
max(case sq.pseudonym when 'JVO_START_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_START_TIME,
max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_COMMENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_THERAPEUTIC_CHAR_COMMENTS,
max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_THERAPEUTIC_CHAR_SCORE,
max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_COMMENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_VISIT_STRUCTURE_COMMENTS,
max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as JVO_VISIT_STRUCTURE_SCORE
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Joint Visit Observation Form'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Maternal_Health_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Maternal_Health_Assessment] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_CANT_SOLVE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_ADDICTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_ADDICTION,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS2,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_OTHER,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_EDD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_EDD,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Maternal Health Assessment'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_12_Month_Infant]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_12_Month_Infant] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,

	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_ASQ3_12MOS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQ3_12MOS,
max(case sq.pseudonym when 'MN_ASQ3_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQ3_REFERRAL,
max(case sq.pseudonym when 'MN_ASQSE_12MOS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQSE_12MOS,
max(case sq.pseudonym when 'MN_ASQSE_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQSE_REFERRAL,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_CPA_FILE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_FURTHER_SCREEN_ASQ3,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_FURTHER_SCREEN_ASQSE,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_NCAST_CAREGIVER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_CAREGIVER,
max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_CLARITY_CUES,
max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_COGN_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_DISTRESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_DISTRESS,
max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_SE_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_SENS_CUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_SENS_CUES,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME



   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN 12 Month Infant'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_18_Months_Toddler]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_18_Months_Toddler] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,

max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN 18 Months Toddler'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_24_Month_Toddler]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_24_Month_Toddler] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN 24 Month Toddler'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_6_Months_Infant]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_6_Months_Infant] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_ASQ3_4MOS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQ3_4MOS,
max(case sq.pseudonym when 'MN_ASQ3_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQ3_REFERRAL,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_CPA_FILE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_FOLIC_ACID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_FOLIC_ACID,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_FURTHER_SCREEN_ASQ3,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_NCAST_CAREGIVER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_CAREGIVER,
max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_CLARITY_CUES,
max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_COGN_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_DISTRESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_DISTRESS,
max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_SE_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_SENS_CUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_SENS_CUES,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN 6 Months Infant'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_Child_Intake]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_Child_Intake] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN Child Intake'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_Primary_Caregiver_Closure]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_Primary_Caregiver_Closure]
 as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'MN_CPA_FILE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN Primary Caregiver Closure'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[MN_Primary_Caregiver_Intake]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_Primary_Caregiver_Intake]
 as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_HOUSEHOLD_SIZE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_HOUSEHOLD_SIZE,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_WKS_PREGNANT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_WKS_PREGNANT,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN Primary Caregiver Intake'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[New_Hire_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[New_Hire_Form] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_ACCESS_LEVEL,
max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_EDUC_COMPLETED,
max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_0_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_FTE,
max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_HIRE_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_NAME_LAST,
max(case sq.pseudonym when 'NEW_HIRE_0_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_START_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_TEAM_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_DOB,
max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_NAME_FIRST,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_CITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_CITY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE1,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE2,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_STATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_STATE,
max(case sq.pseudonym when 'NEW_HIRE_1_REPLACE_STAFF_TERM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_REPLACE_STAFF_TERM,
max(case sq.pseudonym when 'NEW_HIRE_1_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_ROLE,
max(case sq.pseudonym when 'NEW_HIRE_ADDITIONAL_INFO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDITIONAL_INFO,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_0_ZIP,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_CITY,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STATE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE_OTHR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STATE_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STREET,
max(case sq.pseudonym when 'NEW_HIRE_ER_0_LNAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ER_0_LNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_FNAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ER_1_FNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ER_1_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_NAME,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME_OTHR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_NAME_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_PHONE

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'New Hire Form'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[New_Hire_V2]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[New_Hire_V2] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_ACCESS_LEVEL,
max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_EDUC_COMPLETED,
max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_0_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_FTE,
max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_HIRE_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_NAME_LAST,
max(case sq.pseudonym when 'NEW_HIRE_0_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_START_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_TEAM_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_DOB,
max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_NAME_FIRST,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_CITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_CITY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE1,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE2,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_STATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_PREVIOUS_WORK_STATE,
max(case sq.pseudonym when 'NEW_HIRE_1_REPLACE_STAFF_TERM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_REPLACE_STAFF_TERM,
max(case sq.pseudonym when 'NEW_HIRE_1_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_ROLE,
max(case sq.pseudonym when 'NEW_HIRE_ADDITIONAL_INFO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDITIONAL_INFO,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_0_ZIP,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_CITY,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STATE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE_OTHR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STATE_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STREET,
max(case sq.pseudonym when 'NEW_HIRE_ER_0_LNAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ER_0_LNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_FNAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ER_1_FNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ER_1_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_NAME,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME_OTHR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_NAME_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_PHONE

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'New Hire V2'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[NFP_Los_Angeles__Outreach_Marketing]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[NFP_Los_Angeles__Outreach_Marketing] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'LA_CTY_CONTACT_NAME_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CONTACT_NAME_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_CONTACT_PHONE_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CONTACT_PHONE_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_NOTES_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_NOTES_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_ORG_NAME_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ORG_NAME_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OTH_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ORG_TYPE_OTH_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ORG_TYPE_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_STAFF_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF2_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_STAFF2_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF3_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_STAFF3_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF4_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_STAFF4_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF5_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_STAFF5_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_OUTREACH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_OUTREACH


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'NFP Los Angeles - Outreach/Marketing'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[NFP_Tribal_Project]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[NFP_Tribal_Project] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_TRIBAL_0_PARITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_0_PARITY,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_1_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_1_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_1_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_1_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_10_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_10_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_10_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_10_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_2_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_2_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_2_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_2_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_3_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_3_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_3_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_3_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_4_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_4_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_4_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_4_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_5_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_5_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_5_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_5_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_6_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_6_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_6_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_6_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_7_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_7_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_7_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_7_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_8_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_8_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_8_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_8_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_9_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_9_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_9_LIVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TRIBAL_CHILD_9_LIVING,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'NFP Tribal Project'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Nurse_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Nurse_Assessment] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_0_USES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [NURSE_ASSESS_ DATA_0_USES],
max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_1_USES_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [NURSE_ASSESS_ DATA_1_USES_CMT],
max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_0_UTILIZES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_6DOMAINS_0_UTILIZES,
max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE,
max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC,
max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_CARE_0_SELF,
max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_CARE_0_SELF_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS,
max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM,
max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_CULTURE_0_IMPACT,
max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_CULTURE_0_IMPACT_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY,
max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES,
max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING,
max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS,
max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES,
max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME,
max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC,
max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_REFLECTION_0_SELF,
max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_REFLECTION_0_SELF_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION,
max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC,
max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE,
max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD,
max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES,
max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS,
max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Nurse Assessment'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[PHQ_9]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[PHQ_9] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PHQ9_0_TOTAL_SCORE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_0_TOTAL_SCORE,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_CONCENTRATION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_CONCENTRATION,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_DIFFICULTY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_DIFFICULTY,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_BAD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_FEEL_BAD,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_DEPRESSED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_FEEL_DEPRESSED,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_TIRED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_FEEL_TIRED,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_HURT_SELF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_HURT_SELF,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_LITTLE_INTEREST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_LITTLE_INTEREST,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_MOVE_SPEAK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_MOVE_SPEAK,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_EAT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_TROUBLE_EAT,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_SLEEP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PHQ9_1_TROUBLE_SLEEP,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'PHQ-9'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Profile_Of_Program_Staff_UPDATE]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Profile_Of_Program_Staff_UPDATE] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NURSE_EDUCATION_0_NURSING_DEGREES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_EDUCATION_0_NURSING_DEGREES,
max(case sq.pseudonym when 'NURSE_EDUCATION_1_OTHER_DEGREES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_EDUCATION_1_OTHER_DEGREES,
max(case sq.pseudonym when 'NURSE_PRIMARY_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PRIMARY_ROLE,
max(case sq.pseudonym when 'NURSE_PRIMARY_ROLE_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PRIMARY_ROLE_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_NEW_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_NEW_ROLE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_OTHER_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_OTHER_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_SUPERVISOR_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_SUPERVISOR_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_TOTAL_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_TOTAL_FTE,
max(case sq.pseudonym when 'NURSE_SECONDARY_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SECONDARY_ROLE,
max(case sq.pseudonym when 'NURSE_SECONDARY_ROLE_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SECONDARY_ROLE_FTE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_LEAVE_END ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_LEAVE_END,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_LEAVE_START ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_LEAVE_START,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_SPECIFIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_SPECIFIC,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_START_DATE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_TERMINATE_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_TERMINATE_DATE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_TRANSFER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_TRANSFER,
max(case sq.pseudonym when 'NURSE_STATUS_TERM_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_TERM_REASON,
max(case sq.pseudonym when 'NURSE_STATUS_TERM_REASON_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_TERM_REASON_OTHER,
max(case sq.pseudonym when 'NURSE_TEAM_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_TEAM_NAME,
max(case sq.pseudonym when 'NURSE_TEAM_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_TEAM_START_DATE

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Profile Of Program Staff-UPDATE'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Record_of_Team_Meetings_and_Case_Conferences]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Record_of_Team_Meetings_and_Case_Conferences] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'AGENCY_MEETING_0_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_0_TYPE,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF7 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF8 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF9 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF11 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF11,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF12 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF12,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF13 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF13,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF14 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF14,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF15 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF15,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF16 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF16,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF17 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF17,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF18 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF18,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF19 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF19,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF20 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF20,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF21 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF21,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF22 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF22,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF23 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF23,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF24 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF24,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF25 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF25,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF7 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF8 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF9 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_LENGTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_LENGTH

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Record of Team Meetings and Case Conferences'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Referrals_To_NFP_Program]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Referrals_To_NFP_Program] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_FOLLOWUP_NURSE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_0_FOLLOWUP_NURSE,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_MARKETING_SOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_0_MARKETING_SOURCE,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_NOTES ' then coalesce(survey_views.f_replace_chars(fr.text_response),cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_0_NOTES,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_SOURCE_CODE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_0_SOURCE_CODE,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_WAIT_LIST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_0_WAIT_LIST,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_0_NAME_LAST,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_CELL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_CELL,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_DOB,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_EDD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_EDD,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_EMAIL,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_NAME_FIRST,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_PHONE_HOME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_PHONE_HOME,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_PLANG ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_PLANG,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_STREET ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_STREET,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_STREET2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_STREET2,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_WORK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_WORK,
	max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_ZIP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_PROSPECT_DEMO_1_ZIP,
	max(case sq.pseudonym when 'REFERRAL_SOURCE_PRIMARY_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_SOURCE_PRIMARY_0_NAME,
	max(case sq.pseudonym when 'REFERRAL_SOURCE_PRIMARY_1_LOCATION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_SOURCE_PRIMARY_1_LOCATION,
	max(case sq.pseudonym when 'REFERRAL_SOURCE_SECONDARY_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_SOURCE_SECONDARY_0_NAME,
	max(case sq.pseudonym when 'REFERRAL_SOURCE_SECONDARY_1_LOCATION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as REFERRAL_SOURCE_SECONDARY_1_LOCATION

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Referrals To NFP Program'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Relationship_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Relationship_Assessment] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ABUSE_AFRAID_0_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_AFRAID_0_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_FORCED_0_SEX ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_FORCED_0_SEX,
	max(case sq.pseudonym when 'CLIENT_ABUSE_FORCED_1_SEX_LAST_YR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_FORCED_1_SEX_LAST_YR,
	max(case sq.pseudonym when 'CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME,
	max(case sq.pseudonym when 'CLIENT_ABUSE_HIT_0_SLAP_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_HIT_0_SLAP_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HURT_LAST_YR ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_HURT_LAST_YR,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME



   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Relationship Assessment'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Staff_Team_to_Team_Transfer_Request]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Staff_Team_to_Team_Transfer_Request] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'STAFF_XFER_CLIENTS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_CLIENTS,
max(case sq.pseudonym when 'STAFF_XFER_FROM_TEAM_A ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_FROM_TEAM_A,
max(case sq.pseudonym when 'STAFF_XFER_LAST_DAY_TEAM_A ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_LAST_DAY_TEAM_A,
max(case sq.pseudonym when 'STAFF_XFER_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_NAME,
max(case sq.pseudonym when 'STAFF_XFER_NEW_TEAM_B ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_NEW_TEAM_B,
max(case sq.pseudonym when 'STAFF_XFER_PRIMARY_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_PRIMARY_FTE,
max(case sq.pseudonym when 'STAFF_XFER_PRIMARY_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_PRIMARY_ROLE,
max(case sq.pseudonym when 'STAFF_XFER_SECOND_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_SECOND_FTE,
max(case sq.pseudonym when 'STAFF_XFER_SECOND_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_SECOND_ROLE,
max(case sq.pseudonym when 'STAFF_XFER_START_DATE_TEAM_B ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_START_DATE_TEAM_B,
max(case sq.pseudonym when 'STAFF_XFER_SUP_PROMO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as STAFF_XFER_SUP_PROMO


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Staff Team-to-Team Transfer Request'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[STAR_Framework]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[STAR_Framework] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'Client_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as Client_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_DISABILITY_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_DISABILITY_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_DISABILITY_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_DISABILITY_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_DISABILITY_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_EDUC_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_EDUC_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_EDUC_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_EDUC_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_EDUC_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ENGLIT_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ENGLIT_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ENGLIT_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ENGLIT_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ENGLIT_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_GLOBAL_FACTORS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GLOBAL_FACTORS,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_HOMELESS_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HOMELESS_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HOMELESS_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HOMELESS_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HOMELESS_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_IPV_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_IPV_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_IPV_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_IPV_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_IPV_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_LONELY_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_LONELY_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_LONELY_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_LONELY_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_LONELY_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'STAR Framework'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Supplemental_Discharge_Information]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Supplemental_Discharge_Information] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'Client_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as Client_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CAREGIVING_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_CARE_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CHLD_WELL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMM_SVCS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_CRIMINAL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_DISABILITY_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_DISABILITY_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_DISABILITY_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_DISABILITY_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_DISABILITY_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_DISABILITY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ECONOMIC_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_EDUC_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_EDUC_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_EDUC_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_EDUC_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_EDUC_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_EDUC_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ENGLIT_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ENGLIT_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ENGLIT_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ENGLIT_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ENGLIT_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENGLIT_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_GLOBAL_FACTORS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_GLOBAL_FACTORS,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HLTH_SVCS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOME_SAFETY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_HOMELESS_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HOMELESS_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HOMELESS_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HOMELESS_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HOMELESS_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HOMELESS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_IPV_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_IPV_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_IPV_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_IPV_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_IPV_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_IPV_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_LONELY_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_LONELY_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_LONELY_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_LONELY_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_LONELY_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_LONELY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PREGPLAN_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_SUBSTANCE_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_FRIENDS_FAM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_RISK_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_SERVICES_GOALS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_STAGE_CHANGE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Supplemental Discharge Information'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[TCM_Finance_Log]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[TCM_Finance_Log] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'LA_CTY_CASE_MGR_ID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CASE_MGR_ID,
max(case sq.pseudonym when 'LA_CTY_COMPONENT_CODE_FINANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_COMPONENT_CODE_FINANCE,
max(case sq.pseudonym when 'LA_CTY_CONSENT_FINANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CONSENT_FINANCE,
max(case sq.pseudonym when 'LA_CTY_DEMOGRAPHIC_FINANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_DEMOGRAPHIC_FINANCE,
max(case sq.pseudonym when 'LA_CTY_ENCOUNTER_FINANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ENCOUNTER_FINANCE,
max(case sq.pseudonym when 'LA_CTY_LOCATION_FINANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_LOCATION_FINANCE,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MEDI_CAL,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL_STATUS_FINANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MEDI_CAL_STATUS_FINANCE,
max(case sq.pseudonym when 'LA_CTY_NPI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_NPI,
max(case sq.pseudonym when 'LA_CTY_PROG_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PROG_NAME,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME
   
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'TCM Finance Log'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[TCM_ISP]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[TCM_ISP] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'LA_CTY_AGENCY_ADDRESS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AGENCY_ADDRESS_ISP,
max(case sq.pseudonym when 'LA_CTY_AGENCY_NAME_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AGENCY_NAME_ISP,
max(case sq.pseudonym when 'LA_CTY_AGENCY_PH_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AGENCY_PH_ISP,
max(case sq.pseudonym when 'LA_CTY_AREAS_ASSESD_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AREAS_ASSESD_ISP,
max(case sq.pseudonym when 'LA_CTY_CASE_MGR_ID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CASE_MGR_ID,
max(case sq.pseudonym when 'LA_CTY_CLI_AGREE_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CLI_AGREE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_CLI_AGREE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CLI_AGREE_ISP,
max(case sq.pseudonym when 'LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_COMM_LIV_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_COMM_LIV_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_ENVIRON_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ENVIRON_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_FREQ_DUR_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_FREQ_DUR_ISP,
max(case sq.pseudonym when 'LA_CTY_FU_PREV_REF_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_FU_PREV_REF_ISP,
max(case sq.pseudonym when 'LA_CTY_GOAL_NOT_MET_REASON_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_GOAL_NOT_MET_REASON_ISP,
max(case sq.pseudonym when 'LA_CTY_LOC_SEC_DOC_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_LOC_SEC_DOC_ISP,
max(case sq.pseudonym when 'LA_CTY_MED_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MED_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_MED_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MED_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MEDI_CAL,
max(case sq.pseudonym when 'LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_MENTAL_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MENTAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_NPI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_NPI,
max(case sq.pseudonym when 'LA_CTY_PHN_SIG_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHN_SIG_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_PHN_SIG_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHN_SIG_ISP,
max(case sq.pseudonym when 'LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_PHYSICAL_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHYSICAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_PREV_REF_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PREV_REF_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_PROG_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PROG_NAME,
max(case sq.pseudonym when 'LA_CTY_REF_FU_COMPLETE_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_REF_FU_COMPLETE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_REF_FU_DUE_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_REF_FU_DUE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_REF_FU_OUTCOME_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_REF_FU_OUTCOME_ISP,
max(case sq.pseudonym when 'LA_CTY_SIG_INTERVAL_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SIG_INTERVAL_ISP,
max(case sq.pseudonym when 'LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_SOCIAL_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SOCIAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_SRVC_COMP_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SRVC_COMP_ISP,
max(case sq.pseudonym when 'LA_CTY_SRVC_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SRVC_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_SUP_SIG_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SUP_SIG_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_SUP_SIG_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SUP_SIG_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_RISK_21_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_RISK_21_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_RISK_NEG_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_RISK_NEG_ISP,
max(case sq.pseudonym when 'LA_CTY_VISIT_LOCATION_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_VISIT_LOCATION_ISP,
max(case sq.pseudonym when 'LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_VOC_ED_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_VOC_ED_NEEDS_ISP,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME   


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'TCM ISP'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Telehealth_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Telehealth_Form] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_REASON,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_REASON_OTHER,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_TYPE,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_TYPE_OTHER,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Telehealth Form'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Telehealth_Pilot_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Telehealth_Pilot_Form] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_REASON,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_REASON_OTHER,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_TYPE,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_TELEHEALTH_TYPE_OTHER,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Telehealth Pilot Form'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[TEST_CASE_ASSESSMENT]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[TEST_CASE_ASSESSMENT] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
	max(case sq.pseudonym when 'NFP_NSP_6000 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NFP_NSP_6000

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'TEST CASE ASSESSMENT'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[TX_THV_Supplemental_Data_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[TX_THV_Supplemental_Data_Form] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MIECHV_BIRTH_SPACING_SIX_MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_BIRTH_SPACING_SIX_MO_PP,
max(case sq.pseudonym when 'MIECHV_BIRTH_SPACING_THIRD_TRI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_BIRTH_SPACING_THIRD_TRI,
max(case sq.pseudonym when 'MIECHV_INTAKE_COMM_REF ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_INTAKE_COMM_REF,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_12_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_12_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_12_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_12_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_13_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_13_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_13_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_13_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_14_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_14_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_14_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_14_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_15_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_15_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_15_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_15_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_16_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_16_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_16_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CHILD_DEV_16_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CONCRETE_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CONCRETE_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CONCRETE_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_CONCRETE_INTAKE,
max(case sq.pseudonym when 'MIECHV_PFS_FAMILY_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_FAMILY_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_FAMILY_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_FAMILY_INTAKE,
max(case sq.pseudonym when 'MIECHV_PFS_NURTURE_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_NURTURE_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_NURTURE_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_NURTURE_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_SOCIAL_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_SOCIAL_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_SOCIAL_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_PFS_SOCIAL_INTAKE,
max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_12MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_12MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_12MO_PP_3,
max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_2MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_2MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_2MO_PP_3,
max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_IID_12MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_IID_12MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_IID_12MO_PP_3,
max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_IID_2MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_IID_2MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_READ_IID_2MO_PP_3,
max(case sq.pseudonym when 'MIECHV_SUPPORTED_BY_INCOME_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_SUPPORTED_BY_INCOME_12MO_PP,
max(case sq.pseudonym when 'MIECHV_SUPPORTED_BY_INCOME_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MIECHV_SUPPORTED_BY_INCOME_INTAKE,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_12MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as TX_FUNDING_SOURCE_12MO_PP,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_2MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as TX_FUNDING_SOURCE_2MO_PP,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_6MO_PP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as TX_FUNDING_SOURCE_6MO_PP,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as TX_FUNDING_SOURCE_INTAKE,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_THIRD_TRI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as TX_FUNDING_SOURCE_THIRD_TRI

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'TX_THV Supplemental Data Form'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Unknown]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Unknown] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
	max(case sq.pseudonym when 'GHP_Client_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Client_DOB,
max(case sq.pseudonym when 'GHP_Client_FName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Client_FName,
max(case sq.pseudonym when 'GHP_Client_LName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Client_LName,
max(case sq.pseudonym when 'GHP_Client_PlanEnd ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Client_PlanEnd,
max(case sq.pseudonym when 'GHP_Client_PlanStart ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Client_PlanStart,
max(case sq.pseudonym when 'GHP_Infant_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Infant_DOB,
max(case sq.pseudonym when 'GHP_Infant_FName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Infant_FName,
max(case sq.pseudonym when 'GHP_Infant_LName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Infant_LName,
max(case sq.pseudonym when 'GHP_Infant_PlanEnd ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Infant_PlanEnd,
max(case sq.pseudonym when 'GHP_Infant_PlanStart ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as GHP_Infant_PlanStart,
max(case sq.pseudonym when 'HSH_Client_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Client_DOB,
max(case sq.pseudonym when 'HSH_Client_FName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Client_FName,
max(case sq.pseudonym when 'HSH_Client_LName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Client_LName,
max(case sq.pseudonym when 'HSH_Client_PlanEnd ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Client_PlanEnd,
max(case sq.pseudonym when 'HSH_Client_PlanStart  ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Client_PlanStart ,
max(case sq.pseudonym when 'HSH_Infant_DOB ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Infant_DOB,
max(case sq.pseudonym when 'HSH_Infant_FName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Infant_FName,
max(case sq.pseudonym when 'HSH_Infant_LName ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Infant_LName,
max(case sq.pseudonym when 'HSH_Infant_PlanEnd ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Infant_PlanEnd,
max(case sq.pseudonym when 'HSH_Infant_PlanStart ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as HSH_Infant_PlanStart,
max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_ACCESS_LEVEL,
max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_EDUC_COMPLETED,
max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_0_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_FTE,
max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_HIRE_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_NAME_LAST,
max(case sq.pseudonym when 'NEW_HIRE_0_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_START_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_0_TEAM_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_NAME_FIRST,
max(case sq.pseudonym when 'NEW_HIRE_1_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_1_ROLE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_0_ZIP,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_CITY,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STATE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_ADDRESS_1_STREET,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_NAME,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NEW_HIRE_SUP_0_PHONE

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Unknown'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Use_Of_Government_and_Community_Services]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Use_Of_Government_and_Community_Services] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'JP error - if no data associated delete element ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [JP error - if no data associated delete element],
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'SERVICE_USE_0_ADOPTION_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_ADOPTION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHARITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHARITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_CARE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_CARE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_OTHER1,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_OTHER2,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_OTHER3,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_SUPPORT_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_SUPPORT_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CPS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CPS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DENTAL_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DENTAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DRUG_ABUSE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DRUG_ABUSE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_FOODSTAMP_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_FOODSTAMP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_GED_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_GED_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_HIGHER_EDUC_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_HIGHER_EDUC_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_HOUSING_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_HOUSING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_INTERVENTION,
	max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION_45DAYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_INTERVENTION_45DAYS,
	max(case sq.pseudonym when 'SERVICE_USE_0_IPV_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_IPV_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_JOB_TRAINING_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_JOB_TRAINING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_LACTATION_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_LACTATION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_LEGAL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_LEGAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_MEDICAID_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_MEDICAID_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_MENTAL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_MENTAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER1,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER1_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER2,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER2_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER3,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER3_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_PATERNITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PATERNITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_SICK_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_SICK_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_WELL_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_WELL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PREVENT_INJURY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PREVENT_INJURY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SCHIP_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SCHIP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SMOKE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SMOKE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SOCIAL_SECURITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SOCIAL_SECURITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_TANF_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_TANF_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_TRANSPORTATION_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_TRANSPORTATION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_UNEMPLOYMENT_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_UNEMPLOYMENT_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_WIC_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_WIC_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_INDIAN_HEALTH_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_INDIAN_HEALTH_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_MILITARY_INS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CLIENT  ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_MILITARY_INS_CLIENT ,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_POSTPARTUM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_PCP_CLIENT_POSTPARTUM,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_PRENATAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_PCP_CLIENT_PRENATAL,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_WELLWOMAN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_PCP_CLIENT_WELLWOMAN

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Use Of Government & Community Services'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[WA_MIECHV_Supplemental_HVEF]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[WA_MIECHV_Supplemental_HVEF] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
max(case sq.pseudonym when 'CLIENT_O_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_O_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_O_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_O_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_O_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_O_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_O_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_O_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'WA_HVEF_SUPPLEMENT_DELAYED_PREG ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as WA_HVEF_SUPPLEMENT_DELAYED_PREG,
max(case sq.pseudonym when 'WA_HVEF_SUPPLEMENT_IPV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as WA_HVEF_SUPPLEMENT_IPV
   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'WA MIECHV Supplemental HVEF'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  View [survey_views].[Weekly_Supervision_Record]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Weekly_Supervision_Record] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_ENGEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'NURSE_SUPERVISION_0_MIN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SUPERVISION_0_MIN,
max(case sq.pseudonym when 'NURSE_SUPERVISION_0_STAFF_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SUPERVISION_0_STAFF_OTHER,
max(case sq.pseudonym when 'NURSE_SUPERVISION_0_STAFF_SUP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SUPERVISION_0_STAFF_SUP


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Weekly Supervision Record'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Agency_Profile_Update]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Agency_Profile_Update] as  begin  select * from survey_views.Agency_Profile_Update end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Alternative_Encounter]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Alternative_Encounter]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as 
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID] -- col name
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_TIME_0_START_ALT]
      ,s.[CLIENT_TIME_1_END_ALT]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_TALKED_0_WITH_ALT]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_TALKED_1_WITH_OTHER_ALT]) as [CLIENT_TALKED_1_WITH_OTHER_ALT]
      ,s.[CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT]) as [CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT]
      ,s.[CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT]
      ,s.[CLIENT_DOMAIN_0_ENVIRONHLTH_ALT]
      ,s.[CLIENT_DOMAIN_0_LIFECOURSE_ALT]
      ,s.[CLIENT_DOMAIN_0_MATERNAL_ALT]
      ,s.[CLIENT_DOMAIN_0_FRNDFAM_ALT]
      ,s.[CLIENT_DOMAIN_0_TOTAL_ALT]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_ALT_0_COMMENTS_ALT]) as [CLIENT_ALT_0_COMMENTS_ALT]
      ,s.[CLIENT_TIME_1_DURATION_ALT]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      --,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_NO_REFERRAL]
      ,s.[CLIENT_SCREENED_SRVCS]
      --,s.[CLIENT_VISIT_SCHEDULE]
      --,s.[Master_SurveyID]
      --,s.[temp_time_start]
      --,s.[temp_time_end]
      ,s.[CLIENT_TIME_FROM_AMPM_ALT]
      ,s.[CLIENT_TIME_FROM_HR_ALT]
      ,s.[CLIENT_TIME_FROM_MIN_ALT]
      ,s.[CLIENT_TIME_TO_AMPM_ALT]
      ,s.[CLIENT_TIME_TO_HR_ALT]
      ,s.[CLIENT_TIME_TO_MIN_ALT]
      --,s.[Old_CLIENT_TIME_0_START_ALT]
      --,s.[Old_CLIENT_TIME_1_END_ALT]
      --,s.[old_CLIENT_TIME_1_DURATION_ALT]
      --,s.[temp_DURATION]
      --,s.[LastModified]
from survey_views.Alternative_Encounter  s 

where 

s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;






end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_ASQ_3]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_ASQ_3] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      --,s.[DW_AuditDate]
     -- ,s.[DataSource]
      ,s.[INFANT_HEALTH_NO_ASQ_COMM]
      ,s.[INFANT_HEALTH_NO_ASQ_FINE]
      ,s.[INFANT_HEALTH_NO_ASQ_GROSS]
      ,s.[INFANT_HEALTH_NO_ASQ_PERSONAL]
      ,s.[INFANT_HEALTH_NO_ASQ_PROBLEM]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_0_ID_NSO]) as [INFANT_0_ID_NSO]
      --,s.[INFANT_PERSONAL_0_NAME_FIRST]
     --,s.[INFANT_PERSONAL_0_NAME_LAST]
      ,s.[INFANT_AGES_STAGES_1_COMM]
      ,s.[INFANT_AGES_STAGES_1_FMOTOR]
      ,s.[INFANT_AGES_STAGES_1_GMOTOR]
      ,s.[INFANT_AGES_STAGES_1_PSOCIAL]
      ,s.[INFANT_AGES_STAGES_1_PSOLVE]
      --,s.[INFANT_BIRTH_0_DOB]
      ,s.[NURSE_PERSONAL_0_NAME]
     -- ,s.[Master_SurveyID]
from survey_views.ASQ_3  s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Client_and_Infant_Health_or_TCM_Medicaid]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Client_and_Infant_Health_or_TCM_Medicaid] as  begin  select * from survey_views.Client_and_Infant_Health_or_TCM_Medicaid end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Client_Funding_Source]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Client_Funding_Source]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
    --  ,s.[CLIENT_FUNDING_0_SOURCE_OTHER]
     -- ,s.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
     -- ,s.[CLIENT_FUNDING_1_END_OTHER]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
      --,s.[CLIENT_FUNDING_1_START_OTHER]
      ,s.[NURSE_PERSONAL_0_NAME]
     -- ,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER1]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER2]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER3]
      ,s.[CLIENT_FUNDING_1_END_OTHER1]
      ,s.[CLIENT_FUNDING_1_END_OTHER2]
      ,s.[CLIENT_FUNDING_1_END_OTHER3]
      ,s.[CLIENT_FUNDING_1_START_OTHER1]
      ,s.[CLIENT_FUNDING_1_START_OTHER2]
      ,s.[CLIENT_FUNDING_1_START_OTHER3]
      --,s.[Master_SurveyID]
      ,s.[CLIENT_FUNDING_0_SOURCE_PFS]
      ,s.[CLIENT_FUNDING_1_END_PFS]
      ,s.[CLIENT_FUNDING_1_START_PFS]
      --,s.[Archive_Record]					  /*****New Columns Added on 12/19/2016*********/
	  ,s.[CLIENT_FUNDING_0_SOURCE_OTHER4]     /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER5]     /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER6]     /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_END_OTHER4]        /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_END_OTHER5]        /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_END_OTHER6]        /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_START_OTHER4]      /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_START_OTHER5]      /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_START_OTHER6]      /*****New Columns Added on 12/19/2016*********/  
from survey_views.Client_Funding_Source s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;


end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Clinical_IPV_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Clinical_IPV_Assessment] as  begin  select * from survey_views.Clinical_IPV_Assessment end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Community_Advisory_Board_Meeting]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Community_Advisory_Board_Meeting] as  begin  select * from survey_views.Community_Advisory_Board_Meeting end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Course_Completion]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Course_Completion] as  begin  select * from survey_views.Course_Completion end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_DANCE_Coding_Sheet]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_DANCE_Coding_Sheet]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
	
as  
begin  
set nocount on;

select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
     -- ,s.[Master_SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
     -- ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
    --  ,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_CAC_NA]
      ,s.[CLIENT_CI_NA]
      ,s.[CLIENT_EPA_NA]
      ,s.[CLIENT_NCCO_NA]
      ,s.[CLIENT_NI_NA]
      ,s.[CLIENT_NT_NA]
      ,s.[CLIENT_NVC_NA]
      ,s.[CLIENT_PC_NA]
      ,s.[CLIENT_PO_NA]
      ,s.[CLIENT_PRA_NA]
      ,s.[CLIENT_RP_NA]
      ,s.[CLIENT_SCA_NA]
      ,s.[CLIENT_SE_NA]
      ,s.[CLIENT_VE_NA]
      ,s.[CLIENT_VEC_NA]
      ,s.[CLIENT_VISIT_VARIABLES]
      ,s.[CLIENT_LS_NA]
      ,s.[CLIENT_RD_NA]
      ,s.[CLIENT_VQ_NA]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_CAC_COMMENTS] ) as [CLIENT_CAC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_CI_COMMENTS] ) as [CLIENT_CI_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_EPA_COMMENTS] ) as [CLIENT_EPA_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_LS_COMMENTS] ) as [CLIENT_LS_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NCCO_COMMENTS] ) as [CLIENT_NCCO_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NI_COMMENTS] ) as [CLIENT_NI_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NT_COMMENTS] ) as [CLIENT_NT_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NVC_COMMENTS] ) as [CLIENT_NVC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PC_COMMENTS] ) as [CLIENT_PC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PO_COMMENTS] ) as [CLIENT_PO_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PRA_COMMENTS] ) as [CLIENT_PRA_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_RD_COMMENTS] ) as [CLIENT_RD_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_RP_COMMENTS] ) as [CLIENT_RP_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_SCA_COMMENTS] ) as [CLIENT_SCA_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_SE_COMMENTS] ) as [CLIENT_SE_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_VE_COMMENTS] ) as [CLIENT_VE_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_VEC_COMMENTS] ) as [CLIENT_VEC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_VQ_COMMENTS] ) as [CLIENT_VQ_COMMENTS]
	  ,s.[CLIENT_ACTIVITY_DURATION]
      ,s.[CLIENT_CAC_PER]
      ,s.[CLIENT_CHILD_AGE]
      ,s.[CLIENT_CHILD_DURATION]
      ,s.[CLIENT_CI_PER]
      ,s.[CLIENT_EPA_PER]
      ,s.[CLIENT_LS_PER]
      ,s.[CLIENT_NCCO_PER]
      ,s.[CLIENT_NI_PER]
      ,s.[CLIENT_NT_PER]
      ,s.[CLIENT_NVC_PER]
      ,s.[CLIENT_PC_PER]
      ,s.[CLIENT_PO_PER]
      ,s.[CLIENT_PRA_PER]
      ,s.[CLIENT_RD_PER]
      ,s.[CLIENT_RP_PER]
      ,s.[CLIENT_SCA_PER]
      ,s.[CLIENT_SE_PER]
      ,s.[CLIENT_VE_PER]
      ,s.[CLIENT_VEC_PER]
      ,s.[CLIENT_VQ_PER]
      ,s.[NURSE_PERSONAL_0_NAME]   
from survey_views.DANCE_Coding_Sheet s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Demographics]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Demographics]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
     -- ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]
      ,s.[CLIENT_MARITAL_0_STATUS]
      ,s.[CLIENT_BIO_DAD_0_CONTACT_WITH]
      ,s.[CLIENT_LIVING_0_WITH]
      ,s.[CLIENT_LIVING_1_WITH_OTHERS]
      ,s.[CLIENT_EDUCATION_0_HS_GED]
      ,s.[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]
      ,s.[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_CURRENT]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_TYPE]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_PLAN]
      ,s.[CLIENT_WORKING_0_CURRENTLY_WORKING]
      ,s.[CLIENT_INCOME_0_HH_INCOME]
      ,s.[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
    --  ,s.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]
   --   ,s.[CLIENT_PERSONAL_0_RACE]
     -- ,s.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      --,s.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]
      --,s.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]
      --,s.[CLIENT_BC_0_USED_6MONTHS]
      --,s.[CLIENT_BC_1_NOT_USED_REASON]
      --,s.[CLIENT_BC_1_FREQUENCY]
      --,s.[CLIENT_BC_1_TYPES]
      --,s.[CLIENT_SUBPREG_0_BEEN_PREGNANT]
      --,s.[CLIENT_SUBPREG_1_BEGIN_MONTH]
      --,s.[CLIENT_SUBPREG_1_BEGIN_YEAR]
      --,s.[CLIENT_SUBPREG_1_PLANNED]
      --,s.[CLIENT_SUBPREG_1_OUTCOME]
      --,s.[CLIENT_SECOND_0_CHILD_DOB]
      --,s.[CLIENT_SECOND_1_CHILD_GENDER]
      --,s.[CLIENT_SECOND_1_CHILD_BW_POUNDS]
      --,s.[CLIENT_SECOND_1_CHILD_BW_OZ]
      --,s.[CLIENT_SECOND_1_CHILD_NICU]
      --,s.[CLIENT_SECOND_1_CHILD_NICU_DAYS]
      --,s.[CLIENT_BIO_DAD_1_TIME_WITH]
      ,s.[ADULTS_1_ENROLL_NO]
      ,s.[ADULTS_1_ENROLL_PT]
      ,s.[ADULTS_1_CARE_10]
      ,s.[ADULTS_1_CARE_20]
      ,s.[ADULTS_1_CARE_30]
      ,s.[ADULTS_1_CARE_40]
      ,s.[ADULTS_1_CARE_LESS10]
      ,s.[ADULTS_1_COMPLETE_GED]
      ,s.[ADULTS_1_COMPLETE_HS]
      ,s.[ADULTS_1_COMPLETE_HS_NO]
      ,s.[ADULTS_1_ED_TECH]
      ,s.[ADULTS_1_ED_ASSOCIATE]
      ,s.[ADULTS_1_ED_BACHELOR]
      ,s.[ADULTS_1_ED_MASTER]
      ,s.[ADULTS_1_ED_NONE]
      ,s.[ADULTS_1_ED_POSTGRAD]
      ,s.[ADULTS_1_ED_SOME_COLLEGE]
      ,s.[ADULTS_1_ED_UNKNOWN]
      ,s.[ADULTS_1_ENROLL_FT]
      ,s.[ADULTS_1_INS_NO]
      ,s.[ADULTS_1_INS_PRIVATE]
      ,s.[ADULTS_1_INS_PUBLIC]
      ,s.[ADULTS_1_WORK_10]
      ,s.[ADULTS_1_WORK_20]
      ,s.[ADULTS_1_WORK_37]
      ,s.[ADULTS_1_WORK_LESS10]
      ,s.[ADULTS_1_WORK_UNEMPLOY]
      ,s.[CLIENT_CARE_0_ER_HOSP]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_FTPT]
      ,s.[CLIENT_INCOME_1_HH_SOURCES]
      ,s.[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]
    --  ,s.[DW_AuditDate]
    --  ,s.[DataSource]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]
      ,s.[CLIENT_SCHOOL_MIDDLE_HS]
      ,s.[CLIENT_ED_PROG_TYPE]
      ,s.[CLIENT_PROVIDE_CHILDCARE]
      --,s.[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]
      ,s.[CLIENT_CARE_0_ER]
      ,s.[CLIENT_CARE_0_URGENT]
      ,s.[CLIENT_CARE_0_ER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_TIMES]
      ,s.[CLIENT_INCOME_IN_KIND]
      ,s.[CLIENT_INCOME_SOURCES]
      ,s.[CLIENT_MILITARY]
     -- ,s.[DELETE ME]
      ,s.[CLIENT_INCOME_AMOUNT]
      ,s.[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_INCOME_INKIND_OTHER]) as [CLIENT_INCOME_INKIND_OTHER]
       ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_INCOME_OTHER_SOURCES]) as [CLIENT_INCOME_OTHER_SOURCES]
      --,s.[CLIENT_BC_1_TYPES_NEXT6]
      --,s.[CLIENT_SUBPREG_1_EDD]
      ,s.[CLIENT_CARE_0_ER_PURPOSE]
      ,s.[CLIENT_CARE_0_URGENT_PURPOSE]
     -- ,s.[CLIENT_CARE_0_ URGENT_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_CARE_0_ER_OTHER]) as [CLIENT_CARE_0_ER_OTHER]
      ,s.[CLIENT_CARE_0_ER_FEVER_TIMES]
      ,s.[CLIENT_CARE_0_ER_INFECTION_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_TIMES]
      ,s.[CLIENT_CARE_0_ER_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_FEVER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INFECTION_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_OTHER_TIMES]
     -- ,s.[CLIENT_SECOND_1_CHILD_BW_MEASURE]
      ,s.[CLIENT_CARE_0_URGENT_OTHER]
     -- ,s.[CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS]
     -- ,s.[CLIENT_SECOND_1_CHILD_BW_GRAMS]
     -- ,s.[CLIENT_SUBPREG_1_GEST_AGE]
      --,s.[Master_SurveyID]
      ,s.[CLIENT_CARE_0_ER_PURPOSE_R6]
      ,s.[CLIENT_CARE_0_URGENT_PURPOSE_R6]
     -- ,s.[CLIENT_SUBPREG]
      ,s.[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_SELF_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES]
      --,s.[Archive_Record]
      ,s.[CLIENT_INSURANCE_TYPE]
      ,s.[CLIENT_INSURANCE]
      ,s.[CLIENT_LIVING_HOMELESS]
      ,s.[CLIENT_LIVING_WHERE]
      ,s.[CLIENT_INSURANCE_OTHER]
from survey_views.Demographics s

where 

s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



	
	
end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Demographics_Update]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Demographics_Update] as  begin  select * from survey_views.Demographics_Update end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Edinburgh_Postnatal_Depression_Scale]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Edinburgh_Postnatal_Depression_Scale] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_EPDS_1_ABLE_TO_LAUGH]
      ,s.[CLIENT_EPDS_1_ENJOY_THINGS]
      ,s.[CLIENT_EPDS_1_BLAME_SELF]
      ,s.[CLIENT_EPDS_1_ANXIOUS_WORRIED]
      ,s.[CLIENT_EPDS_1_SCARED_PANICKY]
      ,s.[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]
      ,s.[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]
      ,s.[CLIENT_EPDS_1_SAD_MISERABLE]
      ,s.[CLIENT_EPDS_1_BEEN_CRYING]
      ,s.[CLIENT_EPDS_1_HARMING_SELF]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as[CLIENT_0_ID_AGENCY]
     -- ,s.[DW_AuditDate]
     -- ,s.[DataSource]
      --,s.[LA_CTY_OQ10_EDPS]
      --,s.[LA_CTY_PHQ9_SCORE_EDPS]
     -- ,s.[LA_CTY_STRESS_INDEX_EDPS]
      ,s.[CLIENT_EPS_TOTAL_SCORE]
      --,s.[Master_SurveyID]  
from survey_views.Edinburgh_Postnatal_Depression_Scale s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;




end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Education_Registration]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Education_Registration] as  begin  select * from survey_views.Education_Registration end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Education_Registration_V2]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Education_Registration_V2] as  begin  select * from survey_views.Education_Registration_V2 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_GAD_7]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_GAD_7] as  begin  select * from survey_views.GAD_7 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Goodwill_Indy_Additional_Referral_Data]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Goodwill_Indy_Additional_Referral_Data] as  begin  select * from survey_views.Goodwill_Indy_Additional_Referral_Data end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Health_Habits]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Health_Habits] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  
set nocount on;

select 
 s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_SUBSTANCE_CIG_1_PRE_PREG]
      ,s.[CLIENT_SUBSTANCE_CIG_0_DURING_PREG]
      ,s.[CLIENT_SUBSTANCE_CIG_1_LAST_48]
      ,s.[CLIENT_SUBSTANCE_ALCOHOL_0_14DAY]
      ,s.[CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS]
      ,s.[CLIENT_SUBSTANCE_POT_0_14DAYS]
      ,s.[CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS]
      ,s.[CLIENT_SUBSTANCE_COCAINE_0_14DAY]
      ,s.[CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES]
      ,s.[CLIENT_SUBSTANCE_OTHER_0_14DAY]
      ,s.[CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES]
      ,s.[NURSE_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_0_ID_AGENCY]
      --,s.[DW_AuditDate]
     -- ,s.[DataSource]
      ,s.[CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES]
      ,s.[CLIENT_SUBSTANCE_NICOTINE_0_OTHER]
     -- ,s.[Master_SurveyID] 
from survey_views.Health_Habits s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;





end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Home_Visit_Encounter]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Home_Visit_Encounter] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO] 
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_FIRST]) as  [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_TIME_0_START_VISIT]
      ,s.[CLIENT_TIME_1_END_VISIT]
      ,s.[NURSE_MILEAGE_0_VIS]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_COMPLETE_0_VISIT]
      ,s.[CLIENT_LOCATION_0_VISIT]
      ,s.[CLIENT_ATTENDEES_0_AT_VISIT]
      ,s.[CLIENT_INVOLVE_0_CLIENT_VISIT]
      ,s.[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]
      ,s.[CLIENT_INVOLVE_1_PARTNER_VISIT]
      ,s.[CLIENT_CONFLICT_0_CLIENT_VISIT]
      ,s.[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]
      ,s.[CLIENT_CONFLICT_1_PARTNER_VISIT]
      ,s.[CLIENT_UNDERSTAND_0_CLIENT_VISIT]
      ,s.[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]
      ,s.[CLIENT_UNDERSTAND_1_PARTNER_VISIT]
      ,s.[CLIENT_DOMAIN_0_PERSHLTH_VISIT]
      ,s.[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]
      ,s.[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]
      ,s.[CLIENT_DOMAIN_0_MATERNAL_VISIT]
      ,s.[CLIENT_DOMAIN_0_FRNDFAM_VISIT]
      ,s.[CLIENT_DOMAIN_0_TOTAL_VISIT]
      ,s.[CLIENT_CONTENT_0_PERCENT_VISIT]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]) as [CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]
      ,s.[CLIENT_TIME_1_DURATION_VISIT]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_CHILD_INJURY_0_PREVENTION]
      ,s.[CLIENT_IPV_0_SAFETY_PLAN]
     -- ,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_PRENATAL_VISITS_WEEKS]
      ,s.[CLIENT_NO_REFERRAL]
      ,s.[CLIENT_PRENATAL_VISITS]
      ,s.[CLIENT_SCREENED_SRVCS]
      ,s.[CLIENT_VISIT_SCHEDULE]
      --,s.[Master_SurveyID]
      ,s.[CLIENT_PLANNED_VISIT_SCH]
      ,s.[CLIENT_TIME_FROM_AMPM]
      ,s.[CLIENT_TIME_FROM_HR]
      ,s.[CLIENT_TIME_FROM_MIN]
      ,s.[CLIENT_TIME_TO_AMPM]
      ,s.[CLIENT_TIME_TO_HR]
      ,s.[CLIENT_TIME_TO_MIN]
      --,s.[temp_time_start]
      --,s.[temp_time_end]
      --,s.[Old_CLIENT_TIME_0_START_Visit]
      --,s.[Old_CLIENT_TIME_1_END_Visit]
      --,s.[old_CLIENT_TIME_1_DURATION_VISIT]
      --,s.[temp_DURATION]
      --,s.[LastModified]
      --,s.[Archive_Record]
      ,s.[INFANT_HEALTH_ER_1_TYPE]
      ,s.[INFANT_HEALTH_HOSP_1_TYPE]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]
      ,s.[CLIENT_CHILD_DEVELOPMENT_CONCERN]
      ,s.[CLIENT_CONT_HLTH_INS]
      ,s.[INFANT_HEALTH_ER_0_HAD_VISIT]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT3]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT1]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT2]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT3]
      ,s.[INFANT_HEALTH_ER_1_OTHER]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]
      ,s.[INFANT_HEALTH_HOSP_0_HAD_VISIT]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT_R2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_REASON1]
      ,s.[INFANT_HEALTH_ER_1_OTHER_REASON2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_REASON3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS3]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS1]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS2]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE3]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE1]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE2]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE3]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT1]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT2]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT3]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE1]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE2]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE3]
from survey_views.Home_Visit_Encounter s
where

s.SiteID = case when @p_Profile_Id=null then s.SiteID else @p_Profile_Id end;


end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Infant_Birth]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Infant_Birth] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as 
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
     -- ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_0_ID_NSO]) as [INFANT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_FIRST NAME]) as [INFANT_PERSONAL_0_FIRST NAME]
      ,s.[INFANT_BIRTH_0_DOB]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[INFANT_BIRTH_1_MULTIPLE_BIRTHS]
      ,s.[INFANT_PERSONAL_0_ETHNICITY]
      ,s.[INFANT_PERSONAL_0_RACE]
      ,s.[INFANT_PERSONAL_0_GENDER]
      ,s.[INFANT_BIRTH_1_WEIGHT_GRAMS]
      ,s.[INFANT_BIRTH_1_WEIGHT_POUNDS]
      ,s.[INFANT_BIRTH_1_GEST_AGE]
      ,s.[INFANT_BIRTH_1_NICU]
      ,s.[INFANT_BIRTH_1_NICU_DAYS]
      ,s.[CLIENT_WEIGHT_0_PREG_GAIN]
      ,s.[INFANT_BREASTMILK_0_EVER_BIRTH]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_0_ID_NSO2]) as [INFANT_0_ID_NSO2]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_FIRST NAME2]) as [INFANT_PERSONAL_0_FIRST NAME2]
      ,s.[INFANT_BIRTH_0_DOB2]
      ,s.[INFANT_PERSONAL_0_ETHNICITY2]
      ,s.[INFANT_PERSONAL_0_ETHNICITY3]
      ,s.[INFANT_PERSONAL_0_RACE2]
      ,s.[INFANT_PERSONAL_0_RACE3]
      ,s.[INFANT_PERSONAL_0_GENDER2]
      ,s.[INFANT_BIRTH_1_WEIGHT_GRAMS2]
      ,s.[INFANT_BIRTH_1_GEST_AGE2]
      ,s.[INFANT_BIRTH_1_NICU2]
      ,s.[INFANT_BIRTH_1_NICU_DAYS2]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_0_ID_NSO3]) as [INFANT_0_ID_NSO3]
      ,s.[INFANT_BIRTH_0_DOB3]
      ,s.[INFANT_PERSONAL_0_GENDER3]
      ,s.[INFANT_BIRTH_1_WEIGHT_GRAMS3]
      ,s.[INFANT_BIRTH_1_WEIGHT_POUNDS3]
      ,s.[INFANT_BIRTH_1_GEST_AGE3]
      ,s.[INFANT_BIRTH_1_NICU3]
      ,s.[INFANT_BIRTH_1_NICU_DAYS3]
      ,s.[INFANT_BREASTMILK_0_EVER_BIRTH2]
      ,s.[INFANT_BREASTMILK_0_EVER_BIRTH3]
      ,s.[INFANT_BIRTH_1_WEIGHT_MEASURE]
      ,s.[INFANT_BIRTH_1_WEIGHT_OUNCES]
      ,s.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]
      ,s.[INFANT_BIRTH_1_WEIGHT_MEASURE2]
      ,s.[INFANT_BIRTH_1_WEIGHT_MEASURE3]
      ,s.[INFANT_BIRTH_1_WEIGHT_OUNCES3]
      ,s.[INFANT_BIRTH_1_WEIGHT_POUNDS2]
      ,s.[INFANT_BIRTH_1_WEIGHT_OUNCES2]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_FIRST NAME3]) as [INFANT_PERSONAL_0_FIRST NAME3]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_LAST NAME]) as [INFANT_PERSONAL_0_LAST NAME]
     -- ,s.[DW_AuditDate]
     -- ,s.[DataSource]
      ,s.[INFANT_BIRTH_0_CLIENT_ER]
      ,s.[INFANT_BIRTH_0_CLIENT_URGENT CARE]
      ,s.[INFANT_BIRTH_1_NICU_R2]
      ,s.[INFANT_BIRTH_1_NICU_R2_2]
      ,s.[INFANT_BIRTH_1_NICU_R2_3]
      ,s.[INFANT_BIRTH_1_NURSERY_R2]
      ,s.[INFANT_BIRTH_1_NURSERY_R2_2]
      ,s.[INFANT_BIRTH_1_NURSERY_R2_3]
      ,s.[INFANT_BIRTH_0_CLIENT_ER_TIMES]
      ,s.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]
      ,s.[INFANT_BIRTH_1_NICU_DAYS_R2]
      ,s.[INFANT_BIRTH_1_NICU_DAYS_R2_2]
      ,s.[INFANT_BIRTH_1_NICU_DAYS_R2_3]
      ,s.[INFANT_BIRTH_1_NURSERY_DAYS_R2]
      ,s.[INFANT_BIRTH_1_NURSERY_DAYS_R2_2]
      ,s.[INFANT_BIRTH_1_NURSERY_DAYS_R2_3]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3]
      ,s.[INFANT_BIRTH_1_DELIVERY]
      ,s.[INFANT_BIRTH_1_HEARING_SCREEN]
      ,s.[INFANT_BIRTH_1_HEARING_SCREEN2]
      ,s.[INFANT_BIRTH_1_HEARING_SCREEN3]
      ,s.[INFANT_BIRTH_1_LABOR]
      ,s.[INFANT_BIRTH_1_NEWBORN_SCREEN]
      ,s.[INFANT_BIRTH_1_NEWBORN_SCREEN2]
      ,s.[INFANT_BIRTH_1_NEWBORN_SCREEN3]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]) as [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2]) as [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3]) as [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3]
      --,s.[Master_SurveyID]
      ,s.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2]
      ,s.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3]
      --,s.[LastModified]  
      --,s.[Archive_Record]
      ,s.[INFANT_INSURANCE_TYPE]
      ,s.[INFANT_INSURANCE_TYPE2]
      ,s.[INFANT_INSURANCE_TYPE3]
      ,s.[INFANT_BIRTH_COSLEEP]
      ,s.[INFANT_BIRTH_COSLEEP2]
      ,s.[INFANT_BIRTH_COSLEEP3]
      ,s.[INFANT_BIRTH_READ]
      ,s.[INFANT_BIRTH_READ2]
      ,s.[INFANT_BIRTH_READ3]
      ,s.[INFANT_BIRTH_SLEEP_BACK]
      ,s.[INFANT_BIRTH_SLEEP_BACK2]
      ,s.[INFANT_BIRTH_SLEEP_BACK3]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING2]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING3]
      ,s.[INFANT_INSURANCE]
      ,s.[INFANT_INSURANCE2]
      ,s.[INFANT_INSURANCE3]
      ,s.[INFANT_INSURANCE_OTHER]
      ,s.[INFANT_INSURANCE_OTHER2]
      ,s.[INFANT_INSURANCE_OTHER3] 
 from survey_views.Infant_Birth s 
 where
 s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;




 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Infant_Health_Care]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Infant_Health_Care] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
     -- ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_0_ID_NSO]) as [INFANT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_NAME_FIRST]) as  [INFANT_PERSONAL_0_NAME_FIRST]
      ,s.[INFANT_BIRTH_0_DOB]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[INFANT_HEALTH_PROVIDER_0_PRIMARY]
      ,s.[INFANT_HEALTH_IMMUNIZ_0_UPDATE]
      ,s.[INFANT_HEALTH_IMMUNIZ_1_RECORD]
      ,s.[INFANT_HEALTH_LEAD_0_TEST]
      ,s.[INFANT_HEALTH_HEIGHT_0_INCHES]
      ,s.[INFANT_HEALTH_HEIGHT_1_PERCENT]
      ,s.[INFANT_HEALTH_HEAD_0_CIRC_INCHES]
      ,s.[INFANT_HEALTH_ER_0_HAD_VISIT]
      ,s.[INFANT_HEALTH_ER_1_TYPE]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE1]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE2]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE3]
      ,s.[INFANT_HEALTH_HOSP_0_HAD_VISIT]
      ,s.[INFANT_BREASTMILK_0_EVER_IHC]
      ,s.[INFANT_BREASTMILK_1_CONT]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE1]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE2]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE3]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]
      ,s.[INFANT_HEALTH_HOSP_1_TYPE]
      ,s.[INFANT_BREASTMILK_1_AGE_STOP]
      ,s.[INFANT_BREASTMILK_1_WEEK_STOP]
      ,s.[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]
      ,s.[INFANT_SOCIAL_SERVICES_0_REFERRAL]
      ,s.[INFANT_SOCIAL_SERVICES_1_REFDATE1]
      ,s.[INFANT_SOCIAL_SERVICES_1_REFDATE2]
      ,s.[INFANT_SOCIAL_SERVICES_1_REFDATE3]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]
      ,s.[INFANT_HEALTH_WEIGHT_0_POUNDS]
      ,s.[INFANT_HEALTH_WEIGHT_1_OUNCES]
      ,s.[INFANT_HEALTH_WEIGHT_1_OZ]
      ,s.[INFANT_HEALTH_WEIGHT_1_PERCENT]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      ,s.[INFANT_AGES_STAGES_1_COMM]
      ,s.[INFANT_AGES_STAGES_0_VERSION]
      ,s.[INFANT_AGES_STAGES_1_GMOTOR]
      ,s.[INFANT_AGES_STAGES_1_FMOTOR]
      ,s.[INFANT_AGES_STAGES_1_PSOLVE]
      ,s.[INFANT_AGES_STAGES_1_PSOCIAL]
      ,s.[INFANT_AGES_STAGES_SE_0_EMOTIONAL]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_NAME_LAST]) as [INFANT_PERSONAL_0_NAME_LAST]
      ,s.[INFANT_HEALTH_HEAD_1_REPORT]
      ,s.[INFANT_HEALTH_HEIGHT_1_REPORT]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT]
      ,s.[INFANT_HEALTH_WEIGHT_1_REPORT]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT3]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT1]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT2]
      ,s.[INFANT_HEALTH_ER_1_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_HEALTH_ER_1_OTHER_REASON1]) as [INFANT_HEALTH_ER_1_OTHER_REASON1]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_HEALTH_ER_1_OTHER_REASON2]) as [INFANT_HEALTH_ER_1_OTHER_REASON2]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_HEALTH_ER_1_OTHER_REASON3]) as [INFANT_HEALTH_ER_1_OTHER_REASON3]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT2]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT3]
      ,s.[INFANT_HOME_0_TOTAL]
      ,s.[INFANT_HOME_1_ACCEPTANCE]
      ,s.[INFANT_HOME_1_EXPERIENCE]
      ,s.[INFANT_HOME_1_INVOLVEMENT]
      ,s.[INFANT_HOME_1_LEARNING]
      ,s.[INFANT_HOME_1_ORGANIZATION]
      ,s.[INFANT_HOME_1_RESPONSIVITY]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REASON1]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REASON2]
      ,s.[INFANT_SOCIAL_SERVICES_1_NHV_REASON3]
      ,s.[INFANT_SOCIAL_SERVICES_1_REASON1]
      ,s.[INFANT_SOCIAL_SERVICES_1_REASON2]
      ,s.[INFANT_SOCIAL_SERVICES_1_REASON3]
     -- ,s.[NFANT_HEALTH_ER_1_INJ_TREAT3]
     -- ,s.[DW_AuditDate]
     -- ,s.[DataSource]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT_R2]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]
      ,s.[INFANT_HEALTH_NO_ASQ_COMM]
      ,s.[INFANT_HEALTH_NO_ASQ_FINE]
      ,s.[INFANT_HEALTH_NO_ASQ_GROSS]
      ,s.[INFANT_HEALTH_NO_ASQ_PERSONAL]
      ,s.[INFANT_HEALTH_NO_ASQ_PROBLEM]
      ,s.[INFANT_HEALTH_NO_ASQ_TOTAL]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT3]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_PERSONAL_0_SSN]) as [INFANT_PERSONAL_0_SSN]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS3]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS1]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS2]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS3]
      --,s.[Master_SurveyID]
      ,s.[INFANT_HEALTH_IMMUNIZ_UPDATE_NO]
      ,s.[INFANT_HEALTH_IMMUNIZ_UPDATE_YES]
      ,s.[INFANT_HEALTH_DENTIST]
      ,s.[INFANT_HEALTH_DENTIST_STILL_EBF]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER]) as [INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER]) as [INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER]) as  [INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_SOCIAL_SERVICES_1_REASON1_OTHER]) as  [INFANT_SOCIAL_SERVICES_1_REASON1_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_SOCIAL_SERVICES_1_REASON2_OTHER]) as [INFANT_SOCIAL_SERVICES_1_REASON2_OTHER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_SOCIAL_SERVICES_1_REASON3_OTHER])as [INFANT_SOCIAL_SERVICES_1_REASON3_OTHER]
     -- ,s.[Archive_Record]
      ,s.[INFANT_INSURANCE_TYPE]
      ,s.[INFANT_AGES_STAGES_SE_VERSION]
      ,s.[INFANT_BIRTH_COSLEEP]
      ,s.[INFANT_BIRTH_READ]
      ,s.[INFANT_BIRTH_SLEEP_BACK]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING]
      ,s.[INFANT_HEALTH_DENTAL_SOURCE]
      ,s.[INFANT_INSURANCE]
      ,s.[INFANT_INSURANCE_OTHER] 
from survey_views.Infant_Health_Care  s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;


end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Joint_Visit_Observation]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Joint_Visit_Observation] as  begin  select * from survey_views.Joint_Visit_Observation end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Joint_Visit_Observation_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Joint_Visit_Observation_Form] as  begin  select * from survey_views.Joint_Visit_Observation_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Maternal_Health_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Maternal_Health_Assessment]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  
set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_EDD]
      ,s.[CLIENT_HEALTH_GENERAL_0_CONCERNS]
      ,s.[CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS]
      ,s.[CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL]
      ,s.[CLIENT_HEALTH_BELIEF_0_CANT_SOLVE]
      ,s.[CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO]
      ,s.[CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS]
      ,s.[CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND]
      ,s.[CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL]
      ,s.[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING]
      ,s.[CLIENT_HEALTH_GENERAL_0_OTHER]
      ,s.[CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET]
      ,s.[CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES]
      ,s.[CLIENT_0_ID_AGENCY]
      --,s.[DW_AuditDate]
      --,s.[DataSource]
     -- ,s.[LA_CTY_MENTAL_MAT_HEALTH]
     -- ,s.[LA_CTY_PHYSICAL_MAT_HEALTH]
      --,s.[LA_CTY_DX_OTHER_MAT_HEALTH]
      --,s.[LA_CTY_DSM_DX_MAT_HEALTH]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI]
      ,s.[CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS]
      --,s.[Master_SurveyID]
      ,s.[CLIENT_HEALTH_GENERAL_0_CONCERNS2]
      ,s.[CLIENT_HEALTH_GENERAL_0_ADDICTION]
      ,s.[CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH]
     -- ,s.[LastModified] 
from survey_views.Maternal_Health_Assessment  s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_12_Month_Infant]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_12_Month_Infant] as  begin  select * from survey_views.MN_12_Month_Infant end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_18_Months_Toddler]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_18_Months_Toddler] as  begin  select * from survey_views.MN_18_Months_Toddler end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_24_Month_Toddler]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_24_Month_Toddler] as  begin  select * from survey_views.MN_24_Month_Toddler end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_6_Months_Infant]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_6_Months_Infant] as  begin  select * from survey_views.MN_6_Months_Infant end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_Child_Intake]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Child_Intake] as  begin  select * from survey_views.MN_Child_Intake end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_Primary_Caregiver_Closure]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Primary_Caregiver_Closure] as  begin  select * from survey_views.MN_Primary_Caregiver_Closure end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_Primary_Caregiver_Intake]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Primary_Caregiver_Intake] as  begin  select * from survey_views.MN_Primary_Caregiver_Intake end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_New_Hire_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_New_Hire_Form] as  begin  select * from survey_views.New_Hire_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_New_Hire_V2]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_New_Hire_V2] as  begin  select * from survey_views.New_Hire_V2 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_NFP_Los_Angeles__Outreach_Marketing]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_NFP_Los_Angeles__Outreach_Marketing] as  begin  select * from survey_views.NFP_Los_Angeles__Outreach_Marketing end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_NFP_Tribal_Project]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_NFP_Tribal_Project] as  begin  select * from survey_views.NFP_Tribal_Project end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Nurse_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Nurse_Assessment] as  begin  select * from survey_views.Nurse_Assessment end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_PHQ_9]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_PHQ_9] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
     -- ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      --,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      --,s.[Need from Kim]
      --,s.[NeedFromKim]
      ,s.[CLIENT_PHQ9_0_TOTAL_SCORE]
      ,s.[CLIENT_PHQ9_1_CONCENTRATION]
      ,s.[CLIENT_PHQ9_1_DIFFICULTY]
      ,s.[CLIENT_PHQ9_1_FEEL_BAD]
      ,s.[CLIENT_PHQ9_1_FEEL_DEPRESSED]
      ,s.[CLIENT_PHQ9_1_FEEL_TIRED]
      ,s.[CLIENT_PHQ9_1_HURT_SELF]
      ,s.[CLIENT_PHQ9_1_LITTLE_INTEREST]
      ,s.[CLIENT_PHQ9_1_MOVE_SPEAK]
      ,s.[CLIENT_PHQ9_1_TROUBLE_EAT]
      ,s.[CLIENT_PHQ9_1_TROUBLE_SLEEP]
      ,s.[NURSE_PERSONAL_0_NAME]
     -- ,s.[DW_AuditDate]
     -- ,s.[DataSource]
     -- ,s.[Master_SurveyID] 
from survey_views.PHQ_9 s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Profile_Of_Program_Staff_UPDATE]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Profile_Of_Program_Staff_UPDATE] as  begin  select * from survey_views.Profile_Of_Program_Staff_UPDATE end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Record_of_Team_Meetings_and_Case_Conferences]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Record_of_Team_Meetings_and_Case_Conferences] as  begin  select * from survey_views.Record_of_Team_Meetings_and_Case_Conferences end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Referrals_To_NFP_Program]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Referrals_To_NFP_Program] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  
set nocount on;


select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[REFERRAL_PROSPECT_0_SOURCE_CODE]
      ,s.[REFERRAL_SOURCE_PRIMARY_0_NAME]
      ,s.[REFERRAL_SOURCE_PRIMARY_1_LOCATION]
      ,s.[REFERRAL_SOURCE_SECONDARY_0_NAME]
      ,s.[REFERRAL_SOURCE_SECONDARY_1_LOCATION]
      ,s.[REFERRAL_PROSPECT_0_NOTES]
	  ,s.[REFERRAL_PROSPECT_DEMO_1_PLANG]
      ,s.[REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]
      ,s.[REFERRAL_PROSPECT_DEMO_0_NAME_LAST]
      ,s.[REFERRAL_PROSPECT_DEMO_1_DOB]
      ,s.[REFERRAL_PROSPECT_DEMO_1_STREET]
      ,s.[REFERRAL_PROSPECT_DEMO_1_STREET2]
      ,s.[REFERRAL_PROSPECT_DEMO_1_ZIP]
      ,s.[REFERRAL_PROSPECT_DEMO_1_WORK]
      ,s.[REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]
      ,s.[REFERRAL_PROSPECT_DEMO_1_CELL]
      ,s.[REFERRAL_PROSPECT_DEMO_1_EMAIL]
      ,s.[REFERRAL_PROSPECT_DEMO_1_EDD]
      ,s.[REFERRAL_PROSPECT_0_WAIT_LIST]
      ,s.[REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]
      --,s.[DW_AuditDate]
      --,s.[DataSource]
      --,s.[LA_CTY_REFERRAL_SCHOOL]
      --,s.[LA_CTY_REFERRAL_SOURCE_OTH]
      ,s.[CLIENT_0_ID_NSO]
      --,s.[Master_SurveyID]
from survey_views.Referrals_To_NFP_Program  s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;




end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Relationship_Assessment]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Relationship_Assessment] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

set nocount on;

select 
 s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as  [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]
      ,s.[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]
      ,s.[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]
      ,s.[CLIENT_ABUSE_FORCED_0_SEX]
      ,s.[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]
      ,s.[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]
      ,s.[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]
      ,s.[CLIENT_ABUSE_AFRAID_0_PARTNER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      --,s.[ABUSE_EMOTION_0_PHYSICAL_PARTNER]
      --,s.[DW_AuditDate]
      --,s.[DataSource]
      --,s.[Master_SurveyID]  
from survey_views.Relationship_Assessment s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Staff_Team_to_Team_Transfer_Request]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Staff_Team_to_Team_Transfer_Request] as  begin  select * from survey_views.Staff_Team_to_Team_Transfer_Request end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_STAR_Framework]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_STAR_Framework] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as 
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      --,s.[Master_SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      --,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_GLOBAL_FACTORS]
      ,s.[CLIENT_CAREGIVING_FRIENDS_FAM]
      ,s.[CLIENT_CAREGIVING_RISK_LEVEL]
      ,s.[CLIENT_CAREGIVING_SERVICES_GOALS]
      ,s.[CLIENT_CAREGIVING_STAGE_CHANGE]
      ,s.[CLIENT_CAREGIVING_UNDERSTANDS_RISK]
      ,s.[CLIENT_CHLD_CARE_FRIENDS_FAM]
      ,s.[CLIENT_CHLD_CARE_RISK_LEVEL]
      ,s.[CLIENT_CHLD_CARE_SERVICES_GOALS]
      ,s.[CLIENT_CHLD_CARE_STAGE_CHANGE]
      ,s.[CLIENT_CHLD_CARE_UNDERSTANDS_RISK]
      ,s.[CLIENT_CHLD_HEALTH_FRIENDS_FAM]
      ,s.[CLIENT_CHLD_HEALTH_RISK_LEVEL]
      ,s.[CLIENT_CHLD_HEALTH_SERVICES_GOALS]
      ,s.[CLIENT_CHLD_HEALTH_STAGE_CHANGE]
      ,s.[CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK]
      ,s.[CLIENT_CHLD_WELL_FRIENDS_FAM]
      ,s.[CLIENT_CHLD_WELL_RISK_LEVEL]
      ,s.[CLIENT_CHLD_WELL_SERVICES_GOALS]
      ,s.[CLIENT_CHLD_WELL_STAGE_CHANGE]
      ,s.[CLIENT_CHLD_WELL_UNDERSTANDS_RISK]
      ,s.[CLIENT_COMM_SVCS_FRIENDS_FAM]
      ,s.[CLIENT_COMM_SVCS_RISK_LEVEL]
      ,s.[CLIENT_COMM_SVCS_SERVICES_GOALS]
      ,s.[CLIENT_COMM_SVCS_STAGE_CHANGE]
      ,s.[CLIENT_COMM_SVCS_UNDERSTANDS_RISK]
      ,s.[CLIENT_COMPLICATION_ILL_FRIENDS_FAM]
      ,s.[CLIENT_COMPLICATION_ILL_RISK_LEVEL]
      ,s.[CLIENT_COMPLICATION_ILL_SERVICES_GOALS]
      ,s.[CLIENT_COMPLICATION_ILL_STAGE_CHANGE]
      ,s.[CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK]
      ,s.[CLIENT_CRIMINAL_FRIENDS_FAM]
      ,s.[CLIENT_CRIMINAL_RISK_LEVEL]
      ,s.[CLIENT_CRIMINAL_SERVICES_GOALS]
      ,s.[CLIENT_CRIMINAL_STAGE_CHANGE]
      ,s.[CLIENT_CRIMINAL_UNDERSTANDS_RISK]
      ,s.[CLIENT_DISABILITY_FRIENDS_FAM]
      ,s.[CLIENT_DISABILITY_RISK_LEVEL]
      ,s.[CLIENT_DISABILITY_SERVICES_GOALS]
      ,s.[CLIENT_DISABILITY_STAGE_CHANGE]
      ,s.[CLIENT_DISABILITY_UNDERSTANDS_RISK]
      ,s.[CLIENT_ECONOMIC_FRIENDS_FAM]
      ,s.[CLIENT_ECONOMIC_RISK_LEVEL]
      ,s.[CLIENT_ECONOMIC_SERVICES_GOALS]
      ,s.[CLIENT_ECONOMIC_STAGE_CHANGE]
      ,s.[CLIENT_ECONOMIC_UNDERSTANDS_RISK]
      ,s.[CLIENT_EDUC_FRIENDS_FAM]
      ,s.[CLIENT_EDUC_RISK_LEVEL]
      ,s.[CLIENT_EDUC_SERVICES_GOALS]
      ,s.[CLIENT_EDUC_STAGE_CHANGE]
      ,s.[CLIENT_EDUC_UNDERSTANDS_RISK]
      ,s.[CLIENT_ENGLIT_FRIENDS_FAM]
      ,s.[CLIENT_ENGLIT_RISK_LEVEL]
      ,s.[CLIENT_ENGLIT_SERVICES_GOALS]
      ,s.[CLIENT_ENGLIT_STAGE_CHANGE]
      ,s.[CLIENT_ENGLIT_UNDERSTANDS_RISK]
      ,s.[CLIENT_ENVIRO_HEALTH_FRIENDS_FAM]
      ,s.[CLIENT_ENVIRO_HEALTH_RISK_LEVEL]
      ,s.[CLIENT_ENVIRO_HEALTH_SERVICES_GOALS]
      ,s.[CLIENT_ENVIRO_HEALTH_STAGE_CHANGE]
      ,s.[CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK]
      ,s.[CLIENT_HLTH_SVCS_FRIENDS_FAM]
      ,s.[CLIENT_HLTH_SVCS_RISK_LEVEL]
      ,s.[CLIENT_HLTH_SVCS_SERVICES_GOALS]
      ,s.[CLIENT_HLTH_SVCS_STAGE_CHANGE]
      ,s.[CLIENT_HLTH_SVCS_UNDERSTANDS_RISK]
      ,s.[CLIENT_HOME_SAFETY_FRIENDS_FAM]
      ,s.[CLIENT_HOME_SAFETY_RISK_LEVEL]
      ,s.[CLIENT_HOME_SAFETY_SERVICES_GOALS]
      ,s.[CLIENT_HOME_SAFETY_STAGE_CHANGE]
      ,s.[CLIENT_HOME_SAFETY_UNDERSTANDS_RISK]
      ,s.[CLIENT_HOMELESS_FRIENDS_FAM]
      ,s.[CLIENT_HOMELESS_RISK_LEVEL]
      ,s.[CLIENT_HOMELESS_SERVICES_GOALS]
      ,s.[CLIENT_HOMELESS_STAGE_CHANGE]
      ,s.[CLIENT_HOMELESS_UNDERSTANDS_RISK]
      ,s.[CLIENT_IPV_FRIENDS_FAM]
      ,s.[CLIENT_IPV_RISK_LEVEL]
      ,s.[CLIENT_IPV_SERVICES_GOALS]
      ,s.[CLIENT_IPV_STAGE_CHANGE]
      ,s.[CLIENT_IPV_UNDERSTANDS_RISK]
      ,s.[CLIENT_LONELY_FRIENDS_FAM]
      ,s.[CLIENT_LONELY_RISK_LEVEL]
      ,s.[CLIENT_LONELY_SERVICES_GOALS]
      ,s.[CLIENT_LONELY_STAGE_CHANGE]
      ,s.[CLIENT_LONELY_UNDERSTANDS_RISK]
      ,s.[CLIENT_MENTAL_HEALTH_FRIENDS_FAM]
      ,s.[CLIENT_MENTAL_HEALTH_RISK_LEVEL]
      ,s.[CLIENT_MENTAL_HEALTH_SERVICES_GOALS]
      ,s.[CLIENT_MENTAL_HEALTH_STAGE_CHANGE]
      ,s.[CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK]
      ,s.[CLIENT_PREGPLAN_FRIENDS_FAM]
      ,s.[CLIENT_PREGPLAN_RISK_LEVEL]
      ,s.[CLIENT_PREGPLAN_SERVICES_GOALS]
      ,s.[CLIENT_PREGPLAN_STAGE_CHANGE]
      ,s.[CLIENT_PREGPLAN_UNDERSTANDS_RISK]
      ,s.[CLIENT_SUBSTANCE_FRIENDS_FAM]
      ,s.[CLIENT_SUBSTANCE_RISK_LEVEL]
      ,s.[CLIENT_SUBSTANCE_SERVICES_GOALS]
      ,s.[CLIENT_SUBSTANCE_STAGE_CHANGE]
      ,s.[CLIENT_SUBSTANCE_UNDERSTANDS_RISK]
      ,s.[CLIENT_UNSAFE_NTWK_FRIENDS_FAM]
      ,s.[CLIENT_UNSAFE_NTWK_RISK_LEVEL]
      ,s.[CLIENT_UNSAFE_NTWK_SERVICES_GOALS]
      ,s.[CLIENT_UNSAFE_NTWK_STAGE_CHANGE]
      ,s.[CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]

from survey_views.STAR_Framework  s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;




end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Supplemental_Discharge_Information]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Supplemental_Discharge_Information] as  begin  select * from survey_views.Supplemental_Discharge_Information end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TCM_Finance_Log]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TCM_Finance_Log] as  begin  select * from survey_views.TCM_Finance_Log end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TCM_ISP]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TCM_ISP] as  begin  select * from survey_views.TCM_ISP end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Telehealth_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Telehealth_Form] as  begin  select * from survey_views.Telehealth_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Telehealth_Pilot_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Telehealth_Pilot_Form] as  begin  select * from survey_views.Telehealth_Pilot_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TEST_CASE_ASSESSMENT]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TEST_CASE_ASSESSMENT] as  begin  select * from survey_views.TEST_CASE_ASSESSMENT end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TX_THV_Supplemental_Data_Form]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TX_THV_Supplemental_Data_Form] as  begin  select * from survey_views.TX_THV_Supplemental_Data_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Unknown]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Unknown] as  begin  select * from survey_views.Unknown end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Use_Of_Government_and_Community_Services]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Use_Of_Government_and_Community_Services]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null
as  
begin  

set nocount on;

select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      --,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
     -- ,s.[RespondentID]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[SERVICE_USE_0_TANF_CLIENT]
      ,s.[SERVICE_USE_0_FOODSTAMP_CLIENT]
      ,s.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT]
      ,s.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT]
      ,s.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT]
      ,s.[SERVICE_USE_0_IPV_CLIENT]
      ,s.[SERVICE_USE_0_CPS_CLIENT]
      ,s.[SERVICE_USE_0_CPS_CHILD]
      ,s.[SERVICE_USE_0_MENTAL_CLIENT]
      ,s.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT]
      ,s.[SERVICE_USE_0_SMOKE_CLIENT]
      ,s.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT]
      ,s.[SERVICE_USE_0_DRUG_ABUSE_CLIENT]
      ,s.[SERVICE_USE_0_MEDICAID_CLIENT]
      ,s.[SERVICE_USE_0_MEDICAID_CHILD]
      ,s.[SERVICE_USE_0_SCHIP_CLIENT]
      ,s.[SERVICE_USE_0_SCHIP_CHILD]
      ,s.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT]
      ,s.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD]
      ,s.[SERVICE_USE_0_PCP_CLIENT]
      ,s.[SERVICE_USE_0_PCP_SICK_CHILD]
      ,s.[SERVICE_USE_0_PCP_WELL_CHILD]
      ,s.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT]
      ,s.[SERVICE_USE_0_WIC_CLIENT]
      ,s.[SERVICE_USE_0_CHILD_CARE_CLIENT]
      ,s.[SERVICE_USE_0_JOB_TRAINING_CLIENT]
      ,s.[SERVICE_USE_0_HOUSING_CLIENT]
      ,s.[SERVICE_USE_0_TRANSPORTATION_CLIENT]
      ,s.[SERVICE_USE_0_PREVENT_INJURY_CLIENT]
      ,s.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT]
      ,s.[SERVICE_USE_0_LACTATION_CLIENT]
      ,s.[SERVICE_USE_0_GED_CLIENT]
      ,s.[SERVICE_USE_0_HIGHER_EDUC_CLIENT]
      ,s.[SERVICE_USE_0_CHARITY_CLIENT]
      ,s.[SERVICE_USE_0_LEGAL_CLIENT]
      ,s.[SERVICE_USE_0_PATERNITY_CLIENT]
      ,s.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT]
      ,s.[SERVICE_USE_0_ADOPTION_CLIENT]
      ,s.[SERVICE_USE_0_OTHER1_DESC]
      ,s.[SERVICE_USE_0_OTHER1]
      ,s.[SERVICE_USE_0_CHILD_OTHER1]
      ,s.[SERVICE_USE_0_OTHER2_DESC]
      ,s.[SERVICE_USE_0_OTHER3_DESC]
      ,s.[SERVICE_USE_0_OTHER2]
      ,s.[SERVICE_USE_0_CHILD_OTHER2]
      ,s.[SERVICE_USE_0_OTHER3]
      ,s.[SERVICE_USE_0_CHILD_OTHER3]
      ,s.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT]
      ,s.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[SERVICE_USE_0_DENTAL_CLIENT]
      ,s.[SERVICE_USE_0_INTERVENTION]
      ,s.[SERVICE_USE_0_PCP_WELL_CLIENT]
      ,s.[SERVICE_USE_0_DENTAL_CHILD]
     -- ,s.[DW_AuditDate]
     -- ,s.[DataSource]
     -- ,s.[JP error  if no data associated delete element]
      ,s.[SERVICE_USE_INDIAN_HEALTH_CHILD]
      ,s.[SERVICE_USE_INDIAN_HEALTH_CLIENT]
      ,s.[SERVICE_USE_MILITARY_INS_CHILD]
     -- ,s.[SERVICE_USE_MILITARY_INS_CLIENT ]
      ,s.[SERVICE_USE_PCP_CLIENT_POSTPARTUM]
      ,s.[SERVICE_USE_PCP_CLIENT_PRENATAL]
      ,s.[SERVICE_USE_PCP_CLIENT_WELLWOMAN]
      --,s.[Master_SurveyID]
     -- ,s.[Archive_Record]						/*****new columns added on 12/9/2016 according to Ticket#33134.*******/
      ,s.[SERVICE_USE_0_INTERVENTION_45DAYS]	/*****new columns added on 12/9/2016 according to Ticket#33134.*******/
from survey_views.Use_Of_Government_and_Community_Services s
where
s.SiteID = case when @p_Profile_Id is null then s.SiteID else @p_Profile_Id end;



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_WA_MIECHV_Supplemental_HVEF]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_WA_MIECHV_Supplemental_HVEF] as  begin  select * from survey_views.WA_MIECHV_Supplemental_HVEF end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Weekly_Supervision_Record]    Script Date: 11/1/2017 5:05:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Weekly_Supervision_Record] as  begin  select * from survey_views.Weekly_Supervision_Record end 
GO
