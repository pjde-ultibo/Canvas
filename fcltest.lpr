program fcltest;

{$mode objfpc}{$H+}

{$define use_tftp}
{$hints off}
{$notes off}

uses
  RaspberryPi3,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Console,
  GraphicsConsole,
  Services,

  FPimage,
  FPReadPNG,
  FPReadJPEG,
  FPReadBMP,
  FPReadTIFF,
  FPReadGIF,
  FPReadTGA,
  FPReadPCX,
  FPReadPSD,

  uCanvas,
{$ifdef use_tftp}
  uTFTP, Winsock2,
{$endif}
  Logging,
  uLog,
  FrameBuffer,
  freetypeh,
  Ultibo
  { Add additional units here };

const
  BACK_COLOUR                    = $FF055A93;

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
  IPAddress : string;
  SysLogger : PLoggingDevice;
  i : integer;
  BGnd : TCanvas;
  aCanvas : TCanvas;
  anImage : TFPCustomImage;
  DefFrameBuff : PFrameBufferDevice;
  Properties : TWindowProperties;

procedure Log1 (s : string);
begin
  ConsoleWindowWriteLn (Console1, s);
end;

procedure Log2 (s : string);
begin
  ConsoleWindowWriteLn (Console2, s);
end;

procedure Msg2 (Sender : TObject; s : string);
begin
  Log2 ('TFTP - ' + s);
end;

procedure WaitForSDDrive;
begin
  while not DirectoryExists ('C:\') do sleep (500);
end;

function WaitForIPComplete : string;
var
  TCP : TWinsock2TCPClient;
begin
  TCP := TWinsock2TCPClient.Create;
  Result := TCP.LocalAddress;
  if (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') then
    begin
      while (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') do
        begin
          sleep (1000);
          Result := TCP.LocalAddress;
        end;
    end;
  TCP.Free;
end;

begin
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := GraphicsWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT);
  GraphicsWindowSetBackcolor (Console3, BACK_COLOUR);
  GraphicsWindowClear (Console3);

  DefFrameBuff := FramebufferDeviceGetDefault;
  aCanvas := TCanvas.Create;
  if GraphicsWindowGetProperties (Console3, @Properties) = ERROR_SUCCESS then
    begin
      aCanvas.Left := Properties.X1;
      aCanvas.Top := Properties.Y1;
      aCanvas.SetSize (Properties.X2 - Properties.X1, Properties.Y2 - Properties.Y1 , COLOR_FORMAT_ARGB32);
    end;
  aCanvas.Fill (BACK_COLOUR);

  anImage := TFPMemoryImage.Create (0, 0);

  SetLogProc (@Log1);
  SysLogger := LoggingDeviceFindByType (LOGGING_TYPE_SYSLOG);
  SysLogLoggingSetTarget (SysLogger, '10.0.0.4');
  LoggingDeviceSetDefault (SysLogger);

  Log1 ('Canvas with FPImage Test.');
  Log1 ('2018 pjde.');
  if SysLogger = nil then Log1 ('SysLogger Inactive.') else Log1 ('SysLogger Active.');
  WaitForSDDrive;
  Log1 ('SD Drive Ready.');
  IPAddress := WaitForIPComplete;
  {$ifdef use_tftp}
  Log2 ('TFTP - Enabled.');
  Log2 ('TFTP - Syntax "tftp -i ' + IPAddress + ' put kernel7.img"');
  SetOnMsg (@Msg2);
  Log2 ('');
  {$endif}

  aCanvas.Flush (DefFrameBuff);   // renamed draw to flush

  BGnd := TCanvas.Create;      // create a background canvas to speed up redraws
  BGnd.SetSize (aCanvas.Width, aCanvas.Height, aCanvas.ColourFormat);
  try
    anImage.LoadFromFile ('bg.png');
    BGnd.DrawImage (anImage, 0, 0, BGnd.Width, BGnd.Height);
  finally
  end;
  BGnd.DrawText (10, 30, 'BACKGROUND TEXT.', 'arial', 24, COLOR_WHITE);

  ch := #0;
  while true do
    begin
      if ConsoleGetKey (ch, nil) then
        case (ch) of
          '1' :
            begin
              Log1 ('Nos of Handlers ' + ImageHandlers.Count.ToString);
              for i := 0 to ImageHandlers.Count - 1 do
                begin
                  Log1 ('Handler ' + i.ToString + ' ' + ImageHandlers.TypeNames[i] + ' ext ' + ImageHandlers.Extensions[ImageHandlers.TypeNames[i]]);
                end;
            end;
          '2' :
            begin
              try
                anImage.LoadFromFile ('test.png');
              except
                on e : exception do Log1 ('Image Error ' + e.Message);
              end;
            end;
          '3' :
            begin
              try
                anImage.LoadFromFile ('test.jpg');
              except
                on e : exception do Log1 ('Image Error ' + e.Message);
              end;
            end;
          '4' :
            begin
              try
                anImage.LoadFromFile ('test.bmp');
              except
                on e : exception do Log1 ('Image Error ' + e.Message);
              end;
            end;
          '5' :
            begin
              aCanvas.Assign (BGnd);   // assign background
              aCanvas.DrawImage (anImage, 30, 30, 40, 80);
              aCanvas.Flush (DefFrameBuff);
            end;
          '6' :
            begin
              aCanvas.DrawImage (anImage, 100, 100);
              aCanvas.Flush (DefFrameBuff);
            end;
          '7' :
            begin
              aCanvas.DrawImage (anImage, 150, 150);
              aCanvas.Flush (DefFrameBuff);
            end;
          '8' :
            begin
              aCanvas.DrawImage (anImage, 0, 0, aCanvas.Width, aCanvas.Height);
              aCanvas.Flush (DefFrameBuff);
            end;
          'B', 'b' :
            begin
              aCanvas.Assign (BGnd);
              aCanvas.Flush (DefFrameBuff);
            end;
        end;
    end;
  ThreadHalt (0);
end.

