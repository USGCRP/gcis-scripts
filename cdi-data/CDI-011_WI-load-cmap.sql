-- O/P of C:\db\GSFC\WI-CMAP2SQL.pl
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Health' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Water Related Illnesses' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Human Vulnerability' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Human Vulnerability' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Socioeconomic Risks' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Social Mores' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Health Care Access' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Employment' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Poverty' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Education' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Language' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Housing' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Environment' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Transportation' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Human Vulnerability' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Populations at Risk' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Populations at Risk' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Indigenous People' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Populations at Risk' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Pregnant' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Populations at Risk' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Race/Ethnicity' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Populations at Risk' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Age' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Populations at Risk' and s.context_identifier = 'waterIllness'), 'isResultOf', (SELECT o.identifier FROM term AS o WHERE o.term = 'Sex/Gender' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Response' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Planning' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.context_identifier = 'waterIllness'), 'isDoneFor', (SELECT o.identifier FROM term AS o WHERE o.term = 'Urban Growth' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.context_identifier = 'waterIllness'), 'isDoneFor', (SELECT o.identifier FROM term AS o WHERE o.term = 'Nuisance Flooding' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.context_identifier = 'waterIllness'), 'isDoneFor', (SELECT o.identifier FROM term AS o WHERE o.term = 'Storm Shelters' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.context_identifier = 'waterIllness'), 'isDoneFor', (SELECT o.identifier FROM term AS o WHERE o.term = 'Mitigation' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Agricultural Management Practices' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.context_identifier = 'waterIllness'), 'isDoneFor', (SELECT o.identifier FROM term AS o WHERE o.term = 'Health Surveillance System' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.context_identifier = 'waterIllness'), 'isDoneFor', (SELECT o.identifier FROM term AS o WHERE o.term = 'Shellfish Bed Closure' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Notification' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Notification' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Reporting Capacity' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Hydrology' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Discharge' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Watershed' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Nutrient Loading' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Turbidity' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Stream Flow' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Eutrophication' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Residence Time' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Harmful Algal Blooms (HABs)' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Infrastructure' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Water Purification Systems' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Purification Systems' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Water Treatment Plants' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Purification Systems' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Water Distribution Systems' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Purification Systems' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Pipelines' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Purification Systems' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Water Towers' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Purification Systems' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Water Tanks' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Wastewater System' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater System' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Septic Systems' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater System' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Sanitary Sewer Systems' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater System' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Wastewater Treatment Plant' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater System' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Lifts' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater System' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Sewer Pipes' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater System' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Wastewater Lagoons' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Stormwater Systems' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Combined Sewer Systems' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Wells' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Exposure' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Exposure' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Location' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Location' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Geographic Distribution' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Location' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Habitat' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Location' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'CaFOs' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Exposure' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Time' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Time' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Seasonal Growth Window' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Exposure' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Pathway' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathway' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Recreational Water' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathway' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Fish' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathway' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Shellfish' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathway' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Drinking Water' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Exposure' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Sources' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sources' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Human Waste' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sources' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Animal Waste' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sources' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Agriculture' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sources' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Fertilizers' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Exposure' and s.context_identifier = 'waterIllness'), 'isDeterminedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Contaminants' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Contaminants' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Pathogens' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Cyanobacteria' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Vibrio' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Cholera' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Cryptosporidium' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Giardia' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Salmonella enterica' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Naegleria' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Leptospira' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Leptonema' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Campylobacter' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Escherichia coli' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Enteroviruses' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Rotaviruses' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Noroviruses' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Contaminants' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Chemicals' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Chemicals' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Mercury' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Chemicals' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Organohalogens' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Chemicals' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Organotins' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Contaminants' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Biotoxins' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Biotoxins' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Ciguatoxins' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Biotoxins' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Saxitoxins' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Biotoxins' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Domoic Acids' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Biotoxins' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Okadaic Acids' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Biotoxins' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Brevetoxins' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Natural Hazard' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Drought' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Runoff' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Flooding' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Storm Surge' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Sea Level Rise' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Hurricanes' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Related Illnesses' and s.context_identifier = 'waterIllness'), 'isInfluencedBy', (SELECT o.identifier FROM term AS o WHERE o.term = 'Climate Indicators' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Sea Surface Temperature' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Temperature' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Precipitation' and o.context_identifier = 'waterIllness' ));
INSERT INTO term_relationship (term_subject, relationship_identifier, term_object) VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.context_identifier = 'waterIllness'), 'skos:narrower', (SELECT o.identifier FROM term AS o WHERE o.term = 'Salinity' and o.context_identifier = 'waterIllness' ));

