create function survey_views.f_select_Agency_Profile_Update
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
	max(case sq.pseudonym when 'AGENCY_FUNDING01_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING01_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING01_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING01_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING01_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING01_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING01_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING01_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING02_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING02_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING02_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING02_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING02_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING02_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING02_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING02_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING03_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING03_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING03_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING03_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING03_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING03_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING03_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING03_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING04_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING04_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING04_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING04_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING04_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING04_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING04_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING04_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING05_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING05_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING05_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING05_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING05_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING05_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING05_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING05_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING06_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING06_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING06_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING06_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING06_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING06_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING06_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING06_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING07_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING07_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING07_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING07_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING07_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING07_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING07_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING07_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING08_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING08_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING08_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING08_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING08_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING08_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING08_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING08_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING09_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING09_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING09_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING09_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING09_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING09_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING09_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING09_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING10_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING10_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING10_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING10_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING10_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING10_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING10_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING10_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING11_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING11_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING11_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING11_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING11_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING11_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING11_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING11_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING12_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING12_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING12_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING12_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING12_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING12_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING12_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING12_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING13_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING13_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING13_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING13_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING13_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING13_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING13_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING13_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING14_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING14_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING14_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING14_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING14_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING14_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING14_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING14_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING15_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING15_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING15_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING15_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING15_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING15_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING15_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING15_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING16_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING16_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING16_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING16_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING16_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING16_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING16_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING16_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING17_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING17_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING17_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING17_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING17_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING17_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING17_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING17_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING18_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING18_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING18_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING18_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING18_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING18_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING18_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING18_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING19_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING19_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING19_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING19_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING19_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING19_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING19_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING19_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_0_FUNDER_NAME' then  secured_value else null end) as AGENCY_FUNDING20_0_FUNDER_NAME,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_AMOUNT' then  secured_value else null end) as AGENCY_FUNDING20_1_AMOUNT,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_DF_GRANT_TYPE' then  secured_value else null end) as AGENCY_FUNDING20_1_DF_GRANT_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_END_DATE' then  secured_value else null end) as AGENCY_FUNDING20_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_FUNDER_TYPE' then  secured_value else null end) as AGENCY_FUNDING20_1_FUNDER_TYPE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_1_START_DATE' then  secured_value else null end) as AGENCY_FUNDING20_1_START_DATE,
max(case sq.pseudonym when 'AGENCY_FUNDING20_MEDICAID_TYPE' then  secured_value else null end) as AGENCY_FUNDING20_MEDICAID_TYPE,
max(case sq.pseudonym when 'AGENCY_INFO_1_CONTRACT_CAPACITY_FTE' then  secured_value else null end) as AGENCY_INFO_1_CONTRACT_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_1_FUNDED_CAPACITY_FTE' then  secured_value else null end) as AGENCY_INFO_1_FUNDED_CAPACITY_FTE,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE01' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE01,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE02' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE02,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE03' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE03,
max(case sq.pseudonym when 'AGENCY_INFO_BOARD_0_MEETING_DATE04' then  secured_value else null end) as AGENCY_INFO_BOARD_0_MEETING_DATE04,
max(case sq.pseudonym when 'AGENCY_RESEARCH_0_INVOLVEMENT' then  secured_value else null end) as AGENCY_RESEARCH_0_INVOLVEMENT,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_0_PROJECT_NAME' then  secured_value else null end) as AGENCY_RESEARCH01_0_PROJECT_NAME,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_APPROVAL' then  secured_value else null end) as AGENCY_RESEARCH01_1_APPROVAL,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_END_DATE' then  secured_value else null end) as AGENCY_RESEARCH01_1_END_DATE,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PI1' then  secured_value else null end) as AGENCY_RESEARCH01_1_PI1,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION' then  secured_value else null end) as AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION,
max(case sq.pseudonym when 'AGENCY_RESEARCH01_1_START_DATE' then  secured_value else null end) as AGENCY_RESEARCH01_1_START_DATE



     from survey_views.f_secure_fact_survey_response('Agency Profile-Update',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Alternative_Encounter
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_ALT_0_COMMENTS_ALT' then  secured_value else null end) as CLIENT_ALT_0_COMMENTS_ALT,
max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT' then  secured_value else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT,
max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT' then  secured_value else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_ALT' then  secured_value else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_ALT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_ALT' then  secured_value else null end) as CLIENT_DOMAIN_0_FRNDFAM_ALT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_ALT' then  secured_value else null end) as CLIENT_DOMAIN_0_LIFECOURSE_ALT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_ALT' then  secured_value else null end) as CLIENT_DOMAIN_0_MATERNAL_ALT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT' then  secured_value else null end) as CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_ALT' then  secured_value else null end) as CLIENT_DOMAIN_0_TOTAL_ALT,
max(case sq.pseudonym when 'CLIENT_NO_REFERRAL' then  secured_value else null end) as CLIENT_NO_REFERRAL,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS' then  secured_value else null end) as CLIENT_SCREENED_SRVCS,
max(case sq.pseudonym when 'CLIENT_TALKED_0_WITH_ALT' then  secured_value else null end) as CLIENT_TALKED_0_WITH_ALT,
max(case sq.pseudonym when 'CLIENT_TALKED_1_WITH_OTHER_ALT' then  secured_value else null end) as CLIENT_TALKED_1_WITH_OTHER_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_0_START_ALT' then  secured_value else null end) as CLIENT_TIME_0_START_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_ALT' then  secured_value else null end) as CLIENT_TIME_1_DURATION_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_1_END_ALT' then  secured_value else null end) as CLIENT_TIME_1_END_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM_ALT' then  secured_value else null end) as CLIENT_TIME_FROM_AMPM_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR_ALT' then  secured_value else null end) as CLIENT_TIME_FROM_HR_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN_ALT' then  secured_value else null end) as CLIENT_TIME_FROM_MIN_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM_ALT' then  secured_value else null end) as CLIENT_TIME_TO_AMPM_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_TO_HR_ALT' then  secured_value else null end) as CLIENT_TIME_TO_HR_ALT,
max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN_ALT' then  secured_value else null end) as CLIENT_TIME_TO_MIN_ALT,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Alternative Encounter',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_ASQ_3
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM' then  secured_value else null end) as INFANT_AGES_STAGES_1_COMM,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR' then  secured_value else null end) as INFANT_AGES_STAGES_1_FMOTOR,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR' then  secured_value else null end) as INFANT_AGES_STAGES_1_GMOTOR,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL' then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE' then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOLVE,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_COMM,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_FINE,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('ASQ-3',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Client_and_Infant_Health_or_TCM_Medicaid
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
CLIENT_PERSONAL_0_NAME_LAST varchar(256)

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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST



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

Go

create function survey_views.f_select_Client_Funding_Source
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
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_COM' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_COM,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER1' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER1,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER2' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER2,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER3' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER3,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER4' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER4,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER5' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER5,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER6' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER6,
max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_PFS' then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_PFS,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_COM' then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_COM,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_FORM' then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_FORM,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_TRIBAL' then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER1' then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER1,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER2' then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER2,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER3' then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER3,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER4' then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER4,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER5' then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER5,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER6' then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER6,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_PFS' then  secured_value else null end) as CLIENT_FUNDING_1_END_PFS,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_COM' then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_COM,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_FORM' then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_FORM,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_TRIBAL' then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_TRIBAL,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER1' then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER1,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER2' then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER2,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER3' then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER3,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER4' then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER4,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER5' then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER5,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER6' then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER6,
max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_PFS' then  secured_value else null end) as CLIENT_FUNDING_1_START_PFS,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Client Funding Source',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Clinical_IPV_Assessment
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'IPV_AFRAID' then  secured_value else null end) as IPV_AFRAID,
max(case sq.pseudonym when 'IPV_CHILD_SAFETY' then  secured_value else null end) as IPV_CHILD_SAFETY,
max(case sq.pseudonym when 'IPV_CONTROLING' then  secured_value else null end) as IPV_CONTROLING,
max(case sq.pseudonym when 'IPV_FORCED_SEX' then  secured_value else null end) as IPV_FORCED_SEX,
max(case sq.pseudonym when 'IPV_INDICATED' then  secured_value else null end) as IPV_INDICATED,
max(case sq.pseudonym when 'IPV_INSULTED' then  secured_value else null end) as IPV_INSULTED,
max(case sq.pseudonym when 'IPV_PHYSICALLY_HURT' then  secured_value else null end) as IPV_PHYSICALLY_HURT,
max(case sq.pseudonym when 'IPV_PRN_REASON' then  secured_value else null end) as IPV_PRN_REASON,
max(case sq.pseudonym when 'IPV_Q1_4_SCORE' then  secured_value else null end) as IPV_Q1_4_SCORE,
max(case sq.pseudonym when 'IPV_SCREAMED' then  secured_value else null end) as IPV_SCREAMED,
max(case sq.pseudonym when 'IPV_THREATENED' then  secured_value else null end) as IPV_THREATENED,
max(case sq.pseudonym when 'IPV_TOOL_USED' then  secured_value else null end) as IPV_TOOL_USED,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Community_Advisory_Board_Meeting
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
	max(case sq.pseudonym when 'CAB_MTG_DATE' then  secured_value else null end) as CAB_MTG_DATE



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

Go

create function survey_views.f_select_Course_Completion
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
	COURSE_COMPLETION_0_DATE1-11 varchar(256),
COURSE_COMPLETION_0_NAME1-11 varchar(256)

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
	max(case sq.pseudonym when 'COURSE_COMPLETION_0_DATE1-11' then  secured_value else null end) as COURSE_COMPLETION_0_DATE1-11,
max(case sq.pseudonym when 'COURSE_COMPLETION_0_NAME1-11' then  secured_value else null end) as COURSE_COMPLETION_0_NAME1-11



     from survey_views.f_secure_fact_survey_response('Course Completion',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_DANCE_Coding_Sheet
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_ACTIVITY_DURATION' then  secured_value else null end) as CLIENT_ACTIVITY_DURATION,
max(case sq.pseudonym when 'CLIENT_CAC_COMMENTS' then  secured_value else null end) as CLIENT_CAC_COMMENTS,
max(case sq.pseudonym when 'CLIENT_CAC_NA' then  secured_value else null end) as CLIENT_CAC_NA,
max(case sq.pseudonym when 'CLIENT_CAC_PER' then  secured_value else null end) as CLIENT_CAC_PER,
max(case sq.pseudonym when 'CLIENT_CHILD_AGE' then  secured_value else null end) as CLIENT_CHILD_AGE,
max(case sq.pseudonym when 'CLIENT_CHILD_DURATION' then  secured_value else null end) as CLIENT_CHILD_DURATION,
max(case sq.pseudonym when 'CLIENT_CI_COMMENTS' then  secured_value else null end) as CLIENT_CI_COMMENTS,
max(case sq.pseudonym when 'CLIENT_CI_NA' then  secured_value else null end) as CLIENT_CI_NA,
max(case sq.pseudonym when 'CLIENT_CI_PER' then  secured_value else null end) as CLIENT_CI_PER,
max(case sq.pseudonym when 'CLIENT_EPA_COMMENTS' then  secured_value else null end) as CLIENT_EPA_COMMENTS,
max(case sq.pseudonym when 'CLIENT_EPA_NA' then  secured_value else null end) as CLIENT_EPA_NA,
max(case sq.pseudonym when 'CLIENT_EPA_PER' then  secured_value else null end) as CLIENT_EPA_PER,
max(case sq.pseudonym when 'CLIENT_LS_COMMENTS' then  secured_value else null end) as CLIENT_LS_COMMENTS,
max(case sq.pseudonym when 'CLIENT_LS_NA' then  secured_value else null end) as CLIENT_LS_NA,
max(case sq.pseudonym when 'CLIENT_LS_PER' then  secured_value else null end) as CLIENT_LS_PER,
max(case sq.pseudonym when 'CLIENT_NCCO_COMMENTS' then  secured_value else null end) as CLIENT_NCCO_COMMENTS,
max(case sq.pseudonym when 'CLIENT_NCCO_NA' then  secured_value else null end) as CLIENT_NCCO_NA,
max(case sq.pseudonym when 'CLIENT_NCCO_PER' then  secured_value else null end) as CLIENT_NCCO_PER,
max(case sq.pseudonym when 'CLIENT_NI_COMMENTS' then  secured_value else null end) as CLIENT_NI_COMMENTS,
max(case sq.pseudonym when 'CLIENT_NI_NA' then  secured_value else null end) as CLIENT_NI_NA,
max(case sq.pseudonym when 'CLIENT_NI_PER' then  secured_value else null end) as CLIENT_NI_PER,
max(case sq.pseudonym when 'CLIENT_NT_COMMENTS' then  secured_value else null end) as CLIENT_NT_COMMENTS,
max(case sq.pseudonym when 'CLIENT_NT_NA' then  secured_value else null end) as CLIENT_NT_NA,
max(case sq.pseudonym when 'CLIENT_NT_PER' then  secured_value else null end) as CLIENT_NT_PER,
max(case sq.pseudonym when 'CLIENT_NVC_COMMENTS' then  secured_value else null end) as CLIENT_NVC_COMMENTS,
max(case sq.pseudonym when 'CLIENT_NVC_NA' then  secured_value else null end) as CLIENT_NVC_NA,
max(case sq.pseudonym when 'CLIENT_NVC_PER' then  secured_value else null end) as CLIENT_NVC_PER,
max(case sq.pseudonym when 'CLIENT_PC_COMMENTS' then  secured_value else null end) as CLIENT_PC_COMMENTS,
max(case sq.pseudonym when 'CLIENT_PC_NA' then  secured_value else null end) as CLIENT_PC_NA,
max(case sq.pseudonym when 'CLIENT_PC_PER' then  secured_value else null end) as CLIENT_PC_PER,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PO_COMMENTS' then  secured_value else null end) as CLIENT_PO_COMMENTS,
max(case sq.pseudonym when 'CLIENT_PO_NA' then  secured_value else null end) as CLIENT_PO_NA,
max(case sq.pseudonym when 'CLIENT_PO_PER' then  secured_value else null end) as CLIENT_PO_PER,
max(case sq.pseudonym when 'CLIENT_PRA_COMMENTS' then  secured_value else null end) as CLIENT_PRA_COMMENTS,
max(case sq.pseudonym when 'CLIENT_PRA_NA' then  secured_value else null end) as CLIENT_PRA_NA,
max(case sq.pseudonym when 'CLIENT_PRA_PER' then  secured_value else null end) as CLIENT_PRA_PER,
max(case sq.pseudonym when 'CLIENT_RD_COMMENTS' then  secured_value else null end) as CLIENT_RD_COMMENTS,
max(case sq.pseudonym when 'CLIENT_RD_NA' then  secured_value else null end) as CLIENT_RD_NA,
max(case sq.pseudonym when 'CLIENT_RD_PER' then  secured_value else null end) as CLIENT_RD_PER,
max(case sq.pseudonym when 'CLIENT_RP_COMMENTS' then  secured_value else null end) as CLIENT_RP_COMMENTS,
max(case sq.pseudonym when 'CLIENT_RP_NA' then  secured_value else null end) as CLIENT_RP_NA,
max(case sq.pseudonym when 'CLIENT_RP_PER' then  secured_value else null end) as CLIENT_RP_PER,
max(case sq.pseudonym when 'CLIENT_SCA_COMMENTS' then  secured_value else null end) as CLIENT_SCA_COMMENTS,
max(case sq.pseudonym when 'CLIENT_SCA_NA' then  secured_value else null end) as CLIENT_SCA_NA,
max(case sq.pseudonym when 'CLIENT_SCA_PER' then  secured_value else null end) as CLIENT_SCA_PER,
max(case sq.pseudonym when 'CLIENT_SE_COMMENTS' then  secured_value else null end) as CLIENT_SE_COMMENTS,
max(case sq.pseudonym when 'CLIENT_SE_NA' then  secured_value else null end) as CLIENT_SE_NA,
max(case sq.pseudonym when 'CLIENT_SE_PER' then  secured_value else null end) as CLIENT_SE_PER,
max(case sq.pseudonym when 'CLIENT_VE_COMMENTS' then  secured_value else null end) as CLIENT_VE_COMMENTS,
max(case sq.pseudonym when 'CLIENT_VE_NA' then  secured_value else null end) as CLIENT_VE_NA,
max(case sq.pseudonym when 'CLIENT_VE_PER' then  secured_value else null end) as CLIENT_VE_PER,
max(case sq.pseudonym when 'CLIENT_VEC_COMMENTS' then  secured_value else null end) as CLIENT_VEC_COMMENTS,
max(case sq.pseudonym when 'CLIENT_VEC_NA' then  secured_value else null end) as CLIENT_VEC_NA,
max(case sq.pseudonym when 'CLIENT_VEC_PER' then  secured_value else null end) as CLIENT_VEC_PER,
max(case sq.pseudonym when 'CLIENT_VISIT_VARIABLES' then  secured_value else null end) as CLIENT_VISIT_VARIABLES,
max(case sq.pseudonym when 'CLIENT_VQ_COMMENTS' then  secured_value else null end) as CLIENT_VQ_COMMENTS,
max(case sq.pseudonym when 'CLIENT_VQ_NA' then  secured_value else null end) as CLIENT_VQ_NA,
max(case sq.pseudonym when 'CLIENT_VQ_PER' then  secured_value else null end) as CLIENT_VQ_PER,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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
return;
end

Go

create function survey_views.f_select_Demographics_Update
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
	max(case sq.pseudonym when 'ADULTS_1_CARE_10' then  secured_value else null end) as ADULTS_1_CARE_10,
max(case sq.pseudonym when 'ADULTS_1_CARE_20' then  secured_value else null end) as ADULTS_1_CARE_20,
max(case sq.pseudonym when 'ADULTS_1_CARE_30' then  secured_value else null end) as ADULTS_1_CARE_30,
max(case sq.pseudonym when 'ADULTS_1_CARE_40' then  secured_value else null end) as ADULTS_1_CARE_40,
max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10' then  secured_value else null end) as ADULTS_1_CARE_LESS10,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED' then  secured_value else null end) as ADULTS_1_COMPLETE_GED,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS' then  secured_value else null end) as ADULTS_1_COMPLETE_HS,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO' then  secured_value else null end) as ADULTS_1_COMPLETE_HS_NO,
max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE' then  secured_value else null end) as ADULTS_1_ED_ASSOCIATE,
max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR' then  secured_value else null end) as ADULTS_1_ED_BACHELOR,
max(case sq.pseudonym when 'ADULTS_1_ED_MASTER' then  secured_value else null end) as ADULTS_1_ED_MASTER,
max(case sq.pseudonym when 'ADULTS_1_ED_NONE' then  secured_value else null end) as ADULTS_1_ED_NONE,
max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD' then  secured_value else null end) as ADULTS_1_ED_POSTGRAD,
max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE' then  secured_value else null end) as ADULTS_1_ED_SOME_COLLEGE,
max(case sq.pseudonym when 'ADULTS_1_ED_TECH' then  secured_value else null end) as ADULTS_1_ED_TECH,
max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN' then  secured_value else null end) as ADULTS_1_ED_UNKNOWN,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT' then  secured_value else null end) as ADULTS_1_ENROLL_FT,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO' then  secured_value else null end) as ADULTS_1_ENROLL_NO,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT' then  secured_value else null end) as ADULTS_1_ENROLL_PT,
max(case sq.pseudonym when 'ADULTS_1_INS_NO' then  secured_value else null end) as ADULTS_1_INS_NO,
max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE' then  secured_value else null end) as ADULTS_1_INS_PRIVATE,
max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC' then  secured_value else null end) as ADULTS_1_INS_PUBLIC,
max(case sq.pseudonym when 'ADULTS_1_WORK_10' then  secured_value else null end) as ADULTS_1_WORK_10,
max(case sq.pseudonym when 'ADULTS_1_WORK_20' then  secured_value else null end) as ADULTS_1_WORK_20,
max(case sq.pseudonym when 'ADULTS_1_WORK_37' then  secured_value else null end) as ADULTS_1_WORK_37,
max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10' then  secured_value else null end) as ADULTS_1_WORK_LESS10,
max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY' then  secured_value else null end) as ADULTS_1_WORK_UNEMPLOY,
max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_BC_0_USED_6MONTHS' then  secured_value else null end) as CLIENT_BC_0_USED_6MONTHS,
max(case sq.pseudonym when 'CLIENT_BC_1_FREQUENCY' then  secured_value else null end) as CLIENT_BC_1_FREQUENCY,
max(case sq.pseudonym when 'CLIENT_BC_1_NOT_USED_REASON' then  secured_value else null end) as CLIENT_BC_1_NOT_USED_REASON,
max(case sq.pseudonym when 'CLIENT_BC_1_TYPES' then  secured_value else null end) as CLIENT_BC_1_TYPES,
max(case sq.pseudonym when 'CLIENT_BC_1_TYPES_NEXT6' then  secured_value else null end) as CLIENT_BC_1_TYPES_NEXT6,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH' then  secured_value else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_1_TIME_WITH' then  secured_value else null end) as CLIENT_BIO_DAD_1_TIME_WITH,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER' then  secured_value else null end) as CLIENT_CARE_0_ER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP' then  secured_value else null end) as CLIENT_CARE_0_ER_HOSP,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER' then  secured_value else null end) as CLIENT_CARE_0_ER_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE' then  secured_value else null end) as CLIENT_CARE_0_ER_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6' then  secured_value else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT' then  secured_value else null end) as CLIENT_CARE_0_URGENT,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER' then  secured_value else null end) as CLIENT_CARE_0_URGENT_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE' then  secured_value else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6' then  secured_value else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_TIMES,
max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE' then  secured_value else null end) as CLIENT_ED_PROG_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED' then  secured_value else null end) as CLIENT_EDUCATION_0_HS_GED,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP' then  secured_value else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE' then  secured_value else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME' then  secured_value else null end) as CLIENT_INCOME_0_HH_INCOME,
max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES' then  secured_value else null end) as CLIENT_INCOME_1_HH_SOURCES,
max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY' then  secured_value else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT' then  secured_value else null end) as CLIENT_INCOME_AMOUNT,
max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND' then  secured_value else null end) as CLIENT_INCOME_IN_KIND,
max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER' then  secured_value else null end) as CLIENT_INCOME_INKIND_OTHER,
max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES' then  secured_value else null end) as CLIENT_INCOME_OTHER_SOURCES,
max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES' then  secured_value else null end) as CLIENT_INCOME_SOURCES,
max(case sq.pseudonym when 'CLIENT_INSURANCE' then  secured_value else null end) as CLIENT_INSURANCE,
max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER' then  secured_value else null end) as CLIENT_INSURANCE_OTHER,
max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE' then  secured_value else null end) as CLIENT_INSURANCE_TYPE,
max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH' then  secured_value else null end) as CLIENT_LIVING_0_WITH,
max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS' then  secured_value else null end) as CLIENT_LIVING_1_WITH_OTHERS,
max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS' then  secured_value else null end) as CLIENT_LIVING_HOMELESS,
max(case sq.pseudonym when 'CLIENT_LIVING_WHERE' then  secured_value else null end) as CLIENT_LIVING_WHERE,
max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS' then  secured_value else null end) as CLIENT_MARITAL_0_STATUS,
max(case sq.pseudonym when 'CLIENT_MILITARY' then  secured_value else null end) as CLIENT_MILITARY,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE' then  secured_value else null end) as CLIENT_PROVIDE_CHILDCARE,
max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS' then  secured_value else null end) as CLIENT_SCHOOL_MIDDLE_HS,
max(case sq.pseudonym when 'CLIENT_SECOND_0_CHILD_DOB' then  secured_value else null end) as CLIENT_SECOND_0_CHILD_DOB,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_GRAMS' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_GRAMS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_MEASURE' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_MEASURE,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_OZ' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_OZ,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_BW_POUNDS' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_BW_POUNDS,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_GENDER' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_GENDER,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_NICU' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_NICU,
max(case sq.pseudonym when 'CLIENT_SECOND_1_CHILD_NICU_DAYS' then  secured_value else null end) as CLIENT_SECOND_1_CHILD_NICU_DAYS,
max(case sq.pseudonym when 'CLIENT_SUBPREG' then  secured_value else null end) as CLIENT_SUBPREG,
max(case sq.pseudonym when 'CLIENT_SUBPREG_0_BEEN_PREGNANT' then  secured_value else null end) as CLIENT_SUBPREG_0_BEEN_PREGNANT,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_BEGIN_MONTH' then  secured_value else null end) as CLIENT_SUBPREG_1_BEGIN_MONTH,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_BEGIN_YEAR' then  secured_value else null end) as CLIENT_SUBPREG_1_BEGIN_YEAR,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_EDD' then  secured_value else null end) as CLIENT_SUBPREG_1_EDD,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_GEST_AGE' then  secured_value else null end) as CLIENT_SUBPREG_1_GEST_AGE,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_OUTCOME' then  secured_value else null end) as CLIENT_SUBPREG_1_OUTCOME,
max(case sq.pseudonym when 'CLIENT_SUBPREG_1_PLANNED' then  secured_value else null end) as CLIENT_SUBPREG_1_PLANNED,
max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING' then  secured_value else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS' then  secured_value else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO' then  secured_value else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
max(case sq.pseudonym when 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH' then  secured_value else null end) as CLIENT_WORKING_1_WORKED_SINCE_BIRTH,
max(case sq.pseudonym when 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS' then  secured_value else null end) as CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Demographics
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
CLIENT_BIO_DAD_0_CONTACT_WITH varchar(256),
CLIENT_CARE_0_ URGENT_OTHER varchar(256),
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
	max(case sq.pseudonym when 'ADULTS_1_CARE_10' then  secured_value else null end) as ADULTS_1_CARE_10,
max(case sq.pseudonym when 'ADULTS_1_CARE_20' then  secured_value else null end) as ADULTS_1_CARE_20,
max(case sq.pseudonym when 'ADULTS_1_CARE_30' then  secured_value else null end) as ADULTS_1_CARE_30,
max(case sq.pseudonym when 'ADULTS_1_CARE_40' then  secured_value else null end) as ADULTS_1_CARE_40,
max(case sq.pseudonym when 'ADULTS_1_CARE_LESS10' then  secured_value else null end) as ADULTS_1_CARE_LESS10,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_GED' then  secured_value else null end) as ADULTS_1_COMPLETE_GED,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS' then  secured_value else null end) as ADULTS_1_COMPLETE_HS,
max(case sq.pseudonym when 'ADULTS_1_COMPLETE_HS_NO' then  secured_value else null end) as ADULTS_1_COMPLETE_HS_NO,
max(case sq.pseudonym when 'ADULTS_1_ED_ASSOCIATE' then  secured_value else null end) as ADULTS_1_ED_ASSOCIATE,
max(case sq.pseudonym when 'ADULTS_1_ED_BACHELOR' then  secured_value else null end) as ADULTS_1_ED_BACHELOR,
max(case sq.pseudonym when 'ADULTS_1_ED_MASTER' then  secured_value else null end) as ADULTS_1_ED_MASTER,
max(case sq.pseudonym when 'ADULTS_1_ED_NONE' then  secured_value else null end) as ADULTS_1_ED_NONE,
max(case sq.pseudonym when 'ADULTS_1_ED_POSTGRAD' then  secured_value else null end) as ADULTS_1_ED_POSTGRAD,
max(case sq.pseudonym when 'ADULTS_1_ED_SOME_COLLEGE' then  secured_value else null end) as ADULTS_1_ED_SOME_COLLEGE,
max(case sq.pseudonym when 'ADULTS_1_ED_TECH' then  secured_value else null end) as ADULTS_1_ED_TECH,
max(case sq.pseudonym when 'ADULTS_1_ED_UNKNOWN' then  secured_value else null end) as ADULTS_1_ED_UNKNOWN,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_FT' then  secured_value else null end) as ADULTS_1_ENROLL_FT,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_NO' then  secured_value else null end) as ADULTS_1_ENROLL_NO,
max(case sq.pseudonym when 'ADULTS_1_ENROLL_PT' then  secured_value else null end) as ADULTS_1_ENROLL_PT,
max(case sq.pseudonym when 'ADULTS_1_INS_NO' then  secured_value else null end) as ADULTS_1_INS_NO,
max(case sq.pseudonym when 'ADULTS_1_INS_PRIVATE' then  secured_value else null end) as ADULTS_1_INS_PRIVATE,
max(case sq.pseudonym when 'ADULTS_1_INS_PUBLIC' then  secured_value else null end) as ADULTS_1_INS_PUBLIC,
max(case sq.pseudonym when 'ADULTS_1_WORK_10' then  secured_value else null end) as ADULTS_1_WORK_10,
max(case sq.pseudonym when 'ADULTS_1_WORK_20' then  secured_value else null end) as ADULTS_1_WORK_20,
max(case sq.pseudonym when 'ADULTS_1_WORK_37' then  secured_value else null end) as ADULTS_1_WORK_37,
max(case sq.pseudonym when 'ADULTS_1_WORK_LESS10' then  secured_value else null end) as ADULTS_1_WORK_LESS10,
max(case sq.pseudonym when 'ADULTS_1_WORK_UNEMPLOY' then  secured_value else null end) as ADULTS_1_WORK_UNEMPLOY,
max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_BIO_DAD_0_CONTACT_WITH' then  secured_value else null end) as CLIENT_BIO_DAD_0_CONTACT_WITH,
max(case sq.pseudonym when 'CLIENT_CARE_0_ URGENT_OTHER' then  secured_value else null end) as CLIENT_CARE_0_ URGENT_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER' then  secured_value else null end) as CLIENT_CARE_0_ER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_FEVER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_HOSP' then  secured_value else null end) as CLIENT_CARE_0_ER_HOSP,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INFECTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INGESTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_INJURY_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER' then  secured_value else null end) as CLIENT_CARE_0_ER_OTHER,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE' then  secured_value else null end) as CLIENT_CARE_0_ER_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_PURPOSE_R6' then  secured_value else null end) as CLIENT_CARE_0_ER_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_ER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_ER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT' then  secured_value else null end) as CLIENT_CARE_0_URGENT,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_FEVER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_FEVER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INFECTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INFECTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INGESTION_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INGESTION_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_INJURY_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_INJURY_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_OTHER_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_OTHER_TIMES,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE' then  secured_value else null end) as CLIENT_CARE_0_URGENT_PURPOSE,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_PURPOSE_R6' then  secured_value else null end) as CLIENT_CARE_0_URGENT_PURPOSE_R6,
max(case sq.pseudonym when 'CLIENT_CARE_0_URGENT_TIMES' then  secured_value else null end) as CLIENT_CARE_0_URGENT_TIMES,
max(case sq.pseudonym when 'CLIENT_ED_PROG_TYPE' then  secured_value else null end) as CLIENT_ED_PROG_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_0_HS_GED' then  secured_value else null end) as CLIENT_EDUCATION_0_HS_GED,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_CURRENT' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_CURRENT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_FTPT' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_FTPT,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PLAN' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_PLAN,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_PT_HRS,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_ENROLLED_TYPE' then  secured_value else null end) as CLIENT_EDUCATION_1_ENROLLED_TYPE,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP' then  secured_value else null end) as CLIENT_EDUCATION_1_HIGHER_EDUC_COMP,
max(case sq.pseudonym when 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE' then  secured_value else null end) as CLIENT_EDUCATION_1_HS_GED_LAST_GRADE,
max(case sq.pseudonym when 'CLIENT_INCOME_0_HH_INCOME' then  secured_value else null end) as CLIENT_INCOME_0_HH_INCOME,
max(case sq.pseudonym when 'CLIENT_INCOME_1_HH_SOURCES' then  secured_value else null end) as CLIENT_INCOME_1_HH_SOURCES,
max(case sq.pseudonym when 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY' then  secured_value else null end) as CLIENT_INCOME_1_LOW_INCOME_QUALIFY,
max(case sq.pseudonym when 'CLIENT_INCOME_AMOUNT' then  secured_value else null end) as CLIENT_INCOME_AMOUNT,
max(case sq.pseudonym when 'CLIENT_INCOME_IN_KIND' then  secured_value else null end) as CLIENT_INCOME_IN_KIND,
max(case sq.pseudonym when 'CLIENT_INCOME_INKIND_OTHER' then  secured_value else null end) as CLIENT_INCOME_INKIND_OTHER,
max(case sq.pseudonym when 'CLIENT_INCOME_OTHER_SOURCES' then  secured_value else null end) as CLIENT_INCOME_OTHER_SOURCES,
max(case sq.pseudonym when 'CLIENT_INCOME_SOURCES' then  secured_value else null end) as CLIENT_INCOME_SOURCES,
max(case sq.pseudonym when 'CLIENT_INSURANCE' then  secured_value else null end) as CLIENT_INSURANCE,
max(case sq.pseudonym when 'CLIENT_INSURANCE_OTHER' then  secured_value else null end) as CLIENT_INSURANCE_OTHER,
max(case sq.pseudonym when 'CLIENT_INSURANCE_TYPE' then  secured_value else null end) as CLIENT_INSURANCE_TYPE,
max(case sq.pseudonym when 'CLIENT_LIVING_0_WITH' then  secured_value else null end) as CLIENT_LIVING_0_WITH,
max(case sq.pseudonym when 'CLIENT_LIVING_1_WITH_OTHERS' then  secured_value else null end) as CLIENT_LIVING_1_WITH_OTHERS,
max(case sq.pseudonym when 'CLIENT_LIVING_HOMELESS' then  secured_value else null end) as CLIENT_LIVING_HOMELESS,
max(case sq.pseudonym when 'CLIENT_LIVING_WHERE' then  secured_value else null end) as CLIENT_LIVING_WHERE,
max(case sq.pseudonym when 'CLIENT_MARITAL_0_STATUS' then  secured_value else null end) as CLIENT_MARITAL_0_STATUS,
max(case sq.pseudonym when 'CLIENT_MILITARY' then  secured_value else null end) as CLIENT_MILITARY,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED' then  secured_value else null end) as CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED,
max(case sq.pseudonym when 'CLIENT_PROVIDE_CHILDCARE' then  secured_value else null end) as CLIENT_PROVIDE_CHILDCARE,
max(case sq.pseudonym when 'CLIENT_SCHOOL_MIDDLE_HS' then  secured_value else null end) as CLIENT_SCHOOL_MIDDLE_HS,
max(case sq.pseudonym when 'CLIENT_WORKING_0_CURRENTLY_WORKING' then  secured_value else null end) as CLIENT_WORKING_0_CURRENTLY_WORKING,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_HRS' then  secured_value else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_HRS,
max(case sq.pseudonym when 'CLIENT_WORKING_1_CURRENTLY_WORKING_NO' then  secured_value else null end) as CLIENT_WORKING_1_CURRENTLY_WORKING_NO,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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
return;
end

Go

create function survey_views.f_select_Edinburgh_Postnatal_Depression_Scale
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_EPDS_1_ABLE_TO_LAUGH' then  secured_value else null end) as CLIENT_EPDS_1_ABLE_TO_LAUGH,
max(case sq.pseudonym when 'CLIENT_EPDS_1_ANXIOUS_WORRIED' then  secured_value else null end) as CLIENT_EPDS_1_ANXIOUS_WORRIED,
max(case sq.pseudonym when 'CLIENT_EPDS_1_BEEN_CRYING' then  secured_value else null end) as CLIENT_EPDS_1_BEEN_CRYING,
max(case sq.pseudonym when 'CLIENT_EPDS_1_BLAME_SELF' then  secured_value else null end) as CLIENT_EPDS_1_BLAME_SELF,
max(case sq.pseudonym when 'CLIENT_EPDS_1_DIFFICULTY_SLEEPING' then  secured_value else null end) as CLIENT_EPDS_1_DIFFICULTY_SLEEPING,
max(case sq.pseudonym when 'CLIENT_EPDS_1_ENJOY_THINGS' then  secured_value else null end) as CLIENT_EPDS_1_ENJOY_THINGS,
max(case sq.pseudonym when 'CLIENT_EPDS_1_HARMING_SELF' then  secured_value else null end) as CLIENT_EPDS_1_HARMING_SELF,
max(case sq.pseudonym when 'CLIENT_EPDS_1_SAD_MISERABLE' then  secured_value else null end) as CLIENT_EPDS_1_SAD_MISERABLE,
max(case sq.pseudonym when 'CLIENT_EPDS_1_SCARED_PANICKY' then  secured_value else null end) as CLIENT_EPDS_1_SCARED_PANICKY,
max(case sq.pseudonym when 'CLIENT_EPDS_1_THINGS_GETTING_ON_TOP' then  secured_value else null end) as CLIENT_EPDS_1_THINGS_GETTING_ON_TOP,
max(case sq.pseudonym when 'CLIENT_EPS_TOTAL_SCORE' then  secured_value else null end) as CLIENT_EPS_TOTAL_SCORE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Education_Registration_V2
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
	max(case sq.pseudonym when 'EDUC_REGISTER_0_REASON' then  secured_value else null end) as EDUC_REGISTER_0_REASON



     from survey_views.f_secure_fact_survey_response('Education Registration V2',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Education_Registration
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
	max(case sq.pseudonym when 'EDUC_REGISTER_0_REASON' then  secured_value else null end) as EDUC_REGISTER_0_REASON



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

Go

create function survey_views.f_select_GAD_7
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_GAD7_AFRAID' then  secured_value else null end) as CLIENT_GAD7_AFRAID,
max(case sq.pseudonym when 'CLIENT_GAD7_CTRL_WORRY' then  secured_value else null end) as CLIENT_GAD7_CTRL_WORRY,
max(case sq.pseudonym when 'CLIENT_GAD7_IRRITABLE' then  secured_value else null end) as CLIENT_GAD7_IRRITABLE,
max(case sq.pseudonym when 'CLIENT_GAD7_NERVOUS' then  secured_value else null end) as CLIENT_GAD7_NERVOUS,
max(case sq.pseudonym when 'CLIENT_GAD7_PROBS_DIFFICULT' then  secured_value else null end) as CLIENT_GAD7_PROBS_DIFFICULT,
max(case sq.pseudonym when 'CLIENT_GAD7_RESTLESS' then  secured_value else null end) as CLIENT_GAD7_RESTLESS,
max(case sq.pseudonym when 'CLIENT_GAD7_TOTAL' then  secured_value else null end) as CLIENT_GAD7_TOTAL,
max(case sq.pseudonym when 'CLIENT_GAD7_TRBL_RELAX' then  secured_value else null end) as CLIENT_GAD7_TRBL_RELAX,
max(case sq.pseudonym when 'CLIENT_GAD7_WORRY' then  secured_value else null end) as CLIENT_GAD7_WORRY,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Goodwill_Indy_Additional_Referral_Data
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_DIMISSAL_REASON' then  secured_value else null end) as REFERRAL_ADDITIONAL_DIMISSAL_REASON,
max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_NOTES' then  secured_value else null end) as REFERRAL_ADDITIONAL_NOTES,
max(case sq.pseudonym when 'REFERRAL_ADDITIONAL_SOURCE' then  secured_value else null end) as REFERRAL_ADDITIONAL_SOURCE



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

Go

create function survey_views.f_select_Health_Habits
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_ALCOHOL_0_14DAY' then  secured_value else null end) as CLIENT_SUBSTANCE_ALCOHOL_0_14DAY,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS' then  secured_value else null end) as CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_0_DURING_PREG' then  secured_value else null end) as CLIENT_SUBSTANCE_CIG_0_DURING_PREG,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_1_LAST_48' then  secured_value else null end) as CLIENT_SUBSTANCE_CIG_1_LAST_48,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_CIG_1_PRE_PREG' then  secured_value else null end) as CLIENT_SUBSTANCE_CIG_1_PRE_PREG,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_COCAINE_0_14DAY' then  secured_value else null end) as CLIENT_SUBSTANCE_COCAINE_0_14DAY,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES' then  secured_value else null end) as CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_NICOTINE_0_OTHER' then  secured_value else null end) as CLIENT_SUBSTANCE_NICOTINE_0_OTHER,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES' then  secured_value else null end) as CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_OTHER_0_14DAY' then  secured_value else null end) as CLIENT_SUBSTANCE_OTHER_0_14DAY,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES' then  secured_value else null end) as CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_POT_0_14DAYS' then  secured_value else null end) as CLIENT_SUBSTANCE_POT_0_14DAYS,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS' then  secured_value else null end) as CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME_LAST' then  secured_value else null end) as NURSE_PERSONAL_0_NAME_LAST



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

Go

create function survey_views.f_select_Home_Visit_Encounter
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_ATTENDEES_0_AT_VISIT' then  secured_value else null end) as CLIENT_ATTENDEES_0_AT_VISIT,
max(case sq.pseudonym when 'CLIENT_ATTENDEES_0_OTHER_VISIT_DESC' then  secured_value else null end) as CLIENT_ATTENDEES_0_OTHER_VISIT_DESC,
max(case sq.pseudonym when 'CLIENT_CHILD_DEVELOPMENT_CONCERN' then  secured_value else null end) as CLIENT_CHILD_DEVELOPMENT_CONCERN,
max(case sq.pseudonym when 'CLIENT_CHILD_INJURY_0_PREVENTION' then  secured_value else null end) as CLIENT_CHILD_INJURY_0_PREVENTION,
max(case sq.pseudonym when 'CLIENT_COMPLETE_0_VISIT' then  secured_value else null end) as CLIENT_COMPLETE_0_VISIT,
max(case sq.pseudonym when 'CLIENT_CONFLICT_0_CLIENT_VISIT' then  secured_value else null end) as CLIENT_CONFLICT_0_CLIENT_VISIT,
max(case sq.pseudonym when 'CLIENT_CONFLICT_1_GRNDMTHR_VISIT' then  secured_value else null end) as CLIENT_CONFLICT_1_GRNDMTHR_VISIT,
max(case sq.pseudonym when 'CLIENT_CONFLICT_1_PARTNER_VISIT' then  secured_value else null end) as CLIENT_CONFLICT_1_PARTNER_VISIT,
max(case sq.pseudonym when 'CLIENT_CONT_HLTH_INS' then  secured_value else null end) as CLIENT_CONT_HLTH_INS,
max(case sq.pseudonym when 'CLIENT_CONTENT_0_PERCENT_VISIT' then  secured_value else null end) as CLIENT_CONTENT_0_PERCENT_VISIT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT' then  secured_value else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_VISIT' then  secured_value else null end) as CLIENT_DOMAIN_0_FRNDFAM_VISIT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_VISIT' then  secured_value else null end) as CLIENT_DOMAIN_0_LIFECOURSE_VISIT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_VISIT' then  secured_value else null end) as CLIENT_DOMAIN_0_MATERNAL_VISIT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSHLTH_VISIT' then  secured_value else null end) as CLIENT_DOMAIN_0_PERSHLTH_VISIT,
max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_VISIT' then  secured_value else null end) as CLIENT_DOMAIN_0_TOTAL_VISIT,
max(case sq.pseudonym when 'CLIENT_INVOLVE_0_CLIENT_VISIT' then  secured_value else null end) as CLIENT_INVOLVE_0_CLIENT_VISIT,
max(case sq.pseudonym when 'CLIENT_INVOLVE_1_GRNDMTHR_VISIT' then  secured_value else null end) as CLIENT_INVOLVE_1_GRNDMTHR_VISIT,
max(case sq.pseudonym when 'CLIENT_INVOLVE_1_PARTNER_VISIT' then  secured_value else null end) as CLIENT_INVOLVE_1_PARTNER_VISIT,
max(case sq.pseudonym when 'CLIENT_IPV_0_SAFETY_PLAN' then  secured_value else null end) as CLIENT_IPV_0_SAFETY_PLAN,
max(case sq.pseudonym when 'CLIENT_LOCATION_0_VISIT' then  secured_value else null end) as CLIENT_LOCATION_0_VISIT,
max(case sq.pseudonym when 'CLIENT_NO_REFERRAL' then  secured_value else null end) as CLIENT_NO_REFERRAL,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PLANNED_VISIT_SCH' then  secured_value else null end) as CLIENT_PLANNED_VISIT_SCH,
max(case sq.pseudonym when 'CLIENT_PRENATAL_VISITS' then  secured_value else null end) as CLIENT_PRENATAL_VISITS,
max(case sq.pseudonym when 'CLIENT_PRENATAL_VISITS_WEEKS' then  secured_value else null end) as CLIENT_PRENATAL_VISITS_WEEKS,
max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS' then  secured_value else null end) as CLIENT_SCREENED_SRVCS,
max(case sq.pseudonym when 'CLIENT_TIME_0_START_VISIT' then  secured_value else null end) as CLIENT_TIME_0_START_VISIT,
max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_VISIT' then  secured_value else null end) as CLIENT_TIME_1_DURATION_VISIT,
max(case sq.pseudonym when 'CLIENT_TIME_1_END_VISIT' then  secured_value else null end) as CLIENT_TIME_1_END_VISIT,
max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM' then  secured_value else null end) as CLIENT_TIME_FROM_AMPM,
max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR' then  secured_value else null end) as CLIENT_TIME_FROM_HR,
max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN' then  secured_value else null end) as CLIENT_TIME_FROM_MIN,
max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM' then  secured_value else null end) as CLIENT_TIME_TO_AMPM,
max(case sq.pseudonym when 'CLIENT_TIME_TO_HR' then  secured_value else null end) as CLIENT_TIME_TO_HR,
max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN' then  secured_value else null end) as CLIENT_TIME_TO_MIN,
max(case sq.pseudonym when 'CLIENT_UNDERSTAND_0_CLIENT_VISIT' then  secured_value else null end) as CLIENT_UNDERSTAND_0_CLIENT_VISIT,
max(case sq.pseudonym when 'CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT' then  secured_value else null end) as CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT,
max(case sq.pseudonym when 'CLIENT_UNDERSTAND_1_PARTNER_VISIT' then  secured_value else null end) as CLIENT_UNDERSTAND_1_PARTNER_VISIT,
max(case sq.pseudonym when 'CLIENT_VISIT_SCHEDULE' then  secured_value else null end) as CLIENT_VISIT_SCHEDULE,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_0_HAD_VISIT' then  secured_value else null end) as INFANT_HEALTH_ER_0_HAD_VISIT,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC1' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC2' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC3' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON1' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON2' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON3' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT1' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT2' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT3' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_TYPE' then  secured_value else null end) as INFANT_HEALTH_ER_1_TYPE,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_0_HAD_VISIT' then  secured_value else null end) as INFANT_HEALTH_HOSP_0_HAD_VISIT,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE1' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE2' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE3' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE1' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE2' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE3' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_TYPE' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_TYPE,
max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_R2' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_R2,
max(case sq.pseudonym when 'NURSE_MILEAGE_0_VIS' then  secured_value else null end) as NURSE_MILEAGE_0_VIS,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Infant_Birth
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
INFANT_BIRTH_0_CLIENT_URGENT CARE varchar(256),
INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES varchar(256),
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
INFANT_PERSONAL_0_FIRST NAME varchar(256),
INFANT_PERSONAL_0_FIRST NAME2 varchar(256),
INFANT_PERSONAL_0_FIRST NAME3 varchar(256),
INFANT_PERSONAL_0_GENDER varchar(256),
INFANT_PERSONAL_0_GENDER2 varchar(256),
INFANT_PERSONAL_0_GENDER3 varchar(256),
INFANT_PERSONAL_0_LAST NAME varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_WEIGHT_0_PREG_GAIN' then  secured_value else null end) as CLIENT_WEIGHT_0_PREG_GAIN,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_0_ID_NSO2' then  secured_value else null end) as INFANT_0_ID_NSO2,
max(case sq.pseudonym when 'INFANT_0_ID_NSO3' then  secured_value else null end) as INFANT_0_ID_NSO3,
max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_ER' then  secured_value else null end) as INFANT_BIRTH_0_CLIENT_ER,
max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_ER_TIMES' then  secured_value else null end) as INFANT_BIRTH_0_CLIENT_ER_TIMES,
max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_URGENT CARE' then  secured_value else null end) as INFANT_BIRTH_0_CLIENT_URGENT CARE,
max(case sq.pseudonym when 'INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES' then  secured_value else null end) as INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES,
max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB' then  secured_value else null end) as INFANT_BIRTH_0_DOB,
max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB2' then  secured_value else null end) as INFANT_BIRTH_0_DOB2,
max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB3' then  secured_value else null end) as INFANT_BIRTH_0_DOB3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_DELIVERY' then  secured_value else null end) as INFANT_BIRTH_1_DELIVERY,
max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE' then  secured_value else null end) as INFANT_BIRTH_1_GEST_AGE,
max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE2' then  secured_value else null end) as INFANT_BIRTH_1_GEST_AGE2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_GEST_AGE3' then  secured_value else null end) as INFANT_BIRTH_1_GEST_AGE3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN' then  secured_value else null end) as INFANT_BIRTH_1_HEARING_SCREEN,
max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN2' then  secured_value else null end) as INFANT_BIRTH_1_HEARING_SCREEN2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_HEARING_SCREEN3' then  secured_value else null end) as INFANT_BIRTH_1_HEARING_SCREEN3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_LABOR' then  secured_value else null end) as INFANT_BIRTH_1_LABOR,
max(case sq.pseudonym when 'INFANT_BIRTH_1_MULTIPLE_BIRTHS' then  secured_value else null end) as INFANT_BIRTH_1_MULTIPLE_BIRTHS,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN' then  secured_value else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN2' then  secured_value else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NEWBORN_SCREEN3' then  secured_value else null end) as INFANT_BIRTH_1_NEWBORN_SCREEN3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU' then  secured_value else null end) as INFANT_BIRTH_1_NICU,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS_R2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2_2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS_R2_2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS_R2_3' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS_R2_3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_DAYS3' then  secured_value else null end) as INFANT_BIRTH_1_NICU_DAYS3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3' then  secured_value else null end) as INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_R2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2_2' then  secured_value else null end) as INFANT_BIRTH_1_NICU_R2_2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU_R2_3' then  secured_value else null end) as INFANT_BIRTH_1_NICU_R2_3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU2' then  secured_value else null end) as INFANT_BIRTH_1_NICU2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NICU3' then  secured_value else null end) as INFANT_BIRTH_1_NICU3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2_2' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2_2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_DAYS_R2_3' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_DAYS_R2_3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_R2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2_2' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_R2_2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_NURSERY_R2_3' then  secured_value else null end) as INFANT_BIRTH_1_NURSERY_R2_3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS2' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_GRAMS3' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_GRAMS3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE2' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_MEASURE3' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_MEASURE3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES2' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_OUNCES3' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_OUNCES3,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS2' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS2,
max(case sq.pseudonym when 'INFANT_BIRTH_1_WEIGHT_POUNDS3' then  secured_value else null end) as INFANT_BIRTH_1_WEIGHT_POUNDS3,
max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP' then  secured_value else null end) as INFANT_BIRTH_COSLEEP,
max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP2' then  secured_value else null end) as INFANT_BIRTH_COSLEEP2,
max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP3' then  secured_value else null end) as INFANT_BIRTH_COSLEEP3,
max(case sq.pseudonym when 'INFANT_BIRTH_READ' then  secured_value else null end) as INFANT_BIRTH_READ,
max(case sq.pseudonym when 'INFANT_BIRTH_READ2' then  secured_value else null end) as INFANT_BIRTH_READ2,
max(case sq.pseudonym when 'INFANT_BIRTH_READ3' then  secured_value else null end) as INFANT_BIRTH_READ3,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK2' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK2,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK3' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK3,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING2' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING2,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING3' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING3,
max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_BIRTH,
max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH2' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_BIRTH2,
max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_BIRTH3' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_BIRTH3,
max(case sq.pseudonym when 'INFANT_INSURANCE' then  secured_value else null end) as INFANT_INSURANCE,
max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER' then  secured_value else null end) as INFANT_INSURANCE_OTHER,
max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER2' then  secured_value else null end) as INFANT_INSURANCE_OTHER2,
max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER3' then  secured_value else null end) as INFANT_INSURANCE_OTHER3,
max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE' then  secured_value else null end) as INFANT_INSURANCE_TYPE,
max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE2' then  secured_value else null end) as INFANT_INSURANCE_TYPE2,
max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE3' then  secured_value else null end) as INFANT_INSURANCE_TYPE3,
max(case sq.pseudonym when 'INFANT_INSURANCE2' then  secured_value else null end) as INFANT_INSURANCE2,
max(case sq.pseudonym when 'INFANT_INSURANCE3' then  secured_value else null end) as INFANT_INSURANCE3,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY' then  secured_value else null end) as INFANT_PERSONAL_0_ETHNICITY,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY2' then  secured_value else null end) as INFANT_PERSONAL_0_ETHNICITY2,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_ETHNICITY3' then  secured_value else null end) as INFANT_PERSONAL_0_ETHNICITY3,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME' then  secured_value else null end) as INFANT_PERSONAL_0_FIRST NAME,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME2' then  secured_value else null end) as INFANT_PERSONAL_0_FIRST NAME2,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_FIRST NAME3' then  secured_value else null end) as INFANT_PERSONAL_0_FIRST NAME3,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER' then  secured_value else null end) as INFANT_PERSONAL_0_GENDER,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER2' then  secured_value else null end) as INFANT_PERSONAL_0_GENDER2,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_GENDER3' then  secured_value else null end) as INFANT_PERSONAL_0_GENDER3,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_LAST NAME' then  secured_value else null end) as INFANT_PERSONAL_0_LAST NAME,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE' then  secured_value else null end) as INFANT_PERSONAL_0_RACE,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE2' then  secured_value else null end) as INFANT_PERSONAL_0_RACE2,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_RACE3' then  secured_value else null end) as INFANT_PERSONAL_0_RACE3,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Infant Birth',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Infant_Health_Care
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_0_VERSION' then  secured_value else null end) as INFANT_AGES_STAGES_0_VERSION,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_COMM' then  secured_value else null end) as INFANT_AGES_STAGES_1_COMM,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_FMOTOR' then  secured_value else null end) as INFANT_AGES_STAGES_1_FMOTOR,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_GMOTOR' then  secured_value else null end) as INFANT_AGES_STAGES_1_GMOTOR,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOCIAL' then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOCIAL,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_1_PSOLVE' then  secured_value else null end) as INFANT_AGES_STAGES_1_PSOLVE,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_SE_0_EMOTIONAL' then  secured_value else null end) as INFANT_AGES_STAGES_SE_0_EMOTIONAL,
max(case sq.pseudonym when 'INFANT_AGES_STAGES_SE_VERSION' then  secured_value else null end) as INFANT_AGES_STAGES_SE_VERSION,
max(case sq.pseudonym when 'INFANT_BIRTH_0_DOB' then  secured_value else null end) as INFANT_BIRTH_0_DOB,
max(case sq.pseudonym when 'INFANT_BIRTH_COSLEEP' then  secured_value else null end) as INFANT_BIRTH_COSLEEP,
max(case sq.pseudonym when 'INFANT_BIRTH_READ' then  secured_value else null end) as INFANT_BIRTH_READ,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BACK' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BACK,
max(case sq.pseudonym when 'INFANT_BIRTH_SLEEP_BEDDING' then  secured_value else null end) as INFANT_BIRTH_SLEEP_BEDDING,
max(case sq.pseudonym when 'INFANT_BREASTMILK_0_EVER_IHC' then  secured_value else null end) as INFANT_BREASTMILK_0_EVER_IHC,
max(case sq.pseudonym when 'INFANT_BREASTMILK_1_AGE_STOP' then  secured_value else null end) as INFANT_BREASTMILK_1_AGE_STOP,
max(case sq.pseudonym when 'INFANT_BREASTMILK_1_CONT' then  secured_value else null end) as INFANT_BREASTMILK_1_CONT,
max(case sq.pseudonym when 'INFANT_BREASTMILK_1_EXCLUSIVE_WKS' then  secured_value else null end) as INFANT_BREASTMILK_1_EXCLUSIVE_WKS,
max(case sq.pseudonym when 'INFANT_BREASTMILK_1_WEEK_STOP' then  secured_value else null end) as INFANT_BREASTMILK_1_WEEK_STOP,
max(case sq.pseudonym when 'INFANT_HEALTH_DENTAL_SOURCE' then  secured_value else null end) as INFANT_HEALTH_DENTAL_SOURCE,
max(case sq.pseudonym when 'INFANT_HEALTH_DENTIST' then  secured_value else null end) as INFANT_HEALTH_DENTIST,
max(case sq.pseudonym when 'INFANT_HEALTH_DENTIST_STILL_EBF' then  secured_value else null end) as INFANT_HEALTH_DENTIST_STILL_EBF,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_0_HAD_VISIT' then  secured_value else null end) as INFANT_HEALTH_ER_0_HAD_VISIT,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DATE3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_DAYS3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_DAYS3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_ERvsUC3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INGEST_TREAT3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INGEST_TREAT3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DATE3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_DAYS3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_DAYS3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_ERvsUC3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_ERvsUC3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT1' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT2' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_INJ_TREAT3' then  secured_value else null end) as INFANT_HEALTH_ER_1_INJ_TREAT3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC1' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC2' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_ERvsUC3' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON1' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON2' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHER_REASON3' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHER_REASON3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT1' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT1,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT2' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT2,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_OTHERDT3' then  secured_value else null end) as INFANT_HEALTH_ER_1_OTHERDT3,
max(case sq.pseudonym when 'INFANT_HEALTH_ER_1_TYPE' then  secured_value else null end) as INFANT_HEALTH_ER_1_TYPE,
max(case sq.pseudonym when 'INFANT_HEALTH_HEAD_0_CIRC_INCHES' then  secured_value else null end) as INFANT_HEALTH_HEAD_0_CIRC_INCHES,
max(case sq.pseudonym when 'INFANT_HEALTH_HEAD_1_REPORT' then  secured_value else null end) as INFANT_HEALTH_HEAD_1_REPORT,
max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_0_INCHES' then  secured_value else null end) as INFANT_HEALTH_HEIGHT_0_INCHES,
max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_1_PERCENT' then  secured_value else null end) as INFANT_HEALTH_HEIGHT_1_PERCENT,
max(case sq.pseudonym when 'INFANT_HEALTH_HEIGHT_1_REPORT' then  secured_value else null end) as INFANT_HEALTH_HEIGHT_1_REPORT,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_0_HAD_VISIT' then  secured_value else null end) as INFANT_HEALTH_HOSP_0_HAD_VISIT,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE1' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE2' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INGEST_DATE3' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INGEST_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE1' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE1,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE2' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE2,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_INJ_DATE3' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_INJ_DATE3,
max(case sq.pseudonym when 'INFANT_HEALTH_HOSP_1_TYPE' then  secured_value else null end) as INFANT_HEALTH_HOSP_1_TYPE,
max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_0_UPDATE' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_0_UPDATE,
max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_1_RECORD' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_1_RECORD,
max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_UPDATE_NO' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_UPDATE_NO,
max(case sq.pseudonym when 'INFANT_HEALTH_IMMUNIZ_UPDATE_YES' then  secured_value else null end) as INFANT_HEALTH_IMMUNIZ_UPDATE_YES,
max(case sq.pseudonym when 'INFANT_HEALTH_LEAD_0_TEST' then  secured_value else null end) as INFANT_HEALTH_LEAD_0_TEST,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_COMM' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_COMM,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_FINE' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_FINE,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_GROSS' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_GROSS,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PERSONAL' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PERSONAL,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_PROBLEM' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_PROBLEM,
max(case sq.pseudonym when 'INFANT_HEALTH_NO_ASQ_TOTAL' then  secured_value else null end) as INFANT_HEALTH_NO_ASQ_TOTAL,
max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT,
max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_APPT_R2' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_APPT_R2,
max(case sq.pseudonym when 'INFANT_HEALTH_PROVIDER_0_PRIMARY' then  secured_value else null end) as INFANT_HEALTH_PROVIDER_0_PRIMARY,
max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_0_POUNDS' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_0_POUNDS,
max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_OUNCES' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_OUNCES,
max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_OZ' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_OZ,
max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_PERCENT' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_PERCENT,
max(case sq.pseudonym when 'INFANT_HEALTH_WEIGHT_1_REPORT' then  secured_value else null end) as INFANT_HEALTH_WEIGHT_1_REPORT,
max(case sq.pseudonym when 'INFANT_HOME_0_TOTAL' then  secured_value else null end) as INFANT_HOME_0_TOTAL,
max(case sq.pseudonym when 'INFANT_HOME_1_ACCEPTANCE' then  secured_value else null end) as INFANT_HOME_1_ACCEPTANCE,
max(case sq.pseudonym when 'INFANT_HOME_1_EXPERIENCE' then  secured_value else null end) as INFANT_HOME_1_EXPERIENCE,
max(case sq.pseudonym when 'INFANT_HOME_1_INVOLVEMENT' then  secured_value else null end) as INFANT_HOME_1_INVOLVEMENT,
max(case sq.pseudonym when 'INFANT_HOME_1_LEARNING' then  secured_value else null end) as INFANT_HOME_1_LEARNING,
max(case sq.pseudonym when 'INFANT_HOME_1_ORGANIZATION' then  secured_value else null end) as INFANT_HOME_1_ORGANIZATION,
max(case sq.pseudonym when 'INFANT_HOME_1_RESPONSIVITY' then  secured_value else null end) as INFANT_HOME_1_RESPONSIVITY,
max(case sq.pseudonym when 'INFANT_INSURANCE' then  secured_value else null end) as INFANT_INSURANCE,
max(case sq.pseudonym when 'INFANT_INSURANCE_OTHER' then  secured_value else null end) as INFANT_INSURANCE_OTHER,
max(case sq.pseudonym when 'INFANT_INSURANCE_TYPE' then  secured_value else null end) as INFANT_INSURANCE_TYPE,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_SSN' then  secured_value else null end) as INFANT_PERSONAL_0_SSN,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_0_REFERRAL' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_0_REFERRAL,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON1' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON1,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON2' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON2,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON3' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON3,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON1' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON1,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON1_OTHER' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON1_OTHER,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON2' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON2,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON2_OTHER' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON2_OTHER,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON3' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON3,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REASON3_OTHER' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REASON3_OTHER,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE1' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE1,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE2' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE2,
max(case sq.pseudonym when 'INFANT_SOCIAL_SERVICES_1_REFDATE3' then  secured_value else null end) as INFANT_SOCIAL_SERVICES_1_REFDATE3,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Joint_Visit_Observation_Form
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
	max(case sq.pseudonym when 'JVO_ADDITIONAL_REASON' then  secured_value else null end) as JVO_ADDITIONAL_REASON,
max(case sq.pseudonym when 'JVO_CLIENT_CASE' then  secured_value else null end) as JVO_CLIENT_CASE,
max(case sq.pseudonym when 'JVO_CLIENT_NAME' then  secured_value else null end) as JVO_CLIENT_NAME,
max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT' then  secured_value else null end) as JVO_CLINICAL_CHART_CONSISTENT,
max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT_COMMENTS' then  secured_value else null end) as JVO_CLINICAL_CHART_CONSISTENT_COMMENTS,
max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT' then  secured_value else null end) as JVO_HVEF_CONSISTENT,
max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT_COMMENTS' then  secured_value else null end) as JVO_HVEF_CONSISTENT_COMMENTS,
max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_COMMENTS' then  secured_value else null end) as JVO_MI_CLIENT_PRIN_COMMENTS,
max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_SCORE' then  secured_value else null end) as JVO_MI_CLIENT_PRIN_SCORE,
max(case sq.pseudonym when 'JVO_OBSERVER_NAME' then  secured_value else null end) as JVO_OBSERVER_NAME,
max(case sq.pseudonym when 'JVO_OBSERVER_NAME_OTHER' then  secured_value else null end) as JVO_OBSERVER_NAME_OTHER,
max(case sq.pseudonym when 'JVO_OTHER_OBSERVATIONS' then  secured_value else null end) as JVO_OTHER_OBSERVATIONS,
max(case sq.pseudonym when 'JVO_PARENT_CHILD_COMMENTS' then  secured_value else null end) as JVO_PARENT_CHILD_COMMENTS,
max(case sq.pseudonym when 'JVO_PARENT_CHILD_SCORE' then  secured_value else null end) as JVO_PARENT_CHILD_SCORE,
max(case sq.pseudonym when 'JVO_START_TIME' then  secured_value else null end) as JVO_START_TIME,
max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_COMMENTS' then  secured_value else null end) as JVO_THERAPEUTIC_CHAR_COMMENTS,
max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_SCORE' then  secured_value else null end) as JVO_THERAPEUTIC_CHAR_SCORE,
max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_COMMENTS' then  secured_value else null end) as JVO_VISIT_STRUCTURE_COMMENTS,
max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_SCORE' then  secured_value else null end) as JVO_VISIT_STRUCTURE_SCORE



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

Go

create function survey_views.f_select_Joint_Visit_Observation
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
	max(case sq.pseudonym when 'NURSE_JVSCALE_GUIDE_0_LINES' then  secured_value else null end) as NURSE_JVSCALE_GUIDE_0_LINES,
max(case sq.pseudonym when 'NURSE_JVSCALE_GUIDE_1_LINES_CMT' then  secured_value else null end) as NURSE_JVSCALE_GUIDE_1_LINES_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_MOTIV_1_INTERVIEW' then  secured_value else null end) as NURSE_JVSCALE_MOTIV_1_INTERVIEW,
max(case sq.pseudonym when 'NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT' then  secured_value else null end) as NURSE_JVSCALE_MOTIV_1_INTERVIEW_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_PC_0_INTERVENTION' then  secured_value else null end) as NURSE_JVSCALE_PC_0_INTERVENTION,
max(case sq.pseudonym when 'NURSE_JVSCALE_PC_1_INTERVENTION_CMT' then  secured_value else null end) as NURSE_JVSCALE_PC_1_INTERVENTION_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_SELF_0_EFFICACY' then  secured_value else null end) as NURSE_JVSCALE_SELF_0_EFFICACY,
max(case sq.pseudonym when 'NURSE_JVSCALE_SELF_1_EFFICACY_CMT' then  secured_value else null end) as NURSE_JVSCALE_SELF_1_EFFICACY_CMT,
max(case sq.pseudonym when 'NURSE_JVSCALE_THERAPEUTIC_0_CHAR' then  secured_value else null end) as NURSE_JVSCALE_THERAPEUTIC_0_CHAR,
max(case sq.pseudonym when 'NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT' then  secured_value else null end) as NURSE_JVSCALE_THERAPEUTIC_0_CHAR_CMT



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

Go

create function survey_views.f_select_Maternal_Health_Assessment
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
CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_CANT_SOLVE' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_ADDICTION' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_ADDICTION,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS2' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS2,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_OTHER' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_OTHER,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_EDD' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_EDD,
max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_MN_12_Month_Infant
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_ASQ3_12MOS' then  secured_value else null end) as MN_ASQ3_12MOS,
max(case sq.pseudonym when 'MN_ASQ3_REFERRAL' then  secured_value else null end) as MN_ASQ3_REFERRAL,
max(case sq.pseudonym when 'MN_ASQSE_12MOS' then  secured_value else null end) as MN_ASQSE_12MOS,
max(case sq.pseudonym when 'MN_ASQSE_REFERRAL' then  secured_value else null end) as MN_ASQSE_REFERRAL,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE' then  secured_value else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_CPA_FILE' then  secured_value else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME' then  secured_value else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED' then  secured_value else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3' then  secured_value else null end) as MN_FURTHER_SCREEN_ASQ3,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQSE' then  secured_value else null end) as MN_FURTHER_SCREEN_ASQSE,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE' then  secured_value else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_NCAST_CAREGIVER' then  secured_value else null end) as MN_NCAST_CAREGIVER,
max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES' then  secured_value else null end) as MN_NCAST_CLARITY_CUES,
max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH' then  secured_value else null end) as MN_NCAST_COGN_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_DISTRESS' then  secured_value else null end) as MN_NCAST_DISTRESS,
max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH' then  secured_value else null end) as MN_NCAST_SE_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_SENS_CUES' then  secured_value else null end) as MN_NCAST_SENS_CUES,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV' then  secured_value else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_MN_18_Months_Toddler
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE' then  secured_value else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE' then  secured_value else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV' then  secured_value else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('MN 18 Months Toddler',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_MN_24_Month_Toddler
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE' then  secured_value else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE' then  secured_value else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV' then  secured_value else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_MN_6_Months_Infant
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_ASQ3_4MOS' then  secured_value else null end) as MN_ASQ3_4MOS,
max(case sq.pseudonym when 'MN_ASQ3_REFERRAL' then  secured_value else null end) as MN_ASQ3_REFERRAL,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE' then  secured_value else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_CPA_FILE' then  secured_value else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME' then  secured_value else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED' then  secured_value else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_FOLIC_ACID' then  secured_value else null end) as MN_FOLIC_ACID,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3' then  secured_value else null end) as MN_FURTHER_SCREEN_ASQ3,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE' then  secured_value else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_NCAST_CAREGIVER' then  secured_value else null end) as MN_NCAST_CAREGIVER,
max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES' then  secured_value else null end) as MN_NCAST_CLARITY_CUES,
max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH' then  secured_value else null end) as MN_NCAST_COGN_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_DISTRESS' then  secured_value else null end) as MN_NCAST_DISTRESS,
max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH' then  secured_value else null end) as MN_NCAST_SE_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_SENS_CUES' then  secured_value else null end) as MN_NCAST_SENS_CUES,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV' then  secured_value else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_MN_Child_Intake
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE' then  secured_value else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_ENROLLMENT_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE' then  secured_value else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV' then  secured_value else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_MN_Primary_Caregiver_Closure
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO' then  secured_value else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'MN_CPA_FILE' then  secured_value else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME' then  secured_value else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED' then  secured_value else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2' then  secured_value else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_MN_Primary_Caregiver_Intake
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE' then  secured_value else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER' then  secured_value else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES' then  secured_value else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME' then  secured_value else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_HOUSEHOLD_SIZE' then  secured_value else null end) as MN_HOUSEHOLD_SIZE,
max(case sq.pseudonym when 'MN_SITE' then  secured_value else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_WKS_PREGNANT' then  secured_value else null end) as MN_WKS_PREGNANT,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_New_Hire_Form
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
	max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL' then  secured_value else null end) as NEW_HIRE_0_ACCESS_LEVEL,
max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED' then  secured_value else null end) as NEW_HIRE_0_EDUC_COMPLETED,
max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL' then  secured_value else null end) as NEW_HIRE_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_0_FTE' then  secured_value else null end) as NEW_HIRE_0_FTE,
max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE' then  secured_value else null end) as NEW_HIRE_0_HIRE_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST' then  secured_value else null end) as NEW_HIRE_0_NAME_LAST,
max(case sq.pseudonym when 'NEW_HIRE_0_PHONE' then  secured_value else null end) as NEW_HIRE_0_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK' then  secured_value else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC' then  secured_value else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE' then  secured_value else null end) as NEW_HIRE_0_START_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME' then  secured_value else null end) as NEW_HIRE_0_TEAM_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_DOB' then  secured_value else null end) as NEW_HIRE_1_DOB,
max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST' then  secured_value else null end) as NEW_HIRE_1_NAME_FIRST,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_AGENCY' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_CITY' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_CITY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE1' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE1,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE2' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE2,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_NAME' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_STATE' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_STATE,
max(case sq.pseudonym when 'NEW_HIRE_1_REPLACE_STAFF_TERM' then  secured_value else null end) as NEW_HIRE_1_REPLACE_STAFF_TERM,
max(case sq.pseudonym when 'NEW_HIRE_1_ROLE' then  secured_value else null end) as NEW_HIRE_1_ROLE,
max(case sq.pseudonym when 'NEW_HIRE_ADDITIONAL_INFO' then  secured_value else null end) as NEW_HIRE_ADDITIONAL_INFO,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP' then  secured_value else null end) as NEW_HIRE_ADDRESS_0_ZIP,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_CITY,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE_OTHR' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STREET,
max(case sq.pseudonym when 'NEW_HIRE_ER_0_LNAME' then  secured_value else null end) as NEW_HIRE_ER_0_LNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_FNAME' then  secured_value else null end) as NEW_HIRE_ER_1_FNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_PHONE' then  secured_value else null end) as NEW_HIRE_ER_1_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL' then  secured_value else null end) as NEW_HIRE_SUP_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME_OTHR' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE' then  secured_value else null end) as NEW_HIRE_SUP_0_PHONE



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

Go

create function survey_views.f_select_New_Hire_V2
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
	max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL' then  secured_value else null end) as NEW_HIRE_0_ACCESS_LEVEL,
max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED' then  secured_value else null end) as NEW_HIRE_0_EDUC_COMPLETED,
max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL' then  secured_value else null end) as NEW_HIRE_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_0_FTE' then  secured_value else null end) as NEW_HIRE_0_FTE,
max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE' then  secured_value else null end) as NEW_HIRE_0_HIRE_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST' then  secured_value else null end) as NEW_HIRE_0_NAME_LAST,
max(case sq.pseudonym when 'NEW_HIRE_0_PHONE' then  secured_value else null end) as NEW_HIRE_0_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK' then  secured_value else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC' then  secured_value else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE' then  secured_value else null end) as NEW_HIRE_0_START_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME' then  secured_value else null end) as NEW_HIRE_0_TEAM_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_DOB' then  secured_value else null end) as NEW_HIRE_1_DOB,
max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST' then  secured_value else null end) as NEW_HIRE_1_NAME_FIRST,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_AGENCY' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_CITY' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_CITY,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE1' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE1,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_DATE2' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_DATE2,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_NAME' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_PREVIOUS_WORK_STATE' then  secured_value else null end) as NEW_HIRE_1_PREVIOUS_WORK_STATE,
max(case sq.pseudonym when 'NEW_HIRE_1_REPLACE_STAFF_TERM' then  secured_value else null end) as NEW_HIRE_1_REPLACE_STAFF_TERM,
max(case sq.pseudonym when 'NEW_HIRE_1_ROLE' then  secured_value else null end) as NEW_HIRE_1_ROLE,
max(case sq.pseudonym when 'NEW_HIRE_ADDITIONAL_INFO' then  secured_value else null end) as NEW_HIRE_ADDITIONAL_INFO,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP' then  secured_value else null end) as NEW_HIRE_ADDRESS_0_ZIP,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_CITY,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE_OTHR' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STREET,
max(case sq.pseudonym when 'NEW_HIRE_ER_0_LNAME' then  secured_value else null end) as NEW_HIRE_ER_0_LNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_FNAME' then  secured_value else null end) as NEW_HIRE_ER_1_FNAME,
max(case sq.pseudonym when 'NEW_HIRE_ER_1_PHONE' then  secured_value else null end) as NEW_HIRE_ER_1_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL' then  secured_value else null end) as NEW_HIRE_SUP_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME_OTHR' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME_OTHR,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE' then  secured_value else null end) as NEW_HIRE_SUP_0_PHONE



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

Go

create function survey_views.f_select_NFP_Los_Angeles__Outreach/Marketing
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
	max(case sq.pseudonym when 'LA_CTY_CONTACT_NAME_OUTREACH' then  secured_value else null end) as LA_CTY_CONTACT_NAME_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_CONTACT_PHONE_OUTREACH' then  secured_value else null end) as LA_CTY_CONTACT_PHONE_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_NOTES_OUTREACH' then  secured_value else null end) as LA_CTY_NOTES_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_ORG_NAME_OUTREACH' then  secured_value else null end) as LA_CTY_ORG_NAME_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OTH_OUTREACH' then  secured_value else null end) as LA_CTY_ORG_TYPE_OTH_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OUTREACH' then  secured_value else null end) as LA_CTY_ORG_TYPE_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF_OUTREACH' then  secured_value else null end) as LA_CTY_STAFF_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF2_OUTREACH' then  secured_value else null end) as LA_CTY_STAFF2_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF3_OUTREACH' then  secured_value else null end) as LA_CTY_STAFF3_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF4_OUTREACH' then  secured_value else null end) as LA_CTY_STAFF4_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_STAFF5_OUTREACH' then  secured_value else null end) as LA_CTY_STAFF5_OUTREACH,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_OUTREACH' then  secured_value else null end) as LA_CTY_TARGET_POP_OUTREACH



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

Go

create function survey_views.f_select_NFP_Tribal_Project
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
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_TRIBAL_0_PARITY' then  secured_value else null end) as CLIENT_TRIBAL_0_PARITY,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_1_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_1_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_1_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_1_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_10_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_10_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_10_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_10_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_2_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_2_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_2_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_2_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_3_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_3_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_3_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_3_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_4_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_4_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_4_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_4_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_5_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_5_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_5_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_5_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_6_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_6_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_6_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_6_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_7_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_7_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_7_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_7_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_8_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_8_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_8_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_8_LIVING,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_9_DOB' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_9_DOB,
max(case sq.pseudonym when 'CLIENT_TRIBAL_CHILD_9_LIVING' then  secured_value else null end) as CLIENT_TRIBAL_CHILD_9_LIVING,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Nurse_Assessment
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
	NURSE_ASSESS_ DATA_0_USES varchar(256),
NURSE_ASSESS_ DATA_1_USES_CMT varchar(256),
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
	max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_0_USES' then  secured_value else null end) as NURSE_ASSESS_ DATA_0_USES,
max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_1_USES_CMT' then  secured_value else null end) as NURSE_ASSESS_ DATA_1_USES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_0_UTILIZES' then  secured_value else null end) as NURSE_ASSESS_6DOMAINS_0_UTILIZES,
max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT' then  secured_value else null end) as NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE' then  secured_value else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE,
max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT' then  secured_value else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC' then  secured_value else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC,
max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT' then  secured_value else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF' then  secured_value else null end) as NURSE_ASSESS_CARE_0_SELF,
max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF_CMT' then  secured_value else null end) as NURSE_ASSESS_CARE_0_SELF_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS' then  secured_value else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS,
max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT' then  secured_value else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM' then  secured_value else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM,
max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT' then  secured_value else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT' then  secured_value else null end) as NURSE_ASSESS_CULTURE_0_IMPACT,
max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT_CMT' then  secured_value else null end) as NURSE_ASSESS_CULTURE_0_IMPACT_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY' then  secured_value else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY,
max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT' then  secured_value else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES' then  secured_value else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES,
max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT' then  secured_value else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING' then  secured_value else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING,
max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT' then  secured_value else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS' then  secured_value else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS,
max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT' then  secured_value else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES' then  secured_value else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES,
max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT' then  secured_value else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME' then  secured_value else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME,
max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT' then  secured_value else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC' then  secured_value else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC,
max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT' then  secured_value else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF' then  secured_value else null end) as NURSE_ASSESS_REFLECTION_0_SELF,
max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF_CMT' then  secured_value else null end) as NURSE_ASSESS_REFLECTION_0_SELF_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION' then  secured_value else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION,
max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT' then  secured_value else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC' then  secured_value else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC,
max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT' then  secured_value else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE' then  secured_value else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE,
max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT' then  secured_value else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD' then  secured_value else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD,
max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT' then  secured_value else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES' then  secured_value else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES,
max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT' then  secured_value else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT,
max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS' then  secured_value else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS,
max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT' then  secured_value else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT



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

Go

create function survey_views.f_select_PHQ_9
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PHQ9_0_TOTAL_SCORE' then  secured_value else null end) as CLIENT_PHQ9_0_TOTAL_SCORE,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_CONCENTRATION' then  secured_value else null end) as CLIENT_PHQ9_1_CONCENTRATION,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_DIFFICULTY' then  secured_value else null end) as CLIENT_PHQ9_1_DIFFICULTY,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_BAD' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_BAD,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_DEPRESSED' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_DEPRESSED,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_TIRED' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_TIRED,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_HURT_SELF' then  secured_value else null end) as CLIENT_PHQ9_1_HURT_SELF,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_LITTLE_INTEREST' then  secured_value else null end) as CLIENT_PHQ9_1_LITTLE_INTEREST,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_MOVE_SPEAK' then  secured_value else null end) as CLIENT_PHQ9_1_MOVE_SPEAK,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_EAT' then  secured_value else null end) as CLIENT_PHQ9_1_TROUBLE_EAT,
max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_SLEEP' then  secured_value else null end) as CLIENT_PHQ9_1_TROUBLE_SLEEP,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



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

Go

create function survey_views.f_select_Profile_Of_Program_Staff_UPDATE
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
	NURSE_EDUCATION_0_NURSING_DEGREES varchar(256),
NURSE_EDUCATION_1_OTHER_DEGREES varchar(256),
NURSE_PRIMARY_ROLE varchar(256),
NURSE_PRIMARY_ROLE_FTE varchar(256),
NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE varchar(256),
NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE varchar(256),
NURSE_PROFESSIONAL_1_NEW_ROLE varchar(256),
NURSE_PROFESSIONAL_1_OTHER_FTE varchar(256),
NURSE_PROFESSIONAL_1_SUPERVISOR_FTE varchar(256),
NURSE_PROFESSIONAL_1_TOTAL_FTE varchar(256),
NURSE_SECONDARY_ROLE varchar(256),
NURSE_SECONDARY_ROLE_FTE varchar(256),
NURSE_STATUS_0_CHANGE_LEAVE_END varchar(256),
NURSE_STATUS_0_CHANGE_LEAVE_START varchar(256),
NURSE_STATUS_0_CHANGE_SPECIFIC varchar(256),
NURSE_STATUS_0_CHANGE_START_DATE varchar(256),
NURSE_STATUS_0_CHANGE_TERMINATE_DATE varchar(256),
NURSE_STATUS_0_CHANGE_TRANSFER varchar(256),
NURSE_STATUS_TERM_REASON varchar(256),
NURSE_STATUS_TERM_REASON_OTHER varchar(256),
NURSE_TEAM_NAME varchar(256),
NURSE_TEAM_START_DATE varchar(256)

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
	max(case sq.pseudonym when 'NURSE_EDUCATION_0_NURSING_DEGREES' then  secured_value else null end) as NURSE_EDUCATION_0_NURSING_DEGREES,
max(case sq.pseudonym when 'NURSE_EDUCATION_1_OTHER_DEGREES' then  secured_value else null end) as NURSE_EDUCATION_1_OTHER_DEGREES,
max(case sq.pseudonym when 'NURSE_PRIMARY_ROLE' then  secured_value else null end) as NURSE_PRIMARY_ROLE,
max(case sq.pseudonym when 'NURSE_PRIMARY_ROLE_FTE' then  secured_value else null end) as NURSE_PRIMARY_ROLE_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE' then  secured_value else null end) as NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE' then  secured_value else null end) as NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_NEW_ROLE' then  secured_value else null end) as NURSE_PROFESSIONAL_1_NEW_ROLE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_OTHER_FTE' then  secured_value else null end) as NURSE_PROFESSIONAL_1_OTHER_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_SUPERVISOR_FTE' then  secured_value else null end) as NURSE_PROFESSIONAL_1_SUPERVISOR_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_TOTAL_FTE' then  secured_value else null end) as NURSE_PROFESSIONAL_1_TOTAL_FTE,
max(case sq.pseudonym when 'NURSE_SECONDARY_ROLE' then  secured_value else null end) as NURSE_SECONDARY_ROLE,
max(case sq.pseudonym when 'NURSE_SECONDARY_ROLE_FTE' then  secured_value else null end) as NURSE_SECONDARY_ROLE_FTE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_LEAVE_END' then  secured_value else null end) as NURSE_STATUS_0_CHANGE_LEAVE_END,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_LEAVE_START' then  secured_value else null end) as NURSE_STATUS_0_CHANGE_LEAVE_START,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_SPECIFIC' then  secured_value else null end) as NURSE_STATUS_0_CHANGE_SPECIFIC,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_START_DATE' then  secured_value else null end) as NURSE_STATUS_0_CHANGE_START_DATE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_TERMINATE_DATE' then  secured_value else null end) as NURSE_STATUS_0_CHANGE_TERMINATE_DATE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_TRANSFER' then  secured_value else null end) as NURSE_STATUS_0_CHANGE_TRANSFER,
max(case sq.pseudonym when 'NURSE_STATUS_TERM_REASON' then  secured_value else null end) as NURSE_STATUS_TERM_REASON,
max(case sq.pseudonym when 'NURSE_STATUS_TERM_REASON_OTHER' then  secured_value else null end) as NURSE_STATUS_TERM_REASON_OTHER,
max(case sq.pseudonym when 'NURSE_TEAM_NAME' then  secured_value else null end) as NURSE_TEAM_NAME,
max(case sq.pseudonym when 'NURSE_TEAM_START_DATE' then  secured_value else null end) as NURSE_TEAM_START_DATE



     from survey_views.f_secure_fact_survey_response('Profile Of Program Staff-UPDATE',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Record_of_Team_Meetings_and_Case_Conferences
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
	AGENCY_MEETING_0_TYPE varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF1 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF10 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF2 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF3 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF4 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF5 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF6 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF7 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF8 varchar(256),
AGENCY_MEETING_1_ATTENDEES_NONSTAFF9 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF1 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF10 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF11 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF12 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF13 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF14 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF15 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF16 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF17 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF18 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF19 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF2 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF20 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF21 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF22 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF23 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF24 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF25 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF3 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF4 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF5 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF6 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF7 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF8 varchar(256),
AGENCY_MEETING_1_ATTENDEES_STAFF9 varchar(256),
AGENCY_MEETING_1_LENGTH varchar(256)

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
	max(case sq.pseudonym when 'AGENCY_MEETING_0_TYPE' then  secured_value else null end) as AGENCY_MEETING_0_TYPE,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF1' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF10' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF2' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF3' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF4' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF5' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF6' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF7' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF8' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF9' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF1' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF10' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF11' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF11,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF12' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF12,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF13' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF13,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF14' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF14,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF15' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF15,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF16' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF16,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF17' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF17,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF18' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF18,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF19' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF19,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF2' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF20' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF20,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF21' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF21,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF22' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF22,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF23' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF23,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF24' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF24,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF25' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF25,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF3' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF4' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF5' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF6' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF7' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF8' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF9' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_LENGTH' then  secured_value else null end) as AGENCY_MEETING_1_LENGTH



     from survey_views.f_secure_fact_survey_response('Record of Team Meetings and Case Conferences',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Referrals_To_NFP_Program
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
REFERRAL_PROSPECT_0_FOLLOWUP_NURSE varchar(256),
REFERRAL_PROSPECT_0_MARKETING_SOURCE varchar(256),
REFERRAL_PROSPECT_0_NOTES varchar(256),
REFERRAL_PROSPECT_0_SOURCE_CODE varchar(256),
REFERRAL_PROSPECT_0_WAIT_LIST varchar(256),
REFERRAL_PROSPECT_DEMO_0_NAME_LAST varchar(256),
REFERRAL_PROSPECT_DEMO_1_CELL varchar(256),
REFERRAL_PROSPECT_DEMO_1_DOB varchar(256),
REFERRAL_PROSPECT_DEMO_1_EDD varchar(256),
REFERRAL_PROSPECT_DEMO_1_EMAIL varchar(256),
REFERRAL_PROSPECT_DEMO_1_NAME_FIRST varchar(256),
REFERRAL_PROSPECT_DEMO_1_PHONE_HOME varchar(256),
REFERRAL_PROSPECT_DEMO_1_PLANG varchar(256),
REFERRAL_PROSPECT_DEMO_1_STREET varchar(256),
REFERRAL_PROSPECT_DEMO_1_STREET2 varchar(256),
REFERRAL_PROSPECT_DEMO_1_WORK varchar(256),
REFERRAL_PROSPECT_DEMO_1_ZIP varchar(256),
REFERRAL_SOURCE_PRIMARY_0_NAME varchar(256),
REFERRAL_SOURCE_PRIMARY_1_LOCATION varchar(256),
REFERRAL_SOURCE_SECONDARY_0_NAME varchar(256),
REFERRAL_SOURCE_SECONDARY_1_LOCATION varchar(256)

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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_FOLLOWUP_NURSE' then  secured_value else null end) as REFERRAL_PROSPECT_0_FOLLOWUP_NURSE,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_MARKETING_SOURCE' then  secured_value else null end) as REFERRAL_PROSPECT_0_MARKETING_SOURCE,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_NOTES' then  secured_value else null end) as REFERRAL_PROSPECT_0_NOTES,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_SOURCE_CODE' then  secured_value else null end) as REFERRAL_PROSPECT_0_SOURCE_CODE,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_0_WAIT_LIST' then  secured_value else null end) as REFERRAL_PROSPECT_0_WAIT_LIST,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_0_NAME_LAST' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_0_NAME_LAST,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_CELL' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_CELL,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_DOB' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_DOB,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_EDD' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_EDD,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_EMAIL' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_EMAIL,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_NAME_FIRST' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_NAME_FIRST,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_PHONE_HOME' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_PHONE_HOME,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_PLANG' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_PLANG,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_STREET' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_STREET,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_STREET2' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_STREET2,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_WORK' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_WORK,
max(case sq.pseudonym when 'REFERRAL_PROSPECT_DEMO_1_ZIP' then  secured_value else null end) as REFERRAL_PROSPECT_DEMO_1_ZIP,
max(case sq.pseudonym when 'REFERRAL_SOURCE_PRIMARY_0_NAME' then  secured_value else null end) as REFERRAL_SOURCE_PRIMARY_0_NAME,
max(case sq.pseudonym when 'REFERRAL_SOURCE_PRIMARY_1_LOCATION' then  secured_value else null end) as REFERRAL_SOURCE_PRIMARY_1_LOCATION,
max(case sq.pseudonym when 'REFERRAL_SOURCE_SECONDARY_0_NAME' then  secured_value else null end) as REFERRAL_SOURCE_SECONDARY_0_NAME,
max(case sq.pseudonym when 'REFERRAL_SOURCE_SECONDARY_1_LOCATION' then  secured_value else null end) as REFERRAL_SOURCE_SECONDARY_1_LOCATION



     from survey_views.f_secure_fact_survey_response('Referrals To NFP Program',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Referrals_to_Services
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
NURSE_PERSONAL_0_NAME varchar(256),
REFERRALS_TO_0_FORM_TYPE varchar(256),
SERIVCE_REFER_0_OTHER1_DESC varchar(256),
SERIVCE_REFER_0_OTHER2_DESC varchar(256),
SERIVCE_REFER_0_OTHER3_DESC varchar(256),
SERVICE_REFER_0_ADOPTION varchar(256),
SERVICE_REFER_0_ALCOHOL_ABUSE varchar(256),
SERVICE_REFER_0_BIRTH_EDUC_CLASS varchar(256),
SERVICE_REFER_0_CHARITY varchar(256),
SERVICE_REFER_0_CHILD_CARE varchar(256),
SERVICE_REFER_0_CHILD_SUPPORT varchar(256),
SERVICE_REFER_0_CPS varchar(256),
SERVICE_REFER_0_DENTAL varchar(256),
SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY varchar(256),
SERVICE_REFER_0_DRUG_ABUSE varchar(256),
SERVICE_REFER_0_FOODSTAMP varchar(256),
SERVICE_REFER_0_GED varchar(256),
SERVICE_REFER_0_HIGHER_EDUC varchar(256),
SERVICE_REFER_0_HOUSING varchar(256),
SERVICE_REFER_0_INTERVENTION varchar(256),
SERVICE_REFER_0_IPV varchar(256),
SERVICE_REFER_0_JOB_TRAINING varchar(256),
SERVICE_REFER_0_LACTATION varchar(256),
SERVICE_REFER_0_LEGAL_CLIENT varchar(256),
SERVICE_REFER_0_MEDICAID varchar(256),
SERVICE_REFER_0_MENTAL varchar(256),
SERVICE_REFER_0_OTHER varchar(256),
SERVICE_REFER_0_PATERNITY varchar(256),
SERVICE_REFER_0_PCP varchar(256),
SERVICE_REFER_0_PCP_R2 varchar(256),
SERVICE_REFER_0_PREVENT_INJURY varchar(256),
SERVICE_REFER_0_PRIVATE_INSURANCE varchar(256),
SERVICE_REFER_0_RELATIONSHIP_COUNSELING varchar(256),
SERVICE_REFER_0_SCHIP varchar(256),
SERVICE_REFER_0_SMOKE varchar(256),
SERVICE_REFER_0_SOCIAL_SECURITY varchar(256),
SERVICE_REFER_0_SPECIAL_NEEDS varchar(256),
SERVICE_REFER_0_SUBSID_CHILD_CARE varchar(256),
SERVICE_REFER_0_TANF varchar(256),
SERVICE_REFER_0_TRANSPORTATION varchar(256),
SERVICE_REFER_0_UNEMPLOYMENT varchar(256),
SERVICE_REFER_0_WIC_CLIENT varchar(256),
SERVICE_REFER_INDIAN_HEALTH varchar(256),
SERVICE_REFER_MILITARY_INS varchar(256)

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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'REFERRALS_TO_0_FORM_TYPE' then  secured_value else null end) as REFERRALS_TO_0_FORM_TYPE,
max(case sq.pseudonym when 'SERIVCE_REFER_0_OTHER1_DESC' then  secured_value else null end) as SERIVCE_REFER_0_OTHER1_DESC,
max(case sq.pseudonym when 'SERIVCE_REFER_0_OTHER2_DESC' then  secured_value else null end) as SERIVCE_REFER_0_OTHER2_DESC,
max(case sq.pseudonym when 'SERIVCE_REFER_0_OTHER3_DESC' then  secured_value else null end) as SERIVCE_REFER_0_OTHER3_DESC,
max(case sq.pseudonym when 'SERVICE_REFER_0_ADOPTION' then  secured_value else null end) as SERVICE_REFER_0_ADOPTION,
max(case sq.pseudonym when 'SERVICE_REFER_0_ALCOHOL_ABUSE' then  secured_value else null end) as SERVICE_REFER_0_ALCOHOL_ABUSE,
max(case sq.pseudonym when 'SERVICE_REFER_0_BIRTH_EDUC_CLASS' then  secured_value else null end) as SERVICE_REFER_0_BIRTH_EDUC_CLASS,
max(case sq.pseudonym when 'SERVICE_REFER_0_CHARITY' then  secured_value else null end) as SERVICE_REFER_0_CHARITY,
max(case sq.pseudonym when 'SERVICE_REFER_0_CHILD_CARE' then  secured_value else null end) as SERVICE_REFER_0_CHILD_CARE,
max(case sq.pseudonym when 'SERVICE_REFER_0_CHILD_SUPPORT' then  secured_value else null end) as SERVICE_REFER_0_CHILD_SUPPORT,
max(case sq.pseudonym when 'SERVICE_REFER_0_CPS' then  secured_value else null end) as SERVICE_REFER_0_CPS,
max(case sq.pseudonym when 'SERVICE_REFER_0_DENTAL' then  secured_value else null end) as SERVICE_REFER_0_DENTAL,
max(case sq.pseudonym when 'SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY' then  secured_value else null end) as SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY,
max(case sq.pseudonym when 'SERVICE_REFER_0_DRUG_ABUSE' then  secured_value else null end) as SERVICE_REFER_0_DRUG_ABUSE,
max(case sq.pseudonym when 'SERVICE_REFER_0_FOODSTAMP' then  secured_value else null end) as SERVICE_REFER_0_FOODSTAMP,
max(case sq.pseudonym when 'SERVICE_REFER_0_GED' then  secured_value else null end) as SERVICE_REFER_0_GED,
max(case sq.pseudonym when 'SERVICE_REFER_0_HIGHER_EDUC' then  secured_value else null end) as SERVICE_REFER_0_HIGHER_EDUC,
max(case sq.pseudonym when 'SERVICE_REFER_0_HOUSING' then  secured_value else null end) as SERVICE_REFER_0_HOUSING,
max(case sq.pseudonym when 'SERVICE_REFER_0_INTERVENTION' then  secured_value else null end) as SERVICE_REFER_0_INTERVENTION,
max(case sq.pseudonym when 'SERVICE_REFER_0_IPV' then  secured_value else null end) as SERVICE_REFER_0_IPV,
max(case sq.pseudonym when 'SERVICE_REFER_0_JOB_TRAINING' then  secured_value else null end) as SERVICE_REFER_0_JOB_TRAINING,
max(case sq.pseudonym when 'SERVICE_REFER_0_LACTATION' then  secured_value else null end) as SERVICE_REFER_0_LACTATION,
max(case sq.pseudonym when 'SERVICE_REFER_0_LEGAL_CLIENT' then  secured_value else null end) as SERVICE_REFER_0_LEGAL_CLIENT,
max(case sq.pseudonym when 'SERVICE_REFER_0_MEDICAID' then  secured_value else null end) as SERVICE_REFER_0_MEDICAID,
max(case sq.pseudonym when 'SERVICE_REFER_0_MENTAL' then  secured_value else null end) as SERVICE_REFER_0_MENTAL,
max(case sq.pseudonym when 'SERVICE_REFER_0_OTHER' then  secured_value else null end) as SERVICE_REFER_0_OTHER,
max(case sq.pseudonym when 'SERVICE_REFER_0_PATERNITY' then  secured_value else null end) as SERVICE_REFER_0_PATERNITY,
max(case sq.pseudonym when 'SERVICE_REFER_0_PCP' then  secured_value else null end) as SERVICE_REFER_0_PCP,
max(case sq.pseudonym when 'SERVICE_REFER_0_PCP_R2' then  secured_value else null end) as SERVICE_REFER_0_PCP_R2,
max(case sq.pseudonym when 'SERVICE_REFER_0_PREVENT_INJURY' then  secured_value else null end) as SERVICE_REFER_0_PREVENT_INJURY,
max(case sq.pseudonym when 'SERVICE_REFER_0_PRIVATE_INSURANCE' then  secured_value else null end) as SERVICE_REFER_0_PRIVATE_INSURANCE,
max(case sq.pseudonym when 'SERVICE_REFER_0_RELATIONSHIP_COUNSELING' then  secured_value else null end) as SERVICE_REFER_0_RELATIONSHIP_COUNSELING,
max(case sq.pseudonym when 'SERVICE_REFER_0_SCHIP' then  secured_value else null end) as SERVICE_REFER_0_SCHIP,
max(case sq.pseudonym when 'SERVICE_REFER_0_SMOKE' then  secured_value else null end) as SERVICE_REFER_0_SMOKE,
max(case sq.pseudonym when 'SERVICE_REFER_0_SOCIAL_SECURITY' then  secured_value else null end) as SERVICE_REFER_0_SOCIAL_SECURITY,
max(case sq.pseudonym when 'SERVICE_REFER_0_SPECIAL_NEEDS' then  secured_value else null end) as SERVICE_REFER_0_SPECIAL_NEEDS,
max(case sq.pseudonym when 'SERVICE_REFER_0_SUBSID_CHILD_CARE' then  secured_value else null end) as SERVICE_REFER_0_SUBSID_CHILD_CARE,
max(case sq.pseudonym when 'SERVICE_REFER_0_TANF' then  secured_value else null end) as SERVICE_REFER_0_TANF,
max(case sq.pseudonym when 'SERVICE_REFER_0_TRANSPORTATION' then  secured_value else null end) as SERVICE_REFER_0_TRANSPORTATION,
max(case sq.pseudonym when 'SERVICE_REFER_0_UNEMPLOYMENT' then  secured_value else null end) as SERVICE_REFER_0_UNEMPLOYMENT,
max(case sq.pseudonym when 'SERVICE_REFER_0_WIC_CLIENT' then  secured_value else null end) as SERVICE_REFER_0_WIC_CLIENT,
max(case sq.pseudonym when 'SERVICE_REFER_INDIAN_HEALTH' then  secured_value else null end) as SERVICE_REFER_INDIAN_HEALTH,
max(case sq.pseudonym when 'SERVICE_REFER_MILITARY_INS' then  secured_value else null end) as SERVICE_REFER_MILITARY_INS



     from survey_views.f_secure_fact_survey_response('Referrals to Services',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Relationship_Assessment
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
CLIENT_ABUSE_AFRAID_0_PARTNER varchar(256),
CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER varchar(256),
CLIENT_ABUSE_FORCED_0_SEX varchar(256),
CLIENT_ABUSE_FORCED_1_SEX_LAST_YR varchar(256),
CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME varchar(256),
CLIENT_ABUSE_HIT_0_SLAP_PARTNER varchar(256),
CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER varchar(256),
CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER varchar(256),
CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER varchar(256),
CLIENT_ABUSE_TIMES_0_HURT_LAST_YR varchar(256),
CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME varchar(256),
CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER varchar(256),
CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_ABUSE_AFRAID_0_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_AFRAID_0_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_FORCED_0_SEX' then  secured_value else null end) as CLIENT_ABUSE_FORCED_0_SEX,
max(case sq.pseudonym when 'CLIENT_ABUSE_FORCED_1_SEX_LAST_YR' then  secured_value else null end) as CLIENT_ABUSE_FORCED_1_SEX_LAST_YR,
max(case sq.pseudonym when 'CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME' then  secured_value else null end) as CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME,
max(case sq.pseudonym when 'CLIENT_ABUSE_HIT_0_SLAP_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_HIT_0_SLAP_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HURT_LAST_YR' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_HURT_LAST_YR,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER,
max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Relationship Assessment',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Staff_Team_to_Team_Transfer_Request
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
	STAFF_XFER_CLIENTS varchar(256),
STAFF_XFER_FROM_TEAM_A varchar(256),
STAFF_XFER_LAST_DAY_TEAM_A varchar(256),
STAFF_XFER_NAME varchar(256),
STAFF_XFER_NEW_TEAM_B varchar(256),
STAFF_XFER_PRIMARY_FTE varchar(256),
STAFF_XFER_PRIMARY_ROLE varchar(256),
STAFF_XFER_SECOND_FTE varchar(256),
STAFF_XFER_SECOND_ROLE varchar(256),
STAFF_XFER_START_DATE_TEAM_B varchar(256),
STAFF_XFER_SUP_PROMO varchar(256)

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
	max(case sq.pseudonym when 'STAFF_XFER_CLIENTS' then  secured_value else null end) as STAFF_XFER_CLIENTS,
max(case sq.pseudonym when 'STAFF_XFER_FROM_TEAM_A' then  secured_value else null end) as STAFF_XFER_FROM_TEAM_A,
max(case sq.pseudonym when 'STAFF_XFER_LAST_DAY_TEAM_A' then  secured_value else null end) as STAFF_XFER_LAST_DAY_TEAM_A,
max(case sq.pseudonym when 'STAFF_XFER_NAME' then  secured_value else null end) as STAFF_XFER_NAME,
max(case sq.pseudonym when 'STAFF_XFER_NEW_TEAM_B' then  secured_value else null end) as STAFF_XFER_NEW_TEAM_B,
max(case sq.pseudonym when 'STAFF_XFER_PRIMARY_FTE' then  secured_value else null end) as STAFF_XFER_PRIMARY_FTE,
max(case sq.pseudonym when 'STAFF_XFER_PRIMARY_ROLE' then  secured_value else null end) as STAFF_XFER_PRIMARY_ROLE,
max(case sq.pseudonym when 'STAFF_XFER_SECOND_FTE' then  secured_value else null end) as STAFF_XFER_SECOND_FTE,
max(case sq.pseudonym when 'STAFF_XFER_SECOND_ROLE' then  secured_value else null end) as STAFF_XFER_SECOND_ROLE,
max(case sq.pseudonym when 'STAFF_XFER_START_DATE_TEAM_B' then  secured_value else null end) as STAFF_XFER_START_DATE_TEAM_B,
max(case sq.pseudonym when 'STAFF_XFER_SUP_PROMO' then  secured_value else null end) as STAFF_XFER_SUP_PROMO



     from survey_views.f_secure_fact_survey_response('Staff Team-to-Team Transfer Request',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_STAR_Framework
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
Client_0_ID_NSO varchar(256),
CLIENT_CAREGIVING_FRIENDS_FAM varchar(256),
CLIENT_CAREGIVING_RISK_LEVEL varchar(256),
CLIENT_CAREGIVING_SERVICES_GOALS varchar(256),
CLIENT_CAREGIVING_STAGE_CHANGE varchar(256),
CLIENT_CAREGIVING_UNDERSTANDS_RISK varchar(256),
CLIENT_CHLD_CARE_FRIENDS_FAM varchar(256),
CLIENT_CHLD_CARE_RISK_LEVEL varchar(256),
CLIENT_CHLD_CARE_SERVICES_GOALS varchar(256),
CLIENT_CHLD_CARE_STAGE_CHANGE varchar(256),
CLIENT_CHLD_CARE_UNDERSTANDS_RISK varchar(256),
CLIENT_CHLD_HEALTH_FRIENDS_FAM varchar(256),
CLIENT_CHLD_HEALTH_RISK_LEVEL varchar(256),
CLIENT_CHLD_HEALTH_SERVICES_GOALS varchar(256),
CLIENT_CHLD_HEALTH_STAGE_CHANGE varchar(256),
CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK varchar(256),
CLIENT_CHLD_WELL_FRIENDS_FAM varchar(256),
CLIENT_CHLD_WELL_RISK_LEVEL varchar(256),
CLIENT_CHLD_WELL_SERVICES_GOALS varchar(256),
CLIENT_CHLD_WELL_STAGE_CHANGE varchar(256),
CLIENT_CHLD_WELL_UNDERSTANDS_RISK varchar(256),
CLIENT_COMM_SVCS_FRIENDS_FAM varchar(256),
CLIENT_COMM_SVCS_RISK_LEVEL varchar(256),
CLIENT_COMM_SVCS_SERVICES_GOALS varchar(256),
CLIENT_COMM_SVCS_STAGE_CHANGE varchar(256),
CLIENT_COMM_SVCS_UNDERSTANDS_RISK varchar(256),
CLIENT_COMPLICATION_ILL_FRIENDS_FAM varchar(256),
CLIENT_COMPLICATION_ILL_RISK_LEVEL varchar(256),
CLIENT_COMPLICATION_ILL_SERVICES_GOALS varchar(256),
CLIENT_COMPLICATION_ILL_STAGE_CHANGE varchar(256),
CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK varchar(256),
CLIENT_CRIMINAL_FRIENDS_FAM varchar(256),
CLIENT_CRIMINAL_RISK_LEVEL varchar(256),
CLIENT_CRIMINAL_SERVICES_GOALS varchar(256),
CLIENT_CRIMINAL_STAGE_CHANGE varchar(256),
CLIENT_CRIMINAL_UNDERSTANDS_RISK varchar(256),
CLIENT_DISABILITY_FRIENDS_FAM varchar(256),
CLIENT_DISABILITY_RISK_LEVEL varchar(256),
CLIENT_DISABILITY_SERVICES_GOALS varchar(256),
CLIENT_DISABILITY_STAGE_CHANGE varchar(256),
CLIENT_DISABILITY_UNDERSTANDS_RISK varchar(256),
CLIENT_ECONOMIC_FRIENDS_FAM varchar(256),
CLIENT_ECONOMIC_RISK_LEVEL varchar(256),
CLIENT_ECONOMIC_SERVICES_GOALS varchar(256),
CLIENT_ECONOMIC_STAGE_CHANGE varchar(256),
CLIENT_ECONOMIC_UNDERSTANDS_RISK varchar(256),
CLIENT_EDUC_FRIENDS_FAM varchar(256),
CLIENT_EDUC_RISK_LEVEL varchar(256),
CLIENT_EDUC_SERVICES_GOALS varchar(256),
CLIENT_EDUC_STAGE_CHANGE varchar(256),
CLIENT_EDUC_UNDERSTANDS_RISK varchar(256),
CLIENT_ENGLIT_FRIENDS_FAM varchar(256),
CLIENT_ENGLIT_RISK_LEVEL varchar(256),
CLIENT_ENGLIT_SERVICES_GOALS varchar(256),
CLIENT_ENGLIT_STAGE_CHANGE varchar(256),
CLIENT_ENGLIT_UNDERSTANDS_RISK varchar(256),
CLIENT_ENVIRO_HEALTH_FRIENDS_FAM varchar(256),
CLIENT_ENVIRO_HEALTH_RISK_LEVEL varchar(256),
CLIENT_ENVIRO_HEALTH_SERVICES_GOALS varchar(256),
CLIENT_ENVIRO_HEALTH_STAGE_CHANGE varchar(256),
CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK varchar(256),
CLIENT_GLOBAL_FACTORS varchar(256),
CLIENT_HLTH_SVCS_FRIENDS_FAM varchar(256),
CLIENT_HLTH_SVCS_RISK_LEVEL varchar(256),
CLIENT_HLTH_SVCS_SERVICES_GOALS varchar(256),
CLIENT_HLTH_SVCS_STAGE_CHANGE varchar(256),
CLIENT_HLTH_SVCS_UNDERSTANDS_RISK varchar(256),
CLIENT_HOME_SAFETY_FRIENDS_FAM varchar(256),
CLIENT_HOME_SAFETY_RISK_LEVEL varchar(256),
CLIENT_HOME_SAFETY_SERVICES_GOALS varchar(256),
CLIENT_HOME_SAFETY_STAGE_CHANGE varchar(256),
CLIENT_HOME_SAFETY_UNDERSTANDS_RISK varchar(256),
CLIENT_HOMELESS_FRIENDS_FAM varchar(256),
CLIENT_HOMELESS_RISK_LEVEL varchar(256),
CLIENT_HOMELESS_SERVICES_GOALS varchar(256),
CLIENT_HOMELESS_STAGE_CHANGE varchar(256),
CLIENT_HOMELESS_UNDERSTANDS_RISK varchar(256),
CLIENT_IPV_FRIENDS_FAM varchar(256),
CLIENT_IPV_RISK_LEVEL varchar(256),
CLIENT_IPV_SERVICES_GOALS varchar(256),
CLIENT_IPV_STAGE_CHANGE varchar(256),
CLIENT_IPV_UNDERSTANDS_RISK varchar(256),
CLIENT_LONELY_FRIENDS_FAM varchar(256),
CLIENT_LONELY_RISK_LEVEL varchar(256),
CLIENT_LONELY_SERVICES_GOALS varchar(256),
CLIENT_LONELY_STAGE_CHANGE varchar(256),
CLIENT_LONELY_UNDERSTANDS_RISK varchar(256),
CLIENT_MENTAL_HEALTH_FRIENDS_FAM varchar(256),
CLIENT_MENTAL_HEALTH_RISK_LEVEL varchar(256),
CLIENT_MENTAL_HEALTH_SERVICES_GOALS varchar(256),
CLIENT_MENTAL_HEALTH_STAGE_CHANGE varchar(256),
CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK varchar(256),
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256),
CLIENT_PERSONAL_0_NAME_FIRST varchar(256),
CLIENT_PERSONAL_0_NAME_LAST varchar(256),
CLIENT_PREGPLAN_FRIENDS_FAM varchar(256),
CLIENT_PREGPLAN_RISK_LEVEL varchar(256),
CLIENT_PREGPLAN_SERVICES_GOALS varchar(256),
CLIENT_PREGPLAN_STAGE_CHANGE varchar(256),
CLIENT_PREGPLAN_UNDERSTANDS_RISK varchar(256),
CLIENT_SUBSTANCE_FRIENDS_FAM varchar(256),
CLIENT_SUBSTANCE_RISK_LEVEL varchar(256),
CLIENT_SUBSTANCE_SERVICES_GOALS varchar(256),
CLIENT_SUBSTANCE_STAGE_CHANGE varchar(256),
CLIENT_SUBSTANCE_UNDERSTANDS_RISK varchar(256),
CLIENT_UNSAFE_NTWK_FRIENDS_FAM varchar(256),
CLIENT_UNSAFE_NTWK_RISK_LEVEL varchar(256),
CLIENT_UNSAFE_NTWK_SERVICES_GOALS varchar(256),
CLIENT_UNSAFE_NTWK_STAGE_CHANGE varchar(256),
CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'Client_0_ID_NSO' then  secured_value else null end) as Client_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_FRIENDS_FAM' then  secured_value else null end) as CLIENT_CAREGIVING_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_RISK_LEVEL' then  secured_value else null end) as CLIENT_CAREGIVING_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_SERVICES_GOALS' then  secured_value else null end) as CLIENT_CAREGIVING_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_STAGE_CHANGE' then  secured_value else null end) as CLIENT_CAREGIVING_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CAREGIVING_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_CAREGIVING_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_FRIENDS_FAM' then  secured_value else null end) as CLIENT_CHLD_CARE_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_RISK_LEVEL' then  secured_value else null end) as CLIENT_CHLD_CARE_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_SERVICES_GOALS' then  secured_value else null end) as CLIENT_CHLD_CARE_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_STAGE_CHANGE' then  secured_value else null end) as CLIENT_CHLD_CARE_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_CARE_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_CHLD_CARE_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_FRIENDS_FAM' then  secured_value else null end) as CLIENT_CHLD_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_RISK_LEVEL' then  secured_value else null end) as CLIENT_CHLD_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_SERVICES_GOALS' then  secured_value else null end) as CLIENT_CHLD_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_STAGE_CHANGE' then  secured_value else null end) as CLIENT_CHLD_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_FRIENDS_FAM' then  secured_value else null end) as CLIENT_CHLD_WELL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_RISK_LEVEL' then  secured_value else null end) as CLIENT_CHLD_WELL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_SERVICES_GOALS' then  secured_value else null end) as CLIENT_CHLD_WELL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_STAGE_CHANGE' then  secured_value else null end) as CLIENT_CHLD_WELL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CHLD_WELL_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_CHLD_WELL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_FRIENDS_FAM' then  secured_value else null end) as CLIENT_COMM_SVCS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_RISK_LEVEL' then  secured_value else null end) as CLIENT_COMM_SVCS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_SERVICES_GOALS' then  secured_value else null end) as CLIENT_COMM_SVCS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_STAGE_CHANGE' then  secured_value else null end) as CLIENT_COMM_SVCS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_COMM_SVCS_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_COMM_SVCS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_FRIENDS_FAM' then  secured_value else null end) as CLIENT_COMPLICATION_ILL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_RISK_LEVEL' then  secured_value else null end) as CLIENT_COMPLICATION_ILL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_SERVICES_GOALS' then  secured_value else null end) as CLIENT_COMPLICATION_ILL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_STAGE_CHANGE' then  secured_value else null end) as CLIENT_COMPLICATION_ILL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_FRIENDS_FAM' then  secured_value else null end) as CLIENT_CRIMINAL_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_RISK_LEVEL' then  secured_value else null end) as CLIENT_CRIMINAL_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_SERVICES_GOALS' then  secured_value else null end) as CLIENT_CRIMINAL_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_STAGE_CHANGE' then  secured_value else null end) as CLIENT_CRIMINAL_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_CRIMINAL_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_CRIMINAL_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_DISABILITY_FRIENDS_FAM' then  secured_value else null end) as CLIENT_DISABILITY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_DISABILITY_RISK_LEVEL' then  secured_value else null end) as CLIENT_DISABILITY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_DISABILITY_SERVICES_GOALS' then  secured_value else null end) as CLIENT_DISABILITY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_DISABILITY_STAGE_CHANGE' then  secured_value else null end) as CLIENT_DISABILITY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_DISABILITY_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_DISABILITY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_FRIENDS_FAM' then  secured_value else null end) as CLIENT_ECONOMIC_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_RISK_LEVEL' then  secured_value else null end) as CLIENT_ECONOMIC_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_SERVICES_GOALS' then  secured_value else null end) as CLIENT_ECONOMIC_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_STAGE_CHANGE' then  secured_value else null end) as CLIENT_ECONOMIC_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ECONOMIC_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_ECONOMIC_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_EDUC_FRIENDS_FAM' then  secured_value else null end) as CLIENT_EDUC_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_EDUC_RISK_LEVEL' then  secured_value else null end) as CLIENT_EDUC_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_EDUC_SERVICES_GOALS' then  secured_value else null end) as CLIENT_EDUC_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_EDUC_STAGE_CHANGE' then  secured_value else null end) as CLIENT_EDUC_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_EDUC_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_EDUC_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ENGLIT_FRIENDS_FAM' then  secured_value else null end) as CLIENT_ENGLIT_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ENGLIT_RISK_LEVEL' then  secured_value else null end) as CLIENT_ENGLIT_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ENGLIT_SERVICES_GOALS' then  secured_value else null end) as CLIENT_ENGLIT_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ENGLIT_STAGE_CHANGE' then  secured_value else null end) as CLIENT_ENGLIT_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ENGLIT_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_ENGLIT_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_FRIENDS_FAM' then  secured_value else null end) as CLIENT_ENVIRO_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_RISK_LEVEL' then  secured_value else null end) as CLIENT_ENVIRO_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_SERVICES_GOALS' then  secured_value else null end) as CLIENT_ENVIRO_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_STAGE_CHANGE' then  secured_value else null end) as CLIENT_ENVIRO_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_GLOBAL_FACTORS' then  secured_value else null end) as CLIENT_GLOBAL_FACTORS,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_FRIENDS_FAM' then  secured_value else null end) as CLIENT_HLTH_SVCS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_RISK_LEVEL' then  secured_value else null end) as CLIENT_HLTH_SVCS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_SERVICES_GOALS' then  secured_value else null end) as CLIENT_HLTH_SVCS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_STAGE_CHANGE' then  secured_value else null end) as CLIENT_HLTH_SVCS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HLTH_SVCS_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_HLTH_SVCS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_FRIENDS_FAM' then  secured_value else null end) as CLIENT_HOME_SAFETY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_RISK_LEVEL' then  secured_value else null end) as CLIENT_HOME_SAFETY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_SERVICES_GOALS' then  secured_value else null end) as CLIENT_HOME_SAFETY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_STAGE_CHANGE' then  secured_value else null end) as CLIENT_HOME_SAFETY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HOME_SAFETY_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_HOME_SAFETY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_HOMELESS_FRIENDS_FAM' then  secured_value else null end) as CLIENT_HOMELESS_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_HOMELESS_RISK_LEVEL' then  secured_value else null end) as CLIENT_HOMELESS_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_HOMELESS_SERVICES_GOALS' then  secured_value else null end) as CLIENT_HOMELESS_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_HOMELESS_STAGE_CHANGE' then  secured_value else null end) as CLIENT_HOMELESS_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_HOMELESS_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_HOMELESS_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_IPV_FRIENDS_FAM' then  secured_value else null end) as CLIENT_IPV_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_IPV_RISK_LEVEL' then  secured_value else null end) as CLIENT_IPV_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_IPV_SERVICES_GOALS' then  secured_value else null end) as CLIENT_IPV_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_IPV_STAGE_CHANGE' then  secured_value else null end) as CLIENT_IPV_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_IPV_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_IPV_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_LONELY_FRIENDS_FAM' then  secured_value else null end) as CLIENT_LONELY_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_LONELY_RISK_LEVEL' then  secured_value else null end) as CLIENT_LONELY_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_LONELY_SERVICES_GOALS' then  secured_value else null end) as CLIENT_LONELY_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_LONELY_STAGE_CHANGE' then  secured_value else null end) as CLIENT_LONELY_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_LONELY_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_LONELY_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_FRIENDS_FAM' then  secured_value else null end) as CLIENT_MENTAL_HEALTH_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_RISK_LEVEL' then  secured_value else null end) as CLIENT_MENTAL_HEALTH_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_SERVICES_GOALS' then  secured_value else null end) as CLIENT_MENTAL_HEALTH_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_STAGE_CHANGE' then  secured_value else null end) as CLIENT_MENTAL_HEALTH_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_FRIENDS_FAM' then  secured_value else null end) as CLIENT_PREGPLAN_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_RISK_LEVEL' then  secured_value else null end) as CLIENT_PREGPLAN_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_SERVICES_GOALS' then  secured_value else null end) as CLIENT_PREGPLAN_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_STAGE_CHANGE' then  secured_value else null end) as CLIENT_PREGPLAN_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_PREGPLAN_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_PREGPLAN_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_FRIENDS_FAM' then  secured_value else null end) as CLIENT_SUBSTANCE_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_RISK_LEVEL' then  secured_value else null end) as CLIENT_SUBSTANCE_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_SERVICES_GOALS' then  secured_value else null end) as CLIENT_SUBSTANCE_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_STAGE_CHANGE' then  secured_value else null end) as CLIENT_SUBSTANCE_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_SUBSTANCE_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_SUBSTANCE_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_FRIENDS_FAM' then  secured_value else null end) as CLIENT_UNSAFE_NTWK_FRIENDS_FAM,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_RISK_LEVEL' then  secured_value else null end) as CLIENT_UNSAFE_NTWK_RISK_LEVEL,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_SERVICES_GOALS' then  secured_value else null end) as CLIENT_UNSAFE_NTWK_SERVICES_GOALS,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_STAGE_CHANGE' then  secured_value else null end) as CLIENT_UNSAFE_NTWK_STAGE_CHANGE,
max(case sq.pseudonym when 'CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK' then  secured_value else null end) as CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('STAR Framework',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Supplemental_Discharge_Information
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
CLIENT_DISCHARGE_0_REASON varchar(256),
CLIENT_DISCHARGE_1_INCARCERATION_DATE varchar(256),
CLIENT_DISCHARGE_1_INFANTDEATH_DATE varchar(256),
CLIENT_DISCHARGE_1_INFANTDEATH_REASON varchar(256),
CLIENT_DISCHARGE_1_LOST_CUSTODY varchar(256),
CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE varchar(256),
CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE varchar(256),
CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON varchar(256),
CLIENT_DISCHARGE_1_MISCARRIED_DATE varchar(256),
CLIENT_DISCHARGE_1_MISCARRIED_DATE2 varchar(256),
CLIENT_DISCHARGE_1_UNABLE_REASON varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_0_REASON' then  secured_value else null end) as CLIENT_DISCHARGE_0_REASON,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_INCARCERATION_DATE' then  secured_value else null end) as CLIENT_DISCHARGE_1_INCARCERATION_DATE,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_INFANTDEATH_DATE' then  secured_value else null end) as CLIENT_DISCHARGE_1_INFANTDEATH_DATE,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_INFANTDEATH_REASON' then  secured_value else null end) as CLIENT_DISCHARGE_1_INFANTDEATH_REASON,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_LOST_CUSTODY' then  secured_value else null end) as CLIENT_DISCHARGE_1_LOST_CUSTODY,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE' then  secured_value else null end) as CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE' then  secured_value else null end) as CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON' then  secured_value else null end) as CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MISCARRIED_DATE' then  secured_value else null end) as CLIENT_DISCHARGE_1_MISCARRIED_DATE,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MISCARRIED_DATE2' then  secured_value else null end) as CLIENT_DISCHARGE_1_MISCARRIED_DATE2,
max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_UNABLE_REASON' then  secured_value else null end) as CLIENT_DISCHARGE_1_UNABLE_REASON,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Supplemental Discharge Information',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_TCM_Finance_Log
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
LA_CTY_CASE_MGR_ID varchar(256),
LA_CTY_COMPONENT_CODE_FINANCE varchar(256),
LA_CTY_CONSENT_FINANCE varchar(256),
LA_CTY_DEMOGRAPHIC_FINANCE varchar(256),
LA_CTY_ENCOUNTER_FINANCE varchar(256),
LA_CTY_LOCATION_FINANCE varchar(256),
LA_CTY_MEDI_CAL varchar(256),
LA_CTY_MEDI_CAL_STATUS_FINANCE varchar(256),
LA_CTY_NPI varchar(256),
LA_CTY_PROG_NAME varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'LA_CTY_CASE_MGR_ID' then  secured_value else null end) as LA_CTY_CASE_MGR_ID,
max(case sq.pseudonym when 'LA_CTY_COMPONENT_CODE_FINANCE' then  secured_value else null end) as LA_CTY_COMPONENT_CODE_FINANCE,
max(case sq.pseudonym when 'LA_CTY_CONSENT_FINANCE' then  secured_value else null end) as LA_CTY_CONSENT_FINANCE,
max(case sq.pseudonym when 'LA_CTY_DEMOGRAPHIC_FINANCE' then  secured_value else null end) as LA_CTY_DEMOGRAPHIC_FINANCE,
max(case sq.pseudonym when 'LA_CTY_ENCOUNTER_FINANCE' then  secured_value else null end) as LA_CTY_ENCOUNTER_FINANCE,
max(case sq.pseudonym when 'LA_CTY_LOCATION_FINANCE' then  secured_value else null end) as LA_CTY_LOCATION_FINANCE,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL' then  secured_value else null end) as LA_CTY_MEDI_CAL,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL_STATUS_FINANCE' then  secured_value else null end) as LA_CTY_MEDI_CAL_STATUS_FINANCE,
max(case sq.pseudonym when 'LA_CTY_NPI' then  secured_value else null end) as LA_CTY_NPI,
max(case sq.pseudonym when 'LA_CTY_PROG_NAME' then  secured_value else null end) as LA_CTY_PROG_NAME,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('TCM Finance Log',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_TCM_ISP
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
LA_CTY_AGENCY_ADDRESS_ISP varchar(256),
LA_CTY_AGENCY_NAME_ISP varchar(256),
LA_CTY_AGENCY_PH_ISP varchar(256),
LA_CTY_AREAS_ASSESD_ISP varchar(256),
LA_CTY_CASE_MGR_ID varchar(256),
LA_CTY_CLI_AGREE_DATE_ISP varchar(256),
LA_CTY_CLI_AGREE_ISP varchar(256),
LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_COMM_LIV_NEEDS_ISP varchar(256),
LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_ENVIRON_NEEDS_ISP varchar(256),
LA_CTY_FREQ_DUR_ISP varchar(256),
LA_CTY_FU_PREV_REF_ISP varchar(256),
LA_CTY_GOAL_NOT_MET_REASON_ISP varchar(256),
LA_CTY_LOC_SEC_DOC_ISP varchar(256),
LA_CTY_MED_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_MED_NEEDS_ISP varchar(256),
LA_CTY_MEDI_CAL varchar(256),
LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_MENTAL_NEEDS_ISP varchar(256),
LA_CTY_NPI varchar(256),
LA_CTY_PHN_SIG_DATE_ISP varchar(256),
LA_CTY_PHN_SIG_ISP varchar(256),
LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_PHYSICAL_NEEDS_ISP varchar(256),
LA_CTY_PREV_REF_DATE_ISP varchar(256),
LA_CTY_PROG_NAME varchar(256),
LA_CTY_REF_FU_COMPLETE_DATE_ISP varchar(256),
LA_CTY_REF_FU_DUE_DATE_ISP varchar(256),
LA_CTY_REF_FU_OUTCOME_ISP varchar(256),
LA_CTY_SIG_INTERVAL_ISP varchar(256),
LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_SOCIAL_NEEDS_ISP varchar(256),
LA_CTY_SRVC_COMP_ISP varchar(256),
LA_CTY_SRVC_DATE_ISP varchar(256),
LA_CTY_SUP_SIG_DATE_ISP varchar(256),
LA_CTY_SUP_SIG_ISP varchar(256),
LA_CTY_TARGET_POP_ISP varchar(256),
LA_CTY_TARGET_POP_RISK_21_ISP varchar(256),
LA_CTY_TARGET_POP_RISK_NEG_ISP varchar(256),
LA_CTY_VISIT_LOCATION_ISP varchar(256),
LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP varchar(256),
LA_CTY_VOC_ED_NEEDS_ISP varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'LA_CTY_AGENCY_ADDRESS_ISP' then  secured_value else null end) as LA_CTY_AGENCY_ADDRESS_ISP,
max(case sq.pseudonym when 'LA_CTY_AGENCY_NAME_ISP' then  secured_value else null end) as LA_CTY_AGENCY_NAME_ISP,
max(case sq.pseudonym when 'LA_CTY_AGENCY_PH_ISP' then  secured_value else null end) as LA_CTY_AGENCY_PH_ISP,
max(case sq.pseudonym when 'LA_CTY_AREAS_ASSESD_ISP' then  secured_value else null end) as LA_CTY_AREAS_ASSESD_ISP,
max(case sq.pseudonym when 'LA_CTY_CASE_MGR_ID' then  secured_value else null end) as LA_CTY_CASE_MGR_ID,
max(case sq.pseudonym when 'LA_CTY_CLI_AGREE_DATE_ISP' then  secured_value else null end) as LA_CTY_CLI_AGREE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_CLI_AGREE_ISP' then  secured_value else null end) as LA_CTY_CLI_AGREE_ISP,
max(case sq.pseudonym when 'LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_COMM_LIV_NEEDS_ISP' then  secured_value else null end) as LA_CTY_COMM_LIV_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_ENVIRON_NEEDS_ISP' then  secured_value else null end) as LA_CTY_ENVIRON_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_FREQ_DUR_ISP' then  secured_value else null end) as LA_CTY_FREQ_DUR_ISP,
max(case sq.pseudonym when 'LA_CTY_FU_PREV_REF_ISP' then  secured_value else null end) as LA_CTY_FU_PREV_REF_ISP,
max(case sq.pseudonym when 'LA_CTY_GOAL_NOT_MET_REASON_ISP' then  secured_value else null end) as LA_CTY_GOAL_NOT_MET_REASON_ISP,
max(case sq.pseudonym when 'LA_CTY_LOC_SEC_DOC_ISP' then  secured_value else null end) as LA_CTY_LOC_SEC_DOC_ISP,
max(case sq.pseudonym when 'LA_CTY_MED_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_MED_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_MED_NEEDS_ISP' then  secured_value else null end) as LA_CTY_MED_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL' then  secured_value else null end) as LA_CTY_MEDI_CAL,
max(case sq.pseudonym when 'LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_MENTAL_NEEDS_ISP' then  secured_value else null end) as LA_CTY_MENTAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_NPI' then  secured_value else null end) as LA_CTY_NPI,
max(case sq.pseudonym when 'LA_CTY_PHN_SIG_DATE_ISP' then  secured_value else null end) as LA_CTY_PHN_SIG_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_PHN_SIG_ISP' then  secured_value else null end) as LA_CTY_PHN_SIG_ISP,
max(case sq.pseudonym when 'LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_PHYSICAL_NEEDS_ISP' then  secured_value else null end) as LA_CTY_PHYSICAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_PREV_REF_DATE_ISP' then  secured_value else null end) as LA_CTY_PREV_REF_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_PROG_NAME' then  secured_value else null end) as LA_CTY_PROG_NAME,
max(case sq.pseudonym when 'LA_CTY_REF_FU_COMPLETE_DATE_ISP' then  secured_value else null end) as LA_CTY_REF_FU_COMPLETE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_REF_FU_DUE_DATE_ISP' then  secured_value else null end) as LA_CTY_REF_FU_DUE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_REF_FU_OUTCOME_ISP' then  secured_value else null end) as LA_CTY_REF_FU_OUTCOME_ISP,
max(case sq.pseudonym when 'LA_CTY_SIG_INTERVAL_ISP' then  secured_value else null end) as LA_CTY_SIG_INTERVAL_ISP,
max(case sq.pseudonym when 'LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_SOCIAL_NEEDS_ISP' then  secured_value else null end) as LA_CTY_SOCIAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_SRVC_COMP_ISP' then  secured_value else null end) as LA_CTY_SRVC_COMP_ISP,
max(case sq.pseudonym when 'LA_CTY_SRVC_DATE_ISP' then  secured_value else null end) as LA_CTY_SRVC_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_SUP_SIG_DATE_ISP' then  secured_value else null end) as LA_CTY_SUP_SIG_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_SUP_SIG_ISP' then  secured_value else null end) as LA_CTY_SUP_SIG_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_ISP' then  secured_value else null end) as LA_CTY_TARGET_POP_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_RISK_21_ISP' then  secured_value else null end) as LA_CTY_TARGET_POP_RISK_21_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_RISK_NEG_ISP' then  secured_value else null end) as LA_CTY_TARGET_POP_RISK_NEG_ISP,
max(case sq.pseudonym when 'LA_CTY_VISIT_LOCATION_ISP' then  secured_value else null end) as LA_CTY_VISIT_LOCATION_ISP,
max(case sq.pseudonym when 'LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP' then  secured_value else null end) as LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_VOC_ED_NEEDS_ISP' then  secured_value else null end) as LA_CTY_VOC_ED_NEEDS_ISP,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('TCM ISP',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Telehealth_Form
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
CLIENT_TELEHEALTH_REASON varchar(256),
CLIENT_TELEHEALTH_REASON_OTHER varchar(256),
CLIENT_TELEHEALTH_TYPE varchar(256),
CLIENT_TELEHEALTH_TYPE_OTHER varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON' then  secured_value else null end) as CLIENT_TELEHEALTH_REASON,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON_OTHER' then  secured_value else null end) as CLIENT_TELEHEALTH_REASON_OTHER,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE' then  secured_value else null end) as CLIENT_TELEHEALTH_TYPE,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE_OTHER' then  secured_value else null end) as CLIENT_TELEHEALTH_TYPE_OTHER,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Telehealth Form',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Telehealth_Pilot_Form
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
CLIENT_TELEHEALTH_REASON varchar(256),
CLIENT_TELEHEALTH_REASON_OTHER varchar(256),
CLIENT_TELEHEALTH_TYPE varchar(256),
CLIENT_TELEHEALTH_TYPE_OTHER varchar(256),
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON' then  secured_value else null end) as CLIENT_TELEHEALTH_REASON,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_REASON_OTHER' then  secured_value else null end) as CLIENT_TELEHEALTH_REASON_OTHER,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE' then  secured_value else null end) as CLIENT_TELEHEALTH_TYPE,
max(case sq.pseudonym when 'CLIENT_TELEHEALTH_TYPE_OTHER' then  secured_value else null end) as CLIENT_TELEHEALTH_TYPE_OTHER,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



     from survey_views.f_secure_fact_survey_response('Telehealth Pilot Form',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_TEST_CASE_ASSESSMENT
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
	NFP_NSP_6000 varchar(256)

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
	max(case sq.pseudonym when 'NFP_NSP_6000' then  secured_value else null end) as NFP_NSP_6000



     from survey_views.f_secure_fact_survey_response('TEST CASE ASSESSMENT',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_TX_THV_Supplemental_Data_Form
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
MIECHV_BIRTH_SPACING_SIX_MO_PP varchar(256),
MIECHV_BIRTH_SPACING_THIRD_TRI varchar(256),
MIECHV_INTAKE_COMM_REF varchar(256),
MIECHV_PFS_CHILD_DEV_12_12MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_12_2MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_13_12MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_13_2MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_14_12MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_14_2MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_15_12MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_15_2MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_16_12MO_PP varchar(256),
MIECHV_PFS_CHILD_DEV_16_2MO_PP varchar(256),
MIECHV_PFS_CONCRETE_12MO_PP varchar(256),
MIECHV_PFS_CONCRETE_INTAKE varchar(256),
MIECHV_PFS_FAMILY_12MO_PP varchar(256),
MIECHV_PFS_FAMILY_INTAKE varchar(256),
MIECHV_PFS_NURTURE_12MO_PP varchar(256),
MIECHV_PFS_NURTURE_2MO_PP varchar(256),
MIECHV_PFS_SOCIAL_12MO_PP varchar(256),
MIECHV_PFS_SOCIAL_INTAKE varchar(256),
MIECHV_READ_12MO_PP_1 varchar(256),
MIECHV_READ_12MO_PP_2 varchar(256),
MIECHV_READ_12MO_PP_3 varchar(256),
MIECHV_READ_2MO_PP_1 varchar(256),
MIECHV_READ_2MO_PP_2 varchar(256),
MIECHV_READ_2MO_PP_3 varchar(256),
MIECHV_READ_IID_12MO_PP_1 varchar(256),
MIECHV_READ_IID_12MO_PP_2 varchar(256),
MIECHV_READ_IID_12MO_PP_3 varchar(256),
MIECHV_READ_IID_2MO_PP_1 varchar(256),
MIECHV_READ_IID_2MO_PP_2 varchar(256),
MIECHV_READ_IID_2MO_PP_3 varchar(256),
MIECHV_SUPPORTED_BY_INCOME_12MO_PP varchar(256),
MIECHV_SUPPORTED_BY_INCOME_INTAKE varchar(256),
NURSE_PERSONAL_0_NAME varchar(256),
TX_FUNDING_SOURCE_12MO_PP varchar(256),
TX_FUNDING_SOURCE_2MO_PP varchar(256),
TX_FUNDING_SOURCE_6MO_PP varchar(256),
TX_FUNDING_SOURCE_INTAKE varchar(256),
TX_FUNDING_SOURCE_THIRD_TRI varchar(256)

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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MIECHV_BIRTH_SPACING_SIX_MO_PP' then  secured_value else null end) as MIECHV_BIRTH_SPACING_SIX_MO_PP,
max(case sq.pseudonym when 'MIECHV_BIRTH_SPACING_THIRD_TRI' then  secured_value else null end) as MIECHV_BIRTH_SPACING_THIRD_TRI,
max(case sq.pseudonym when 'MIECHV_INTAKE_COMM_REF' then  secured_value else null end) as MIECHV_INTAKE_COMM_REF,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_12_12MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_12_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_12_2MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_12_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_13_12MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_13_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_13_2MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_13_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_14_12MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_14_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_14_2MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_14_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_15_12MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_15_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_15_2MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_15_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_16_12MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_16_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_16_2MO_PP' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_16_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CONCRETE_12MO_PP' then  secured_value else null end) as MIECHV_PFS_CONCRETE_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_CONCRETE_INTAKE' then  secured_value else null end) as MIECHV_PFS_CONCRETE_INTAKE,
max(case sq.pseudonym when 'MIECHV_PFS_FAMILY_12MO_PP' then  secured_value else null end) as MIECHV_PFS_FAMILY_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_FAMILY_INTAKE' then  secured_value else null end) as MIECHV_PFS_FAMILY_INTAKE,
max(case sq.pseudonym when 'MIECHV_PFS_NURTURE_12MO_PP' then  secured_value else null end) as MIECHV_PFS_NURTURE_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_NURTURE_2MO_PP' then  secured_value else null end) as MIECHV_PFS_NURTURE_2MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_SOCIAL_12MO_PP' then  secured_value else null end) as MIECHV_PFS_SOCIAL_12MO_PP,
max(case sq.pseudonym when 'MIECHV_PFS_SOCIAL_INTAKE' then  secured_value else null end) as MIECHV_PFS_SOCIAL_INTAKE,
max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_1' then  secured_value else null end) as MIECHV_READ_12MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_2' then  secured_value else null end) as MIECHV_READ_12MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_3' then  secured_value else null end) as MIECHV_READ_12MO_PP_3,
max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_1' then  secured_value else null end) as MIECHV_READ_2MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_2' then  secured_value else null end) as MIECHV_READ_2MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_3' then  secured_value else null end) as MIECHV_READ_2MO_PP_3,
max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_1' then  secured_value else null end) as MIECHV_READ_IID_12MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_2' then  secured_value else null end) as MIECHV_READ_IID_12MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_3' then  secured_value else null end) as MIECHV_READ_IID_12MO_PP_3,
max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_1' then  secured_value else null end) as MIECHV_READ_IID_2MO_PP_1,
max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_2' then  secured_value else null end) as MIECHV_READ_IID_2MO_PP_2,
max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_3' then  secured_value else null end) as MIECHV_READ_IID_2MO_PP_3,
max(case sq.pseudonym when 'MIECHV_SUPPORTED_BY_INCOME_12MO_PP' then  secured_value else null end) as MIECHV_SUPPORTED_BY_INCOME_12MO_PP,
max(case sq.pseudonym when 'MIECHV_SUPPORTED_BY_INCOME_INTAKE' then  secured_value else null end) as MIECHV_SUPPORTED_BY_INCOME_INTAKE,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_12MO_PP' then  secured_value else null end) as TX_FUNDING_SOURCE_12MO_PP,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_2MO_PP' then  secured_value else null end) as TX_FUNDING_SOURCE_2MO_PP,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_6MO_PP' then  secured_value else null end) as TX_FUNDING_SOURCE_6MO_PP,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_INTAKE' then  secured_value else null end) as TX_FUNDING_SOURCE_INTAKE,
max(case sq.pseudonym when 'TX_FUNDING_SOURCE_THIRD_TRI' then  secured_value else null end) as TX_FUNDING_SOURCE_THIRD_TRI



     from survey_views.f_secure_fact_survey_response('TX_THV Supplemental Data Form',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Unknown
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
	GHP_Client_DOB varchar(256),
GHP_Client_FName varchar(256),
GHP_Client_LName varchar(256),
GHP_Client_PlanEnd varchar(256),
GHP_Client_PlanStart varchar(256),
GHP_Infant_DOB varchar(256),
GHP_Infant_FName varchar(256),
GHP_Infant_LName varchar(256),
GHP_Infant_PlanEnd varchar(256),
GHP_Infant_PlanStart varchar(256),
HSH_Client_DOB varchar(256),
HSH_Client_FName varchar(256),
HSH_Client_LName varchar(256),
HSH_Client_PlanEnd varchar(256),
HSH_Client_PlanStart varchar(256),
HSH_Infant_DOB varchar(256),
HSH_Infant_FName varchar(256),
HSH_Infant_LName varchar(256),
HSH_Infant_PlanEnd varchar(256),
HSH_Infant_PlanStart varchar(256),
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
NEW_HIRE_1_NAME_FIRST varchar(256),
NEW_HIRE_1_ROLE varchar(256),
NEW_HIRE_ADDRESS_0_ZIP varchar(256),
NEW_HIRE_ADDRESS_1_CITY varchar(256),
NEW_HIRE_ADDRESS_1_STATE varchar(256),
NEW_HIRE_ADDRESS_1_STREET varchar(256),
NEW_HIRE_SUP_0_EMAIL varchar(256),
NEW_HIRE_SUP_0_NAME varchar(256),
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
	max(case sq.pseudonym when 'GHP_Client_DOB' then  secured_value else null end) as GHP_Client_DOB,
max(case sq.pseudonym when 'GHP_Client_FName' then  secured_value else null end) as GHP_Client_FName,
max(case sq.pseudonym when 'GHP_Client_LName' then  secured_value else null end) as GHP_Client_LName,
max(case sq.pseudonym when 'GHP_Client_PlanEnd' then  secured_value else null end) as GHP_Client_PlanEnd,
max(case sq.pseudonym when 'GHP_Client_PlanStart' then  secured_value else null end) as GHP_Client_PlanStart,
max(case sq.pseudonym when 'GHP_Infant_DOB' then  secured_value else null end) as GHP_Infant_DOB,
max(case sq.pseudonym when 'GHP_Infant_FName' then  secured_value else null end) as GHP_Infant_FName,
max(case sq.pseudonym when 'GHP_Infant_LName' then  secured_value else null end) as GHP_Infant_LName,
max(case sq.pseudonym when 'GHP_Infant_PlanEnd' then  secured_value else null end) as GHP_Infant_PlanEnd,
max(case sq.pseudonym when 'GHP_Infant_PlanStart' then  secured_value else null end) as GHP_Infant_PlanStart,
max(case sq.pseudonym when 'HSH_Client_DOB' then  secured_value else null end) as HSH_Client_DOB,
max(case sq.pseudonym when 'HSH_Client_FName' then  secured_value else null end) as HSH_Client_FName,
max(case sq.pseudonym when 'HSH_Client_LName' then  secured_value else null end) as HSH_Client_LName,
max(case sq.pseudonym when 'HSH_Client_PlanEnd' then  secured_value else null end) as HSH_Client_PlanEnd,
max(case sq.pseudonym when 'HSH_Client_PlanStart' then  secured_value else null end) as HSH_Client_PlanStart,
max(case sq.pseudonym when 'HSH_Infant_DOB' then  secured_value else null end) as HSH_Infant_DOB,
max(case sq.pseudonym when 'HSH_Infant_FName' then  secured_value else null end) as HSH_Infant_FName,
max(case sq.pseudonym when 'HSH_Infant_LName' then  secured_value else null end) as HSH_Infant_LName,
max(case sq.pseudonym when 'HSH_Infant_PlanEnd' then  secured_value else null end) as HSH_Infant_PlanEnd,
max(case sq.pseudonym when 'HSH_Infant_PlanStart' then  secured_value else null end) as HSH_Infant_PlanStart,
max(case sq.pseudonym when 'NEW_HIRE_0_ACCESS_LEVEL' then  secured_value else null end) as NEW_HIRE_0_ACCESS_LEVEL,
max(case sq.pseudonym when 'NEW_HIRE_0_EDUC_COMPLETED' then  secured_value else null end) as NEW_HIRE_0_EDUC_COMPLETED,
max(case sq.pseudonym when 'NEW_HIRE_0_EMAIL' then  secured_value else null end) as NEW_HIRE_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_0_FTE' then  secured_value else null end) as NEW_HIRE_0_FTE,
max(case sq.pseudonym when 'NEW_HIRE_0_HIRE_DATE' then  secured_value else null end) as NEW_HIRE_0_HIRE_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_NAME_LAST' then  secured_value else null end) as NEW_HIRE_0_NAME_LAST,
max(case sq.pseudonym when 'NEW_HIRE_0_PHONE' then  secured_value else null end) as NEW_HIRE_0_PHONE,
max(case sq.pseudonym when 'NEW_HIRE_0_PREVIOUS_NFP_WORK' then  secured_value else null end) as NEW_HIRE_0_PREVIOUS_NFP_WORK,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_FOR_HIRE_REPLACE' then  secured_value else null end) as NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
max(case sq.pseudonym when 'NEW_HIRE_0_REASON_NFP_WORK_DESC' then  secured_value else null end) as NEW_HIRE_0_REASON_NFP_WORK_DESC,
max(case sq.pseudonym when 'NEW_HIRE_0_START_DATE' then  secured_value else null end) as NEW_HIRE_0_START_DATE,
max(case sq.pseudonym when 'NEW_HIRE_0_TEAM_NAME' then  secured_value else null end) as NEW_HIRE_0_TEAM_NAME,
max(case sq.pseudonym when 'NEW_HIRE_1_NAME_FIRST' then  secured_value else null end) as NEW_HIRE_1_NAME_FIRST,
max(case sq.pseudonym when 'NEW_HIRE_1_ROLE' then  secured_value else null end) as NEW_HIRE_1_ROLE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_0_ZIP' then  secured_value else null end) as NEW_HIRE_ADDRESS_0_ZIP,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_CITY' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_CITY,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STATE' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STATE,
max(case sq.pseudonym when 'NEW_HIRE_ADDRESS_1_STREET' then  secured_value else null end) as NEW_HIRE_ADDRESS_1_STREET,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_EMAIL' then  secured_value else null end) as NEW_HIRE_SUP_0_EMAIL,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_NAME' then  secured_value else null end) as NEW_HIRE_SUP_0_NAME,
max(case sq.pseudonym when 'NEW_HIRE_SUP_0_PHONE' then  secured_value else null end) as NEW_HIRE_SUP_0_PHONE



     from survey_views.f_secure_fact_survey_response('Unknown',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Use_Of_Government_&_Community_Services
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
JP error - if no data associated delete element varchar(256),
NURSE_PERSONAL_0_NAME varchar(256),
SERVICE_USE_0_ADOPTION_CLIENT varchar(256),
SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT varchar(256),
SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT varchar(256),
SERVICE_USE_0_CHARITY_CLIENT varchar(256),
SERVICE_USE_0_CHILD_CARE_CLIENT varchar(256),
SERVICE_USE_0_CHILD_OTHER1 varchar(256),
SERVICE_USE_0_CHILD_OTHER2 varchar(256),
SERVICE_USE_0_CHILD_OTHER3 varchar(256),
SERVICE_USE_0_CHILD_SUPPORT_CLIENT varchar(256),
SERVICE_USE_0_CPS_CHILD varchar(256),
SERVICE_USE_0_CPS_CLIENT varchar(256),
SERVICE_USE_0_DENTAL_CHILD varchar(256),
SERVICE_USE_0_DENTAL_CLIENT varchar(256),
SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT varchar(256),
SERVICE_USE_0_DRUG_ABUSE_CLIENT varchar(256),
SERVICE_USE_0_FOODSTAMP_CLIENT varchar(256),
SERVICE_USE_0_GED_CLIENT varchar(256),
SERVICE_USE_0_HIGHER_EDUC_CLIENT varchar(256),
SERVICE_USE_0_HOUSING_CLIENT varchar(256),
SERVICE_USE_0_INTERVENTION varchar(256),
SERVICE_USE_0_INTERVENTION_45DAYS varchar(256),
SERVICE_USE_0_IPV_CLIENT varchar(256),
SERVICE_USE_0_JOB_TRAINING_CLIENT varchar(256),
SERVICE_USE_0_LACTATION_CLIENT varchar(256),
SERVICE_USE_0_LEGAL_CLIENT varchar(256),
SERVICE_USE_0_MEDICAID_CHILD varchar(256),
SERVICE_USE_0_MEDICAID_CLIENT varchar(256),
SERVICE_USE_0_MENTAL_CLIENT varchar(256),
SERVICE_USE_0_OTHER1 varchar(256),
SERVICE_USE_0_OTHER1_DESC varchar(256),
SERVICE_USE_0_OTHER2 varchar(256),
SERVICE_USE_0_OTHER2_DESC varchar(256),
SERVICE_USE_0_OTHER3 varchar(256),
SERVICE_USE_0_OTHER3_DESC varchar(256),
SERVICE_USE_0_PATERNITY_CLIENT varchar(256),
SERVICE_USE_0_PCP_CLIENT varchar(256),
SERVICE_USE_0_PCP_SICK_CHILD varchar(256),
SERVICE_USE_0_PCP_WELL_CHILD varchar(256),
SERVICE_USE_0_PCP_WELL_CLIENT varchar(256),
SERVICE_USE_0_PREVENT_INJURY_CLIENT varchar(256),
SERVICE_USE_0_PRIVATE_INSURANCE_CHILD varchar(256),
SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT varchar(256),
SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT varchar(256),
SERVICE_USE_0_SCHIP_CHILD varchar(256),
SERVICE_USE_0_SCHIP_CLIENT varchar(256),
SERVICE_USE_0_SMOKE_CLIENT varchar(256),
SERVICE_USE_0_SOCIAL_SECURITY_CLIENT varchar(256),
SERVICE_USE_0_SPECIAL_NEEDS_CHILD varchar(256),
SERVICE_USE_0_SPECIAL_NEEDS_CLIENT varchar(256),
SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT varchar(256),
SERVICE_USE_0_TANF_CLIENT varchar(256),
SERVICE_USE_0_TRANSPORTATION_CLIENT varchar(256),
SERVICE_USE_0_UNEMPLOYMENT_CLIENT varchar(256),
SERVICE_USE_0_WIC_CLIENT varchar(256),
SERVICE_USE_INDIAN_HEALTH_CHILD varchar(256),
SERVICE_USE_INDIAN_HEALTH_CLIENT varchar(256),
SERVICE_USE_MILITARY_INS_CHILD varchar(256),
SERVICE_USE_MILITARY_INS_CLIENT varchar(256),
SERVICE_USE_PCP_CLIENT_POSTPARTUM varchar(256),
SERVICE_USE_PCP_CLIENT_PRENATAL varchar(256),
SERVICE_USE_PCP_CLIENT_WELLWOMAN varchar(256)

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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
max(case sq.pseudonym when 'CLIENT_0_ID_NSO' then  secured_value else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'JP error - if no data associated delete element' then  secured_value else null end) as JP error - if no data associated delete element,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'SERVICE_USE_0_ADOPTION_CLIENT' then  secured_value else null end) as SERVICE_USE_0_ADOPTION_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT' then  secured_value else null end) as SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT' then  secured_value else null end) as SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_CHARITY_CLIENT' then  secured_value else null end) as SERVICE_USE_0_CHARITY_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_CARE_CLIENT' then  secured_value else null end) as SERVICE_USE_0_CHILD_CARE_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER1' then  secured_value else null end) as SERVICE_USE_0_CHILD_OTHER1,
max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER2' then  secured_value else null end) as SERVICE_USE_0_CHILD_OTHER2,
max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER3' then  secured_value else null end) as SERVICE_USE_0_CHILD_OTHER3,
max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_SUPPORT_CLIENT' then  secured_value else null end) as SERVICE_USE_0_CHILD_SUPPORT_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CHILD' then  secured_value else null end) as SERVICE_USE_0_CPS_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CLIENT' then  secured_value else null end) as SERVICE_USE_0_CPS_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CHILD' then  secured_value else null end) as SERVICE_USE_0_DENTAL_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CLIENT' then  secured_value else null end) as SERVICE_USE_0_DENTAL_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT' then  secured_value else null end) as SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_DRUG_ABUSE_CLIENT' then  secured_value else null end) as SERVICE_USE_0_DRUG_ABUSE_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_FOODSTAMP_CLIENT' then  secured_value else null end) as SERVICE_USE_0_FOODSTAMP_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_GED_CLIENT' then  secured_value else null end) as SERVICE_USE_0_GED_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_HIGHER_EDUC_CLIENT' then  secured_value else null end) as SERVICE_USE_0_HIGHER_EDUC_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_HOUSING_CLIENT' then  secured_value else null end) as SERVICE_USE_0_HOUSING_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION' then  secured_value else null end) as SERVICE_USE_0_INTERVENTION,
max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION_45DAYS' then  secured_value else null end) as SERVICE_USE_0_INTERVENTION_45DAYS,
max(case sq.pseudonym when 'SERVICE_USE_0_IPV_CLIENT' then  secured_value else null end) as SERVICE_USE_0_IPV_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_JOB_TRAINING_CLIENT' then  secured_value else null end) as SERVICE_USE_0_JOB_TRAINING_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_LACTATION_CLIENT' then  secured_value else null end) as SERVICE_USE_0_LACTATION_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_LEGAL_CLIENT' then  secured_value else null end) as SERVICE_USE_0_LEGAL_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CHILD' then  secured_value else null end) as SERVICE_USE_0_MEDICAID_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CLIENT' then  secured_value else null end) as SERVICE_USE_0_MEDICAID_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_MENTAL_CLIENT' then  secured_value else null end) as SERVICE_USE_0_MENTAL_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1' then  secured_value else null end) as SERVICE_USE_0_OTHER1,
max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1_DESC' then  secured_value else null end) as SERVICE_USE_0_OTHER1_DESC,
max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2' then  secured_value else null end) as SERVICE_USE_0_OTHER2,
max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2_DESC' then  secured_value else null end) as SERVICE_USE_0_OTHER2_DESC,
max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3' then  secured_value else null end) as SERVICE_USE_0_OTHER3,
max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3_DESC' then  secured_value else null end) as SERVICE_USE_0_OTHER3_DESC,
max(case sq.pseudonym when 'SERVICE_USE_0_PATERNITY_CLIENT' then  secured_value else null end) as SERVICE_USE_0_PATERNITY_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_PCP_CLIENT' then  secured_value else null end) as SERVICE_USE_0_PCP_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_PCP_SICK_CHILD' then  secured_value else null end) as SERVICE_USE_0_PCP_SICK_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CHILD' then  secured_value else null end) as SERVICE_USE_0_PCP_WELL_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CLIENT' then  secured_value else null end) as SERVICE_USE_0_PCP_WELL_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_PREVENT_INJURY_CLIENT' then  secured_value else null end) as SERVICE_USE_0_PREVENT_INJURY_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CHILD' then  secured_value else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT' then  secured_value else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT' then  secured_value else null end) as SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CHILD' then  secured_value else null end) as SERVICE_USE_0_SCHIP_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CLIENT' then  secured_value else null end) as SERVICE_USE_0_SCHIP_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_SMOKE_CLIENT' then  secured_value else null end) as SERVICE_USE_0_SMOKE_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_SOCIAL_SECURITY_CLIENT' then  secured_value else null end) as SERVICE_USE_0_SOCIAL_SECURITY_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CHILD' then  secured_value else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CLIENT' then  secured_value else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT' then  secured_value else null end) as SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_TANF_CLIENT' then  secured_value else null end) as SERVICE_USE_0_TANF_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_TRANSPORTATION_CLIENT' then  secured_value else null end) as SERVICE_USE_0_TRANSPORTATION_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_UNEMPLOYMENT_CLIENT' then  secured_value else null end) as SERVICE_USE_0_UNEMPLOYMENT_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_0_WIC_CLIENT' then  secured_value else null end) as SERVICE_USE_0_WIC_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CHILD' then  secured_value else null end) as SERVICE_USE_INDIAN_HEALTH_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CLIENT' then  secured_value else null end) as SERVICE_USE_INDIAN_HEALTH_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CHILD' then  secured_value else null end) as SERVICE_USE_MILITARY_INS_CHILD,
max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CLIENT' then  secured_value else null end) as SERVICE_USE_MILITARY_INS_CLIENT,
max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_POSTPARTUM' then  secured_value else null end) as SERVICE_USE_PCP_CLIENT_POSTPARTUM,
max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_PRENATAL' then  secured_value else null end) as SERVICE_USE_PCP_CLIENT_PRENATAL,
max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_WELLWOMAN' then  secured_value else null end) as SERVICE_USE_PCP_CLIENT_WELLWOMAN



     from survey_views.f_secure_fact_survey_response('Use Of Government & Community Services',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_WA_MIECHV_Supplemental_HVEF
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
	CLIENT_O_ID_NSO varchar(256),
CLIENT_PERSONAL_O_DOB_INTAKE varchar(256),
CLIENT_PERSONAL_O_NAME_FIRST varchar(256),
CLIENT_PERSONAL_O_NAME_LAST varchar(256),
NURSE_PERSONAL_0_NAME varchar(256),
WA_HVEF_SUPPLEMENT_DELAYED_PREG varchar(256),
WA_HVEF_SUPPLEMENT_IPV varchar(256)

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
	max(case sq.pseudonym when 'CLIENT_O_ID_NSO' then  secured_value else null end) as CLIENT_O_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_O_DOB_INTAKE' then  secured_value else null end) as CLIENT_PERSONAL_O_DOB_INTAKE,
max(case sq.pseudonym when 'CLIENT_PERSONAL_O_NAME_FIRST' then  secured_value else null end) as CLIENT_PERSONAL_O_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_O_NAME_LAST' then  secured_value else null end) as CLIENT_PERSONAL_O_NAME_LAST,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'WA_HVEF_SUPPLEMENT_DELAYED_PREG' then  secured_value else null end) as WA_HVEF_SUPPLEMENT_DELAYED_PREG,
max(case sq.pseudonym when 'WA_HVEF_SUPPLEMENT_IPV' then  secured_value else null end) as WA_HVEF_SUPPLEMENT_IPV



     from survey_views.f_secure_fact_survey_response('WA MIECHV Supplemental HVEF',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

create function survey_views.f_select_Weekly_Supervision_Record
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
	NURSE_PERSONAL_0_NAME varchar(256),
NURSE_SUPERVISION_0_MIN varchar(256),
NURSE_SUPERVISION_0_STAFF_OTHER varchar(256),
NURSE_SUPERVISION_0_STAFF_SUP varchar(256)

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
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
max(case sq.pseudonym when 'NURSE_SUPERVISION_0_MIN' then  secured_value else null end) as NURSE_SUPERVISION_0_MIN,
max(case sq.pseudonym when 'NURSE_SUPERVISION_0_STAFF_OTHER' then  secured_value else null end) as NURSE_SUPERVISION_0_STAFF_OTHER,
max(case sq.pseudonym when 'NURSE_SUPERVISION_0_STAFF_SUP' then  secured_value else null end) as NURSE_SUPERVISION_0_STAFF_SUP



     from survey_views.f_secure_fact_survey_response('Weekly Supervision Record',@p_requested_security_policy,@p_export_profile_id) fr    
   
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

Go

