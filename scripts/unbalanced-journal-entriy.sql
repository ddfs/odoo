/* filters unbalanced journal entries in account_move and account_move_line */ 
SELECT t.*, abs(t.total_debit - t.total_credit) as total_diff FROM (

SELECT am.id, 
(SELECT sum(aml.debit) as total_debit FROM account_move_line AS aml WHERE aml.move_id = am.id),
(SELECT sum(aml.credit) as total_credit FROM account_move_line AS aml WHERE aml.move_id = am.id)
FROM account_move AS am
) as t
WHERE t.total_debit - t.total_credit > 0
