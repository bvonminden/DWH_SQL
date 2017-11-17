USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI]
	-- Add the parameters for the stored procedure here
	@Site INT,@Quarter INT, @QuarterYear INT
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
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-4,CAST(@QuarterDate AS DATE))) 

SET NOCOUNT ON;
WITH FHVI AS 
(
	SELECT 

		EAD.CaseNumber,EADT.EndDate
		,CFS.[SurveyDate]
		,CFS.[AuditDate]
		,EADT.ProgramName
		,EADT.Site
		,MAX(IBS.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
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
		,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD
		,ISNULL(CASE
			WHEN MAX(ISNULL(ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),GETDATE())) > @QuarterStart
			THEN 1
		 END,0) [Pregnancy Intake Y/N]
		,ISNULL(CASE
			WHEN 40 + DATEDIFF(WEEK,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD,CAST(@QuarterDate AS DATE)) >= 36
				AND (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL 
				OR (MAX(IBS.INFANT_BIRTH_0_DOB) > = @QuarterStart 
					AND MAX(IBS.INFANT_BIRTH_1_GEST_AGE) > = 36))
			THEN 1
		 END,0) [36 Weeks Preg Y/N]
		,ISNULL(MAX(CASE WHEN (IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate THEN 1 END),0) [Birth]
		,ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(WEEK,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 1
				THEN 1 
		 END,0) [1 - 8 Weeks Infancy Y/N]
		,ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 4
				THEN 1 
		 END,0) [Infancy 4 - 6 Months Y/N]
		,ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 6 
				THEN 1 
		 END,0) [Infancy 6 Months Y/N]
		,ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 12 
				THEN 1 
		 END,0) [Infancy 12 Months Y/N]
		,ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 18 
				THEN 1 
		 END,0) [Toddler 18 Months Y/N]
		,ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) >=24
				THEN 1 
		 END,0) [Toddler 24 Months Y/N]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
				THEN 1
		 END),0) [Competitive]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
				THEN 1
		 END),0) [Formula]
		,ISNULL(MAX(CASE 
			WHEN MHS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Maternal Health Assessment Y/N]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Demographics Assessment Y/N]
		,ISNULL(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE < = 13
				THEN '1st Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE BETWEEN 13 AND 26
				THEN '2nd Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE > 26 
				THEN '3rd Trimester'
		END,'Blank') Trimester
		,ISNULL(MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT = 'YES' THEN 1
		 END),0) [Prenatal Care Y/N]
		,ISNULL(MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT IS NOT NULL THEN 1
		 END),0) [Answered Prenatal Question]
		,ISNULL(MAX(CASE 
			WHEN HHS.CL_EN_GEN_ID IS NOT NULL THEN 1 
		 END),0) [Health Habits Assessment Y/N]
		,ISNULL(MAX(CASE	
			WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
				AND MS_H.SurveyName LIKE '%Intake%' THEN 1
		 END),0) [Alcohol use at Intake]
		,ISNULL(MAX(CASE	
			WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
			AND MS_H.SurveyName LIKE '%36%' THEN 1
		END),0) [Alcohol use at 36 Weeks]
		,ISNULL(MAX(CASE	
			WHEN HHS.CLIENT_SUBSTANCE_CIG_0_DURING_PREG = 'Yes'
				AND MS_H.SurveyName LIKE '%Intake%' THEN 1
		END),0) [Tobacco use at Intake]
		,ISNULL(MAX(CASE	
			WHEN HHS.CLIENT_SUBSTANCE_CIG_0_DURING_PREG = 'Yes'
				AND MS_H.SurveyName LIKE '%36%' THEN 1
		 END),0) [Tobacco use at 36 Weeks]
		,ISNULL(MAX( 
				CASE	
					WHEN HHS.CLIENT_SUBSTANCE_POT_0_14DAYS + HHS.CLIENT_SUBSTANCE_COCAINE_0_14DAY
						+HHS.CLIENT_SUBSTANCE_OTHER_0_14DAY > 0	AND MS_H.SurveyName LIKE '%Intake%'
						THEN 1
				END
			  ),0) [Illicit Drug use at Intake]
		,ISNULL(MAX( 
				CASE	
					WHEN HHS.CLIENT_SUBSTANCE_POT_0_14DAYS + HHS.CLIENT_SUBSTANCE_COCAINE_0_14DAY
						+ HHS.CLIENT_SUBSTANCE_OTHER_0_14DAY > 0 AND MS_H.SurveyName LIKE '%36%'
						THEN 1
				END
			  ),0) [Illicit Drug use at 36 Weeks]  
		,ISNULL(MAX( 
				CASE 
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND GCSS.SurveyDate < = @QuarterDate
					THEN 1
				END
			  ),0) [Use of Gov't and Comm Svcs Assessment Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
				END
			  ),0) [Pregnancy since 1st child]
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
					AND GCSS.SurveyDate < = @QuarterDate
					THEN 1 
					END
		END),0) [Well Woman Care]
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
					AND MS_G.SurveyName LIKE '%6%'
					THEN 1 
					END
		END),0) [Well Woman Care 6 mos]	
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
					AND MS_G.SurveyName LIKE '%12%'
					THEN 1 
					END
		END),0) [Well Woman Care 12 mos]
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
					AND MS_G.SurveyName LIKE '%18%'
					THEN 1 
					END
		END),0) [Well Woman Care 18 mos]		
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
					AND MS_G.SurveyName LIKE '%24%'
					THEN 1 
					END
		END),0) [Well Woman Care 24 mos]	
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Pregnancy at 6 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Pregnancy at 12 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Pregnancy at 18 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Pregnancy at 24 Mos]
		,ISNULL(MAX(CASE
					WHEN MS_D.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Demographics Update - Infancy 6 Months]
		,ISNULL(MAX(CASE
					WHEN MS_D.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Demographics Update - Infancy 12 Months]
		,ISNULL(MAX( 
				CASE
					WHEN MS_D.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Demographics Update - Infancy 18 Months]
		,ISNULL(MAX( 
				CASE
					WHEN MS_D.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Demographics Update - Infancy 24 Months]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Preg%36%' THEN 1
				END
			  ),0) [Depression Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%1%4%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%4%6%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%12%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN (IBS.INFANT_BREASTMILK_0_EVER_BIRTH = 'Yes'
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH2 = 'Yes'
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH3 = 'Yes'
						) AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at birth]
		,ISNULL(MAX( 
				CASE 
					WHEN (IBS.INFANT_BREASTMILK_0_EVER_BIRTH IS NOT NULL
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH2 IS NOT NULL
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH3 IS NOT NULL
						) AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Breastfeeding question]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
						AND IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%INF%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%INF%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
						AND IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%INF%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%INF%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
						AND IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%TOD%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%TOD%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
						AND IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%TOD%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 24 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_0_EVER_IHC IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%TOD%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Child Health Insurance]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Child Health Ins 6 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Child Health Ins 12 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Child Health Ins 18 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Child Health Ins 24 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Client Health Insurance]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Client Health Ins 6 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Client Health Ins 12 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Client Health Ins 18 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Client Health Ins 24 Mos]
		,CASE ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 12 
				THEN 1 
		 END,0)
		 WHEN 1
		 THEN ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND MS_G.SurveyName LIKE '%INTAKE%'
						THEN 1
				END
			  ),0)
		ELSE 0 END [Child Health Insurance - Intake]
		,CASE ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 12 
				THEN 1 
		 END,0)
		 WHEN 1
		 THEN ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND MS_G.SurveyName LIKE '%INTAKE%'
						THEN 1
				END
			  ),0)
		ELSE 0 END [Client Health Insurance - Intake]
		,CASE ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 12 
				THEN 1 
		 END,0)
		 WHEN 1
		 THEN ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD = 2)
						AND MS_G.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) 
		ELSE 0 END [Child Health Insurance - 12 Mos]
		,CASE ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) > = 12 
				THEN 1 
		 END,0)
		 WHEN 1
		 THEN ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT = 2
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT = 2
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT = 2)
						AND MS_G.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) 
		ELSE 0 END [Client Health Insurance - 12 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%6%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 6 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%12%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 12 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%18%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 18 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%24%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 24 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
				END
			  ),0) [Infant Birth Survey Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL THEN 1
				END
			  ),0) [Infant Health Survey Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Emergency Visists - Injury/Injestion]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
						AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Emergency Visists - Other]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						THEN 1
				END
			  ),0) [Emergency Visists - Client]

		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Injuries requiring treatment]   
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment]
		,ISNULL(MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_LEARNING] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ),0) [Learning Materials Score - 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_LEARNING] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ),0) [Learning Materials Score - 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_Involvement] IS NOT NULL
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ),0) [Involvement Materials Score - 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_Involvement] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ),0) [Involvement Materials Score - 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_0_TOTAL] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ),0) [Total Score - 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_0_TOTAL] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ),0) [Total Score - 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ),0) [Acceptance Score - 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ),0) [Acceptance Score - 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ),0) [Responsivity Score - 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ),0) [Responsivity Score - 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Preg%36%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%1%4%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%4%6%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%12%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 12 mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 24 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 24 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 24 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 24 Mos - Agg]			  
		,ISNULL(MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Weight/Height/Head Measured Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Weight/Height/Head Measured Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Weight/Height/Head Measured Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Weight/Height/Head Measured Screening 24 Mos]

		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ),0) [ASQ Height 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ),0) [ASQ Height 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ),0) [ASQ Height 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ),0) [ASQ Height 24 Mos - Agg]	
			  
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ),0) [ASQ Weight 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ),0) [ASQ Weight 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ),0) [ASQ Weight 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ),0) [ASQ Weight 24 Mos - Agg]
			  
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ),0) [ASQ Head Circ 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ),0) [ASQ Head Circ 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ),0) [ASQ Head Circ 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ),0) [ASQ Head Circ 24 Mos - Agg]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL THEN 1 
				END
			  ),0) [Domestic Violence Screening Y/N]
		,ISNULL(MAX(
				CASE
					WHEN (
							DS.CLIENT_INCOME_0_HH_INCOME IS NOT NULL
							AND DS.CLIENT_INCOME_0_HH_INCOME <> 'Client is dependent on parent/guardian'
						 )
						AND DS.CLIENT_INCOME_1_HH_SOURCES IS NOT NULL
						AND (
								MS_D.SurveyName LIKE '%INTAKE%'
								OR MS_D.SurveyName LIKE '%12%'
							 )
						THEN 1
				END
			  ),0) [Household Income/Source Collected Y/N]
		,ISNULL(MAX(
				CASE
					WHEN (
							DS.ADULTS_1_WORK_10 > 0
							OR DS.ADULTS_1_WORK_20 > 0
							OR DS.ADULTS_1_WORK_37 > 0
							OR DS.ADULTS_1_WORK_LESS10 > 0
						 )
						 AND (
								MS_D.SurveyName LIKE '%INTAKE%'
								OR MS_D.SurveyName LIKE '%12%'
							 )
						 
						THEN 1
				END
			  ),0) [Employment Status of HH Adults]
		,ISNULL(MAX(
				CASE
					WHEN (
							DS.ADULTS_1_ED_ASSOCIATE > 0
							OR DS.ADULTS_1_ED_BACHELOR > 0
							OR DS.ADULTS_1_ED_MASTER > 0
							OR DS.ADULTS_1_ED_POSTGRAD > 0
							OR DS.ADULTS_1_ED_SOME_COLLEGE > 0
							OR DS.ADULTS_1_ED_TECH > 0
							OR DS.ADULTS_1_ED_NONE > 0
							OR DS.ADULTS_1_COMPLETE_HS_NO > 0
							OR DS.ADULTS_1_COMPLETE_HS > 0
							OR DS.ADULTS_1_COMPLETE_GED > 0
							OR DS.ADULTS_1_ENROLL_FT > 0
							OR DS.ADULTS_1_ENROLL_NO> 0
							OR DS.ADULTS_1_ENROLL_PT > 0
						 )
						 AND (
								MS_D.SurveyName LIKE '%INTAKE%'
								OR MS_D.SurveyName LIKE '%12%'
							 )
						 
						THEN 1
				END
			  ),0) [Education Status of HH Adults]	
		,ISNULL(MAX(
				CASE
					WHEN (
							DS.ADULTS_1_INS_NO > 0
							OR DS.ADULTS_1_INS_PRIVATE > 0
							OR DS.ADULTS_1_INS_PUBLIC > 0
						 )
						 AND (
								MS_D.SurveyName LIKE '%INTAKE%'
								OR MS_D.SurveyName LIKE '%12%'
							 )
						 
						THEN 1
				END
			  ),0) [Insurance Status of HH Adults]
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
				WHEN ([CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER] NOT LIKE 'No%' 
						AND  [CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_HIT_0_SLAP_PARTNER] NOT LIKE 'No%' 
						AND  [CLIENT_ABUSE_HIT_0_SLAP_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_HURT_LAST_YR] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_HURT_LAST_YR] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_FORCED_0_SEX] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_FORCED_0_SEX] IS NOT NULL) 
					OR ([CLIENT_ABUSE_FORCED_1_SEX_LAST_YR] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_FORCED_1_SEX_LAST_YR] IS NOT NULL) 
					OR ([CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME] IS NOT NULL) 
					OR ([CLIENT_ABUSE_AFRAID_0_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_AFRAID_0_PARTNER] IS NOT NULL) 
					OR ([ABUSE_EMOTION_0_PHYSICAL_PARTNER] NOT LIKE 'No%'  
						AND  [ABUSE_EMOTION_0_PHYSICAL_PARTNER] IS NOT NULL) 
				THEN 1
		 END),0) [Domestic Violence Identified]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_IPV_0_SAFETY_PLAN = 'Yes'
				THEN 1
		 END),0) [Safety Plan discussed]
		,ISNULL(MAX(CASE
				WHEN RSS.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Families screened for need]
		 ,1 [Families in NFP]
		 ,ISNULL(MAX(CASE
				WHEN  RSS.[SERVICE_REFER_0_TANF] IS NOT NULL
					OR RSS.[REFERRALS_TO_0_FORM_TYPE] IS NOT NULL
					OR RSS.[SERIVCE_REFER_0_OTHER1_DESC] IS NOT NULL
					OR RSS.[SERIVCE_REFER_0_OTHER2_DESC] IS NOT NULL
					OR RSS.[SERIVCE_REFER_0_OTHER3_DESC] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_ADOPTION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_ALCOHOL_ABUSE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CHARITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CHILD_CARE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CHILD_SUPPORT] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CPS] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_DENTAL] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_DRUG_ABUSE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_FOODSTAMP] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_GED] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_HIGHER_EDUC] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_HOUSING] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_INTERVENTION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_IPV] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_JOB_TRAINING] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_LACTATION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_LEGAL_CLIENT] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_MEDICAID] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_MENTAL] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_OTHER] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PATERNITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PCP] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PREVENT_INJURY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PRIVATE_INSURANCE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SCHIP] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SMOKE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SOCIAL_SECURITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SPECIAL_NEEDS] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SUBSID_CHILD_CARE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_TRANSPORTATION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_UNEMPLOYMENT] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_WIC_CLIENT] IS NOT NULL
 				THEN 1
		 END),0) [Received referral]
		 ,ISNULL(MAX(CASE
				WHEN (
						GCSS.[SERVICE_USE_0_ADOPTION_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHARITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_CARE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_OTHER1] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_OTHER2] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_OTHER3] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CPS_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CPS_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DENTAL_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DENTAL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DRUG_ABUSE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_FOODSTAMP_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_GED_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_HIGHER_EDUC_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_HOUSING_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_INTERVENTION] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_IPV_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_JOB_TRAINING_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_LACTATION_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_LEGAL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_MEDICAID_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_MEDICAID_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_MENTAL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_OTHER1] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_OTHER2] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_OTHER3] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PATERNITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_SICK_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_WELL_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PREVENT_INJURY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SCHIP_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SCHIP_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SMOKE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_TANF_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_TRANSPORTATION_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_WIC_CLIENT] IN (2,5) 
					) AND GCSS.SurveyDate < = @QuarterDate
				THEN 1
		 END),0) [Received Services]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_TANF] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_TANF]
,ISNULL(MAX(CASE
    WHEN RSS.[REFERRALS_TO_0_FORM_TYPE] IS NOT NULL     THEN 1
   END),0) [REFERRALS_TO_0_FORM_TYPE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERIVCE_REFER_0_OTHER1_DESC] IS NOT NULL 
		OR RSS.[SERIVCE_REFER_0_OTHER2_DESC] IS NOT NULL  
		OR RSS.[SERIVCE_REFER_0_OTHER3_DESC] IS NOT NULL 
		OR RSS.[SERVICE_REFER_0_OTHER] IS NOT NULL      THEN 1
   END),0) [SERIVCE_REFER_0_OTHER]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_ADOPTION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_ADOPTION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_ALCOHOL_ABUSE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_ALCOHOL_ABUSE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_BIRTH_EDUC_CLASS]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CHARITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CHARITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CHILD_CARE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CHILD_CARE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CHILD_SUPPORT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CHILD_SUPPORT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CPS] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CPS]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_DENTAL] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_DENTAL]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_DRUG_ABUSE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_DRUG_ABUSE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_FOODSTAMP] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_FOODSTAMP]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_GED] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_GED]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_HIGHER_EDUC] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_HIGHER_EDUC]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_HOUSING] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_HOUSING]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_INTERVENTION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_INTERVENTION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_IPV] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_IPV]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_JOB_TRAINING] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_JOB_TRAINING]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_LACTATION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_LACTATION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_LEGAL_CLIENT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_LEGAL_CLIENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_MEDICAID] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_MEDICAID]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_MENTAL] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_MENTAL]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PATERNITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_PATERNITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE '%Child - sick%' 
		OR RSS.[SERVICE_REFER_0_PCP] LIKE '%Child – sick%'     THEN 1
   END),0) [SERVICE_REFER_0_PCP_SICK_CHILD]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE '%Child - well%' 
		OR RSS.[SERVICE_REFER_0_PCP] LIKE '%Child – well%'     THEN 1
   END),0) [SERVICE_REFER_0_PCP_WELL_CHILD]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE 'Client - well%'
		OR RSS.[SERVICE_REFER_0_PCP] LIKE '%CLIENT;%' 
		OR RSS.[SERVICE_REFER_0_PCP] = 'Client' THEN 1
   END),0) [SERVICE_REFER_0_PCP_WELL_CLIENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE 'Client - sick'     THEN 1
   END),0) [SERVICE_REFER_0_PCP_SICK_CLIENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PREVENT_INJURY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_PREVENT_INJURY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PRIVATE_INSURANCE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_PRIVATE_INSURANCE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SCHIP] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SCHIP]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SMOKE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SMOKE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SOCIAL_SECURITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SOCIAL_SECURITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SPECIAL_NEEDS] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SPECIAL_NEEDS]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SUBSID_CHILD_CARE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SUBSID_CHILD_CARE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_TRANSPORTATION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_TRANSPORTATION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_UNEMPLOYMENT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_UNEMPLOYMENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_WIC_CLIENT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_WIC_CLIENT]

,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_ADOPTION_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_ADOPTION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_ALCOHOL_ABUSE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_BIRTH_EDUC_CLASS] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CHARITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_CHARITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CHILD_CARE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_CARE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SUPPORT] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CPS_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CPS_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_CPS] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_DENTAL_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_DENTAL_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_DENTAL] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_DRUG_ABUSE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_DRUG_ABUSE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_FOODSTAMP_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_FOODSTAMP] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_GED_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_GED] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_HIGHER_EDUC_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_HIGHER_EDUC] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_HOUSING_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_HOUSING] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_INTERVENTION]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_INTERVENTION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_IPV_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_IPV] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_JOB_TRAINING_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_JOB_TRAINING] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_LACTATION_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_LACTATION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_LEGAL_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_LEGAL] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_MEDICAID_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_MEDICAID_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_MEDICAID] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_MENTAL_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_MENTAL] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_OTHER1]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CHILD_OTHER1]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_OTHER3]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CHILD_OTHER3]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_OTHER2]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CHILD_OTHER2]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_OTHER1] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PATERNITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_PATERNITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PCP_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_SICK_CLIENT] 
,ISNULL(MAX(CASE
    WHEN  GCSS.[SERVICE_USE_0_PCP_SICK_CHILD]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_SICK_CHILD] 
,ISNULL(MAX(CASE
    WHEN  GCSS.[SERVICE_USE_0_PCP_WELL_CHILD]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_WELL_CHILD] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_WELL_CLIENT] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PREVENT_INJURY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_PREVENT_INJURY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PRIVATE_INSURANCE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SCHIP_CHILD]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SCHIP] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SMOKE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SMOKE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SOCIAL_SECURITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_SPECIAL_NEEDS] 

,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SUBSID_CARE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_TANF_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_TANF] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_TRANSPORTATION_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_TRANSPORTATION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_UNEMPLOYMENT] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_WIC_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_WIC] 


	FROM DataWarehouse..EnrollmentAndDismissal EAD
		LEFT JOIN [DataWarehouse].[dbo].[Client_Funding_Survey] CFS
			ON CFS.CL_EN_GEN_ID = EAD.CLID
			AND CFS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		INNER JOIN DataWarehouse..Clients C
			ON C.Client_Id = EAD.CLID
		LEFT JOIN DataWarehouse..Mstr_surveys MS_CFS
			ON MS_CFS.SurveyID = CFS.SurveyID
			AND MS_CFS.SurveyName NOT LIKE '%MASTER%'
		LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
			ON MHS.CL_EN_GEN_ID = EAD.CLID
			AND MHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Health_Habits_Survey HHS
			ON HHS.CL_EN_GEN_ID = EAD.CLID
			AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_H
			ON MS_H.SurveyID = HHS.SurveyID
		LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GCSS
			ON GCSS.CL_EN_GEN_ID = EAD.CLID
		--	AND GCSS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_G
			ON MS_G.SurveyID = GCSS.SurveyID
		LEFT JOIN DataWarehouse..Demographics_Survey DS
			ON DS.CL_EN_GEN_ID = EAD.CLID
			AND DS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_D
			ON MS_D.SurveyID = DS.SurveyID
		LEFT JOIN DataWarehouse..Edinburgh_Survey ES
			ON ES.CL_EN_GEN_ID = EAD.CLID
			AND ES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_E
			ON MS_E.SurveyID = ES.SurveyID
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			
		LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
			ON MS_IHS.SurveyID = IHS.SurveyID
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS2
			ON IHS2.CL_EN_GEN_ID = EAD.CLID
			AND IHS.SurveyID IN (
									SELECT MS_IHS2.SurveyID
									FROM DataWarehouse..Mstr_surveys MS_IHS2
									WHERE MS_IHS2.SurveyName LIKE '%INFANT%6%'
								)
		LEFT JOIN DataWarehouse..PHQ_Survey PHQ
			ON PHQ.CL_EN_GEN_ID = EAD.CLID
			AND PHQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_PHQ
			ON MS_PHQ.SurveyID = PHQ.SurveyID
		LEFT JOIN DataWarehouse..Relationship_Survey RS
			ON RS.CL_EN_GEN_ID = EAD.CLID
			AND RS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_RS
			ON MS_RS.SurveyID = RS.SurveyID
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
		INNER JOIN (
						SELECT EAD2.EndDate, EAD2.CaseNumber,EAD2.ProgramID,EAD2.ProgramName, EAD2.Site,EAD2.SiteID,EAD2.AGENCY_INFO_0_NAME,EAD2.State [Agency State]
						FROM DataWarehouse..view_EADTable EAD2
						WHERE 
							CASE 
								WHEN EAD2.EndDate > @QuarterDate 
								OR EAD2.OpenYN = 1 THEN 1 END IS NOT NULL
							AND EAD2.OpenRank = 1
						
					) EADT ON EADT.CaseNumber = EAD.CaseNumber

	WHERE EADT.SiteID IN (@Site)
	GROUP BY
		EAD.CaseNumber,EADT.EndDate
		,CFS.[SurveyDate]
		,CFS.[AuditDate]
		,EADT.ProgramName
		,EADT.Site
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
		,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD
)

SELECT
	F.Trimester
	,F.Site
	,CASE F.Competitive
		WHEN 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END NC_11
	,CASE F.Formula
		WHEN 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END NF_11
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END	NFC_11
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END NN_11
	,F.[Prenatal Care Y/N] NT_11
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DC_11
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DF_11
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DFC_11
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DN_11
	,F.[Answered Prenatal Question] DT_11
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END NC_12A
	,CASE F.Formula
		WHEN 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END NF_12A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END	NFC_12A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END NN_12A
	,F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake] NT_12A
	,CASE F.Competitive
		WHEN 1 THEN F.[Alcohol use at Intake]
		ELSE 0
	END DC_12A
	,CASE F.Formula
		WHEN 1 THEN F.[Alcohol use at Intake]
		ELSE 0
	END DF_12A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Alcohol use at Intake]
		ELSE 0
	END DFC_12A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Alcohol use at Intake]
		ELSE 0
	END DN_12A
	,F.[Alcohol use at Intake] DT_12A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END NC_12T
	,CASE F.Formula
		WHEN 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END NF_12T
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END	NFC_12T
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END NN_12T
	,F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake] NT_12T
	,CASE F.Competitive
		WHEN 1 THEN F.[Tobacco use at Intake]
		ELSE 0
	END DC_12T
	,CASE F.Formula
		WHEN 1 THEN F.[Tobacco use at Intake]
		ELSE 0
	END DF_12T
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Tobacco use at Intake]
		ELSE 0
	END DFC_12T
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Tobacco use at Intake]
		ELSE 0
	END DN_12T
	,F.[Tobacco use at Intake] DT_12T
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END NC_12I
	,CASE F.Formula
		WHEN 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END NF_12I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END	NFC_12I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END NN_12I
	,F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake] NT_12I
	,CASE F.Competitive
		WHEN 1 THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DC_12I
	,CASE F.Formula
		WHEN 1 THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DF_12I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DFC_12I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DN_12I
	,F.[Illicit Drug use at Intake] DT_12I
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care]
		ELSE 0
	END NC_13A
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care]
		ELSE 0
	END NF_13A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care]
		ELSE 0
	END	NFC_13A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care]
		ELSE 0
	END NN_13A
	,F.[Well Woman Care] NT_13A
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DC_13A
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DF_13A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DFC_13A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DN_13A
	,F.[Pregnancy since 1st child] DT_13A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END NC_136
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END NF_136
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END	NFC_136
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END NN_136
	,F.[Well Woman Care 6 mos] NT_136
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DC_136
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DF_136
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DFC_136
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DN_136
	,F.[Pregnancy at 6 Mos] DT_136
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END NC_1312
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END NF_1312
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END	NFC_1312
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END NN_1312
	,F.[Well Woman Care 12 mos] NT_1312
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DC_1312
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DF_1312
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DFC_1312
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DN_1312
	,F.[Pregnancy at 12 Mos] DT_1312
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END NC_1318
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END NF_1318
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END	NFC_1318
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END NN_1318
	,F.[Well Woman Care 18 mos] NT_1318
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DC_1318
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DF_1318
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DFC_1318
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DN_1318
	,F.[Pregnancy at 18 Mos] DT_1318
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END NC_1324
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END NF_1324
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END	NFC_1324
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END NN_1324
	,F.[Well Woman Care 24 mos] NT_1324
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DC_1324
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DF_1324
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DFC_1324
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DN_1324
	,F.[Pregnancy at 24 Mos] DT_1324
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END NC_146
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END NF_146
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END	NFC_146
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END NN_146
	,F.[Pregnancy at 6 Mos] NT_146
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Update - Infancy 6 Months]
		ELSE 0
	END DC_146
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Update - Infancy 6 Months]
		ELSE 0
	END DF_146
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Update - Infancy 6 Months]
		ELSE 0
	END DFC_146
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Update - Infancy 6 Months]
		ELSE 0
	END DN_146
	,F.[Demographics Update - Infancy 6 Months] DT_146
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END NC_1412
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END NF_1412
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END	NFC_1412
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END NN_1412
	,F.[Pregnancy at 12 Mos] NT_1412
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Update - Infancy 12 Months]
		ELSE 0
	END DC_1412
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Update - Infancy 12 Months]
		ELSE 0
	END DF_1412
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Update - Infancy 12 Months]
		ELSE 0
	END DFC_1412
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Update - Infancy 12 Months]
		ELSE 0
	END DN_1412
	,F.[Demographics Update - Infancy 12 Months] DT_1412
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END NC_1418
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END NF_1418
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END	NFC_1418
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END NN_1418
	,F.[Pregnancy at 18 Mos] NT_1418
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Update - Infancy 18 Months]
		ELSE 0
	END DC_1418
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Update - Infancy 18 Months]
		ELSE 0
	END DF_1418
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Update - Infancy 18 Months]
		ELSE 0
	END DFC_1418
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Update - Infancy 18 Months]
		ELSE 0
	END DN_1418
	,F.[Demographics Update - Infancy 18 Months] DT_1418
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END NC_1424
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END NF_1424
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END	NFC_1424
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END NN_1424
	,F.[Pregnancy at 24 Mos] NT_1424
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Update - Infancy 24 Months]
		ELSE 0
	END DC_1424
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Update - Infancy 24 Months]
		ELSE 0
	END DF_1424
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Update - Infancy 24 Months]
		ELSE 0
	END DFC_1424
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Update - Infancy 24 Months]
		ELSE 0
	END DN_1424
	,F.[Demographics Update - Infancy 24 Months] DT_1424
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NC_15E36
	,CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NF_15E36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END	NFC_15E36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NN_15E36
	,CASE F.[36 Weeks Preg Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NT_15E36
	,CASE F.Competitive
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DC_15E36
	,CASE F.Formula
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DF_15E36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DFC_15E36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DN_15E36
	,F.[36 Weeks Preg Y/N] DT_15E36	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NC_15E14
	,CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NF_15E14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END	NFC_15E14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NN_15E14
	,CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NT_15E14
	,CASE F.Competitive
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DC_15E14
	,CASE F.Formula
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DF_15E14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DFC_15E14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DN_15E14
	,F.[1 - 8 Weeks Infancy Y/N] DT_15E14	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15E46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15E46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15E46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15E46
	,CASE F.[Infancy 4 - 6 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15E46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15E46
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15E46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15E46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15E46
	,F.[Infancy 4 - 6 Months Y/N] DT_15E46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15E12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15E12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15E12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15E12
	,CASE F.[Infancy 12 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15E12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_15E12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_15E12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_15E12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_15E12
	,F.[Infancy 12 Months Y/N] DT_15E12	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NC_15P36
	,CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NF_15P36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END	NFC_15P36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NN_15P36
	,CASE F.[36 Weeks Preg Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NT_15P36
	,CASE F.Competitive
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DC_15P36
	,CASE F.Formula
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DF_15P36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DFC_15P36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DN_15P36
	,F.[36 Weeks Preg Y/N] DT_15P36	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NC_15P14
	,CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NF_15P14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END	NFC_15P14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NN_15P14
	,CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NT_15P14
	,CASE F.Competitive
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DC_15P14
	,CASE F.Formula
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DF_15P14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DFC_15P14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DN_15P14
	,F.[1 - 8 Weeks Infancy Y/N] DT_15P14	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15P46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15P46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15P46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15P46
	,CASE F.[Infancy 4 - 6 Months Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15P46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15P46
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15P46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15P46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15P46
	,F.[Infancy 4 - 6 Months Y/N] DT_15P46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15P12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15P12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15P12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15P12
	,CASE F.[Infancy 12 Months Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15P12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_15P12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_15P12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_15P12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_15P12
	,F.[Infancy 12 Months Y/N] DT_15P12	
----------------------------------------
,CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NC_15EP36
	,CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NF_15EP36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END	NFC_15EP36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NN_15EP36
	,CASE F.[36 Weeks Preg Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NT_15EP36
	,CASE F.Competitive
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DC_15EP36
	,CASE F.Formula
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DF_15EP36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DFC_15EP36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DN_15EP36
	,F.[36 Weeks Preg Y/N] DT_15EP36	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NC_15EP14
	,CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NF_15EP14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END	NFC_15EP14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NN_15EP14
	,CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NT_15EP14
	,CASE F.Competitive
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DC_15EP14
	,CASE F.Formula
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DF_15EP14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DFC_15EP14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DN_15EP14
	,F.[1 - 8 Weeks Infancy Y/N] DT_15EP14	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15EP46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15EP46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15EP46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15EP46
	,CASE F.[Infancy 4 - 6 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15EP46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15EP46
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15EP46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15EP46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15EP46
	,F.[Infancy 4 - 6 Months Y/N] DT_15EP46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15EP12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15EP12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15EP12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15EP12
	,CASE F.[Infancy 12 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15EP12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_15EP12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_15EP12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_15EP12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_15EP12
	,F.[Infancy 12 Months Y/N] DT_15EP12	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END NC_16I
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END NF_16I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END	NFC_16I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END NN_16I
	,F.[Breastfeeding at birth] NT_16I
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DC_16I
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DF_16I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DFC_16I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DN_16I
	,F.[Answered Breastfeeding question] DT_16I
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END NC_166
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END NF_166
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END	NFC_166
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END NN_166
	,F.[Breastfeeding at 6 mos] NT_166
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DC_166
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DF_166
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DFC_166
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DN_166
	,F.[Breastfeeding Question 6 mos] DT_166
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END NC_1612
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END NF_1612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END	NFC_1612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END NN_1612
	,F.[Breastfeeding at 12 mos] NT_1612
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 12 mos] 
		ELSE 0
	END DC_1612
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 12 mos]
		ELSE 0
	END DF_1612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 12 mos]
		ELSE 0
	END DFC_1612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 12 mos]
		ELSE 0
	END DN_1612
	,F.[Breastfeeding Question 12 mos] DT_1612
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END NC_1618
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END NF_1618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END	NFC_1618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END NN_1618
	,F.[Breastfeeding at 18 mos] NT_1618
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DC_1618
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DF_1618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DFC_1618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DN_1618
	,F.[Breastfeeding Question 18 mos] DT_1618
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END NC_1624
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END NF_1624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END	NFC_1624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END NN_1624
	,F.[Breastfeeding at 24 mos] NT_1624
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DC_1624
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DF_1624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DFC_1624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DN_1624
	,F.[Breastfeeding Question 24 mos] DT_1624
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END NC_176
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END NF_176
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END	NFC_176
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END NN_176
	,F.[Well-Child Visits 6 mos] NT_176
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_176
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_176
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_176
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_176
	,F.[Infancy 6 Months Y/N] DT_176
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END NC_1712
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END NF_1712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END	NFC_1712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END NN_1712
	,F.[Well-Child Visits 12 mos] NT_1712
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_1712
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_1712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_1712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_1712
	,F.[Infancy 12 Months Y/N] DT_1712
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END NC_1718
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END NF_1718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END	NFC_1718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END NN_1718
	,F.[Well-Child Visits 18 mos] NT_1718
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_1718
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N] 
		ELSE 0
	END DF_1718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_1718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_1718
	,F.[Toddler 18 Months Y/N] DT_1718
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END NC_1724
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END NF_1724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END	NFC_1724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END NN_1724
	,F.[Well-Child Visits 24 mos] NT_1724
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_1724
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_1724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_1724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_1724
	,F.[Toddler 24 Months Y/N] DT_1724	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Insurance]
		ELSE 0
	END NC_18M
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Insurance]
		ELSE 0
	END NF_18M
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Insurance]
		ELSE 0
	END	NFC_18M
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Insurance]
		ELSE 0
	END NN_18M
	,F.[Client Health Insurance] NT_18M
	,CASE F.Competitive
		WHEN 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DC_18M
	,CASE F.Formula
		WHEN 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DF_18M
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DFC_18M
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DN_18M
	,F.[Use of Gov't and Comm Svcs Assessment Y/N] DT_18M
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END NC_18M6
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END NF_18M6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END	NFC_18M6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END NN_18M6
	,F.[Client Health Ins 6 Mos] NT_18M6
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DC_18M6
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DF_18M6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DFC_18M6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DN_18M6
	,F.[Govt Svc Survey 6 mos Y/N] DT_18M6
	----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END NC_18M12
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END NF_18M12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END	NFC_18M12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END NN_18M12
	,F.[Client Health Ins 12 Mos] NT_18M12
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DC_18M12
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DF_18M12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DFC_18M12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DN_18M12
	,F.[Govt Svc Survey 12 mos Y/N] DT_18M12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END NC_18M18
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END NF_18M18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END	NFC_18M18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END NN_18M18
	,F.[Client Health Ins 18 Mos] NT_18M18
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DC_18M18
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DF_18M18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DFC_18M18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DN_18M18
	,F.[Govt Svc Survey 18 mos Y/N] DT_18M18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END NC_18M24
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END NF_18M24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END	NFC_18M24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END NN_18M24
	,F.[Client Health Ins 24 Mos] NT_18M24
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DC_18M24
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DF_18M24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DFC_18M24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DN_18M24
	,F.[Govt Svc Survey 24 mos Y/N] DT_18M24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Insurance]
		ELSE 0
	END NC_18C
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Insurance]
		ELSE 0
	END NF_18C
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Insurance]
		ELSE 0
	END	NFC_18C
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Insurance]
		ELSE 0
	END NN_18C
	,F.[Child Health Insurance] NT_18C
	,CASE F.Competitive
		WHEN 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DC_18C
	,CASE F.Formula
		WHEN 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DF_18C
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DFC_18C
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Use of Gov't and Comm Svcs Assessment Y/N]
		ELSE 0
	END DN_18C
	,F.[Use of Gov't and Comm Svcs Assessment Y/N] DT_18C
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END NC_18C6
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END NF_18C6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END	NFC_18C6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END NN_18C6
	,F.[Child Health Ins 6 Mos] NT_18C6
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DC_18C6
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DF_18C6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DFC_18C6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DN_18C6
	,F.[Govt Svc Survey 6 mos Y/N] DT_18C6
	----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END NC_18C12
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END NF_18C12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END	NFC_18C12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END NN_18C12
	,F.[Child Health Ins 12 Mos] NT_18C12
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DC_18C12
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DF_18C12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DFC_18C12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DN_18C12
	,F.[Govt Svc Survey 12 mos Y/N] DT_18C12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END NC_18C18
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END NF_18C18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END	NFC_18C18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END NN_18C18
	,F.[Child Health Ins 18 Mos] NT_18C18
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DC_18C18
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DF_18C18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DFC_18C18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DN_18C18
	,F.[Govt Svc Survey 18 mos Y/N] DT_18C18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END NC_18C24
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END NF_18C24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END	NFC_18C24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END NN_18C24
	,F.[Child Health Ins 24 Mos] NT_18C24
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DC_18C24
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DF_18C24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DFC_18C24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DN_18C24
	,F.[Govt Svc Survey 24 mos Y/N] DT_18C2
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visists - Injury/Injestion]
		ELSE 0
	END NC_21I
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visists - Injury/Injestion]
		ELSE 0
	END NF_21I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visists - Injury/Injestion]
		ELSE 0
	END	NFC_21I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visists - Injury/Injestion]
		ELSE 0
	END NN_21I
	,F.[Emergency Visists - Injury/Injestion] NT_21I
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DC_21I
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DF_21I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DFC_21I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DN_21I
	,F.[Infant Health Survey Y/N] DT_21I
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visists - Other]
		ELSE 0
	END NC_21A
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visists - Other]
		ELSE 0
	END NF_21A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visists - Other]
		ELSE 0
	END	NFC_21A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visists - Other]
		ELSE 0
	END NN_21A
	,F.[Emergency Visists - Other] NT_21A
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DC_21A
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DF_21A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DFC_21A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DN_21A
	,F.[Infant Health Survey Y/N] DT_21A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visists - Client]
		ELSE 0
	END NC_22
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visists - Client]
		ELSE 0
	END NF_22
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visists - Client]
		ELSE 0
	END	NFC_22
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visists - Client]
		ELSE 0
	END NN_22
	,F.[Emergency Visists - Client] NT_22
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DC_22
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DF_22
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DFC_22
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DN_22
	,F.[Demographics Assessment Y/N] DT_22
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END NC_23
	,CASE F.Formula
		WHEN 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END NF_23
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END	NFC_23
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END NN_23
	,F.[Client Child Injury Prevention Training Y/N] NT_23
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DC_23
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DF_23
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DFC_23
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DN_23
	,F.[Home Visit Encounter Y/N] DT_23
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END NC_24
	,CASE F.Formula
		WHEN 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END NF_24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END	NFC_24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END NN_24
	,F.[Injuries requiring treatment] NT_24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DC_24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DF_24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DFC_24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DN_24
	,F.[Infant Birth Survey Y/N] DT_24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END NC_25
	,CASE F.Formula
		WHEN 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END NF_25
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END	NFC_25
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END NN_25
	,F.[Suspected cases of maltreatment] NT_25
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DC_25
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DF_25
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DFC_25
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DN_25
	,F.[Infant Birth Survey Y/N] DT_25
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NC_31L
	,CASE F.Formula
		WHEN 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NF_31L
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END	NFC_31L
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NN_31L
	,F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos] NT_31L
	,CASE F.Competitive
		WHEN 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DC_31L
	,CASE F.Formula
		WHEN 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DF_31L
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DFC_31L
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DN_31L
	,F.[Learning Materials Score - 6 mos] DT_31L
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NC_31I
	,CASE F.Formula
		WHEN 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NF_31I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END	NFC_31I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NN_31I
	,F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos] NT_31I
	,CASE F.Competitive
		WHEN 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DC_31I
	,CASE F.Formula
		WHEN 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DF_31I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DFC_31I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DN_31I
	,F.[Involvement Materials Score - 6 mos] DT_31I
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END NC_32
	,CASE F.Formula
		WHEN 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END NF_32
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END	NFC_32
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END NN_32
	,F.[Total Score - 18 mos] - F.[Total Score - 6 mos] NT_32
	,CASE F.Competitive
		WHEN 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DC_32
	,CASE F.Formula
		WHEN 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DF_32
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DFC_32
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DN_32
	,F.[Total Score - 6 mos] DT_32
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END NC_33R
	,CASE F.Formula
		WHEN 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END NF_33R
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END	NFC_33R
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END NN_33R
	,F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos] NT_33R
	,CASE F.Competitive
		WHEN 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DC_33R
	,CASE F.Formula
		WHEN 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DF_33R
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DFC_33R
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DN_33R
	,F.[Responsivity Score - 6 mos] DT_33R
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END NC_33A
	,CASE F.Formula
		WHEN 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END NF_33A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END	NFC_33A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END NN_33A
	,F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos] NT_33A
	,CASE F.Competitive
		WHEN 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DC_33A
	,CASE F.Formula
		WHEN 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DF_33A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DFC_33A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DN_33A
	,F.[Acceptance Score - 6 mos] DT_33A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 6 Mos]
		ELSE 0
	END NC_356
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END NF_356
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END	NFC_356
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END NN_356
	,F.[ASQ Communication Screening 6 mos] NT_356
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_356
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_356
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_356
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_356
	,F.[Infancy 6 Months Y/N] DT_356
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END NC_3512
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END NF_3512
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END	NFC_3512
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END NN_3512
	,F.[ASQ Communication Screening 12 mos] NT_3512
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_3512
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_3512
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_3512
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_3512
	,F.[Infancy 12 Months Y/N] DT_3512
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END NC_3518
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END NF_3518
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END	NFC_3518
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END NN_3518
	,F.[ASQ Communication Screening 18 mos] NT_3518
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_3518
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_3518
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_3518
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_3518
	,F.[Toddler 18 Months Y/N] DT_3518
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END NC_3524
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END NF_3524
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END	NFC_3524
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END NN_3524
	,F.[ASQ Communication Screening 24 mos] NT_3524
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_3524
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_3524
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_3524
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_3524
	,F.[Toddler 24 Months Y/N] DT_3524	
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END NC_35A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END NF_35A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END	NFC_35A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END NN_35A6
	,F.[ASQ Communication Score 6 Mos - Agg] NT_35A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_35A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_35A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_35A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_35A6
	,F.[Infancy 6 Months Y/N] DT_35A6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END NC_35A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END NF_35A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END	NFC_35A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END NN_35A12
	,F.[ASQ Communication Score 12 Mos - Agg] NT_35A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_35A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_35A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_35A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_35A12
	,F.[Infancy 12 Months Y/N] DT_35A12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END NC_35A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END NF_35A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END	NFC_35A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END NN_35A18
	,F.[ASQ Communication Score 18 Mos - Agg] NT_35A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_35A18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_35A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_35A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_35A18
	,F.[Toddler 18 Months Y/N] DT_35A18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END NC_35A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END NF_35A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END	NFC_35A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END NN_35A24
	,F.[ASQ Communication Score 24 Mos - Agg] NT_35A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_35A24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_35A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_35A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_35A24
	,F.[Toddler 24 Months Y/N] DT_35A24	

----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 6 Mos]
		ELSE 0
	END NC_366
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END NF_366
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END	NFC_366
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END NN_366
	,F.[ASQ Problem Solving Screening 6 mos] NT_366
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_366
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_366
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_366
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_366
	,F.[Infancy 6 Months Y/N] DT_366
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END NC_3612
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END NF_3612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END	NFC_3612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END NN_3612
	,F.[ASQ Problem Solving Screening 12 mos] NT_3612
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_3612
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_3612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_3612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_3612
	,F.[Infancy 12 Months Y/N] DT_3612
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END NC_3618
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END NF_3618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END	NFC_3618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END NN_3618
	,F.[ASQ Problem Solving Screening 18 mos] NT_3618
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_3618
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_3618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_3618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_3618
	,F.[Toddler 18 Months Y/N] DT_3618
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END NC_3624
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END NF_3624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END	NFC_3624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END NN_3624
	,F.[ASQ Problem Solving Screening 24 mos] NT_3624
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_3624
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_3624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_3624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_3624
	,F.[Toddler 24 Months Y/N] DT_3624	
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END NC_36A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END NF_36A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END	NFC_36A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END NN_36A6
	,F.[ASQ Problem Solving Score 6 Mos - Agg] NT_36A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_36A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_36A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_36A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_36A6
	,F.[Infancy 6 Months Y/N] DT_36A6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END NC_36A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END NF_36A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END	NFC_36A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END NN_36A12
	,F.[ASQ Problem Solving Score 12 Mos - Agg] NT_36A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_36A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_36A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_36A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_36A12
	,F.[Infancy 12 Months Y/N] DT_36A12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END NC_36A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END NF_36A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END	NFC_36A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END NN_36A18
	,F.[ASQ Problem Solving Score 18 Mos - Agg] NT_36A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_36A18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_36A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_36A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_36A18
	,F.[Toddler 18 Months Y/N] DT_36A18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END NC_36A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END NF_36A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END	NFC_36A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END NN_36A24
	,F.[ASQ Problem Solving Score 24 Mos - Agg] NT_36A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_36A24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_36A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_36A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_36A24
	,F.[Toddler 24 Months Y/N] DT_36A24	

----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 6 Mos]
		ELSE 0
	END NC_376
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END NF_376
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END	NFC_376
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END NN_376
	,F.[ASQ Personal-Social Screening 6 mos] NT_376
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_376
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_376
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_376
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_376
	,F.[Infancy 6 Months Y/N] DT_376
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END NC_3712
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END NF_3712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END	NFC_3712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END NN_3712
	,F.[ASQ Personal-Social Screening 12 mos] NT_3712
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_3712
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_3712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_3712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_3712
	,F.[Infancy 12 Months Y/N] DT_3712
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END NC_3718
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END NF_3718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END	NFC_3718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END NN_3718
	,F.[ASQ Personal-Social Screening 18 mos] NT_3718
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_3718
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_3718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_3718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_3718
	,F.[Toddler 18 Months Y/N] DT_3718
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END NC_3724
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END NF_3724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END	NFC_3724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END NN_3724
	,F.[ASQ Personal-Social Screening 24 mos] NT_3724
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_3724
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_3724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_3724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_3724
	,F.[Toddler 24 Months Y/N] DT_3724	
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END NC_37A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END NF_37A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END	NFC_37A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END NN_37A6
	,F.[ASQ Personal-Social Score 6 Mos - Agg] NT_37A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_37A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_37A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_37A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_37A6
	,F.[Infancy 6 Months Y/N] DT_37A6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END NC_37A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END NF_37A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END	NFC_37A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END NN_37A12
	,F.[ASQ Personal-Social Score 12 Mos - Agg] NT_37A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_37A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_37A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_37A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_37A12
	,F.[Infancy 12 Months Y/N] DT_37A12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END NC_37A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END NF_37A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END	NFC_37A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END NN_37A18
	,F.[ASQ Personal-Social Score 18 Mos - Agg] NT_37A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_37A18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_37A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_37A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_37A18
	,F.[Toddler 18 Months Y/N] DT_37A18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END NC_37A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END NF_37A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END	NFC_37A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END NN_37A24
	,F.[ASQ Personal-Social Score 24 Mos - Agg] NT_37A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_37A24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_37A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_37A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_37A24
	,F.[Toddler 24 Months Y/N] DT_37A24	

----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 6 Mos]
		ELSE 0
	END NC_386
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END NF_386
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END	NFC_386
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END NN_386
	,F.[ASQ ASQ-SE Screening 6 mos] NT_386
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_386
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_386
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_386
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_386
	,F.[Infancy 6 Months Y/N] DT_386
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END NC_3812
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END NF_3812
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END	NFC_3812
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END NN_3812
	,F.[ASQ ASQ-SE Screening 12 mos] NT_3812
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_3812
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_3812
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_3812
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_3812
	,F.[Infancy 12 Months Y/N] DT_3812
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END NC_3818
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END NF_3818
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END	NFC_3818
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END NN_3818
	,F.[ASQ ASQ-SE Screening 18 mos] NT_3818
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_3818
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_3818
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_3818
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_3818
	,F.[Toddler 18 Months Y/N] DT_3818
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END NC_3824
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END NF_3824
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END	NFC_3824
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END NN_3824
	,F.[ASQ ASQ-SE Screening 24 mos] NT_3824
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_3824
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_3824
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_3824
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_3824
	,F.[Toddler 24 Months Y/N] DT_3824	
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END NC_38A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END NF_38A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END	NFC_38A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END NN_38A6
	,F.[ASQ ASQ-SE Score 6 Mos - Agg] NT_38A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_38A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_38A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_38A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_38A6
	,F.[Infancy 6 Months Y/N] DT_38A6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END NC_38A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END NF_38A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END	NFC_38A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END NN_38A12
	,F.[ASQ ASQ-SE Score 12 Mos - Agg] NT_38A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_38A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_38A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_38A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_38A12
	,F.[Infancy 12 Months Y/N] DT_38A12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END NC_38A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END NF_38A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END	NFC_38A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END NN_38A18
	,F.[ASQ ASQ-SE Score 18 Mos - Agg] NT_38A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_38A18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_38A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_38A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_38A18
	,F.[Toddler 18 Months Y/N] DT_38A18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END NC_38A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END NF_38A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END	NFC_38A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END NN_38A24
	,F.[ASQ ASQ-SE Score 24 Mos - Agg] NT_38A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_38A24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_38A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_38A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_38A24
	,F.[Toddler 24 Months Y/N] DT_38A24	
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END NC_39S6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END NF_39S6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END	NFC_39S6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END NN_39S6
	,F.[ASQ Weight/Height/Head Measured Screening 6 Mos] NT_39S6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DC_39S6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_39S6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_39S6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_39S6
	,F.[Infancy 6 Months Y/N] DT_39S6
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END NC_39S12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END NF_39S12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END	NFC_39S12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END NN_39S12
	,F.[ASQ Weight/Height/Head Measured Screening 12 Mos] NT_39S12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_39S12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_39S12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_39S12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_39S12
	,F.[Infancy 12 Months Y/N] DT_39S12
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END NC_39S18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END NF_39S18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END	NFC_39S18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END NN_39S18
	,F.[ASQ Weight/Height/Head Measured Screening 18 Mos] NT_39S18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DC_39S18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_39S18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_39S18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_39S18
	,F.[Toddler 18 Months Y/N] DT_39S18
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END NC_39S24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END NF_39S24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END	NFC_39S24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END NN_39S24
	,F.[ASQ Weight/Height/Head Measured Screening 24 Mos] NT_39S24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DC_39S24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_39S24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_39S24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_39S24
	,F.[Toddler 24 Months Y/N] DT_39S24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height 6 Mos - Agg]
		ELSE 0
	END NC_39H6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height 6 Mos - Agg]
		ELSE 0
	END NF_39H6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height 6 Mos - Agg]
		ELSE 0
	END	NFC_39H6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height 6 Mos - Agg]
		ELSE 0
	END NN_39H6
	,F.[ASQ Height 6 Mos - Agg] NT_39H6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N] 
		ELSE 0
	END DC_39H6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_39H6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_39H6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_39H6
	,F.[Infancy 6 Months Y/N] DT_39H6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height 12 Mos - Agg]
		ELSE 0
	END NC_39H12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height 12 Mos - Agg]
		ELSE 0
	END NF_39H12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height 12 Mos - Agg]
		ELSE 0
	END	NFC_39H12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height 12 Mos - Agg]
		ELSE 0
	END NN_39H12
	,F.[ASQ Height 12 Mos - Agg] NT_39H12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_39H12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_39H12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_39H12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_39H12
	,F.[Infancy 12 Months Y/N] DT_39H12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height 18 Mos - Agg]
		ELSE 0
	END NC_39H18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height 18 Mos - Agg]
		ELSE 0
	END NF_39H18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height 18 Mos - Agg]
		ELSE 0
	END	NFC_39H18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height 18 Mos - Agg]
		ELSE 0
	END NN_39H18
	,F.[ASQ Height 18 Mos - Agg] NT_39H18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N] 
		ELSE 0
	END DC_39H18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_39H18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_39H18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_39H18
	,F.[Toddler 18 Months Y/N] DT_39H18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height 24 Mos - Agg]
		ELSE 0
	END NC_39H24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height 24 Mos - Agg]
		ELSE 0
	END NF_39H24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height 24 Mos - Agg]
		ELSE 0
	END	NFC_39H24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height 24 Mos - Agg]
		ELSE 0
	END NN_39H24
	,F.[ASQ Height 24 Mos - Agg] NT_39H24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N] 
		ELSE 0
	END DC_39H24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_39H24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_39H24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_39H24
	,F.[Toddler 24 Months Y/N] DT_39H24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight 6 Mos - Agg]
		ELSE 0
	END NC_39W6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight 6 Mos - Agg]
		ELSE 0
	END NF_39W6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight 6 Mos - Agg]
		ELSE 0
	END	NFC_39W6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight 6 Mos - Agg]
		ELSE 0
	END NN_39W6
	,F.[ASQ Weight 6 Mos - Agg] NT_39W6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N] 
		ELSE 0
	END DC_39W6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_39W6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_39W6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_39W6
	,F.[Infancy 6 Months Y/N] DT_39W6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight 12 Mos - Agg]
		ELSE 0
	END NC_39W12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight 12 Mos - Agg]
		ELSE 0
	END NF_39W12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight 12 Mos - Agg]
		ELSE 0
	END	NFC_39W12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight 12 Mos - Agg]
		ELSE 0
	END NN_39W12
	,F.[ASQ Weight 12 Mos - Agg] NT_39W12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_39W12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_39W12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_39W12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_39W12
	,F.[Infancy 12 Months Y/N] DT_39W12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight 18 Mos - Agg]
		ELSE 0
	END NC_39W18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight 18 Mos - Agg]
		ELSE 0
	END NF_39W18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight 18 Mos - Agg]
		ELSE 0
	END	NFC_39W18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight 18 Mos - Agg]
		ELSE 0
	END NN_39W18
	,F.[ASQ Weight 18 Mos - Agg] NT_39W18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N] 
		ELSE 0
	END DC_39W18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_39W18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_39W18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_39W18
	,F.[Toddler 18 Months Y/N] DT_39W18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight 24 Mos - Agg]
		ELSE 0
	END NC_39W24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight 24 Mos - Agg]
		ELSE 0
	END NF_39W24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight 24 Mos - Agg]
		ELSE 0
	END	NFC_39W24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight 24 Mos - Agg]
		ELSE 0
	END NN_39W24
	,F.[ASQ Weight 24 Mos - Agg] NT_39W24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N] 
		ELSE 0
	END DC_39W24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_39W24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_39W24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_39W24
	,F.[Toddler 24 Months Y/N] DT_39W24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Circ 6 Mos - Agg]
		ELSE 0
	END NC_39HC6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Circ 6 Mos - Agg]
		ELSE 0
	END NF_39HC6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Circ 6 Mos - Agg]
		ELSE 0
	END	NFC_39HC6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Circ 6 Mos - Agg]
		ELSE 0
	END NN_39HC6
	,F.[ASQ Head Circ 6 Mos - Agg] NT_39HC6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 6 Months Y/N] 
		ELSE 0
	END DC_39HC6
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DF_39HC6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DFC_39HC6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 6 Months Y/N]
		ELSE 0
	END DN_39HC6
	,F.[Infancy 6 Months Y/N] DT_39HC6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Circ 12 Mos - Agg]
		ELSE 0
	END NC_39HC12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Circ 12 Mos - Agg]
		ELSE 0
	END NF_39HC12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Circ 12 Mos - Agg]
		ELSE 0
	END	NFC_39HC12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Circ 12 Mos - Agg]
		ELSE 0
	END NN_39HC12
	,F.[ASQ Head Circ 12 Mos - Agg] NT_39HC12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] 
		ELSE 0
	END DC_39HC12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_39HC12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_39HC12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_39HC12
	,F.[Infancy 12 Months Y/N] DT_39HC12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Circ 18 Mos - Agg]
		ELSE 0
	END NC_39HC18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Circ 18 Mos - Agg]
		ELSE 0
	END NF_39HC18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Circ 18 Mos - Agg]
		ELSE 0
	END	NFC_39HC18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Circ 18 Mos - Agg]
		ELSE 0
	END NN_39HC18
	,F.[ASQ Head Circ 18 Mos - Agg] NT_39HC18
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 18 Months Y/N] 
		ELSE 0
	END DC_39HC18
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DF_39HC18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DFC_39HC18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 18 Months Y/N]
		ELSE 0
	END DN_39HC18
	,F.[Toddler 18 Months Y/N] DT_39HC18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Circ 24 Mos - Agg]
		ELSE 0
	END NC_39HC24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Circ 24 Mos - Agg]
		ELSE 0
	END NF_39HC24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Circ 24 Mos - Agg]
		ELSE 0
	END	NFC_39HC24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Circ 24 Mos - Agg]
		ELSE 0
	END NN_39HC24
	,F.[ASQ Head Circ 24 Mos - Agg] NT_39HC24
	,CASE F.Competitive
		WHEN 1 THEN F.[Toddler 24 Months Y/N] 
		ELSE 0
	END DC_39HC24
	,CASE F.Formula
		WHEN 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DF_39HC24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DFC_39HC24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Toddler 24 Months Y/N]
		ELSE 0
	END DN_39HC24
	,F.[Toddler 24 Months Y/N] DT_39HC24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END NC_42
	,CASE F.Formula
		WHEN 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END NF_42
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END	NFC_42
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END NN_42
	,F.[Domestic Violence Screening Y/N] NT_42
	,CASE F.Competitive
		WHEN 1 THEN F.[Families in NFP] 
		ELSE 0
	END DC_42
	,CASE F.Formula
		WHEN 1 THEN F.[Families in NFP]
		ELSE 0
	END DF_42
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Families in NFP]
		ELSE 0
	END DFC_42
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Families in NFP]
		ELSE 0
	END DN_42
	,F.[Families in NFP] DT_42
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END NC_43
	,CASE F.Formula
		WHEN 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END NF_43
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END	NFC_43
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END NN_43
	,F.[Domestic Violence Referral] NT_43
	,CASE F.Competitive
		WHEN 1 THEN F.[Domestic Violence Identified] 
		ELSE 0
	END DC_43
	,CASE F.Formula
		WHEN 1 THEN F.[Domestic Violence Identified]
		ELSE 0
	END DF_43
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Domestic Violence Identified]
		ELSE 0
	END DFC_43
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Domestic Violence Identified]
		ELSE 0
	END DN_43
	,F.[Domestic Violence Identified] DT_43
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END NC_44
	,CASE F.Formula
		WHEN 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END NF_44
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END	NFC_44
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END NN_44
	,F.[Safety Plan discussed] NT_44
	,CASE F.Competitive
		WHEN 1 THEN F.[Safety Plan discussed] 
		ELSE 0
	END DC_44
	,CASE F.Formula
		WHEN 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END DF_44
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END DFC_44
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END DN_44
	,F.[Safety Plan discussed] DT_44
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Received referral]
		ELSE 0
	END NC_61
	,CASE F.Formula
		WHEN 1 THEN F.[Received referral]
		ELSE 0
	END NF_61
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received referral]
		ELSE 0
	END	NFC_61
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received referral]
		ELSE 0
	END NN_61
	,F.[Received referral] NT_61
	,CASE F.Competitive
		WHEN 1 THEN F.[Received Referral] 
		ELSE 0
	END DC_61
	,CASE F.Formula
		WHEN 1 THEN F.[Received Referral]
		ELSE 0
	END DF_61
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
		ELSE 0
	END DFC_61
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
		ELSE 0
	END DN_61
	,F.[Received Referral] DT_61
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Received referral]
		ELSE 0
	END NC_62C
	,CASE F.Formula
		WHEN 1 THEN F.[Received referral]
		ELSE 0
	END NF_62C
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received referral]
		ELSE 0
	END	NFC_62C
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received referral]
		ELSE 0
	END NN_62C
	,F.[Received referral] NT_62C
	,CASE F.Competitive
		WHEN 1 THEN F.[Received Referral] 
		ELSE 0
	END DC_62C
	,CASE F.Formula
		WHEN 1 THEN F.[Received Referral]
		ELSE 0
	END DF_62C
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
		ELSE 0
	END DFC_62C
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
		ELSE 0
	END DN_62C
	,F.[Received Referral] DT_62C
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END NC_62_1
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END NF_62_1
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END NFC_62_1
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END NN_62_1
 ,F.[SERVICE_REFER_0_TANF] NT_62_1
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_1
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_1
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_1
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_1
 ,F.[Received Referral] DT_62_1
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END NC_62_2
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END NF_62_2
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END NFC_62_2
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END NN_62_2
 ,F.[SERVICE_REFER_0_FOODSTAMP] NT_62_2
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_2
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_2
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_2
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_2
 ,F.[Received Referral] DT_62_2
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END NC_62_3
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END NF_62_3
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END NFC_62_3
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END NN_62_3
 ,F.[SERVICE_REFER_0_SOCIAL_SECURITY] NT_62_3
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_3
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_3
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_3
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_3
 ,F.[Received Referral] DT_62_3
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END NC_62_4
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END NF_62_4
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END NFC_62_4
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END NN_62_4
 ,F.[SERVICE_REFER_0_UNEMPLOYMENT] NT_62_4
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_4
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_4
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_4
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_4
 ,F.[Received Referral] DT_62_4
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END NC_62_5
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END NF_62_5
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END NFC_62_5
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END NN_62_5
 ,F.[SERVICE_REFER_0_SUBSID_CHILD_CARE] NT_62_5
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_5
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_5
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_5
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_5
 ,F.[Received Referral] DT_62_5
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END NC_62_6
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END NF_62_6
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END NFC_62_6
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END NN_62_6
 ,F.[SERVICE_REFER_0_IPV] NT_62_6
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_6
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_6
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_6
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_6
 ,F.[Received Referral] DT_62_6
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END NC_62_7
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END NF_62_7
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END NFC_62_7
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END NN_62_7
 ,F.[SERVICE_REFER_0_CPS] NT_62_7
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_7
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_7
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_7
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_7
 ,F.[Received Referral] DT_62_7
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END NC_62_8
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END NF_62_8
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END NFC_62_8
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END NN_62_8
 ,F.[SERVICE_REFER_0_MENTAL] NT_62_8
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_8
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_8
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_8
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_8
 ,F.[Received Referral] DT_62_8
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END NC_62_9
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END NF_62_9
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END NFC_62_9
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END NN_62_9
 ,F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] NT_62_9
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_9
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_9
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_9
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_9
 ,F.[Received Referral] DT_62_9
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END NC_62_10
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END NF_62_10
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END NFC_62_10
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END NN_62_10
 ,F.[SERVICE_REFER_0_SMOKE] NT_62_10
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_10
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_10
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_10
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_10
 ,F.[Received Referral] DT_62_10
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END NC_62_11
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END NF_62_11
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END NFC_62_11
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END NN_62_11
 ,F.[SERVICE_REFER_0_ALCOHOL_ABUSE] NT_62_11
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_11
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_11
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_11
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_11
 ,F.[Received Referral] DT_62_11
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END NC_62_12
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END NF_62_12
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END NFC_62_12
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END NN_62_12
 ,F.[SERVICE_REFER_0_DRUG_ABUSE] NT_62_12
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_12
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_12
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_12
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_12
 ,F.[Received Referral] DT_62_12
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END NC_62_13
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END NF_62_13
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END NFC_62_13
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END NN_62_13
 ,F.[SERVICE_REFER_0_MEDICAID] NT_62_13
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_13
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_13
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_13
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_13
 ,F.[Received Referral] DT_62_13
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END NC_62_14
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END NF_62_14
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END NFC_62_14
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END NN_62_14
 ,F.[SERVICE_REFER_0_SCHIP] NT_62_14
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_14
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_14
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_14
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_14
 ,F.[Received Referral] DT_62_14
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END NC_62_15
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END NF_62_15
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END NFC_62_15
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END NN_62_15
 ,F.[SERVICE_REFER_0_PRIVATE_INSURANCE] NT_62_15
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_15
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_15
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_15
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_15
 ,F.[Received Referral] DT_62_15
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END NC_62_16
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END NF_62_16
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END NFC_62_16
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END NN_62_16
 ,F.[SERVICE_REFER_0_SPECIAL_NEEDS] NT_62_16
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_16
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_16
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_16
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_16
 ,F.[Received Referral] DT_62_16
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END NC_62_17
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END NF_62_17
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END NFC_62_17
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END NN_62_17
 ,F.[SERVICE_REFER_0_PCP_SICK_CLIENT] NT_62_17
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_17
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_17
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_17
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_17
 ,F.[Received Referral] DT_62_17
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END NC_62_18
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END NF_62_18
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END NFC_62_18
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END NN_62_18
 ,F.[SERVICE_REFER_0_PCP_WELL_CLIENT] NT_62_18
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_18
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_18
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_18
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_18
 ,F.[Received Referral] DT_62_18
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END NC_62_19
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END NF_62_19
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END NFC_62_19
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END NN_62_19
 ,F.[SERVICE_REFER_0_PCP_SICK_CHILD] NT_62_19
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_19
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_19
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_19
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_19
 ,F.[Received Referral] DT_62_19
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END NC_62_20
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END NF_62_20
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END NFC_62_20
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END NN_62_20
 ,F.[SERVICE_REFER_0_PCP_WELL_CHILD] NT_62_20
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_20
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_20
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_20
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_20
 ,F.[Received Referral] DT_62_20
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END NC_62_21
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END NF_62_21
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END NFC_62_21
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END NN_62_21
 ,F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] NT_62_21
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_21
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_21
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_21
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_21
 ,F.[Received Referral] DT_62_21
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END NC_62_22
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END NF_62_22
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END NFC_62_22
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END NN_62_22
 ,F.[SERVICE_REFER_0_INTERVENTION] NT_62_22
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_22
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_22
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_22
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_22
 ,F.[Received Referral] DT_62_22
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END NC_62_23
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END NF_62_23
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END NFC_62_23
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END NN_62_23
 ,F.[SERVICE_REFER_0_WIC_CLIENT] NT_62_23
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_23
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_23
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_23
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_23
 ,F.[Received Referral] DT_62_23
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END NC_62_24
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END NF_62_24
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END NFC_62_24
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END NN_62_24
 ,F.[SERVICE_REFER_0_CHILD_CARE] NT_62_24
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_24
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_24
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_24
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_24
 ,F.[Received Referral] DT_62_24
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END NC_62_25
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END NF_62_25
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END NFC_62_25
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END NN_62_25
 ,F.[SERVICE_REFER_0_JOB_TRAINING] NT_62_25
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_25
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_25
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_25
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_25
 ,F.[Received Referral] DT_62_25
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END NC_62_26
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END NF_62_26
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END NFC_62_26
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END NN_62_26
 ,F.[SERVICE_REFER_0_HOUSING] NT_62_26
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_26
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_26
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_26
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_26
 ,F.[Received Referral] DT_62_26
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END NC_62_27
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END NF_62_27
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END NFC_62_27
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END NN_62_27
 ,F.[SERVICE_REFER_0_TRANSPORTATION] NT_62_27
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_27
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_27
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_27
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_27
 ,F.[Received Referral] DT_62_27
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END NC_62_28
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END NF_62_28
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END NFC_62_28
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END NN_62_28
 ,F.[SERVICE_REFER_0_PREVENT_INJURY] NT_62_28
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_28
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_28
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_28
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_28
 ,F.[Received Referral] DT_62_28
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END NC_62_29
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END NF_62_29
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END NFC_62_29
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END NN_62_29
 ,F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] NT_62_29
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_29
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_29
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_29
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_29
 ,F.[Received Referral] DT_62_29
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END NC_62_30
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END NF_62_30
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END NFC_62_30
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END NN_62_30
 ,F.[SERVICE_REFER_0_LACTATION] NT_62_30
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_30
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_30
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_30
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_30
 ,F.[Received Referral] DT_62_30
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END NC_62_31
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END NF_62_31
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END NFC_62_31
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END NN_62_31
 ,F.[SERVICE_REFER_0_GED] NT_62_31
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_31
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_31
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_31
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_31
 ,F.[Received Referral] DT_62_31
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END NC_62_32
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END NF_62_32
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END NFC_62_32
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END NN_62_32
 ,F.[SERVICE_REFER_0_HIGHER_EDUC] NT_62_32
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_32
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_32
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_32
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_32
 ,F.[Received Referral] DT_62_32
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END NC_62_33
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END NF_62_33
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END NFC_62_33
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END NN_62_33
 ,F.[SERVICE_REFER_0_CHARITY] NT_62_33
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_33
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_33
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_33
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_33
 ,F.[Received Referral] DT_62_33
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END NC_62_34
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END NF_62_34
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END NFC_62_34
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END NN_62_34
 ,F.[SERVICE_REFER_0_LEGAL_CLIENT] NT_62_34
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_34
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_34
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_34
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_34
 ,F.[Received Referral] DT_62_34
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END NC_62_35
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END NF_62_35
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END NFC_62_35
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END NN_62_35
 ,F.[SERVICE_REFER_0_PATERNITY] NT_62_35
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_35
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_35
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_35
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_35
 ,F.[Received Referral] DT_62_35
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END NC_62_36
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END NF_62_36
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END NFC_62_36
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END NN_62_36
 ,F.[SERVICE_REFER_0_CHILD_SUPPORT] NT_62_36
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_36
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_36
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_36
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_36
 ,F.[Received Referral] DT_62_36
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END NC_62_37
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END NF_62_37
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END NFC_62_37
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END NN_62_37
 ,F.[SERVICE_REFER_0_ADOPTION] NT_62_37
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_37
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_37
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_37
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_37
 ,F.[Received Referral] DT_62_37
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END NC_62_38
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END NF_62_38
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END NFC_62_38
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END NN_62_38
 ,F.[SERVICE_REFER_0_DENTAL] NT_62_38
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_38
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_38
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_38
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_38
 ,F.[Received Referral] DT_62_38

----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END NC_62_40
 ,CASE F.Formula
  WHEN 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END NF_62_40
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END NFC_62_40
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END NN_62_40
 ,F.[SERIVCE_REFER_0_OTHER] NT_62_40
 ,CASE F.Competitive
  WHEN 1 THEN F.[Received Referral] 
  ELSE 0
 END DC_62_40
 ,CASE F.Formula
  WHEN 1 THEN F.[Received Referral]
  ELSE 0
 END DF_62_40
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Received Referral]
  ELSE 0
 END DFC_62_40
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Received Referral]
  ELSE 0
 END DN_62_40
 ,F.[Received Referral] DT_62_40

----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_TANF] 
  ELSE 0
 END NC_65_1
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_TANF] 
  ELSE 0
 END NF_65_1
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_TANF] 
  ELSE 0
 END NFC_65_1
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_TANF] 
  ELSE 0
 END NN_65_1
 ,F.[SERVICE_USE_0_TANF]  NT_65_1
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_TANF] 
  ELSE 0
 END DC_65_1
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END DF_65_1
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END DFC_65_1
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_TANF]
  ELSE 0
 END DN_65_1
 ,F.[SERVICE_REFER_0_TANF] DT_65_1
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_FOODSTAMP] 
  ELSE 0
 END NC_65_2
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_FOODSTAMP] 
  ELSE 0
 END NF_65_2
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_FOODSTAMP] 
  ELSE 0
 END NFC_65_2
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_FOODSTAMP] 
  ELSE 0
 END NN_65_2
 ,F.[SERVICE_USE_0_FOODSTAMP]  NT_65_2
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_FOODSTAMP] 
  ELSE 0
 END DC_65_2
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END DF_65_2
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END DFC_65_2
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_FOODSTAMP]
  ELSE 0
 END DN_65_2
 ,F.[SERVICE_REFER_0_FOODSTAMP] DT_65_2
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_SOCIAL_SECURITY] 
  ELSE 0
 END NC_65_3
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_SOCIAL_SECURITY] 
  ELSE 0
 END NF_65_3
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_SOCIAL_SECURITY] 
  ELSE 0
 END NFC_65_3
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_SOCIAL_SECURITY] 
  ELSE 0
 END NN_65_3
 ,F.[SERVICE_USE_0_SOCIAL_SECURITY]  NT_65_3
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY] 
  ELSE 0
 END DC_65_3
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END DF_65_3
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END DFC_65_3
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SOCIAL_SECURITY]
  ELSE 0
 END DN_65_3
 ,F.[SERVICE_REFER_0_SOCIAL_SECURITY] DT_65_3
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_UNEMPLOYMENT] 
  ELSE 0
 END NC_65_4
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_UNEMPLOYMENT] 
  ELSE 0
 END NF_65_4
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_UNEMPLOYMENT] 
  ELSE 0
 END NFC_65_4
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_UNEMPLOYMENT] 
  ELSE 0
 END NN_65_4
 ,F.[SERVICE_USE_0_UNEMPLOYMENT]  NT_65_4
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT] 
  ELSE 0
 END DC_65_4
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END DF_65_4
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END DFC_65_4
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_UNEMPLOYMENT]
  ELSE 0
 END DN_65_4
 ,F.[SERVICE_REFER_0_UNEMPLOYMENT] DT_65_4
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_SUBSID_CARE] 
  ELSE 0
 END NC_65_5
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_SUBSID_CARE] 
  ELSE 0
 END NF_65_5
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_SUBSID_CARE] 
  ELSE 0
 END NFC_65_5
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_SUBSID_CARE] 
  ELSE 0
 END NN_65_5
 ,F.[SERVICE_USE_0_SUBSID_CARE]  NT_65_5
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE] 
  ELSE 0
 END DC_65_5
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END DF_65_5
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END DFC_65_5
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
  ELSE 0
 END DN_65_5
 ,F.[SERVICE_REFER_0_SUBSID_CHILD_CARE] DT_65_5
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_IPV] 
  ELSE 0
 END NC_65_6
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_IPV] 
  ELSE 0
 END NF_65_6
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_IPV] 
  ELSE 0
 END NFC_65_6
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_IPV] 
  ELSE 0
 END NN_65_6
 ,F.[SERVICE_USE_0_IPV]  NT_65_6
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_IPV] 
  ELSE 0
 END DC_65_6
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END DF_65_6
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END DFC_65_6
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_IPV]
  ELSE 0
 END DN_65_6
 ,F.[SERVICE_REFER_0_IPV] DT_65_6
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_CPS] 
  ELSE 0
 END NC_65_7
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_CPS] 
  ELSE 0
 END NF_65_7
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_CPS] 
  ELSE 0
 END NFC_65_7
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_CPS] 
  ELSE 0
 END NN_65_7
 ,F.[SERVICE_USE_0_CPS]  NT_65_7
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CPS] 
  ELSE 0
 END DC_65_7
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END DF_65_7
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END DFC_65_7
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CPS]
  ELSE 0
 END DN_65_7
 ,F.[SERVICE_REFER_0_CPS] DT_65_7
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_MENTAL] 
  ELSE 0
 END NC_65_8
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_MENTAL] 
  ELSE 0
 END NF_65_8
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_MENTAL] 
  ELSE 0
 END NFC_65_8
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_MENTAL] 
  ELSE 0
 END NN_65_8
 ,F.[SERVICE_USE_0_MENTAL]  NT_65_8
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_MENTAL] 
  ELSE 0
 END DC_65_8
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END DF_65_8
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END DFC_65_8
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_MENTAL]
  ELSE 0
 END DN_65_8
 ,F.[SERVICE_REFER_0_MENTAL] DT_65_8
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
  ELSE 0
 END NC_65_9
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
  ELSE 0
 END NF_65_9
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
  ELSE 0
 END NFC_65_9
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
  ELSE 0
 END NN_65_9
 ,F.[SERVICE_USE_0_RELATIONSHIP_COUNSELING]  NT_65_9
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] 
  ELSE 0
 END DC_65_9
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END DF_65_9
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END DFC_65_9
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
  ELSE 0
 END DN_65_9
 ,F.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] DT_65_9
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_SMOKE] 
  ELSE 0
 END NC_65_10
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_SMOKE] 
  ELSE 0
 END NF_65_10
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_SMOKE] 
  ELSE 0
 END NFC_65_10
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_SMOKE] 
  ELSE 0
 END NN_65_10
 ,F.[SERVICE_USE_0_SMOKE]  NT_65_10
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SMOKE] 
  ELSE 0
 END DC_65_10
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END DF_65_10
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END DFC_65_10
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SMOKE]
  ELSE 0
 END DN_65_10
 ,F.[SERVICE_REFER_0_SMOKE] DT_65_10
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_ALCOHOL_ABUSE] 
  ELSE 0
 END NC_65_11
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_ALCOHOL_ABUSE] 
  ELSE 0
 END NF_65_11
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_ALCOHOL_ABUSE] 
  ELSE 0
 END NFC_65_11
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_ALCOHOL_ABUSE] 
  ELSE 0
 END NN_65_11
 ,F.[SERVICE_USE_0_ALCOHOL_ABUSE]  NT_65_11
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE] 
  ELSE 0
 END DC_65_11
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END DF_65_11
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END DFC_65_11
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_ALCOHOL_ABUSE]
  ELSE 0
 END DN_65_11
 ,F.[SERVICE_REFER_0_ALCOHOL_ABUSE] DT_65_11
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_DRUG_ABUSE] 
  ELSE 0
 END NC_65_12
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_DRUG_ABUSE] 
  ELSE 0
 END NF_65_12
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_DRUG_ABUSE] 
  ELSE 0
 END NFC_65_12
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_DRUG_ABUSE] 
  ELSE 0
 END NN_65_12
 ,F.[SERVICE_USE_0_DRUG_ABUSE]  NT_65_12
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE] 
  ELSE 0
 END DC_65_12
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END DF_65_12
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END DFC_65_12
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_DRUG_ABUSE]
  ELSE 0
 END DN_65_12
 ,F.[SERVICE_REFER_0_DRUG_ABUSE] DT_65_12
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_MEDICAID] 
  ELSE 0
 END NC_65_13
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_MEDICAID] 
  ELSE 0
 END NF_65_13
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_MEDICAID] 
  ELSE 0
 END NFC_65_13
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_MEDICAID] 
  ELSE 0
 END NN_65_13
 ,F.[SERVICE_USE_0_MEDICAID]  NT_65_13
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_MEDICAID] 
  ELSE 0
 END DC_65_13
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END DF_65_13
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END DFC_65_13
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_MEDICAID]
  ELSE 0
 END DN_65_13
 ,F.[SERVICE_REFER_0_MEDICAID] DT_65_13
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_SCHIP] 
  ELSE 0
 END NC_65_14
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_SCHIP] 
  ELSE 0
 END NF_65_14
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_SCHIP] 
  ELSE 0
 END NFC_65_14
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_SCHIP] 
  ELSE 0
 END NN_65_14
 ,F.[SERVICE_USE_0_SCHIP]  NT_65_14
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SCHIP] 
  ELSE 0
 END DC_65_14
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END DF_65_14
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END DFC_65_14
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SCHIP]
  ELSE 0
 END DN_65_14
 ,F.[SERVICE_REFER_0_SCHIP] DT_65_14
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PRIVATE_INSURANCE] 
  ELSE 0
 END NC_65_15
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PRIVATE_INSURANCE] 
  ELSE 0
 END NF_65_15
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PRIVATE_INSURANCE] 
  ELSE 0
 END NFC_65_15
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PRIVATE_INSURANCE] 
  ELSE 0
 END NN_65_15
 ,F.[SERVICE_USE_0_PRIVATE_INSURANCE]  NT_65_15
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE] 
  ELSE 0
 END DC_65_15
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END DF_65_15
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END DFC_65_15
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PRIVATE_INSURANCE]
  ELSE 0
 END DN_65_15
 ,F.[SERVICE_REFER_0_PRIVATE_INSURANCE] DT_65_15
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_SPECIAL_NEEDS] 
  ELSE 0
 END NC_65_16
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_SPECIAL_NEEDS] 
  ELSE 0
 END NF_65_16
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_SPECIAL_NEEDS] 
  ELSE 0
 END NFC_65_16
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_SPECIAL_NEEDS] 
  ELSE 0
 END NN_65_16
 ,F.[SERVICE_USE_0_SPECIAL_NEEDS]  NT_65_16
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS] 
  ELSE 0
 END DC_65_16
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END DF_65_16
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END DFC_65_16
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_SPECIAL_NEEDS]
  ELSE 0
 END DN_65_16
 ,F.[SERVICE_REFER_0_SPECIAL_NEEDS] DT_65_16
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_SICK_CLIENT] 
  ELSE 0
 END NC_65_17
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_SICK_CLIENT] 
  ELSE 0
 END NF_65_17
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PCP_SICK_CLIENT] 
  ELSE 0
 END NFC_65_17
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PCP_SICK_CLIENT] 
  ELSE 0
 END NN_65_17
 ,F.[SERVICE_USE_0_PCP_SICK_CLIENT]  NT_65_17
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT] 
  ELSE 0
 END DC_65_17
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END DF_65_17
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END DFC_65_17
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CLIENT]
  ELSE 0
 END DN_65_17
 ,F.[SERVICE_REFER_0_PCP_SICK_CLIENT] DT_65_17
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_WELL_CLIENT]
  ELSE 0
 END NC_65_18
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_WELL_CLIENT]
  ELSE 0
 END NF_65_18
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PCP_WELL_CLIENT]
  ELSE 0
 END NFC_65_18
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PCP_WELL_CLIENT]
  ELSE 0
 END NN_65_18
 ,F.[SERVICE_USE_0_PCP_WELL_CLIENT] NT_65_18
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT] 
  ELSE 0
 END DC_65_18
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END DF_65_18
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END DFC_65_18
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CLIENT]
  ELSE 0
 END DN_65_18
 ,F.[SERVICE_REFER_0_PCP_WELL_CLIENT] DT_65_18
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_SICK_CHILD]
  ELSE 0
 END NC_65_19
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_SICK_CHILD]
  ELSE 0
 END NF_65_19
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PCP_SICK_CHILD]
  ELSE 0
 END NFC_65_19
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PCP_SICK_CHILD]
  ELSE 0
 END NN_65_19
 ,F.[SERVICE_USE_0_PCP_SICK_CHILD] NT_65_19
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD] 
  ELSE 0
 END DC_65_19
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END DF_65_19
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END DFC_65_19
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_SICK_CHILD]
  ELSE 0
 END DN_65_19
 ,F.[SERVICE_REFER_0_PCP_SICK_CHILD] DT_65_19
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_WELL_CHILD]
  ELSE 0
 END NC_65_20
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PCP_WELL_CHILD]
  ELSE 0
 END NF_65_20
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PCP_WELL_CHILD]
  ELSE 0
 END NFC_65_20
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PCP_WELL_CHILD]
  ELSE 0
 END NN_65_20
 ,F.[SERVICE_USE_0_PCP_WELL_CHILD] NT_65_20
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD] 
  ELSE 0
 END DC_65_20
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END DF_65_20
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END DFC_65_20
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PCP_WELL_CHILD]
  ELSE 0
 END DN_65_20
 ,F.[SERVICE_REFER_0_PCP_WELL_CHILD] DT_65_20
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
  ELSE 0
 END NC_65_21
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
  ELSE 0
 END NF_65_21
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
  ELSE 0
 END NFC_65_21
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
  ELSE 0
 END NN_65_21
 ,F.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY]  NT_65_21
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] 
  ELSE 0
 END DC_65_21
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END DF_65_21
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END DFC_65_21
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
  ELSE 0
 END DN_65_21
 ,F.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] DT_65_21
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_INTERVENTION] 
  ELSE 0
 END NC_65_22
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_INTERVENTION] 
  ELSE 0
 END NF_65_22
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_INTERVENTION] 
  ELSE 0
 END NFC_65_22
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_INTERVENTION] 
  ELSE 0
 END NN_65_22
 ,F.[SERVICE_USE_0_INTERVENTION]  NT_65_22
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_INTERVENTION] 
  ELSE 0
 END DC_65_22
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END DF_65_22
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END DFC_65_22
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_INTERVENTION]
  ELSE 0
 END DN_65_22
 ,F.[SERVICE_REFER_0_INTERVENTION] DT_65_22
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_WIC] 
  ELSE 0
 END NC_65_23
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_WIC] 
  ELSE 0
 END NF_65_23
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_WIC] 
  ELSE 0
 END NFC_65_23
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_WIC] 
  ELSE 0
 END NN_65_23
 ,F.[SERVICE_USE_0_WIC]  NT_65_23
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT] 
  ELSE 0
 END DC_65_23
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END DF_65_23
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END DFC_65_23
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_WIC_CLIENT]
  ELSE 0
 END DN_65_23
 ,F.[SERVICE_REFER_0_WIC_CLIENT] DT_65_23
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_CARE] 
  ELSE 0
 END NC_65_24
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_CARE] 
  ELSE 0
 END NF_65_24
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_CARE] 
  ELSE 0
 END NFC_65_24
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_CARE] 
  ELSE 0
 END NN_65_24
 ,F.[SERVICE_USE_0_CARE]  NT_65_24
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_CARE] 
  ELSE 0
 END DC_65_24
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END DF_65_24
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END DFC_65_24
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CHILD_CARE]
  ELSE 0
 END DN_65_24
 ,F.[SERVICE_REFER_0_CHILD_CARE] DT_65_24
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_JOB_TRAINING] 
  ELSE 0
 END NC_65_25
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_JOB_TRAINING] 
  ELSE 0
 END NF_65_25
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_JOB_TRAINING] 
  ELSE 0
 END NFC_65_25
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_JOB_TRAINING] 
  ELSE 0
 END NN_65_25
 ,F.[SERVICE_USE_0_JOB_TRAINING]  NT_65_25
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING] 
  ELSE 0
 END DC_65_25
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END DF_65_25
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END DFC_65_25
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_JOB_TRAINING]
  ELSE 0
 END DN_65_25
 ,F.[SERVICE_REFER_0_JOB_TRAINING] DT_65_25
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_HOUSING] 
  ELSE 0
 END NC_65_26
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_HOUSING] 
  ELSE 0
 END NF_65_26
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_HOUSING] 
  ELSE 0
 END NFC_65_26
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_HOUSING] 
  ELSE 0
 END NN_65_26
 ,F.[SERVICE_USE_0_HOUSING]  NT_65_26
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_HOUSING] 
  ELSE 0
 END DC_65_26
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END DF_65_26
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END DFC_65_26
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_HOUSING]
  ELSE 0
 END DN_65_26
 ,F.[SERVICE_REFER_0_HOUSING] DT_65_26
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_TRANSPORTATION] 
  ELSE 0
 END NC_65_27
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_TRANSPORTATION] 
  ELSE 0
 END NF_65_27
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_TRANSPORTATION] 
  ELSE 0
 END NFC_65_27
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_TRANSPORTATION] 
  ELSE 0
 END NN_65_27
 ,F.[SERVICE_USE_0_TRANSPORTATION]  NT_65_27
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION] 
  ELSE 0
 END DC_65_27
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END DF_65_27
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END DFC_65_27
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_TRANSPORTATION]
  ELSE 0
 END DN_65_27
 ,F.[SERVICE_REFER_0_TRANSPORTATION] DT_65_27
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PREVENT_INJURY] 
  ELSE 0
 END NC_65_28
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PREVENT_INJURY] 
  ELSE 0
 END NF_65_28
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PREVENT_INJURY] 
  ELSE 0
 END NFC_65_28
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PREVENT_INJURY] 
  ELSE 0
 END NN_65_28
 ,F.[SERVICE_USE_0_PREVENT_INJURY]  NT_65_28
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY] 
  ELSE 0
 END DC_65_28
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END DF_65_28
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END DFC_65_28
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PREVENT_INJURY]
  ELSE 0
 END DN_65_28
 ,F.[SERVICE_REFER_0_PREVENT_INJURY] DT_65_28
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_BIRTH_EDUC_CLASS] 
  ELSE 0
 END NC_65_29
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_BIRTH_EDUC_CLASS] 
  ELSE 0
 END NF_65_29
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_BIRTH_EDUC_CLASS] 
  ELSE 0
 END NFC_65_29
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_BIRTH_EDUC_CLASS] 
  ELSE 0
 END NN_65_29
 ,F.[SERVICE_USE_0_BIRTH_EDUC_CLASS]  NT_65_29
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] 
  ELSE 0
 END DC_65_29
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END DF_65_29
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END DFC_65_29
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
  ELSE 0
 END DN_65_29
 ,F.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] DT_65_29
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_LACTATION] 
  ELSE 0
 END NC_65_30
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_LACTATION] 
  ELSE 0
 END NF_65_30
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_LACTATION] 
  ELSE 0
 END NFC_65_30
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_LACTATION] 
  ELSE 0
 END NN_65_30
 ,F.[SERVICE_USE_0_LACTATION]  NT_65_30
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_LACTATION] 
  ELSE 0
 END DC_65_30
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END DF_65_30
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END DFC_65_30
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_LACTATION]
  ELSE 0
 END DN_65_30
 ,F.[SERVICE_REFER_0_LACTATION] DT_65_30
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_GED] 
  ELSE 0
 END NC_65_31
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_GED] 
  ELSE 0
 END NF_65_31
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_GED] 
  ELSE 0
 END NFC_65_31
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_GED] 
  ELSE 0
 END NN_65_31
 ,F.[SERVICE_USE_0_GED]  NT_65_31
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_GED] 
  ELSE 0
 END DC_65_31
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END DF_65_31
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END DFC_65_31
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_GED]
  ELSE 0
 END DN_65_31
 ,F.[SERVICE_REFER_0_GED] DT_65_31
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_HIGHER_EDUC] 
  ELSE 0
 END NC_65_32
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_HIGHER_EDUC] 
  ELSE 0
 END NF_65_32
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_HIGHER_EDUC] 
  ELSE 0
 END NFC_65_32
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_HIGHER_EDUC] 
  ELSE 0
 END NN_65_32
 ,F.[SERVICE_USE_0_HIGHER_EDUC]  NT_65_32
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC] 
  ELSE 0
 END DC_65_32
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END DF_65_32
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END DFC_65_32
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_HIGHER_EDUC]
  ELSE 0
 END DN_65_32
 ,F.[SERVICE_REFER_0_HIGHER_EDUC] DT_65_32
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_CHARITY] 
  ELSE 0
 END NC_65_33
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_CHARITY] 
  ELSE 0
 END NF_65_33
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_CHARITY] 
  ELSE 0
 END NFC_65_33
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_CHARITY] 
  ELSE 0
 END NN_65_33
 ,F.[SERVICE_USE_0_CHARITY]  NT_65_33
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CHARITY] 
  ELSE 0
 END DC_65_33
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END DF_65_33
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END DFC_65_33
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CHARITY]
  ELSE 0
 END DN_65_33
 ,F.[SERVICE_REFER_0_CHARITY] DT_65_33
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_LEGAL] 
  ELSE 0
 END NC_65_34
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_LEGAL] 
  ELSE 0
 END NF_65_34
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_LEGAL] 
  ELSE 0
 END NFC_65_34
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_LEGAL] 
  ELSE 0
 END NN_65_34
 ,F.[SERVICE_USE_0_LEGAL]  NT_65_34
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT] 
  ELSE 0
 END DC_65_34
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END DF_65_34
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END DFC_65_34
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_LEGAL_CLIENT]
  ELSE 0
 END DN_65_34
 ,F.[SERVICE_REFER_0_LEGAL_CLIENT] DT_65_34
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_PATERNITY] 
  ELSE 0
 END NC_65_35
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_PATERNITY] 
  ELSE 0
 END NF_65_35
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_PATERNITY] 
  ELSE 0
 END NFC_65_35
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_PATERNITY] 
  ELSE 0
 END NN_65_35
 ,F.[SERVICE_USE_0_PATERNITY]  NT_65_35
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_PATERNITY] 
  ELSE 0
 END DC_65_35
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END DF_65_35
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END DFC_65_35
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_PATERNITY]
  ELSE 0
 END DN_65_35
 ,F.[SERVICE_REFER_0_PATERNITY] DT_65_35
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_SUPPORT] 
  ELSE 0
 END NC_65_36
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_SUPPORT] 
  ELSE 0
 END NF_65_36
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_SUPPORT] 
  ELSE 0
 END NFC_65_36
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_SUPPORT] 
  ELSE 0
 END NN_65_36
 ,F.[SERVICE_USE_0_SUPPORT]  NT_65_36
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT] 
  ELSE 0
 END DC_65_36
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END DF_65_36
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END DFC_65_36
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_CHILD_SUPPORT]
  ELSE 0
 END DN_65_36
 ,F.[SERVICE_REFER_0_CHILD_SUPPORT] DT_65_36
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_ADOPTION] 
  ELSE 0
 END NC_65_37
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_ADOPTION] 
  ELSE 0
 END NF_65_37
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_ADOPTION] 
  ELSE 0
 END NFC_65_37
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_ADOPTION] 
  ELSE 0
 END NN_65_37
 ,F.[SERVICE_USE_0_ADOPTION]  NT_65_37
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_ADOPTION] 
  ELSE 0
 END DC_65_37
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END DF_65_37
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END DFC_65_37
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_ADOPTION]
  ELSE 0
 END DN_65_37
 ,F.[SERVICE_REFER_0_ADOPTION] DT_65_37
----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_DENTAL] 
  ELSE 0
 END NC_65_38
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_DENTAL] 
  ELSE 0
 END NF_65_38
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_DENTAL] 
  ELSE 0
 END NFC_65_38
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_DENTAL] 
  ELSE 0
 END NN_65_38
 ,F.[SERVICE_USE_0_DENTAL]  NT_65_38
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_REFER_0_DENTAL] 
  ELSE 0
 END DC_65_38
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END DF_65_38
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END DFC_65_38
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_REFER_0_DENTAL]
  ELSE 0
 END DN_65_38
 ,F.[SERVICE_REFER_0_DENTAL] DT_65_38

----------------------------------------
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERVICE_USE_0_OTHER1] 
  ELSE 0
 END NC_65_40
 ,CASE F.Formula
  WHEN 1 THEN F.[SERVICE_USE_0_OTHER1] 
  ELSE 0
 END NF_65_40
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERVICE_USE_0_OTHER1] 
  ELSE 0
 END NFC_65_40
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERVICE_USE_0_OTHER1] 
  ELSE 0
 END NN_65_40
 ,F.[SERVICE_USE_0_OTHER1]  NT_65_40
 ,CASE F.Competitive
  WHEN 1 THEN F.[SERIVCE_REFER_0_OTHER] 
  ELSE 0
 END DC_65_40
 ,CASE F.Formula
  WHEN 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END DF_65_40
 ,CASE
  WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END DFC_65_40
 ,CASE 
  WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[SERIVCE_REFER_0_OTHER]
  ELSE 0
 END DN_65_40
 ,F.[SERIVCE_REFER_0_OTHER] DT_65_40


FROM FHVI F


END
GO
