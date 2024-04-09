CREATE PROCEDURE dbo.outputDelimitedData
    (
		@storedProcName	NVARCHAR(100), ---Stored Proc with Data to convert to Delmited List 
		@delimiter		CHAR(1) = ',' -- default delimiter to comma
	)
AS
BEGIN
    -- Take all the data from a table and return it as a Delimited File
	-- Author: Al Serize al@bluemindtech.com
	-- Created On : 4/8/24

	-- Step 1: Execute the stored procedure and insert results into a global temporary table
		DECLARE @ExecSql NVARCHAR(MAX);
		SET @ExecSql = N'SELECT * INTO ##tempDataTable FROM OPENROWSET(''SQLNCLI'', ''Server=(local);Trusted_Connection=yes;'', ''SET FMTONLY OFF; EXEC '+ @storedProcName +';'')';
		EXEC sp_executesql @ExecSql;

	-- Step 2: Dynamically construct and execute SQL to concatenate all columns
		DECLARE @Headers NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Sql NVARCHAR(MAX);
		-- Building the header row with column names
		SELECT @Headers = COALESCE(@Headers + @delimiter, '') + QUOTENAME(COLUMN_NAME)
		FROM tempdb.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = '##tempDataTable' AND TABLE_SCHEMA = 'dbo';

		-- Removing brackets from QUOTENAME for header row
		SET @Headers = REPLACE(REPLACE(@Headers, '[', ''), ']', '');

		-- Concatenate column values dynamically for each row
		--SELECT @Columns = COALESCE(@Columns + '+ '', '' + ', '') + 'ISNULL(CONVERT(NVARCHAR(MAX), ' + QUOTENAME(COLUMN_NAME) + '), ''NULL'')'
		SELECT @Columns = COALESCE(@Columns + ' + ' + '''' + @delimiter + '''' + ' + ', '') + 'ISNULL(CONVERT(NVARCHAR(MAX), ' + QUOTENAME(COLUMN_NAME) + '), ''NULL'')'

		FROM tempdb.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = '##tempDataTable' AND TABLE_SCHEMA = 'dbo';

		-- Combine the headers and the data
		SET @Sql = '
					SELECT ''' + @Headers + ''' AS data
					UNION ALL
					SELECT ' + @Columns + ' FROM ##tempDataTable
					';

		-- Execute the dynamic SQL
		EXEC sp_executesql @Sql; 


	-- Step 3: Cleanup by dropping the temporary table
	DROP TABLE IF EXISTS ##tempDataTable; 

END;
