/* TYPEMAKER v0.1.0
FOR POSTGRESQL 


Type equivalency:
numeric = smallint, integer, bigint, decimal, numeric, real, double precision, smallserial, serial, bigserial, money
string[] = array  
boolean = boolean  
literally everything else = it's a string now I'm not your dad 

In other words: the extent to which a SQL database, despite being strongly typed on its own, can tell you about types that are analogous to what TypeScript needs is limited. If you already have the knowledge to nitpick the typemaker output, you're further along in the process than it's capable of helping you with.

NOTE ON NULLABILITY: Database introspection doesn't extend to being able to detect whether its columns are nullable in this kind of setup. (Guessing based on whether there are nulls in the example data as an optional toggle is a potential future feature.) From the output's perspective, maybe everything is nullable, maybe nothing is; that's also on you.

See README for other things.*/

DO $$

--create variables at the beginning of the script 
declare contents TEXT ; interfaceName TEXT := 'dbCreatedInterface' ; --put the name you want here if you want a specific name

BEGIN

drop table if exists TypeFactsTable ; --clean up after any aborted previous runs
create table type_testing_table_do_not_overlap as 
--PASTE YOUR QUERY HERE
  --BUT: omit any WHERE or JOIN conditions that have parameters/variables in them for now.
 ; --end of query (you now have an example of your query's potential output; this needs to be committed before we can move on)

create TEMP TABLE TypeFactsTable as
 with TypeFacts as (
 select column_name, 
   CASE --default script acts like everything is nullable in a way that matters
    WHEN is_nullable = 'YES'
     then '?: '
     ELSE ': ' END as append_this,
   CASE --see comments at the beginning of this document
    WHEN data_type in ('smallint', 'integer', 'bigint', 'decimal', 'numeric', 'real', 'double precision', 'smallserial', 'serial', 'bigserial', 'money')
     then 'number' 
    WHEN data_type = 'ARRAY'
     then 'string[]'
    WHEN data_type = 'boolean'
     then 'boolean'
    ELSE 'string' END as ts_type,
   CASE WHEN is_nullable = 'YES'
     then ' | null'
    ELSE ''  END as ts_type_ext from information_schema.columns 
   where table_name = 'type_testing_table_do_not_overlap')
 select concat(column_name, append_this, ts_type, ts_type_ext) as TypeList
  from TypeFacts ;

select into contents STRING_AGG(TypeList, ';  ' || CHR(10)) 
 from TypeFactsTable ;
RAISE NOTICE 'interface % = { % }', interfaceName, contents ; --admin console outputs the generated interface for you here; % = template variable replaced in order of appearance 

--clean up:
drop table type_testing_table_do_not_overlap ;
drop table TypeFactsTable ; 

END $$