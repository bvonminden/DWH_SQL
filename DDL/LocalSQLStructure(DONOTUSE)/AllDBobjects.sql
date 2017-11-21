USE [dwh_test]
GO
/****** Object:  Schema [survey_views]    Script Date: 11/21/2017 3:18:52 PM ******/
CREATE SCHEMA [survey_views]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_get_sites_for_profile_id]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [survey_views].[f_get_sites_for_profile_id]
(
	@p_profile_id		int	= null
)
RETURNS 
@sites TABLE 
(
	siteid int not null primary key
)
AS
BEGIN

	if @p_profile_id is null
	begin

		insert into @sites
		select 
			distinct
		ee.SiteID
		from survey_views.ExportProfile ep 
			inner join survey_views.ExportEntities ee on ep.ExportProfileID=ee.ExportProfileID
	end
	else
	begin

		insert into @sites
		select 
		ee.SiteID
		from survey_views.ExportProfile ep 
			inner join survey_views.ExportEntities ee on ep.ExportProfileID=ee.ExportProfileID
		where 
		ep.ExportProfileID=@p_profile_id
		
	end;

	
	RETURN 
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_hash_field]    Script Date: 11/21/2017 3:18:52 PM ******/
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
	@p_Value_To_Hash	varchar(4000)
)
RETURNS varchar(4000)
AS
BEGIN
	
	return convert(varchar,hashbytes('SHA2_256',@p_Value_To_Hash),2);
	
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_list_survey_questions]    Script Date: 11/21/2017 3:18:52 PM ******/
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
/****** Object:  UserDefinedFunction [survey_views].[f_list_surveys]    Script Date: 11/21/2017 3:18:52 PM ******/
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
/****** Object:  UserDefinedFunction [survey_views].[f_replace_chars]    Script Date: 11/21/2017 3:18:52 PM ******/
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
/****** Object:  UserDefinedFunction [survey_views].[f_secure_fact_survey_response]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_secure_fact_survey_response]
(
	@p_survey_name varchar(100),
	@p_requested_hashing_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
	survey_response_id bigint,
	pseudonym varchar(256),
	secured_value varchar(256),
	survey_question_key bigint,
	survey_date_key bigint,
	organization_key bigint,
	client_key bigint,
	nurse_key bigint
)
AS
BEGIN

if(@p_requested_hashing_policy is null) -- no requested hashing policy so just return as requested
begin

	insert into @result
	select 
		fr.survey_response_id,
		sq.pseudonym,
 		coalesce(fr.text_response,
									cast(fr.numeric_response as varchar),
									cast(fr.date_response as varchar), 
									cast(fr.boolean_response as varchar))
		 as secured_response,
		 fr.survey_question_key,
		 fr.survey_date_key,
		 fr.organization_key,
		 fr.client_key,
		 fr.nurse_key

	   from fact_survey_response			fr  
		inner join dim_survey_question      sq		on fr.survey_question_key			= sq.survey_question_key
		inner join  xref_organization       xo		on fr.organization_key				= xo.organization_key
		inner join  xref_program            xp		on xo.programid						= xp.programid
	  
	  where 
		sq.survey_name = @p_survey_name
		and
		xp.site_id in (select * from survey_views.f_get_sites_for_profile_id(@p_export_profile_id) s)
 
	  group by 
  
		fr.survey_response_id,
		sq.pseudonym,
		coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)),
		 fr.survey_question_key,
		 fr.survey_date_key,
		 fr.organization_key,
		 fr.client_key,
		 fr.nurse_key;

end
else
begin -- in hashing policy so hash if the pseudo matches the policy

	insert into @result
	select 
		fr.survey_response_id,
		sq.pseudonym,
		case
			when (@p_requested_hashing_policy=hpm.policy_codifier) 
			
			then survey_views.f_hash_field( 
								coalesce(fr.text_response,
									cast(fr.numeric_response as varchar),
									cast(fr.date_response as varchar), 
									cast(fr.boolean_response as varchar)))
			
			else 				coalesce(fr.text_response,
									cast(fr.numeric_response as varchar),
									cast(fr.date_response as varchar), 
									cast(fr.boolean_response as varchar))
		 end
		 as secured_response,
		 fr.survey_question_key,
		 fr.survey_date_key,
		 fr.organization_key,
		 fr.client_key,
		 fr.nurse_key


	   from fact_survey_response					fr  
			inner	join dim_survey_question		sq			on fr.survey_question_key			= sq.survey_question_key
			
			left	join (select distinct z.policy_codifier, z.pseudonym
							 from survey_views.pseudo_security z where z.policy_codifier=@p_requested_hashing_policy)			
													hpm			on (hpm.pseudonym = sq.pseudonym )
		inner join  xref_organization       xo		on fr.organization_key				= xo.organization_key
		inner join  xref_program            xp		on xo.programid						= xp.programid

  
	  where 
		sq.survey_name			= @p_survey_name
		and
		xp.site_id in (select * from survey_views.f_get_sites_for_profile_id(@p_export_profile_id) s)

	  group by 
  
		fr.survey_response_id,
		sq.pseudonym,
		coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)),
		hpm.policy_codifier,
		 fr.survey_question_key,
		 fr.survey_date_key,
		 fr.organization_key,
		 fr.client_key,
		 fr.nurse_key;


end;


 
 return;
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Agency_Profile_Update]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Agency_Profile_Update]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID bigint, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
AGENCY_FUNDING01_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING01_1_AMOUNT varchar(256), 
AGENCY_FUNDING01_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING01_1_END_DATE varchar(256), 
AGENCY_FUNDING01_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING01_1_START_DATE varchar(256), 
AGENCY_FUNDING01_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING02_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING02_1_AMOUNT varchar(256), 
AGENCY_FUNDING02_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING02_1_END_DATE varchar(256), 
AGENCY_FUNDING02_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING02_1_START_DATE varchar(256), 
AGENCY_FUNDING02_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING03_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING03_1_AMOUNT varchar(256), 
AGENCY_FUNDING03_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING03_1_END_DATE varchar(256), 
AGENCY_FUNDING03_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING03_1_START_DATE varchar(256), 
AGENCY_FUNDING03_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING04_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING04_1_AMOUNT varchar(256), 
AGENCY_FUNDING04_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING04_1_END_DATE varchar(256), 
AGENCY_FUNDING04_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING04_1_START_DATE varchar(256), 
AGENCY_FUNDING04_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING05_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING05_1_AMOUNT varchar(256), 
AGENCY_FUNDING05_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING05_1_END_DATE varchar(256), 
AGENCY_FUNDING05_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING05_1_START_DATE varchar(256), 
AGENCY_FUNDING05_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING06_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING06_1_AMOUNT varchar(256), 
AGENCY_FUNDING06_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING06_1_END_DATE varchar(256), 
AGENCY_FUNDING06_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING06_1_START_DATE varchar(256), 
AGENCY_FUNDING06_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING07_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING07_1_AMOUNT varchar(256), 
AGENCY_FUNDING07_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING07_1_END_DATE varchar(256), 
AGENCY_FUNDING07_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING07_1_START_DATE varchar(256), 
AGENCY_FUNDING07_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING08_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING08_1_AMOUNT varchar(256), 
AGENCY_FUNDING08_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING08_1_END_DATE varchar(256), 
AGENCY_FUNDING08_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING08_1_START_DATE varchar(256), 
AGENCY_FUNDING08_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING09_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING09_1_AMOUNT varchar(256), 
AGENCY_FUNDING09_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING09_1_END_DATE varchar(256), 
AGENCY_FUNDING09_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING09_1_START_DATE varchar(256), 
AGENCY_FUNDING09_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING10_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING10_1_AMOUNT varchar(256), 
AGENCY_FUNDING10_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING10_1_END_DATE varchar(256), 
AGENCY_FUNDING10_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING10_1_START_DATE varchar(256), 
AGENCY_FUNDING10_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING11_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING11_1_AMOUNT varchar(256), 
AGENCY_FUNDING11_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING11_1_END_DATE varchar(256), 
AGENCY_FUNDING11_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING11_1_START_DATE varchar(256), 
AGENCY_FUNDING11_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING12_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING12_1_AMOUNT varchar(256), 
AGENCY_FUNDING12_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING12_1_END_DATE varchar(256), 
AGENCY_FUNDING12_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING12_1_START_DATE varchar(256), 
AGENCY_FUNDING12_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING13_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING13_1_AMOUNT varchar(256), 
AGENCY_FUNDING13_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING13_1_END_DATE varchar(256), 
AGENCY_FUNDING13_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING13_1_START_DATE varchar(256), 
AGENCY_FUNDING13_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING14_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING14_1_AMOUNT varchar(256), 
AGENCY_FUNDING14_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING14_1_END_DATE varchar(256), 
AGENCY_FUNDING14_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING14_1_START_DATE varchar(256), 
AGENCY_FUNDING14_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING15_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING15_1_AMOUNT varchar(256), 
AGENCY_FUNDING15_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING15_1_END_DATE varchar(256), 
AGENCY_FUNDING15_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING15_1_START_DATE varchar(256), 
AGENCY_FUNDING15_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING16_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING16_1_AMOUNT varchar(256), 
AGENCY_FUNDING16_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING16_1_END_DATE varchar(256), 
AGENCY_FUNDING16_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING16_1_START_DATE varchar(256), 
AGENCY_FUNDING16_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING17_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING17_1_AMOUNT varchar(256), 
AGENCY_FUNDING17_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING17_1_END_DATE varchar(256), 
AGENCY_FUNDING17_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING17_1_START_DATE varchar(256), 
AGENCY_FUNDING17_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING18_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING18_1_AMOUNT varchar(256), 
AGENCY_FUNDING18_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING18_1_END_DATE varchar(256), 
AGENCY_FUNDING18_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING18_1_START_DATE varchar(256), 
AGENCY_FUNDING18_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING19_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING19_1_AMOUNT varchar(256), 
AGENCY_FUNDING19_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING19_1_END_DATE varchar(256), 
AGENCY_FUNDING19_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING19_1_START_DATE varchar(256), 
AGENCY_FUNDING19_MEDICAID_TYPE varchar(256), 
AGENCY_FUNDING20_0_FUNDER_NAME varchar(256), 
AGENCY_FUNDING20_1_AMOUNT varchar(256), 
AGENCY_FUNDING20_1_DF_GRANT_TYPE varchar(256), 
AGENCY_FUNDING20_1_END_DATE varchar(256), 
AGENCY_FUNDING20_1_FUNDER_TYPE varchar(256), 
AGENCY_FUNDING20_1_START_DATE varchar(256), 
AGENCY_FUNDING20_MEDICAID_TYPE varchar(256), 
AGENCY_INFO_1_CONTRACT_CAPACITY_FTE varchar(256), 
AGENCY_INFO_1_FUNDED_CAPACITY_FTE varchar(256), 
AGENCY_INFO_BOARD_0_MEETING_DATE01 varchar(256), 
AGENCY_INFO_BOARD_0_MEETING_DATE02 varchar(256), 
AGENCY_INFO_BOARD_0_MEETING_DATE03 varchar(256), 
AGENCY_INFO_BOARD_0_MEETING_DATE04 varchar(256), 
AGENCY_RESEARCH_0_INVOLVEMENT varchar(256), 
AGENCY_RESEARCH01_0_PROJECT_NAME varchar(256), 
AGENCY_RESEARCH01_1_APPROVAL varchar(256), 
AGENCY_RESEARCH01_1_END_DATE varchar(256), 
AGENCY_RESEARCH01_1_PI1 varchar(256), 
AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION varchar(256), 
AGENCY_RESEARCH01_1_START_DATE varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'AGENCY_FUNDING01_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING01_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING01_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING01_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING01_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING01_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING01_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING02_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING02_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING02_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING02_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING02_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING02_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING02_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING03_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING03_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING03_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING03_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING03_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING03_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING03_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING04_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING04_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING04_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING04_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING04_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING04_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING04_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING05_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING05_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING05_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING05_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING05_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING05_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING05_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING06_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING06_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING06_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING06_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING06_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING06_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING06_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING07_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING07_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING07_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING07_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING07_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING07_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING07_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING08_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING08_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING08_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING08_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING08_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING08_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING08_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING09_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING09_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING09_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING09_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING09_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING09_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING09_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING10_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING10_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING10_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING10_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING10_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING10_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING10_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING11_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING11_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING11_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING11_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING11_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING11_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING11_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING12_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING12_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING12_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING12_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING12_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING12_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING12_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING13_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING13_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING13_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING13_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING13_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING13_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING13_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING14_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING14_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING14_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING14_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING14_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING14_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING14_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING15_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING15_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING15_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING15_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING15_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING15_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING15_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING16_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING16_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING16_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING16_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING16_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING16_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING16_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING17_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING17_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING17_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING17_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING17_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING17_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING17_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING18_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING18_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING18_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING18_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING18_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING18_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING18_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING19_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING19_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING19_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING19_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING19_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING19_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING19_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING20_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING20_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING20_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING20_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING20_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING20_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING20_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_INFO_1_CONTRACT_CAPACITY_FTE ' then  secured_value else null end) as AGENCY_INFO_1_CONTRACT_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_1_FUNDED_CAPACITY_FTE ' then  secured_value else null end) as AGENCY_INFO_1_FUNDED_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE01 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE01,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE02 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE02,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE03 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE03,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE04 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE04,
max(case sq.pseudonym when 'AGENCY_RESEARCH_0_INVOLVEMENT ' then  secured_value else null end) as AGENCY_RESEARCH_0_INVOLVEMENT,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_0_PROJECT_NAME ' then  secured_value else null end) as AGENCY_RESEARCH01_0_PROJECT_NAME,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_APPROVAL ' then  secured_value else null end) as AGENCY_RESEARCH01_1_APPROVAL,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_END_DATE ' then  secured_value else null end) as AGENCY_RESEARCH01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PI1 ' then  secured_value else null end) as AGENCY_RESEARCH01_1_PI1,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION ' then  secured_value else null end) as AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_START_DATE ' then  secured_value else null end) as AGENCY_RESEARCH01_1_START_DATE


   from survey_views.f_secure_fact_survey_response('Agency Profile Update',@p_requested_security_policy,@p_export_profile_id) fr  
 
     inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
   
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;


return;
 
 
 
 end
 
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Alternative_Encounter]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Alternative_Encounter]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
DataSource int, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_ALT_0_COMMENTS_ALT varchar(256), 
CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT varchar(256), 
CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT varchar(256), 
CLIENT_DOMAIN_0_ENVIRONHLTH_ALT varchar(256), 
CLIENT_DOMAIN_0_FRNDFAM_ALT varchar(256), 
CLIENT_DOMAIN_0_LIFECOURSE_ALT varchar(256), 
CLIENT_DOMAIN_0_MATERNAL_ALT varchar(256), 
CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT varchar(256), 
CLIENT_DOMAIN_0_TOTAL_ALT varchar(256), 
CLIENT_NO_REFERRAL varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_SCREENED_SRVCS varchar(256), 
CLIENT_TALKED_0_WITH_ALT varchar(256), 
CLIENT_TALKED_1_WITH_OTHER_ALT varchar(256), 
CLIENT_TIME_0_START_ALT varchar(256), 
CLIENT_TIME_1_DURATION_ALT varchar(256), 
CLIENT_TIME_1_END_ALT varchar(256), 
CLIENT_TIME_FROM_AMPM_ALT varchar(256), 
CLIENT_TIME_FROM_HR_ALT varchar(256), 
CLIENT_TIME_FROM_MIN_ALT varchar(256), 
CLIENT_TIME_TO_AMPM_ALT varchar(256), 
CLIENT_TIME_TO_HR_ALT varchar(256), 
CLIENT_TIME_TO_MIN_ALT varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
AS
BEGIN


insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
	--ss.source_system_name	  
	null as DataSource,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ALT_0_COMMENTS_ALT ' then secured_value else null end) as CLIENT_ALT_0_COMMENTS_ALT,
	max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT ' then secured_value else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT,
	max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT ' then secured_value else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_FRNDFAM_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_LIFECOURSE_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_MATERNAL_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_TOTAL_ALT,
	max(case sq.pseudonym when 'CLIENT_NO_REFERRAL ' then secured_value else null end) as CLIENT_NO_REFERRAL,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS ' then secured_value else null end) as CLIENT_SCREENED_SRVCS,
	max(case sq.pseudonym when 'CLIENT_TALKED_0_WITH_ALT ' then secured_value else null end) as CLIENT_TALKED_0_WITH_ALT,
	max(case sq.pseudonym when 'CLIENT_TALKED_1_WITH_OTHER_ALT ' then secured_value else null end) as CLIENT_TALKED_1_WITH_OTHER_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_0_START_ALT ' then secured_value else null end) as CLIENT_TIME_0_START_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_ALT ' then secured_value else null end) as CLIENT_TIME_1_DURATION_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_END_ALT ' then secured_value else null end) as CLIENT_TIME_1_END_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM_ALT ' then secured_value else null end) as CLIENT_TIME_FROM_AMPM_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR_ALT ' then secured_value else null end) as CLIENT_TIME_FROM_HR_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN_ALT ' then secured_value else null end) as CLIENT_TIME_FROM_MIN_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM_ALT ' then secured_value else null end) as CLIENT_TIME_TO_AMPM_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_HR_ALT ' then secured_value else null end) as CLIENT_TIME_TO_HR_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN_ALT ' then secured_value else null end) as CLIENT_TIME_TO_MIN_ALT,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then secured_value else null end) as NURSE_PERSONAL_0_NAME


   from survey_views.f_secure_fact_survey_response('Alternative Encounter',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    inner  join  dim_nurse              dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
	--inner join dim_source_system		ss on fr.source_system_key			  = ss.source_system_key
  
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
    dc.client_id,
	--ss.source_system_name,
	xp.source_auditdate


	
	RETURN 
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_ASQ3]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_ASQ3]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_AGES_STAGES_1_COMM varchar(256), 
INFANT_AGES_STAGES_1_FMOTOR varchar(256), 
INFANT_AGES_STAGES_1_GMOTOR varchar(256), 
INFANT_AGES_STAGES_1_PSOCIAL varchar(256), 
INFANT_AGES_STAGES_1_PSOLVE varchar(256), 
INFANT_HEALTH_NO_ASQ_COMM varchar(256), 
INFANT_HEALTH_NO_ASQ_FINE varchar(256), 
INFANT_HEALTH_NO_ASQ_GROSS varchar(256), 
INFANT_HEALTH_NO_ASQ_PERSONAL varchar(256), 
INFANT_HEALTH_NO_ASQ_PROBLEM varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY '  then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO '  then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO '  then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM '  then  secured_value else null end) as INFANT_AGES_STAGES_1_COMM,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR '  then  secured_value else null end) as INFANT_AGES_STAGES_1_FMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR '  then  secured_value else null end) as INFANT_AGES_STAGES_1_GMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL '  then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE '  then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOLVE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_COMM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_FINE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

    from survey_views.f_secure_fact_survey_response('ASQ_3',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
    dc.client_id;

return;


end
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Client_and_Infant_Health_or_TCM_Medicaid]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [survey_views].[f_select_Client_and_Infant_Health_or_TCM_Medicaid]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_AGES_STAGES_1_COMM varchar(256), 
INFANT_AGES_STAGES_1_FMOTOR varchar(256), 
INFANT_AGES_STAGES_1_GMOTOR varchar(256), 
INFANT_AGES_STAGES_1_PSOCIAL varchar(256), 
INFANT_AGES_STAGES_1_PSOLVE varchar(256), 
INFANT_HEALTH_NO_ASQ_COMM varchar(256), 
INFANT_HEALTH_NO_ASQ_FINE varchar(256), 
INFANT_HEALTH_NO_ASQ_GROSS varchar(256), 
INFANT_HEALTH_NO_ASQ_PERSONAL varchar(256), 
INFANT_HEALTH_NO_ASQ_PROBLEM varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY '  then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO '  then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO '  then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM '  then  secured_value else null end) as INFANT_AGES_STAGES_1_COMM,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR '  then  secured_value else null end) as INFANT_AGES_STAGES_1_FMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR '  then  secured_value else null end) as INFANT_AGES_STAGES_1_GMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL '  then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE '  then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOLVE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_COMM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_FINE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM '  then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('Client and Infant Health or TCM Medicaid',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

	return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Client_Funding_Source]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Client_Funding_Source]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
	SurveyResponseID int, 
	ElementsProcessed int, 
	SurveyID int, 
	SurveyDate date, 
	AuditDate datetime2, 
	CL_EN_GEN_ID bigint, 
	SiteID int, 
	ProgramID int, 
	IA_StaffID int, 
	ClientID varchar(20), 
	RespondentID int, 
	CLIENT_FUNDING_0_SOURCE_MIECHVP_COM varchar(256), 
	CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM varchar(256), 
	CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER1 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER2 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER3 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER4 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER5 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER6 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_PFS varchar(256), 
	CLIENT_FUNDING_1_END_MIECHVP_COM varchar(256), 
	CLIENT_FUNDING_1_END_MIECHVP_FORM varchar(256), 
	CLIENT_FUNDING_1_END_MIECHVP_TRIBAL varchar(256), 
	CLIENT_FUNDING_1_END_OTHER1 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER2 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER3 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER4 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER5 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER6 varchar(256), 
	CLIENT_FUNDING_1_END_PFS varchar(256), 
	CLIENT_FUNDING_1_START_MIECHVP_COM varchar(256), 
	CLIENT_FUNDING_1_START_MIECHVP_FORM varchar(256), 
	CLIENT_FUNDING_1_START_MIECHVP_TRIBAL varchar(256), 
	CLIENT_FUNDING_1_START_OTHER1 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER2 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER3 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER4 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER5 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER6 varchar(256), 
	CLIENT_FUNDING_1_START_PFS varchar(256), 
	NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result

select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_COM '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER1 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER2 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER3 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER4 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER5 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER6 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_PFS '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_PFS,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_COM '  then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_FORM '  then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_TRIBAL '  then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER1 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER2 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER3 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER4 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER5 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER6 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_PFS '  then  secured_value else null end) as CLIENT_FUNDING_1_END_PFS,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_COM '  then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_FORM '  then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_TRIBAL '  then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER1 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER2 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER3 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER4 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER5 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER6 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_PFS '  then  secured_value else null end) as CLIENT_FUNDING_1_START_PFS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response( 'Client Funding Source',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  

  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Clinical_IPV_Assessment]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Clinical_IPV_Assessment]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
	SurveyResponseID int, 
	ElementsProcessed int, 
	SurveyID int, 
	SurveyDate date, 
	AuditDate datetime2, 
	CL_EN_GEN_ID bigint, 
	SiteID int, 
	ProgramID int, 
	IA_StaffID int, 
	ClientID varchar(20), 
	RespondentID int, 
	CLIENT_0_ID_NSO varchar(256), 
	CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
	CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
	CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
	IPV_AFRAID varchar(256), 
	IPV_CHILD_SAFETY varchar(256), 
	IPV_CONTROLING varchar(256), 
	IPV_FORCED_SEX varchar(256), 
	IPV_INDICATED varchar(256), 
	IPV_INSULTED varchar(256), 
	IPV_PHYSICALLY_HURT varchar(256), 
	IPV_PRN_REASON varchar(256), 
	IPV_Q1_4_SCORE varchar(256), 
	IPV_SCREAMED varchar(256), 
	IPV_THREATENED varchar(256), 
	IPV_TOOL_USED varchar(256), 
	NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO '  then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE '  then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST  '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST ,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'IPV_AFRAID '  then  secured_value else null end) as IPV_AFRAID,
	max(case sq.pseudonym when 'IPV_CHILD_SAFETY '  then  secured_value else null end) as IPV_CHILD_SAFETY,
	max(case sq.pseudonym when 'IPV_CONTROLING '  then  secured_value else null end) as IPV_CONTROLING,
	max(case sq.pseudonym when 'IPV_FORCED_SEX '  then  secured_value else null end) as IPV_FORCED_SEX,
	max(case sq.pseudonym when 'IPV_INDICATED '  then  secured_value else null end) as IPV_INDICATED,
	max(case sq.pseudonym when 'IPV_INSULTED '  then  secured_value else null end) as IPV_INSULTED,
	max(case sq.pseudonym when 'IPV_PHYSICALLY_HURT '  then  secured_value else null end) as IPV_PHYSICALLY_HURT,
	max(case sq.pseudonym when 'IPV_PRN_REASON '  then  secured_value else null end) as IPV_PRN_REASON,
	max(case sq.pseudonym when 'IPV_Q1_4_SCORE '  then  secured_value else null end) as IPV_Q1_4_SCORE,
	max(case sq.pseudonym when 'IPV_SCREAMED '  then  secured_value else null end) as IPV_SCREAMED,
	max(case sq.pseudonym when 'IPV_THREATENED '  then  secured_value else null end) as IPV_THREATENED,
	max(case sq.pseudonym when 'IPV_TOOL_USED '  then  secured_value else null end) as IPV_TOOL_USED,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('Clinical IPV Assessment',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Community_Advisory_Board_Meeting]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Community_Advisory_Board_Meeting]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CAB_MTG_DATE varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CAB_MTG_DATE '  then  secured_value else null end) as CAB_MTG_DATE


     from survey_views.f_secure_fact_survey_response('Community Advisory Board Meeting',@p_requested_security_policy,@p_export_profile_id) fr   
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

	return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Course_Completion]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Course_Completion]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
[COURSE_COMPLETION_0_DATE1-11] varchar(256), 
[COURSE_COMPLETION_0_NAME1-11] varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'COURSE_COMPLETION_0_DATE1-11 '  then  secured_value else null end) as [COURSE_COMPLETION_0_DATE1-11],
	max(case sq.pseudonym when 'COURSE_COMPLETION_0_NAME1-11 '  then  secured_value else null end) as [COURSE_COMPLETION_0_NAME1-11]

      from survey_views.f_secure_fact_survey_response( 'Course Completion', @p_requested_security_policy, @p_export_profile_id) fr  

   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_DANCE_Coding_Sheet]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_select_DANCE_Coding_Sheet]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_ACTIVITY_DURATION varchar(256), 
CLIENT_CAC_COMMENTS varchar(256), 
CLIENT_CAC_NA varchar(256), 
CLIENT_CAC_PER varchar(256), 
CLIENT_CHILD_AGE varchar(256), 
CLIENT_CHILD_DURATION varchar(256), 
CLIENT_CI_COMMENTS varchar(256), 
CLIENT_CI_NA varchar(256), 
CLIENT_CI_PER varchar(256), 
CLIENT_EPA_COMMENTS varchar(256), 
CLIENT_EPA_NA varchar(256), 
CLIENT_EPA_PER varchar(256), 
CLIENT_LS_COMMENTS varchar(256), 
CLIENT_LS_NA varchar(256), 
CLIENT_LS_PER varchar(256), 
CLIENT_NCCO_COMMENTS varchar(256), 
CLIENT_NCCO_NA varchar(256), 
CLIENT_NCCO_PER varchar(256), 
CLIENT_NI_COMMENTS varchar(256), 
CLIENT_NI_NA varchar(256), 
CLIENT_NI_PER varchar(256), 
CLIENT_NT_COMMENTS varchar(256), 
CLIENT_NT_NA varchar(256), 
CLIENT_NT_PER varchar(256), 
CLIENT_NVC_COMMENTS varchar(256), 
CLIENT_NVC_NA varchar(256), 
CLIENT_NVC_PER varchar(256), 
CLIENT_PC_COMMENTS varchar(256), 
CLIENT_PC_NA varchar(256), 
CLIENT_PC_PER varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_PO_COMMENTS varchar(256), 
CLIENT_PO_NA varchar(256), 
CLIENT_PO_PER varchar(256), 
CLIENT_PRA_COMMENTS varchar(256), 
CLIENT_PRA_NA varchar(256), 
CLIENT_PRA_PER varchar(256), 
CLIENT_RD_COMMENTS varchar(256), 
CLIENT_RD_NA varchar(256), 
CLIENT_RD_PER varchar(256), 
CLIENT_RP_COMMENTS varchar(256), 
CLIENT_RP_NA varchar(256), 
CLIENT_RP_PER varchar(256), 
CLIENT_SCA_COMMENTS varchar(256), 
CLIENT_SCA_NA varchar(256), 
CLIENT_SCA_PER varchar(256), 
CLIENT_SE_COMMENTS varchar(256), 
CLIENT_SE_NA varchar(256), 
CLIENT_SE_PER varchar(256), 
CLIENT_VE_COMMENTS varchar(256), 
CLIENT_VE_NA varchar(256), 
CLIENT_VE_PER varchar(256), 
CLIENT_VEC_COMMENTS varchar(256), 
CLIENT_VEC_NA varchar(256), 
CLIENT_VEC_PER varchar(256), 
CLIENT_VISIT_VARIABLES varchar(256), 
CLIENT_VQ_COMMENTS varchar(256), 
CLIENT_VQ_NA varchar(256), 
CLIENT_VQ_PER varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO '  then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ACTIVITY_DURATION '  then  secured_value else null end) as CLIENT_ACTIVITY_DURATION,
	max(case sq.pseudonym when 'CLIENT_CAC_COMMENTS '  then  secured_value else null end) as CLIENT_CAC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_CAC_NA '  then  secured_value else null end) as CLIENT_CAC_NA,
	max(case sq.pseudonym when 'CLIENT_CAC_PER '  then  secured_value else null end) as CLIENT_CAC_PER,
	max(case sq.pseudonym when 'CLIENT_CHILD_AGE '  then  secured_value else null end) as CLIENT_CHILD_AGE,
	max(case sq.pseudonym when 'CLIENT_CHILD_DURATION '  then  secured_value else null end) as CLIENT_CHILD_DURATION,
	max(case sq.pseudonym when 'CLIENT_CI_COMMENTS '  then  secured_value else null end) as CLIENT_CI_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_CI_NA '  then  secured_value else null end) as CLIENT_CI_NA,
	max(case sq.pseudonym when 'CLIENT_CI_PER '  then  secured_value else null end) as CLIENT_CI_PER,
	max(case sq.pseudonym when 'CLIENT_EPA_COMMENTS '  then  secured_value else null end) as CLIENT_EPA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_EPA_NA '  then  secured_value else null end) as CLIENT_EPA_NA,
	max(case sq.pseudonym when 'CLIENT_EPA_PER '  then  secured_value else null end) as CLIENT_EPA_PER,
	max(case sq.pseudonym when 'CLIENT_LS_COMMENTS '  then  secured_value else null end) as CLIENT_LS_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_LS_NA '  then  secured_value else null end) as CLIENT_LS_NA,
	max(case sq.pseudonym when 'CLIENT_LS_PER '  then  secured_value else null end) as CLIENT_LS_PER,
	max(case sq.pseudonym when 'CLIENT_NCCO_COMMENTS '  then  secured_value else null end) as CLIENT_NCCO_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NCCO_NA '  then  secured_value else null end) as CLIENT_NCCO_NA,
	max(case sq.pseudonym when 'CLIENT_NCCO_PER '  then  secured_value else null end) as CLIENT_NCCO_PER,
	max(case sq.pseudonym when 'CLIENT_NI_COMMENTS '  then  secured_value else null end) as CLIENT_NI_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NI_NA '  then  secured_value else null end) as CLIENT_NI_NA,
	max(case sq.pseudonym when 'CLIENT_NI_PER '  then  secured_value else null end) as CLIENT_NI_PER,
	max(case sq.pseudonym when 'CLIENT_NT_COMMENTS '  then  secured_value else null end) as CLIENT_NT_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NT_NA '  then  secured_value else null end) as CLIENT_NT_NA,
	max(case sq.pseudonym when 'CLIENT_NT_PER '  then  secured_value else null end) as CLIENT_NT_PER,
	max(case sq.pseudonym when 'CLIENT_NVC_COMMENTS '  then  secured_value else null end) as CLIENT_NVC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NVC_NA '  then  secured_value else null end) as CLIENT_NVC_NA,
	max(case sq.pseudonym when 'CLIENT_NVC_PER '  then  secured_value else null end) as CLIENT_NVC_PER,
	max(case sq.pseudonym when 'CLIENT_PC_COMMENTS '  then  secured_value else null end) as CLIENT_PC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PC_NA '  then  secured_value else null end) as CLIENT_PC_NA,
	max(case sq.pseudonym when 'CLIENT_PC_PER '  then  secured_value else null end) as CLIENT_PC_PER,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PO_COMMENTS '  then  secured_value else null end) as CLIENT_PO_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PO_NA '  then  secured_value else null end) as CLIENT_PO_NA,
	max(case sq.pseudonym when 'CLIENT_PO_PER '  then  secured_value else null end) as CLIENT_PO_PER,
	max(case sq.pseudonym when 'CLIENT_PRA_COMMENTS '  then  secured_value else null end) as CLIENT_PRA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PRA_NA '  then  secured_value else null end) as CLIENT_PRA_NA,
	max(case sq.pseudonym when 'CLIENT_PRA_PER '  then  secured_value else null end) as CLIENT_PRA_PER,
	max(case sq.pseudonym when 'CLIENT_RD_COMMENTS '  then  secured_value else null end) as CLIENT_RD_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_RD_NA '  then  secured_value else null end) as CLIENT_RD_NA,
	max(case sq.pseudonym when 'CLIENT_RD_PER '  then  secured_value else null end) as CLIENT_RD_PER,
	max(case sq.pseudonym when 'CLIENT_RP_COMMENTS '  then  secured_value else null end) as CLIENT_RP_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_RP_NA '  then  secured_value else null end) as CLIENT_RP_NA,
	max(case sq.pseudonym when 'CLIENT_RP_PER '  then  secured_value else null end) as CLIENT_RP_PER,
	max(case sq.pseudonym when 'CLIENT_SCA_COMMENTS '  then  secured_value else null end) as CLIENT_SCA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_SCA_NA '  then  secured_value else null end) as CLIENT_SCA_NA,
	max(case sq.pseudonym when 'CLIENT_SCA_PER '  then  secured_value else null end) as CLIENT_SCA_PER,
	max(case sq.pseudonym when 'CLIENT_SE_COMMENTS '  then  secured_value else null end) as CLIENT_SE_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_SE_NA '  then  secured_value else null end) as CLIENT_SE_NA,
	max(case sq.pseudonym when 'CLIENT_SE_PER '  then  secured_value else null end) as CLIENT_SE_PER,
	max(case sq.pseudonym when 'CLIENT_VE_COMMENTS '  then  secured_value else null end) as CLIENT_VE_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VE_NA '  then  secured_value else null end) as CLIENT_VE_NA,
	max(case sq.pseudonym when 'CLIENT_VE_PER '  then  secured_value else null end) as CLIENT_VE_PER,
	max(case sq.pseudonym when 'CLIENT_VEC_COMMENTS '  then  secured_value else null end) as CLIENT_VEC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VEC_NA '  then  secured_value else null end) as CLIENT_VEC_NA,
	max(case sq.pseudonym when 'CLIENT_VEC_PER '  then  secured_value else null end) as CLIENT_VEC_PER,
	max(case sq.pseudonym when 'CLIENT_VISIT_VARIABLES '  then  secured_value else null end) as CLIENT_VISIT_VARIABLES,
	max(case sq.pseudonym when 'CLIENT_VQ_COMMENTS '  then  secured_value else null end) as CLIENT_VQ_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VQ_NA '  then  secured_value else null end) as CLIENT_VQ_NA,
	max(case sq.pseudonym when 'CLIENT_VQ_PER '  then  secured_value else null end) as CLIENT_VQ_PER,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('DANCE Coding Sheet',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

RETURN;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Demographics]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [survey_views].[f_select_Demographics]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
	SurveyResponseID bigint, 
	ElementsProcessed int, 
	SurveyID int, 
	SurveyDate date, 
	AuditDate datetime2, 
	CL_EN_GEN_ID bigint, 
	SiteID int, 
	ProgramID int, 
	IA_StaffID int, 
	ClientID varchar(20), 
	RespondentID int, 
	ADULTS_1_CARE_10 varchar(256), 
	ADULTS_1_CARE_20 varchar(256), 
	ADULTS_1_CARE_30 varchar(256), 
	ADULTS_1_CARE_40 varchar(256), 
	ADULTS_1_CARE_LESS10 varchar(256), 
	ADULTS_1_COMPLETE_GED varchar(256), 
	ADULTS_1_COMPLETE_HS varchar(256), 
	ADULTS_1_COMPLETE_HS_NO varchar(256), 
	ADULTS_1_ED_ASSOCIATE varchar(256), 
	ADULTS_1_ED_BACHELOR varchar(256), 
	ADULTS_1_ED_MASTER varchar(256), 
	ADULTS_1_ED_NONE varchar(256), 
	ADULTS_1_ED_POSTGRAD varchar(256), 
	ADULTS_1_ED_SOME_COLLEGE varchar(256), 
	ADULTS_1_ED_TECH varchar(256), 
	ADULTS_1_ED_UNKNOWN varchar(256), 
	ADULTS_1_ENROLL_FT varchar(256), 
	ADULTS_1_ENROLL_NO varchar(256), 
	ADULTS_1_ENROLL_PT varchar(256), 
	ADULTS_1_INS_NO varchar(256), 
	ADULTS_1_INS_PRIVATE varchar(256), 
	ADULTS_1_INS_PUBLIC varchar(256), 
	ADULTS_1_WORK_10 varchar(256), 
	ADULTS_1_WORK_20 varchar(256), 
	ADULTS_1_WORK_37 varchar(256), 
	ADULTS_1_WORK_LESS10 varchar(256), 
	ADULTS_1_WORK_UNEMPLOY varchar(256), 
	CLIENT_0_ID_AGENCY varchar(256), 
	CLIENT_0_ID_NSO varchar(256), 
	CLIENT_BIO_DAD_0_CONTACT_WITH varchar(256), 
	CLIENT_CARE_0_URGENT_OTHER varchar(256), 
	CLIENT_CARE_0_ER varchar(256), 
	CLIENT_CARE_0_ER_FEVER_TIMES varchar(256), 
	CLIENT_CARE_0_ER_HOSP varchar(256), 
	CLIENT_CARE_0_ER_INFECTION_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INGESTION_SELF_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INGESTION_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INJURY_SELF_TIMES varchar(256), 
	CLIENT_CARE_0_ER_INJURY_TIMES varchar(256), 
	CLIENT_CARE_0_ER_OTHER varchar(256), 
	CLIENT_CARE_0_ER_OTHER_TIMES varchar(256), 
	CLIENT_CARE_0_ER_PURPOSE varchar(256), 
	CLIENT_CARE_0_ER_PURPOSE_R6 varchar(256), 
	CLIENT_CARE_0_ER_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT varchar(256), 
	CLIENT_CARE_0_URGENT_FEVER_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INFECTION_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INGESTION_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_INJURY_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_OTHER_TIMES varchar(256), 
	CLIENT_CARE_0_URGENT_PURPOSE varchar(256), 
	CLIENT_CARE_0_URGENT_PURPOSE_R6 varchar(256), 
	CLIENT_CARE_0_URGENT_TIMES varchar(256), 
	CLIENT_ED_PROG_TYPE varchar(256), 
	CLIENT_EDUCATION_0_HS_GED varchar(256), 
	CLIENT_EDUCATION_1_ENROLLED_CURRENT varchar(256), 
	CLIENT_EDUCATION_1_ENROLLED_FTPT varchar(256), 
	CLIENT_EDUCATION_1_ENROLLED_PLAN varchar(256), 
	CLIENT_EDUCATION_1_ENROLLED_PT_HRS varchar(256), 
	CLIENT_EDUCATION_1_ENROLLED_TYPE varchar(256), 
	CLIENT_EDUCATION_1_HIGHER_EDUC_COMP varchar(256), 
	CLIENT_EDUCATION_1_HS_GED_LAST_GRADE varchar(256), 
	CLIENT_INCOME_0_HH_INCOME varchar(256), 
	CLIENT_INCOME_1_HH_SOURCES varchar(256), 
	CLIENT_INCOME_1_LOW_INCOME_QUALIFY varchar(256), 
	CLIENT_INCOME_AMOUNT varchar(256), 
	CLIENT_INCOME_IN_KIND varchar(256), 
	CLIENT_INCOME_INKIND_OTHER varchar(256), 
	CLIENT_INCOME_OTHER_SOURCES varchar(256), 
	CLIENT_INCOME_SOURCES varchar(256), 
	CLIENT_INSURANCE varchar(256), 
	CLIENT_INSURANCE_OTHER varchar(256), 
	CLIENT_INSURANCE_TYPE varchar(256), 
	CLIENT_LIVING_0_WITH varchar(256), 
	CLIENT_LIVING_1_WITH_OTHERS varchar(256), 
	CLIENT_LIVING_HOMELESS varchar(256), 
	CLIENT_LIVING_WHERE varchar(256), 
	CLIENT_MARITAL_0_STATUS varchar(256), 
	CLIENT_MILITARY varchar(256), 
	CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
	CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
	CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
	CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED varchar(256), 
	CLIENT_PROVIDE_CHILDCARE varchar(256), 
	CLIENT_SCHOOL_MIDDLE_HS varchar(256), 
	CLIENT_WORKING_0_CURRENTLY_WORKING varchar(256), 
	CLIENT_WORKING_1_CURRENTLY_WORKING_HRS varchar(256), 
	CLIENT_WORKING_1_CURRENTLY_WORKING_NO varchar(256), 
	NURSE_PERSONAL_0_NAME varchar(256)
)
AS
BEGIN


insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'ADULTS_1_CARE_10 ' then  secured_value  else null end) as ADULTS_1_CARE_10,
	max(case sq.pseudonym when 'ADULTS_1_CARE_20 ' then  secured_value  else null end) as ADULTS_1_CARE_20,
	max(case sq.pseudonym when 'ADULTS_1_CARE_30 ' then  secured_value  else null end) as ADULTS_1_CARE_30,
	max(case sq.pseudonym when 'ADULTS_1_CARE_40 ' then  secured_value  else null end) as ADULTS_1_CARE_40,
	max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10 ' then  secured_value  else null end) as ADULTS_1_CARE_LESS10,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED ' then  secured_value  else null end) as ADULTS_1_COMPLETE_GED,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS ' then  secured_value  else null end) as ADULTS_1_COMPLETE_HS,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO ' then  secured_value  else null end) as ADULTS_1_COMPLETE_HS_NO,
	max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE ' then  secured_value  else null end) as ADULTS_1_ED_ASSOCIATE,
	max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR ' then  secured_value  else null end) as ADULTS_1_ED_BACHELOR,
	max(case sq.pseudonym when 'ADULTS_1_ED_MASTER ' then  secured_value  else null end) as ADULTS_1_ED_MASTER,
	max(case sq.pseudonym when 'ADULTS_1_ED_NONE ' then  secured_value  else null end) as ADULTS_1_ED_NONE,
	max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD ' then  secured_value  else null end) as ADULTS_1_ED_POSTGRAD,
	max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE ' then  secured_value  else null end) as ADULTS_1_ED_SOME_COLLEGE,
	max(case sq.pseudonym when 'ADULTS_1_ED_TECH ' then  secured_value  else null end) as ADULTS_1_ED_TECH,
	max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN ' then  secured_value  else null end) as ADULTS_1_ED_UNKNOWN,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT ' then  secured_value  else null end) as ADULTS_1_ENROLL_FT,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO ' then  secured_value  else null end) as ADULTS_1_ENROLL_NO,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT ' then  secured_value  else null end) as ADULTS_1_ENROLL_PT,
	max(case sq.pseudonym when 'ADULTS_1_INS_NO ' then  secured_value  else null end) as ADULTS_1_INS_NO,
	max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE ' then  secured_value  else null end) as ADULTS_1_INS_PRIVATE,
	max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC ' then  secured_value  else null end) as ADULTS_1_INS_PUBLIC,
	max(case sq.pseudonym when 'ADULTS_1_WORK_10 ' then  secured_value  else null end) as ADULTS_1_WORK_10,
	max(case sq.pseudonym when 'ADULTS_1_WORK_20 ' then  secured_value  else null end) as ADULTS_1_WORK_20,
	max(case sq.pseudonym when 'ADULTS_1_WORK_37 ' then  secured_value  else null end) as ADULTS_1_WORK_37,
	max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10 ' then  secured_value  else null end) as ADULTS_1_WORK_LESS10,
	max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY ' then  secured_value  else null end) as ADULTS_1_WORK_UNEMPLOY,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value  else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value  else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH ' then  secured_value  else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ URGENT_OTHER ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_OTHER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER ' then  secured_value  else null end) as CLIENT_CARE_0_ER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP ' then  secured_value  else null end) as CLIENT_CARE_0_ER_HOSP,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER ' then  secured_value  else null end) as CLIENT_CARE_0_ER_OTHER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE ' then  secured_value  else null end) as CLIENT_CARE_0_ER_PURPOSE,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6 ' then  secured_value  else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6 ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE ' then  secured_value  else null end) as CLIENT_ED_PROG_TYPE,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED ' then  secured_value  else null end) as CLIENT_EDUCATION_0_HS_GED,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP ' then  secured_value  else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE ' then  secured_value  else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
	max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME ' then  secured_value  else null end) as CLIENT_INCOME_0_HH_INCOME,
	max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES ' then  secured_value  else null end) as CLIENT_INCOME_1_HH_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY ' then  secured_value  else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
	max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT ' then  secured_value  else null end) as CLIENT_INCOME_AMOUNT,
	max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND ' then  secured_value  else null end) as CLIENT_INCOME_IN_KIND,
	max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER ' then  secured_value  else null end) as CLIENT_INCOME_INKIND_OTHER,
	max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES ' then  secured_value  else null end) as CLIENT_INCOME_OTHER_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES ' then  secured_value  else null end) as CLIENT_INCOME_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INSURANCE ' then  secured_value  else null end) as CLIENT_INSURANCE,
	max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER ' then  secured_value  else null end) as CLIENT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE ' then  secured_value  else null end) as CLIENT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH ' then  secured_value  else null end) as CLIENT_LIVING_0_WITH,
	max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS ' then  secured_value  else null end) as CLIENT_LIVING_1_WITH_OTHERS,
	max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS ' then  secured_value  else null end) as CLIENT_LIVING_HOMELESS,
	max(case sq.pseudonym when 'CLIENT_LIVING_WHERE ' then  secured_value  else null end) as CLIENT_LIVING_WHERE,
	max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS ' then  secured_value  else null end) as CLIENT_MARITAL_0_STATUS,
	max(case sq.pseudonym when 'CLIENT_MILITARY ' then  secured_value  else null end) as CLIENT_MILITARY,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value  else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value  else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value  else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED ' then  secured_value  else null end) as CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED,
	max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE ' then  secured_value  else null end) as CLIENT_PROVIDE_CHILDCARE,
	max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS ' then  secured_value  else null end) as CLIENT_SCHOOL_MIDDLE_HS,
	max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING ' then  secured_value  else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
	max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS ' then  secured_value  else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
	max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO ' then  secured_value  else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value  else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('Demographics',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;




	
	RETURN 
END
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Demographics_Update]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Demographics_Update]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
ADULTS_1_CARE_10 varchar(256), 
ADULTS_1_CARE_20 varchar(256), 
ADULTS_1_CARE_30 varchar(256), 
ADULTS_1_CARE_40 varchar(256), 
ADULTS_1_CARE_LESS10 varchar(256), 
ADULTS_1_COMPLETE_GED varchar(256), 
ADULTS_1_COMPLETE_HS varchar(256), 
ADULTS_1_COMPLETE_HS_NO varchar(256), 
ADULTS_1_ED_ASSOCIATE varchar(256), 
ADULTS_1_ED_BACHELOR varchar(256), 
ADULTS_1_ED_MASTER varchar(256), 
ADULTS_1_ED_NONE varchar(256), 
ADULTS_1_ED_POSTGRAD varchar(256), 
ADULTS_1_ED_SOME_COLLEGE varchar(256), 
ADULTS_1_ED_TECH varchar(256), 
ADULTS_1_ED_UNKNOWN varchar(256), 
ADULTS_1_ENROLL_FT varchar(256), 
ADULTS_1_ENROLL_NO varchar(256), 
ADULTS_1_ENROLL_PT varchar(256), 
ADULTS_1_INS_NO varchar(256), 
ADULTS_1_INS_PRIVATE varchar(256), 
ADULTS_1_INS_PUBLIC varchar(256), 
ADULTS_1_WORK_10 varchar(256), 
ADULTS_1_WORK_20 varchar(256), 
ADULTS_1_WORK_37 varchar(256), 
ADULTS_1_WORK_LESS10 varchar(256), 
ADULTS_1_WORK_UNEMPLOY varchar(256), 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_BC_0_USED_6MONTHS varchar(256), 
CLIENT_BC_1_FREQUENCY varchar(256), 
CLIENT_BC_1_NOT_USED_REASON varchar(256), 
CLIENT_BC_1_TYPES varchar(256), 
CLIENT_BC_1_TYPES_NEXT6 varchar(256), 
CLIENT_BIO_DAD_0_CONTACT_WITH varchar(256), 
CLIENT_BIO_DAD_1_TIME_WITH varchar(256), 
CLIENT_CARE_0_ER varchar(256), 
CLIENT_CARE_0_ER_FEVER_TIMES varchar(256), 
CLIENT_CARE_0_ER_HOSP varchar(256), 
CLIENT_CARE_0_ER_INFECTION_TIMES varchar(256), 
CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES varchar(256), 
CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES varchar(256), 
CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES varchar(256), 
CLIENT_CARE_0_ER_INGESTION_SELF_TIMES varchar(256), 
CLIENT_CARE_0_ER_INGESTION_TIMES varchar(256), 
CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES varchar(256), 
CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES varchar(256), 
CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES varchar(256), 
CLIENT_CARE_0_ER_INJURY_SELF_TIMES varchar(256), 
CLIENT_CARE_0_ER_INJURY_TIMES varchar(256), 
CLIENT_CARE_0_ER_OTHER varchar(256), 
CLIENT_CARE_0_ER_OTHER_TIMES varchar(256), 
CLIENT_CARE_0_ER_PURPOSE varchar(256), 
CLIENT_CARE_0_ER_PURPOSE_R6 varchar(256), 
CLIENT_CARE_0_ER_TIMES varchar(256), 
CLIENT_CARE_0_URGENT varchar(256), 
CLIENT_CARE_0_URGENT_FEVER_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INFECTION_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INGESTION_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_INJURY_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_OTHER varchar(256), 
CLIENT_CARE_0_URGENT_OTHER_TIMES varchar(256), 
CLIENT_CARE_0_URGENT_PURPOSE varchar(256), 
CLIENT_CARE_0_URGENT_PURPOSE_R6 varchar(256), 
CLIENT_CARE_0_URGENT_TIMES varchar(256), 
CLIENT_ED_PROG_TYPE varchar(256), 
CLIENT_EDUCATION_0_HS_GED varchar(256), 
CLIENT_EDUCATION_1_ENROLLED_CURRENT varchar(256), 
CLIENT_EDUCATION_1_ENROLLED_FTPT varchar(256), 
CLIENT_EDUCATION_1_ENROLLED_PLAN varchar(256), 
CLIENT_EDUCATION_1_ENROLLED_PT_HRS varchar(256), 
CLIENT_EDUCATION_1_ENROLLED_TYPE varchar(256), 
CLIENT_EDUCATION_1_HIGHER_EDUC_COMP varchar(256), 
CLIENT_EDUCATION_1_HS_GED_LAST_GRADE varchar(256), 
CLIENT_INCOME_0_HH_INCOME varchar(256), 
CLIENT_INCOME_1_HH_SOURCES varchar(256), 
CLIENT_INCOME_1_LOW_INCOME_QUALIFY varchar(256), 
CLIENT_INCOME_AMOUNT varchar(256), 
CLIENT_INCOME_IN_KIND varchar(256), 
CLIENT_INCOME_INKIND_OTHER varchar(256), 
CLIENT_INCOME_OTHER_SOURCES varchar(256), 
CLIENT_INCOME_SOURCES varchar(256), 
CLIENT_INSURANCE varchar(256), 
CLIENT_INSURANCE_OTHER varchar(256), 
CLIENT_INSURANCE_TYPE varchar(256), 
CLIENT_LIVING_0_WITH varchar(256), 
CLIENT_LIVING_1_WITH_OTHERS varchar(256), 
CLIENT_LIVING_HOMELESS varchar(256), 
CLIENT_LIVING_WHERE varchar(256), 
CLIENT_MARITAL_0_STATUS varchar(256), 
CLIENT_MILITARY varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_PROVIDE_CHILDCARE varchar(256), 
CLIENT_SCHOOL_MIDDLE_HS varchar(256), 
CLIENT_SECOND_0_CHILD_DOB varchar(256), 
CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS varchar(256), 
CLIENT_SECOND_1_CHILD_BW_GRAMS varchar(256), 
CLIENT_SECOND_1_CHILD_BW_MEASURE varchar(256), 
CLIENT_SECOND_1_CHILD_BW_OZ varchar(256), 
CLIENT_SECOND_1_CHILD_BW_POUNDS varchar(256), 
CLIENT_SECOND_1_CHILD_GENDER varchar(256), 
CLIENT_SECOND_1_CHILD_NICU varchar(256), 
CLIENT_SECOND_1_CHILD_NICU_DAYS varchar(256), 
CLIENT_SUBPREG varchar(256), 
CLIENT_SUBPREG_0_BEEN_PREGNANT varchar(256), 
CLIENT_SUBPREG_1_BEGIN_MONTH varchar(256), 
CLIENT_SUBPREG_1_BEGIN_YEAR varchar(256), 
CLIENT_SUBPREG_1_EDD varchar(256), 
CLIENT_SUBPREG_1_GEST_AGE varchar(256), 
CLIENT_SUBPREG_1_OUTCOME varchar(256), 
CLIENT_SUBPREG_1_PLANNED varchar(256), 
CLIENT_WORKING_0_CURRENTLY_WORKING varchar(256), 
CLIENT_WORKING_1_CURRENTLY_WORKING_HRS varchar(256), 
CLIENT_WORKING_1_CURRENTLY_WORKING_NO varchar(256), 
CLIENT_WORKING_1_WORKED_SINCE_BIRTH varchar(256), 
CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'ADULTS_1_CARE_10 ' then  secured_value else null end) as ADULTS_1_CARE_10,
max(case sq.pseudonym when 'ADULTS_1_CARE_20 ' then  secured_value else null end) as ADULTS_1_CARE_20,
max(case sq.pseudonym when 'ADULTS_1_CARE_30 ' then  secured_value else null end) as ADULTS_1_CARE_30,
max(case sq.pseudonym when 'ADULTS_1_CARE_40 ' then  secured_value else null end) as ADULTS_1_CARE_40,
max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10 ' then  secured_value else null end) as ADULTS_1_CARE_LESS10,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED ' then  secured_value else null end) as ADULTS_1_COMPLETE_GED,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS ' then  secured_value else null end) as ADULTS_1_COMPLETE_HS,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO ' then  secured_value else null end) as ADULTS_1_COMPLETE_HS_NO,
max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE ' then  secured_value else null end) as ADULTS_1_ED_ASSOCIATE,
max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR ' then  secured_value else null end) as ADULTS_1_ED_BACHELOR,
max(case sq.pseudonym when 'ADULTS_1_ED_MASTER ' then  secured_value else null end) as ADULTS_1_ED_MASTER,
max(case sq.pseudonym when 'ADULTS_1_ED_NONE ' then  secured_value else null end) as ADULTS_1_ED_NONE,
max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD ' then  secured_value else null end) as ADULTS_1_ED_POSTGRAD,
max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE ' then  secured_value else null end) as ADULTS_1_ED_SOME_COLLEGE,
max(case sq.pseudonym when 'ADULTS_1_ED_TECH ' then  secured_value else null end) as ADULTS_1_ED_TECH,
max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN ' then  secured_value else null end) as ADULTS_1_ED_UNKNOWN,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT ' then  secured_value else null end) as ADULTS_1_ENROLL_FT,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO ' then  secured_value else null end) as ADULTS_1_ENROLL_NO,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT ' then  secured_value else null end) as ADULTS_1_ENROLL_PT,
max(case sq.pseudonym when 'ADULTS_1_INS_NO ' then  secured_value else null end) as ADULTS_1_INS_NO,
max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE ' then  secured_value else null end) as ADULTS_1_INS_PRIVATE,
max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC ' then  secured_value else null end) as ADULTS_1_INS_PUBLIC,
max(case sq.pseudonym when 'ADULTS_1_WORK_10 ' then  secured_value else null end) as ADULTS_1_WORK_10,
max(case sq.pseudonym when 'ADULTS_1_WORK_20 ' then  secured_value else null end) as ADULTS_1_WORK_20,
max(case sq.pseudonym when 'ADULTS_1_WORK_37 ' then  secured_value else null end) as ADULTS_1_WORK_37,
max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10 ' then  secured_value else null end) as ADULTS_1_WORK_LESS10,
max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY ' then  secured_value else null end) as ADULTS_1_WORK_UNEMPLOY,
max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_BC_0_USED_6MONTHS ' then  secured_value else null end) as CLIENT_BC_0_USED_6MONTHS,
max(case sq.pseudonym when 'CLIENT_BC_1_FREQUENCY ' then  secured_value else null end) as CLIENT_BC_1_FREQUENCY,
max(case sq.pseudonym when 'CLIENT_BC_1_NOT_USED_REASON ' then  secured_value else null end) as CLIENT_BC_1_NOT_USED_REASON,
max(case sq.pseudonym when 'CLIENT_BC_1_TYPES ' then  secured_value else null end) as CLIENT_BC_1_TYPES,
max(case sq.pseudonym when 'CLIENT_BC_1_TYPES_NEXT6 ' then  secured_value else null end) as CLIENT_BC_1_TYPES_NEXT6,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH ' then  secured_value else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_1_TIME_WITH ' then  secured_value else null end) as CLIENT_BIO_DAD_1_TIME_WITH,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER ' then  secured_value else null end) as CLIENT_CARE_0_ER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP ' then  secured_value else null end) as CLIENT_CARE_0_ER_HOSP,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER ' then  secured_value else null end) as CLIENT_CARE_0_ER_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE ' then  secured_value else null end) as CLIENT_CARE_0_ER_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6 ' then  secured_value else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_ER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT ' then  secured_value else null end) as CLIENT_CARE_0_URGENT,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6 ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES ' then  secured_value else null end) as CLIENT_CARE_0_URGENT_TIMES,
max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE ' then  secured_value else null end) as CLIENT_ED_PROG_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED ' then  secured_value else null end) as CLIENT_EDUCATION_0_HS_GED,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT ' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT ' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN ' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS ' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE ' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP ' then  secured_value else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE ' then  secured_value else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME ' then  secured_value else null end) as CLIENT_INCOME_0_HH_INCOME,
max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES ' then  secured_value else null end) as CLIENT_INCOME_1_HH_SOURCES,
max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY ' then  secured_value else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT ' then  secured_value else null end) as CLIENT_INCOME_AMOUNT,
max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND ' then  secured_value else null end) as CLIENT_INCOME_IN_KIND,
max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER ' then  secured_value else null end) as CLIENT_INCOME_INKIND_OTHER,
max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES  ' then  secured_value else null end) as CLIENT_INCOME_OTHER_SOURCES ,
max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES ' then  secured_value else null end) as CLIENT_INCOME_SOURCES,
max(case sq.pseudonym when 'CLIENT_INSURANCE ' then  secured_value else null end) as CLIENT_INSURANCE,
max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER ' then  secured_value else null end) as CLIENT_INSURANCE_OTHER,
max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE ' then  secured_value else null end) as CLIENT_INSURANCE_TYPE,
max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH ' then  secured_value else null end) as CLIENT_LIVING_0_WITH,
max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS ' then  secured_value else null end) as CLIENT_LIVING_1_WITH_OTHERS,
max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS ' then  secured_value else null end) as CLIENT_LIVING_HOMELESS,
max(case sq.pseudonym when 'CLIENT_LIVING_WHERE ' then  secured_value else null end) as CLIENT_LIVING_WHERE,
max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS ' then  secured_value else null end) as CLIENT_MARITAL_0_STATUS,
max(case sq.pseudonym when 'CLIENT_MILITARY ' then  secured_value else null end) as CLIENT_MILITARY,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE ' then  secured_value else null end) as CLIENT_PROVIDE_CHILDCARE,
max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS ' then  secured_value else null end) as CLIENT_SCHOOL_MIDDLE_HS,
max(case sq.pseudonym when 'CLIENT_SECOND_0_CHILD_DOB ' then  secured_value else null end) as CLIENT_SECOND_0_CHILD_DOB,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_GRAMS ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_GRAMS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_MEASURE ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_MEASURE,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_OZ ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_OZ,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_POUNDS ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_POUNDS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_GENDER ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_GENDER,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_NICU ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_NICU,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_NICU_DAYS ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_NICU_DAYS,
max(case sq.pseudonym when 'CLIENT_SUBPREG ' then  secured_value else null end) as CLIENT_SUBPREG,
max(case sq.pseudonym when 'CLIENT_SUBPREG_0_BEEN_PREGNANT ' then  secured_value else null end) as CLIENT_SUBPREG_0_BEEN_PREGNANT,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_BEGIN_MONTH ' then  secured_value else null end) as CLIENT_SUBPREG_1_BEGIN_MONTH,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_BEGIN_YEAR ' then  secured_value else null end) as CLIENT_SUBPREG_1_BEGIN_YEAR,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_EDD ' then  secured_value else null end) as CLIENT_SUBPREG_1_EDD,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_GEST_AGE ' then  secured_value else null end) as CLIENT_SUBPREG_1_GEST_AGE,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_OUTCOME ' then  secured_value else null end) as CLIENT_SUBPREG_1_OUTCOME,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_PLANNED ' then  secured_value else null end) as CLIENT_SUBPREG_1_PLANNED,
max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING ' then  secured_value else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS ' then  secured_value else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO ' then  secured_value else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
max(case sq.pseudonym when 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH ' then  secured_value else null end) as CLIENT_WORKING_1_WORKED_SINCE_BIRTH,
max(case sq.pseudonym when 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS ' then  secured_value else null end) as CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


    from survey_views.f_secure_fact_survey_response('Demographics Update',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Edinburgh_Postnatal_Depression_Scale]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Edinburgh_Postnatal_Depression_Scale]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_EPDS_1_ABLE_TO_LAUGH varchar(256), 
CLIENT_EPDS_1_ANXIOUS_WORRIED varchar(256), 
CLIENT_EPDS_1_BEEN_CRYING varchar(256), 
CLIENT_EPDS_1_BLAME_SELF varchar(256), 
CLIENT_EPDS_1_DIFFICULTY_SLEEPING varchar(256), 
CLIENT_EPDS_1_ENJOY_THINGS varchar(256), 
CLIENT_EPDS_1_HARMING_SELF varchar(256), 
CLIENT_EPDS_1_SAD_MISERABLE varchar(256), 
CLIENT_EPDS_1_SCARED_PANICKY varchar(256), 
CLIENT_EPDS_1_THINGS_GETTING_ON_TOP varchar(256), 
CLIENT_EPS_TOTAL_SCORE varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin
insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ABLE_TO_LAUGH ' then  secured_value else null end) as CLIENT_EPDS_1_ABLE_TO_LAUGH,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ANXIOUS_WORRIED ' then  secured_value else null end) as CLIENT_EPDS_1_ANXIOUS_WORRIED,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_BEEN_CRYING ' then  secured_value else null end) as CLIENT_EPDS_1_BEEN_CRYING,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_BLAME_SELF ' then  secured_value else null end) as CLIENT_EPDS_1_BLAME_SELF,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_DIFFICULTY_SLEEPING ' then  secured_value else null end) as CLIENT_EPDS_1_DIFFICULTY_SLEEPING,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ENJOY_THINGS ' then  secured_value else null end) as CLIENT_EPDS_1_ENJOY_THINGS,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_HARMING_SELF ' then  secured_value else null end) as CLIENT_EPDS_1_HARMING_SELF,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_SAD_MISERABLE ' then  secured_value else null end) as CLIENT_EPDS_1_SAD_MISERABLE,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_SCARED_PANICKY ' then  secured_value else null end) as CLIENT_EPDS_1_SCARED_PANICKY,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_THINGS_GETTING_ON_TOP ' then  secured_value else null end) as CLIENT_EPDS_1_THINGS_GETTING_ON_TOP,
	max(case sq.pseudonym when 'CLIENT_EPS_TOTAL_SCORE ' then  secured_value else null end) as CLIENT_EPS_TOTAL_SCORE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('Edinburgh Postnatal Depression Scale',@p_requested_security_policy,@p_export_profile_id) fr   
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Education_Registration]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Education_Registration]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
EDUC_REGISTER_0_REASON varchar(256)
)
as
begin
insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'EDUC_REGISTER_0_REASON ' then  secured_value else null end) as EDUC_REGISTER_0_REASON

	
    from survey_views.f_secure_fact_survey_response('Education Registration',@p_requested_security_policy,@p_export_profile_id) fr    
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_GAD_7]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_GAD_7]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_GAD7_AFRAID varchar(256), 
CLIENT_GAD7_CTRL_WORRY varchar(256), 
CLIENT_GAD7_IRRITABLE varchar(256), 
CLIENT_GAD7_NERVOUS varchar(256), 
CLIENT_GAD7_PROBS_DIFFICULT varchar(256), 
CLIENT_GAD7_RESTLESS varchar(256), 
CLIENT_GAD7_TOTAL varchar(256), 
CLIENT_GAD7_TRBL_RELAX varchar(256), 
CLIENT_GAD7_WORRY varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_GAD7_AFRAID ' then  secured_value else null end) as CLIENT_GAD7_AFRAID,
	max(case sq.pseudonym when 'CLIENT_GAD7_CTRL_WORRY ' then  secured_value else null end) as CLIENT_GAD7_CTRL_WORRY,
	max(case sq.pseudonym when 'CLIENT_GAD7_IRRITABLE ' then  secured_value else null end) as CLIENT_GAD7_IRRITABLE,
	max(case sq.pseudonym when 'CLIENT_GAD7_NERVOUS ' then  secured_value else null end) as CLIENT_GAD7_NERVOUS,
	max(case sq.pseudonym when 'CLIENT_GAD7_PROBS_DIFFICULT ' then  secured_value else null end) as CLIENT_GAD7_PROBS_DIFFICULT,
	max(case sq.pseudonym when 'CLIENT_GAD7_RESTLESS ' then  secured_value else null end) as CLIENT_GAD7_RESTLESS,
	max(case sq.pseudonym when 'CLIENT_GAD7_TOTAL ' then  secured_value else null end) as CLIENT_GAD7_TOTAL,
	max(case sq.pseudonym when 'CLIENT_GAD7_TRBL_RELAX ' then  secured_value else null end) as CLIENT_GAD7_TRBL_RELAX,
	max(case sq.pseudonym when 'CLIENT_GAD7_WORRY ' then  secured_value else null end) as CLIENT_GAD7_WORRY,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

	
    from survey_views.f_secure_fact_survey_response('GAD-7',@p_requested_security_policy,@p_export_profile_id) fr   
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Goodwill_Indy_Additional_Referral_Data]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Goodwill_Indy_Additional_Referral_Data]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
REFERRAL_ADDITIONAL_DIMISSAL_REASON varchar(256), 
REFERRAL_ADDITIONAL_NOTES varchar(256), 
REFERRAL_ADDITIONAL_SOURCE varchar(256)
)
as
begin
insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_DIMISSAL_REASON ' then  secured_value else null end) as REFERRAL_ADDITIONAL_DIMISSAL_REASON,
	max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_NOTES ' then  secured_value else null end) as REFERRAL_ADDITIONAL_NOTES,
	max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_SOURCE ' then  secured_value else null end) as REFERRAL_ADDITIONAL_SOURCE

	
   from survey_views.f_secure_fact_survey_response('Goodwill Indy Additional Referral Data',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
 
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Health_Habits]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Health_Habits]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
	SurveyResponseID int, 
	ElementsProcessed int, 
	SurveyID int, 
	SurveyDate date, 
	AuditDate datetime2, 
	CL_EN_GEN_ID bigint, 
	SiteID int, 
	ProgramID int, 
	IA_StaffID int, 
	ClientID varchar(20), 
	RespondentID int, 
	CLIENT_0_ID_AGENCY varchar(256), 
	CLIENT_0_ID_NSO varchar(256), 
	CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
	CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
	CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
	CLIENT_SUBSTANCE_ALCOHOL_0_14DAY varchar(256), 
	CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS varchar(256), 
	CLIENT_SUBSTANCE_CIG_0_DURING_PREG varchar(256), 
	CLIENT_SUBSTANCE_CIG_1_LAST_48 varchar(256), 
	CLIENT_SUBSTANCE_CIG_1_PRE_PREG varchar(256), 
	CLIENT_SUBSTANCE_COCAINE_0_14DAY varchar(256), 
	CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES varchar(256), 
	CLIENT_SUBSTANCE_NICOTINE_0_OTHER varchar(256), 
	CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES varchar(256), 
	CLIENT_SUBSTANCE_OTHER_0_14DAY varchar(256), 
	CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES varchar(256), 
	CLIENT_SUBSTANCE_POT_0_14DAYS varchar(256), 
	CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS varchar(256), 
	NURSE_PERSONAL_0_NAME_LAST varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_ALCOHOL_0_14DAY ' then  secured_value else null end) as CLIENT_SUBSTANCE_ALCOHOL_0_14DAY,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS ' then  secured_value else null end) as CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_0_DURING_PREG ' then  secured_value else null end) as CLIENT_SUBSTANCE_CIG_0_DURING_PREG,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_1_LAST_48 ' then  secured_value else null end) as CLIENT_SUBSTANCE_CIG_1_LAST_48,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_1_PRE_PREG ' then  secured_value else null end) as CLIENT_SUBSTANCE_CIG_1_PRE_PREG,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_COCAINE_0_14DAY ' then  secured_value else null end) as CLIENT_SUBSTANCE_COCAINE_0_14DAY,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES ' then  secured_value else null end) as CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_NICOTINE_0_OTHER ' then  secured_value else null end) as CLIENT_SUBSTANCE_NICOTINE_0_OTHER,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES ' then  secured_value else null end) as CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_OTHER_0_14DAY ' then  secured_value else null end) as CLIENT_SUBSTANCE_OTHER_0_14DAY,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES ' then  secured_value else null end) as CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_POT_0_14DAYS ' then  secured_value else null end) as CLIENT_SUBSTANCE_POT_0_14DAYS,
	max(case sq.pseudonym when 'CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS ' then  secured_value else null end) as CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME_LAST


  from survey_views.f_secure_fact_survey_response('Health Habits',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Home_Visit_Encounter]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Home_Visit_Encounter]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_ATTENDEES_0_AT_VISIT varchar(256), 
CLIENT_ATTENDEES_0_OTHER_VISIT_DESC varchar(256), 
CLIENT_CHILD_DEVELOPMENT_CONCERN varchar(256), 
CLIENT_CHILD_INJURY_0_PREVENTION varchar(256), 
CLIENT_COMPLETE_0_VISIT varchar(256), 
CLIENT_CONFLICT_0_CLIENT_VISIT varchar(256), 
CLIENT_CONFLICT_1_GRNDMTHR_VISIT varchar(256), 
CLIENT_CONFLICT_1_PARTNER_VISIT varchar(256), 
CLIENT_CONT_HLTH_INS varchar(256), 
CLIENT_CONTENT_0_PERCENT_VISIT varchar(256), 
CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT varchar(256), 
CLIENT_DOMAIN_0_FRNDFAM_VISIT varchar(256), 
CLIENT_DOMAIN_0_LIFECOURSE_VISIT varchar(256), 
CLIENT_DOMAIN_0_MATERNAL_VISIT varchar(256), 
CLIENT_DOMAIN_0_PERSHLTH_VISIT varchar(256), 
CLIENT_DOMAIN_0_TOTAL_VISIT varchar(256), 
CLIENT_INVOLVE_0_CLIENT_VISIT varchar(256), 
CLIENT_INVOLVE_1_GRNDMTHR_VISIT varchar(256), 
CLIENT_INVOLVE_1_PARTNER_VISIT varchar(256), 
CLIENT_IPV_0_SAFETY_PLAN varchar(256), 
CLIENT_LOCATION_0_VISIT varchar(256), 
CLIENT_NO_REFERRAL varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_PLANNED_VISIT_SCH varchar(256), 
CLIENT_PRENATAL_VISITS varchar(256), 
CLIENT_PRENATAL_VISITS_WEEKS varchar(256), 
CLIENT_SCREENED_SRVCS varchar(256), 
CLIENT_TIME_0_START_VISIT varchar(256), 
CLIENT_TIME_1_DURATION_VISIT varchar(256), 
CLIENT_TIME_1_END_VISIT varchar(256), 
CLIENT_TIME_FROM_AMPM varchar(256), 
CLIENT_TIME_FROM_HR varchar(256), 
CLIENT_TIME_FROM_MIN varchar(256), 
CLIENT_TIME_TO_AMPM varchar(256), 
CLIENT_TIME_TO_HR varchar(256), 
CLIENT_TIME_TO_MIN varchar(256), 
CLIENT_UNDERSTAND_0_CLIENT_VISIT varchar(256), 
CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT varchar(256), 
CLIENT_UNDERSTAND_1_PARTNER_VISIT varchar(256), 
CLIENT_VISIT_SCHEDULE varchar(256), 
INFANT_HEALTH_ER_0_HAD_VISIT varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DATE1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DATE2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DATE3 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DAYS1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DAYS2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DAYS3 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_ERvsUC1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_ERvsUC2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_ERvsUC3 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_TREAT1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_TREAT2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_TREAT3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DATE1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DATE2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DATE3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DAYS1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DAYS2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DAYS3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_ERvsUC1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_ERvsUC2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_ERvsUC3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_TREAT1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_TREAT2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_TREAT3 varchar(256), 
INFANT_HEALTH_ER_1_OTHER varchar(256), 
INFANT_HEALTH_ER_1_OTHER_ERvsUC1 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_ERvsUC2 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_ERvsUC3 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_REASON1 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_REASON2 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_REASON3 varchar(256), 
INFANT_HEALTH_ER_1_OTHERDT1 varchar(256), 
INFANT_HEALTH_ER_1_OTHERDT2 varchar(256), 
INFANT_HEALTH_ER_1_OTHERDT3 varchar(256), 
INFANT_HEALTH_ER_1_TYPE varchar(256), 
INFANT_HEALTH_HOSP_0_HAD_VISIT varchar(256), 
INFANT_HEALTH_HOSP_1_INGEST_DATE1 varchar(256), 
INFANT_HEALTH_HOSP_1_INGEST_DATE2 varchar(256), 
INFANT_HEALTH_HOSP_1_INGEST_DATE3 varchar(256), 
INFANT_HEALTH_HOSP_1_INJ_DATE1 varchar(256), 
INFANT_HEALTH_HOSP_1_INJ_DATE2 varchar(256), 
INFANT_HEALTH_HOSP_1_INJ_DATE3 varchar(256), 
INFANT_HEALTH_HOSP_1_TYPE varchar(256), 
INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 varchar(256), 
INFANT_HEALTH_PROVIDER_0_APPT_R2 varchar(256), 
NURSE_MILEAGE_0_VIS varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ATTENDEES_0_AT_VISIT ' then  secured_value else null end) as CLIENT_ATTENDEES_0_AT_VISIT,
	max(case sq.pseudonym when 'CLIENT_ATTENDEES_0_OTHER_VISIT_DESC ' then  secured_value else null end) as CLIENT_ATTENDEES_0_OTHER_VISIT_DESC,
	max(case sq.pseudonym when 'CLIENT_CHILD_DEVELOPMENT_CONCERN ' then  secured_value else null end) as CLIENT_CHILD_DEVELOPMENT_CONCERN,
	max(case sq.pseudonym when 'CLIENT_CHILD_INJURY_0_PREVENTION ' then  secured_value else null end) as CLIENT_CHILD_INJURY_0_PREVENTION,
	max(case sq.pseudonym when 'CLIENT_COMPLETE_0_VISIT ' then  secured_value else null end) as CLIENT_COMPLETE_0_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONFLICT_0_CLIENT_VISIT ' then  secured_value else null end) as CLIENT_CONFLICT_0_CLIENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONFLICT_1_GRNDMTHR_VISIT ' then  secured_value else null end) as CLIENT_CONFLICT_1_GRNDMTHR_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONFLICT_1_PARTNER_VISIT ' then  secured_value else null end) as CLIENT_CONFLICT_1_PARTNER_VISIT,
	max(case sq.pseudonym when 'CLIENT_CONT_HLTH_INS ' then  secured_value else null end) as CLIENT_CONT_HLTH_INS,
	max(case sq.pseudonym when 'CLIENT_CONTENT_0_PERCENT_VISIT ' then  secured_value else null end) as CLIENT_CONTENT_0_PERCENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ' then  secured_value else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_VISIT ' then  secured_value else null end) as CLIENT_DOMAIN_0_FRNDFAM_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_VISIT ' then  secured_value else null end) as CLIENT_DOMAIN_0_LIFECOURSE_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_VISIT ' then  secured_value else null end) as CLIENT_DOMAIN_0_MATERNAL_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSHLTH_VISIT ' then  secured_value else null end) as CLIENT_DOMAIN_0_PERSHLTH_VISIT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_VISIT ' then  secured_value else null end) as CLIENT_DOMAIN_0_TOTAL_VISIT,
	max(case sq.pseudonym when 'CLIENT_INVOLVE_0_CLIENT_VISIT ' then  secured_value else null end) as CLIENT_INVOLVE_0_CLIENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_INVOLVE_1_GRNDMTHR_VISIT ' then  secured_value else null end) as CLIENT_INVOLVE_1_GRNDMTHR_VISIT,
	max(case sq.pseudonym when 'CLIENT_INVOLVE_1_PARTNER_VISIT ' then  secured_value else null end) as CLIENT_INVOLVE_1_PARTNER_VISIT,
	max(case sq.pseudonym when 'CLIENT_IPV_0_SAFETY_PLAN ' then  secured_value else null end) as CLIENT_IPV_0_SAFETY_PLAN,
	max(case sq.pseudonym when 'CLIENT_LOCATION_0_VISIT ' then  secured_value else null end) as CLIENT_LOCATION_0_VISIT,
	max(case sq.pseudonym when 'CLIENT_NO_REFERRAL ' then  secured_value else null end) as CLIENT_NO_REFERRAL,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PLANNED_VISIT_SCH ' then  secured_value else null end) as CLIENT_PLANNED_VISIT_SCH,
	max(case sq.pseudonym when 'CLIENT_PRENATAL_VISITS ' then  secured_value else null end) as CLIENT_PRENATAL_VISITS,
	max(case sq.pseudonym when 'CLIENT_PRENATAL_VISITS_WEEKS ' then  secured_value else null end) as CLIENT_PRENATAL_VISITS_WEEKS,
	max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS ' then  secured_value else null end) as CLIENT_SCREENED_SRVCS,
	max(case sq.pseudonym when 'CLIENT_TIME_0_START_VISIT ' then  secured_value else null end) as CLIENT_TIME_0_START_VISIT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_VISIT ' then  secured_value else null end) as CLIENT_TIME_1_DURATION_VISIT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_END_VISIT ' then  secured_value else null end) as CLIENT_TIME_1_END_VISIT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM ' then  secured_value else null end) as CLIENT_TIME_FROM_AMPM,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR ' then  secured_value else null end) as CLIENT_TIME_FROM_HR,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN ' then  secured_value else null end) as CLIENT_TIME_FROM_MIN,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM ' then  secured_value else null end) as CLIENT_TIME_TO_AMPM,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_HR ' then  secured_value else null end) as CLIENT_TIME_TO_HR,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN ' then  secured_value else null end) as CLIENT_TIME_TO_MIN,
	max(case sq.pseudonym when 'CLIENT_UNDERSTAND_0_CLIENT_VISIT ' then  secured_value else null end) as CLIENT_UNDERSTAND_0_CLIENT_VISIT,
	max(case sq.pseudonym when 'CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT ' then  secured_value else null end) as CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT,
	max(case sq.pseudonym when 'CLIENT_UNDERSTAND_1_PARTNER_VISIT ' then  secured_value else null end) as CLIENT_UNDERSTAND_1_PARTNER_VISIT,
	max(case sq.pseudonym when 'CLIENT_VISIT_SCHEDULE ' then  secured_value else null end) as CLIENT_VISIT_SCHEDULE,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_0_HAD_VISIT ' then  secured_value else null end) as INFANT_HEALTH_ER_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_TYPE ' then  secured_value else null end) as INFANT_HEALTH_ER_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_0_HAD_VISIT ' then  secured_value else null end) as INFANT_HEALTH_HOSP_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_TYPE ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 ' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_R2 ' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_R2,
	max(case sq.pseudonym when 'NURSE_MILEAGE_0_VIS ' then  secured_value else null end) as NURSE_MILEAGE_0_VIS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


   from survey_views.f_secure_fact_survey_response('Home Visit Encounter',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
    
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Infant_Birth]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Infant_Birth]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_WEIGHT_0_PREG_GAIN varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_0_ID_NSO2 varchar(256), 
INFANT_0_ID_NSO3 varchar(256), 
INFANT_BIRTH_0_CLIENT_ER varchar(256), 
INFANT_BIRTH_0_CLIENT_ER_TIMES varchar(256), 
[INFANT_BIRTH_0_CLIENT_URGENT CARE] varchar(256), 
[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES] varchar(256), 
INFANT_BIRTH_0_DOB varchar(256), 
INFANT_BIRTH_0_DOB2 varchar(256), 
INFANT_BIRTH_0_DOB3 varchar(256), 
INFANT_BIRTH_1_DELIVERY varchar(256), 
INFANT_BIRTH_1_GEST_AGE varchar(256), 
INFANT_BIRTH_1_GEST_AGE2 varchar(256), 
INFANT_BIRTH_1_GEST_AGE3 varchar(256), 
INFANT_BIRTH_1_HEARING_SCREEN varchar(256), 
INFANT_BIRTH_1_HEARING_SCREEN2 varchar(256), 
INFANT_BIRTH_1_HEARING_SCREEN3 varchar(256), 
INFANT_BIRTH_1_LABOR varchar(256), 
INFANT_BIRTH_1_MULTIPLE_BIRTHS varchar(256), 
INFANT_BIRTH_1_NEWBORN_SCREEN varchar(256), 
INFANT_BIRTH_1_NEWBORN_SCREEN2 varchar(256), 
INFANT_BIRTH_1_NEWBORN_SCREEN3 varchar(256), 
INFANT_BIRTH_1_NICU varchar(256), 
INFANT_BIRTH_1_NICU_DAYS varchar(256), 
INFANT_BIRTH_1_NICU_DAYS_R2 varchar(256), 
INFANT_BIRTH_1_NICU_DAYS_R2_2 varchar(256), 
INFANT_BIRTH_1_NICU_DAYS_R2_3 varchar(256), 
INFANT_BIRTH_1_NICU_DAYS2 varchar(256), 
INFANT_BIRTH_1_NICU_DAYS3 varchar(256), 
INFANT_BIRTH_1_NICU_NURSERY_PURPOSE varchar(256), 
INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER varchar(256), 
INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2 varchar(256), 
INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3 varchar(256), 
INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2 varchar(256), 
INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3 varchar(256), 
INFANT_BIRTH_1_NICU_R2 varchar(256), 
INFANT_BIRTH_1_NICU_R2_2 varchar(256), 
INFANT_BIRTH_1_NICU_R2_3 varchar(256), 
INFANT_BIRTH_1_NICU2 varchar(256), 
INFANT_BIRTH_1_NICU3 varchar(256), 
INFANT_BIRTH_1_NURSERY_DAYS_R2 varchar(256), 
INFANT_BIRTH_1_NURSERY_DAYS_R2_2 varchar(256), 
INFANT_BIRTH_1_NURSERY_DAYS_R2_3 varchar(256), 
INFANT_BIRTH_1_NURSERY_R2 varchar(256), 
INFANT_BIRTH_1_NURSERY_R2_2 varchar(256), 
INFANT_BIRTH_1_NURSERY_R2_3 varchar(256), 
INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS varchar(256), 
INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2 varchar(256), 
INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3 varchar(256), 
INFANT_BIRTH_1_WEIGHT_GRAMS varchar(256), 
INFANT_BIRTH_1_WEIGHT_GRAMS2 varchar(256), 
INFANT_BIRTH_1_WEIGHT_GRAMS3 varchar(256), 
INFANT_BIRTH_1_WEIGHT_MEASURE varchar(256), 
INFANT_BIRTH_1_WEIGHT_MEASURE2 varchar(256), 
INFANT_BIRTH_1_WEIGHT_MEASURE3 varchar(256), 
INFANT_BIRTH_1_WEIGHT_OUNCES varchar(256), 
INFANT_BIRTH_1_WEIGHT_OUNCES2 varchar(256), 
INFANT_BIRTH_1_WEIGHT_OUNCES3 varchar(256), 
INFANT_BIRTH_1_WEIGHT_POUNDS varchar(256), 
INFANT_BIRTH_1_WEIGHT_POUNDS2 varchar(256), 
INFANT_BIRTH_1_WEIGHT_POUNDS3 varchar(256), 
INFANT_BIRTH_COSLEEP varchar(256), 
INFANT_BIRTH_COSLEEP2 varchar(256), 
INFANT_BIRTH_COSLEEP3 varchar(256), 
INFANT_BIRTH_READ varchar(256), 
INFANT_BIRTH_READ2 varchar(256), 
INFANT_BIRTH_READ3 varchar(256), 
INFANT_BIRTH_SLEEP_BACK varchar(256), 
INFANT_BIRTH_SLEEP_BACK2 varchar(256), 
INFANT_BIRTH_SLEEP_BACK3 varchar(256), 
INFANT_BIRTH_SLEEP_BEDDING varchar(256), 
INFANT_BIRTH_SLEEP_BEDDING2 varchar(256), 
INFANT_BIRTH_SLEEP_BEDDING3 varchar(256), 
INFANT_BREASTMILK_0_EVER_BIRTH varchar(256), 
INFANT_BREASTMILK_0_EVER_BIRTH2 varchar(256), 
INFANT_BREASTMILK_0_EVER_BIRTH3 varchar(256), 
INFANT_INSURANCE varchar(256), 
INFANT_INSURANCE_OTHER varchar(256), 
INFANT_INSURANCE_OTHER2 varchar(256), 
INFANT_INSURANCE_OTHER3 varchar(256), 
INFANT_INSURANCE_TYPE varchar(256), 
INFANT_INSURANCE_TYPE2 varchar(256), 
INFANT_INSURANCE_TYPE3 varchar(256), 
INFANT_INSURANCE2 varchar(256), 
INFANT_INSURANCE3 varchar(256), 
INFANT_PERSONAL_0_ETHNICITY varchar(256), 
INFANT_PERSONAL_0_ETHNICITY2 varchar(256), 
INFANT_PERSONAL_0_ETHNICITY3 varchar(256), 
[INFANT_PERSONAL_0_FIRST NAME] varchar(256), 
[INFANT_PERSONAL_0_FIRST NAME2] varchar(256), 
[INFANT_PERSONAL_0_FIRST NAME3] varchar(256), 
INFANT_PERSONAL_0_GENDER varchar(256), 
INFANT_PERSONAL_0_GENDER2 varchar(256), 
INFANT_PERSONAL_0_GENDER3 varchar(256), 
[INFANT_PERSONAL_0_LAST NAME] varchar(256), 
INFANT_PERSONAL_0_RACE varchar(256), 
INFANT_PERSONAL_0_RACE2 varchar(256), 
INFANT_PERSONAL_0_RACE3 varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_WEIGHT_0_PREG_GAIN ' then  secured_value else null end) as CLIENT_WEIGHT_0_PREG_GAIN,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO2 ' then  secured_value else null end) as INFANT_0_ID_NSO2,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO3 ' then  secured_value else null end) as INFANT_0_ID_NSO3,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_ER ' then  secured_value else null end) as INFANT_BIRTH_0_CLIENT_ER,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_ER_TIMES ' then  secured_value else null end) as INFANT_BIRTH_0_CLIENT_ER_TIMES,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_URGENT CARE ' then  secured_value else null end) as [INFANT_BIRTH_0_CLIENT_URGENT CARE],
	max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES ' then  secured_value else null end) as [INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES],
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB ' then  secured_value else null end) as INFANT_BIRTH_0_DOB,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB2 ' then  secured_value else null end) as INFANT_BIRTH_0_DOB2,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB3 ' then  secured_value else null end) as INFANT_BIRTH_0_DOB3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_DELIVERY ' then  secured_value else null end) as INFANT_BIRTH_1_DELIVERY,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE ' then  secured_value else null end) as INFANT_BIRTH_1_GEST_AGE,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE2 ' then  secured_value else null end) as INFANT_BIRTH_1_GEST_AGE2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE3 ' then  secured_value else null end) as INFANT_BIRTH_1_GEST_AGE3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN ' then  secured_value else null end) as INFANT_BIRTH_1_HEARING_SCREEN,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN2 ' then  secured_value else null end) as INFANT_BIRTH_1_HEARING_SCREEN2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN3 ' then  secured_value else null end) as INFANT_BIRTH_1_HEARING_SCREEN3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_LABOR ' then  secured_value else null end) as INFANT_BIRTH_1_LABOR,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_MULTIPLE_BIRTHS ' then  secured_value else null end) as INFANT_BIRTH_1_MULTIPLE_BIRTHS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN ' then  secured_value else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN2 ' then  secured_value else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN3 ' then  secured_value else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU ' then  secured_value else null end) as INFANT_BIRTH_1_NICU,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2_2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2_3 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS3 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2_2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2_3 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU2 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU3 ' then  secured_value else null end) as INFANT_BIRTH_1_NICU3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2 ' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2_2 ' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2_3 ' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2 ' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_R2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2_2 ' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_R2_2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2_3 ' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_R2_3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS2 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS3 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE2 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE3 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES2 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES3 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES3,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS2 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS2,
	max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS3 ' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS3,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP ' then  secured_value else null end) as INFANT_BIRTH_COSLEEP,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP2 ' then  secured_value else null end) as INFANT_BIRTH_COSLEEP2,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP3 ' then  secured_value else null end) as INFANT_BIRTH_COSLEEP3,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ ' then  secured_value else null end) as INFANT_BIRTH_READ,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ2 ' then  secured_value else null end) as INFANT_BIRTH_READ2,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ3 ' then  secured_value else null end) as INFANT_BIRTH_READ3,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK2 ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK2,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK3 ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK3,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING2 ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING2,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING3 ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING3,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH ' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_BIRTH,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH2 ' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_BIRTH2,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH3 ' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_BIRTH3,
	max(case sq.pseudonym when 'INFANT_INSURANCE ' then  secured_value else null end) as INFANT_INSURANCE,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER ' then  secured_value else null end) as INFANT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER2 ' then  secured_value else null end) as INFANT_INSURANCE_OTHER2,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER3 ' then  secured_value else null end) as INFANT_INSURANCE_OTHER3,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE ' then  secured_value else null end) as INFANT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE2 ' then  secured_value else null end) as INFANT_INSURANCE_TYPE2,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE3 ' then  secured_value else null end) as INFANT_INSURANCE_TYPE3,
	max(case sq.pseudonym when 'INFANT_INSURANCE2 ' then  secured_value else null end) as INFANT_INSURANCE2,
	max(case sq.pseudonym when 'INFANT_INSURANCE3 ' then  secured_value else null end) as INFANT_INSURANCE3,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY ' then  secured_value else null end) as INFANT_PERSONAL_0_ETHNICITY,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY2 ' then  secured_value else null end) as INFANT_PERSONAL_0_ETHNICITY2,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY3 ' then  secured_value else null end) as INFANT_PERSONAL_0_ETHNICITY3,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME ' then  secured_value else null end) as [INFANT_PERSONAL_0_FIRST NAME],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME2 ' then  secured_value else null end) as [INFANT_PERSONAL_0_FIRST NAME2],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME3 ' then  secured_value else null end) as [INFANT_PERSONAL_0_FIRST NAME3],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER ' then  secured_value else null end) as INFANT_PERSONAL_0_GENDER,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER2 ' then  secured_value else null end) as INFANT_PERSONAL_0_GENDER2,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER3 ' then  secured_value else null end) as INFANT_PERSONAL_0_GENDER3,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_LAST NAME ' then  secured_value else null end) as [INFANT_PERSONAL_0_LAST NAME],
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE ' then  secured_value else null end) as INFANT_PERSONAL_0_RACE,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE2 ' then  secured_value else null end) as INFANT_PERSONAL_0_RACE2,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE3 ' then  secured_value else null end) as INFANT_PERSONAL_0_RACE3,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


  from survey_views.f_secure_fact_survey_response('Infant Birth',@p_requested_security_policy,@p_export_profile_id) fr 
   
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
    dc.client_id;

	return;

end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Infant_Health_Care]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Infant_Health_Care]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_AGES_STAGES_0_VERSION varchar(256), 
INFANT_AGES_STAGES_1_COMM varchar(256), 
INFANT_AGES_STAGES_1_FMOTOR varchar(256), 
INFANT_AGES_STAGES_1_GMOTOR varchar(256), 
INFANT_AGES_STAGES_1_PSOCIAL varchar(256), 
INFANT_AGES_STAGES_1_PSOLVE varchar(256), 
INFANT_AGES_STAGES_SE_0_EMOTIONAL varchar(256), 
INFANT_AGES_STAGES_SE_VERSION varchar(256), 
INFANT_BIRTH_0_DOB varchar(256), 
INFANT_BIRTH_COSLEEP varchar(256), 
INFANT_BIRTH_READ varchar(256), 
INFANT_BIRTH_SLEEP_BACK varchar(256), 
INFANT_BIRTH_SLEEP_BEDDING varchar(256), 
INFANT_BREASTMILK_0_EVER_IHC varchar(256), 
INFANT_BREASTMILK_1_AGE_STOP varchar(256), 
INFANT_BREASTMILK_1_CONT varchar(256), 
INFANT_BREASTMILK_1_EXCLUSIVE_WKS varchar(256), 
INFANT_BREASTMILK_1_WEEK_STOP varchar(256), 
INFANT_HEALTH_DENTAL_SOURCE varchar(256), 
INFANT_HEALTH_DENTIST varchar(256), 
INFANT_HEALTH_DENTIST_STILL_EBF varchar(256), 
INFANT_HEALTH_ER_0_HAD_VISIT varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DATE1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DATE2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DATE3 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DAYS1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DAYS2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_DAYS3 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_ERvsUC1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_ERvsUC2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_ERvsUC3 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_TREAT1 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_TREAT2 varchar(256), 
INFANT_HEALTH_ER_1_INGEST_TREAT3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DATE1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DATE2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DATE3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DAYS1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DAYS2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_DAYS3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_ERvsUC1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_ERvsUC2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_ERvsUC3 varchar(256), 
INFANT_HEALTH_ER_1_INJ_TREAT1 varchar(256), 
INFANT_HEALTH_ER_1_INJ_TREAT2 varchar(256), 
INFANT_HEALTH_ER_1_INJ_TREAT3 varchar(256), 
INFANT_HEALTH_ER_1_OTHER varchar(256), 
INFANT_HEALTH_ER_1_OTHER_ERvsUC1 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_ERvsUC2 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_ERvsUC3 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_REASON1 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_REASON2 varchar(256), 
INFANT_HEALTH_ER_1_OTHER_REASON3 varchar(256), 
INFANT_HEALTH_ER_1_OTHERDT1 varchar(256), 
INFANT_HEALTH_ER_1_OTHERDT2 varchar(256), 
INFANT_HEALTH_ER_1_OTHERDT3 varchar(256), 
INFANT_HEALTH_ER_1_TYPE varchar(256), 
INFANT_HEALTH_HEAD_0_CIRC_INCHES varchar(256), 
INFANT_HEALTH_HEAD_1_REPORT varchar(256), 
INFANT_HEALTH_HEIGHT_0_INCHES varchar(256), 
INFANT_HEALTH_HEIGHT_1_PERCENT varchar(256), 
INFANT_HEALTH_HEIGHT_1_REPORT varchar(256), 
INFANT_HEALTH_HOSP_0_HAD_VISIT varchar(256), 
INFANT_HEALTH_HOSP_1_INGEST_DATE1 varchar(256), 
INFANT_HEALTH_HOSP_1_INGEST_DATE2 varchar(256), 
INFANT_HEALTH_HOSP_1_INGEST_DATE3 varchar(256), 
INFANT_HEALTH_HOSP_1_INJ_DATE1 varchar(256), 
INFANT_HEALTH_HOSP_1_INJ_DATE2 varchar(256), 
INFANT_HEALTH_HOSP_1_INJ_DATE3 varchar(256), 
INFANT_HEALTH_HOSP_1_TYPE varchar(256), 
INFANT_HEALTH_IMMUNIZ_0_UPDATE varchar(256), 
INFANT_HEALTH_IMMUNIZ_1_RECORD varchar(256), 
INFANT_HEALTH_IMMUNIZ_UPDATE_NO varchar(256), 
INFANT_HEALTH_IMMUNIZ_UPDATE_YES varchar(256), 
INFANT_HEALTH_LEAD_0_TEST varchar(256), 
INFANT_HEALTH_NO_ASQ_COMM varchar(256), 
INFANT_HEALTH_NO_ASQ_FINE varchar(256), 
INFANT_HEALTH_NO_ASQ_GROSS varchar(256), 
INFANT_HEALTH_NO_ASQ_PERSONAL varchar(256), 
INFANT_HEALTH_NO_ASQ_PROBLEM varchar(256), 
INFANT_HEALTH_NO_ASQ_TOTAL varchar(256), 
INFANT_HEALTH_PROVIDER_0_APPT varchar(256), 
INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 varchar(256), 
INFANT_HEALTH_PROVIDER_0_APPT_R2 varchar(256), 
INFANT_HEALTH_PROVIDER_0_PRIMARY varchar(256), 
INFANT_HEALTH_WEIGHT_0_POUNDS varchar(256), 
INFANT_HEALTH_WEIGHT_1_OUNCES varchar(256), 
INFANT_HEALTH_WEIGHT_1_OZ varchar(256), 
INFANT_HEALTH_WEIGHT_1_PERCENT varchar(256), 
INFANT_HEALTH_WEIGHT_1_REPORT varchar(256), 
INFANT_HOME_0_TOTAL varchar(256), 
INFANT_HOME_1_ACCEPTANCE varchar(256), 
INFANT_HOME_1_EXPERIENCE varchar(256), 
INFANT_HOME_1_INVOLVEMENT varchar(256), 
INFANT_HOME_1_LEARNING varchar(256), 
INFANT_HOME_1_ORGANIZATION varchar(256), 
INFANT_HOME_1_RESPONSIVITY varchar(256), 
INFANT_INSURANCE varchar(256), 
INFANT_INSURANCE_OTHER varchar(256), 
INFANT_INSURANCE_TYPE varchar(256), 
INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
INFANT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_PERSONAL_0_SSN varchar(256), 
INFANT_SOCIAL_SERVICES_0_REFERRAL varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REASON1 varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REASON2 varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REASON3 varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1 varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2 varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3 varchar(256), 
INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL varchar(256), 
INFANT_SOCIAL_SERVICES_1_REASON1 varchar(256), 
INFANT_SOCIAL_SERVICES_1_REASON1_OTHER varchar(256), 
INFANT_SOCIAL_SERVICES_1_REASON2 varchar(256), 
INFANT_SOCIAL_SERVICES_1_REASON2_OTHER varchar(256), 
INFANT_SOCIAL_SERVICES_1_REASON3 varchar(256), 
INFANT_SOCIAL_SERVICES_1_REASON3_OTHER varchar(256), 
INFANT_SOCIAL_SERVICES_1_REFDATE1 varchar(256), 
INFANT_SOCIAL_SERVICES_1_REFDATE2 varchar(256), 
INFANT_SOCIAL_SERVICES_1_REFDATE3 varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_0_VERSION ' then  secured_value else null end) as INFANT_AGES_STAGES_0_VERSION,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM ' then  secured_value else null end) as INFANT_AGES_STAGES_1_COMM,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR ' then  secured_value else null end) as INFANT_AGES_STAGES_1_FMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR ' then  secured_value else null end) as INFANT_AGES_STAGES_1_GMOTOR,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL ' then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE ' then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOLVE,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_SE_0_EMOTIONAL ' then  secured_value else null end) as INFANT_AGES_STAGES_SE_0_EMOTIONAL,
	max(case sq.pseudonym when 'INFANT_AGES_STAGES_SE_VERSION ' then  secured_value else null end) as INFANT_AGES_STAGES_SE_VERSION,
	max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB ' then  secured_value else null end) as INFANT_BIRTH_0_DOB,
	max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP ' then  secured_value else null end) as INFANT_BIRTH_COSLEEP,
	max(case sq.pseudonym when 'INFANT_BIRTH_READ ' then  secured_value else null end) as INFANT_BIRTH_READ,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK,
	max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING ' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_IHC ' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_IHC,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_AGE_STOP ' then  secured_value else null end) as INFANT_BREASTMILK_1_AGE_STOP,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_CONT ' then  secured_value else null end) as INFANT_BREASTMILK_1_CONT,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_EXCLUSIVE_WKS ' then  secured_value else null end) as INFANT_BREASTMILK_1_EXCLUSIVE_WKS,
	max(case sq.pseudonym when 'INFANT_BREASTMILK_1_WEEK_STOP ' then  secured_value else null end) as INFANT_BREASTMILK_1_WEEK_STOP,
	max(case sq.pseudonym when 'INFANT_HEALTH_DENTAL_SOURCE ' then  secured_value else null end) as INFANT_HEALTH_DENTAL_SOURCE,
	max(case sq.pseudonym when 'INFANT_HEALTH_DENTIST ' then  secured_value else null end) as INFANT_HEALTH_DENTIST,
	max(case sq.pseudonym when 'INFANT_HEALTH_DENTIST_STILL_EBF ' then  secured_value else null end) as INFANT_HEALTH_DENTIST_STILL_EBF,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_0_HAD_VISIT ' then  secured_value else null end) as INFANT_HEALTH_ER_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT1 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT1,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT2 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT2,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT3 ' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT3,
	max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_TYPE ' then  secured_value else null end) as INFANT_HEALTH_ER_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEAD_0_CIRC_INCHES ' then  secured_value else null end) as INFANT_HEALTH_HEAD_0_CIRC_INCHES,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEAD_1_REPORT ' then  secured_value else null end) as INFANT_HEALTH_HEAD_1_REPORT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_0_INCHES ' then  secured_value else null end) as INFANT_HEALTH_HEIGHT_0_INCHES,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_1_PERCENT ' then  secured_value else null end) as INFANT_HEALTH_HEIGHT_1_PERCENT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_1_REPORT ' then  secured_value else null end) as INFANT_HEALTH_HEIGHT_1_REPORT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_0_HAD_VISIT ' then  secured_value else null end) as INFANT_HEALTH_HOSP_0_HAD_VISIT,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE1 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE1,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE2 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE2,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE3 ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE3,
	max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_TYPE ' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_TYPE,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_0_UPDATE ' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_0_UPDATE,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_1_RECORD ' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_1_RECORD,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_UPDATE_NO ' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_UPDATE_NO,
	max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_UPDATE_YES ' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_UPDATE_YES,
	max(case sq.pseudonym when 'INFANT_HEALTH_LEAD_0_TEST ' then  secured_value else null end) as INFANT_HEALTH_LEAD_0_TEST,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM ' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_COMM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE ' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_FINE,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS ' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL ' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM ' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
	max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_TOTAL ' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_TOTAL,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT ' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 ' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_R2 ' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_R2,
	max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_PRIMARY ' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_PRIMARY,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_0_POUNDS ' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_OUNCES ' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_OUNCES,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_OZ ' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_OZ,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_PERCENT ' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_PERCENT,
	max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_REPORT ' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_REPORT,
	max(case sq.pseudonym when 'INFANT_HOME_0_TOTAL ' then  secured_value else null end) as INFANT_HOME_0_TOTAL,
	max(case sq.pseudonym when 'INFANT_HOME_1_ACCEPTANCE ' then  secured_value else null end) as INFANT_HOME_1_ACCEPTANCE,
	max(case sq.pseudonym when 'INFANT_HOME_1_EXPERIENCE ' then  secured_value else null end) as INFANT_HOME_1_EXPERIENCE,
	max(case sq.pseudonym when 'INFANT_HOME_1_INVOLVEMENT ' then  secured_value else null end) as INFANT_HOME_1_INVOLVEMENT,
	max(case sq.pseudonym when 'INFANT_HOME_1_LEARNING ' then  secured_value else null end) as INFANT_HOME_1_LEARNING,
	max(case sq.pseudonym when 'INFANT_HOME_1_ORGANIZATION ' then  secured_value else null end) as INFANT_HOME_1_ORGANIZATION,
	max(case sq.pseudonym when 'INFANT_HOME_1_RESPONSIVITY ' then  secured_value else null end) as INFANT_HOME_1_RESPONSIVITY,
	max(case sq.pseudonym when 'INFANT_INSURANCE ' then  secured_value else null end) as INFANT_INSURANCE,
	max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER ' then  secured_value else null end) as INFANT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE ' then  secured_value else null end) as INFANT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_SSN ' then  secured_value else null end) as INFANT_PERSONAL_0_SSN,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_0_REFERRAL ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_0_REFERRAL,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON1 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON2 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON3 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON3,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON1 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON1_OTHER ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON1_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON2 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON2_OTHER ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON2_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON3 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON3,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON3_OTHER ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON3_OTHER,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE1 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE1,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE2 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE2,
	max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE3 ' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE3,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


    from survey_views.f_secure_fact_survey_response('Infant Health Care',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

	  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Joint_Visit_Observation]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Joint_Visit_Observation]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
NURSE_JVSCALE_GUIDE_0_LINES varchar(256), 
NURSE_JVSCALE_GUIDE_1_LINES_CMT varchar(256), 
NURSE_JVSCALE_MOTIV_1_INTERVIEW varchar(256), 
NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT varchar(256), 
NURSE_JVSCALE_PC_0_INTERVENTION varchar(256), 
NURSE_JVSCALE_PC_1_INTERVENTION_CMT varchar(256), 
NURSE_JVSCALE_SELF_0_EFFICACY varchar(256), 
NURSE_JVSCALE_SELF_1_EFFICACY_CMT varchar(256), 
NURSE_JVSCALE_THERAPEUTIC_0_CHAR varchar(256), 
NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NURSE_JVSCALE_GUIDE_0_LINES ' then  secured_value else null end) as NURSE_JVSCALE_GUIDE_0_LINES,
	max(case sq.pseudonym when 'NURSE_JVSCALE_GUIDE_1_LINES_CMT ' then  secured_value else null end) as NURSE_JVSCALE_GUIDE_1_LINES_CMT,
	max(case sq.pseudonym when 'NURSE_JVSCALE_MOTIV_1_INTERVIEW ' then  secured_value else null end) as NURSE_JVSCALE_MOTIV_1_INTERVIEW,
	max(case sq.pseudonym when 'NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT ' then  secured_value else null end) as NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT,
	max(case sq.pseudonym when 'NURSE_JVSCALE_PC_0_INTERVENTION ' then  secured_value else null end) as NURSE_JVSCALE_PC_0_INTERVENTION,
	max(case sq.pseudonym when 'NURSE_JVSCALE_PC_1_INTERVENTION_CMT ' then  secured_value else null end) as NURSE_JVSCALE_PC_1_INTERVENTION_CMT,
	max(case sq.pseudonym when 'NURSE_JVSCALE_SELF_0_EFFICACY ' then  secured_value else null end) as NURSE_JVSCALE_SELF_0_EFFICACY,
	max(case sq.pseudonym when 'NURSE_JVSCALE_SELF_1_EFFICACY_CMT ' then  secured_value else null end) as NURSE_JVSCALE_SELF_1_EFFICACY_CMT,
	max(case sq.pseudonym when 'NURSE_JVSCALE_THERAPEUTIC_0_CHAR ' then  secured_value else null end) as NURSE_JVSCALE_THERAPEUTIC_0_CHAR,
	max(case sq.pseudonym when 'NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT ' then  secured_value else null end) as NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT

   from survey_views.f_secure_fact_survey_response('Joint Visit Observation',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Joint_Visit_Observation_Form]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Joint_Visit_Observation_Form]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
JVO_ADDITIONAL_REASON varchar(256), 
JVO_CLIENT_CASE varchar(256), 
JVO_CLIENT_NAME varchar(256), 
JVO_CLINICAL_CHART_CONSISTENT varchar(256), 
JVO_CLINICAL_CHART_CONSISTENT_COMMENTS varchar(256), 
JVO_HVEF_CONSISTENT varchar(256), 
JVO_HVEF_CONSISTENT_COMMENTS varchar(256), 
JVO_MI_CLIENT_PRIN_COMMENTS varchar(256), 
JVO_MI_CLIENT_PRIN_SCORE varchar(256), 
JVO_OBSERVER_NAME varchar(256), 
JVO_OBSERVER_NAME_OTHER varchar(256), 
JVO_OTHER_OBSERVATIONS varchar(256), 
JVO_PARENT_CHILD_COMMENTS varchar(256), 
JVO_PARENT_CHILD_SCORE varchar(256), 
JVO_START_TIME varchar(256), 
JVO_THERAPEUTIC_CHAR_COMMENTS varchar(256), 
JVO_THERAPEUTIC_CHAR_SCORE varchar(256), 
JVO_VISIT_STRUCTURE_COMMENTS varchar(256), 
JVO_VISIT_STRUCTURE_SCORE varchar(256)
)
as
begin
insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'JVO_ADDITIONAL_REASON ' then  secured_value else null end) as JVO_ADDITIONAL_REASON,
	max(case sq.pseudonym when 'JVO_CLIENT_CASE ' then  secured_value else null end) as JVO_CLIENT_CASE,
	max(case sq.pseudonym when 'JVO_CLIENT_NAME ' then  secured_value else null end) as JVO_CLIENT_NAME,
	max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT ' then  secured_value else null end) as JVO_CLINICAL_CHART_CONSISTENT,
	max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT_COMMENTS ' then  secured_value else null end) as JVO_CLINICAL_CHART_CONSISTENT_COMMENTS,
	max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT ' then  secured_value else null end) as JVO_HVEF_CONSISTENT,
	max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT_COMMENTS ' then  secured_value else null end) as JVO_HVEF_CONSISTENT_COMMENTS,
	max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_COMMENTS ' then  secured_value else null end) as JVO_MI_CLIENT_PRIN_COMMENTS,
	max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_SCORE ' then  secured_value else null end) as JVO_MI_CLIENT_PRIN_SCORE,
	max(case sq.pseudonym when 'JVO_OBSERVER_NAME ' then  secured_value else null end) as JVO_OBSERVER_NAME,
	max(case sq.pseudonym when 'JVO_OBSERVER_NAME_OTHER ' then  secured_value else null end) as JVO_OBSERVER_NAME_OTHER,
	max(case sq.pseudonym when 'JVO_OTHER_OBSERVATIONS ' then  secured_value else null end) as JVO_OTHER_OBSERVATIONS,
	max(case sq.pseudonym when 'JVO_PARENT_CHILD_COMMENTS ' then  secured_value else null end) as JVO_PARENT_CHILD_COMMENTS,
	max(case sq.pseudonym when 'JVO_PARENT_CHILD_SCORE ' then  secured_value else null end) as JVO_PARENT_CHILD_SCORE,
	max(case sq.pseudonym when 'JVO_START_TIME ' then  secured_value else null end) as JVO_START_TIME,
	max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_COMMENTS ' then  secured_value else null end) as JVO_THERAPEUTIC_CHAR_COMMENTS,
	max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_SCORE ' then  secured_value else null end) as JVO_THERAPEUTIC_CHAR_SCORE,
	max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_COMMENTS ' then  secured_value else null end) as JVO_VISIT_STRUCTURE_COMMENTS,
	max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_SCORE ' then  secured_value else null end) as JVO_VISIT_STRUCTURE_SCORE
  
   from survey_views.f_secure_fact_survey_response('Joint Visit Observation Form',@p_requested_security_policy,@p_export_profile_id) fr   
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;

end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Maternal_Health_Assessment]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Maternal_Health_Assessment]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING] varchar(256), 
CLIENT_HEALTH_BELIEF_0_CANT_SOLVE varchar(256), 
CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS varchar(256), 
CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND varchar(256), 
CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL varchar(256), 
CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO varchar(256), 
CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL varchar(256), 
CLIENT_HEALTH_GENERAL_0_ADDICTION varchar(256), 
CLIENT_HEALTH_GENERAL_0_CONCERNS varchar(256), 
CLIENT_HEALTH_GENERAL_0_CONCERNS2 varchar(256), 
CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH varchar(256), 
CLIENT_HEALTH_GENERAL_0_OTHER varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI varchar(256), 
CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS varchar(256), 
CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET varchar(256), 
CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES varchar(256), 
CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_EDD varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING ' then  secured_value else null end) as [CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_CANT_SOLVE ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_ADDICTION ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_ADDICTION,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS2 ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS2,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_OTHER ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_OTHER,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_EDD ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_EDD,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


  from survey_views.f_secure_fact_survey_response('Maternal Health Assessment',@p_requested_security_policy,@p_export_profile_id) fr    
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_12_Month_Infant]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_12_Month_Infant]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
INFANT_PERSONAL_0_NAME_LAST varchar(256), 
MN_ASQ3_12MOS varchar(256), 
MN_ASQ3_REFERRAL varchar(256), 
MN_ASQSE_12MOS varchar(256), 
MN_ASQSE_REFERRAL varchar(256), 
MN_CLIENT_INSURANCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS_YES varchar(256), 
MN_CPA_FILE varchar(256), 
MN_CPA_FIRST_TIME varchar(256), 
MN_CPA_SUBSTANTIATED varchar(256), 
MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
MN_FURTHER_SCREEN_ASQ3 varchar(256), 
MN_FURTHER_SCREEN_ASQSE varchar(256), 
MN_INFANT_0_ID_2 varchar(256), 
MN_INFANT_INSURANCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_NCAST_CAREGIVER varchar(256), 
MN_NCAST_CLARITY_CUES varchar(256), 
MN_NCAST_COGN_GROWTH varchar(256), 
MN_NCAST_DISTRESS varchar(256), 
MN_NCAST_SE_GROWTH varchar(256), 
MN_NCAST_SENS_CUES varchar(256), 
MN_SITE varchar(256), 
MN_TOTAL_HV varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,

	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MN_ASQ3_12MOS ' then  secured_value else null end) as MN_ASQ3_12MOS,
	max(case sq.pseudonym when 'MN_ASQ3_REFERRAL ' then  secured_value else null end) as MN_ASQ3_REFERRAL,
	max(case sq.pseudonym when 'MN_ASQSE_12MOS ' then  secured_value else null end) as MN_ASQSE_12MOS,
	max(case sq.pseudonym when 'MN_ASQSE_REFERRAL ' then  secured_value else null end) as MN_ASQSE_REFERRAL,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
	max(case sq.pseudonym when 'MN_CPA_FILE ' then  secured_value else null end) as MN_CPA_FILE,
	max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then  secured_value else null end) as MN_CPA_FIRST_TIME,
	max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then  secured_value else null end) as MN_CPA_SUBSTANTIATED,
	max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3 ' then  secured_value else null end) as MN_FURTHER_SCREEN_ASQ3,
	max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQSE ' then  secured_value else null end) as MN_FURTHER_SCREEN_ASQSE,
	max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then  secured_value else null end) as MN_INFANT_0_ID_2,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then  secured_value else null end) as MN_INFANT_INSURANCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_NCAST_CAREGIVER ' then  secured_value else null end) as MN_NCAST_CAREGIVER,
	max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES ' then  secured_value else null end) as MN_NCAST_CLARITY_CUES,
	max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH ' then  secured_value else null end) as MN_NCAST_COGN_GROWTH,
	max(case sq.pseudonym when 'MN_NCAST_DISTRESS ' then  secured_value else null end) as MN_NCAST_DISTRESS,
	max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH ' then  secured_value else null end) as MN_NCAST_SE_GROWTH,
	max(case sq.pseudonym when 'MN_NCAST_SENS_CUES ' then  secured_value else null end) as MN_NCAST_SENS_CUES,
	max(case sq.pseudonym when 'MN_SITE ' then  secured_value else null end) as MN_SITE,
	max(case sq.pseudonym when 'MN_TOTAL_HV ' then  secured_value else null end) as MN_TOTAL_HV,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



   from survey_views.f_secure_fact_survey_response('MN 12 Month Infant',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;

end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_18_Months_Toddler]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_18_Months_Toddler]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
INFANT_PERSONAL_0_NAME_LAST varchar(256), 
MN_CLIENT_INSURANCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS_YES varchar(256), 
MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
MN_INFANT_0_ID_2 varchar(256), 
MN_INFANT_INSURANCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_SITE varchar(256), 
MN_TOTAL_HV varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,

	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
	max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then  secured_value else null end) as MN_INFANT_0_ID_2,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then  secured_value else null end) as MN_INFANT_INSURANCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_SITE ' then  secured_value else null end) as MN_SITE,
	max(case sq.pseudonym when 'MN_TOTAL_HV ' then  secured_value else null end) as MN_TOTAL_HV,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response( 'MN 18 Months Toddler',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_24_Month_Toddler]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_24_Month_Toddler]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
INFANT_PERSONAL_0_NAME_LAST varchar(256), 
MN_CLIENT_INSURANCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS_YES varchar(256), 
MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
MN_INFANT_0_ID_2 varchar(256), 
MN_INFANT_INSURANCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_SITE varchar(256), 
MN_TOTAL_HV varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
	max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then  secured_value else null end) as MN_INFANT_0_ID_2,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then  secured_value else null end) as MN_INFANT_INSURANCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_SITE ' then  secured_value else null end) as MN_SITE,
	max(case sq.pseudonym when 'MN_TOTAL_HV ' then  secured_value else null end) as MN_TOTAL_HV,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('MN 24 Month Toddler',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_6_Months_Infant]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_6_Months_Infant]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
	SurveyResponseID int, 
	ElementsProcessed int, 
	SurveyID int, 
	SurveyDate date, 
	AuditDate datetime2, 
	CL_EN_GEN_ID bigint, 
	SiteID int, 
	ProgramID int, 
	IA_StaffID int, 
	ClientID varchar(20), 
	RespondentID int, 
	CLIENT_0_ID_NSO varchar(256), 
	CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
	CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
	INFANT_0_ID_NSO varchar(256), 
	INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
	INFANT_PERSONAL_0_NAME_LAST varchar(256), 
	MN_ASQ3_4MOS varchar(256), 
	MN_ASQ3_REFERRAL varchar(256), 
	MN_CLIENT_INSURANCE varchar(256), 
	MN_CLIENT_INSURANCE_RESOURCE varchar(256), 
	MN_CLIENT_INSURANCE_RESOURCE_OTHER varchar(256), 
	MN_COMPLETED_EDUCATION_PROGRAMS varchar(256), 
	MN_COMPLETED_EDUCATION_PROGRAMS_YES varchar(256), 
	MN_CPA_FILE varchar(256), 
	MN_CPA_FIRST_TIME varchar(256), 
	MN_CPA_SUBSTANTIATED varchar(256), 
	MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
	MN_FOLIC_ACID varchar(256), 
	MN_FURTHER_SCREEN_ASQ3 varchar(256), 
	MN_INFANT_0_ID_2 varchar(256), 
	MN_INFANT_INSURANCE varchar(256), 
	MN_INFANT_INSURANCE_RESOURCE varchar(256), 
	MN_INFANT_INSURANCE_RESOURCE_OTHER varchar(256), 
	MN_NCAST_CAREGIVER varchar(256), 
	MN_NCAST_CLARITY_CUES varchar(256), 
	MN_NCAST_COGN_GROWTH varchar(256), 
	MN_NCAST_DISTRESS varchar(256), 
	MN_NCAST_SE_GROWTH varchar(256), 
	MN_NCAST_SENS_CUES varchar(256), 
	MN_SITE varchar(256), 
	MN_TOTAL_HV varchar(256), 
	NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin
insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MN_ASQ3_4MOS ' then  secured_value else null end) as MN_ASQ3_4MOS,
	max(case sq.pseudonym when 'MN_ASQ3_REFERRAL ' then  secured_value else null end) as MN_ASQ3_REFERRAL,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
	max(case sq.pseudonym when 'MN_CPA_FILE ' then  secured_value else null end) as MN_CPA_FILE,
	max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then  secured_value else null end) as MN_CPA_FIRST_TIME,
	max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then  secured_value else null end) as MN_CPA_SUBSTANTIATED,
	max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'MN_FOLIC_ACID ' then  secured_value else null end) as MN_FOLIC_ACID,
	max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3 ' then  secured_value else null end) as MN_FURTHER_SCREEN_ASQ3,
	max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then  secured_value else null end) as MN_INFANT_0_ID_2,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then  secured_value else null end) as MN_INFANT_INSURANCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_NCAST_CAREGIVER ' then  secured_value else null end) as MN_NCAST_CAREGIVER,
	max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES ' then  secured_value else null end) as MN_NCAST_CLARITY_CUES,
	max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH ' then  secured_value else null end) as MN_NCAST_COGN_GROWTH,
	max(case sq.pseudonym when 'MN_NCAST_DISTRESS ' then  secured_value else null end) as MN_NCAST_DISTRESS,
	max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH ' then  secured_value else null end) as MN_NCAST_SE_GROWTH,
	max(case sq.pseudonym when 'MN_NCAST_SENS_CUES ' then  secured_value else null end) as MN_NCAST_SENS_CUES,
	max(case sq.pseudonym when 'MN_SITE ' then  secured_value else null end) as MN_SITE,
	max(case sq.pseudonym when 'MN_TOTAL_HV ' then  secured_value else null end) as MN_TOTAL_HV,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


     from survey_views.f_secure_fact_survey_response('MN 6 Months Infant',@p_requested_security_policy,@p_export_profile_id) fr    
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by   
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_Child_Intake]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_Child_Intake]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
INFANT_PERSONAL_0_NAME_LAST varchar(256), 
MN_CLIENT_INSURANCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES varchar(256), 
MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
MN_INFANT_0_ID_2 varchar(256), 
MN_INFANT_INSURANCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE varchar(256), 
MN_INFANT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_SITE varchar(256), 
MN_TOTAL_HV varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

)
as
begin
insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES ' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES,
	max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then  secured_value else null end) as MN_INFANT_0_ID_2,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then  secured_value else null end) as MN_INFANT_INSURANCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_SITE ' then  secured_value else null end) as MN_SITE,
	max(case sq.pseudonym when 'MN_TOTAL_HV ' then  secured_value else null end) as MN_TOTAL_HV,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

 from survey_views.f_secure_fact_survey_response('MN Child Intake',@p_requested_security_policy,@p_export_profile_id) fr    
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_Primary_Caregiver_Closure]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_Primary_Caregiver_Closure]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
INFANT_0_ID_NSO varchar(256), 
INFANT_PERSONAL_0_NAME_FIRST varchar(256), 
MN_CPA_FILE varchar(256), 
MN_CPA_FIRST_TIME varchar(256), 
MN_CPA_SUBSTANTIATED varchar(256), 
MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
MN_INFANT_0_ID_2 varchar(256), 
MN_SITE varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'MN_CPA_FILE ' then  secured_value else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then  secured_value else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then  secured_value else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_SITE ' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

from survey_views.f_secure_fact_survey_response('MN Primary Caregiver Closure',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  

  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_MN_Primary_Caregiver_Intake]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_MN_Primary_Caregiver_Intake]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
MN_CLIENT_INSURANCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE varchar(256), 
MN_CLIENT_INSURANCE_RESOURCE_OTHER varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS varchar(256), 
MN_COMPLETED_EDUCATION_PROGRAMS_YES varchar(256), 
MN_DATA_STAFF_PERSONAL_0_NAME varchar(256), 
MN_HOUSEHOLD_SIZE varchar(256), 
MN_SITE varchar(256), 
MN_WKS_PREGNANT varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY 'then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO 'then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST 'then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST 'then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE 'then  secured_value else null end) as MN_CLIENT_INSURANCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE 'then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
	max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER 'then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS 'then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
	max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES 'then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
	max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME 'then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'MN_HOUSEHOLD_SIZE 'then  secured_value else null end) as MN_HOUSEHOLD_SIZE,
	max(case sq.pseudonym when 'MN_SITE 'then  secured_value else null end) as MN_SITE,
	max(case sq.pseudonym when 'MN_WKS_PREGNANT 'then  secured_value else null end) as MN_WKS_PREGNANT,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME 'then  secured_value else null end) as NURSE_PERSONAL_0_NAME


   from survey_views.f_secure_fact_survey_response('MN Primary Caregiver Intake',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_New_Hire_Form]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_New_Hire_Form]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
NEW_HIRE_0_ACCESS_LEVEL varchar(256), 
NEW_HIRE_0_EDUC_COMPLETED varchar(256), 
NEW_HIRE_0_EMAIL varchar(256), 
NEW_HIRE_0_FTE varchar(256), 
NEW_HIRE_0_HIRE_DATE varchar(256), 
NEW_HIRE_0_NAME_LAST varchar(256), 
NEW_HIRE_0_PHONE varchar(256), 
NEW_HIRE_0_PREVIOUS_NFP_WORK varchar(256), 
NEW_HIRE_0_REASON_FOR_HIRE varchar(256), 
NEW_HIRE_0_REASON_FOR_HIRE_REPLACE varchar(256), 
NEW_HIRE_0_REASON_NFP_WORK_DESC varchar(256), 
NEW_HIRE_0_START_DATE varchar(256), 
NEW_HIRE_0_TEAM_NAME varchar(256), 
NEW_HIRE_1_DOB varchar(256), 
NEW_HIRE_1_NAME_FIRST varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_AGENCY varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_CITY varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_DATE1 varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_DATE2 varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_NAME varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_STATE varchar(256), 
NEW_HIRE_1_REPLACE_STAFF_TERM varchar(256), 
NEW_HIRE_1_ROLE varchar(256), 
NEW_HIRE_ADDITIONAL_INFO varchar(256), 
NEW_HIRE_ADDRESS_0_ZIP varchar(256), 
NEW_HIRE_ADDRESS_1_CITY varchar(256), 
NEW_HIRE_ADDRESS_1_STATE varchar(256), 
NEW_HIRE_ADDRESS_1_STATE_OTHR varchar(256), 
NEW_HIRE_ADDRESS_1_STREET varchar(256), 
NEW_HIRE_ER_0_LNAME varchar(256), 
NEW_HIRE_ER_1_FNAME varchar(256), 
NEW_HIRE_ER_1_PHONE varchar(256), 
NEW_HIRE_SUP_0_EMAIL varchar(256), 
NEW_HIRE_SUP_0_NAME varchar(256), 
NEW_HIRE_SUP_0_NAME_OTHR varchar(256), 
NEW_HIRE_SUP_0_PHONE varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL ' then  secured_value else null end) as NEW_HIRE_0_ACCESS_LEVEL,
	max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED ' then  secured_value else null end) as NEW_HIRE_0_EDUC_COMPLETED,
	max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL ' then  secured_value else null end) as NEW_HIRE_0_EMAIL,
	max(case sq.pseudonym when 'NEW_HIRE_0_FTE ' then  secured_value else null end) as NEW_HIRE_0_FTE,
	max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE ' then  secured_value else null end) as NEW_HIRE_0_HIRE_DATE,
	max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST ' then  secured_value else null end) as NEW_HIRE_0_NAME_LAST,
	max(case sq.pseudonym when 'NEW_HIRE_0_PHONE ' then  secured_value else null end) as NEW_HIRE_0_PHONE,
	max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK ' then  secured_value else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
	max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE ' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
	max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE ' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
	max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC ' then  secured_value else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
	max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE ' then  secured_value else null end) as NEW_HIRE_0_START_DATE,
	max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME ' then  secured_value else null end) as NEW_HIRE_0_TEAM_NAME,
	max(case sq.pseudonym when 'NEW_HIRE_1_DOB ' then  secured_value else null end) as NEW_HIRE_1_DOB,
	max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST ' then  secured_value else null end) as NEW_HIRE_1_NAME_FIRST,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_AGENCY ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_CITY ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_CITY,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE1 ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE1,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE2 ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE2,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_NAME ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_NAME,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_STATE ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_STATE,
	max(case sq.pseudonym when 'NEW_HIRE_1_REPLACE_STAFF_TERM ' then  secured_value else null end) as NEW_HIRE_1_REPLACE_STAFF_TERM,
	max(case sq.pseudonym when 'NEW_HIRE_1_ROLE ' then  secured_value else null end) as NEW_HIRE_1_ROLE,
	max(case sq.pseudonym when 'NEW_HIRE_ADDITIONAL_INFO ' then  secured_value else null end) as NEW_HIRE_ADDITIONAL_INFO,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP ' then  secured_value else null end) as NEW_HIRE_ADDRESS_0_ZIP,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_CITY,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE_OTHR ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE_OTHR,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STREET,
	max(case sq.pseudonym when 'NEW_HIRE_ER_0_LNAME ' then  secured_value else null end) as NEW_HIRE_ER_0_LNAME,
	max(case sq.pseudonym when 'NEW_HIRE_ER_1_FNAME ' then  secured_value else null end) as NEW_HIRE_ER_1_FNAME,
	max(case sq.pseudonym when 'NEW_HIRE_ER_1_PHONE ' then  secured_value else null end) as NEW_HIRE_ER_1_PHONE,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL ' then  secured_value else null end) as NEW_HIRE_SUP_0_EMAIL,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME ' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME_OTHR ' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME_OTHR,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE ' then  secured_value else null end) as NEW_HIRE_SUP_0_PHONE

   from survey_views.f_secure_fact_survey_response('New Hire Form',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end



GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_New_Hire_V2]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_New_Hire_V2]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
NEW_HIRE_0_ACCESS_LEVEL varchar(256), 
NEW_HIRE_0_EDUC_COMPLETED varchar(256), 
NEW_HIRE_0_EMAIL varchar(256), 
NEW_HIRE_0_FTE varchar(256), 
NEW_HIRE_0_HIRE_DATE varchar(256), 
NEW_HIRE_0_NAME_LAST varchar(256), 
NEW_HIRE_0_PHONE varchar(256), 
NEW_HIRE_0_PREVIOUS_NFP_WORK varchar(256), 
NEW_HIRE_0_REASON_FOR_HIRE varchar(256), 
NEW_HIRE_0_REASON_FOR_HIRE_REPLACE varchar(256), 
NEW_HIRE_0_REASON_NFP_WORK_DESC varchar(256), 
NEW_HIRE_0_START_DATE varchar(256), 
NEW_HIRE_0_TEAM_NAME varchar(256), 
NEW_HIRE_1_DOB varchar(256), 
NEW_HIRE_1_NAME_FIRST varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_AGENCY varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_CITY varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_DATE1 varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_DATE2 varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_NAME varchar(256), 
NEW_HIRE_1_PREVIOUS_WORK_STATE varchar(256), 
NEW_HIRE_1_REPLACE_STAFF_TERM varchar(256), 
NEW_HIRE_1_ROLE varchar(256), 
NEW_HIRE_ADDITIONAL_INFO varchar(256), 
NEW_HIRE_ADDRESS_0_ZIP varchar(256), 
NEW_HIRE_ADDRESS_1_CITY varchar(256), 
NEW_HIRE_ADDRESS_1_STATE varchar(256), 
NEW_HIRE_ADDRESS_1_STATE_OTHR varchar(256), 
NEW_HIRE_ADDRESS_1_STREET varchar(256), 
NEW_HIRE_ER_0_LNAME varchar(256), 
NEW_HIRE_ER_1_FNAME varchar(256), 
NEW_HIRE_ER_1_PHONE varchar(256), 
NEW_HIRE_SUP_0_EMAIL varchar(256), 
NEW_HIRE_SUP_0_NAME varchar(256), 
NEW_HIRE_SUP_0_NAME_OTHR varchar(256), 
NEW_HIRE_SUP_0_PHONE varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL ' then  secured_value else null end) as NEW_HIRE_0_ACCESS_LEVEL,
	max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED ' then  secured_value else null end) as NEW_HIRE_0_EDUC_COMPLETED,
	max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL ' then  secured_value else null end) as NEW_HIRE_0_EMAIL,
	max(case sq.pseudonym when 'NEW_HIRE_0_FTE ' then  secured_value else null end) as NEW_HIRE_0_FTE,
	max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE ' then  secured_value else null end) as NEW_HIRE_0_HIRE_DATE,
	max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST ' then  secured_value else null end) as NEW_HIRE_0_NAME_LAST,
	max(case sq.pseudonym when 'NEW_HIRE_0_PHONE ' then  secured_value else null end) as NEW_HIRE_0_PHONE,
	max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK ' then  secured_value else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
	max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE ' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
	max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE ' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
	max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC ' then  secured_value else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
	max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE ' then  secured_value else null end) as NEW_HIRE_0_START_DATE,
	max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME ' then  secured_value else null end) as NEW_HIRE_0_TEAM_NAME,
	max(case sq.pseudonym when 'NEW_HIRE_1_DOB ' then  secured_value else null end) as NEW_HIRE_1_DOB,
	max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST ' then  secured_value else null end) as NEW_HIRE_1_NAME_FIRST,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_AGENCY ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_CITY ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_CITY,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE1 ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE1,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE2 ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE2,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_NAME ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_NAME,
	max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_STATE ' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_STATE,
	max(case sq.pseudonym when 'NEW_HIRE_1_REPLACE_STAFF_TERM ' then  secured_value else null end) as NEW_HIRE_1_REPLACE_STAFF_TERM,
	max(case sq.pseudonym when 'NEW_HIRE_1_ROLE ' then  secured_value else null end) as NEW_HIRE_1_ROLE,
	max(case sq.pseudonym when 'NEW_HIRE_ADDITIONAL_INFO ' then  secured_value else null end) as NEW_HIRE_ADDITIONAL_INFO,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP ' then  secured_value else null end) as NEW_HIRE_ADDRESS_0_ZIP,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_CITY,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE_OTHR ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE_OTHR,
	max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET ' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STREET,
	max(case sq.pseudonym when 'NEW_HIRE_ER_0_LNAME ' then  secured_value else null end) as NEW_HIRE_ER_0_LNAME,
	max(case sq.pseudonym when 'NEW_HIRE_ER_1_FNAME ' then  secured_value else null end) as NEW_HIRE_ER_1_FNAME,
	max(case sq.pseudonym when 'NEW_HIRE_ER_1_PHONE ' then  secured_value else null end) as NEW_HIRE_ER_1_PHONE,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL ' then  secured_value else null end) as NEW_HIRE_SUP_0_EMAIL,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME ' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME_OTHR ' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME_OTHR,
	max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE ' then  secured_value else null end) as NEW_HIRE_SUP_0_PHONE

from survey_views.f_secure_fact_survey_response('New Hire V2',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;

return;
end

GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_NFP_Los_Angeles_Outreach_Marketing]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_NFP_Los_Angeles_Outreach_Marketing]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
LA_CTY_CONTACT_NAME_OUTREACH varchar(256), 
LA_CTY_CONTACT_PHONE_OUTREACH varchar(256), 
LA_CTY_NOTES_OUTREACH varchar(256), 
LA_CTY_ORG_NAME_OUTREACH varchar(256), 
LA_CTY_ORG_TYPE_OTH_OUTREACH varchar(256), 
LA_CTY_ORG_TYPE_OUTREACH varchar(256), 
LA_CTY_STAFF_OUTREACH varchar(256), 
LA_CTY_STAFF2_OUTREACH varchar(256), 
LA_CTY_STAFF3_OUTREACH varchar(256), 
LA_CTY_STAFF4_OUTREACH varchar(256), 
LA_CTY_STAFF5_OUTREACH varchar(256), 
LA_CTY_TARGET_POP_OUTREACH varchar(256)
)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'LA_CTY_CONTACT_NAME_OUTREACH ' then  secured_value else null end) as LA_CTY_CONTACT_NAME_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_CONTACT_PHONE_OUTREACH ' then  secured_value else null end) as LA_CTY_CONTACT_PHONE_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_NOTES_OUTREACH ' then  secured_value else null end) as LA_CTY_NOTES_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_ORG_NAME_OUTREACH ' then  secured_value else null end) as LA_CTY_ORG_NAME_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OTH_OUTREACH ' then  secured_value else null end) as LA_CTY_ORG_TYPE_OTH_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OUTREACH ' then  secured_value else null end) as LA_CTY_ORG_TYPE_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF2_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF2_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF3_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF3_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF4_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF4_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF5_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF5_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_TARGET_POP_OUTREACH ' then  secured_value else null end) as LA_CTY_TARGET_POP_OUTREACH


    from survey_views.f_secure_fact_survey_response('NFP Los Angeles - Outreach/Marketing',@p_requested_security_policy,@p_export_profile_id) fr
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
    
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_NFP_Tribal_Project]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_NFP_Tribal_Project]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_TRIBAL_0_PARITY varchar(256), 
CLIENT_TRIBAL_CHILD_1_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_1_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_10_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_10_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_2_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_2_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_3_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_3_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_4_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_4_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_5_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_5_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_6_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_6_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_7_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_7_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_8_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_8_LIVING varchar(256), 
CLIENT_TRIBAL_CHILD_9_DOB varchar(256), 
CLIENT_TRIBAL_CHILD_9_LIVING varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)
)
as
begin

insert into @result

select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_0_PARITY ' then  secured_value else null end) as CLIENT_TRIBAL_0_PARITY,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_1_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_1_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_1_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_1_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_10_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_10_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_10_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_10_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_2_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_2_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_2_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_2_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_3_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_3_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_3_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_3_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_4_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_4_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_4_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_4_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_5_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_5_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_5_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_5_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_6_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_6_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_6_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_6_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_7_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_7_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_7_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_7_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_8_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_8_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_8_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_8_LIVING,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_9_DOB ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_9_DOB,
	max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_9_LIVING ' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_9_LIVING,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('NFP Tribal Project',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
   
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Nurse_Assessment]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [survey_views].[f_select_Nurse_Assessment]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
[NURSE_ASSESS_ DATA_0_USES] varchar(256), 
[NURSE_ASSESS_ DATA_1_USES_CMT] varchar(256), 
NURSE_ASSESS_6DOMAINS_0_UTILIZES varchar(256), 
NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT varchar(256), 
NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE varchar(256), 
NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT varchar(256), 
NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC varchar(256), 
NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT varchar(256), 
NURSE_ASSESS_CARE_0_SELF varchar(256), 
NURSE_ASSESS_CARE_0_SELF_CMT varchar(256), 
NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS varchar(256), 
NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT varchar(256), 
NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM varchar(256), 
NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT varchar(256), 
NURSE_ASSESS_CULTURE_0_IMPACT varchar(256), 
NURSE_ASSESS_CULTURE_0_IMPACT_CMT varchar(256), 
NURSE_ASSESS_DOCUMENTATION_0_TIMELY varchar(256), 
NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT varchar(256), 
NURSE_ASSESS_FIDELITY_0_PRACTICES varchar(256), 
NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT varchar(256), 
NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING varchar(256), 
NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT varchar(256), 
NURSE_ASSESS_GUIDELINES_0_ADAPTS varchar(256), 
NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT varchar(256), 
NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES varchar(256), 
NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT varchar(256), 
NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME varchar(256), 
NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT varchar(256), 
NURSE_ASSESS_QUALITIES_0_THERAPEUTIC varchar(256), 
NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT varchar(256), 
NURSE_ASSESS_REFLECTION_0_SELF varchar(256), 
NURSE_ASSESS_REFLECTION_0_SELF_CMT varchar(256), 
NURSE_ASSESS_REGULAR_0_SUPERVISION varchar(256), 
NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT varchar(256), 
NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC varchar(256), 
NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT varchar(256), 
NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE varchar(256), 
NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT varchar(256), 
NURSE_ASSESS_SELF_ADVOCACY_0_BUILD varchar(256), 
NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT varchar(256), 
NURSE_ASSESS_THEORIES_0_PRINCIPLES varchar(256), 
NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT varchar(256), 
NURSE_ASSESS_UNDERSTAND_0_GOALS varchar(256), 
NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT varchar(256)

)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_0_USES ' then  secured_value else null end) as [NURSE_ASSESS_ DATA_0_USES],
	max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_1_USES_CMT ' then  secured_value else null end) as [NURSE_ASSESS_ DATA_1_USES_CMT],
	max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_0_UTILIZES ' then  secured_value else null end) as NURSE_ASSESS_6DOMAINS_0_UTILIZES,
	max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT ' then  secured_value else null end) as NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE ' then  secured_value else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE,
	max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT ' then  secured_value else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC ' then  secured_value else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC,
	max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT ' then  secured_value else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF ' then  secured_value else null end) as NURSE_ASSESS_CARE_0_SELF,
	max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF_CMT ' then  secured_value else null end) as NURSE_ASSESS_CARE_0_SELF_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS ' then  secured_value else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS,
	max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT ' then  secured_value else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM ' then  secured_value else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM,
	max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT ' then  secured_value else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT ' then  secured_value else null end) as NURSE_ASSESS_CULTURE_0_IMPACT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT_CMT ' then  secured_value else null end) as NURSE_ASSESS_CULTURE_0_IMPACT_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY ' then  secured_value else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY,
	max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT ' then  secured_value else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES ' then  secured_value else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES,
	max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT ' then  secured_value else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING ' then  secured_value else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING,
	max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT ' then  secured_value else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS ' then  secured_value else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS,
	max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT ' then  secured_value else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES ' then  secured_value else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES,
	max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT ' then  secured_value else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME ' then  secured_value else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME,
	max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT ' then  secured_value else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC ' then  secured_value else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC,
	max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT ' then  secured_value else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF ' then  secured_value else null end) as NURSE_ASSESS_REFLECTION_0_SELF,
	max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF_CMT ' then  secured_value else null end) as NURSE_ASSESS_REFLECTION_0_SELF_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION ' then  secured_value else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION,
	max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT ' then  secured_value else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC ' then  secured_value else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC,
	max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT ' then  secured_value else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE ' then  secured_value else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE,
	max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT ' then  secured_value else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD ' then  secured_value else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD,
	max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT ' then  secured_value else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES ' then  secured_value else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES,
	max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT ' then  secured_value else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS ' then  secured_value else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS,
	max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT ' then  secured_value else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT
   
   from survey_views.f_secure_fact_survey_response('Nurse Assessment',@p_requested_security_policy,@p_export_profile_id) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  

  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_PHQ_9]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_PHQ_9]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
RespondentID int, 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_PHQ9_0_TOTAL_SCORE varchar(256), 
CLIENT_PHQ9_1_CONCENTRATION varchar(256), 
CLIENT_PHQ9_1_DIFFICULTY varchar(256), 
CLIENT_PHQ9_1_FEEL_BAD varchar(256), 
CLIENT_PHQ9_1_FEEL_DEPRESSED varchar(256), 
CLIENT_PHQ9_1_FEEL_TIRED varchar(256), 
CLIENT_PHQ9_1_HURT_SELF varchar(256), 
CLIENT_PHQ9_1_LITTLE_INTEREST varchar(256), 
CLIENT_PHQ9_1_MOVE_SPEAK varchar(256), 
CLIENT_PHQ9_1_TROUBLE_EAT varchar(256), 
CLIENT_PHQ9_1_TROUBLE_SLEEP varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

)
as
begin

insert into @result
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PHQ9_0_TOTAL_SCORE ' then  secured_value else null end) as CLIENT_PHQ9_0_TOTAL_SCORE,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_CONCENTRATION ' then  secured_value else null end) as CLIENT_PHQ9_1_CONCENTRATION,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_DIFFICULTY ' then  secured_value else null end) as CLIENT_PHQ9_1_DIFFICULTY,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_BAD ' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_BAD,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_DEPRESSED ' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_DEPRESSED,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_TIRED ' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_TIRED,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_HURT_SELF ' then  secured_value else null end) as CLIENT_PHQ9_1_HURT_SELF,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_LITTLE_INTEREST ' then  secured_value else null end) as CLIENT_PHQ9_1_LITTLE_INTEREST,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_MOVE_SPEAK ' then  secured_value else null end) as CLIENT_PHQ9_1_MOVE_SPEAK,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_EAT ' then  secured_value else null end) as CLIENT_PHQ9_1_TROUBLE_EAT,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_SLEEP ' then  secured_value else null end) as CLIENT_PHQ9_1_TROUBLE_SLEEP,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


   from survey_views.f_secure_fact_survey_response('PHQ-9',@p_requested_security_policy,@p_export_profile_id) fr 
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end


GO
/****** Object:  Table [dbo].[xref_program]    Script Date: 11/21/2017 3:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_program](
	[programid] [int] NULL,
	[program_name] [varchar](50) NULL,
	[site_id] [int] NULL,
	[team_id] [int] NULL,
	[program_demo_group_id] [int] NULL,
	[program_demo_group] [varchar](50) NULL,
	[program_grouptype] [varchar](50) NULL,
	[program_grouptype_id] [int] NULL,
	[program_type] [varchar](50) NULL,
	[program_type_id] [int] NULL,
	[insert_date] [datetime2](7) NULL,
	[last_modified] [datetime2](7) NULL,
	[source_auditdate] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_client]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_client](
	[client_key] [bigint] IDENTITY(160480,1) NOT NULL,
	[client_id] [varchar](20) NOT NULL,
	[first_name] [varchar](256) NULL,
	[middle_initial] [char](1) NULL,
	[last_name] [varchar](256) NULL,
	[address1] [varchar](256) NULL,
	[address2] [varchar](256) NULL,
	[city] [varchar](256) NULL,
	[state] [varchar](256) NULL,
	[postal_code] [varchar](256) NULL,
	[client_date_of_birth_key] [int] NULL,
	[email] [varchar](256) NULL,
	[client_ethnicity] [varchar](256) NULL,
	[single_race] [varchar](256) NULL,
	[race_bridge_key] [int] NULL,
	[source_system_key] [int] NULL,
	[current_expired_flag] [varchar](256) NULL,
	[record_created_date] [datetime2](7) NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [dim_client_pkey] PRIMARY KEY CLUSTERED 
(
	[client_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_date]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_date](
	[date_key] [int] IDENTITY(160490,1) NOT NULL,
	[date_actual] [date] NULL,
	[epoch] [bigint] NULL,
	[day_suffix] [varchar](4) NULL,
	[day_name] [varchar](9) NULL,
	[day_of_week] [int] NULL,
	[day_of_month] [int] NULL,
	[day_of_quarter] [int] NULL,
	[day_of_year] [int] NULL,
	[week_of_month] [int] NULL,
	[week_of_year] [int] NULL,
	[week_of_year_iso] [char](10) NULL,
	[month_actual] [int] NULL,
	[month_name] [varchar](9) NULL,
	[month_name_abbreviated] [varchar](3) NULL,
	[quarter_actual] [int] NULL,
	[quarter_abbreviation] [char](2) NULL,
	[quarter_name] [varchar](9) NULL,
	[year_actual] [int] NULL,
	[first_day_of_week] [date] NULL,
	[last_day_of_week] [date] NULL,
	[first_day_of_month] [date] NULL,
	[last_day_of_month] [date] NULL,
	[first_day_of_quarter] [date] NULL,
	[last_day_of_quarter] [date] NULL,
	[first_day_of_year] [date] NULL,
	[last_day_of_year] [date] NULL,
	[mmyyyy] [char](6) NULL,
	[mmddyyyy] [char](10) NULL,
	[weekend_indr] [bit] NULL,
	[record_created_date] [datetime2](7) NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [dim_date_pkey] PRIMARY KEY CLUSTERED 
(
	[date_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_nurse]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_nurse](
	[nurse_key] [int] IDENTITY(160516,1) NOT NULL,
	[organization_key] [int] NULL,
	[nfp_start_date_key] [int] NULL,
	[nfp_end_date_key] [int] NULL,
	[role_start_date_key] [int] NULL,
	[role_end_date_key] [int] NULL,
	[team_start_date_key] [int] NULL,
	[team_end_date_key] [int] NULL,
	[source_system_key] [int] NULL,
	[nurse_id] [int] NULL,
	[nurse_first_name] [varchar](256) NULL,
	[nurse_last_name] [varchar](256) NULL,
	[nurse_address] [varchar](256) NULL,
	[nurse_city] [varchar](256) NULL,
	[nurse_state] [varchar](256) NULL,
	[nurse_zipcode] [varchar](256) NULL,
	[nurse_email] [varchar](256) NULL,
	[primary_role] [varchar](256) NULL,
	[primary_role_fte] [numeric](18, 0) NULL,
	[secondary_role] [varchar](256) NULL,
	[secondary_role_fte] [numeric](18, 0) NULL,
	[highest_degree] [varchar](256) NULL,
	[highest_nursing_degree] [varchar](256) NULL,
	[hire_reason] [varchar](256) NULL,
	[nurse_gender] [varchar](100) NULL,
	[nurse_ethnicity] [varchar](100) NULL,
	[nurse_single_race] [varchar](100) NULL,
	[nurse_birth_year] [int] NULL,
	[nurse_dob_mm_dd] [varchar](20) NULL,
	[current_expired_flag] [varchar](100) NULL,
	[record_created_date] [datetime2](7) NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [dim_nurse_pkey] PRIMARY KEY CLUSTERED 
(
	[nurse_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_survey_question]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_survey_question](
	[survey_question_key] [int] IDENTITY(160538,1) NOT NULL,
	[master_survey_id] [int] NOT NULL,
	[survey_name] [varchar](100) NOT NULL,
	[time_period] [varchar](75) NOT NULL,
	[time_period_key] [int] NULL,
	[survey_type] [varchar](256) NOT NULL,
	[survey_element_type] [varchar](256) NOT NULL,
	[question_number] [smallint] NOT NULL,
	[question] [varchar](3400) NOT NULL,
	[pseudonym] [varchar](256) NULL,
	[source_survey_element_id] [int] NULL,
	[current_expired_flag] [varchar](7) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [dim_survey_question_pkey] PRIMARY KEY CLUSTERED 
(
	[survey_question_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_organization]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_organization](
	[organization_key] [int] NULL,
	[nsoid] [int] NULL,
	[nso_name] [varchar](25) NULL,
	[nso_abbreviation] [varchar](20) NULL,
	[countryid] [int] NULL,
	[country_name] [varchar](25) NULL,
	[country_abbreviation] [varchar](5) NULL,
	[stateid] [int] NULL,
	[state_name] [varchar](25) NULL,
	[state_abbreviation] [varchar](2) NULL,
	[agencyid] [int] NULL,
	[agency_name] [varchar](50) NULL,
	[teamid] [int] NULL,
	[team_name] [varchar](50) NULL,
	[programid] [int] NULL,
	[program_name] [varchar](50) NULL,
	[program_type] [varchar](20) NULL
) ON [PRIMARY]
GO
/****** Object:  View [survey_views].[Agency_Profile_Update]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [survey_views].[Agency_Profile_Update] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
max(case sq.pseudonym when 'AGENCY_FUNDING01_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING01_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING01_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING01_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING01_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING01_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING01_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING02_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING02_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING02_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING02_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING02_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING02_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING02_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING03_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING03_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING03_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING03_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING03_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING03_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING03_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING04_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING04_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING04_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING04_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING04_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING04_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING04_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING05_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING05_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING05_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING05_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING05_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING05_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING05_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING06_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING06_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING06_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING06_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING06_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING06_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING06_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING07_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING07_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING07_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING07_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING07_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING07_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING07_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING08_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING08_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING08_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING08_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING08_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING08_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING08_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING09_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING09_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING09_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING09_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING09_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING09_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING09_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING10_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING10_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING10_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING10_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING10_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING10_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING10_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING11_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING11_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING11_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING11_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING11_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING11_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING11_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING12_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING12_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING12_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING12_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING12_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING12_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING12_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING13_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING13_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING13_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING13_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING13_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING13_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING13_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING14_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING14_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING14_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING14_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING14_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING14_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING14_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING15_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING15_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING15_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING15_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING15_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING15_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING15_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING16_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING16_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING16_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING16_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING16_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING16_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING16_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING17_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING17_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING17_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING17_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING17_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING17_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING17_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING18_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING18_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING18_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING18_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING18_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING18_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING18_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING19_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING19_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING19_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING19_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING19_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING19_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING19_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_0_FUNDER_NAME ' then  secured_value else null end) as AGENCY_FUNDING20_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_AMOUNT ' then  secured_value else null end) as AGENCY_FUNDING20_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_DF_GRANT_TYPE ' then  secured_value else null end) as AGENCY_FUNDING20_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_END_DATE ' then  secured_value else null end) as AGENCY_FUNDING20_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_FUNDER_TYPE ' then  secured_value else null end) as AGENCY_FUNDING20_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_START_DATE ' then  secured_value else null end) as AGENCY_FUNDING20_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_MEDICAID_TYPE ' then  secured_value else null end) as AGENCY_FUNDING20_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_INFO_1_CONTRACT_CAPACITY_FTE ' then  secured_value else null end) as AGENCY_INFO_1_CONTRACT_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_1_FUNDED_CAPACITY_FTE ' then  secured_value else null end) as AGENCY_INFO_1_FUNDED_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE01 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE01,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE02 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE02,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE03 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE03,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE04 ' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE04,
max(case sq.pseudonym when 'AGENCY_RESEARCH_0_INVOLVEMENT ' then  secured_value else null end) as AGENCY_RESEARCH_0_INVOLVEMENT,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_0_PROJECT_NAME ' then  secured_value else null end) as AGENCY_RESEARCH01_0_PROJECT_NAME,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_APPROVAL ' then  secured_value else null end) as AGENCY_RESEARCH01_1_APPROVAL,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_END_DATE ' then  secured_value else null end) as AGENCY_RESEARCH01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PI1 ' then  secured_value else null end) as AGENCY_RESEARCH01_1_PI1,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION ' then  secured_value else null end) as AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_START_DATE ' then  secured_value else null end) as AGENCY_RESEARCH01_1_START_DATE


   from survey_views.udf_secure_fact_survey_response('Agency Profile-Update',null) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
   
  
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
/****** Object:  Table [dbo].[fact_survey_response]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_survey_response](
	[survey_response_key] [int] IDENTITY(160572,1) NOT NULL,
	[survey_date_key] [int] NULL,
	[survey_question_key] [int] NULL,
	[client_key] [int] NULL,
	[nurse_key] [int] NULL,
	[child_key] [int] NULL,
	[organization_key] [int] NULL,
	[source_system_key] [int] NULL,
	[survey_response_id] [int] NOT NULL,
	[text_response] [varchar](256) NULL,
	[numeric_response] [numeric](18, 0) NULL,
	[date_response] [date] NULL,
	[boolean_response] [varchar](256) NULL,
	[clob_indicator] [varchar](256) NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [fact_survey_response_pkey] PRIMARY KEY CLUSTERED 
(
	[survey_response_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [survey_views].[Alternative_Encounter]    Script Date: 11/21/2017 3:18:53 PM ******/
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
	--ss.source_system_name	  
	null as DataSource,
    dc.client_key             as CL_EN_GEN_ID,
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
    inner  join  dim_nurse              dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
	--inner join dim_source_system		ss on fr.source_system_key			  = ss.source_system_key
  
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
    dc.client_id,
	--ss.source_system_name,
	xp.source_auditdate

GO
/****** Object:  View [survey_views].[ASQ_3]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Client_and_Infant_Health_or_TCM_Medicaid]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Client_Funding_Source]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Clinical_IPV_Assessment]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Community_Advisory_Board_Meeting]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Course_Completion]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[DANCE_Coding_Sheet]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Demographics]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'ADULTS_1_CARE_10 ' then  secured_value  else null end) as ADULTS_1_CARE_10,
	max(case sq.pseudonym when 'ADULTS_1_CARE_20 ' then  secured_value  else null end) as ADULTS_1_CARE_20,
	max(case sq.pseudonym when 'ADULTS_1_CARE_30 ' then  secured_value  else null end) as ADULTS_1_CARE_30,
	max(case sq.pseudonym when 'ADULTS_1_CARE_40 ' then  secured_value  else null end) as ADULTS_1_CARE_40,
	max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10 ' then  secured_value  else null end) as ADULTS_1_CARE_LESS10,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED ' then  secured_value  else null end) as ADULTS_1_COMPLETE_GED,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS ' then  secured_value  else null end) as ADULTS_1_COMPLETE_HS,
	max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO ' then  secured_value  else null end) as ADULTS_1_COMPLETE_HS_NO,
	max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE ' then  secured_value  else null end) as ADULTS_1_ED_ASSOCIATE,
	max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR ' then  secured_value  else null end) as ADULTS_1_ED_BACHELOR,
	max(case sq.pseudonym when 'ADULTS_1_ED_MASTER ' then  secured_value  else null end) as ADULTS_1_ED_MASTER,
	max(case sq.pseudonym when 'ADULTS_1_ED_NONE ' then  secured_value  else null end) as ADULTS_1_ED_NONE,
	max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD ' then  secured_value  else null end) as ADULTS_1_ED_POSTGRAD,
	max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE ' then  secured_value  else null end) as ADULTS_1_ED_SOME_COLLEGE,
	max(case sq.pseudonym when 'ADULTS_1_ED_TECH ' then  secured_value  else null end) as ADULTS_1_ED_TECH,
	max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN ' then  secured_value  else null end) as ADULTS_1_ED_UNKNOWN,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT ' then  secured_value  else null end) as ADULTS_1_ENROLL_FT,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO ' then  secured_value  else null end) as ADULTS_1_ENROLL_NO,
	max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT ' then  secured_value  else null end) as ADULTS_1_ENROLL_PT,
	max(case sq.pseudonym when 'ADULTS_1_INS_NO ' then  secured_value  else null end) as ADULTS_1_INS_NO,
	max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE ' then  secured_value  else null end) as ADULTS_1_INS_PRIVATE,
	max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC ' then  secured_value  else null end) as ADULTS_1_INS_PUBLIC,
	max(case sq.pseudonym when 'ADULTS_1_WORK_10 ' then  secured_value  else null end) as ADULTS_1_WORK_10,
	max(case sq.pseudonym when 'ADULTS_1_WORK_20 ' then  secured_value  else null end) as ADULTS_1_WORK_20,
	max(case sq.pseudonym when 'ADULTS_1_WORK_37 ' then  secured_value  else null end) as ADULTS_1_WORK_37,
	max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10 ' then  secured_value  else null end) as ADULTS_1_WORK_LESS10,
	max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY ' then  secured_value  else null end) as ADULTS_1_WORK_UNEMPLOY,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value  else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value  else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH ' then  secured_value  else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ URGENT_OTHER ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_OTHER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER ' then  secured_value  else null end) as CLIENT_CARE_0_ER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP ' then  secured_value  else null end) as CLIENT_CARE_0_ER_HOSP,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER ' then  secured_value  else null end) as CLIENT_CARE_0_ER_OTHER,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE ' then  secured_value  else null end) as CLIENT_CARE_0_ER_PURPOSE,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6 ' then  secured_value  else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
	max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_ER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6 ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
	max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES ' then  secured_value  else null end) as CLIENT_CARE_0_URGENT_TIMES,
	max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE ' then  secured_value  else null end) as CLIENT_ED_PROG_TYPE,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED ' then  secured_value  else null end) as CLIENT_EDUCATION_0_HS_GED,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE ' then  secured_value  else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP ' then  secured_value  else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
	max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE ' then  secured_value  else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
	max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME ' then  secured_value  else null end) as CLIENT_INCOME_0_HH_INCOME,
	max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES ' then  secured_value  else null end) as CLIENT_INCOME_1_HH_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY ' then  secured_value  else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
	max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT ' then  secured_value  else null end) as CLIENT_INCOME_AMOUNT,
	max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND ' then  secured_value  else null end) as CLIENT_INCOME_IN_KIND,
	max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER ' then  secured_value  else null end) as CLIENT_INCOME_INKIND_OTHER,
	max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES ' then  secured_value  else null end) as CLIENT_INCOME_OTHER_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES ' then  secured_value  else null end) as CLIENT_INCOME_SOURCES,
	max(case sq.pseudonym when 'CLIENT_INSURANCE ' then  secured_value  else null end) as CLIENT_INSURANCE,
	max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER ' then  secured_value  else null end) as CLIENT_INSURANCE_OTHER,
	max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE ' then  secured_value  else null end) as CLIENT_INSURANCE_TYPE,
	max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH ' then  secured_value  else null end) as CLIENT_LIVING_0_WITH,
	max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS ' then  secured_value  else null end) as CLIENT_LIVING_1_WITH_OTHERS,
	max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS ' then  secured_value  else null end) as CLIENT_LIVING_HOMELESS,
	max(case sq.pseudonym when 'CLIENT_LIVING_WHERE ' then  secured_value  else null end) as CLIENT_LIVING_WHERE,
	max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS ' then  secured_value  else null end) as CLIENT_MARITAL_0_STATUS,
	max(case sq.pseudonym when 'CLIENT_MILITARY ' then  secured_value  else null end) as CLIENT_MILITARY,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value  else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value  else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value  else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED ' then  secured_value  else null end) as CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED,
	max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE ' then  secured_value  else null end) as CLIENT_PROVIDE_CHILDCARE,
	max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS ' then  secured_value  else null end) as CLIENT_SCHOOL_MIDDLE_HS,
	max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING ' then  secured_value  else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
	max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS ' then  secured_value  else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
	max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO ' then  secured_value  else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value  else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.udf_secure_fact_survey_response('Demographics',null) fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  
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
/****** Object:  View [survey_views].[Demographics_Update]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Edinburgh_Postnatal_Depression_Scale]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Education_Registration]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Education_Registration_V2]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[GAD_7]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Goodwill_Indy_Additional_Referral_Data]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Health_Habits]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Home_Visit_Encounter]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Infant_Birth]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Infant_Health_Care]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Joint_Visit_Observation]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Joint_Visit_Observation_Form]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Maternal_Health_Assessment]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_12_Month_Infant]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_18_Months_Toddler]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_24_Month_Toddler]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_6_Months_Infant]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_Child_Intake]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_Primary_Caregiver_Closure]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[MN_Primary_Caregiver_Intake]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[New_Hire_Form]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[New_Hire_V2]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[NFP_Los_Angeles__Outreach_Marketing]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[NFP_Tribal_Project]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Nurse_Assessment]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[PHQ_9]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Profile_Of_Program_Staff_UPDATE]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Record_of_Team_Meetings_and_Case_Conferences]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Referrals_To_NFP_Program]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Relationship_Assessment]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Staff_Team_to_Team_Transfer_Request]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[STAR_Framework]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Supplemental_Discharge_Information]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[TCM_Finance_Log]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[TCM_ISP]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Telehealth_Form]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Telehealth_Pilot_Form]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[TEST_CASE_ASSESSMENT]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[TX_THV_Supplemental_Data_Form]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Unknown]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Use_Of_Government_and_Community_Services]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[WA_MIECHV_Supplemental_HVEF]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  View [survey_views].[Weekly_Supervision_Record]    Script Date: 11/21/2017 3:18:53 PM ******/
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
    dc.client_key             as CL_EN_GEN_ID,
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
/****** Object:  Table [survey_views].[ExportEntities]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[ExportEntities](
	[ExportProfileID] [int] NOT NULL,
	[ExportEntitiesID] [bigint] IDENTITY(1,1) NOT NULL,
	[SiteID] [int] NULL,
	[AgencyName] [nvarchar](200) NULL,
	[State] [varchar](2) NULL,
	[ExcludeTribal] [int] NULL,
	[ExportDisabled] [bit] NULL,
 CONSTRAINT [PK_ExportEntities] PRIMARY KEY CLUSTERED 
(
	[ExportEntitiesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [survey_views].[ExportProfile]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[ExportProfile](
	[ExportProfileID] [int] IDENTITY(1,1) NOT NULL,
	[ProfileName] [nvarchar](200) NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[ExportTypeID] [int] NULL,
	[EntityID] [bigint] NULL,
	[Active] [bit] NULL,
	[Web3FTPPath] [nvarchar](200) NULL,
	[Web3FTPFolder] [nvarchar](100) NULL,
	[IsSingleSite] [bit] NULL,
	[ExportDT] [datetime] NULL,
	[PublicKey] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_get_survey_etl_work]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [survey_views].[f_get_survey_etl_work]
(	
)
RETURNS TABLE 
AS
RETURN 
(
		select 

		ep.ProfileName,
		ee.AgencyName,
		ee.SiteID,
		ep.ExportProfileID,
		ep.ExportTypeID,

		case 
			when ep.ExportTypeID in (0,2,4) then 'BAA' 
			when ep.ExportTypeID in (1,3,5) then 'DUA'
			when ep.ExportTypeID in (6,7,8) then 'SA'
		else 'NA'
		end
		as hash_policy,

		case 
			when ep.ExportTypeID in (4,5,8) then 'BCP'
		else 'TAB' 
		end
		as export_format_code,

		case 
			when ep.ExportTypeID in (2,3,7) then 1  
		else 0
		end
		as miechv_only,

		ee.ExcludeTribal 
		as exclude_tribal

 
		from ExportProfile ep 
		inner join ExportEntities ee 
			on ep.ExportProfileID=ee.ExportProfileID

		where 
		ee.ExportDisabled=1

)
GO
/****** Object:  Table [dbo].[dim_birthing_attribute]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_birthing_attribute](
	[birthing_attribute_key] [int] IDENTITY(160459,1) NOT NULL,
	[multiple_birth] [varchar](256) NOT NULL,
	[child_stay_type] [varchar](256) NOT NULL,
	[delivery_type] [varchar](256) NOT NULL,
	[labor_type] [varchar](256) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_child]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_child](
	[child_key] [int] IDENTITY(160462,1) NOT NULL,
	[infant_id] [varchar](256) NULL,
	[client_key] [bigint] NULL,
	[child_date_of_birth_key] [int] NULL,
	[child_first_name] [varchar](256) NULL,
	[child_last_name] [varchar](256) NULL,
	[child_gender] [varchar](8) NULL,
	[child_ethnicity] [varchar](256) NULL,
	[child_single_race] [varchar](256) NULL,
	[child_race_bridge_key] [int] NULL,
	[source_system_key] [int] NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_child_birth_issue]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_child_birth_issue](
	[birth_issue_key] [int] IDENTITY(160465,1) NOT NULL,
	[birth_issue] [varchar](256) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_child_birth_issue_bridge]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_child_birth_issue_bridge](
	[child_issue_bridge_key] [int] NOT NULL,
	[birth_issue_key] [int] NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_child_birth_other_issue]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_child_birth_other_issue](
	[other_birth_issue_key] [int] IDENTITY(160472,1) NOT NULL,
	[other_birth_issue] [varchar](256) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_child_screening]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_child_screening](
	[child_screening_key] [int] IDENTITY(160475,1) NOT NULL,
	[newborn_screen] [varchar](256) NOT NULL,
	[hearing_screen] [varchar](256) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_client_referral]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_client_referral](
	[client_referral_key] [bigint] IDENTITY(160485,1) NOT NULL,
	[client_id] [varchar](20) NOT NULL,
	[referral_first_name] [varchar](256) NOT NULL,
	[referral_last_name] [varchar](256) NOT NULL,
	[referral_date_of_birth_key] [int] NULL,
	[referral_address1] [varchar](256) NOT NULL,
	[referral_address2] [varchar](256) NULL,
	[referral_city_state_zipcode] [varchar](256) NULL,
	[referral_home_phone] [varchar](20) NULL,
	[referral_cell_phone] [varchar](20) NULL,
	[referral_work_phone] [varchar](20) NULL,
	[referral_email] [varchar](256) NULL,
	[referral_primary_language] [varchar](256) NOT NULL,
	[primary_source_name] [varchar](256) NOT NULL,
	[primary_source_location] [varchar](256) NOT NULL,
	[secondary_source_name] [varchar](256) NOT NULL,
	[secondary_source_location] [varchar](256) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [dim_client_referral_pkey] PRIMARY KEY CLUSTERED 
(
	[client_referral_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_dismissal_transfer_reason]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_dismissal_transfer_reason](
	[dismissal_reason_key] [bigint] NULL,
	[dismissal_transfer_type] [varchar](9) NULL,
	[dismissal_transfer_reason] [varchar](93) NULL,
	[record_created_date] [datetime2](7) NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_encounter_location]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_encounter_location](
	[encounter_location_key] [int] IDENTITY(160497,1) NOT NULL,
	[encounter_location] [varchar](256) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_encounter_status]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_encounter_status](
	[encounter_status_key] [int] IDENTITY(160502,1) NOT NULL,
	[encounter_type] [varchar](256) NOT NULL,
	[encounter_status_name] [varchar](256) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL,
 CONSTRAINT [dim_encounter_status_pkey] PRIMARY KEY CLUSTERED 
(
	[encounter_status_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_meeting_type]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_meeting_type](
	[meeting_type_key] [int] IDENTITY(160511,1) NOT NULL,
	[meeting_type_name] [varchar](256) NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [dim_meeting_type_pkey] PRIMARY KEY CLUSTERED 
(
	[meeting_type_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_organization]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_organization](
	[organization_key] [int] IDENTITY(160521,1) NOT NULL,
	[nso_name] [varchar](25) NOT NULL,
	[nso_abbreviation] [varchar](20) NOT NULL,
	[country_name] [varchar](25) NOT NULL,
	[country_abbreviation] [varchar](5) NOT NULL,
	[state_name] [varchar](25) NOT NULL,
	[state_abbreviation] [varchar](2) NOT NULL,
	[agency_name] [varchar](50) NOT NULL,
	[team_name] [varchar](50) NOT NULL,
	[program_name] [varchar](50) NOT NULL,
	[program_type] [varchar](20) NOT NULL,
	[effective_start_date_key] [int] NOT NULL,
	[end_date_key] [int] NOT NULL,
	[current_expired_flag] [varchar](7) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_phase]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_phase](
	[phase_key] [int] IDENTITY(160524,1) NOT NULL,
	[phase_name] [varchar](256) NOT NULL,
	[phase_description] [varchar](256) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_race]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_race](
	[race_key] [int] IDENTITY(160527,1) NOT NULL,
	[race] [varchar](256) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_race_bridge]    Script Date: 11/21/2017 3:18:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_race_bridge](
	[race_bridge_key] [int] NOT NULL,
	[race_key] [int] NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_referral_source]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_referral_source](
	[referral_source_key] [int] IDENTITY(160532,1) NOT NULL,
	[referral_source_code] [varchar](2) NULL,
	[referral_source_name] [varchar](256) NOT NULL,
	[effective_start_date] [date] NOT NULL,
	[effective_end_date] [date] NOT NULL,
	[current_expired] [varchar](7) NULL,
	[record_created_date] [datetime2](7) NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_source_system]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_source_system](
	[source_system_key] [int] IDENTITY(160535,1) NOT NULL,
	[source_system_name] [varchar](256) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_time]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_time](
	[time_key] [int] IDENTITY(160543,1) NOT NULL,
	[actual_time] [varchar](256) NOT NULL,
	[military_time] [varchar](256) NOT NULL,
	[actual_hour] [varchar](256) NOT NULL,
	[military_hour] [varchar](256) NOT NULL,
	[actual_hour_minute] [varchar](256) NOT NULL,
	[military_hour_minute] [varchar](256) NOT NULL,
	[am_pm] [char](2) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL,
 CONSTRAINT [dim_time_pkey] PRIMARY KEY CLUSTERED 
(
	[time_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[dim_time_period]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dim_time_period](
	[time_period_key] [bigint] NULL,
	[time_period] [varchar](75) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[fact_birth]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_birth](
	[birth_key] [int] IDENTITY(160548,1) NOT NULL,
	[date_of_birth_key] [int] NULL,
	[client_key] [int] NULL,
	[child_key] [int] NULL,
	[organization_key] [int] NULL,
	[birthing_attribute_key] [int] NULL,
	[child_screening_key] [int] NULL,
	[other_birth_issue_key] [int] NULL,
	[gestational_age_weeks] [int] NULL,
	[mother_weight_gain] [smallint] NULL,
	[mothers_age_days] [int] NULL,
	[birth_weight_oz] [int] NULL,
	[birth_weight_grams] [int] NULL,
	[days_in_nicu] [smallint] NULL,
	[days_in_special_nursery] [smallint] NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[fact_client_discharge_transfer]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_client_discharge_transfer](
	[discharge_key] [int] IDENTITY(160551,1) NOT NULL,
	[discharge_date_key] [int] NULL,
	[client_key] [int] NULL,
	[organization_key] [int] NULL,
	[dismissal_reason_key] [int] NULL,
	[discharge_transfer_count] [int] NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[fact_client_enrollment]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_client_enrollment](
	[enrollment_key] [int] IDENTITY(160554,1) NOT NULL,
	[enrollment_date_key] [int] NULL,
	[client_key] [bigint] NULL,
	[nurse_key] [int] NULL,
	[case_number] [bigint] NULL,
	[date_nurse_assigned_key] [int] NULL,
	[organization_key] [int] NOT NULL,
	[mothers_age_days] [int] NULL,
	[gestational_age_weeks] [int] NULL,
	[enrollment_count] [smallint] NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[record_created_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[fact_encounter]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_encounter](
	[encounter_key] [int] IDENTITY(160557,1) NOT NULL,
	[encounter_date_key] [int] NOT NULL,
	[encounter_start_time_key] [varchar](20) NULL,
	[encounter_end_time_key] [varchar](20) NULL,
	[nurse_key] [int] NOT NULL,
	[client_key] [int] NOT NULL,
	[organization_key] [int] NOT NULL,
	[encounter_status_key] [int] NOT NULL,
	[encounter_location_key] [int] NOT NULL,
	[phase_key] [int] NOT NULL,
	[case_number] [int] NULL,
	[encounter_duration] [int] NULL,
	[my_health_percentage] [int] NULL,
	[my_home_percentage] [int] NULL,
	[my_life_percentage] [int] NULL,
	[my_child_percentage] [int] NULL,
	[my_family_percentage] [int] NULL,
	[gestational_age_weeks] [int] NULL,
	[child_age_months] [int] NULL,
	[client_involvement_score] [int] NULL,
	[material_conflict_score] [int] NULL,
	[material_understanding_score] [int] NULL,
	[encounter_count] [smallint] NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [fact_encounter_pkey] PRIMARY KEY CLUSTERED 
(
	[encounter_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[fact_meeting]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_meeting](
	[meeting_key] [int] IDENTITY(160563,1) NOT NULL,
	[meeting_date_key] [int] NULL,
	[organization_key] [int] NOT NULL,
	[meeting_type_key] [int] NOT NULL,
	[meeting_duration] [int] NULL,
	[meeting_count] [smallint] NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
 CONSTRAINT [fact_meeting_pkey] PRIMARY KEY CLUSTERED 
(
	[meeting_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[fact_nfp_referral]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_nfp_referral](
	[referral_key] [int] IDENTITY(160569,1) NOT NULL,
	[referral_date_key] [int] NULL,
	[client_referral_key] [int] NULL,
	[case_number] [int] NULL,
	[estimate_due_date_key] [int] NULL,
	[nurse_key] [int] NULL,
	[organization_key] [int] NULL,
	[referral_source_key] [int] NULL,
	[dismissal_reason_key] [int] NULL,
	[note_or_comment_key] [int] NULL,
	[mothers_age_days] [int] NULL,
	[gestational_age_weeks] [int] NULL,
	[referral_count] [int] NULL,
	[record_created_date] [datetime2](7) NULL,
	[record_modified_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[loader_log]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[loader_log](
	[batch_key] [int] IDENTITY(160577,1) NOT NULL,
	[process_key] [int] NULL,
	[batchstartdate] [datetime2](7) NULL,
	[batchenddate] [datetime2](7) NULL,
	[jobstartdate] [datetime2](7) NULL,
	[jobenddate] [datetime2](7) NULL,
	[jobname] [varchar](100) NULL,
	[completedbatchdate] [datetime2](7) NULL,
	[activebatchdate] [datetime2](7) NULL,
	[status] [varchar](100) NULL,
	[comments] [varchar](100) NULL,
	[file_name] [varchar](256) NULL,
 CONSTRAINT [loader_log_pkey] PRIMARY KEY CLUSTERED 
(
	[batch_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[loader_process]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[loader_process](
	[process_key] [int] IDENTITY(160582,1) NOT NULL,
	[process_name] [varchar](50) NULL,
 CONSTRAINT [loader_process_pkey] PRIMARY KEY CLUSTERED 
(
	[process_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[loader_processed_dates]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[loader_processed_dates](
	[processed_key] [int] IDENTITY(160587,1) NOT NULL,
	[startdate] [date] NULL,
	[enddate] [date] NULL,
	[batch_key] [int] NULL,
	[processed_date] [datetime2](7) NULL,
 CONSTRAINT [loader_processed_dates_pkey] PRIMARY KEY CLUSTERED 
(
	[processed_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_agency]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_agency](
	[agencyid] [int] NOT NULL,
	[stateid] [int] NULL,
	[agencyname] [varchar](100) NULL,
	[lastmodified] [datetime2](7) NULL,
	[insertdate] [datetime2](7) NULL,
 CONSTRAINT [xref_agency_pkey] PRIMARY KEY CLUSTERED 
(
	[agencyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_country]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_country](
	[countryid] [int] IDENTITY(160596,1) NOT NULL,
	[nsoid] [int] NULL,
	[countryname] [varchar](100) NULL,
	[countryabbr] [varchar](20) NULL,
	[lastmodified] [datetime2](7) NULL,
	[insertdate] [datetime2](7) NULL,
 CONSTRAINT [xref_country_pkey] PRIMARY KEY CLUSTERED 
(
	[countryid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_exclusion]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_exclusion](
	[agencyid] [int] NOT NULL,
	[agency_name] [varchar](50) NULL,
	[agency_type] [varchar](20) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_nso]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_nso](
	[nsoid] [int] IDENTITY(160603,1) NOT NULL,
	[nsoname] [varchar](100) NULL,
	[nsoabbr] [varchar](20) NULL,
	[lastmodified] [datetime2](7) NULL,
	[insertdate] [datetime2](7) NULL,
 CONSTRAINT [xref_nso_pkey] PRIMARY KEY CLUSTERED 
(
	[nsoid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_replace_lookup]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_replace_lookup](
	[surveyid] [int] NOT NULL,
	[master_survey_id] [int] NULL,
	[original_site_survey_name] [varchar](200) NOT NULL,
	[new_survey_name] [varchar](75) NULL,
	[time_period] [varchar](75) NOT NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_replace_survey_name]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_replace_survey_name](
	[original_site_survey_name] [varchar](100) NULL,
	[new_survey_name] [varchar](75) NULL,
	[time_period] [varchar](75) NULL,
	[record_created_date] [datetime2](7) NOT NULL,
	[record_modified_date] [datetime2](7) NULL,
	[time_period_key] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_state]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_state](
	[stateid] [int] IDENTITY(160620,1) NOT NULL,
	[countryid] [int] NOT NULL,
	[statename] [varchar](50) NULL,
	[stateabbr] [varchar](5) NULL,
	[lastmodifed] [datetime2](7) NULL,
	[insertdate] [datetime2](7) NULL,
 CONSTRAINT [xref_state_pkey] PRIMARY KEY CLUSTERED 
(
	[stateid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xref_team]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xref_team](
	[teamid] [int] NOT NULL,
	[agencyid] [int] NULL,
	[teamname] [varchar](100) NULL,
	[lastmodified] [datetime2](7) NULL,
	[insertdate] [datetime2](7) NULL,
 CONSTRAINT [xref_team_pkey] PRIMARY KEY CLUSTERED 
(
	[teamid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [survey_views].[etl_extract_types]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[etl_extract_types](
	[export_type_id] [int] NOT NULL,
	[export_profile_code] [char](1) NOT NULL,
	[extract_procedure] [varchar](500) NOT NULL,
	[extract_file_name] [varchar](100) NOT NULL,
	[field_hashing] [bit] NOT NULL,
	[include_tribal] [bit] NOT NULL,
	[include_at_risk] [bit] NOT NULL,
	[extract_format] [char](3) NOT NULL,
 CONSTRAINT [PK_etl_extract_types] PRIMARY KEY CLUSTERED 
(
	[export_profile_code] ASC,
	[export_type_id] ASC,
	[extract_procedure] ASC,
	[extract_file_name] ASC,
	[field_hashing] ASC,
	[include_tribal] ASC,
	[include_at_risk] ASC,
	[extract_format] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [survey_views].[pseudo_security]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[pseudo_security](
	[pseudonym] [varchar](150) NULL,
	[policy_codifier] [char](10) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [survey_views].[survey_export_logs]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[survey_export_logs](
	[occured] [datetime] NOT NULL,
	[export_profile_id] [int] NOT NULL,
	[export_profile_name] [varchar](150) NOT NULL,
	[process_message] [varchar](150) NOT NULL,
 CONSTRAINT [PK_survey_export_logs] PRIMARY KEY CLUSTERED 
(
	[occured] ASC,
	[export_profile_id] ASC,
	[export_profile_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[fact_encounter] ADD  DEFAULT ((1)) FOR [encounter_count]
GO
ALTER TABLE [dbo].[fact_meeting] ADD  DEFAULT ((1)) FOR [meeting_count]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_field_hashing]  DEFAULT ((1)) FOR [field_hashing]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_include_tribal]  DEFAULT ((0)) FOR [include_tribal]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_include_at_risk]  DEFAULT ((0)) FOR [include_at_risk]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_extract_format]  DEFAULT ('BCP') FOR [extract_format]
GO
ALTER TABLE [survey_views].[survey_export_logs] ADD  CONSTRAINT [DF_survey_export_logs_occured]  DEFAULT (getdate()) FOR [occured]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_export_logs_log_message]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_etl_export_logs_log_message]
(
	@p_export_profile_id int,
	@p_export_profile_name varchar(150),
	@p_message varchar(150)
) as
begin
set nocount on;

insert into survey_views.survey_export_logs (export_profile_id, export_profile_name, process_message)
values(@p_export_profile_id,@p_export_profile_name,@p_message);


end
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_exportprofiles_get_export_type_for_export_profile_id]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_etl_exportprofiles_get_export_type_for_export_profile_id]
(
	@p_export_profile_id int = null
)
as
begin
set nocount on;

select
ExportTypeID 
from survey_views.ExportProfile 
where ExportProfileID = @p_export_profile_id;

end;
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_exportprofiles_select]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_exportprofiles_select]
as
begin
set nocount on;

/** 
	provides a list of export profile id's to process for client extracts
**/

select distinct 
EE.ExportProfileID, 
EP.ProfileName
from survey_views.ExportEntities EE
inner join survey_views.ExportProfile EP 
on EP.ExportProfileID = EE.ExportProfileID
where EP.Active = 1 
and EE.ExcludeTribal = 0
and isnull(EE.ExportDisabled,0) != 1;



end;
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_exportprofiles_update_status]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [survey_views].[usp_etl_exportprofiles_update_status]
	@p_export_profile_id int,
	@p_result char(1)
AS
BEGIN
	SET NOCOUNT ON;





END
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Agency_Profile_Update]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Agency_Profile_Update] as  begin  select * from survey_views.Agency_Profile_Update end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Alternative_Encounter]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Alternative_Encounter]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as 
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CL_EN_GEN_ID]) as [CL_EN_GEN_ID] -- col name
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
      , s.AuditDate as  [DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_NO_REFERRAL]
      ,s.[CLIENT_SCREENED_SRVCS]
      ,null as [CLIENT_VISIT_SCHEDULE]
      , null as [Master_SurveyID]
      , null as [temp_time_start]
      , null  as [temp_time_end]
      ,s.[CLIENT_TIME_FROM_AMPM_ALT]
      ,s.[CLIENT_TIME_FROM_HR_ALT]
      ,s.[CLIENT_TIME_FROM_MIN_ALT]
      ,s.[CLIENT_TIME_TO_AMPM_ALT]
      ,s.[CLIENT_TIME_TO_HR_ALT]
      ,s.[CLIENT_TIME_TO_MIN_ALT]
      , null as [Old_CLIENT_TIME_0_START_ALT]
      , null as [Old_CLIENT_TIME_1_END_ALT]
      , null as [old_CLIENT_TIME_1_DURATION_ALT]
      , null as [temp_DURATION]
      , null as [LastModified]
from survey_views.Alternative_Encounter  s 

where 

s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)






end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_ASQ_3]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_ASQ_3] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Client_and_Infant_Health_or_TCM_Medicaid]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Client_and_Infant_Health_or_TCM_Medicaid] as  begin  select * from survey_views.Client_and_Infant_Health_or_TCM_Medicaid end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Client_Funding_Source]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Client_Funding_Source]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
      --,s.[Archive_Record]					   
	  ,s.[CLIENT_FUNDING_0_SOURCE_OTHER4]     
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER5]     
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER6]     
      ,s.[CLIENT_FUNDING_1_END_OTHER4]        
      ,s.[CLIENT_FUNDING_1_END_OTHER5]        
      ,s.[CLIENT_FUNDING_1_END_OTHER6]        
      ,s.[CLIENT_FUNDING_1_START_OTHER4]      
      ,s.[CLIENT_FUNDING_1_START_OTHER5]      
      ,s.[CLIENT_FUNDING_1_START_OTHER6]      
from survey_views.Client_Funding_Source s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)


end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Clinical_IPV_Assessment]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Clinical_IPV_Assessment] as  begin  select * from survey_views.Clinical_IPV_Assessment end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Community_Advisory_Board_Meeting]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Community_Advisory_Board_Meeting] as  begin  select * from survey_views.Community_Advisory_Board_Meeting end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Course_Completion]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Course_Completion] as  begin  select * from survey_views.Course_Completion end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_DANCE_Coding_Sheet]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_DANCE_Coding_Sheet]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
	
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
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Demographics]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Demographics]
	@p_requested_security_policy	char(10) = null,
	@p_profile_id					int = null
as
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
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
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
    --  ,s.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]
   --   ,s.[CLIENT_PERSONAL_0_RACE]
     -- ,s.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]
      ,s.[CLIENT_0_ID_AGENCY]
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
      ,s.[CLIENT_INCOME_INKIND_OTHER]
      ,s.[CLIENT_INCOME_OTHER_SOURCES]
      --,s.[CLIENT_BC_1_TYPES_NEXT6]
      --,s.[CLIENT_SUBPREG_1_EDD]
      ,s.[CLIENT_CARE_0_ER_PURPOSE]
      ,s.[CLIENT_CARE_0_URGENT_PURPOSE]
     -- ,s.[CLIENT_CARE_0_ URGENT_OTHER]
      ,s.[CLIENT_CARE_0_ER_OTHER]
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
from survey_views.udf_select_Demographics(@p_requested_security_policy) s

where 

s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, 0) s)



	
	
end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Demographics_Update]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Demographics_Update] as  begin  select * from survey_views.Demographics_Update end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Edinburgh_Postnatal_Depression_Scale]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Edinburgh_Postnatal_Depression_Scale] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)




end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Education_Registration]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Education_Registration] as  begin  select * from survey_views.Education_Registration end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Education_Registration_V2]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Education_Registration_V2] as  begin  select * from survey_views.Education_Registration_V2 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_GAD_7]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_GAD_7]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

select 

		   s.[SurveyResponseID]
		  ,s.[ElementsProcessed]
		  ,s.[SurveyID]
		  --,s.[Master_SurveyID]
		  , null as Master_SurveyID
		  ,s.[SurveyDate]
		  ,s.[AuditDate]
		  , survey_views.f_hash_field(s.CL_EN_GEN_ID,@p_Encrypt) as [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  , survey_views.f_hash_field(s.[ClientID],@p_Encrypt) AS ClientID
		  ,s.[RespondentID]
		  --,s.[DW_AuditDate]
		, null as DW_AuditDate
		  --,s.[DataSource]
		, null as DataSource
		  ,s.[CLIENT_GAD7_AFRAID]
		  ,s.[CLIENT_GAD7_CTRL_WORRY]
		  ,s.[CLIENT_GAD7_IRRITABLE]
		  ,s.[CLIENT_GAD7_NERVOUS]
		  ,s.[CLIENT_GAD7_PROBS_DIFFICULT]
		  ,s.[CLIENT_GAD7_RESTLESS]
		  ,s.[CLIENT_GAD7_TRBL_RELAX]
		  ,s.[CLIENT_GAD7_WORRY]
		  , survey_views.f_hash_field(s.[CLIENT_0_ID_NSO],@p_Encrypt) AS [CLIENT_0_ID_NSO]
		  , survey_views.f_hash_field(s.[CLIENT_PERSONAL_0_NAME_FIRST],@p_Encrypt) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  , survey_views.f_hash_field(s.[CLIENT_PERSONAL_0_NAME_LAST],@p_Encrypt) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,s.[CLIENT_GAD7_TOTAL]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[NURSE_PERSONAL_0_NAME]

from survey_views.GAD_7  s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)


end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Goodwill_Indy_Additional_Referral_Data]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Goodwill_Indy_Additional_Referral_Data] as  begin  select * from survey_views.Goodwill_Indy_Additional_Referral_Data end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Health_Habits]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Health_Habits] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  
set nocount on;

select 
 s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)





end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Home_Visit_Encounter]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Home_Visit_Encounter] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
/****** Object:  StoredProcedure [survey_views].[usp_select_Infant_Birth]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Infant_Birth] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as 
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
 s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)




 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Infant_Health_Care]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Infant_Health_Care] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)


end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Joint_Visit_Observation]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Joint_Visit_Observation] as  begin  select * from survey_views.Joint_Visit_Observation end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Joint_Visit_Observation_Form]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Joint_Visit_Observation_Form] as  begin  select * from survey_views.Joint_Visit_Observation_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Maternal_Health_Assessment]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Maternal_Health_Assessment]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  
set nocount on;

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_12_Month_Infant]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_12_Month_Infant] as  begin  select * from survey_views.MN_12_Month_Infant end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_18_Months_Toddler]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_18_Months_Toddler] as  begin  select * from survey_views.MN_18_Months_Toddler end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_24_Month_Toddler]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_24_Month_Toddler] as  begin  select * from survey_views.MN_24_Month_Toddler end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_6_Months_Infant]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_6_Months_Infant] as  begin  select * from survey_views.MN_6_Months_Infant end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_Child_Intake]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Child_Intake] as  begin  select * from survey_views.MN_Child_Intake end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_Primary_Caregiver_Closure]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Primary_Caregiver_Closure] as  begin  select * from survey_views.MN_Primary_Caregiver_Closure end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_MN_Primary_Caregiver_Intake]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Primary_Caregiver_Intake] as  begin  select * from survey_views.MN_Primary_Caregiver_Intake end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_New_Hire_Form]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_New_Hire_Form] as  begin  select * from survey_views.New_Hire_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_New_Hire_V2]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_New_Hire_V2] as  begin  select * from survey_views.New_Hire_V2 end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_NFP_Los_Angeles__Outreach_Marketing]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_NFP_Los_Angeles__Outreach_Marketing] as  begin  select * from survey_views.NFP_Los_Angeles__Outreach_Marketing end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_NFP_Tribal_Project]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_NFP_Tribal_Project]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as
begin  

set nocount on;

select s.[SurveyResponseID]
		  ,s.[ElementsProcessed]
		  ,s.[SurveyID]
		  ,s.[SurveyDate]
		  ,s.[AuditDate]
		  ,survey_views.f_hash_field(s.[CL_EN_GEN_ID],@p_Encrypt) AS [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  ,survey_views.f_hash_field(s.[ClientID],@p_Encrypt) AS [ClientID]
		  ,s.[RespondentID]
		  --,s.[DW_AuditDate]
		  , null as DW_AuditDate
		  ,s.[CLIENT_TRIBAL_0_PARITY]
		   ,survey_views.f_hash_field(s.[CLIENT_PERSONAL_0_NAME_FIRST],@p_Encrypt) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		   ,survey_views.f_hash_field(s.[CLIENT_PERSONAL_0_NAME_LAST],@p_Encrypt) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[NURSE_PERSONAL_0_NAME]
		  --s.[DataSource]
		  , null as DataSource
		  ,s.[CLIENT_TRIBAL_CHILD_1_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_10_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_2_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_3_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_4_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_5_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_6_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_7_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_8_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_9_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_1_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_10_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_2_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_3_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_4_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_5_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_6_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_7_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_8_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_9_DOB]
		  --,s.[Master_SurveyID]
		  , null as Master_SurveyID

	from survey_views.NFP_Tribal_Project s

	where
	s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)





end; 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Nurse_Assessment]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Nurse_Assessment] as  begin  select * from survey_views.Nurse_Assessment end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_PHQ_9]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_PHQ_9] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Profile_Of_Program_Staff_UPDATE]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Profile_Of_Program_Staff_UPDATE] as  begin  select * from survey_views.Profile_Of_Program_Staff_UPDATE end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Record_of_Team_Meetings_and_Case_Conferences]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Record_of_Team_Meetings_and_Case_Conferences] as  begin  select * from survey_views.Record_of_Team_Meetings_and_Case_Conferences end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Referrals_To_NFP_Program]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Referrals_To_NFP_Program] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  
set nocount on;


select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)




end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Relationship_Assessment]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Relationship_Assessment] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

set nocount on;

select 
 s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Staff_Team_to_Team_Transfer_Request]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Staff_Team_to_Team_Transfer_Request] as  begin  select * from survey_views.Staff_Team_to_Team_Transfer_Request end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_STAR_Framework]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_STAR_Framework] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
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
      ,s.[CL_EN_GEN_ID]
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
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)




end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Supplemental_Discharge_Information]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Supplemental_Discharge_Information] as  begin  select * from survey_views.Supplemental_Discharge_Information end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TCM_Finance_Log]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TCM_Finance_Log] as  begin  select * from survey_views.TCM_Finance_Log end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TCM_ISP]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TCM_ISP] as  begin  select * from survey_views.TCM_ISP end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Telehealth_Form]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Telehealth_Form] as  begin  select * from survey_views.Telehealth_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Telehealth_Pilot_Form]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Telehealth_Pilot_Form] as  begin  select * from survey_views.Telehealth_Pilot_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TEST_CASE_ASSESSMENT]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TEST_CASE_ASSESSMENT] as  begin  select * from survey_views.TEST_CASE_ASSESSMENT end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_TX_THV_Supplemental_Data_Form]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_TX_THV_Supplemental_Data_Form] as  begin  select * from survey_views.TX_THV_Supplemental_Data_Form end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Unknown]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Unknown] as  begin  select * from survey_views.Unknown end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Use_Of_Government_and_Community_Services]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Use_Of_Government_and_Community_Services]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

set nocount on;

select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
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
     -- ,s.[Archive_Record]						
      ,s.[SERVICE_USE_0_INTERVENTION_45DAYS]	
from survey_views.Use_Of_Government_and_Community_Services s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_WA_MIECHV_Supplemental_HVEF]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_WA_MIECHV_Supplemental_HVEF] as  begin  select * from survey_views.WA_MIECHV_Supplemental_HVEF end 
GO
/****** Object:  StoredProcedure [survey_views].[usp_select_Weekly_Supervision_Record]    Script Date: 11/21/2017 3:18:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Weekly_Supervision_Record] as  begin  select * from survey_views.Weekly_Supervision_Record end 
GO
