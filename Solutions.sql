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
SELECT row_number() over (ORDER BY maker, CASE
                                              WHEN type = 'PC' then 1
                                              WHEN type = 'Laptop' then 2
                                              else 3
    end),
       maker,
       type
FROM (SELECT DISTINCT maker, type
      FROM product
      ORDER BY maker, type) t1
ORDER BY maker,
         CASE
             WHEN type = 'PC' then 1
             WHEN type = 'Laptop' then 2
             else 3
             end


