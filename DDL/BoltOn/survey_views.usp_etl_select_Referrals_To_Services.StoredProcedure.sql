USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Referrals_To_Services]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Referrals_To_Services]  
(
 @p_export_profile_id int,
  @p_entity_filter char(5)=null,
  @p_etl_session_token varchar(50)=null
)
as
begin


set nocount on;
declare		@_rec_count int;
declare		@_my_name varchar(256);
set			@_my_name = OBJECT_NAME(@@PROCID);


declare  @_hash_profile   char(10);


set   @_hash_profile   = (select top 1 isnull('SA',hash_policy) from survey_views.f_get_survey_etl_work() where ExportProfileID=@p_export_profile_id);

begin transaction


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
	vbase.SERVICE_REFER_0_TANF,
	vbase.SERVICE_REFER_0_FOODSTAMP,
	vbase.SERVICE_REFER_0_SOCIAL_SECURITY,
	vbase.SERVICE_REFER_0_UNEMPLOYMENT,
	vbase.SERVICE_REFER_0_SUBSID_CHILD_CARE,
	vbase.SERVICE_REFER_0_IPV,
	vbase.SERVICE_REFER_0_CPS,
	vbase.SERVICE_REFER_0_MENTAL,
	vbase.SERVICE_REFER_0_RELATIONSHIP_COUNSELING,
	vbase.SERVICE_REFER_0_SMOKE,
	vbase.SERVICE_REFER_0_ALCOHOL_ABUSE,
	vbase.SERVICE_REFER_0_MEDICAID,
	vbase.SERVICE_REFER_0_SCHIP,
	vbase.SERVICE_REFER_0_PRIVATE_INSURANCE,
	vbase.SERVICE_REFER_0_SPECIAL_NEEDS,
	vbase.SERVICE_REFER_0_PCP,
	vbase.SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY,
	vbase.SERVICE_REFER_0_WIC_CLIENT,
	vbase.SERVICE_REFER_0_CHILD_CARE,
	vbase.SERVICE_REFER_0_JOB_TRAINING,
	vbase.SERVICE_REFER_0_HOUSING,
	vbase.SERVICE_REFER_0_TRANSPORTATION,
	vbase.SERVICE_REFER_0_PREVENT_INJURY,
	vbase.SERVICE_REFER_0_BIRTH_EDUC_CLASS,
	vbase.SERVICE_REFER_0_LACTATION,
	vbase.SERVICE_REFER_0_GED,
	vbase.SERVICE_REFER_0_HIGHER_EDUC,
	vbase.SERVICE_REFER_0_CHARITY,
	vbase.SERVICE_REFER_0_LEGAL_CLIENT,
	vbase.SERVICE_REFER_0_PATERNITY,
	vbase.SERVICE_REFER_0_CHILD_SUPPORT,
	vbase.SERVICE_REFER_0_ADOPTION,
	vbase.SERIVCE_REFER_0_OTHER1_DESC,
	vbase.SERIVCE_REFER_0_OTHER2_DESC,
	vbase.SERIVCE_REFER_0_OTHER3_DESC,
	vbase.SERVICE_REFER_0_DRUG_ABUSE,
	vbase.SERVICE_REFER_0_OTHER,
	vbase.REFERRALS_TO_0_FORM_TYPE,
	vbase.CLIENT_0_ID_NSO,
	vbase.CLIENT_PERSONAL_0_NAME_FIRST,
	vbase.CLIENT_PERSONAL_0_NAME_LAST,
	vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
	vbase.CLIENT_0_ID_AGENCY,
	vbase.NURSE_PERSONAL_0_NAME,
	vbase.SERVICE_REFER_0_DENTAL,
	vbase.SERVICE_REFER_0_INTERVENTION,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	vbase.SERVICE_REFER_0_PCP_R2,
	vbase.SERVICE_REFER_INDIAN_HEALTH,
	vbase.SERVICE_REFER_MILITARY_INS
	--vbase.Master_SurveyID


	from survey_views.f_select_Referrals_To_Services(@_hash_profile,@p_export_profile_id) vbase

		if @p_etl_session_token is not null
		begin

		declare @_completed datetime=getdate();
		
		insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
		select 
		@p_etl_session_token,
		@_my_name,
		count(responses.SurveyResponseID) as [Count],
		@_completed,
		'Referrals_to_Services_Survey',
		'Referrals_To_Services.txt',
		ep.ExportProfileID,
		ep.ProfileName,
		ee.SiteID,
		ee.AgencyName

		from survey_views.ExportEntities ee 
		 inner join survey_views.f_select_Referrals_To_Services(@_hash_profile,@p_export_profile_id) responses 
													on responses.SiteID=ee.SiteID
		 inner join survey_views.ExportProfile ep	on ee.ExportProfileID=ep.ExportProfileID
		where
			ee.ExportProfileID=@p_export_profile_id
		group by
		ep.ExportProfileID,
		ep.ProfileName,
		ee.AgencyName,
		ee.SiteID;


		end


commit transaction;

 
end;


GO
