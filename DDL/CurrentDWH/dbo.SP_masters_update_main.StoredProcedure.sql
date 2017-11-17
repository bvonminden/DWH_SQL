USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_masters_update_main]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_masters_update_main
CREATE PROCEDURE [dbo].[SP_masters_update_main]
AS
-- This script updates the replicated master tables in the Data Warehouse.
-- These tables are used for LOVs and table integrety during import from ETO.
--
-- Survey masters are copied from ETO, to the DW so that additional field mapping 
-- can be addressed at a local level.
--
exec SP_masters_update_surveys                 -- inserts/updates surveys table
exec sp_masters_update_survey_elements         -- inserts/updates survey elements
exec sp_masters_update_survey_element_choices  -- inserts/updates survey element choices
exec SP_masters_update_entity_attributes       -- inserts/updates entity attributes
exec SP_masters_update_client_demographics     -- inserts/updates client demographics


GO
