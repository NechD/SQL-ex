-- 59. Посчитать остаток денежных средств на каждом пункте приема для базы данных с отчетностью не чаще одного раза в день.
--     Вывод: пункт, остаток.
SELECT point,
       CASE
           WHEN total_out IS NOT NULL THEN total_inc - total_out
           ELSE total_inc
           END as result
FROM (SELECT point, SUM(inc) as total_inc
      FROM Income_o
      GROUP BY point) t1
         LEFT JOIN
     (SELECT point, SUM(out) as total_out
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
FROM (SELECT point, sum(inc) as total_inc
      FROM income_o
      WHERE date < '15/04/2001'
      GROUP BY point) t1
         FULL OUTER JOIN
     (SELECT point, sum(out) as total_out
      FROM outcome_o
      WHERE date < '15/04/2001'
      GROUP BY point) t2 USING (point)
ORDER BY point;


-- 61. Посчитать остаток денежных средств на всех пунктах приема для базы данных с отчетностью не чаще одного раза в день.
SELECT SUM(total_inc) as total_result
FROM (SELECT SUM(inc) as total_inc
      FROM Income_o
      UNION ALL
      SELECT SUM(out) * -1 as total_out
      FROM Outcome_o) t1;

-- 62. Посчитать остаток денежных средств на всех пунктах приема на начало дня 15/04/01
-- для базы данных с отчетностью не чаще одного раза в день.
SELECT SUM(total_inc) as total_result
FROM (SELECT SUM(inc) as total_inc
      FROM Income_o
      WHERE date < '15/04/2001'
      UNION ALL
      SELECT SUM(out) * -1 as total_out
      FROM Outcome_o
      WHERE date < '15/04/2001') t1;

-- 63. БД "Аэрофлот"
-- Определить имена разных пассажиров, когда-либо летевших на одном и том же месте более одного раза.
-- (среди пассажиров могут быть однофамильцы (одинаковые значения поля name, например, Bruce Willis)
SELECT name
FROM (SELECT DISTINCT p.id_psg, name
      FROM pass_in_trip
               LEFT JOIN passenger p on pass_in_trip.id_psg = p.id_psg
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
             sum(inc) as total_inc
      FROM Income
      GROUP BY point, date) t1
         FULL OUTER JOIN
     (SELECT point,
             date,
             sum(out) as total_out
      FROM outcome
      GROUP BY point, date) t2
     USING (point, date)
WHERE total_inc IS NULL
   or total_out IS NULL
ORDER BY point, date;

-- 65. БД "Компьютерная фирма"
-- Пронумеровать уникальные пары {maker, type} из Product, упорядочив их следующим образом:
-- - имя производителя (maker) по возрастанию;
-- - тип продукта (type) в порядке PC, Laptop, Printer.
-- Если некий производитель выпускает несколько типов продукции, то выводить его имя только в первой строке;
-- остальные строки для ЭТОГО производителя должны содержать пустую строку символов ('').
Select row_number() over () as row_number,
       Case
           when lag(maker, 1) over (order by maker, case
                                                        when type = 'PC' then 1
                                                        when type = 'Laptop' then 2
                                                        when type = 'Printer' then 3 end) = maker then ''
           Else maker
           End              as maker,
       type
From (select distinct maker, type from product) t1
Order by row_number

-- 66. БД "Аэрофлот"
-- Для всех дней в интервале с 01/04/2003 по 07/04/2003 определить число рейсов из Rostov с пассажирами на борту.
-- Вывод: дата, количество рейсов.
-- ошибка в базе
WITH t1 AS (SELECT generate_series('2003-04-01'::timestamp, '2003-07-04'::timestamp,
                                   '1 day'::interval)::date as all_datas),
     t2 AS
         (SELECT COUNT(DISTINCT trip_no) as number_flights,
                 time_out::date
          FROM trip
          WHERE town_from = 'Rostov'
            and trip_no IN (SELECT DISTINCT trip_no
                            FROM pass_in_trip)
          GROUP BY time_out::date)
SELECT all_datas, coalesce(number_flights, 0) as number_flights_in_day
FROM t1
         LEFT JOIN t2 on t1.all_datas = t2.time_out;

--67. БД "Аэрофлот"
-- Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
-- Замечания.
-- 1) A - B и B - A считать РАЗНЫМИ маршрутами.
-- 2) Использовать только таблицу Trip
WITH t1 AS (SELECT town_from, town_to, COUNT(DISTINCT trip_no) AS num_reises
            FROM trip
            GROUP BY town_from, town_to)
SELECT count(num_reises)
FROM t1
WHERE num_reises = (SELECT max(num_reises) FROM t1)

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
     t2 AS (SELECT town_from, town_to, COUNT(DISTINCT trip_no) as num_reises
            FROM t1
            GROUP BY town_from, town_to)
SELECT COUNT(*) / 2 as max_reises
FROM t2
WHERE num_reises = (SELECT max(num_reises) FROM t2)

-- 2 способ
with tt1 as
    (select trip_no                                                       tn,
            case when town_from < town_to then town_from else town_to end tf,
            case when town_from < town_to then town_to else town_from end tt
     from Trip)
   , tt2 as
        (select count(tn) qty from tt1 group by tf, tt)
   , tt3 as
    (select count(tn) mqt from tt1 group by tf, tt having count(tn) = (select max(qty) from tt2))

select count(mqt) qt
from tt3

--68. БД "Вторсырье"
-- По таблицам Income и Outcome для каждого пункта приема найти остатки денежных средств на конец каждого дня,
-- в который выполнялись операции по приходу и/или расходу на данном пункте.
-- Учесть при этом, что деньги не изымаются, а остатки/задолженность переходят на следующий день.
-- Вывод: пункт приема, день в формате "dd/mm/yyyy", остатки/задолженность на конец этого дня.
-- p.s Приведенное ниже решение система не принимает, т.к. в задании подразумевается неупорядоченный по возрастанию дат вывод итогов.
SElECT point,
       date::date,
       SUM(COALESCE(total_inc, 0) - COALESCE(total_out, 0))
       OVER (PARTITION BY point ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM (SELECT point, date, sum(inc) as total_inc
      FROM income
      GROUP BY point, date
      ORDER BY point, date) t1
         FULL OUTER JOIN
     (SELECT point, date, sum(out) as total_out
      FROM Outcome
      GROUP BY point, date
      ORDER BY point, date) t2 USING (point, date)

