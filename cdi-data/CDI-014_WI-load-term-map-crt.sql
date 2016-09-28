-- O/P of c:\db\GSFC\WI-term-map-crt.pl
INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Human Vulnerability' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Human Vulnerability' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Assessing Health Vulnerability to Climate Change: A Guide for Health Departments', 'http://toolkit.climate.gov/tool/assessing-health-vulnerability-climate-change-guide-health-departments');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Human Vulnerability' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Human Vulnerability' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Sustainable and Climate-Resilient Health Care Facilities Toolkit', 'http://toolkit.climate.gov/tool/sustainable-and-climate-resilient-health-care-facilities-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Great Lakes Climate Atlas', 'http://toolkit.climate.gov/tool/great-lakes-climate-atlas');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Hazus-MH', 'http://toolkit.climate.gov/tool/hazus');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Socioeconomic Risks' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Health Care Access' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Sustainable and Climate-Resilient Health Care Facilities Toolkit', 'http://toolkit.climate.gov/tool/sustainable-and-climate-resilient-health-care-facilities-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Housing' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Transportation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Populations at Risk' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Race/Ethnicity' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Arctic Adaptation Exchange', 'http://toolkit.climate.gov/tool/arctic-adaptation-exchange');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Addressing Links Between Climate and Public Health in Alaska Native Villages', 'http://toolkit.climate.gov/taking-action/addressing-links-between-climate-and-public-health-alaska-native-villages');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Alaskan Tribes Join Together to Assess Harmful Algal Blooms', 'http://toolkit.climate.gov/taking-action/alaskan-tribes-join-together-monitor-harmful-algal-blooms');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Charting Colorado’s Vulnerability to Climate Change', 'http://toolkit.climate.gov/taking-action/charting-colorado%E2%80%99s-vulnerability-climate-change');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Ready Campaign', 'http://toolkit.climate.gov/tool/ready-campaign');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Response' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Emergency Preparedness and Response: Natural Disasters and Severe Weather', 'http://toolkit.climate.gov/tool/emergency-preparedness-and-response-natural-disasters-and-severe-weather');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Addressing Links Between Climate and Public Health in Alaska Native Villages', 'http://toolkit.climate.gov/taking-action/addressing-links-between-climate-and-public-health-alaska-native-villages');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Cal-Adapt', 'http://toolkit.climate.gov/tool/cal-adapt');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Hazus-MH', 'http://toolkit.climate.gov/tool/hazus');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Planning for the Future in a Floodplain', 'http://toolkit.climate.gov/taking-action/planning-future-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Cities Impacts & Adaptation Tool (CIAT)', 'http://toolkit.climate.gov/tool/cities-impacts-adaptation-tool-ciat');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Flood Resilience: A Basic Guide for Water and Wastewater Utilities', 'http://toolkit.climate.gov/tool/flood-resilience-basic-guide-water-and-wastewater-utilities');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Ready Campaign', 'http://toolkit.climate.gov/tool/ready-campaign');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Social Vulnerability Index', 'http://toolkit.climate.gov/tool/social-vulnerability-index');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Sustainable and Climate-Resilient Health Care Facilities Toolkit', 'http://toolkit.climate.gov/tool/sustainable-and-climate-resilient-health-care-facilities-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'U.S. Drought Portal', 'http://toolkit.climate.gov/tool/us-drought-portal');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'EJSCREEN: Environmental Justice Screening and Mapping Tool', 'http://toolkit.climate.gov/tool/ejscreen-environmental-justice-screening-and-mapping-tool');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Emergency Preparedness and Response: Natural Disasters and Severe Weather', 'http://toolkit.climate.gov/tool/emergency-preparedness-and-response-natural-disasters-and-severe-weather');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Planning' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Tribal-Focused Environmental Risk and Sustainability Tool (Tribal-FERST)', 'http://toolkit.climate.gov/tool/tribal-focused-environmental-risk-and-sustainability-tool-tribal-ferst');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Storm Shelters' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Flood Resilience: A Basic Guide for Water and Wastewater Utilities', 'http://toolkit.climate.gov/tool/flood-resilience-basic-guide-water-and-wastewater-utilities');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Hazus-MH', 'http://toolkit.climate.gov/tool/hazus');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Mitigation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Notification' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Emergency Preparedness and Response: Natural Disasters and Severe Weather', 'http://toolkit.climate.gov/tool/emergency-preparedness-and-response-natural-disasters-and-severe-weather');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Notification' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Ready Campaign', 'http://toolkit.climate.gov/tool/ready-campaign');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Developing and Using an Index to Guide Water Supply Decisions', 'http://toolkit.climate.gov/taking-action/developing-and-using-index-guide-water-supply-decisions');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hydrology' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Watershed' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Stream Flow' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Harmful Algal Blooms (HABs)' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Alaskan Tribes Join Together to Assess Harmful Algal Blooms', 'http://toolkit.climate.gov/taking-action/alaskan-tribes-join-together-monitor-harmful-algal-blooms');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Harmful Algal Blooms (HABs)' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Keeping Toxins From Harmful Algal Blooms out of the Food Supply', 'http://toolkit.climate.gov/taking-action/keeping-toxins-harmful-algal-blooms-out-food-supply');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Harmful Algal Blooms (HABs)' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Integrating Education and Stormwater Management for Healthy Rivers and Residents', 'http://toolkit.climate.gov/taking-action/integrating-education-and-stormwater-management-healthy-rivers-and-residents');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Building Smart in the Floodplain', 'http://toolkit.climate.gov/taking-action/building-smart-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Planning for the Future in a Floodplain', 'http://toolkit.climate.gov/taking-action/planning-future-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Stormwater Calculator—Climate Assessment Tool', 'http://toolkit.climate.gov/tool/national-stormwater-calculator%E2%80%94climate-assessment-tool');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Infrastructure' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Water Distribution Systems' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Water Information System: Mapper', 'http://toolkit.climate.gov/tool/national-water-information-system-mapper');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Septic Systems' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Water Information System: Mapper', 'http://toolkit.climate.gov/tool/national-water-information-system-mapper');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sanitary Sewer Systems' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater Treatment Plant' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Wastewater Treatment Plant' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Water Information System: Mapper', 'http://toolkit.climate.gov/tool/national-water-information-system-mapper');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Stormwater Systems' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Integrating Education and Stormwater Management for Healthy Rivers and Residents', 'http://toolkit.climate.gov/taking-action/integrating-education-and-stormwater-management-healthy-rivers-and-residents');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Stormwater Systems' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Stormwater Calculator—Climate Assessment Tool', 'http://toolkit.climate.gov/tool/national-stormwater-calculator%E2%80%94climate-assessment-tool');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Stormwater Systems' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Exposure' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Tribal-Focused Environmental Risk and Sustainability Tool (Tribal-FERST)', 'http://toolkit.climate.gov/tool/tribal-focused-environmental-risk-and-sustainability-tool-tribal-ferst');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Location' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Planning for the Future in a Floodplain', 'http://toolkit.climate.gov/taking-action/planning-future-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Recreational Water' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Virtual Beach', 'http://toolkit.climate.gov/tool/virtual-beach');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Shellfish' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Alaskan Tribes Join Together to Assess Harmful Algal Blooms', 'http://toolkit.climate.gov/taking-action/alaskan-tribes-join-together-monitor-harmful-algal-blooms');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drinking Water' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Developing and Using an Index to Guide Water Supply Decisions', 'http://toolkit.climate.gov/taking-action/developing-and-using-index-guide-water-supply-decisions');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drinking Water' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Integrating Education and Stormwater Management for Healthy Rivers and Residents', 'http://toolkit.climate.gov/taking-action/integrating-education-and-stormwater-management-healthy-rivers-and-residents');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Contaminants' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Pathogens' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Virtual Beach', 'http://toolkit.climate.gov/tool/virtual-beach');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Vibrio' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Cholera' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Cryptosporidium' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Giardia' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Salmonella enterica' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Campylobacter' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Escherichia coli' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Virtual Beach', 'http://toolkit.climate.gov/tool/virtual-beach');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Chemicals' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Keeping Toxins From Harmful Algal Blooms out of the Food Supply', 'http://toolkit.climate.gov/taking-action/keeping-toxins-harmful-algal-blooms-out-food-supply');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Chemicals' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Integrating Education and Stormwater Management for Healthy Rivers and Residents', 'http://toolkit.climate.gov/taking-action/integrating-education-and-stormwater-management-healthy-rivers-and-residents');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Addressing Links Between Climate and Public Health in Alaska Native Villages', 'http://toolkit.climate.gov/taking-action/addressing-links-between-climate-and-public-health-alaska-native-villages');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Hazus-MH', 'http://toolkit.climate.gov/tool/hazus');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Ready Campaign', 'http://toolkit.climate.gov/tool/ready-campaign');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'NOAA''s Weather and Climate Toolkit', 'http://toolkit.climate.gov/tool/noaas-weather-and-climate-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Emergency Preparedness and Response: Natural Disasters and Severe Weather', 'http://toolkit.climate.gov/tool/emergency-preparedness-and-response-natural-disasters-and-severe-weather');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Natural Hazard' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'SERVIR', 'http://toolkit.climate.gov/tool/servir');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Addressing Links Between Climate and Public Health in Alaska Native Villages', 'http://toolkit.climate.gov/taking-action/addressing-links-between-climate-and-public-health-alaska-native-villages');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Advanced Hydrologic Prediction Service', 'http://toolkit.climate.gov/tool/advanced-hydrologic-prediction-service');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate at a Glance', 'http://toolkit.climate.gov/tool/climate-glance');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'NOAA''s Weather and Climate Toolkit', 'http://toolkit.climate.gov/tool/noaas-weather-and-climate-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'U.S. Drought Portal', 'http://toolkit.climate.gov/tool/us-drought-portal');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Drought' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Runoff' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Runoff' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Integrating Education and Stormwater Management for Healthy Rivers and Residents', 'http://toolkit.climate.gov/taking-action/integrating-education-and-stormwater-management-healthy-rivers-and-residents');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Runoff' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Charting Colorado’s Vulnerability to Climate Change', 'http://toolkit.climate.gov/taking-action/charting-colorado%E2%80%99s-vulnerability-climate-change');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Runoff' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Stormwater Calculator—Climate Assessment Tool', 'http://toolkit.climate.gov/tool/national-stormwater-calculator%E2%80%94climate-assessment-tool');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Runoff' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Addressing Links Between Climate and Public Health in Alaska Native Villages', 'http://toolkit.climate.gov/taking-action/addressing-links-between-climate-and-public-health-alaska-native-villages');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Building Smart in the Floodplain', 'http://toolkit.climate.gov/taking-action/building-smart-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Planning for the Future in a Floodplain', 'http://toolkit.climate.gov/taking-action/planning-future-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Charting Colorado’s Vulnerability to Climate Change', 'http://toolkit.climate.gov/taking-action/charting-colorado%E2%80%99s-vulnerability-climate-change');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Advanced Hydrologic Prediction Service', 'http://toolkit.climate.gov/tool/advanced-hydrologic-prediction-service');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Stormwater Calculator—Climate Assessment Tool', 'http://toolkit.climate.gov/tool/national-stormwater-calculator%E2%80%94climate-assessment-tool');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Water Information System: Mapper', 'http://toolkit.climate.gov/tool/national-water-information-system-mapper');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'FEMA Flood Map Service Center', 'http://toolkit.climate.gov/tool/fema-flood-map-service-center');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Flood Resilience: A Basic Guide for Water and Wastewater Utilities', 'http://toolkit.climate.gov/tool/flood-resilience-basic-guide-water-and-wastewater-utilities');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Hazus-MH', 'http://toolkit.climate.gov/tool/hazus');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Ready Campaign', 'http://toolkit.climate.gov/tool/ready-campaign');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'NOAA''s Weather and Climate Toolkit', 'http://toolkit.climate.gov/tool/noaas-weather-and-climate-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Flooding' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sea Level Rise' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Developing and Using an Index to Guide Water Supply Decisions', 'http://toolkit.climate.gov/taking-action/developing-and-using-index-guide-water-supply-decisions');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sea Level Rise' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Sea Level Rise' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Metadata Access Tool for Climate and Health (MATCH)', 'http://toolkit.climate.gov/tool/metadata-access-tool-climate-and-health-match');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Hurricanes' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'NOAA''s Weather and Climate Toolkit', 'http://toolkit.climate.gov/tool/noaas-weather-and-climate-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Local Climate Analysis Tool (LCAT)', 'http://toolkit.climate.gov/tool/local-climate-analysis-tool-lcat');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Climate Indicators' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Storm Water Management Model', 'http://toolkit.climate.gov/tool/storm-water-management-model');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Cal-Adapt', 'http://toolkit.climate.gov/tool/cal-adapt');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Addressing Links Between Climate and Public Health in Alaska Native Villages', 'http://toolkit.climate.gov/taking-action/addressing-links-between-climate-and-public-health-alaska-native-villages');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Alaskan Tribes Join Together to Assess Harmful Algal Blooms', 'http://toolkit.climate.gov/taking-action/alaskan-tribes-join-together-monitor-harmful-algal-blooms');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Keeping Toxins From Harmful Algal Blooms out of the Food Supply', 'http://toolkit.climate.gov/taking-action/keeping-toxins-harmful-algal-blooms-out-food-supply');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate at a Glance', 'http://toolkit.climate.gov/tool/climate-glance');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Cities Impacts & Adaptation Tool (CIAT)', 'http://toolkit.climate.gov/tool/cities-impacts-adaptation-tool-ciat');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Local Climate Analysis Tool (LCAT)', 'http://toolkit.climate.gov/tool/local-climate-analysis-tool-lcat');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'NOAA''s Weather and Climate Toolkit', 'http://toolkit.climate.gov/tool/noaas-weather-and-climate-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'U.S. Drought Portal', 'http://toolkit.climate.gov/tool/us-drought-portal');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Temperature' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Cal-Adapt', 'http://toolkit.climate.gov/tool/cal-adapt');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Using Demonstration Storms to Prepare for Extreme Rainfall', 'http://toolkit.climate.gov/taking-action/using-demonstration-storms-prepare-extreme-rainfall');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Integrating Education and Stormwater Management for Healthy Rivers and Residents', 'http://toolkit.climate.gov/taking-action/integrating-education-and-stormwater-management-healthy-rivers-and-residents');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasCaseStudy', 'Planning for the Future in a Floodplain', 'http://toolkit.climate.gov/taking-action/planning-future-floodplain');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Advanced Hydrologic Prediction Service', 'http://toolkit.climate.gov/tool/advanced-hydrologic-prediction-service');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate at a Glance', 'http://toolkit.climate.gov/tool/climate-glance');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Cities Impacts & Adaptation Tool (CIAT)', 'http://toolkit.climate.gov/tool/cities-impacts-adaptation-tool-ciat');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Explorer', 'http://toolkit.climate.gov/tool/climate-explorer');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Local Climate Analysis Tool (LCAT)', 'http://toolkit.climate.gov/tool/local-climate-analysis-tool-lcat');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'National Stormwater Calculator—Climate Assessment Tool', 'http://toolkit.climate.gov/tool/national-stormwater-calculator%E2%80%94climate-assessment-tool');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'NOAA''s Weather and Climate Toolkit', 'http://toolkit.climate.gov/tool/noaas-weather-and-climate-toolkit');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'U.S. Drought Portal', 'http://toolkit.climate.gov/tool/us-drought-portal');

INSERT INTO term_map (term_identifier, relationship_identifier, description ,gcid) 
	VALUES ((SELECT s.identifier FROM term AS s WHERE s.term = 'Precipitation' and s.lexicon_identifier = 'cdi'), 
	'hasAnalysisTool', 'Climate Outlooks', 'http://toolkit.climate.gov/tool/climate-outlooks');


