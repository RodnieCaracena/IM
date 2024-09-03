
CREATE VIEW vw_StudentAttendanceSummary
AS
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    c.CourseCode,
    c.CourseName,
    asummary.TotalPresent,
    asummary.TotalLate,
    asummary.TotalAbsent
FROM 
    dbo.Student s
    JOIN dbo.AttendanceSummary asummary ON s.StudentID = asummary.StudentID
    JOIN dbo.Course c ON asummary.CourseCode = c.CourseCode;



select * from vw_StudentAttendanceSummary;



CREATE VIEW vw_CourseSchedules
AS
SELECT 
    c.CourseCode,
    c.CourseName,
    cs.DayOfWeek,
    cs.StartTime,
    cs.EndTime,
    cs.GracePeriod,
    cs.GracePeriodForAbsent
FROM 
    dbo.Course c
    JOIN dbo.CourseSchedule cs ON c.CourseCode = cs.CourseCode;



    
CREATE VIEW vw_StudentContactInfo
AS
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    s.ContactNumber,
    s.Email,
    s.GuardianFirstName,
    s.GuardianLastName,
    s.GuardianContactNumber
FROM 
    dbo.Student s;


    
CREATE VIEW vw_EnrollmentDetails
AS
SELECT 
    e.EnrollmentID,
    e.CourseCode,
    e.StudentID,
    e.EnrolledAt,
    e.TotalPresent,
    e.TotalAbsent,
    e.TotalLate,
    e.LastThreeAttendances,
    e.ConsecutiveLateCount,
    e.ConsecutiveAbsentCount
FROM 
    dbo.Enrollment e;







