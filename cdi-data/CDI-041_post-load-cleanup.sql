--Changes manually applied after data had been loaded

--'N/A' had been used as a placeholder, but those rows really don't belong
DELETE from term_map where gcid = 'N/A';
DELETE FROM relationship where identifier = 'N/A';

--term_relationship has a cumulative relationship of all terms under 
--lexicon/context: cdi/health, and isolation concept-map relationships
--of subtopic specifi terms under lexicon concept-map.  We want the 
--cdi/health/Health term to relate to the top-level concept map terms
--The below gets that job done.
update term_relationship 
set term_subject = (select identifier from term 
                    where lexicon_identifier = 'cdi' 
                      and context_identifier = 'health' 
                      and term = 'Health') 
where term_subject in (select term_subject from term, term_relationship 
                       where term.identifier = term_relationship.term_subject 
                         and term.term = 'Health');


--Somehow, Air Quality didn't get mapped at the top level properly, manually fix
insert into term_relationship (term_subject, relationship_identifier, term_object) 
values ((select identifier from term 
          where lexicon_identifier = 'cdi' 
            and context_identifier = 'health' 
            and term = 'Health'), 
        'skos:narrower', 
        (select identifier from term 
          where lexicon_identifier = 'concept-map' 
            and context_identifier = 'airQuality' 
            and term = 'Air Quality'));


--Finally, since we ONLY want cdi/health/Health to relate to the top-level concept-map 
--terms, get rid of the top level relationships in cdi/health (but keep the concept-map ones)
--(eg, delete /cdi/health/Health skos:narrower /cdi/health/Vector Borne Disease)
--because it makes the tree for /cdi/health/Health way to unweldy

delete from term_relationship where term_subject=(select identifier from term where lexicon_identifier='cdi' and context_identifier='health' and term='Health')
                              and relationship_identifier = 'skos:narrower'
                              and term_object IN (select identifier from term where lexicon_identifier='cdi' and context_identifier='health')
;

