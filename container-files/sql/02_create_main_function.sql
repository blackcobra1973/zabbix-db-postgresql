-- Function: trg_partition()

-- DROP FUNCTION trg_partition();

CREATE OR REPLACE FUNCTION trg_partition()
  RETURNS trigger AS
$BODY$
DECLARE
prefix text := 'partitions.';
timeformat text;
selector text;
_interval interval;
tablename text;
startdate text;
enddate text;
create_table_part text;
create_index_part text;
BEGIN

selector = TG_ARGV[0];

IF selector = 'day' THEN
timeformat := 'YYYY_MM_DD';
ELSIF selector = 'month' THEN
timeformat := 'YYYY_MM';
END IF;

_interval := '1 ' || selector;
tablename :=  TG_TABLE_NAME || '_p' || to_char(to_timestamp(NEW.clock), timeformat);

EXECUTE 'INSERT INTO ' || prefix || quote_ident(tablename) || ' SELECT ($1).*' USING NEW;
RETURN NULL;

EXCEPTION
WHEN undefined_table THEN

startdate := extract(epoch FROM date_trunc(selector, to_timestamp(NEW.clock)));
enddate := extract(epoch FROM date_trunc(selector, to_timestamp(NEW.clock) + _interval ));

create_table_part:= 'CREATE TABLE IF NOT EXISTS '|| prefix || quote_ident(tablename) || ' (CHECK ((clock >= ' || quote_literal(startdate) || ' AND clock < ' || quote_literal(enddate) || '))) INHERITS ('|| TG_TABLE_NAME || ')';
create_index_part:= 'CREATE INDEX '|| quote_ident(tablename) || '_1 on ' || prefix || quote_ident(tablename) || '(itemid,clock)';

EXECUTE create_table_part;
EXECUTE create_index_part;

--insert it again
EXECUTE 'INSERT INTO ' || prefix || quote_ident(tablename) || ' SELECT ($1).*' USING NEW;
RETURN NULL;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION trg_partition()
  OWNER TO postgres;
