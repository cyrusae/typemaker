/* equivalency:
numeric = smallint, integer, bigint, decimal, numeric, real, double precision, smallserial, serial, bigserial, money
string[] = array  
boolean = boolean  
literally everything else = it's a string now I'm not your dad */

--See typemaker.pgsql for the tool itself
--This is an example run using a query from the BobaBoard backend c. September 2022
--It is preserved here for my records' sake mostly 

DO $$
declare contents TEXT ; interfaceName TEXT := 'dbCreatedInterface' ; --put the name you want here if you want a specific name
BEGIN

drop table if exists TypeFactsTable ;
create table type_testing_table_do_not_overlap as 
-- The return type of this query is DbActivityThreadType.
-- If updating, please also update DbActivityThreadType in Types.
-- TODO: enforce this through tests
SELECT
    -- Thread details (DbThreadType)
    thread_string_id as thread_id,
    board_slug,
    board_string_id as board_id,
    realm_slug,
    realm_string_id as realm_id,
    TO_CHAR(last_update_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.00"Z"') as thread_last_activity,
    thread_details.default_view,
    -- Amount details
    COALESCE(posts_amount, 0) as thread_total_posts_amount,
    COALESCE(threads_amount, 0) as thread_direct_threads_amount,
    COALESCE(comments_amount, 0) as thread_total_comments_amount,
    COALESCE(new_posts_board_amount, 0) as thread_new_posts_amount,
    COALESCE(new_comments_board_amount, 0) as thread_new_comments_amount,
    COALESCE(muted, FALSE) as muted,
    COALESCE(hidden, FALSE) as hidden,
    -- Post details (DbPostType)
    first_post_string_id as post_id,
    thread_string_id as parent_thread_id,
    NULL as parent_post_id,
    board_slug as parent_board_slug,
    board_string_id as parent_board_id,
    -- Author details
    author,
    author_identity.username,
    author_identity.user_avatar,
    author_identity.secret_identity_name,
    author_identity.secret_identity_avatar,
    author_identity.secret_identity_color,
    author_identity.accessory_avatar,
    COALESCE(friend_thread, FALSE) as friend,
    COALESCE(own_thread, FALSE) as self,
    TO_CHAR(first_post_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.00"Z"') as created_at,
    -- Generic details
    content,
    -- TODO[realms]: deprecated
    thread_details.options,
    -- post tags
    index_tags,
    category_tags,
    content_warnings,
    whisper_tags,
    -- TODO[realms]: likely deprecated
    COALESCE(own_thread, FALSE) as is_own,
    COALESCE(is_new_board, FALSE) as is_new,
    -- This last activity must have the .US at the end or it will trigger a bug
    -- where some posts are skipped by the last activity cursor.
    -- See documentation on the queries JS file.
    TO_CHAR(last_update_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.US') as thread_last_activity_at_micro
FROM (
  SELECT * FROM threads 
  INNER JOIN user_thread_identities uti
  ON uti.thread_id = threads.id /* AND uti.user_id = (SELECT id FROM users WHERE users.firebase_id = ${firebase_id} LIMIT 1) */
) AS threads
INNER JOIN thread_details
   ON threads.id = thread_details.thread_id
LEFT JOIN thread_identities author_identity
    ON author_identity.user_id = thread_details.author AND author_identity.thread_id = thread_details.thread_id
LEFT JOIN thread_user_details
 ON thread_details.thread_id = thread_user_details.thread_id
WHERE
   -- activity cursor condition
   muted IS FALSE
   AND hidden IS FALSE
 ;

create TEMP TABLE TypeFactsTable as

with TypeFacts as (
select column_name, 
  CASE 
   WHEN is_nullable = 'YES'
    then '?: '
    ELSE ': ' END as append_this,
  CASE
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

drop table type_testing_table_do_not_overlap ;

select into contents STRING_AGG(TypeList, ';  ' || CHR(10)) 
 from TypeFactsTable ;
RAISE NOTICE 'interface % = { % }', interfaceName, contents ;
drop table TypeFactsTable ; 
END $$