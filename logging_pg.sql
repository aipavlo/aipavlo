REATE OR REPLACE FUNCTION metadata.etl_logging(
    INOUT _id UUID DEFAULT NULL,
    IN _upd BIGINT DEFAULT NULL,
    IN _ins BIGINT DEFAULT NULL,
    IN _err_msg TEXT DEFAULT NULL,
    IN _info_msg TEXT DEFAULT NULL
)
RETURNS SETOF UUID 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Replace empty strings with NULL
    _err_msg = NULLIF(_err_msg, '');
    _info_msg = NULLIF(_info_msg, '');

    IF _id IS NULL THEN
        RETURN QUERY
        INSERT INTO metadata.etl_logs (start_ts)
        VALUES (CURRENT_TIMESTAMP)
        RETURNING id;
    ELSE
        UPDATE metadata.etl_logs
        SET upd = _upd,
            ins = _ins,
            end_ts = CURRENT_TIMESTAMP,
            info_msg = _info_msg,
            err_msg = _err_msg
        WHERE id = _id;
    END IF;
    RETURN;
END;
$$
