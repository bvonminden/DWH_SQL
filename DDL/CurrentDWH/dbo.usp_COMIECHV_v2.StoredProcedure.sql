USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_COMIECHV_v2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_COMIECHV_v2]
(	
	@StartDate		DATE		--= '20140101'
	,@EndDate		DATE		--= '20141231'
	,@SiteID		VARCHAR(4000)--= '109,110,111,112,113,114,140,141,142,143,144,145,146,147,148,149,150,151,279,371,372'
	,@FundingType	INT			--= 1 --- 1 = Competitive; 2 = Formula
)

AS

 

SET NOCOUNT ON 


--DECLARE 
--	@StartDate		DATE		= '20140101'
--	,@EndDate		DATE		= '20141231'
--	,@SiteID		VARCHAR(4000)= '109,110,111,112,113,114,140,141,142,143,144,145,146,147,148,149,150,151,279,371,372'
--	,@FundingType	INT			= 1 --- 1 = Competitive; 2 = Formula


SELECT 


--------------------------------------------Benchmark 1----------------------------------------------------------------------
	ROOT.ProgramID
	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB -- pregnant client
			AND ((ROOT.EndDate IS NULL AND ROOT.ProgramStartDate < DATEADD(Day,-84,@EndDate)) OR ROOT.EndDate > DATEADD(DAY,84,ROOT.ProgramStartDate)) -- (client is active at least 84 days)
			AND GCSS_Intake.CL_EN_GEN_ID IS NOT NULL -- client has GCSS intake
			AND GCSS_Intake.SERVICE_USE_PCP_CLIENT_PRENATAL <> 2
			AND GCSS_Intake.SERVICE_USE_PCP_CLIENT_WELLWOMAN <> 2
		THEN ROOT.CLID
	END) B1C1_T
	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB -- pregnant client
			AND ((ROOT.EndDate IS NULL AND ROOT.ProgramStartDate < DATEADD(Day,-84,@EndDate)) OR ROOT.EndDate > DATEADD(DAY,84,ROOT.ProgramStartDate)) -- (client is active at least 84 days)
			AND GCSS_Intake.CL_EN_GEN_ID IS NOT NULL -- client has GCSS intake
			AND HVES.Prenatal = 1
		THEN ROOT.CLID
	END) B1C1_T1
	,COUNT(DISTINCT CASE 
		WHEN HHS_Intake.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS intake data on smoking
			AND HHS_36.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS 36 data on smoking
			AND HHS_36.SurveyDate BETWEEN @StartDate AND @EndDate -- client has HHS 36 during period
			AND HHS_Intake.CLIENT_SUBSTANCE_CIG_1_LAST_48 >= 0 -- Tabacoo use at intake
		THEN ROOT.CLID
	END) B1C2_T
	,COUNT(DISTINCT CASE 
		WHEN HHS_Intake.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS intake data on smoking
			AND HHS_36.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS 36 data on smoking
			AND HHS_36.SurveyDate BETWEEN @StartDate AND @EndDate -- client has HHS 36 during period
			AND HHS_36.CLIENT_SUBSTANCE_CIG_1_LAST_48 >= 0 -- Tabacoo use at 36w
		THEN ROOT.CLID
	END) B1C2_T2
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate --GCSS inf 6 form during period
			AND GCSS_inf6.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN('2','5') --had pcp visit
			AND GCSS_inf6.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN('2','5') -- had pcp visit
		THEN ROOT.CLID
	END) B1C3_N
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate --GCSS inf 6 form during period
		THEN ROOT.CLID
	END) B1C3_D
	,COUNT(DISTINCT CASE 
		WHEN DS.SurveyDate BETWEEN @StartDate AND @EndDate --DS form during period
			AND DS.CLIENT_BC_0_USED_6MONTHS IS NOT NULL -- answered birth control question
		THEN ROOT.CLID
	END) B1C4_N
	,COUNT(DISTINCT CASE 
		WHEN DS.SurveyDate BETWEEN @StartDate AND @EndDate --DS form during period
		THEN ROOT.CLID
	END) B1C4_D
	
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @StartDate AND @EndDate --child reached 6 months during time frame (IHS 6 survey present)
			AND B1C5.SurveyDate BETWEEN @StartDate AND @EndDate -- Last edinburgh or last phq9 (prior to enddate) during the time frame
		THEN ROOT.CLID
	END) B1C5_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @StartDate AND @EndDate --child reached 6 months during time frame (IHS 6 survey present)
		THEN ROOT.CLID
	END) B1C5_D

	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB --enrolled prior to birth
			AND IBS.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
			AND IBS.INFANT_BREASTMILK_0_EVER_BIRTH = 'Yes'
		THEN ROOT.CLID
	END) B1C6_N
	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB --enrolled prior to birth
			AND IBS.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
		THEN ROOT.CLID
	END) B1C6_D
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
			AND INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' -- recieved well child visit
		THEN ROOT.CLID
	END) B1C7_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
		THEN ROOT.CLID
	END) B1C7_D
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate IS NOT NULL -- GCSS inf 6 present
			AND GCSS_Intake.SurveyDate IS NOT NULL -- GCSS intake present
			AND GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2'
			AND GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2'
			AND GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' 
			AND GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2'
			AND GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2'   
			AND GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2'
			AND GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD <> '2'   
			AND GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2'
		THEN ROOT.CLID
	END) B1C8_T
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 form during period
			AND GCSS_Intake.SurveyDate IS NOT NULL -- GCSS intake present
			AND GCSS_inf6.SERVICE_USE_0_MEDICAID_CLIENT IN('2','5')
			AND GCSS_inf6.SERVICE_USE_0_MEDICAID_CHILD IN('2','5')
			AND GCSS_inf6.SERVICE_USE_0_SCHIP_CHILD IN('2','5')
			AND GCSS_inf6.SERVICE_USE_0_SCHIP_CLIENT IN('2','5')
			AND GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN('2','5')  
			AND GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN('2','5')
			AND GCSS_inf6.SERVICE_USE_MILITARY_INS_CHILD  <> '2'
			AND GCSS_inf6.[SERVICE_USE_MILITARY_INS_CLIENT ] IN('2','5')
		THEN ROOT.CLID
	END) B1C8_T1

--------------------------------------------Benchmark 2----------------------------------------------------------------------

	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c1.ER_Yes_c1 = 1 OR IHS_all_c1.ERO_Yes_c1 = 1)  -- had er visit during first six months
		THEN ROOT.CLID
	END) B2C1_N_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c2.ER_Yes_c2 = 1 OR IHS_all_c2.ERO_Yes_c2 = 1)  -- had er visit during last six months
		THEN ROOT.CLID
	END) B2C1_N_c2
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C1_D_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C1_D_c2

	,COUNT(DISTINCT CASE 
		WHEN DS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND DS_all_c1.ER_Yes_c1 = 1  -- had er visit during first six months
		THEN ROOT.CLID
	END) B2C2_N_c1
	,COUNT(DISTINCT CASE 
		WHEN DS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND DS_all_c2.ER_Yes_c2 = 1  -- had er visit during last six months
		THEN ROOT.CLID
	END) B2C2_N_c2
	,COUNT(DISTINCT CASE 
		WHEN DS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C2_D_c1
	,COUNT(DISTINCT CASE 
		WHEN DS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C2_D_c2
	
	,COUNT(DISTINCT CASE 
		WHEN HVES.Visit_365 = 1 --client had visit during 365 days after start
			AND HVES.injury_prev = 1  -- had injury prev training with 365 days of enrollment
		THEN ROOT.CLID
	END) B2C3_N
	,COUNT(DISTINCT CASE 
		WHEN HVES.Visit_365 = 1 --client had visit during 365 days after start
		THEN ROOT.CLID
	END) B2C3_D

	
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c1.ER_Yes_c1 = 1 OR IHS_all_c1.ER_Injury_c1 = 1)  -- had er visit during first six months and it was injury
		THEN ROOT.CLID
	END) B2C4_N_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c2.ER_Yes_c2 = 1 OR IHS_all_c2.ER_Injury_c2 = 1)  -- had er visit during last six months and it was injury
		THEN ROOT.CLID
	END) B2C4_N_c2
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C4_D_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C4_D_c2

	,COUNT(DISTINCT CASE 
		WHEN IHS_12.SurveyDate BETWEEN @Startdate AND @EndDate --client had survey during time period
			AND IHS_12.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes' -- had maltreatment referral
			AND IHS_12.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
		THEN ROOT.CLID
	END) B2C5_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_12.SurveyDate BETWEEN @Startdate AND @EndDate--client had survey during time period
		THEN ROOT.CLID
	END) B2C5_D


--------------------------------------------Benchmark 3----------------------------------------------------------------------


	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @Startdate AND @EndDate --client had survey during time period
			AND IHS_6.INFANT_HOME_1_LEARNING IS NOT NULL -- Learning on HOME reported
		THEN ROOT.CLID
	END) B3C1_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @Startdate AND @EndDate --client had survey during time period
		THEN ROOT.CLID
	END) B3C1_D
	
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported (and has survey)
			AND IHS_18.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported
		THEN ROOT.CLID
	END) B3C2_T
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported (and has survey)
			AND IHS_18.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported
			AND IHS_18.INFANT_HOME_0_TOTAL_calc > IHS_6.INFANT_HOME_0_TOTAL_calc -- increase in score
		THEN ROOT.CLID
	END) B3C2_T1
	
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_1_ACCEPTANCE IS NOT NULL-- HOME ACC reported (and has survey)
			AND IHS_6.INFANT_HOME_1_RESPONSIVITY IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_ACCEPTANCE IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_RESPONSIVITY IS NOT NULL
		THEN ROOT.CLID
	END) B3C3_T
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_1_ACCEPTANCE IS NOT NULL-- HOME ACC reported (and has survey)
			AND IHS_6.INFANT_HOME_1_RESPONSIVITY IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_ACCEPTANCE IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_RESPONSIVITY IS NOT NULL
			AND IHS_18.INFANT_HOME_1_ACCEPTANCE > IHS_6.INFANT_HOME_1_ACCEPTANCE  -- acc increased
			AND IHS_18.INFANT_HOME_1_RESPONSIVITY > IHS_6.INFANT_HOME_1_RESPONSIVITY -- resp increased
		THEN ROOT.CLID
	END) B3C3_T1

	-----B3C4_N and B3C4_D are same as B1C5_N and B1C5_D
	
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND (ASQ_410.INFANT_AGES_STAGES_1_COMM = 1 OR ASQ_410.INFANT_AGES_STAGES_1_COMM = 1) 
		THEN ROOT.CLID
	END) B3C5_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND (ASQ_410.INFANT_AGES_STAGES_1_PSOLVE = 1 OR ASQ_410.INFANT_HEALTH_NO_ASQ_PROBLEM = 1) 
		THEN ROOT.CLID
	END) B3C6_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND (ASQ_410.INFANT_AGES_STAGES_1_PSOCIAL = 1 OR ASQ_410.INFANT_HEALTH_NO_ASQ_PERSONAL = 1) 
		THEN ROOT.CLID
	END) B3C7_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND ((ASQ_410.INFANT_AGES_STAGES_1_GMOTOR = 1 AND ASQ_410.INFANT_AGES_STAGES_1_FMOTOR = 1) OR (ASQ_410.INFANT_HEALTH_NO_ASQ_GROSS = 1 AND ASQ_410.INFANT_HEALTH_NO_ASQ_FINE = 1))
		THEN ROOT.CLID
	END) B3C9_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
		THEN ROOT.CLID
	END) B3C5679_D

	
	,COUNT(DISTINCT CASE 
		WHEN IHS_ASQ.CL_EN_GEN_ID IS NOT NULL -- has IHS 6 or 12 survey during period
			AND (IHS_ASQ.INFANT_AGES_STAGES_SE_0_EMOTIONAL = 1 OR IHS_ASQ.INFANT_HEALTH_NO_ASQ_TOTAL = 1) -- HOME ACC reported (and has survey)
		THEN ROOT.CLID
	END) B3C8_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_ASQ.CL_EN_GEN_ID IS NOT NULL -- has IHS 6 or 12 survey during period
		THEN ROOT.CLID
	END) B3C8_D


-------------------------------------------- Benchmark 4 ---------------------------------------------------------------------

	
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
		THEN ROOT.CLID
	END) B4C3_N
	,COUNT(DISTINCT ROOT.CLID) B4C3_D
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
			AND Referrals.SERVICE_REFER_0_IPV = 1 
		THEN ROOT.CLID
	END) B4C4_N
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
			AND HVES.Safety_Plan_1yr = 1 --- Safety Plan within 1 year
		THEN ROOT.CLID
	END) B4C5_N
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
			AND RS_i36.DV_ident = 1 --- Domestic violence identified on intake or 36 rs
		THEN ROOT.CLID
	END) B4C45_D
	
-------------------------------------------- Benchmark 5 ---------------------------------------------------------------------

	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate -- client has DS intake at some point and DS 12 during time frame
		THEN ROOT.CLID
	END) B5C1_T
	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate -- client has DS intake at some point and DS 12 during time frame
			AND DS_in.CLIENT_INCOME_AMOUNT < DS_12.CLIENT_INCOME_AMOUNT  --- income increased
		THEN ROOT.CLID
	END) B5C1_T1
	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate  -- client has DS intake at some point and DS 12 during time frame
			AND DS_in.CLIENT_EDUCATION_1_ENROLLED_PLAN IS NOT NULL AND DS_12.CLIENT_EDUCATION_1_ENROLLED_PLAN IS NOT NULL --- answered education
		THEN ROOT.CLID
	END) B5C2_T
	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate  -- client has DS intake at some point and DS 12 during time frame
			AND (
				(DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - middle school (6th - 8th grades)' AND DS_in.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE < DS_12.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE AND DS_12.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - middle school (6th - 8th grades)') 
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - middle school (6th - 8th grades)' AND DS_12.CLIENT_SCHOOL_MIDDLE_HS IN( 'Yes - high school or GED program (includes alternative and technical programs)','Yes - completed GED'))
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)' AND DS_in.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE < DS_12.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE AND DS_12.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)') 
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)' AND DS_12.CLIENT_EDUCATION_0_HS_GED IN( 'Yes - completed high school','Yes - completed GED','Yes - completed vocational/certification program'))
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)' AND DS_12.CLIENT_EDUCATION_0_HS_GED = 'Yes - completed high school')
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Not enrolled' AND DS_12.CLIENT_SCHOOL_MIDDLE_HS IN('Yes - middle school (6th - 8th grades)','Yes - high school or GED program (includes alternative and technical programs)'))
			OR (DS_in.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'No' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes')
			OR (DS_in.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes' AND DS_in.CLIENT_EDUCATION_1_ENROLLED_FTPT = 'Part Time' AND DS_in.CLIENT_EDUCATION_1_ENROLLED_PT_HRS = '6 or less semester hours or equivalent' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_FTPT = 'Part Time' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS = '7 - 11 semester hours or equivalent')
			OR (DS_in.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP < DS_12.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP)
			)
		THEN ROOT.CLID
	END) B5C2_T1
	,COUNT(DISTINCT CASE 
		WHEN GCSS_Intake.CL_EN_GEN_ID IS NOT NULL AND GCSS_inf6.CL_EN_GEN_ID IS NOT NULL -- data at both intake and 6months on GCSS
			AND (GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
			AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
			AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CHILD] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CHILD] IS NULL)
		THEN ROOT.CLID
	END) B5C3_T
	,COUNT(DISTINCT CASE 
		WHEN GCSS_Intake.CL_EN_GEN_ID IS NOT NULL AND GCSS_inf6.CL_EN_GEN_ID IS NOT NULL AND GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate --- data at both intake and 6months on GCSS and GCSS 6 mo during period
			AND (GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL) --no insurance intake
			AND (GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
			AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
			AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CHILD] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CHILD] IS NULL)
			
			AND (GCSS_inf6.SERVICE_USE_0_MEDICAID_CLIENT IN ('2','5') -- insurance at 6 mo
			OR GCSS_inf6.SERVICE_USE_0_MEDICAID_CHILD IN ('2','5')
			OR GCSS_inf6.SERVICE_USE_0_SCHIP_CLIENT IN ('2','5')
			OR GCSS_inf6.SERVICE_USE_0_SCHIP_CHILD IN ('2','5')
			OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN ('2','5')
			OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN ('2','5')
			OR GCSS_inf6.[SERVICE_USE_MILITARY_INS_CLIENT ] IN ('2','5')
			OR GCSS_inf6.[SERVICE_USE_MILITARY_INS_CHILD] IN ('2','5') )
		THEN ROOT.CLID
	END) B5C3_T1


	
-------------------------------------------- Benchmark 5 ---------------------------------------------------------------------

	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND HVES.No_Ref = 1 --- client screened or no referral
		THEN ROOT.CLID
	END) B6C1_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
		THEN ROOT.CLID
	END) B6C1_D
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND HVES.No_Ref = 1 --- client screened or no referral
			AND Referrals.CL_EN_GEN_ID IS NOT NULL
		THEN ROOT.CLID
	END) B6C2_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND HVES.No_Ref = 1 --- client screened or no referral
		THEN ROOT.CLID
	END) B6C2_D
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND HVES.No_Ref = 1 --- client screened or no referral
			-- need to add more logic
		THEN ROOT.CLID
	END) B6C5_N



FROM 

(SELECT 
	EAD.CLID
	,EAD.ProgramID 
	,EAD.SiteID
	,EAD.ProgramStartDate
	,EAD.EndDate
	,EAD.ReasonForDismissal
	,EAD.RecID
	,EAD.CaseNumber
FROM UV_EADT EAD
WHERE RankingLatest = 1) ROOT

LEFT JOIN 
	(SELECT 
		CFS.CL_EN_GEN_ID
		,CFS.ProgramID
		,MAX(CASE WHEN CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 1 END) Comp
		,MAX(CASE WHEN CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 1 END) Form
	FROM [DataWarehouse].[dbo].[Client_Funding_Survey] CFS -- logic regarding funding
	WHERE CFS.CLIENT_FUNDING_1_START_MIECHVP_COM >= '10/1/2010'
		OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM >= '10/1/2010'
		AND CFS.SurveyDate <= @EndDate
	GROUP BY CFS.CL_EN_GEN_ID ,CFS.ProgramID) CFS
	ON CFS.CL_EN_GEN_ID = ROOT.CLID
	AND CFS.ProgramID = ROOT.ProgramID

LEFT JOIN ---- Adds infant DOB
	(SELECT 
		I.CL_EN_GEN_ID
		,I.ProgramID
		,(I.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
		,I.SurveyDate
		,I.INFANT_BREASTMILK_0_EVER_BIRTH
		,RANK() OVER(Partition By I.CL_EN_GEN_ID,I.ProgramID Order By I.SurveyDate DESC,I.SurveyResponseID DESC) Rank
	FROM Infant_Birth_Survey I
	WHERE I.INFANT_BIRTH_0_DOB IS NOT NULL
	AND I.SurveyDate <= @EndDate) IBS
	ON ROOT.CLID = IBS.CL_EN_GEN_ID
	AND ROOT.ProgramID = IBS.ProgramID
	AND IBS.Rank = 1

LEFT JOIN
	(SELECT 
		HVES.CL_EN_GEN_ID
		,HVES.ProgramID
		,MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS = 'Yes' 
					AND HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,84,C.ProgramStartDate)
				  THEN 1 END) Prenatal
		,MAX(CASE WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes' 
					AND HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,365,C.ProgramStartDate)
				  THEN 1 END) injury_prev
		,MAX(CASE WHEN HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,365,C.ProgramStartDate) 
				  THEN 1 END) Visit_365
		,MAX(CASE WHEN HVES.SurveyDate > DATEADD(MONTH,12,C.ProgramStartDate)
				  THEN 1 END) Visit_After12m
		,MAX(CASE WHEN CLIENT_IPV_0_SAFETY_PLAN = 'Yes' AND HVES.SurveyDate < DATEADD(MONTH,12,C.ProgramStartDate)
				  THEN 1 END) Safety_Plan_1yr
		,MAX(CASE WHEN (CLIENT_SCREENED_SRVCS = 'Yes' OR CLIENT_NO_REFERRAL = 'No referral needed') AND HVES.SurveyDate < DATEADD(MONTH,12,C.ProgramStartDate)
				  THEN 1 END) No_Ref
	FROM Home_Visit_Encounter_Survey HVES
	LEFT JOIN
		(SELECT 
			EAD.CLID
			,EAD.ProgramID 
			,EAD.ProgramStartDate
		FROM UV_EADT EAD
		WHERE RankingLatest = 1) C ON HVES.CL_EN_GEN_ID = C.CLID AND HVES.ProgramID = C.ProgramID
	--WHERE HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,84,C.ProgramStartDate)
	WHERE HVES.SurveyDate <= @EndDate
	GROUP BY 
		HVES.CL_EN_GEN_ID
		,HVES.ProgramID) HVES
	ON HVES.ProgramID = ROOT.ProgramID
	AND HVES.CL_EN_GEN_ID = ROOT.CLID

LEFT JOIN  --- GCSS intake flags
	(SELECT 
		GCSS.ProgramID
		,GCSS.CL_EN_GEN_ID
		,GCSS.SurveyDate
		,RANK() OVER(PARTITION BY GCSS.ProgramID,GCSS.CL_EN_GEN_ID ORDER BY GCSS.SurveyDate DESC,GCSS.SurveyResponseID DESC) rank
		,GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL
		,GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN
		,GCSS.SERVICE_USE_0_MEDICAID_CLIENT
		,GCSS.SERVICE_USE_0_MEDICAID_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CLIENT
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT
		,GCSS.SERVICE_USE_MILITARY_INS_CHILD
		,GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ]
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE dbo.fnGetFormName(GCSS.SurveyID) = 'Use of Government & Community Services-Intake'
	AND GCSS.SurveyDate <= @EndDate) GCSS_Intake
	ON ROOT.CLID = GCSS_Intake.CL_EN_GEN_ID
	AND ROOT.ProgramID = GCSS_Intake.ProgramID
	AND GCSS_Intake.rank = 1
	

LEFT JOIN  --- GCSS_inf6 flags
	(SELECT 
		GCSS.ProgramID
		,GCSS.CL_EN_GEN_ID
		,GCSS.SurveyDate
		,RANK() OVER(PARTITION BY GCSS.ProgramID,GCSS.CL_EN_GEN_ID ORDER BY GCSS.SurveyDate DESC,GCSS.SurveyResponseID DESC) rank
		,GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL
		,GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN
		,GCSS.SERVICE_USE_0_MEDICAID_CLIENT
		,GCSS.SERVICE_USE_0_MEDICAID_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CLIENT
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT
		,GCSS.SERVICE_USE_MILITARY_INS_CHILD
		,GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ]
		,GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE dbo.fnGetFormName(GCSS.SurveyID) = 'Use of Government & Community Services-Infancy 6'
	AND GCSS.SurveyDate <= @EndDate) GCSS_inf6
	ON ROOT.CLID = GCSS_inf6.CL_EN_GEN_ID
	AND ROOT.ProgramID = GCSS_inf6.ProgramID
	AND GCSS_inf6.rank = 1

LEFT JOIN
	(SELECT 
		HHS.ProgramID
		,HHS.CL_EN_GEN_ID
		,HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
		,RANK() OVER(PARTITION BY HHS.ProgramID,HHS.CL_EN_GEN_ID ORDER BY HHS.SurveyDate DESC,HHS.SurveyResponseID DESC) rank
	FROM Health_Habits_Survey HHS
	WHERE dbo.fnGetFormName(HHS.SurveyID) = 'Health Habits: Pregnancy-Intake'
	AND HHS.SurveyDate <= @EndDate) HHS_Intake
	ON ROOT.CLID = HHS_Intake.CL_EN_GEN_ID
	AND ROOT.ProgramID = HHS_Intake.ProgramID
	AND HHS_Intake.rank = 1

LEFT JOIN
	(SELECT 
		HHS.ProgramID
		,HHS.CL_EN_GEN_ID
		,HHS.SurveyDate
		,HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
		,RANK() OVER(PARTITION BY HHS.ProgramID,HHS.CL_EN_GEN_ID ORDER BY HHS.SurveyDate DESC,HHS.SurveyResponseID DESC) rank
	FROM Health_Habits_Survey HHS
	WHERE dbo.fnGetFormName(HHS.SurveyID) = 'Health Habits: Pregnancy-36 Weeks'
	AND HHS.SurveyDate <= @EndDate) HHS_36
	ON ROOT.CLID = HHS_36.CL_EN_GEN_ID
	AND ROOT.ProgramID = HHS_36.ProgramID
	AND HHS_36.rank = 1

LEFT JOIN
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,IHS.SurveyDate
		,IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2
		,IHS.INFANT_HOME_1_LEARNING
		,CASE WHEN NOT(IHS.INFANT_HOME_1_ACCEPTANCE IS NULL
				AND IHS.INFANT_HOME_1_EXPERIENCE IS NULL
				AND IHS.INFANT_HOME_1_INVOLVEMENT IS NULL
				AND IHS.INFANT_HOME_1_LEARNING IS NULL
				AND IHS.INFANT_HOME_1_ORGANIZATION IS NULL
				AND IHS.INFANT_HOME_1_RESPONSIVITY IS NULL)
			 THEN ISNULL(IHS.INFANT_HOME_1_ACCEPTANCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_EXPERIENCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_INVOLVEMENT,0) + 
				ISNULL(IHS.INFANT_HOME_1_LEARNING,0) + 
				ISNULL(IHS.INFANT_HOME_1_ORGANIZATION,0) + 
				ISNULL(IHS.INFANT_HOME_1_RESPONSIVITY,0) 
		END INFANT_HOME_0_TOTAL_calc --- calculated total with all nulls set to null
		,IHS.INFANT_HOME_1_ACCEPTANCE
		,IHS.INFANT_HOME_1_RESPONSIVITY
		,RANK() OVER(PARTITION BY IHS.ProgramID,IHS.CL_EN_GEN_ID ORDER BY IHS.SurveyDate DESC,IHS.SurveyResponseID DESC) rank
	FROM Infant_Health_Survey IHS
	WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'
		AND IHS.SurveyDate <= @EndDate) IHS_6
	ON ROOT.CLID = IHS_6.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_6.ProgramID
	AND IHS_6.rank = 1

LEFT JOIN
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,IHS.SurveyDate
		,IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL
		,IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL
		,RANK() OVER(PARTITION BY IHS.ProgramID,IHS.CL_EN_GEN_ID ORDER BY IHS.SurveyDate DESC,IHS.SurveyResponseID DESC) rank
	FROM Infant_Health_Survey IHS
	WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'
	AND IHS.SurveyDate <= @EndDate) IHS_12
	ON ROOT.CLID = IHS_12.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_12.ProgramID
	AND IHS_12.rank = 1

LEFT JOIN
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,IHS.SurveyDate
		,CASE WHEN NOT(IHS.INFANT_HOME_1_ACCEPTANCE IS NULL
				AND IHS.INFANT_HOME_1_EXPERIENCE IS NULL
				AND IHS.INFANT_HOME_1_INVOLVEMENT IS NULL
				AND IHS.INFANT_HOME_1_LEARNING IS NULL
				AND IHS.INFANT_HOME_1_ORGANIZATION IS NULL
				AND IHS.INFANT_HOME_1_RESPONSIVITY IS NULL)
			 THEN ISNULL(IHS.INFANT_HOME_1_ACCEPTANCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_EXPERIENCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_INVOLVEMENT,0) + 
				ISNULL(IHS.INFANT_HOME_1_LEARNING,0) + 
				ISNULL(IHS.INFANT_HOME_1_ORGANIZATION,0) + 
				ISNULL(IHS.INFANT_HOME_1_RESPONSIVITY,0) 
		END INFANT_HOME_0_TOTAL_calc --- calculated total with all nulls set to null
		,IHS.INFANT_HOME_1_ACCEPTANCE
		,IHS.INFANT_HOME_1_RESPONSIVITY
		,RANK() OVER(PARTITION BY IHS.ProgramID,IHS.CL_EN_GEN_ID ORDER BY IHS.SurveyDate DESC,IHS.SurveyResponseID DESC) rank
	FROM Infant_Health_Survey IHS
	WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'
		AND IHS.SurveyDate <= @EndDate) IHS_18
	ON ROOT.CLID = IHS_18.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_18.ProgramID
	AND IHS_18.rank = 1


LEFT JOIN ---- ER Visits during first six months of enrollment
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes' 
				  THEN 1 END) ER_Yes_c1
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes' 
				  THEN 1 END) ERO_Yes_c1
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_TYPE = 'Injury' 
				  THEN 1 END) ER_Injury_c1
	FROM Infant_Health_Survey IHS
	WHERE IHS.SurveyDate >= @StartDate AND IHS.SurveyDate <= DATEADD(MONTH,6,@StartDate) AND IHS.SurveyDate <= @EndDate
	GROUP BY IHS.ProgramID, IHS.CL_EN_GEN_ID) IHS_all_c1
	ON ROOT.CLID = IHS_all_c1.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_all_c1.ProgramID

LEFT JOIN ---- ER Visits during last six months of enrollment
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes' 
				  THEN 1 END) ER_Yes_c2
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes' 
				  THEN 1 END) ERO_Yes_c2
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_TYPE = 'Injury' 
				  THEN 1 END) ER_Injury_c2
	FROM Infant_Health_Survey IHS
	WHERE IHS.SurveyDate >= @StartDate AND IHS.SurveyDate >= DATEADD(MONTH,-6,@EndDate) AND IHS.SurveyDate <= @EndDate
	GROUP BY IHS.ProgramID, IHS.CL_EN_GEN_ID) IHS_all_c2
	ON ROOT.CLID = IHS_all_c2.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_all_c2.ProgramID
	

LEFT JOIN ---- client ER Visits during first six months of enrollment
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = 'Yes' 
				  THEN 1 END) ER_Yes_c1
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = 'Yes' 
				  THEN 1 END) ER_Yes_c2
	FROM Demographics_Survey DS
	WHERE DS.SurveyDate >= @StartDate AND DS.SurveyDate <= DATEADD(MONTH,6,@StartDate) AND DS.SurveyDate <= @EndDate
	GROUP BY DS.ProgramID, DS.CL_EN_GEN_ID) DS_all_c1
	ON ROOT.CLID = DS_all_c1.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_all_c1.ProgramID

LEFT JOIN ---- client ER Visits during last six months of enrollment
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = 'Yes' 
				  THEN 1 END) ER_Yes_c1
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = 'Yes' 
				  THEN 1 END) ER_Yes_c2
	FROM Demographics_Survey DS
	WHERE DS.SurveyDate >= @StartDate AND DS.SurveyDate >= DATEADD(MONTH,-6,@EndDate) AND DS.SurveyDate <= @EndDate
	GROUP BY DS.ProgramID, DS.CL_EN_GEN_ID) DS_all_c2
	ON ROOT.CLID = DS_all_c2.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_all_c2.ProgramID

LEFT JOIN
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,DS.SurveyDate
		,DS.CLIENT_BC_0_USED_6MONTHS
		,RANK() OVER(PARTITION BY DS.ProgramID,DS.CL_EN_GEN_ID ORDER BY DS.SurveyDate DESC,DS.SurveyResponseID DESC) rank
	FROM Demographics_Survey DS
	WHERE DS.SurveyDate <= @EndDate) DS
	ON ROOT.CLID = DS.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS.ProgramID
	AND DS.rank = 1
	
LEFT JOIN
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,DS.SurveyDate
		,DS.CLIENT_INCOME_AMOUNT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PLAN
		,DS.CLIENT_SCHOOL_MIDDLE_HS
		,DS.CLIENT_EDUCATION_0_HS_GED
		,DS.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
		,DS.CLIENT_EDUCATION_1_ENROLLED_CURRENT
		,DS.CLIENT_ED_PROG_TYPE
		,DS.CLIENT_EDUCATION_1_ENROLLED_FTPT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PT_HRS
		,CASE WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP = 'No' THEN 0
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Vocational%' THEN 1
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Some college%' THEN 2
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Associate%' THEN 3
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Bachelor%' THEN 4
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Master%' THEN 5
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Doctorate%' THEN 6
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Professional%' THEN 6
		END CLIENT_EDUCATION_1_HIGHER_EDUC_COMP
		,RANK() OVER(PARTITION BY DS.ProgramID,DS.CL_EN_GEN_ID ORDER BY DS.SurveyDate DESC,DS.SurveyResponseID DESC) rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) IN ('Demographics: Pregnancy Intake')
	AND DS.SurveyDate <= @EndDate) DS_in
	ON ROOT.CLID = DS_in.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_in.ProgramID
	AND DS_in.rank = 1



LEFT JOIN -- DS 12 during period
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,DS.SurveyDate
		,DS.CLIENT_INCOME_AMOUNT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PLAN
		,DS.CLIENT_SCHOOL_MIDDLE_HS
		,DS.CLIENT_EDUCATION_0_HS_GED
		,DS.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
		,DS.CLIENT_EDUCATION_1_ENROLLED_CURRENT
		,DS.CLIENT_ED_PROG_TYPE
		,DS.CLIENT_EDUCATION_1_ENROLLED_FTPT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PT_HRS
		,CASE WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP = 'No' THEN 0
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Vocational%' THEN 1
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Some college%' THEN 2
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Associate%' THEN 3
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Bachelor%' THEN 4
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Master%' THEN 5
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Doctorate%' THEN 6
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Professional%' THEN 6
		END CLIENT_EDUCATION_1_HIGHER_EDUC_COMP
		,RANK() OVER(PARTITION BY DS.ProgramID,DS.CL_EN_GEN_ID ORDER BY DS.SurveyDate DESC,DS.SurveyResponseID DESC) rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) IN ('Demographics Update: Infancy 12 Months')
		AND DS.SurveyDate <= @EndDate) DS_12
	ON ROOT.CLID = DS_12.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_12.ProgramID
	AND DS_12.rank = 1

	
LEFT OUTER JOIN --Most recent instance of client being screened for depression w/ edinburgh prior to 6 mos
	(SELECT CL_EN_GEN_ID, MAX(SurveyDate) SurveyDate, ProgramID
	FROM 
	(SELECT PH.CL_EN_GEN_ID, PH.SurveyDate, ProgramID
	FROM PHQ_Survey  PH
	WHERE DBO.fnGetFormName(PH.SurveyID) IN ('PHQ-9-Infancy 4-6 mos'
											,'PHQ-9-Infancy 1-4 wks'
											,'PHQ-9-Intake'
											,'PHQ-9-Infancy 1-8 wks'
											,'PHQ-9-Pregnancy 36 wks')
	
	UNION

	SELECT ES.CL_EN_GEN_ID, ES.SurveyDate, ProgramID
	FROM Edinburgh_Survey  ES
	WHERE DBO.fnGetFormName(ES.SurveyID) IN ('Edinburgh Postnatal Depression-Infancy 4-6 mos'
											,'Edinburgh Postnatal Depression-Pregnancy-36 wks'
											,'Edinburgh Postnatal Depression-Infancy 1-8 wks'
											,'Edinburgh Postnatal Depression-Infancy 1-4 wks'
											,'Edinburgh Postnatal Depression-Intake')
	) Data
	WHERE Data.SurveyDate < @EndDate
	GROUP BY ProgramID,CL_EN_GEN_ID) B1C5
	ON ROOT.CLID = B1C5.CL_EN_GEN_ID
	AND ROOT.ProgramID = B1C5.ProgramID

LEFT JOIN
	(SELECT 
		PHQ.CL_EN_GEN_ID
		,PHQ.ProgramID
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_COMM
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_COMM
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_PSOLVE
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_PROBLEM
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_PSOCIAL
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_PERSONAL
		--,PHQ.INFANT_AGES_STAGES_SE_0_EMOTIONAL
		--,PHQ.INFANT_HEALTH_NO_ASQ_TOTAL
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_GMOTOR
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_FMOTOR
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_GROSS
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_FINE

	FROM ASQ3_Survey PHQ
	WHERE dbo.fnGetFormName(PHQ.SurveyID) IN ('ASQ-3: Infancy 4 Months','ASQ-3: Infancy 10 Months')
		AND PHQ.SurveyDate <= @EndDate
	GROUP BY PHQ.CL_EN_GEN_ID,PHQ.ProgramID) ASQ_410
	ON ROOT.CLID = ASQ_410.CL_EN_GEN_ID
	AND ROOT.ProgramID = ASQ_410.ProgramID


LEFT JOIN
	(SELECT 
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_SE_0_EMOTIONAL
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_TOTAL
	FROM Infant_Health_Survey IHS
	WHERE dbo.fnGetFormName(IHS.SurveyID) IN ('Infant Health Care-Infancy 6 Months','Infant Health Care: Infancy 12 Months')
	AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID) IHS_ASQ
	ON ROOT.CLID = IHS_ASQ.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_ASQ.ProgramID

LEFT JOIN ---note <> 'none' also includes is not null
	(SELECT
		RS.CL_EN_GEN_ID
		,RS.ProgramID
		,MAX(CASE WHEN 
				(RS.CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
				OR RS.CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes')
				AND
				(RS.CLIENT_ABUSE_TIMES_0_HURT_LAST_YR <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER <> 'none'
				OR (RS.CLIENT_ABUSE_FORCED_0_SEX ='Yes'
					AND RS.CLIENT_ABUSE_FORCED_1_SEX_LAST_YR <> 'none')
				OR RS.CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
				OR (RS.CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes'
					AND RS.CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'none') )
				THEN 1
		END) DV_ident

	FROM Relationship_Survey RS
	WHERE dbo.fnGetFormName(RS.SurveyID) IN('Relationship Assessment: Pregnancy-Intake','Relationship Assessment: Pregnancy-36 Weeks')
	AND RS.SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY RS.CL_EN_GEN_ID,RS.ProgramID)	RS_i36
	ON ROOT.CLID = RS_i36.CL_EN_GEN_ID
	AND ROOT.ProgramID = RS_i36.ProgramID

LEFT JOIN --- Referrals survey within one year of startdate
	(SELECT
		RS.CL_EN_GEN_ID
		,RS.ProgramID
		,MAX(CASE WHEN RS.SERVICE_REFER_0_IPV = 'Client' THEN 1 END) SERVICE_REFER_0_IPV
	FROM Referrals_to_Services_Survey RS
	LEFT JOIN
		(SELECT 
			EAD.CLID
			,EAD.ProgramID 
			,EAD.ProgramStartDate
		FROM UV_EADT EAD
		WHERE RankingLatest = 1) C ON RS.CL_EN_GEN_ID = C.CLID AND RS.ProgramID = C.ProgramID
	WHERE RS.SurveyDate BETWEEN C.ProgramStartDate AND DATEADD(MONTH,12,C.ProgramStartDate)
	AND RS.SurveyDate <= @EndDate
	GROUP BY RS.CL_EN_GEN_ID,RS.ProgramID) Referrals
	ON ROOT.CLID = Referrals.CL_EN_GEN_ID
	AND ROOT.ProgramID = Referrals.ProgramID
			
WHERE 
	((CFS.Form = 1 AND @FundingType = 1) OR (CFS.Comp = 1 AND @FundingType = 2))  -- Funding type param
	AND ROOT.ProgramStartDate <= @EndDate AND (ROOT.EndDate >= @StartDate OR ROOT.EndDate IS NULL) -- population of active clients during time frame
	AND ROOT.ProgramID IN(SELECT DISTINCT P.ProgramID FROM UV_PAS P INNER JOIN dbo.udf_ParseMultiParam(@SiteID) S ON P.SiteID = S.Value) -- SiteID

GROUP BY ROOT.ProgramID



GO
