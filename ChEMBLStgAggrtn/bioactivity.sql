--  CTAS bioactivity FROM assays, activities, target_dictionary, molecule_dictionary
CREATE TABLE mini.bioactivity AS (
SELECT a.assay_id, a.assay_type, a.bao_format
, t.tid, t.target_type, act.bao_endpoint, act.standard_type
, mol.molecule_type, mol.max_phase, mol.prodrug
, act.molregno, mol.chembl_id
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
    AND (mol.molecule_type NOT IN ('Antibody', 'Cell', 'Enzyme', 'Gene', 'Oligonucleotide', 'Oligosaccharide', 'Protein')
        OR mol.molecule_type is NULL)
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
--CTAS molecular hierarchy
CREATE TABLE mini.p_bioactivity AS 
    (SELECT ba.assay_id, ba.assay_type, ba.bao_format, ba.tid, ba.target_type
            , ba.molecule_type, ba.max_phase, ba.prodrug
            , ba.bao_endpoint, ba.standard_type
            , ba.molregno, ba.chembl_id, mh.parent_molregno, mh.active_molregno
            , ba.standard_relation, ba.standard_value, ba.standard_units, ba.pchembl_value
            , ba.standard_upper_value, ba.standard_text_value, ba.standard_flag, ba.assay_measurement 
    FROM mini.bioactivity ba
        INNER JOIN molecule_hierarchy mh
            ON ba.molregno = mh.molregno)
GO
--Execution time: 12s
--CTAS parent_chembl_id into bioactivity
CREATE TABLE mini.pc_bioactivity AS (
    SELECT ba.assay_id, ba.assay_type, ba.bao_format, ba.tid, ba.target_type
            , ba.molecule_type, ba.max_phase, ba.prodrug
            , ba.bao_endpoint, ba.standard_type
            , ba.molregno, ba.chembl_id, ba.parent_molregno, md.chembl_id as parent_chembl_id, ba.active_molregno
            , ba.standard_relation, ba.standard_value, ba.standard_units, ba.pchembl_value
            , ba.standard_upper_value, ba.standard_text_value, ba.standard_flag, ba.assay_measurement
	FROM mini.p_bioactivity ba
    INNER JOIN molecule_dictionary md
        ON ba.parent_molregno = md.molregno
)
GO
--Execution time: 12s
--CTAS active_chembl_id into bioactivity
CREATE TABLE mini.pca_bioactivity AS (
    SELECT ba.assay_id, ba.assay_type, ba.bao_format, ba.tid, ba.target_type
            , ba.molecule_type, ba.max_phase, ba.prodrug
            , ba.bao_endpoint, ba.standard_type
            , ba.molregno, ba.chembl_id, ba.parent_molregno, parent_chembl_id, ba.active_molregno, md.chembl_id as  active_chembl_id
            , ba.standard_relation, ba.standard_value, ba.standard_units, ba.pchembl_value
            , ba.standard_upper_value, ba.standard_text_value, ba.standard_flag, ba.assay_measurement
	FROM mini.pc_bioactivity ba
    INNER JOIN molecule_dictionary md
        ON ba.active_molregno = md.molregno
)
GO
--Execution time: 12s
--Cleanup and END triage
DROP TABLE mini.bioactivity
GO
CREATE TABLE mini.bioactivity AS SELECT * FROM mini.pca_bioactivity
GO
DROP TABLE mini.p_bioactivity
GO
DROP TABLE mini.pc_bioactivity
GO
DROP TABLE mini.pca_bioactivity
GO
--Run 13 scripts Total Execution time: 2m 11s

CREATE TABLE mini.bioactivity_cmp AS (
SELECT b.assay_id
, b.assay_type
, b.bao_format
, b.tid
, b.target_type
, b.molecule_type
, b.max_phase
, b.prodrug
, b.bao_endpoint
, b.standard_type
, b.molregno
, b.chembl_id
, b.parent_molregno
, b.parent_chembl_id
, b.active_molregno
, b.active_chembl_id
, c.component_id
, b.standard_relation
, b.standard_value
, b.standard_units
, b.pchembl_value
, b.standard_upper_value
, b.standard_text_value
, b.standard_flag
, b.assay_measurement
    FROM mini.bioactivity_cmp b
    INNER JOIN public.target_components c
        ON b.tid = c.tid)
GO

CREATE TABLE mini.bioactivity_protein AS (
SELECT b.assay_id
, b.assay_type
, b.bao_format
, b.tid
, b.target_type
, b.molecule_type
, b.max_phase
, b.prodrug
, b.bao_endpoint
, b.standard_type
, b.molregno
, b.chembl_id
, b.parent_molregno
, b.parent_chembl_id
, b.active_molregno
, b.active_chembl_id
, b.component_id
, cs.component_type
, cs.accession
, cs.tax_id
, cs.organism
, b.standard_relation
, b.standard_value
, b.standard_units
, b.pchembl_value
, b.standard_upper_value
, b.standard_text_value
, b.standard_flag
, b.assay_measurement
    FROM mini.bioactivity_cmp b
    INNER JOIN public.component_sequences cs
        ON b.component_id = cs.component_id)
GO

CREATE TABLE mini.pbioactivity AS(
SELECT parent_chembl_id, accession, organism, assay_measurement, standard_type, standard_relation
--, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY standard_value) as msv
, count(*)
, round((-LOG(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY standard_value)/1000000000))::numeric, 2) as nlogvalm
/* assay_id,     assay_type
, parent_chembl_id
, accession, organism
,     assay_measurement
, standard_type, standard_relation,     standard_value,     standard_units,     pchembl_value,     standard_upper_value,     standard_text_value     
, standard_flag
*/
FROM mini.bioactivity_protein
WHERE standard_value IS NOT NULL
AND standard_value != 0
GROUP BY parent_chembl_id, accession, organism, assay_measurement, standard_type, standard_relation
)
GO
