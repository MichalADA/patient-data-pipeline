# Projekt Bazy Danych Pacjenta - Azure Data Pipeline

## Struktura projektu
Projekt składa się z systemu do zarządzania danymi pacjentów, wykorzystującego różne usługi Azure do przetwarzania i przechowywania danych.
Celem projektu jest stworzenie kompleksowego rozwiązania do przechowywania i analizy danych pacjentów w formacie JSON. Wykorzystane narzędzia umożliwiają zautomatyzowane przenoszenie danych z plików Excel do relacyjnej bazy danych SQL oraz przekształcanie ich do formatu dokumentów JSON w Azure Cosmos DB.

## Dane źródłowe

Plik Excel `Baza_Danych_Pacjenta.xlsx` zawiera następujące arkusze:

* **Patients** - dane pacjentów, takie jak imiona, nazwiska, PESEL i numer telefonu.
* **Doctors** - informacje o lekarzach, w tym ich specjalizacje.
* **Upcoming_Visits** - nadchodzące wizyty pacjentów wraz z przypisanymi lekarzami.
* **Visit_History** - historia wizyt pacjentów wraz z diagnozami, leczeniem i dodatkowymi notatkami.

## Utworzone zasoby Azure

Projekt wykorzystuje następujące zasoby Azure:

1. **Resource Group**
    * Nazwa: `bazy-danych-zajecia`
    * Region: `Poland Central`
    * Przeznaczenie: Grupowanie wszystkich zasobów projektu.
2. **Azure Storage Account**
    * Nazwa: `bazydanychstorage`
    * Typ: `General Purpose v2`
    * Performance tier: `Standard`
    * Replication: `LRS (Locally Redundant Storage)`
    * Container: `data`
    * Zawartość: Plik `Baza_Danych_Pacjenta.xlsx`.
3. **Azure SQL Database**
    * Server name: `patientdb-server`
    * Database name: `PatientDB`
    * Compute tier: `Basic`
    * Backup storage: `Locally redundant backup storage`
4. **Azure Cosmos DB**
    * Account type: `Core (SQL)`
    * Collection Name: `Karta-Pacjenta`
    * Backup policy: `Periodic`
    * Backup interval: `240 minutes`
    * Backup retention: `8 hours`
    * Storage redundancy: `Locally-redundant`
5. **Azure Data Factory**
    * Name: `bazydanych-adf`
    * Version: `V2`
    * Region: `Poland Central`

## Pipeline'y

### Pipeline 1: Excel to SQL

* **Nazwa:** `Excel_To_SQL`
* **Cel:** Transfer danych z pliku Excel do Azure SQL Database.
* **Funkcjonalności:**
    * Dane z arkuszy Excel (`Patients`, `Doctors`, `Upcoming_Visits`, `Visit_History`) są mapowane do odpowiednich tabel w SQL.
    * Automatyczne tworzenie tabel, jeśli nie istnieją.
    * Typy danych są konwertowane z Excela na SQL (`String` na `nvarchar`).
* **Zaimplementowane Kopie Danych:**
    * **Patients:** Dane pacjentów.
    * **Doctors:** Informacje o lekarzach.
    * **Upcoming_Visits:** Nadchodzące wizyty pacjentów.
    * **Visit_History:** Historia wizyt pacjentów.
    * Każda kolumna jest dokładnie mapowana z Excela do SQL, z uwzględnieniem odpowiednich typów danych.

### Pipeline 2: SQL to Cosmos DB

* **Nazwa:** `sql_to_cosmoDB_karta_Pacjenta`

* **Cel:** Transformacja danych z SQL do formatu dokumentów JSON w Cosmos DB.

* **Funkcjonalności:**

    * Dane pacjentów są przekształcane w strukturę "Karty Pacjenta" i zapisywane w kolekcji `Karta-Pacjenta` w Cosmos DB.
    * Dokument JSON zawiera:
        * Podstawowe dane pacjenta.
        * Historię wizyt pacjenta.
        * Nadchodzące wizyty pacjenta.
        * Informacje o lekarzach powiązanych z wizytami.

* **Szczegóły implementacji:**

    - **Dataflow:**
        - Użyty dataflow: `dataflow2`
        - **Źródła:**
            - `Azure_Baza_Danych_Patients`
            - `Azure_Baza_Danych_Doctors`
            - `Azure_Baza_Danych_Upcoming_Visits`
            - `Azure_Baza_Danych_Visit_History`
        - **Transformacje:**
            - **Lookup** - Powiązanie pacjentów z historią wizyt i nadchodzącymi wizytami.
            - **Aggregate** - Grupowanie danych według `Patient_ID` w celu utworzenia struktury dokumentu.
            - **Join** - Łączenie zgrupowanych danych w pełen obraz "Karty Pacjenta".
        - **Sink:** `CosmosDbNoSqlContainer2` (kolekcja: `Karta-Pacjenta`).

* **Pipeline - dwa podejścia:**

    1. **Łączenie tabel w Azure Data Factory:**
       - Dane są pobierane z kilku tabel w czasie rzeczywistym w Azure Data Factory, gdzie są łączone i przekształcane w strukturę JSON przy użyciu `Mapping Data Flow`.
       - Tak przetworzone dane są następnie przesyłane do kolekcji `Karta-Pacjenta` w Cosmos DB.

    2. **Użycie widoku SQL:**
       - Widok SQL `PatientCardView` został wcześniej przygotowany w Azure SQL Database. Łączy on dane z tabel, tworząc gotową strukturę JSON.
       - W Azure Data Factory widok ten jest używany jako źródło danych, a JSON jest przesyłany bezpośrednio do kolekcji `Karta-Pacjenta` w Cosmos DB.



## Testowanie i Weryfikacja

- **Testowanie Pipeline'u Excel to SQL:**
    - Weryfikacja poprawności danych przeniesionych z Excela do Azure SQL Database.
    - Sprawdzenie, czy tabele SQL zostały poprawnie utworzone i zawierają wszystkie wymagane kolumny.
- **Testowanie Pipeline'u SQL do Cosmos DB:**
    - Sprawdzenie, czy dokumenty JSON w Cosmos DB odzwierciedlają strukturę "Karty Pacjenta".
    - Testy wydajnościowe dla dużych ilości danych.

## Uwagi

- Pipeline korzysta z funkcji `MappingDataFlow` w Azure Data Factory.
- Wszystkie dane w Cosmos DB są przechowywane w formacie JSON, co ułatwia ich późniejsze przetwarzanie i integrację.
- Problemy z aliasami zostały rozwiązane poprzez dostosowanie zapytań w Data Flow.

