USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_TX_THV_Supplemental_Data_Form]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_TX_THV_Supplemental_Data_Form]
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'MIECHV_BIRTH_SPACING_SIX_MO_PP ' then  secured_value else null end) as MIECHV_BIRTH_SPACING_SIX_MO_PP,
	max(case sq.pseudonym when 'MIECHV_BIRTH_SPACING_THIRD_TRI ' then  secured_value else null end) as MIECHV_BIRTH_SPACING_THIRD_TRI,
	max(case sq.pseudonym when 'MIECHV_INTAKE_COMM_REF ' then  secured_value else null end) as MIECHV_INTAKE_COMM_REF,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_12_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_12_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_12_2MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_12_2MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_13_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_13_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_13_2MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_13_2MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_14_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_14_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_14_2MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_14_2MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_15_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_15_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_15_2MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_15_2MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_16_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_16_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CHILD_DEV_16_2MO_PP ' then  secured_value else null end) as MIECHV_PFS_CHILD_DEV_16_2MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CONCRETE_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_CONCRETE_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_CONCRETE_INTAKE ' then  secured_value else null end) as MIECHV_PFS_CONCRETE_INTAKE,
	max(case sq.pseudonym when 'MIECHV_PFS_FAMILY_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_FAMILY_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_FAMILY_INTAKE ' then  secured_value else null end) as MIECHV_PFS_FAMILY_INTAKE,
	max(case sq.pseudonym when 'MIECHV_PFS_NURTURE_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_NURTURE_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_NURTURE_2MO_PP ' then  secured_value else null end) as MIECHV_PFS_NURTURE_2MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_SOCIAL_12MO_PP ' then  secured_value else null end) as MIECHV_PFS_SOCIAL_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_PFS_SOCIAL_INTAKE ' then  secured_value else null end) as MIECHV_PFS_SOCIAL_INTAKE,
	max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_1 ' then  secured_value else null end) as MIECHV_READ_12MO_PP_1,
	max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_2 ' then  secured_value else null end) as MIECHV_READ_12MO_PP_2,
	max(case sq.pseudonym when 'MIECHV_READ_12MO_PP_3 ' then  secured_value else null end) as MIECHV_READ_12MO_PP_3,
	max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_1 ' then  secured_value else null end) as MIECHV_READ_2MO_PP_1,
	max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_2 ' then  secured_value else null end) as MIECHV_READ_2MO_PP_2,
	max(case sq.pseudonym when 'MIECHV_READ_2MO_PP_3 ' then  secured_value else null end) as MIECHV_READ_2MO_PP_3,
	max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_1 ' then  secured_value else null end) as MIECHV_READ_IID_12MO_PP_1,
	max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_2 ' then  secured_value else null end) as MIECHV_READ_IID_12MO_PP_2,
	max(case sq.pseudonym when 'MIECHV_READ_IID_12MO_PP_3 ' then  secured_value else null end) as MIECHV_READ_IID_12MO_PP_3,
	max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_1 ' then  secured_value else null end) as MIECHV_READ_IID_2MO_PP_1,
	max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_2 ' then  secured_value else null end) as MIECHV_READ_IID_2MO_PP_2,
	max(case sq.pseudonym when 'MIECHV_READ_IID_2MO_PP_3 ' then  secured_value else null end) as MIECHV_READ_IID_2MO_PP_3,
	max(case sq.pseudonym when 'MIECHV_SUPPORTED_BY_INCOME_12MO_PP ' then  secured_value else null end) as MIECHV_SUPPORTED_BY_INCOME_12MO_PP,
	max(case sq.pseudonym when 'MIECHV_SUPPORTED_BY_INCOME_INTAKE ' then  secured_value else null end) as MIECHV_SUPPORTED_BY_INCOME_INTAKE,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'TX_FUNDING_SOURCE_12MO_PP ' then  secured_value else null end) as TX_FUNDING_SOURCE_12MO_PP,
	max(case sq.pseudonym when 'TX_FUNDING_SOURCE_2MO_PP ' then  secured_value else null end) as TX_FUNDING_SOURCE_2MO_PP,
	max(case sq.pseudonym when 'TX_FUNDING_SOURCE_6MO_PP ' then  secured_value else null end) as TX_FUNDING_SOURCE_6MO_PP,
	max(case sq.pseudonym when 'TX_FUNDING_SOURCE_INTAKE ' then  secured_value else null end) as TX_FUNDING_SOURCE_INTAKE,
	max(case sq.pseudonym when 'TX_FUNDING_SOURCE_THIRD_TRI ' then  secured_value else null end) as TX_FUNDING_SOURCE_THIRD_TRI

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


GO
