-- metadata.sessions DEFINITION
CREATE SEQUENCE IF NOT EXISTS metadata.Ssessions; 
ALTER SEQUENCE metadata.Ssessions CACHE 1;

CREATE TABLE metadata.sessions
(
    id int NOT NULL DEFAULT nextval('metadata.Ssessions'),
    session_id varchar(80) NOT NULL,
    ts timestamp DEFAULT (now())::timestamptz(6),
    msg varchar(1000),
    CONSTRAINT sessions_UN UNIQUE (session_id) DISABLED,
    CONSTRAINT sessions_PK PRIMARY KEY (id) ENABLED
);


-- INSERT DATA
INSERT INTO metadata.sessions (session_id, msg)
SELECT 
session_id,
NULL AS msg
FROM current_session
WHERE session_id NOT IN (SELECT session_id FROM metadata.sessions);
COMMIT;

SELECT id FROM metadata.sessions WHERE session_id = (SELECT session_id FROM current_session);
