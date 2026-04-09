unit Infra.Logger.Types;

interface

type
  TLogLevel = (llDebug, llInformation, llWarning, llError);
  TLogLevels = set of TLogLevel;

const
  LOG_LEVEL_NAMES: array[TLogLevel] of string = (
    'DEBUG', 'INFO', 'WARNING', 'ERROR'
  );

  ALL_LOG_LEVELS = [llDebug, llInformation, llWarning, llError];

implementation

end.
