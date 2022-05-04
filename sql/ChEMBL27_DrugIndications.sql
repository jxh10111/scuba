SELECT md.chembl_id, md.pref_name, di.max_phase_for_ind, di.mesh_id, di.mesh_heading, di.efo_id, di.efo_term
	FROM public.drug_indication di
	INNER JOIN public.molecule_dictionary md
		ON di.molregno = md.molregno
