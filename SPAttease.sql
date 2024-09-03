
CREATE PROCEDURE [dbo].[CheckStudentEnrollment]
    @StudentID NVARCHAR(50),
    @CourseCode NVARCHAR(50)
AS
BEGIN
    -- Declare a variable to store the count of enrollments
    DECLARE @EnrollmentCount INT;
    DECLARE @return_value NVARCHAR(150);

    -- Count enrollments for the given student and course
    SELECT @EnrollmentCount = COUNT(*)
    FROM [dbo].[Enrollment]
    WHERE StudentID = @StudentID AND CourseCode = @CourseCode;

    -- Check if the student is enrolled
    IF @EnrollmentCount > 0
    BEGIN
        -- Assign the enrollment message to @return_value
        SET @return_value = 'The student is enrolled in the course.';
    END
    ELSE
    BEGIN
        -- Assign the not enrolled message to @return_value
        SET @return_value = 'The student is not enrolled in the course.';
    END

    -- Return the result as output
    SELECT @return_value AS OutputMessage;
END;







CREATE PROCEDURE [dbo].[CourseAttendanceReport]
    @CourseCode NVARCHAR(50)
AS
BEGIN
    SELECT
        s.StudentID,
        s.FirstName + ' ' + s.LastName AS StudentName,
        a.Date,
        a.TimeIn,
        a.AttendanceStatus
    FROM
        [dbo].[Attendance] a
    JOIN
        [dbo].[Student] s ON a.StudentID = s.StudentID
    WHERE
        a.CourseCode = @CourseCode
    ORDER BY
        a.Date, a.StudentID;
END;



CREATE PROCEDURE [dbo].[GetStudentAttendance]
    @StudentID NVARCHAR(50)
AS
BEGIN
    SELECT
        a.CourseCode,
        c.CourseName,
        a.Date,
        a.TimeIn,
        a.AttendanceStatus
    FROM
        [dbo].[Attendance] a
    JOIN
        [dbo].[Course] c ON a.CourseCode = c.CourseCode
    WHERE
        a.StudentID = @StudentID
    ORDER BY
        a.Date, a.CourseCode;
END;



CREATE PROCEDURE [dbo].[UpdateAttendanceSummary]
    @CourseCode NVARCHAR(50)
AS
BEGIN
    DECLARE @StudentID NVARCHAR(50);
    DECLARE @Index INT = 0;
    DECLARE @TotalStudents INT;

    -- Get the list of student IDs for the course
    DECLARE @StudentList TABLE (StudentID NVARCHAR(50));
    INSERT INTO @StudentList (StudentID)
    SELECT DISTINCT StudentID
    FROM [dbo].[Attendance]
    WHERE CourseCode = @CourseCode;

    -- Get the total number of students
    SELECT @TotalStudents = COUNT(*)
    FROM @StudentList;

    -- Loop over each student and update the summary
    WHILE @Index < @TotalStudents
    BEGIN
        -- Get the StudentID for the current iteration
        SELECT @StudentID = StudentID
        FROM @StudentList
        ORDER BY StudentID
        OFFSET @Index ROWS FETCH NEXT 1 ROWS ONLY;

        -- Update the attendance summary for the student
        UPDATE [dbo].[AttendanceSummary]
        SET TotalPresent = (SELECT COUNT(*) FROM [dbo].[Attendance] WHERE StudentID = @StudentID AND CourseCode = @CourseCode AND AttendanceStatus = 'Present'),
            TotalLate = (SELECT COUNT(*) FROM [dbo].[Attendance] WHERE StudentID = @StudentID AND CourseCode = @CourseCode AND AttendanceStatus = 'Late'),
            TotalAbsent = (SELECT COUNT(*) FROM [dbo].[Attendance] WHERE StudentID = @StudentID AND CourseCode = @CourseCode AND AttendanceStatus = 'Absent')
        WHERE StudentID = @StudentID AND CourseCode = @CourseCode;

        -- Increment the index
        SET @Index = @Index + 1;
    END
END;




CREATE PROCEDURE [dbo].[UpdateStudentAttendanceStatus]
    @StudentID NVARCHAR(50),
    @CourseCode NVARCHAR(50),
    @Date DATE,
    @TimeIn TIME(7)
AS
BEGIN
    DECLARE @CourseStartTime TIME(7);
    DECLARE @CourseEndTime TIME(7);
    DECLARE @GracePeriod TIME(7);
    DECLARE @GracePeriodForAbsent TIME(7);

    -- Get course schedule details
    SELECT 
        @CourseStartTime = cs.StartTime,
        @CourseEndTime = cs.EndTime,
        @GracePeriod = cs.GracePeriod,
        @GracePeriodForAbsent = cs.GracePeriodForAbsent
    FROM [dbo].[CourseSchedule] cs
    WHERE cs.CourseCode = @CourseCode 
    AND cs.DayOfWeek = DATENAME(WEEKDAY, @Date); -- Match the day of the week

    -- Determine attendance status using nested IF...ELSE
    IF @TimeIn IS NOT NULL
    BEGIN
        -- Check if the student checked in before the course start time
        IF @TimeIn <= @CourseStartTime
        BEGIN
            -- The student is on time
            UPDATE [dbo].[Attendance]
            SET AttendanceStatus = 'Present'
            WHERE StudentID = @StudentID 
            AND CourseCode = @CourseCode
            AND Date = @Date;

            PRINT 'Student is present on time.';
        END
        ELSE
        BEGIN
            -- Check if the student is within the grace period
            IF @TimeIn <= DATEADD(MINUTE, DATEPART(MINUTE, @GracePeriod), @CourseStartTime)
            BEGIN
                -- The student is late
                UPDATE [dbo].[Attendance]
                SET AttendanceStatus = 'Late'
                WHERE StudentID = @StudentID 
                AND CourseCode = @CourseCode
                AND Date = @Date;

                PRINT 'Student is late.';
            END
            ELSE
            BEGIN
                -- Check if the student is within the grace period for being marked as absent
                IF @TimeIn <= DATEADD(MINUTE, DATEPART(MINUTE, @GracePeriodForAbsent), @CourseStartTime)
                BEGIN
                    -- The student is marked as present but late beyond grace period
                    UPDATE [dbo].[Attendance]
                    SET AttendanceStatus = 'Late Beyond Grace'
                    WHERE StudentID = @StudentID 
                    AND CourseCode = @CourseCode
                    AND Date = @Date;

                    PRINT 'Student is late beyond grace period.';
                END
                ELSE
                BEGIN
                    -- The student is absent
                    UPDATE [dbo].[Attendance]
                    SET AttendanceStatus = 'Absent'
                    WHERE StudentID = @StudentID 
                    AND CourseCode = @CourseCode
                    AND Date = @Date;

                    PRINT 'Student is absent.';
                END
            END
        END
    END
    ELSE
    BEGIN
        -- TimeIn is NULL, mark as absent
        UPDATE [dbo].[Attendance]
        SET AttendanceStatus = 'Absent'
        WHERE StudentID = @StudentID 
        AND CourseCode = @CourseCode
        AND Date = @Date;

        PRINT 'Student did not check in and is absent.';
    END
END;



