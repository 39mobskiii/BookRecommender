-- ============================================================
-- Проект: Графовая база данных "Рекомендатор книг"
-- Узлы  (NODE): User, Book, Genre, Author
-- Рёбра (EDGE): Reads, Recommends, WrittenBy, BelongsTo
-- ============================================================
-- Created:  12.05.2026
-- Modified: 12.05.2026
-- Model:    Microsoft SQL Server 2022
-- Database: MS SQL Server 2022
-- ============================================================

-- ============================================================
-- СОЗДАНИЕ БАЗЫ ДАННЫХ
-- ============================================================
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'BookRecommender')
BEGIN
    ALTER DATABASE BookRecommender SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE IF EXISTS BookRecommender;
END;
GO

CREATE DATABASE BookRecommender;
GO

USE BookRecommender;
GO

-- ============================================================
-- ЧАСТЬ 1: СОЗДАНИЕ ТАБЛИЦ УЗЛОВ (NODE TABLES)
-- ============================================================

-- ------------------------------------------------------------
-- Таблица узлов: User (Пользователи)
-- reading_level: beginner | intermediate | advanced
-- ------------------------------------------------------------
CREATE TABLE [dbo].[User]
(
    [id]            Int           NOT NULL,
    [username]      Nvarchar(60)  COLLATE Cyrillic_General_CI_AS NOT NULL,
    [email]         Nvarchar(100) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [age]           Int           NOT NULL,
    [city]          Nvarchar(50)  COLLATE Cyrillic_General_CI_AS NOT NULL,
    [reading_level] Nvarchar(20)  COLLATE Cyrillic_General_CI_AS NOT NULL
                    CHECK ([reading_level] = N'beginner'
                        OR [reading_level] = N'intermediate'
                        OR [reading_level] = N'advanced'),
    [joined_date]   Date          NOT NULL
)
AS NODE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[User]
    ADD CONSTRAINT [PK_User] PRIMARY KEY ([id])
    ON [PRIMARY];
GO

-- ------------------------------------------------------------
-- Таблица узлов: Book (Книги)
-- language: ru | en | fr | de | other
-- ------------------------------------------------------------
CREATE TABLE [dbo].[Book]
(
    [id]           Int           NOT NULL,
    [title]        Nvarchar(150) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [year]         Int           NOT NULL,
    [pages]        Int           NOT NULL,
    [language]     Nvarchar(10)  COLLATE Cyrillic_General_CI_AS NOT NULL
                   CHECK ([language] = N'ru' OR [language] = N'en'
                       OR [language] = N'fr' OR [language] = N'de'
                       OR [language] = N'other'),
    [avg_rating]   Decimal(3,2)  NOT NULL,
    [isbn]         Nvarchar(20)  COLLATE Cyrillic_General_CI_AS NOT NULL
)
AS NODE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[Book]
    ADD CONSTRAINT [PK_Book] PRIMARY KEY ([id])
    ON [PRIMARY];
GO

-- ------------------------------------------------------------
-- Таблица узлов: Genre (Жанры)
-- ------------------------------------------------------------
CREATE TABLE [dbo].[Genre]
(
    [id]          Int           NOT NULL,
    [name]        Nvarchar(60)  COLLATE Cyrillic_General_CI_AS NOT NULL,
    [description] Nvarchar(300) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [is_fiction]  Bit           DEFAULT ((1)) NOT NULL
)
AS NODE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[Genre]
    ADD CONSTRAINT [PK_Genre] PRIMARY KEY ([id])
    ON [PRIMARY];
GO

-- ------------------------------------------------------------
-- Таблица узлов: Author (Авторы)
-- ------------------------------------------------------------
CREATE TABLE [dbo].[Author]
(
    [id]           Int           NOT NULL,
    [name]         Nvarchar(100) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [birth_year]   Int           NOT NULL,
    [nationality]  Nvarchar(50)  COLLATE Cyrillic_General_CI_AS NOT NULL,
    [is_alive]     Bit           DEFAULT ((1)) NOT NULL
)
AS NODE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[Author]
    ADD CONSTRAINT [PK_Author] PRIMARY KEY ([id])
    ON [PRIMARY];
GO

-- ============================================================
-- ЧАСТЬ 2: СОЗДАНИЕ ТАБЛИЦ РЁБЕР (EDGE TABLES)
-- ============================================================

-- ------------------------------------------------------------
-- Ребро: Reads (User -> Book)
-- Пользователь прочитал книгу.
-- status: reading | finished | abandoned | wishlist
-- ------------------------------------------------------------
CREATE TABLE [dbo].[Reads]
(
    [started_date]  Date          NULL,
    [finished_date] Date          NULL,
    [user_rating]   Decimal(3,2)  NULL,
    [status]        Nvarchar(20)  COLLATE Cyrillic_General_CI_AS NOT NULL
                    CHECK ([status] = N'reading'   OR [status] = N'finished'
                        OR [status] = N'abandoned' OR [status] = N'wishlist'),
    [review]        Nvarchar(500) COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[Reads]
    ADD CONSTRAINT [EC_Reads] CONNECTION ([User] TO [Book]);
GO

-- ------------------------------------------------------------
-- Ребро: Recommends (User -> User)
-- Один пользователь рекомендует книгу другому.
-- ------------------------------------------------------------
CREATE TABLE [dbo].[Recommends]
(
    [book_id]       Int           NOT NULL,
    [recommend_date] Date         NOT NULL,
    [comment]       Nvarchar(300) COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[Recommends]
    ADD CONSTRAINT [EC_Recommends] CONNECTION ([User] TO [User]);
GO

-- ------------------------------------------------------------
-- Ребро: WrittenBy (Book -> Author)
-- Книга написана автором.
-- role: author | co-author | translator
-- ------------------------------------------------------------
CREATE TABLE [dbo].[WrittenBy]
(
    [role]           Nvarchar(20)  COLLATE Cyrillic_General_CI_AS NOT NULL
                     CHECK ([role] = N'author' OR [role] = N'co-author'
                         OR [role] = N'translator'),
    [contribution_pct] Int         NOT NULL DEFAULT (100)
)
AS EDGE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[WrittenBy]
    ADD CONSTRAINT [EC_WrittenBy] CONNECTION ([Book] TO [Author]);
GO

-- ------------------------------------------------------------
-- Ребро: BelongsTo (Book -> Genre)
-- Книга относится к жанру.
-- is_primary: 1 = основной жанр, 0 = второстепенный
-- ------------------------------------------------------------
CREATE TABLE [dbo].[BelongsTo]
(
    [is_primary]  Bit DEFAULT ((1)) NOT NULL,
    [tag]         Nvarchar(50) COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY];
GO

ALTER TABLE [dbo].[BelongsTo]
    ADD CONSTRAINT [EC_BelongsTo] CONNECTION ([Book] TO [Genre]);
GO

-- ============================================================
-- ЧАСТЬ 3: ЗАПОЛНЕНИЕ ТАБЛИЦ УЗЛОВ
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Данные: User (12 пользователей)
-- ------------------------------------------------------------
INSERT INTO [User] (id, username, email, age, city, reading_level, joined_date)
VALUES
    (1,  N'Александр Громов',    N'agromov@mail.ru',     32, N'Москва',          N'advanced',     '2020-01-15'),
    (2,  N'Мария Лисова',        N'mlisova@gmail.com',   25, N'Санкт-Петербург', N'intermediate', '2021-03-22'),
    (3,  N'Дмитрий Орлов',       N'dorl@yandex.ru',      40, N'Казань',          N'advanced',     '2019-07-08'),
    (4,  N'Анна Соколова',       N'asokolova@mail.ru',   19, N'Новосибирск',     N'beginner',     '2023-01-10'),
    (5,  N'Игорь Панов',         N'ipanov@gmail.com',    35, N'Екатеринбург',    N'advanced',     '2018-11-30'),
    (6,  N'Елена Быкова',        N'ebykova@yandex.ru',   28, N'Москва',          N'intermediate', '2022-05-17'),
    (7,  N'Сергей Тихонов',      N'stikhonov@mail.ru',   45, N'Нижний Новгород', N'advanced',     '2017-09-03'),
    (8,  N'Ольга Зимина',        N'ozimina@gmail.com',   22, N'Ростов-на-Дону',  N'beginner',     '2023-06-28'),
    (9,  N'Павел Крылов',        N'pkrylov@yandex.ru',   31, N'Самара',          N'intermediate', '2020-12-01'),
    (10, N'Наталья Ефимова',     N'nefimova@mail.ru',    37, N'Воронеж',         N'advanced',     '2019-04-14'),
    (11, N'Виктор Шмелёв',       N'vshmeljov@gmail.com', 50, N'Москва',          N'advanced',     '2016-08-20'),
    (12, N'Татьяна Лукьянова',   N'tlukyanova@mail.ru',  24, N'Краснодар',       N'intermediate', '2022-10-05');
GO

-- ------------------------------------------------------------
-- 3.2 Данные: Genre (10 жанров)
-- ------------------------------------------------------------
INSERT INTO Genre (id, name, description, is_fiction)
VALUES
    (1,  N'Классическая литература', N'Произведения, признанные образцами художественного мастерства', 1),
    (2,  N'Научная фантастика',      N'Жанр, основанный на научных допущениях и гипотезах',           1),
    (3,  N'Фэнтези',                 N'Произведения с элементами магии и вымышленных миров',           1),
    (4,  N'Детектив',                N'Произведения о расследовании преступлений',                     1),
    (5,  N'Исторический роман',      N'Произведения, действие которых происходит в прошлом',           1),
    (6,  N'Нон-фикшн',               N'Документальная и публицистическая литература',                  0),
    (7,  N'Психологический триллер',  N'Жанр с акцентом на психологическое напряжение',               1),
    (8,  N'Биография',               N'Описание жизни реального человека',                             0),
    (9,  N'Поэзия',                   N'Стихотворные произведения различных форм',                    1),
    (10, N'Антиутопия',              N'Жанр, описывающий нежелательное будущее общество',              1);
GO

-- ------------------------------------------------------------
-- 3.3 Данные: Author (10 авторов)
-- ------------------------------------------------------------
INSERT INTO Author (id, name, birth_year, nationality, is_alive)
VALUES
    (1,  N'Фёдор Достоевский',  1821, N'Русский',       0),
    (2,  N'Лев Толстой',        1828, N'Русский',       0),
    (3,  N'Михаил Булгаков',    1891, N'Русский',       0),
    (4,  N'Джордж Оруэлл',      1903, N'Британский',    0),
    (5,  N'Фрэнк Герберт',      1920, N'Американский',  0),
    (6,  N'Агата Кристи',       1890, N'Британский',    0),
    (7,  N'Умберто Эко',        1932, N'Итальянский',   0),
    (8,  N'Стивен Кинг',        1947, N'Американский',  1),
    (9,  N'Харуки Мураками',    1949, N'Японский',      1),
    (10, N'Маргарет Этвуд',     1939, N'Канадский',     1);
GO

-- ------------------------------------------------------------
-- 3.4 Данные: Book (15 книг)
-- ------------------------------------------------------------
INSERT INTO Book (id, title, year, pages, language, avg_rating, isbn)
VALUES
    (1,  N'Преступление и наказание', 1866, 608,  N'ru', 4.80, N'978-5-389-01921-4'),
    (2,  N'Война и мир',              1869, 1274, N'ru', 4.70, N'978-5-04-089463-6'),
    (3,  N'Мастер и Маргарита',       1967, 480,  N'ru', 4.90, N'978-5-389-08060-8'),
    (4,  N'1984',                     1949, 328,  N'en', 4.75, N'978-0-452-28423-4'),
    (5,  N'Дюна',                     1965, 688,  N'en', 4.60, N'978-0-441-17271-9'),
    (6,  N'Убийство в Восточном экспрессе', 1934, 272, N'en', 4.65, N'978-0-06-207350-2'),
    (7,  N'Имя розы',                 1980, 540,  N'en', 4.50, N'978-0-15-144647-6'),
    (8,  N'Сияние',                   1977, 447,  N'en', 4.55, N'978-0-385-12167-5'),
    (9,  N'Норвежский лес',           1987, 296,  N'en', 4.25, N'978-0-375-70402-1'),
    (10, N'Рассказ служанки',         1985, 311,  N'en', 4.55, N'978-0-385-49081-8'),
    (11, N'Идиот',                    1869, 640,  N'ru', 4.65, N'978-5-389-02122-4'),
    (12, N'Анна Каренина',            1878, 864,  N'ru', 4.60, N'978-5-04-102490-8'),
    (13, N'Скотный двор',             1945, 112,  N'en', 4.50, N'978-0-452-28424-1'),
    (14, N'Убийца на улице Морг',     1841, 80,   N'en', 4.20, N'978-5-389-04471-2'),
    (15, N'Братья Карамазовы',        1880, 824,  N'ru', 4.85, N'978-5-389-07254-2');
GO

-- ============================================================
-- ЧАСТЬ 4: ЗАПОЛНЕНИЕ ТАБЛИЦ РЁБЕР
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 WrittenBy: Книга → Автор
-- ------------------------------------------------------------
INSERT INTO WrittenBy ($from_id, $to_id, role, contribution_pct)
VALUES
    ((SELECT $node_id FROM Book WHERE id = 1),  (SELECT $node_id FROM Author WHERE id = 1), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 2),  (SELECT $node_id FROM Author WHERE id = 2), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 3),  (SELECT $node_id FROM Author WHERE id = 3), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 4),  (SELECT $node_id FROM Author WHERE id = 4), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 5),  (SELECT $node_id FROM Author WHERE id = 5), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 6),  (SELECT $node_id FROM Author WHERE id = 6), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 7),  (SELECT $node_id FROM Author WHERE id = 7), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 8),  (SELECT $node_id FROM Author WHERE id = 8), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 9),  (SELECT $node_id FROM Author WHERE id = 9), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 10), (SELECT $node_id FROM Author WHERE id = 10), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 11), (SELECT $node_id FROM Author WHERE id = 1), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 12), (SELECT $node_id FROM Author WHERE id = 2), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 13), (SELECT $node_id FROM Author WHERE id = 4), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 14), (SELECT $node_id FROM Author WHERE id = 6), N'author', 100),
    ((SELECT $node_id FROM Book WHERE id = 15), (SELECT $node_id FROM Author WHERE id = 1), N'author', 100);
GO

-- ------------------------------------------------------------
-- 4.2 BelongsTo: Книга → Жанр
-- Каждая книга получает основной и при наличии — второстепенный жанр
-- ------------------------------------------------------------
INSERT INTO BelongsTo ($from_id, $to_id, is_primary, tag)
VALUES
    -- Преступление и наказание → Классика (осн.) + Психологический триллер
    ((SELECT $node_id FROM Book WHERE id = 1), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'роман'),
    ((SELECT $node_id FROM Book WHERE id = 1), (SELECT $node_id FROM Genre WHERE id = 7), 0, N'психологизм'),
    -- Война и мир → Классика (осн.) + Исторический роман
    ((SELECT $node_id FROM Book WHERE id = 2), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'эпопея'),
    ((SELECT $node_id FROM Book WHERE id = 2), (SELECT $node_id FROM Genre WHERE id = 5), 0, N'война'),
    -- Мастер и Маргарита → Классика (осн.) + Фэнтези
    ((SELECT $node_id FROM Book WHERE id = 3), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'магический реализм'),
    ((SELECT $node_id FROM Book WHERE id = 3), (SELECT $node_id FROM Genre WHERE id = 3), 0, N'мистика'),
    -- 1984 → Антиутопия (осн.) + Научная фантастика
    ((SELECT $node_id FROM Book WHERE id = 4), (SELECT $node_id FROM Genre WHERE id = 10), 1, N'тоталитаризм'),
    ((SELECT $node_id FROM Book WHERE id = 4), (SELECT $node_id FROM Genre WHERE id = 2),  0, N'дистопия'),
    -- Дюна → Научная фантастика (осн.) + Фэнтези
    ((SELECT $node_id FROM Book WHERE id = 5), (SELECT $node_id FROM Genre WHERE id = 2), 1, N'космическая опера'),
    ((SELECT $node_id FROM Book WHERE id = 5), (SELECT $node_id FROM Genre WHERE id = 3), 0, N'эпик'),
    -- Убийство в Восточном экспрессе → Детектив (осн.)
    ((SELECT $node_id FROM Book WHERE id = 6), (SELECT $node_id FROM Genre WHERE id = 4), 1, N'ваниль'),
    -- Имя розы → Детектив (осн.) + Исторический роман
    ((SELECT $node_id FROM Book WHERE id = 7), (SELECT $node_id FROM Genre WHERE id = 4), 1, N'медиевальный'),
    ((SELECT $node_id FROM Book WHERE id = 7), (SELECT $node_id FROM Genre WHERE id = 5), 0, N'средневековье'),
    -- Сияние → Психологический триллер (осн.)
    ((SELECT $node_id FROM Book WHERE id = 8), (SELECT $node_id FROM Genre WHERE id = 7), 1, N'хоррор'),
    -- Норвежский лес → Классическая литература (осн.)
    ((SELECT $node_id FROM Book WHERE id = 9), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'роман взросления'),
    -- Рассказ служанки → Антиутопия (осн.) + Нон-фикшн мотивы
    ((SELECT $node_id FROM Book WHERE id = 10), (SELECT $node_id FROM Genre WHERE id = 10), 1, N'феминизм'),
    ((SELECT $node_id FROM Book WHERE id = 10), (SELECT $node_id FROM Genre WHERE id = 7), 0,  N'напряжение'),
    -- Идиот → Классика (осн.) + Психологический триллер
    ((SELECT $node_id FROM Book WHERE id = 11), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'роман'),
    ((SELECT $node_id FROM Book WHERE id = 11), (SELECT $node_id FROM Genre WHERE id = 7), 0, N'психологизм'),
    -- Анна Каренина → Классика (осн.) + Исторический роман
    ((SELECT $node_id FROM Book WHERE id = 12), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'роман'),
    ((SELECT $node_id FROM Book WHERE id = 12), (SELECT $node_id FROM Genre WHERE id = 5), 0, N'XIX век'),
    -- Скотный двор → Антиутопия (осн.)
    ((SELECT $node_id FROM Book WHERE id = 13), (SELECT $node_id FROM Genre WHERE id = 10), 1, N'аллегория'),
    -- Убийца на улице Морг → Детектив (осн.)
    ((SELECT $node_id FROM Book WHERE id = 14), (SELECT $node_id FROM Genre WHERE id = 4), 1, N'первый детектив'),
    -- Братья Карамазовы → Классика (осн.) + Психологический триллер
    ((SELECT $node_id FROM Book WHERE id = 15), (SELECT $node_id FROM Genre WHERE id = 1), 1, N'роман'),
    ((SELECT $node_id FROM Book WHERE id = 15), (SELECT $node_id FROM Genre WHERE id = 7), 0, N'философия');
GO

-- ------------------------------------------------------------
-- 4.3 Reads: Пользователь → Книга
-- ------------------------------------------------------------
INSERT INTO Reads ($from_id, $to_id, started_date, finished_date, user_rating, status, review)
VALUES
    -- Александр Громов
    ((SELECT $node_id FROM [User] WHERE id = 1), (SELECT $node_id FROM Book WHERE id = 1),
     '2024-01-05', '2024-01-28', 5.00, N'finished', N'Шедевр мировой литературы, обязательно к прочтению'),
    ((SELECT $node_id FROM [User] WHERE id = 1), (SELECT $node_id FROM Book WHERE id = 3),
     '2024-02-10', '2024-02-28', 5.00, N'finished', N'Лучшая книга на русском языке'),
    ((SELECT $node_id FROM [User] WHERE id = 1), (SELECT $node_id FROM Book WHERE id = 4),
     '2024-03-01', '2024-03-15', 4.80, N'finished', N'Пугающе актуально'),
    ((SELECT $node_id FROM [User] WHERE id = 1), (SELECT $node_id FROM Book WHERE id = 15),
     '2024-04-01', NULL,         NULL, N'reading',  N'Читаю сейчас, впечатляет'),
    -- Мария Лисова
    ((SELECT $node_id FROM [User] WHERE id = 2), (SELECT $node_id FROM Book WHERE id = 6),
     '2024-01-10', '2024-01-20', 4.50, N'finished', N'Классический детектив Кристи'),
    ((SELECT $node_id FROM [User] WHERE id = 2), (SELECT $node_id FROM Book WHERE id = 9),
     '2024-02-01', '2024-02-20', 4.00, N'finished', N'Атмосферный роман, советую'),
    ((SELECT $node_id FROM [User] WHERE id = 2), (SELECT $node_id FROM Book WHERE id = 10),
     '2024-03-05', '2024-03-30', 4.80, N'finished', NULL),
    -- Дмитрий Орлов
    ((SELECT $node_id FROM [User] WHERE id = 3), (SELECT $node_id FROM Book WHERE id = 5),
     '2023-11-01', '2023-11-30', 4.90, N'finished', N'Лучшая научная фантастика всех времён'),
    ((SELECT $node_id FROM [User] WHERE id = 3), (SELECT $node_id FROM Book WHERE id = 7),
     '2024-01-15', '2024-02-15', 4.70, N'finished', N'Погрузился в средневековую атмосферу'),
    ((SELECT $node_id FROM [User] WHERE id = 3), (SELECT $node_id FROM Book WHERE id = 4),
     '2024-03-10', '2024-03-25', 4.60, N'finished', NULL),
    -- Анна Соколова
    ((SELECT $node_id FROM [User] WHERE id = 4), (SELECT $node_id FROM Book WHERE id = 6),
     '2024-02-01', '2024-02-10', 4.20, N'finished', N'Первый детектив который читала'),
    ((SELECT $node_id FROM [User] WHERE id = 4), (SELECT $node_id FROM Book WHERE id = 14),
     '2024-03-01', NULL,         NULL, N'wishlist',  NULL),
    -- Игорь Панов
    ((SELECT $node_id FROM [User] WHERE id = 5), (SELECT $node_id FROM Book WHERE id = 2),
     '2023-09-01', '2023-11-01', 4.50, N'finished', N'Монументальное произведение'),
    ((SELECT $node_id FROM [User] WHERE id = 5), (SELECT $node_id FROM Book WHERE id = 12),
     '2023-12-01', '2024-01-15', 4.60, N'finished', NULL),
    ((SELECT $node_id FROM [User] WHERE id = 5), (SELECT $node_id FROM Book WHERE id = 11),
     '2024-02-01', '2024-03-01', 4.80, N'finished', N'Достоевский на высшем уровне'),
    -- Елена Быкова
    ((SELECT $node_id FROM [User] WHERE id = 6), (SELECT $node_id FROM Book WHERE id = 8),
     '2024-01-20', '2024-02-05', 4.30, N'finished', N'Жутко, но не оторваться'),
    ((SELECT $node_id FROM [User] WHERE id = 6), (SELECT $node_id FROM Book WHERE id = 10),
     '2024-03-01', '2024-03-20', 4.70, N'finished', NULL),
    ((SELECT $node_id FROM [User] WHERE id = 6), (SELECT $node_id FROM Book WHERE id = 13),
     '2024-04-01', '2024-04-10', 4.40, N'finished', N'Короткая, но мощная аллегория'),
    -- Сергей Тихонов
    ((SELECT $node_id FROM [User] WHERE id = 7), (SELECT $node_id FROM Book WHERE id = 1),
     '2023-10-01', '2023-10-25', 5.00, N'finished', N'Перечитывал пятый раз — всегда открываю что-то новое'),
    ((SELECT $node_id FROM [User] WHERE id = 7), (SELECT $node_id FROM Book WHERE id = 15),
     '2023-11-01', '2023-12-15', 5.00, N'finished', N'Философская глубина поражает'),
    ((SELECT $node_id FROM [User] WHERE id = 7), (SELECT $node_id FROM Book WHERE id = 3),
     '2024-01-01', '2024-01-20', 4.90, N'finished', NULL),
    -- Ольга Зимина
    ((SELECT $node_id FROM [User] WHERE id = 8), (SELECT $node_id FROM Book WHERE id = 6),
     '2024-03-15', '2024-03-25', 4.50, N'finished', N'Увлекательно, читала за один день'),
    ((SELECT $node_id FROM [User] WHERE id = 8), (SELECT $node_id FROM Book WHERE id = 9),
     '2024-04-01', NULL,         NULL, N'reading',  NULL),
    -- Павел Крылов
    ((SELECT $node_id FROM [User] WHERE id = 9), (SELECT $node_id FROM Book WHERE id = 5),
     '2024-01-01', '2024-01-30', 4.70, N'finished', N'Грандиозный мир, нетривиальный сюжет'),
    ((SELECT $node_id FROM [User] WHERE id = 9), (SELECT $node_id FROM Book WHERE id = 4),
     '2024-02-15', '2024-03-01', 4.80, N'finished', NULL),
    -- Наталья Ефимова
    ((SELECT $node_id FROM [User] WHERE id = 10), (SELECT $node_id FROM Book WHERE id = 7),
     '2023-12-01', '2024-01-10', 4.60, N'finished', N'Детектив + история = идеально'),
    ((SELECT $node_id FROM [User] WHERE id = 10), (SELECT $node_id FROM Book WHERE id = 1),
     '2024-02-01', '2024-02-22', 4.90, N'finished', N'Психологическая глубина зашкаливает'),
    -- Виктор Шмелёв
    ((SELECT $node_id FROM [User] WHERE id = 11), (SELECT $node_id FROM Book WHERE id = 2),
     '2024-01-01', '2024-03-01', 4.60, N'finished', N'Великая эпопея'),
    ((SELECT $node_id FROM [User] WHERE id = 11), (SELECT $node_id FROM Book WHERE id = 3),
     '2024-03-05', '2024-03-22', 4.90, N'finished', N'Бессмертное произведение'),
    -- Татьяна Лукьянова
    ((SELECT $node_id FROM [User] WHERE id = 12), (SELECT $node_id FROM Book WHERE id = 8),
     '2024-02-10', '2024-02-28', 4.20, N'finished', NULL),
    ((SELECT $node_id FROM [User] WHERE id = 12), (SELECT $node_id FROM Book WHERE id = 6),
     '2024-03-10', '2024-03-20', 4.60, N'finished', N'Классика детективного жанра');
GO

-- ------------------------------------------------------------
-- 4.4 Recommends: Пользователь → Пользователь (с указанием книги)
-- ------------------------------------------------------------
INSERT INTO Recommends ($from_id, $to_id, book_id, recommend_date, comment)
VALUES
    -- Александр рекомендует Марии "Мастер и Маргарита"
    ((SELECT $node_id FROM [User] WHERE id = 1), (SELECT $node_id FROM [User] WHERE id = 2),
     3, '2024-03-01', N'Обязательно прочитай, лучшее что я читал'),
    -- Александр рекомендует Игорю "1984"
    ((SELECT $node_id FROM [User] WHERE id = 1), (SELECT $node_id FROM [User] WHERE id = 5),
     4, '2024-03-20', N'Очень актуально в наше время'),
    -- Дмитрий рекомендует Павлу "Дюна"
    ((SELECT $node_id FROM [User] WHERE id = 3), (SELECT $node_id FROM [User] WHERE id = 9),
     5, '2023-12-01', N'Лучшая фантастика — читай обязательно'),
    -- Дмитрий рекомендует Александру "Имя розы"
    ((SELECT $node_id FROM [User] WHERE id = 3), (SELECT $node_id FROM [User] WHERE id = 1),
     7, '2024-02-20', N'Потрясающий исторический детектив'),
    -- Сергей рекомендует Наталье "Братья Карамазовы"
    ((SELECT $node_id FROM [User] WHERE id = 7), (SELECT $node_id FROM [User] WHERE id = 10),
     15, '2024-01-05', N'Вершина творчества Достоевского'),
    -- Мария рекомендует Ольге "Норвежский лес"
    ((SELECT $node_id FROM [User] WHERE id = 2), (SELECT $node_id FROM [User] WHERE id = 8),
     9, '2024-02-15', N'Атмосферная книга, тебе понравится'),
    -- Елена рекомендует Татьяне "Сияние"
    ((SELECT $node_id FROM [User] WHERE id = 6), (SELECT $node_id FROM [User] WHERE id = 12),
     8, '2024-03-25', N'Если не боишься хоррора — вперёд!'),
    -- Игорь рекомендует Виктору "Война и мир"
    ((SELECT $node_id FROM [User] WHERE id = 5), (SELECT $node_id FROM [User] WHERE id = 11),
     2, '2024-01-10', N'Перечитал снова — грандиозно'),
    -- Виктор рекомендует Дмитрию "Мастер и Маргарита"
    ((SELECT $node_id FROM [User] WHERE id = 11), (SELECT $node_id FROM [User] WHERE id = 3),
     3, '2024-03-25', N'Если вдруг ещё не читал — срочно'),
    -- Наталья рекомендует Александру "Имя розы"
    ((SELECT $node_id FROM [User] WHERE id = 10), (SELECT $node_id FROM [User] WHERE id = 1),
     7, '2024-01-15', N'Детектив и история в одном флаконе'),
    -- Павел рекомендует Елене "1984"
    ((SELECT $node_id FROM [User] WHERE id = 9), (SELECT $node_id FROM [User] WHERE id = 6),
     4, '2024-03-05', N'Антиутопия которую нельзя пропустить'),
    -- Татьяна рекомендует Ольге "Убийство в Восточном экспрессе"
    ((SELECT $node_id FROM [User] WHERE id = 12), (SELECT $node_id FROM [User] WHERE id = 8),
     6, '2024-04-01', N'Лучший детектив для начинающих');
GO

-- ============================================================
-- ПРОВЕРКА: количество строк в каждой таблице
-- ============================================================
SELECT N'User'       AS [Таблица], COUNT(*) AS [Строк] FROM [User]
UNION ALL SELECT N'Book',          COUNT(*) FROM Book
UNION ALL SELECT N'Genre',         COUNT(*) FROM Genre
UNION ALL SELECT N'Author',        COUNT(*) FROM Author
UNION ALL SELECT N'Reads',         COUNT(*) FROM Reads
UNION ALL SELECT N'Recommends',    COUNT(*) FROM Recommends
UNION ALL SELECT N'WrittenBy',     COUNT(*) FROM WrittenBy
UNION ALL SELECT N'BelongsTo',     COUNT(*) FROM BelongsTo;
GO

-- ============================================================
-- ЧАСТЬ 5: ЗАПРОСЫ MATCH (5 запросов, цепочки 3+ узлов)
-- ============================================================

-- ------------------------------------------------------------
-- Запрос 1: Какие книги читали пользователи и к какому жанру
--           они относятся?
-- Цепочка: User → (Reads) → Book → (BelongsTo) → Genre
-- ------------------------------------------------------------
PRINT N'=== Запрос 1: Читатели, прочитанные книги и их основные жанры ===';
SELECT
    u.username       AS [Пользователь],
    u.reading_level  AS [Уровень],
    b.title          AS [Книга],
    b.avg_rating     AS [Рейтинг],
    r.user_rating    AS [Оценка пользователя],
    g.name           AS [Жанр]
FROM [User]   AS u
   , Reads    AS r
   , Book     AS b
   , BelongsTo AS bt
   , Genre    AS g
WHERE MATCH(u-(r)->b-(bt)->g)
  AND r.status   = N'finished'
  AND bt.is_primary = 1
ORDER BY u.username, b.title;
GO

-- ------------------------------------------------------------
-- Запрос 2: Кто написал книги, которые читают пользователи?
--           Найти всех авторов, чьи книги прочитаны хотя бы
--           одним пользователем.
-- Цепочка: User → (Reads) → Book → (WrittenBy) → Author
-- ------------------------------------------------------------
PRINT N'=== Запрос 2: Авторы книг, прочитанных пользователями ===';
SELECT
    u.username    AS [Читатель],
    b.title       AS [Книга],
    b.year        AS [Год издания],
    a.name        AS [Автор],
    a.nationality AS [Национальность],
    r.user_rating AS [Оценка]
FROM [User]   AS u
   , Reads    AS r
   , Book     AS b
   , WrittenBy AS wb
   , Author   AS a
WHERE MATCH(u-(r)->b-(wb)->a)
  AND r.status = N'finished'
  AND r.user_rating >= 4.5
ORDER BY a.name, b.title;
GO

-- ------------------------------------------------------------
-- Запрос 3: Кому пользователи рекомендуют книги одного жанра,
--           который сами читали?
-- Цепочка (5 узлов):
--   User1 → (Recommends) → User2,
--   User1 → (Reads) → Book → (BelongsTo) → Genre
-- Два отдельных MATCH, соединённые через User1
-- ------------------------------------------------------------
PRINT N'=== Запрос 3: Пользователи, рекомендующие книги в жанре, который сами читали ===';
SELECT DISTINCT
    u1.username  AS [Рекомендатель],
    u2.username  AS [Кому рекомендовано],
    rec.book_id  AS [ID книги-рекомендации],
    b.title      AS [Книга читаемая],
    g.name       AS [Жанр]
FROM [User]    AS u1
   , Recommends AS rec
   , [User]    AS u2
   , Reads     AS r
   , Book      AS b
   , BelongsTo AS bt
   , Genre     AS g
WHERE MATCH(u1-(rec)->u2 AND u1-(r)->b-(bt)->g)
  AND bt.is_primary = 1
  AND r.status = N'finished'
ORDER BY u1.username;
GO

-- ------------------------------------------------------------
-- Запрос 4: Найти все книги авторов, которых читает конкретный
--           пользователь, сгруппировать по жанрам.
-- Интерес: пользователь читал книгу X автора A → показать все
--          книги автора A и их жанры.
-- Цепочка: User → (Reads) → Book → (WrittenBy) → Author
--   + отдельно: Book2 → (WrittenBy) → Author (для поиска других книг)
-- Упрощённый вариант через 2 MATCH-шага:
-- User → (Reads) → Book → (WrittenBy) → Author
-- + Book2 → (BelongsTo) → Genre (для той же книги)
-- ------------------------------------------------------------
PRINT N'=== Запрос 4: Книги в жанре "Антиутопия" с авторами, которых читал пользователь ===';
SELECT
    u.username  AS [Пользователь],
    b.title     AS [Книга],
    a.name      AS [Автор],
    g.name      AS [Жанр],
    b.avg_rating AS [Рейтинг книги]
FROM [User]    AS u
   , Reads     AS r
   , Book      AS b
   , WrittenBy AS wb
   , Author    AS a
   , BelongsTo AS bt
   , Genre     AS g
WHERE MATCH(u-(r)->b-(wb)->a AND b-(bt)->g)
  AND g.name = N'Антиутопия'
  AND r.status = N'finished'
ORDER BY u.username, b.title;
GO

-- ------------------------------------------------------------
-- Запрос 5: Найти пользователей, которым рекомендовали книгу,
--           и проверить — они уже её читали или нет?
--           Показать цепочку: кто рекомендовал → кому → книга
-- Цепочка: User1 → (Recommends) → User2 → (Reads) → Book
-- ------------------------------------------------------------
PRINT N'=== Запрос 5: Пользователи, прочитавшие книгу после получения рекомендации ===';
SELECT
    u1.username        AS [Рекомендатель],
    u2.username        AS [Получатель рекомендации],
    rec.comment        AS [Комментарий],
    rec.recommend_date AS [Дата рекомендации],
    b.title            AS [Прочитанная книга],
    r.user_rating      AS [Оценка],
    r.finished_date    AS [Дата прочтения]
FROM [User]    AS u1
   , Recommends AS rec
   , [User]    AS u2
   , Reads     AS r
   , Book      AS b
WHERE MATCH(u1-(rec)->u2-(r)->b)
  AND r.status = N'finished'
ORDER BY rec.recommend_date DESC;
GO

-- ============================================================
-- ЧАСТЬ 6: ЗАПРОСЫ SHORTEST_PATH
-- ============================================================

-- SP-Запрос 1: Все цепочки рекомендаций из пользователя
--              "Александр Громов" (шаблон +)
-- Цепочка: User -(Recommends)-> User (1 или более шагов)

PRINT N'=== SP-Запрос 1: Все цепочки рекомендаций от Александра Громова (шаблон +) ===';
SELECT
    u1.username AS [Исходный пользователь],
    STRING_AGG(u2.username, ' -> ') WITHIN GROUP (GRAPH PATH) AS [Цепочка рекомендаций],
    COUNT(u2.username)               WITHIN GROUP (GRAPH PATH) AS [Длина цепочки],
    LAST_VALUE(u2.username)          WITHIN GROUP (GRAPH PATH) AS [Конечный получатель]
FROM [User] AS u1
   , Recommends FOR PATH AS rec
   , [User]    FOR PATH AS u2
WHERE MATCH(SHORTEST_PATH(u1(-(rec)->u2)+))
  AND u1.username = N'Александр Громов'
ORDER BY [Длина цепочки];
GO
 
-- SP-Запрос 2: Кратчайший путь рекомендаций от Дмитрия Орлова
--              до Елены Быковой (шаблон +)

PRINT N'=== SP-Запрос 2: Кратчайший путь рекомендаций от Дмитрия Орлова до Елены Быковой ===';
WITH PathCTE AS
(
    SELECT
        u1.username AS [Начало],
        STRING_AGG(u2.username, ' -> ') WITHIN GROUP (GRAPH PATH) AS [Путь],
        LAST_VALUE(u2.username)          WITHIN GROUP (GRAPH PATH) AS [Конец],
        COUNT(u2.username)               WITHIN GROUP (GRAPH PATH) AS [Длина]
    FROM [User] AS u1
       , Recommends FOR PATH AS rec
       , [User]    FOR PATH AS u2
    WHERE MATCH(SHORTEST_PATH(u1(-(rec)->u2)+))
      AND u1.username = N'Дмитрий Орлов'
)
SELECT [Начало], [Путь], [Длина]
FROM PathCTE
WHERE [Конец] = N'Елена Быкова';
GO

-- SP-Запрос 3: Все цепочки рекомендаций глубиной от 1 до 3 шагов
--              (шаблон {1,3})
-- Показывает всех пользователей и пути, по которым
-- рекомендации распространяются не более чем на 3 уровня

PRINT N'=== SP-Запрос 3: Все цепочки рекомендаций глубиной 1-3 шага (шаблон {1,3}) ===';
SELECT
    u1.username AS [Источник],
    STRING_AGG(u2.username, ' -> ') WITHIN GROUP (GRAPH PATH) AS [Путь рекомендаций],
    COUNT(u2.username)               WITHIN GROUP (GRAPH PATH) AS [Глубина],
    LAST_VALUE(u2.username)          WITHIN GROUP (GRAPH PATH) AS [Конечный узел]
FROM [User] AS u1
   , Recommends FOR PATH AS rec
   , [User]    FOR PATH AS u2
WHERE MATCH(SHORTEST_PATH(u1(-(rec)->u2){1,3}))
ORDER BY u1.username, [Глубина];
GO