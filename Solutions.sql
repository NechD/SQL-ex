-- 59. Посчитать остаток денежных средств на каждом пункте приема для базы данных с отчетностью не чаще одного раза в день.
--     Вывод: пункт, остаток.
SELECT point,
       CASE
           WHEN total_out IS NOT NULL THEN total_inc - total_out
           ELSE total_inc
           END AS result
FROM (SELECT point, SUM(inc) AS total_inc
      FROM Income_o
      GROUP BY point) t1
         LEFT JOIN
     (SELECT point, SUM(out) AS total_out
      FROM Outcome_o
      GROUP BY point) t2 USING (point)
ORDER BY point;

-- 60. Посчитать остаток денежных средств на начало дня 15/04/01 на каждом пункте приема для базы данных
-- с отчетностью не чаще одного раза в день.
-- Вывод: пункт, остаток.
-- Замечание. Не учитывать пункты, информации о которых нет до указанной даты.

SELECT point,
       CASE
           WHEN total_out IS NOT NULL THEN total_inc - total_out
           ELSE total_inc
           END AS result
FROM (SELECT point, SUM(inc) AS total_inc
      FROM income_o
      WHERE date < '15/04/2001'
      GROUP BY point) t1
         FULL OUTER JOIN
     (SELECT point, SUM(out) AS total_out
      FROM outcome_o
      WHERE date < '15/04/2001'
      GROUP BY point) t2 USING (point)
ORDER BY point;


-- 61. Посчитать остаток денежных средств на всех пунктах приема для базы данных с отчетностью не чаще одного раза в день.
SELECT SUM(total_inc) AS total_result
FROM (SELECT SUM(inc) AS total_inc
      FROM Income_o
      UNION ALL
      SELECT SUM(out) * -1 AS total_out
      FROM Outcome_o) t1;

-- 62. Посчитать остаток денежных средств на всех пунктах приема на начало дня 15/04/01
-- для базы данных с отчетностью не чаще одного раза в день.
SELECT SUM(total_inc) AS total_result
FROM (SELECT SUM(inc) AS total_inc
      FROM Income_o
      WHERE date < '15/04/2001'
      UNION ALL
      SELECT SUM(out) * -1 AS total_out
      FROM Outcome_o
      WHERE date < '15/04/2001') t1;

-- 63. БД "Аэрофлот"
-- Определить имена разных пассажиров, когда-либо летевших на одном и том же месте более одного раза.
-- (среди пассажиров могут быть однофамильцы (одинаковые значения поля name, например, Bruce Willis)
SELECT name
FROM (SELECT DISTINCT p.id_psg, name
      FROM pass_in_trip
               LEFT JOIN passenger p ON pass_in_trip.id_psg = p.id_psg
      GROUP BY p.id_psg, place
      HAVING COUNT(*) > 1) t1;

-- второй вариант решения
SELECT name
FROM passenger
WHERE id_psg IN (SELECT id_psg
                 FROM pass_in_trip
                 GROUP BY id_psg, place
                 HAVING COUNT(*) > 1);

-- 64. БД "Фирма вторсырья"
-- Используя таблицы Income и Outcome, для каждого пункта приема определить дни, когда был приход,
-- но не было расхода и наоборот.
-- Вывод: пункт, дата, тип операции (inc/out), денежная сумма за день.
SELECT point,
       date,
       CASE
           WHEN total_inc IS NULL THEN 'out'
           ELSE 'inc'
           END                        AS operation_type,
       COALESCE(total_inc, total_out) AS result
FROM (SELECT point,
             date,
             SUM(inc) AS total_inc
      FROM Income
      GROUP BY point, date) t1
         FULL OUTER JOIN
     (SELECT point,
             date,
             SUM(out) AS total_out
      FROM outcome
      GROUP BY point, date) t2
     USING (point, date)
WHERE total_inc IS NULL
   OR total_out IS NULL
ORDER BY point, date;

-- 65. БД "Компьютерная фирма"
-- Пронумеровать уникальные пары {maker, type} из Product, упорядочив их следующим образом:
-- - имя производителя (maker) по возрастанию;
-- - тип продукта (type) в порядке PC, Laptop, Printer.
-- Если некий производитель выпускает несколько типов продукции, то выводить его имя только в первой строке;
-- остальные строки для ЭТОГО производителя должны содержать пустую строку символов ('').
SELECT ROW_NUMBER() OVER () AS row_number,
       CASE
           WHEN LAG(maker, 1) OVER (ORDER BY maker, CASE
                                                        WHEN type = 'PC' THEN 1
                                                        WHEN type = 'Laptop' THEN 2
                                                        WHEN type = 'Printer' THEN 3 END) = maker THEN ''
           ELSE maker
           END              AS maker,
       type
FROM (SELECT DISTINCT maker, type FROM product) t1
ORDER BY row_number;

-- 66. БД "Аэрофлот"
-- Для всех дней в интервале с 01/04/2003 по 07/04/2003 определить число рейсов из Rostov с пассажирами на борту.
-- Вывод: дата, количество рейсов.
-- ошибка в базе
WITH t1 AS (SELECT GENERATE_SERIES('2003-04-01'::timestamp, '2003-07-04'::timestamp,
                                   '1 day'::interval)::date AS all_datas),
     t2 AS
         (SELECT COUNT(DISTINCT trip_no) AS number_flights,
                 time_out::date
          FROM trip
          WHERE town_from = 'Rostov'
            AND trip_no IN (SELECT DISTINCT trip_no
                            FROM pass_in_trip)
          GROUP BY time_out::date)
SELECT all_datas, COALESCE(number_flights, 0) AS number_flights_in_day
FROM t1
         LEFT JOIN t2 ON t1.all_datas = t2.time_out;

--67. БД "Аэрофлот"
-- Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
-- Замечания.
-- 1) A - B и B - A считать РАЗНЫМИ маршрутами.
-- 2) Использовать только таблицу Trip
WITH t1 AS (SELECT town_from, town_to, COUNT(DISTINCT trip_no) AS num_reises
            FROM trip
            GROUP BY town_from, town_to)
SELECT COUNT(num_reises)
FROM t1
WHERE num_reises = (SELECT MAX(num_reises) FROM t1);

--68. БД "Аэрофлот"
-- Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
-- Замечания.
-- 1) A - B и B - A считать ОДНИМ И ТЕМ ЖЕ маршрутом.
-- 2) Использовать только таблицу Trip
WITH t1 AS (SELECT trip_no, town_from, town_to
            FROM trip
            UNION ALL
            SELECT trip_no, town_to, town_from
            FROM trip),
     t2 AS (SELECT town_from, town_to, COUNT(DISTINCT trip_no) AS num_reises
            FROM t1
            GROUP BY town_from, town_to)
SELECT COUNT(*) / 2 AS max_reises
FROM t2
WHERE num_reises = (SELECT MAX(num_reises) FROM t2);

-- 2 способ
WITH tt1 AS
    (SELECT trip_no                                                       tn,
            CASE WHEN town_from < town_to THEN town_from ELSE town_to END tf,
            CASE WHEN town_from < town_to THEN town_to ELSE town_from END tt
     FROM Trip)
   , tt2 AS
        (SELECT COUNT(tn) qty FROM tt1 GROUP BY tf, tt)
   , tt3 AS
    (SELECT COUNT(tn) mqt FROM tt1 GROUP BY tf, tt HAVING COUNT(tn) = (SELECT MAX(qty) FROM tt2))

SELECT COUNT(mqt) qt
FROM tt3;

--69. БД "Вторсырье"
-- По таблицам Income и Outcome для каждого пункта приема найти остатки денежных средств на конец каждого дня,
-- в который выполнялись операции по приходу и/или расходу на данном пункте.
-- Учесть при этом, что деньги не изымаются, а остатки/задолженность переходят на следующий день.
-- Вывод: пункт приема, день в формате "dd/mm/yyyy", остатки/задолженность на конец этого дня.
-- p.s Приведенное ниже решение система не принимает, т.к. в задании подразумевается неупорядоченный по возрастанию дат вывод итогов.
SELECT point,
       date::date,
       SUM(COALESCE(total_inc, 0) - COALESCE(total_out, 0))
       OVER (PARTITION BY point ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM (SELECT point, date, SUM(inc) AS total_inc
      FROM income
      GROUP BY point, date
      ORDER BY point, date) t1
         FULL OUTER JOIN
     (SELECT point, date, SUM(out) AS total_out
      FROM Outcome
      GROUP BY point, date
      ORDER BY point, date) t2 USING (point, date);

--70. БД "Корабли"
-- Укажите сражения, в которых участвовало по меньшей мере три корабля одной и той же страны.
WITH t1 AS
         (SELECT ship, battle, country
          FROM outcomes
                   INNER JOIN ships ON Ships.name = Outcomes.ship
                   INNER JOIN Classes USING (Class)
          UNION
          SELECT ship, battle, country
          FROM outcomes
                   INNER JOIN Classes ON Classes.class = Outcomes.ship)
SELECT DISTINCT battle
FROM t1
GROUP BY country, battle
HAVING COUNT(DISTINCT ship) >= 3;

--71. БД "Компьютерная фирма"
-- Найти тех производителей ПК, все модели ПК которых имеются AS
SELECT DISTINCT maker
FROM product p1
WHERE type = 'PC'
  AND NOT EXISTS(SELECT model
                 FROM product p2
                 WHERE type = 'PC'
                   AND p2.maker = p1.maker
                 EXCEPT
                 SELECT pc.model
                 FROM PC
    );

-- 72. БД 'Аэрофлот'
-- Среди тех, кто пользуется услугами только какой-нибудь одной компании, определить имена разных пассажиров,
-- летавших чаще других.
-- Вывести: имя пассажира и число полетов.
WITH t1 AS
         (SELECT id_psg, COUNT(trip_no) AS count_flights
          FROM pass_in_trip
                   INNER JOIN trip USING (trip_no)
          GROUP BY id_psg
          HAVING COUNT(DISTINCT id_comp) = 1
          ORDER BY count_flights DESC)
SELECT DISTINCT name, count_flights
FROM t1
         INNER JOIN passenger USING (id_psg)
WHERE count_flights = (SELECT MAX(count_flights) FROM t1);

-- 73. БД 'Корабли'
-- Для каждой страны определить сражения, в которых не участвовали корабли данной страны.
-- Вывод: страна, сражение
WITH t1 AS (SELECT DISTINCT country, battle
            FROM outcomes
                     LEFT JOIN ships ON outcomes.ship = ships.name
                     INNER JOIN classes ON ships.class = classes.class OR outcomes.ship = classes.class
            GROUP BY country, battle)
SELECT country, name
FROM battles,
     classes
EXCEPT
SELECT country, battle
FROM t1;

-- 74. БД 'Корабли'
-- Вывести все классы кораблей России (Russia).
-- Если в базе данных нет классов кораблей России, вывести классы для всех имеющихся в БД стран.
-- Вывод: страна, класс
SELECT country, class
FROM classes
WHERE CASE
          WHEN EXISTS(SELECT class FROM classes WHERE country = 'Russia') THEN country = 'Russia'
          ELSE country <> 'Russia'
          END;

-- 75. БД "Компьютерная фирма"
-- Для тех производителей, у которых есть продукты с известной ценой хотя бы в одной из таблиц Laptop, PC, Printer
-- найти максимальные цены на каждый из типов продукции.
-- Вывод: maker, максимальная цена на ноутбуки, максимальная цена на ПК, максимальная цена на принтеры.
-- Для отсутствующих продуктов/цен использовать NULL.
WITH t1 AS (SELECT p.maker,
                   p.model,
                   pc.price AS pcprice,
                   lt.price AS ltprice,
                   pr.price AS prprice
            FROM product p
                     LEFT JOIN laptop lt ON
                p.model = lt.model
                     LEFT JOIN pc ON p.model = pc.model
                     LEFT JOIN printer pr ON
                p.model = pr.model)
SELECT maker,
       MAX(ltprice) AS laptop,
       MAX(pcprice) AS pc,
       MAX(prprice) AS printer
FROM t1
WHERE maker IN (SELECT maker
                FROM t1
                WHERE COALESCE(prprice, ltprice, pcprice) IS NOT NULL)
GROUP BY maker;

-- 76.  БД 'Аэрофлот'
-- Определить время, проведенное в полетах, для пассажиров, летавших всегда на разных местах.
-- Вывод: имя пассажира, время в минутах.
-- WITH t1 AS (SELECT DISTINCT id_psg
--             FROM pass_in_trip
--             GROUP BY id_psg, place
--             HAVING COUNT(*) > 1)
-- SELECT id_psg,
--        SUM(EXTRACT(MINUTE FROM (time_in - time_out)))
-- FROM pass_in_trip
--          INNER JOIN trip USING (trip_no)
--          INNER JOIN passenger USING (id_psg)
-- WHERE id_psg NOT IN (SELECT id_psg FROM t1)
-- GROUP BY id_psg;

-- 77. Определить дни, когда было выполнено максимальное число рейсов из
-- Ростова ('Rostov'). Вывод: число рейсов, дата.
WITH t1 AS (SELECT COUNT(DISTINCT trip_no) AS num_trips, DATE
            FROM trip
                     INNER JOIN pass_in_trip USING (trip_no)
            WHERE town_from = 'Rostov'
            GROUP BY DATE)
SELECT num_trips, date
FROM t1
WHERE num_trips = (SELECT MAX(num_trips) FROM t1);

-- 78. БД 'Корабли'
-- Для каждого сражения определить первый и последний день месяца, в котором оно состоялось.
-- Вывод: сражение, первый день месяца, последний день месяца.
SELECT DISTINCT name,
                DATE_TRUNC('month', date)::date AS first,
                (DATE_TRUNC('month', date) + INTERVAL '1 month' - INTERVAL '1 day')::date
FROM battles;