CREATE TABLE public.spine_date (
    id INTEGER NOT NULL,
    yyyymm INTEGER,
    CONSTRAINT spine_date_PK PRIMARY KEY (id) ENABLED
);

INSERT INTO public.spine_date(id, yyyymm) values (1, 200001);
INSERT INTO public.spine_date select MAX(ID)+1 AS ID, TO_NUMBER(to_char(add_months(to_date(to_char(max(yyyymm)), 'yyyymm') , 1 ), 'YYYYMM')) AS YYYYMM from public.spine_date;
