-- Function: delete_partitions(interval, text)

-- DROP FUNCTION delete_partitions(interval, text);

CREATE OR REPLACE FUNCTION delete_partitions(intervaltodelete interval, tabletype text)
  RETURNS text AS
$BODY$
DECLARE
result record ;
prefix text := 'partitions.';
table_timestamp timestamp;
delete_before_date date;
tablename text;

BEGIN
    FOR result IN SELECT * FROM pg_tables WHERE schemaname = 'partitions' LOOP

        table_timestamp := to_timestamp(substring(result.tablename from '[0-9_]*$'), 'YYYY_MM_DD');
        delete_before_date := date_trunc('day', NOW() - intervalToDelete);
        tablename := result.tablename;

    -- Was it called properly?
        IF tabletype != 'month' AND tabletype != 'day' THEN
      RAISE EXCEPTION 'Please specify "month" or "day" instead of %', tabletype;
        END IF;


    --Check whether the table name has a day (YYYY_MM_DD) or month (YYYY_MM) format
        IF length(substring(result.tablename from '[0-9_]*$')) = 10 AND tabletype = 'month' THEN
            --This is a daily partition YYYY_MM_DD
            -- RAISE NOTICE 'Skipping table % when trying to delete "%" partitions (%)', result.tablename, tabletype, length(substring(result.tablename from '[0-9_]*$'));
            CONTINUE;
        ELSIF length(substring(result.tablename from '[0-9_]*$')) = 7 AND tabletype = 'day' THEN
            --this is a monthly partition
            --RAISE NOTICE 'Skipping table % when trying to delete "%" partitions (%)', result.tablename, tabletype, length(substring(result.tablename from '[0-9_]*$'));
            CONTINUE;
        ELSE
            --This is the correct table type. Go ahead and check if it needs to be deleted
      --RAISE NOTICE 'Checking table %', result.tablename;
        END IF;

  IF table_timestamp <= delete_before_date THEN
    RAISE NOTICE 'Deleting table %', quote_ident(tablename);
    EXECUTE 'DROP TABLE ' || prefix || quote_ident(tablename) || ';';
  END IF;
    END LOOP;
RETURN 'OK';

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION delete_partitions(interval, text)
  OWNER TO postgres;
