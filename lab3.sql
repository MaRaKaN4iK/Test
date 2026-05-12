-- Таблица узлов: Мужчины
USE master; 
GO
DROP DATABASE IF EXISTS FamilyTree;
CREATE DATABASE FamilyTree; 
GO
USE FamilyTree; 
CREATE TABLE Men (
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    BirthDate DATE
) AS NODE;

-- Таблица узлов: Женщины
CREATE TABLE Women (
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    BirthDate DATE
) AS NODE;

-- Таблица узлов: Города
CREATE TABLE Cities (
    ID INT PRIMARY KEY,
    CityName NVARCHAR(100)
) AS NODE;
-- Связь: Родительство (направленная: от родителя к ребенку)
CREATE TABLE ParentOf (
    RelationshipType NVARCHAR(20), -- 'Biological' или 'Adoptive'
    CONSTRAINT EC_ParentOf CONNECTION (
        Men TO Men, Men TO Women, 
        Women TO Men, Women TO Women
    )
) AS EDGE;

-- Связь: Брак (направленная, но обычно создается симметрично)
CREATE TABLE MarriedTo (
    MarriageDate DATE,
    Status NVARCHAR(20), -- 'Active', 'Divorced'
    CONSTRAINT EC_MarriedTo CONNECTION (Men TO Women, Women TO Men)
) AS EDGE;

-- Связь: Местоположение (проживание/рождение)
CREATE TABLE LivesIn (
    SinceYear INT,
    CONSTRAINT EC_LivesIn CONNECTION (
        Men TO Cities, Women TO Cities
    )
) AS EDGE;
-- Заполнение городов
INSERT INTO Cities (ID, CityName) VALUES (1, 'Москва'), (2, 'Санкт-Петербург'), (3, 'Новосибирск');

-- Заполнение узлов Men
INSERT INTO Men (ID, Name, BirthDate) VALUES 
(1, 'Иван', '1950-05-10'), (2, 'Петр', '1975-03-15'),
(3, 'Алексей', '2000-01-20'), (4, 'Сергей', '1980-11-05'),
(5, 'Дмитрий', '1990-07-12'), (6, 'Андрей', '1965-12-30'),
(7, 'Николай', '1992-03-12'),
(8, 'Игорь', '1985-07-25'),
(9, 'Владимир', '1970-11-30'),
(10, 'Михаил', '2010-05-05');

-- Заполнение узлов Women
INSERT INTO Women (ID, Name, BirthDate) VALUES 
(1, 'Мария', '1955-08-25'), (2, 'Елена', '1978-06-14'),
(3, 'Ольга', '1982-02-10'), (4, 'Анна', '2005-09-15'),
(5, 'Светлана', '1968-04-03'), (6, 'Татьяна', '1995-10-22'),
(7, 'Ирина', '1973-02-14'),
(8, 'Наталья', '1988-09-20'),
(9, 'Марина', '1986-12-12'),
(10, 'Юлия', '2012-08-18');

-- 1. Устанавливаем браки
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES (
    (SELECT $node_id FROM Men WHERE ID = 1), 
    (SELECT $node_id FROM Women WHERE ID = 1), 
    '1973-09-01', 'Active'
);
-- 1. Брак Петра и Елены (Связываем ID 2 и ID 2)
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES (
    (SELECT $node_id FROM Men WHERE ID = 2), 
    (SELECT $node_id FROM Women WHERE ID = 2), 
    '1998-05-20', 'Active'
);

-- 2. Брак Сергея и Ольги(Связываем ID 4 и ID 3)
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES (
    (SELECT $node_id FROM Men WHERE ID = 4), 
    (SELECT $node_id FROM Women WHERE ID = 3), 
    '2005-10-12', 'Active'
);

-- 3. Брак Андрея и Светланы(Связываем ID 6 и ID 5)
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES (
    (SELECT $node_id FROM Men WHERE ID = 6), 
    (SELECT $node_id FROM Women WHERE ID = 5), 
    '1988-12-01', 'Active'
);
-- 4. Брак Владимира и Ирины(Связываем ID 9 и ID 7)
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES (
    (SELECT $node_id FROM Men WHERE ID = 9), 
    (SELECT $node_id FROM Women WHERE ID = 7), 
    '1994-02-14', 'Active'
);

-- 5. Брак Игоря и Марины (Связываем ID 8 и ID 9)
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES (
    (SELECT $node_id FROM Men WHERE ID = 8), 
    (SELECT $node_id FROM Women WHERE ID = 9), 
    '2010-07-07', 'Active'
);

-- 2. Устанавливаем родительство (Иван и Мария -> Петр)
INSERT INTO ParentOf ($from_id, $to_id, RelationshipType)
VALUES 
    ((SELECT $node_id FROM Men WHERE ID = 1), (SELECT $node_id FROM Men WHERE ID = 2), 'Biological'),
    ((SELECT $node_id FROM Women WHERE ID = 1), (SELECT $node_id FROM Men WHERE ID = 2), 'Biological');

-- 3. Устанавливаем проживание
INSERT INTO LivesIn ($from_id, $to_id, SinceYear)
VALUES 
    ((SELECT $node_id FROM Men WHERE ID = 3), (SELECT $node_id FROM Cities WHERE ID = 1), 2000),
    ((SELECT $node_id FROM Women WHERE ID = 4), (SELECT $node_id FROM Cities WHERE ID = 2), 2020);

-- 1. Связываем Петра (ID 2) и Алексея (ID 3), чтобы Алексей стал ВНУКОМ Ивана
INSERT INTO ParentOf ($from_id, $to_id, RelationshipType)
VALUES ((SELECT $node_id FROM Men WHERE ID = 2), (SELECT $node_id FROM Men WHERE ID = 3), 'Biological');

-- 2. Добавим жену Петру (Елена ID 2), чтобы сработал запрос про "Невесток/Свекровей"
INSERT INTO MarriedTo ($from_id, $to_id, MarriageDate, Status)
VALUES ((SELECT $node_id FROM Men WHERE ID = 2), (SELECT $node_id FROM Women WHERE ID = 2), '2000-01-01', 'Active');

-- 3. Добавим Анну (ID 4) как дочь Алексея (ID 3), чтобы была цепочка из 4-х узлов (Правнучка)
INSERT INTO ParentOf ($from_id, $to_id, RelationshipType)
VALUES ((SELECT $node_id FROM Men WHERE ID = 3), (SELECT $node_id FROM Women WHERE ID = 4), 'Biological');

-- 4. Чтобы запрос №5 (Город <- Муж -> Жена) сработал, поселим Ивана в тот же город, где Мария
INSERT INTO LivesIn ($from_id, $to_id, SinceYear)
VALUES 
((SELECT $node_id FROM Men WHERE ID = 1), (SELECT $node_id FROM Cities WHERE ID = 1), 1970),
((SELECT $node_id FROM Women WHERE ID = 1), (SELECT $node_id FROM Cities WHERE ID = 1), 1970);
    SELECT Parent.Name AS ParentName, Child.Name AS ChildName, City.CityName
FROM Men AS Parent, ParentOf, Men AS Child, LivesIn, Cities AS City
WHERE MATCH(Parent-(ParentOf)->Child-(LivesIn)->City);

SELECT GrandFather.Name AS GrandFather, GrandSon.Name AS GrandSon, City.CityName
FROM Men AS GrandFather, ParentOf AS Edge1, Men AS Father, 
     ParentOf AS Edge2, Men AS GrandSon, LivesIn, Cities AS City
WHERE MATCH(GrandFather-(Edge1)->Father-(Edge2)->GrandSon-(LivesIn)->City);

SELECT Wife.Name, Child.Name, City.CityName
FROM Women AS Wife, MarriedTo, Men AS Husband, 
     ParentOf, Men AS Child, LivesIn, Cities AS City
WHERE MATCH(Wife-(MarriedTo)->Husband-(ParentOf)->Child-(LivesIn)->City);

SELECT Mother.Name AS MotherInLaw, Son.Name AS Son, DaughterInLaw.Name AS DaughterInLaw
FROM Women AS Mother, ParentOf, Men AS Son, MarriedTo, Women AS DaughterInLaw
WHERE MATCH(Mother-(ParentOf)->Son-(MarriedTo)->DaughterInLaw);

SELECT GrandPa.Name, GrandDaughter.Name
FROM Men AS GrandPa, ParentOf AS E1, Men AS Father, ParentOf AS E2, Women AS GrandDaughter
WHERE MATCH(GrandPa-(E1)->Father-(E2)->GrandDaughter);

SELECT City.CityName, Husband.Name, Wife.Name
FROM Cities AS City, LivesIn, Men AS Husband, MarriedTo, Women AS Wife
WHERE MATCH(City<-(LivesIn)-Husband-(MarriedTo)->Wife);

-- Кратчайший путь от предка к потомкам до 5 колена
WITH T1 AS (
    SELECT 
        StartNode.FullName AS PersonName,
        -- Собираем цепочку имен через разделитель
        STRING_AGG(TargetNode.Name, ' -> ') WITHIN GROUP (GRAPH PATH) AS FamilyPath,
        -- Извлекаем имя последнего узла в пути для фильтрации
        LAST_VALUE(TargetNode.Name) WITHIN GROUP (GRAPH PATH) AS LastNode
    FROM 
        Men AS StartNode,
        ParentOf FOR PATH AS rel,
        Men FOR PATH AS TargetNode
    WHERE MATCH(SHORTEST_PATH(StartNode(-(rel)->TargetNode)+))
    AND StartNode.Name = 'Иван'
)


SELECT 
    StartP.Name AS [Основатель рода],
    -- Используем LAST_NODE для идентификации конца цепочки
    LAST_NODE(NextP.FullName) AS [Самый младший потомок],
    -- Собираем всю цепочку имен
    STRING_AGG(NextP.Name, ' -> ') WITHIN GROUP (GRAPH PATH) AS [Полная родословная]
FROM 
    Men AS StartP,
    ParentOf FOR PATH AS rel,
    Men FOR PATH AS NextP
WHERE MATCH(SHORTEST_PATH(StartP(-(rel)->NextP)+))
AND StartP.ID = 1;


SELECT 
    P1.$from_id AS GrandPa, 
    P1.$to_id AS SharedFather, 
    P2.$to_id AS GrandSon
FROM ParentOf P1, ParentOf P2
WHERE P1.$to_id = P2.$from_id; 


