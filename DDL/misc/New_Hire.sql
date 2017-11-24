create procedure [survey_views].usp_etl_select_New_Hire  
(
 @p_export_profile_id int,
  @p_entity_filter char(5)=null
)
as
begin

declare  @_hash_profile   char(10);
set   @_hash_profile   = (select top 1 isnull('SA',hash_policy) from survey_views.f_get_survey_etl_work() where ExportProfileID=@p_export_profile_id);

--print  @p_export_profile_id;
--print  @_hash_profile;


select 

vbase. SurveyResponseID,
vbase.ElementsProcessed,
vbase.SurveyID,
vbase.SurveyDate,
vbase.AuditDate,
vbase.CL_EN_GEN_ID,
vbase.SiteID,
vbase.ProgramID,
vbase.IA_StaffID,
vbase.ClientID,
vbase.RespondentID,
--vbase.Validation_Ind,
--vbase.Validation_Comment,
--vbase.Entity_ID_Mapped,
vbase.NEW_HIRE_0_HIRE_DATE,
vbase.NEW_HIRE_1_NAME_FIRST,
vbase.NEW_HIRE_0_NAME_LAST,
vbase.NEW_HIRE_1_ROLE,
vbase.NEW_HIRE_ADDRESS_1_STREET,
vbase.NEW_HIRE_ADDRESS_1_CITY,
vbase.NEW_HIRE_ADDRESS_1_STATE,
vbase.NEW_HIRE_ADDRESS_0_ZIP,
vbase.NEW_HIRE_0_PHONE,
vbase.NEW_HIRE_0_EMAIL,
vbase.NEW_HIRE_SUP_0_PHONE,
vbase.NEW_HIRE_SUP_0_EMAIL,
vbase.NEW_HIRE_0_REASON_FOR_HIRE,
vbase.NEW_HIRE_0_REASON_FOR_HIRE_REPLACE,
vbase.NEW_HIRE_0_FTE,
vbase.NEW_HIRE_0_PREVIOUS_NFP_WORK,
vbase.NEW_HIRE_0_REASON_NFP_WORK_DESC,
vbase.NEW_HIRE_0_EDUC_COMPLETED,
vbase.NEW_HIRE_0_START_DATE,
vbase.NEW_HIRE_SUP_0_NAME,
vbase.NEW_HIRE_0_TEAM_NAME,
vbase.NEW_HIRE_0_ACCESS_LEVEL,
--vbase.DISP_CODE,
--vbase.REVIEWED_BY,
--vbase.REVIEWED_DATE,
--vbase.ADDED_TO_ETO,
--vbase.ADDED_TO_ETO_BY,
--vbase.ETO_LOGIN_EMAILED,
--vbase.ETO_LOGIN_EMAILED_BY,
--vbase.ADDED_TO_CMS,
--vbase.ADDED_TO_CMS_BY,
--vbase.GEN_COMMENTS,
--vbase.CHANGE_STATUS_COMPLETED,
vbase.NEW_HIRE_1_DOB,
vbase.NEW_HIRE_1_PREVIOUS_WORK_AGENCY,
vbase.NEW_HIRE_1_PREVIOUS_WORK_CITY,
vbase.NEW_HIRE_1_PREVIOUS_WORK_DATE1,
vbase.NEW_HIRE_1_PREVIOUS_WORK_DATE2,
vbase.NEW_HIRE_1_PREVIOUS_WORK_NAME,
vbase.NEW_HIRE_1_PREVIOUS_WORK_STATE,
vbase.NEW_HIRE_1_REPLACE_STAFF_TERM,
vbase.NEW_HIRE_ER_0_LNAME,
vbase.NEW_HIRE_ER_1_FNAME,
vbase.NEW_HIRE_ER_1_PHONE,
vbase.NEW_HIRE_ADDRESS_1_STATE_OTHR,
vbase.NEW_HIRE_SUP_0_NAME_OTHR,
--vbase.DW_AuditDate,
--vbase.DataSource,
vbase.NEW_HIRE_ADDITIONAL_INFO
--vbase.Master_SurveyID

from survey_views.f_select_New_Hire_Form(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


