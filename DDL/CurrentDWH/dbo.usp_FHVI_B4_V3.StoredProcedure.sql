USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B4_V3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B4_V3]
	-- Add the parameters for the stored procedure here
	@Site VARCHAR(50),@Quarter INT, @QuarterYear INT,@ReportType INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
DECLARE @QuarterDate VARCHAR(50) 
SET @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 

SET NOCOUNT ON;
WITH FHVI AS 
(
	SELECT 

		EAD.CaseNumber--,EAD.EndDate
		,PAS.ProgramName
		,PAS.ProgramID
		,PAS.Site
		,PAS.SiteID
		,DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) State
		,MAX(IBS.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]
		,CFS.[CLIENT_FUNDING_1_END_OTHER]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		,CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
		,CFS.[CLIENT_FUNDING_1_START_OTHER]
		,MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE
		,EDD.EDD
		,ISNULL(CASE
			WHEN MAX(ISNULL(EDD.EDD,GETDATE())) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
						AND MIN(EAD.ProgramStartDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END,0) [Pregnancy Intake Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
					WHEN 40 + DATEDIFF(DAY,EDD.EDD,CAST(@QuarterDate AS DATE))/7 >= 36
						AND DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID) <=30
						AND (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL 
						OR (MAX(IBS.INFANT_BIRTH_0_DOB) > = @QuarterStart 
							AND MAX(IBS.INFANT_BIRTH_1_GEST_AGE) > = 36))
					THEN 1
				 END,0)
		 ELSE 0 END [36 Weeks Preg Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(MAX(CASE WHEN (IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate THEN 1 END),0) 
			ELSE 0 END [Birth]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					--AND DATEDIFF(WEEK,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 1 AND 15.9
					AND DATEADD(DAY,61,MAX(IBS.INFANT_BIRTH_0_DOB)) BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 
		 END,0) 
		 ELSE 0 END [1 - 8 Weeks Infancy Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 4 AND 6
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Infancy 4 - 6 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 6 AND 11.9
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Infancy 6 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 12 AND 17.9 
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Infancy 12 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 18 AND 23.9
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Toddler 18 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) >=24
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Toddler 24 Months Y/N]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
				--AND DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) <> 'NJ'
				THEN 1
		 END),0) [Competitive]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
				--OR DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) = 'NJ'
				THEN 1
		 END),0) [Formula]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL] IS NOT NULL
				--OR DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) = 'NJ'
				THEN 1
		 END),0) Tribal
		,ISNULL(MAX(CASE 
			WHEN MHS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Maternal Health Assessment Y/N]
		
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Pregnancy Intake Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Infancy 12 Months Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
				THEN 1
		 END),0) [Client Child Injury Prevention Training Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL 
				OR AES.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Home Visit Encounter Y/N]
		,ISNULL(MAX(CASE
				WHEN RSS.SERVICE_REFER_0_IPV LIKE '%Client%'
				THEN 1
		 END),0)[Domestic Violence Referral]
		,ISNULL(MAX(CASE
				WHEN (
						(
							CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' 
							OR (
									CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'None' 
									AND  CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME IS NOT NULL
								) 
							OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
						)
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					 ) 
					OR (
							(
								CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
								OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes'
								OR (
										CLIENT_ABUSE_TIMES_0_HURT_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HURT_LAST_YR IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER IS NOT NULL
									)
								OR CLIENT_ABUSE_FORCED_0_SEX  = 'Yes'
								OR (
										CLIENT_ABUSE_FORCED_1_SEX_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_FORCED_1_SEX_LAST_YR IS NOT NULL
									)
								OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
							)
							AND (
									dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
									OR dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
								)
						)
				THEN 1
		 END),0) [Domestic Violence Identified]
,ISNULL(MAX(CASE
				WHEN ((
						(
							CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' 
							OR (
									CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'None' 
									AND  CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME IS NOT NULL
								) 
							OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
						)
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					 ) 
					OR (
							(
								CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
								OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes'
								OR (
										CLIENT_ABUSE_TIMES_0_HURT_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HURT_LAST_YR IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER IS NOT NULL
									)
								OR CLIENT_ABUSE_FORCED_0_SEX  = 'Yes'
								OR (
										CLIENT_ABUSE_FORCED_1_SEX_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_FORCED_1_SEX_LAST_YR IS NOT NULL
									)
								OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
							)
							AND (
									dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
									OR dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
								)
						))
					AND RSS.SERVICE_REFER_0_IPV LIKE '%Client%'
					AND RSS.SurveyDate > = RS.SurveyDate
				THEN 1
		 END),0) [IPV Referral - IPV Identified]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_IPV_0_SAFETY_PLAN = 'Yes'
				THEN 1
		 END),0) [Safety Plan discussed]
,ISNULL(MAX(CASE
				WHEN ((
						(
							CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' 
							OR (
									CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'None' 
									AND  CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME IS NOT NULL
								) 
							OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
						)
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					 ) 
					OR (
							(
								CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
								OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes'
								OR (
										CLIENT_ABUSE_TIMES_0_HURT_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HURT_LAST_YR IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER IS NOT NULL
									)
								OR CLIENT_ABUSE_FORCED_0_SEX  = 'Yes'
								OR (
										CLIENT_ABUSE_FORCED_1_SEX_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_FORCED_1_SEX_LAST_YR IS NOT NULL
									)
								OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
							)
							AND (
									dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
									OR dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
								)
						))
					AND HVES.CLIENT_IPV_0_SAFETY_PLAN = 'Yes'
					AND HVES.SurveyDate > = RS.SurveyDate
				THEN 1
		 END),0) [Safety Plan Discussed - IPV Identified]
		,ISNULL(MAX(CASE
				WHEN RSS.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Families screened for need]
		 ,1 [Families in NFP]
		,ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						 AND (
								CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
								OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
								OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							 )
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END
			),0) [Active During Quarter]
		,PAS.StateID

FROM DataWarehouse..EnrollmentAndDismissal EAD
		INNER JOIN [DataWarehouse].[dbo].[Client_Funding_Survey] CFS
			ON CFS.CL_EN_GEN_ID = EAD.CLID
			AND CFS.ProgramID = EAD.ProgramID
			AND (
					CFS.CLIENT_FUNDING_1_START_MIECHVP_COM BETWEEN '10/1/2010' AND @QuarterDate
					OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM BETWEEN '10/1/2010' AND @QuarterDate
					OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL BETWEEN '10/1/2010' AND @QuarterDate
				)	
		INNER JOIN DataWarehouse..Clients C
			ON C.Client_Id = EAD.CLID
			AND C.Last_Name <> 'Fake'
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_CFS
		--	ON MS_CFS.SurveyID = CFS.SurveyID
		--	AND dbo.fngetFormName(CFS.SurveyID) NOT LIKE '%MASTER%'
		LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
			ON MHS.CL_EN_GEN_ID = EAD.CLID
			AND MHS.SurveyDate < = @QuarterDate
		
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			
		LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
			ON MS_IHS.SurveyID = IHS.SurveyID
		
		LEFT JOIN DataWarehouse..Relationship_Survey RS
			ON RS.CL_EN_GEN_ID = EAD.CLID
			AND RS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_RS
		--	ON MS_RS.SurveyID = RS.SurveyID
		LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
			ON HVES.CL_EN_GEN_ID = EAD.CLID
			AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			AND HVES.CLIENT_COMPLETE_0_VISIT NOT LIKE '%CANC%'
		LEFT JOIN DataWarehouse..Alternative_Encounter_Survey AES
			ON AES.CL_EN_GEN_ID = EAD.CLID
			AND AES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Referrals_to_Services_Survey RSS
			ON RSS.CL_EN_GEN_ID = EAD.CLID
			AND RSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		INNER JOIN DataWarehouse..UV_PAS PAS
			ON PAS.ProgramID = EAD.ProgramID
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DataWarehouse..UV_EDD EDD
			ON EDD.CaseNumber = EAD.CaseNumber

	WHERE CASE
			WHEN @ReportType = 1
			THEN '1'
			WHEN @ReportType = 2
			THEN DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
			WHEN @ReportType = 3
			THEN CAST(PAS.SiteID AS VARCHAR(50))
			WHEN @ReportType = 4
			THEN CAST(PAS.ProgramID AS VARCHAR(50))
		 END IN (CAST(@Site AS VARCHAR(50)))

	GROUP BY
		EAD.CaseNumber
		,PAS.ProgramName
		,PAS.ProgramID
		,PAS.Site
		,PAS.SiteID
		,DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_END_OTHER]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_START_OTHER]
		,MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE
		,EDD.EDD
		,DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID)
		,CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
		,CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
		,PAS.StateID

)

SELECT
	F.CaseNumber
	,F.Site,F.ProgramName,F.State
	,F.[Active During Quarter] Active
	,CASE
		WHEN F.Formula > 0 THEN 2
		WHEN F.Competitive > 0 THEN 1
		WHEN F.Tribal > 0 THEN 3
	 END FundingType
	,CASE
		WHEN F.Formula > 0 THEN 'Formula'
		WHEN F.Competitive > 0 THEN 'Competitive'
		WHEN F.Tribal > 0 THEN 'Tribal'
	 END FundingDescription
	,CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN F.Stateid
		WHEN @ReportType = 3 THEN F.SiteID
		WHEN @ReportType = 4 THEN F.ProgramID
	 END [ReportGrouping]
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Active During Quarter] > 0
		THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END,0) NC_42
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Active During Quarter] > 0
		THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END,0) NF_42
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Active During Quarter] > 0 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END,0) NFC_42
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Active During Quarter] > 0 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END,0) NN_42
	,ISNULL(CASE WHEN F.[Active During Quarter] > 0 THEN F.[Domestic Violence Screening Y/N] END,0) NT_42
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Active During Quarter] 
		ELSE 0
	END,0) DC_42
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DF_42
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  THEN F.[Active During Quarter]
		ELSE 0
	END,0) DFC_42
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Active During Quarter]
		ELSE 0
	END,0) DN_42
	,ISNULL(F.[Active During Quarter],0) DT_42
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END,0) NC_42IN
	,ISNULL(CASE
		WHEN F.Formula = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END,0) NF_42IN
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1) ) 
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END,0) NFC_42IN
	,ISNULL(CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1 )
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END,0) NN_42IN
	,ISNULL(CASE
		WHEN F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N] 
		ELSE 0
	END,0) NT_42IN
	,ISNULL(CASE
		WHEN F.Competitive = 1 
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter] 
		ELSE 0
	END,0) DC_42IN
	,ISNULL(CASE
		WHEN  F.Formula = 1 
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DF_42IN
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DFC_42IN
	,ISNULL(CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1 )
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DN_42IN
	,ISNULL(CASE
		WHEN F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0 
	 END,0) DT_42IN
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END,0) NC_4236
	,ISNULL(CASE
		WHEN F.Formula = 1 
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END,0) NF_4236
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1) ) 
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END,0) NFC_4236
	,ISNULL(CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1 )
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END,0) NN_4236
	,ISNULL(CASE
		WHEN F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N] 
		ELSE 0
	END,0) NT_4236
	,ISNULL(CASE
		WHEN F.Competitive = 1 
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter] 
		ELSE 0
	END,0) DC_4236
	,ISNULL(CASE
		WHEN  F.Formula = 1 
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DF_4236
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DFC_4236
	,ISNULL(CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1 )
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DN_4236
	,ISNULL(CASE
		WHEN F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0 
	 END,0) DT_4236
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END,0) NC_4212
	,ISNULL(CASE
		WHEN F.Formula = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END,0) NF_4212
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1) ) 
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END,0) NFC_4212
	,ISNULL(CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1 )
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END,0) NN_4212
	,ISNULL(CASE
		WHEN F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N] 
		ELSE 0
	END,0) NT_4212
	,ISNULL(CASE
		WHEN F.Competitive = 1 
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter] 
		ELSE 0
	END,0) DC_4212
	,ISNULL(CASE
		WHEN  F.Formula = 1 
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DF_4212
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DFC_4212
	,ISNULL(CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1 )
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END,0) DN_4212
	,ISNULL(CASE
		WHEN F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0 
	 END,0) DT_4212
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Domestic Violence Identified] > 0
		THEN F.[Domestic Violence Referral]
		ELSE 0
	END,0) NC_43
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Domestic Violence Identified] > 0
		THEN F.[Domestic Violence Referral]
		ELSE 0
	END,0) NF_43
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Domestic Violence Identified] > 0 THEN F.[Domestic Violence Referral]
		ELSE 0
	END,0) NFC_43
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Domestic Violence Identified] > 0 THEN F.[Domestic Violence Referral]
		ELSE 0
	END,0) NN_43
	,ISNULL(CASE WHEN F.[Domestic Violence Identified] > 0 THEN F.[Domestic Violence Referral] END,0) NT_43
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Domestic Violence Identified] 
		ELSE 0
	END,0) DC_43
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DF_43
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DFC_43
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DN_43
	,ISNULL(F.[Domestic Violence Identified],0) DT_43
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Domestic Violence Identified] > 0
		THEN F.[IPV Referral - IPV Identified]
		ELSE 0
	END,0) NC_43IPVI
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Domestic Violence Identified] > 0
		THEN F.[IPV Referral - IPV Identified]
		ELSE 0
	END,0) NF_43IPVI
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Domestic Violence Identified] > 0 THEN F.[IPV Referral - IPV Identified]
		ELSE 0
	END,0) NFC_43IPVI
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Domestic Violence Identified] > 0 THEN F.[IPV Referral - IPV Identified]
		ELSE 0
	END,0) NN_43IPVI
	,ISNULL(CASE WHEN F.[Domestic Violence Identified] > 0 THEN F.[IPV Referral - IPV Identified] END,0) NT_43IPVI
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Domestic Violence Identified] 
		ELSE 0
	END,0) DC_43IPVI
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DF_43IPVI
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DFC_43IPVI
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DN_43IPVI
	,ISNULL(F.[Domestic Violence Identified],0) DT_43IPVI
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Safety Plan discussed] > 0
		THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) NC_44
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Safety Plan discussed] > 0
		THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) NF_44
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Safety Plan discussed] > 0 THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) NFC_44
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Safety Plan discussed] > 0 THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) NN_44
	,ISNULL(CASE WHEN F.[Safety Plan discussed] > 0 THEN F.[Safety Plan discussed] END,0) NT_44
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Safety Plan discussed] 
		ELSE 0
	END,0) DC_44
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) DF_44
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) DFC_44
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Safety Plan discussed]
		ELSE 0
	END,0) DN_44
	,ISNULL(F.[Safety Plan discussed],0) DT_44
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Domestic Violence Identified] > 0
		THEN F.[Safety Plan Discussed - IPV Identified]
		ELSE 0
	END,0) NC_44IPVI
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Domestic Violence Identified] > 0
		THEN F.[Safety Plan Discussed - IPV Identified]
		ELSE 0
	END,0) NF_44IPVI
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Domestic Violence Identified] > 0 THEN F.[Safety Plan Discussed - IPV Identified]
		ELSE 0
	END,0) NFC_44IPVI
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Domestic Violence Identified] > 0 THEN F.[Safety Plan Discussed - IPV Identified]
		ELSE 0
	END,0) NN_44IPVI
	,ISNULL(CASE WHEN F.[Domestic Violence Identified] > 0 THEN F.[Safety Plan Discussed - IPV Identified] END,0) NT_44IPVI
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Domestic Violence Identified] 
		ELSE 0
	END,0) DC_44IPVI
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DF_44IPVI
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DFC_44IPVI
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Domestic Violence Identified]
		ELSE 0
	END,0) DN_44IPVI
	,ISNULL(F.[Domestic Violence Identified],0) DT_44IPVI


FROM FHVI F


--OPTION(RECOMPILE)

END

GO
