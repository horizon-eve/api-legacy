CREATE USER api_high with password 'api_high' SUPERUSER;
CREATE USER api with password 'api';
GRANT CONNECT ON DATABASE horizon TO api_high;
GRANT CONNECT ON DATABASE horizon TO api;

CREATE SCHEMA AUTHORIZATION api;
CREATE ROLE pubapi;
GRANT USAGE ON SCHEMA evesde TO api;
GRANT USAGE ON SCHEMA esi TO api;
GRANT USAGE ON SCHEMA esi TO pubapi;
GRANT SELECT ON ALL TABLES IN SCHEMA evesde TO pubapi;
GRANT pubapi to authenticated;
GRANT pubapi to api;

SET search_path TO api;

-- item search
CREATE OR REPLACE VIEW itemsearch AS
SELECT t."typeID"    AS type_id,
       t."typeName"  AS type_name,
       g."groupName" AS group_name,
       t.volume
FROM evesde."invTypes" t
         JOIN evesde."invGroups" g ON g."groupID" = t."groupID"
         JOIN evesde."invCategories" c ON c."categoryID" = g."categoryID" and c."categoryID" not in (9, 91)
WHERE t.published = true
  AND t."marketGroupID" IS NOT NULL;
ALTER VIEW itemsearch OWNER TO api;
GRANT SELECT ON TABLE itemsearch TO pubapi;

-- users
create or replace view users as
select user_id, character_id from auth.users;
ALTER VIEW users OWNER TO authenticated;

-- Item Lists
CREATE SEQUENCE seq_itemlist START 10000000;
CREATE TABLE itemlist
(
    itemlist_id varchar(20) PRIMARY KEY DEFAULT concat('il',nextval('seq_itemlist')),
    user_id varchar(20) not null references auth.users(user_id) DEFAULT current_user,
    name varchar(100) not null,
    items jsonb not null,
    items_count integer not null,
    created timestamp not null DEFAULT CURRENT_TIMESTAMP,
    updated timestamp not null DEFAULT CURRENT_TIMESTAMP 
);
ALTER TABLE itemlist OWNER TO api_high;
ALTER SEQUENCE seq_itemlist OWNER TO api;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE itemlist TO authenticated;
ALTER TABLE itemlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY itemlist ON itemlist TO authenticated USING (user_id = current_user);
