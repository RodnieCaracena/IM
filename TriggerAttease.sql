
CREATE TRIGGER trg_UpdateAttendanceSummary
ON dbo.Attendance
AFTER INSERT
AS
BEGIN
    DECLARE @StudentID NVARCHAR(50), @CourseCode NVARCHAR(50), @AttendanceStatus NVARCHAR(50);

    SELECT @StudentID = StudentID, @CourseCode = CourseCode, @AttendanceStatus = AttendanceStatus
    FROM inserted;

    IF @AttendanceStatus = 'Present'
    BEGIN
        UPDATE dbo.AttendanceSummary
        SET TotalPresent = TotalPresent + 1
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
    ELSE IF @AttendanceStatus = 'Late'
    BEGIN
        UPDATE dbo.AttendanceSummary
        SET TotalLate = TotalLate + 1
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
    ELSE IF @AttendanceStatus = 'Absent'
    BEGIN
        UPDATE dbo.AttendanceSummary
        SET TotalAbsent = TotalAbsent + 1
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
END;



CREATE TRIGGER trg_UpdateLastThreeAttendances
ON dbo.Attendance
AFTER INSERT
AS
BEGIN
    DECLARE @StudentID NVARCHAR(50), @CourseCode NVARCHAR(50), @AttendanceStatus NVARCHAR(50), @NewStatus NVARCHAR(3), @CurrentStatus NVARCHAR(3);

    SELECT @StudentID = StudentID, @CourseCode = CourseCode, @AttendanceStatus = AttendanceStatus
    FROM inserted;

    SELECT @CurrentStatus = LastThreeAttendances
    FROM dbo.Enrollment
    WHERE StudentID = @StudentID AND CourseCode = @CourseCode;

    SET @NewStatus = SUBSTRING(@CurrentStatus, 2, 2) + LEFT(@AttendanceStatus, 1);

    UPDATE dbo.Enrollment
    SET LastThreeAttendances = @NewStatus
    WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
END;



CREATE TRIGGER trg_UpdateConsecutiveLateCount
ON dbo.Attendance
AFTER INSERT
AS
BEGIN
    DECLARE @StudentID NVARCHAR(50), @CourseCode NVARCHAR(50), @AttendanceStatus NVARCHAR(50);

    SELECT @StudentID = StudentID, @CourseCode = CourseCode, @AttendanceStatus = AttendanceStatus
    FROM inserted;

    IF @AttendanceStatus = 'Late'
    BEGIN
        UPDATE dbo.Enrollment
        SET ConsecutiveLateCount = ConsecutiveLateCount + 1
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
    ELSE
    BEGIN
        UPDATE dbo.Enrollment
        SET ConsecutiveLateCount = 0
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
END;





CREATE TRIGGER trg_UpdateConsecutiveAbsentCount
ON dbo.Attendance
AFTER INSERT
AS
BEGIN
    DECLARE @StudentID NVARCHAR(50), @CourseCode NVARCHAR(50), @AttendanceStatus NVARCHAR(50);

    SELECT @StudentID = StudentID, @CourseCode = CourseCode, @AttendanceStatus = AttendanceStatus
    FROM inserted;

    IF @AttendanceStatus = 'Absent'
    BEGIN
        UPDATE dbo.Enrollment
        SET ConsecutiveAbsentCount = ConsecutiveAbsentCount + 1
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
    ELSE
    BEGIN
        UPDATE dbo.Enrollment
        SET ConsecutiveAbsentCount = 0
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;
    END
END;


CREATE TRIGGER trg_PreventDuplicateEnrollment
ON dbo.Enrollment
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @StudentID NVARCHAR(50), @CourseCode NVARCHAR(50);

    SELECT @StudentID = StudentID, @CourseCode = CourseCode
    FROM inserted;

    IF EXISTS (SELECT 1 FROM dbo.Enrollment WHERE StudentID = @StudentID AND CourseCode = @CourseCode)
    BEGIN
        RAISERROR ('Duplicate enrollment detected.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO dbo.Enrollment (CourseCode, StudentID, EnrolledAt, TotalPresent, TotalAbsent, TotalLate, LastThreeAttendances, ConsecutiveLateCount, ConsecutiveAbsentCount)
    SELECT CourseCode, StudentID, EnrolledAt, TotalPresent, TotalAbsent, TotalLate, LastThreeAttendances, ConsecutiveLateCount, ConsecutiveAbsentCount
    FROM inserted;
END;




