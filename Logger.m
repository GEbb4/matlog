classdef Logger < handle
    %LOGGER Log handling class for console and file logging.
    %   L = LOGGER(C,F,D,R) instantiates a logger object, where C and F are
    %   boolean and control whether logs are printed to the console and
    %   file respectively. D is the level to log equal to or higher, and R
    %   is the root directory (logs go to R/output/logs).

    properties
        levelDebug = 10;    % Logging level for debugging.
        levelInfo = 20;     % Logging level for information.
        levelWarning = 30;  % Logging level for warnings.
        levelError = 40;    % Logging level for errors.

        fidCon = 0;         % File ID of the commandWindow (placeholder).
        fidLog = 0;         % File ID ofthe current log file (placeholder).

        % Default path from root directory to put logs.
        logDir = fullfile('output','logs');

        % Format for datetime in log messages.
        dateTimeFormatLog = 'yyyy-mm-dd HH:MM:SS';

        % Format for log message file names.
        fileNameFormat = 'yyyy-mm-dd_HH-MM-SS.log';

        names               % Holds the string for each level.
        dispLevel           % This level and above will be logged.

    end

    methods
        function obj = Logger(printConsole,printFile,dispLevel,rootDir)
            % LOGGER See class docstring.

            obj.names = {
                obj.levelDebug,   'Debug';
                obj.levelInfo,    'Info';
                obj.levelWarning, 'Warning';
                obj.levelError,   'Error'
                };

            if printConsole
                obj.fidCon = 1;
            end
            if printFile
                % Check the directory exists.
                dirPath = fullfile(rootDir,obj.logDir);
                [dirMade,~,~] = mkdir(dirPath);
                if ~dirMade
                    error('gebb4:logger:directoryNotMade',...
                        'Could not make log directory.');
                end

                % Make the log file itself.
                fileName = datestr(now,obj.fileNameFormat);
                obj.fidLog = fopen(fullfile(dirPath,fileName),'a');
                if obj.fidLog == -1
                    error('gebb4:logger:couldNotOpen',...
                        'Could not open log file.');
                end
            end

            obj.dispLevel = dispLevel;

        end
        function writeLine(obj,log)
            % WRITELINE The root logging method.
            %    WRITELINE(L) logs the character vector L to the console
            %    and file specified by obj.fidCon and obj.fidLog, unless
            %    either is set by 0.

            if obj.fidCon
                fprintf(obj.fidCon,'%s\n',log); % %s avoids accidental escape chars
            end
            if obj.fidLog
                fprintf(obj.fidLog,'%s\n',log); % %s avoids accidental escape chars
            end
        end
        function exception(obj,ex)
            % EXCEPTION Logs an exception and its traceback.
            %    EXCEPTION(E) logs the MException E to the console,
            %    including the stacktrace.


            obj.writeLog(obj.levelError,'== From catch! ==');
            obj.writeLog(obj.levelError,sprintf('%s %s',ex.identifier,ex.message));

            for i = 1:length(ex.stack)
                format = 'Error in %s (%s) on line %d';

                % Get function.
                funcName = ex.stack(i).name;

                % Get file.
                try
                    relPathIdx = strfind(ex.stack(i).file,'+LC');
                    relPathIdx = relPathIdx(end) + 4; % length of "+LC\"
                    fileName = ex.stack(i).file(relPathIdx:end);
                catch
                    fileName = ex.stack(i).file;
                end


                % Get line.
                lineNum = ex.stack(i).line;

                % Read line of file.
                fid = fopen(ex.stack(i).file);
                lineTextCell = textscan(fid,'%s',1,'delimiter','\n', 'headerlines',lineNum-1);
                fclose(fid);

                % Construct the log.
                log = sprintf(format,funcName,fileName,lineNum);

                % Write the output.
                obj.writeLine('');
                obj.writeLine(log);
                obj.writeLine(lineTextCell{1}{1});
            end

        end
        function writeLog(obj,lvl, varargin)
            % WRITELOG The root log message writer.
            %    WRITELOG(L,V) logs the message in V (a cell from varargin)
            %    with level L, where L is a scalar. If L is less than
            %    obj.dispLevel, the log is suppressed.

            if lvl < obj.dispLevel
                return;
            end

            % Level, datetime, callsite, message
            format = '%s\t%s\t%s\t%s';

            % Get level
            level = sprintf('[%s]',obj.names{[obj.names{:}] == lvl, 2}(1));

            % Get datetime
            dateAndTime = datestr(now, obj.dateTimeFormatLog);

            % Get callsite
            [stack,~] = dbstack;
            callsite = sprintf('%s:%d', stack(3).name, stack(3).line);

            % Get message
            message = sprintf(varargin{:});

            % Write the log message
            log = sprintf(format, level, dateAndTime, callsite, message);
            obj.writeLine(log);

        end
        function error(obj,varargin)
            % ERROR An error level log message.
            obj.writeLog(obj.levelError,varargin{:});
        end
        function warning(obj,varargin)
            % WARNING A warning level log message.
            obj.writeLog(obj.levelWarning,varargin{:});
        end
        function info(obj,varargin)
            % INFO An info level log message.
            obj.writeLog(obj.levelInfo,varargin{:});
        end
        function debug(obj,varargin)
            % DEBUG A debug level log message.
            obj.writeLog(obj.levelDebug,varargin{:});
        end
        function finish(obj)
            % FINISH Finish and close the logging session and file.
            if obj.fidLog
                fclose(obj.fidLog);
            end
        end
    end
end
