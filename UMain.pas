unit UMain;

interface

uses
  algorithms, DrawSVG, Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.VirtualImage,
  Vcl.OleCtrls, SHDocVw, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Menus, System.ImageList,
  Vcl.ImgList, System.Actions, Vcl.ActnList, Vcl.ExtCtrls, Vcl.StdActns;

type
  TFrmMain = class(TForm)
    MemoMain: TMemo;
    TBMain: TToolBar;
    MainMenuMain: TMainMenu;
    ALMain: TActionList;
    ILMain: TImageList;
    OpenDialogMain: TOpenDialog;
    SaveDialogMain: TSaveDialog;
    File1: TMenuItem;
    Splitter1: TSplitter;
    WebBrowserMain: TWebBrowser;
    FileSave: TAction;
    FileOpen: TAction;
    FileSaveAs: TAction;
    Open1: TMenuItem;
    Save1: TMenuItem;
    SaveAs1: TMenuItem;
    ToolButtonOpen: TToolButton;
    ToolButtonSave: TToolButton;
    ToolButtonSaveAs: TToolButton;
    EditMain: TEdit;
    MakeSVG: TAction;
    ToolButtonCreate: TToolButton;
    procedure FileOpenExecute(Sender: TObject);
    procedure MakeSVGExecute(Sender: TObject);
    procedure FileSaveExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FileSaveAsExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;
  TempFileName, SaveFileName, OpenFileName: String;

implementation

{$R *.dfm}

procedure TFrmMain.FileOpenExecute(Sender: TObject);
begin
  if not(OpenDialogMain.Execute) then
    Exit;
  OpenFileName := OpenDialogMain.Files[0];
  MemoMain.Lines.LoadFromFile(OpenFileName);

  SaveFileName := ChangeFileExt(OpenFileName, '.svg');;
  TempFileName := ExtractFilePath(Application.ExeName) + 'temp.svg';

  MakeSVG.Enabled := True;
end;

procedure TFrmMain.FileSaveAsExecute(Sender: TObject);
begin
  if not(SaveDialogMain.Execute) then
    Exit;
  SaveFileName := SaveDialogMain.Files[0];
  FileSaveExecute(self);
end;

procedure TFrmMain.FileSaveExecute(Sender: TObject);
begin
  if FileExists(TempFileName) then
  begin
    try
      if not CopyFile(PChar(TempFileName), PChar(SaveFileName), False) then
        ShowMessage('Ошибка при копировании файла: ' +
          SysErrorMessage(GetLastError))
      else
        FileSetAttr(PChar(SaveFileName), FileGetAttr(SaveFileName) and
          not faHidden);

    except
      on E: Exception do
        ShowMessage('Ошибка при копировании файла: ' + E.Message);
    end;
  end
  else
    ShowMessage('Ошибка при копировании файла: Временный файл не найден');

  FileSave.Enabled := False;
end;

procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FileExists(TempFileName) then
  begin
    try
      DeleteFile(TempFileName);
    except
      on E: Exception do
        ShowMessage('Ошибка при удалении файла: ' + E.Message);
    end;
  end
end;

procedure TFrmMain.MakeSVGExecute(Sender: TObject);

var
  MaxColumn, MaxRow: integer;

begin
  MaxRow := StrToInt(EditMain.Text);
  if MaxRow <= 2 then
  begin
    ShowMessage('Минимальное кол-во блоков - 3');
  end
  else
  begin
    MakeBlockList(MaxRow, MaxColumn, OpenFileName);
    DrawFlowchart(MaxRow, MaxColumn, TempFileName);
    WebBrowserMain.Navigate('file:///' + TempFileName);
    FileSave.Enabled := True;
    FileSaveAs.Enabled := True;
  end;
end;

end.
