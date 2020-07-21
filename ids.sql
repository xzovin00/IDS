/*  IDS 2.
 *
 *  Autori:
 *  Ales Rezac (xrezac21)
 *  Martin Zovinec (xzovin00)
 */

DROP TABLE Familie CASCADE CONSTRAINT;
DROP TABLE Uzemi CASCADE CONSTRAINT;
DROP TABLE Setkani_donu CASCADE CONSTRAINT;
DROP TABLE Aliance CASCADE CONSTRAINT;
DROP TABLE Kriminalni_cinnost CASCADE CONSTRAINT;
DROP TABLE Clen CASCADE CONSTRAINT;
DROP TABLE Vrazda CASCADE CONSTRAINT;

DROP SEQUENCE CLen_ID_counter;
-- M:N
DROP TABLE Don_je_pozvan CASCADE CONSTRAINT;
DROP TABLE Cinnosti_familie CASCADE CONSTRAINT;
DROP TABLE Aliance_familie CASCADE CONSTRAINT;
DROP TABLE Uzemi_operaci CASCADE CONSTRAINT;

CREATE TABLE Familie(
    id_familie INT NOT NULL,
    jmeno_familie VARCHAR2(25 CHAR) NOT NULL,
    jmeno_dona VARCHAR2(25 CHAR) NOT NULL,
    datum_narozeni_dona DATE NOT NULL,
    prestiz INT NOT NULL,
    velikost_bot_dona NUMBER NOT NULL,
    
    CONSTRAINT PK_Familie PRIMARY KEY(id_familie)
);

CREATE TABLE Clen(
    id_clena INT DEFAULT NULL,
    jmeno VARCHAR2(25 CHAR) NOT NULL,
    datum_narozeni DATE NOT NULL,
    pohlavi VARCHAR2(4 CHAR),
    loajalita INT NOT NULL,
    clenova_familie INT NOT NULL,
    bachar VARCHAR2(3 CHAR) DEFAULT ' ',
    poskok VARCHAR2(3 CHAR) DEFAULT ' ',
    bodyguard VARCHAR2(3 CHAR) DEFAULT ' ',
    vymahac VARCHAR2(3 CHAR) DEFAULT ' ',
    
    CONSTRAINT FK_Familie_Clena FOREIGN KEY (clenova_familie) REFERENCES Familie(id_familie),
    CONSTRAINT PK_Clen PRIMARY KEY(id_clena)
);

CREATE TABLE Aliance(
    id_aliance INT NOT NULL,
    datum_vzniku DATE NOT NULL,
    datum_ukonceni DATE NOT NULL,
    
    CONSTRAINT PK_ALIANCE PRIMARY KEY(id_aliance)
);

CREATE TABLE Uzemi(
    id_uzemi INT NOT NULL,
    souradnice VARCHAR2(20 CHAR) NOT NULL,
    rozloha INT NOT NULL,
    adresa VARCHAR2(35 CHAR) NOT NULL,
    majitel_uzemi INT,
    
    CONSTRAINT FK_majitel_uzemi FOREIGN KEY (majitel_uzemi) REFERENCES Familie(id_familie),
    CONSTRAINT PK_Uzemi PRIMARY KEY(id_uzemi)
);

CREATE TABLE Setkani_donu(
    id_setkani INT NOT NULL,
    datum DATE NOT NULL,
    uzemi_setkani INT NOT NULL,
    
    CONSTRAINT FK_uzemi_setkani FOREIGN KEY (uzemi_setkani) REFERENCES Uzemi(id_uzemi),
    CONSTRAINT PK_Setkani PRIMARY KEY(id_setkani)
);

CREATE TABLE Kriminalni_cinnost(
    id_cinnosti INT NOT NULL,
    typ VARCHAR2(20 CHAR) NOT NULL,
    datum_trvani DATE,
    uzemi_provozu INT NOT NULL,
    
    CONSTRAINT FK_Uzemi_Provozu FOREIGN KEY (uzemi_provozu) REFERENCES Uzemi(id_uzemi),
    CONSTRAINT PK_Cinnosti PRIMARY KEY(id_cinnosti)
);

CREATE TABLE Vrazda(
    id_cinnosti INT NOT NULL
    REFERENCES Kriminalni_cinnost(id_cinnosti)
    ON DELETE CASCADE,
    obet VARCHAR2(25 CHAR) NOT NULL,
    
    CONSTRAINT PK_Vrazda PRIMARY KEY(id_cinnosti)
);

CREATE TABLE Don_je_pozvan (
    id_setkani INT NOT NULL,
    id_familie INT NOT NULL,
    jmeno_dona VARCHAR2(50 CHAR) NOT NULL,
    potvrzeni VARCHAR2(3 CHAR),
    
    CONSTRAINT PK_Don_je_pozvan PRIMARY KEY (id_setkani, id_familie),
    CONSTRAINT FK_setkani_don_id FOREIGN KEY (id_familie) REFERENCES Familie,
    CONSTRAINT FK_setkani_id FOREIGN KEY (id_setkani) REFERENCES Setkani_donu
);

CREATE TABLE Cinnosti_familie (
    id_familie INT NOT NULL,
    id_clena INT NOT NULL,
    id_cinnosti INT NOT NULL,

    
    CONSTRAINT PK_CF PRIMARY KEY (id_familie, id_cinnosti, id_clena),
    CONSTRAINT FK_CF_familie FOREIGN KEY (id_familie) REFERENCES Familie,
    CONSTRAINT FK_CF_cinnost FOREIGN KEY (id_cinnosti) REFERENCES Kriminalni_cinnost,
    CONSTRAINT FK_CF_clena FOREIGN KEY (id_clena) REFERENCES Clen
);

CREATE TABLE Aliance_familie (
    id_familie INT NOT NULL,
    id_aliance INT NOT NULL,
    
    CONSTRAINT PK_AF PRIMARY KEY (id_familie, id_aliance),
    CONSTRAINT FK_AF_Familie FOREIGN KEY (id_familie) REFERENCES Familie,
    CONSTRAINT FK_AF_Aliance FOREIGN KEY (id_aliance) REFERENCES Aliance
);

CREATE TABLE Uzemi_operaci (
    id_familie INT NOT NULL,
    id_uzemi INT NOT NULL,
    
    CONSTRAINT PK_UO PRIMARY KEY (id_familie, id_uzemi),
    CONSTRAINT FK_UO_Familie FOREIGN KEY (id_familie) REFERENCES Familie,
    CONSTRAINT FK_UO_Uzemi FOREIGN KEY (id_uzemi) REFERENCES Uzemi
);

/*  IDS 4. Uloha */

-- Pridelena prava druhemu uzivateli jako Donovi
GRANT ALL ON Familie TO xzovin00;
GRANT ALL ON Kriminalni_cinnost TO xzovin00;
GRANT ALL ON Vrazda TO xzovin00;

GRANT SELECT ON Uzemi TO xzovin00;
GRANT SELECT ON Setkani_donu TO xzovin00;
GRANT SELECT ON Aliance TO xzovin00;
GRANT SELECT ON Aliance_familie TO xzovin00;
GRANT SELECT ON Uzemi_operaci TO xzovin00;

GRANT UPDATE ON Clen TO xzovin00;

GRANT INSERT ON Don_je_pozvan TO xzovin00;


-- Trigger pro automaticke generovani id pro cleny
CREATE SEQUENCE CLen_ID_counter;

CREATE OR REPLACE TRIGGER autoClenID
	BEFORE INSERT ON Clen
	FOR EACH ROW
BEGIN
		:new.id_clena := CLen_ID_counter.nextval;
END autoClenID;
/

-- Trigger pro automaticke prirazeni role clena v familii
CREATE OR REPLACE TRIGGER trigger_vyber_hodnost
	BEFORE INSERT ON Clen
	FOR EACH ROW
BEGIN
	IF :new.loajalita < '0' THEN
    raise_application_error(-20000, 'Neplatna loajalita!');
  ELSIF :new.loajalita <= '10' THEN
    :new.poskok := 'ANO';
  ELSIF :new.loajalita <= '20' THEN
    :new.bachar := 'ANO';
  ELSIF :new.loajalita <= '35' THEN
    :new.vymahac := 'ANO';
  ELSIF :new.loajalita >= '50' THEN
    :new.bodyguard := 'ANO';
  
	END IF;
END;
/

EXPLAIN PLAN FOR
SELECT typ, COUNT (id_clena)
FROM Kriminalni_cinnost NATURAL JOIN Cinnosti_familie NATURAL JOIN Clen
GROUP BY id_cinnosti, typ;
SELECT * FROM TABLE(DBMS_XPLAN.display);

CREATE INDEX index_krimi_cinn ON Kriminalni_cinnost(typ);

EXPLAIN PLAN FOR
SELECT typ, COUNT (id_clena)
FROM Kriminalni_cinnost NATURAL JOIN Cinnosti_familie NATURAL JOIN Clen
GROUP BY id_cinnosti, typ;
SELECT * FROM TABLE(DBMS_XPLAN.display);
---------------------------------


-------- Zaklad databaze --------
-- Familie --
INSERT INTO Familie VALUES ('1', 'La Savonarola', 'Lazzaro Turri', TO_DATE('1985-6-25', 'yyyy-mm-dd'), '110', '8');
INSERT INTO Familie VALUES ('2', 'Galamariza', 'Arturo Papa', TO_DATE('1972-3-8', 'yyyy-mm-dd'), '25', '7,5');
INSERT INTO Familie VALUES ('3', 'Del Mozarel', 'Francesco Giovani', TO_DATE('2000-1-1', 'yyyy-mm-dd'), '63', '7');
INSERT INTO Familie VALUES ('4', 'Oglomadore', 'Baldassarre Giancola', TO_DATE('1987-5-5', 'yyyy-mm-dd'), '88', '9');
INSERT INTO Familie VALUES ('5', 'Baragazi', 'Marzia Guccione', TO_DATE('1968-12-19', 'yyyy-mm-dd'), '16', '5');

-- Uzemi --
INSERT INTO Uzemi VALUES ('1', '45.5N 9.1E', '225', 'Duomo Milano 1', '');
INSERT INTO Uzemi VALUES ('2', '43.2N 18.6E', '300', 'Bogramoza 45', '2');
INSERT INTO Uzemi VALUES ('3', '33.4N 5.5E', '543', 'Sagraba 76', '3'); 
INSERT INTO Uzemi VALUES ('4', '68.5N 2E', '456', 'Pizzeze 22', '3');

-- Clenove --
INSERT INTO Clen (jmeno,datum_narozeni,pohlavi,loajalita,clenova_familie)
VALUES ('Romeo Auditore', TO_DATE('2001-5-30', 'yyyy-mm-dd'), 'Muz', '2', '2');
INSERT INTO Clen (jmeno,datum_narozeni,pohlavi,loajalita,clenova_familie)
VALUES ('Julia Agra', TO_DATE('2002-3-2', 'yyyy-mm-dd'), 'Zena', '50', '2');
INSERT INTO Clen (jmeno,datum_narozeni,pohlavi,loajalita,clenova_familie)
VALUES ('Soldore Mia', TO_DATE('1980-6-6', 'yyyy-mm-dd'), 'Muz', '10', '1');
INSERT INTO Clen (jmeno,datum_narozeni,pohlavi,loajalita,clenova_familie)
VALUES ('Pagamus Dius', TO_DATE('1992-2-10', 'yyyy-mm-dd'), 'Muz', '6', '3');
INSERT INTO Clen (jmeno,datum_narozeni,pohlavi,loajalita,clenova_familie)
VALUES ('Galio Sio', TO_DATE('1967-4-15', 'yyyy-mm-dd'), 'Muz', '3', '4');

-- Aliance --
INSERT INTO Aliance VALUES ('1', TO_DATE('2002-3-14', 'yyyy-mm-dd'), TO_DATE('2002-3-15', 'yyyy-mm-dd'));
INSERT INTO Aliance VALUES ('2', TO_DATE('2007-12-12', 'yyyy-mm-dd'), TO_DATE('2008-2-14', 'yyyy-mm-dd'));

-- Kriminalni cinnost --
INSERT INTO Kriminalni_cinnost VALUES ('1', 'Sabotaz', TO_DATE('2016-3-10', 'yyyy-mm-dd'), '1');
INSERT INTO Kriminalni_cinnost VALUES ('2', 'Loupez', TO_DATE('2014-2-24', 'yyyy-mm-dd'), '1');
INSERT INTO Kriminalni_cinnost VALUES ('3', 'Utok', TO_DATE('2003-8-31', 'yyyy-mm-dd'), '1');
INSERT INTO Kriminalni_cinnost VALUES ('4', 'Loupez', TO_DATE('2018-6-4', 'yyyy-mm-dd'), '3');
INSERT INTO Kriminalni_cinnost VALUES ('5', 'Vrazda', TO_DATE('2012-12-21', 'yyyy-mm-dd'), '3');

-- Setkani donu --
INSERT INTO Setkani_donu VALUES ('1', TO_DATE('2009-5-18','yyyy-mm-dd'), '1');
INSERT INTO Setkani_donu VALUES ('2', TO_DATE('2001-11-11', 'yyyy-mm-dd'), '1');
INSERT INTO Setkani_donu VALUES ('3', TO_DATE('2019-12-20', 'yyyy-mm-dd'), '3');
INSERT INTO Setkani_donu VALUES ('4', TO_DATE('2020-3-29', 'yyyy-mm-dd'), '4');
INSERT INTO Setkani_donu VALUES ('5', TO_DATE('2004-2-29', 'yyyy-mm-dd'), '4');

-- Vrazdy --
INSERT INTO Vrazda VALUES ('3', 'Sean Bean');
INSERT INTO Vrazda VALUES ('5', 'J.F.Kennedy');

-- Don je pozvan --
INSERT INTO Don_je_pozvan VALUES ('1', '3', 'Francesco Giovani', 'Ano');
INSERT INTO Don_je_pozvan VALUES ('1', '2', 'Arturo Papa', 'Ano');

-- Cinnost familie --

INSERT INTO Cinnosti_familie VALUES ('4', '5', '1');
INSERT INTO Cinnosti_familie VALUES ('2', '1', '2');
INSERT INTO Cinnosti_familie VALUES ('1', '1', '3');
INSERT INTO Cinnosti_familie VALUES ('3', '2', '4');
INSERT INTO Cinnosti_familie VALUES ('3', '4', '5');

-- Aliance familie --
INSERT INTO Aliance_familie VALUES ('4', '1');
INSERT INTO Aliance_familie VALUES ('2', '2');
INSERT INTO Aliance_familie VALUES ('4', '2');
INSERT INTO Aliance_familie VALUES ('1', '1');

-- Uzemi operaci --
INSERT INTO Uzemi_operaci VALUES ('2', '2');
INSERT INTO Uzemi_operaci VALUES ('2', '1');
INSERT INTO Uzemi_operaci VALUES ('3', '3');
--------------------------------


-- Dodatecna aktivace triggeru vlozenim dat
INSERT INTO Clen (jmeno,datum_narozeni,pohlavi,loajalita,clenova_familie)
VALUES ('Armando Pasterio', TO_DATE('2001-5-30', 'yyyy-mm-dd'), 'Muz', '62', '1');

/*  IDS 3. Uloha */

-- Dotaz se spojenim dvou tabulek 1
-- Tabulka vlastnenych uzemi i s vlastniky
SELECT  F.jmeno_familie as "Majitel", U.adresa as "Adresa", U.souradnice as "Souradnice"
  FROM Uzemi U 
INNER JOIN Familie F
  ON U.majitel_uzemi=F.id_familie;


-- Dotaz se spojenim dvou tabulek 2
-- Tabulka adres uzemi a na nich konane setkani donu
SELECT U.Adresa as "Adresa", SD.datum as "Datum", SD.id_setkani as "ID setkani"
  FROM Setkani_donu SD
INNER JOIN Uzemi U
  ON SD.uzemi_setkani=U.id_uzemi;

-- Dotaz se spojenim tri(ctyr) tabulek
-- Ukazuji se sloupce jen ze tri tabulek, ale byla zapotrebi spojovaci tabulka navic
-- Tabulka clenu co provedli kriminalni cinnost, ktera byla vrazdou
SELECT Cle.jmeno as "Vrah", KC.datum_trvani as "Datum vrazdy", V.obet as "Obet"
  FROM Clen Cle
INNER JOIN Cinnosti_familie CF
  ON Cle.id_clena=CF.id_clena
INNER JOIN  Kriminalni_cinnost KC
  ON CF.id_cinnosti=KC.id_cinnosti
INNER JOIN Vrazda V
  ON KC.id_cinnosti=V.id_cinnosti;
  
  
-- Dotaz s predikatem IN
-- Tabulka s familiemi, ktere jsou aktualne v alianci
SELECT jmeno_familie as "Familie v alianci", jmeno_dona as "Don"
  FROM Familie
WHERE id_familie IN (SELECT id_familie FROM Aliance_familie);

-- Dotaz s predikatem EXISTS
-- Tabulka s dony, kteri momentalne maji bodyguarda
SELECT Fam.jmeno_dona as "Don", Cle.jmeno as "Donuv bodyguard"
  FROM Clen Cle
RIGHT JOIN Familie Fam
  ON Cle.clenova_familie=Fam.id_familie
WHERE EXISTS (SELECT jmeno_dona FROM fAMILIE WHERE Cle.clenova_familie=Fam.id_familie AND Cle.bodyguard='ANO');

-- Dotaz s klauzuli GROUP BY + agregacni funkce COUNT 1
-- Tabulka familii s poctem clenu
SELECT Fam.jmeno_familie as "Familie", COUNT(Cle.id_clena) as "Pocet clenu" 
  FROM Clen Cle
RIGHT JOIN Familie Fam
  ON Cle.clenova_familie=Fam.id_familie
GROUP BY jmeno_familie;

-- Dotaz s klauzuli GROUP BY + agregacni funkce COUNT 2
-- Tabulka clenu s poctem vykonanych kriminalnich cinnosti
SELECT Cle.jmeno as "Clen", COUNT(CF.id_clena) as "Pocet cinnosti" 
  FROM Clen Cle
LEFT JOIN Cinnosti_familie CF
  ON Cle.id_clena=CF.id_clena
GROUP BY jmeno;
--------------------------------