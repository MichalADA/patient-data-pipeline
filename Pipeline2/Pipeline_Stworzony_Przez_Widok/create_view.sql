CREATE VIEW dbo.PatientCardView AS
SELECT 
    p.Patient_ID,
    p.First_Name,
    p.Last_Name,
    p.Date_of_Birth,
    p.Phone_Number,
    p.Pesel,
    -- Podzapytanie dla historii wizyt
    (
        SELECT 
            vh.History_ID,
            vh.Date,
            vh.Time,
            CONCAT(d.First_Name, ' ', d.Last_Name, ' (', d.Specialization, ')') AS Doctor,
            vh.Diagnosis,
            vh.Treatment,
            vh.Additional_Notes
        FROM 
            dbo.Visit_History vh
        INNER JOIN 
            dbo.Doctors d ON vh.Doctor_ID = d.Doctor_ID
        WHERE 
            vh.Patient_ID = p.Patient_ID
        FOR JSON PATH
    ) AS Visit_History,
    -- Podzapytanie dla nadchodzących wizyt
    (
        SELECT 
            uv.Upcoming_ID,
            uv.Date,
            uv.Time,
            CONCAT(d.First_Name, ' ', d.Last_Name, ' (', d.Specialization, ')') AS Doctor,
            uv.Notes
        FROM 
            dbo.Upcoming_Visits uv
        INNER JOIN 
            dbo.Doctors d ON uv.Doctor_ID = d.Doctor_ID
        WHERE 
            uv.Patient_ID = p.Patient_ID
        FOR JSON PATH
    ) AS Upcoming_Visits
FROM 
    dbo.Patients p;
