USE trenitalia_db;

DROP TABLE IF EXISTS Biglietto;
DROP TABLE IF EXISTS Tratta;
DROP TABLE IF EXISTS Viaggio;
DROP TABLE IF EXISTS Treno;
DROP TABLE IF EXISTS Stazione;
DROP TABLE IF EXISTS Servizio;
DROP TABLE IF EXISTS Passeggero;

CREATE TABLE Passeggero (
    IDPasseggero INT PRIMARY KEY,
    Nome VARCHAR(20) NOT NULL,
    Cognome VARCHAR(20) NOT NULL,
    DataNascita DATE, 
    Email VARCHAR(100) UNIQUE,
    Telefono VARCHAR(20) UNIQUE,
    CartaFreccia VARCHAR(20) UNIQUE
);

CREATE TABLE Servizio (
    IDServizio INT PRIMARY KEY,
    Descrizione VARCHAR(30),
    PrezzoServizio DECIMAL(10,2)
);

CREATE TABLE Viaggio (
    IDViaggio INT PRIMARY KEY,
    IDPasseggero INT,
    DataViaggio DATE NOT NULL,
    PrezzoTotale DECIMAL(10,2) NOT NULL,
    TipoViaggio VARCHAR(30) NOT NULL,
    FOREIGN KEY (IDPasseggero) REFERENCES Passeggero(IDPasseggero)
);

CREATE TABLE Treno (
    IDTreno INT PRIMARY KEY,
    NomeTreno VARCHAR(30) NOT NULL,
    Tipo VARCHAR(30) NOT NULL,
    NumPosti INT
);

CREATE TABLE Stazione (
    IDStazione INT PRIMARY KEY,
    NomeStazione VARCHAR(50) NOT NULL,
    Città VARCHAR(30) NOT NULL,
    Regione VARCHAR(30) NOT NULL
);

CREATE TABLE Tratta (
    IDTratta INT PRIMARY KEY,
    IDTreno INT,
    IDStazionePartenza INT,
    IDStazioneArrivo INT,
    TipoTratta VARCHAR(30) NOT NULL,
    Durata INT NOT NULL,
    OrdineFermate VARCHAR(500),
    FOREIGN KEY (IDTreno) REFERENCES Treno(IDTreno),
    FOREIGN KEY (IDStazionePartenza) REFERENCES Stazione(IDStazione),
    FOREIGN KEY (IDStazioneArrivo) REFERENCES Stazione(IDStazione)
);

CREATE TABLE Biglietto (
    IDBiglietto INT PRIMARY KEY,
    IDPasseggero INT,
    IDServizio INT,
    IDViaggio INT,
    DataEmissione DATE NOT NULL,
    PrezzoFinale DECIMAL(10,2) NOT NULL,
    TipoPagamento VARCHAR(20) NOT NULL,
    TipoValidazione VARCHAR(20) NOT NULL,
    TipoBiglietto VARCHAR(20) NOT NULL,
    QRCode VARCHAR(50) NOT NULL UNIQUE,
    NomeTariffa VARCHAR(50),
    FOREIGN KEY (IDPasseggero) REFERENCES Passeggero(IDPasseggero),
    FOREIGN KEY (IDServizio) REFERENCES Servizio(IDServizio),
    FOREIGN KEY (IDViaggio) REFERENCES Viaggio(IDViaggio),
    CHECK (PrezzoFinale >= 0)
);

CREATE INDEX idx_QRCode ON Biglietto(QRCode);
CREATE INDEX idx_IDPasseggero_Biglietto ON Biglietto(IDPasseggero);
CREATE INDEX idx_IDPasseggero_Viaggio ON Viaggio(IDPasseggero);
CREATE INDEX idx_IDTreno_Tratta ON Tratta(IDTreno);
CREATE INDEX idx_IDViaggio_Passeggero ON Biglietto(IDViaggio, IDPasseggero);

SELECT 
    TR.IDTratta,
    T.NomeTreno,
    S1.NomeStazione AS Partenza,
    S2.NomeStazione AS Arrivo,
    TR.TipoTratta,
    TR.Durata
FROM Tratta TR
JOIN Treno T ON TR.IDTreno = T.IDTreno
JOIN Stazione S1 ON TR.IDStazionePartenza = S1.IDStazione
JOIN Stazione S2 ON TR.IDStazioneArrivo = S2.IDStazione
WHERE TR.IDTratta NOT IN (
    SELECT V.IDViaggio
    FROM Viaggio V
    JOIN Biglietto B ON V.IDViaggio = B.IDViaggio
    WHERE V.DataViaggio = '2025-08-05'
);

SELECT 
    B.IDBiglietto,
    B.QRCode,
    P.Nome,
    P.Cognome,
    V.DataViaggio,
    B.TipoValidazione
FROM Biglietto B
JOIN Passeggero P ON B.IDPasseggero = P.IDPasseggero
JOIN Viaggio V ON B.IDViaggio = V.IDViaggio
WHERE V.DataViaggio >= CURDATE()
  AND B.TipoValidazione = 'Valido';

SELECT 
    B.IDBiglietto,
    B.DataEmissione,
    B.PrezzoFinale,
    B.TipoPagamento,
    B.TipoBiglietto,
    B.TipoValidazione,
    B.NomeTariffa,
    T.NomeTreno,
    V.DataViaggio
FROM Biglietto B
JOIN Passeggero P ON B.IDPasseggero = P.IDPasseggero
JOIN Viaggio V ON B.IDViaggio = V.IDViaggio
JOIN Tratta TR ON TR.IDTratta = V.IDViaggio  -- Se Viaggio è collegato a Tratta (altrimenti da rimuovere)
JOIN Treno T ON TR.IDTreno = T.IDTreno
WHERE P.Nome = 'Mario' AND P.Cognome = 'Rossi';

SELECT 
    V.IDViaggio,
    P.Nome,
    P.Cognome,
    B.IDBiglietto,
    V.TipoViaggio,
    V.PrezzoTotale
FROM Viaggio V
JOIN Passeggero P ON V.IDPasseggero = P.IDPasseggero
JOIN Biglietto B ON V.IDViaggio = B.IDViaggio
WHERE V.TipoViaggio = 'Con cambio';

SELECT DISTINCT 
    P.IDPasseggero,
    P.Nome,
    P.Cognome
FROM Passeggero P
JOIN Viaggio V ON P.IDPasseggero = V.IDPasseggero
JOIN Biglietto B ON V.IDViaggio = B.IDViaggio
JOIN Tratta T ON T.IDTratta = V.IDViaggio -- Se c'è legame Viaggio-Tratta
JOIN Treno TR ON TR.IDTreno = T.IDTreno
WHERE TR.Tipo = 'Regionale';

SELECT 
    P.IDPasseggero,
    P.Nome,
    P.Cognome,
    SUM(B.PrezzoFinale) AS SpesaTotale
FROM Passeggero P
JOIN Biglietto B ON P.IDPasseggero = B.IDPasseggero
GROUP BY P.IDPasseggero, P.Nome, P.Cognome;

SELECT 
    T.NomeTreno,
    T.Tipo,
    S1.NomeStazione AS Partenza,
    S2.NomeStazione AS Arrivo,
    TR.OrdineFermate,
    TR.TipoTratta,
    CONCAT(FLOOR(TR.Durata / 60), 'h ', MOD(TR.Durata, 60), 'm') AS Durata
FROM Treno T
JOIN Tratta TR ON T.IDTreno = TR.IDTreno
JOIN Stazione S1 ON TR.IDStazionePartenza = S1.IDStazione
JOIN Stazione S2 ON TR.IDStazioneArrivo = S2.IDStazione
WHERE T.Tipo = 'Alta Velocità' 
  AND S1.Città = 'Bari'
ORDER BY TR.Durata DESC;

SELECT 
	T.NomeTreno,
	TR.OrdineFermate
FROM 
	Treno T
JOIN 
	Tratta TR ON T.IDTreno = TR.IDTreno
WHERE 
	T.NomeTreno = 'REG2335' ;