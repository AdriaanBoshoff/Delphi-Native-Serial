unit NativeSerial;

interface

uses
  Winapi.Windows, System.SysUtils;

type
  TSerialPort = class
  private
    FHandle: THandle;
    FPortName: string;
    FTimeout: DWORD;
  public
    constructor Create(const APort: string; ABaudRate: DWORD = 19200; AParity: Byte = EVENPARITY; ADataBits: Byte = 8; AStopBits: Byte = ONESTOPBIT);
    destructor Destroy; override;

    function IsOpen: Boolean;
    function Write(const Data: TBytes): Boolean;
    function Read(out Data: TBytes; MaxLen: Integer): Integer;
    procedure Close;
  end;

// Parity Def
const
  PARITY_NON = 0;
  PARITY_ODD = 1;
  PARITY_EVEN = 2;
  PARITY_MARK = 3;
  PARITY_SPACE = 4;

implementation

constructor TSerialPort.Create(const APort: string; ABaudRate: DWORD; AParity, ADataBits, AStopBits: Byte);
var
  DCB: TDCB;
  CommTimeouts: TCommTimeouts;
begin
  FPortName := '\\.\' + APort;
  FHandle := CreateFile(PChar(FPortName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  GetCommState(FHandle, DCB);
  DCB.BaudRate := ABaudRate;
  DCB.ByteSize := ADataBits;
  DCB.Parity := AParity;
  DCB.StopBits := AStopBits;

  if not SetCommState(FHandle, DCB) then
    RaiseLastOSError;

  CommTimeouts.ReadIntervalTimeout := 50;
  CommTimeouts.ReadTotalTimeoutConstant := 50;
  CommTimeouts.ReadTotalTimeoutMultiplier := 10;
  CommTimeouts.WriteTotalTimeoutConstant := 50;
  CommTimeouts.WriteTotalTimeoutMultiplier := 10;

  SetCommTimeouts(FHandle, CommTimeouts);
end;

destructor TSerialPort.Destroy;
begin
  Close;
  inherited;
end;

function TSerialPort.IsOpen: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

function TSerialPort.Write(const Data: TBytes): Boolean;
var
  BytesWritten: DWORD;
begin
  Result := WriteFile(FHandle, Data[0], Length(Data), BytesWritten, nil);
end;

function TSerialPort.Read(out Data: TBytes; MaxLen: Integer): Integer;
var
  BytesRead: DWORD;
begin
  SetLength(Data, MaxLen);
  if not ReadFile(FHandle, Data[0], MaxLen, BytesRead, nil) then
    BytesRead := 0;
  SetLength(Data, BytesRead);
  Result := BytesRead;
end;

procedure TSerialPort.Close;
begin
  if IsOpen then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

end.

