--
-- Delete model using model name from your module
--
DELETE FROM ir_model AS ir WHERE ir.model = 'modelname';

--
-- Delete model data using module name!
--
DELETE FROM ir_model_data AS ird WHERE ird.module = 'modulename'

--
-- Delete model fields using model name!
--
DELETE FROM ir_model_fields AS irf WHERE irf.model = 'modelname'

-- 
-- Last step: remove your module from panel
--
