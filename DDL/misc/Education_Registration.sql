create procedure [survey_views].usp_etl_select_Education_Registration  
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
vbase.EDUC_REGISTER_0_REASON
--vbase.First_Confirmation_Sent,
--vbase.First_Confirmation_Sent_By,
--vbase.Second_Confirmation_Sent,
--vbase.Second_Confirmation_Sent_By,
--vbase.Third_Confirmation_Sent,
--vbase.Third_Confirmation_Sent_By,
--vbase.Materials_Shipped,
--vbase.Materials_Shipped_By,
--vbase.Disposition,
--vbase.Disposition_Text,
--vbase.Comments,
--vbase.ClassName,
--vbase.LMS_ClassID,
--vbase.LMS_CourseID,
--vbase.ClassName_Changed_To,
--vbase.Invoice_Nbr,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.Master_SurveyID

from survey_views.f_select_Education_Registration(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


