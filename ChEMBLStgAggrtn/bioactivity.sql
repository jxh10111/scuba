--  CTAS bioactivity FROM assays, activities, target_dictionary, molecule_dictionary
CREATE TABLE mini.bioactivity AS (
SELECT a.assay_id, a.assay_type, a.bao_format
, t.tid, t.target_type, act.bao_endpoint, act.standard_type
, act.molregno, mol.chembl_id, mol.molecule_type, mol.max_phase
, act.standard_relation, act.standard_value, act.standard_units
, act.pchembl_value, act.standard_upper_value, act.standard_text_value, act.standard_flag
    FROM public.assays a
    INNER JOIN public.activities act
        ON a.assay_id = act.assay_id
    INNER JOIN public.target_dictionary t
        ON a.tid = t.tid
    INNER JOIN public.molecule_dictionary mol
        ON act.molregno = mol.molregno
    WHERE t.target_type = 'SINGLE PROTEIN'
    AND act.standard_type IN ('Potency', 'IC50', 'Ki', 'Inhibition', 'Inihibition', 'Inhibition (% of control)', 'EC50', 'AC50', 'Activity', 'Kd', 'Residual Activity', 'Residual activity','Kd apparent', '% Control', '% Ctrl', 'Activation (% of control)', 'Emax')
    AND mol.molecule_type NOT IN ('Antibody', 'Cell', 'Enzyme', 'Gene', 'Oligonucleotide', 'Oligosaccharide', 'Protein')
)
GO
--Execution time: 26s
--Update standard_type typo for “Inihibition”  
UPDATE mini.bioactivity 
	SET standard_type='Inhibition'
	WHERE standard_type = 'Inihibition'
GO
--Execution time: 1s
--Add assay_measurement
ALTER TABLE mini.bioactivity
	ADD COLUMN assay_measurement varchar(25)
GO
--Execution time: 3ms
--Update assay_measurement
UPDATE mini.bioactivity 
	SET assay_measurement='single concentration'
	WHERE standard_type IN ('Inhibition', 'Activity', 'Emax', '% Control', 'Residual Activity', 'Residual activity', '% Ctrl', 'Inhibition (% of control)', 'Activation (% of control)')
GO
--Execution time: 3s
UPDATE mini.bioactivity 
	SET assay_measurement='concentration response'
	WHERE standard_type IN ('Ki', 'EC50', 'IC50', 'Potency', 'AC50', 'Kd', 'Kd apparent')
GO
--Execution time: 13s
