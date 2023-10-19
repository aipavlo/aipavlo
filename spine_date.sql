CREATE TABLE public.spine_date (
    id INTEGER,
    yyyymm INTEGER
);

INSERT INTO core_3.spine_date(id, yyyymm) values (1, 200001);
INSERT INTO core_3.spine_date select MAX(ID)+1 AS ID, TO_NUMBER(to_char(add_months(to_date(to_char(max(yyyymm)), 'yyyymm') , 1 ), 'YYYYMM')) AS YYYYMM from core_3.spine_date;
