program sxema;

uses
  Vcl.Forms,
  UMain in 'UMain.pas' {Form1},
  algorithms in 'algorithms.pas',
  lists in 'lists.pas',
  DrawSVG in 'DrawSVG.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
