unit lists;

interface

type
  PStrList = ^TStrList;

  TStrList = record
    Data: string;
    Next: PStrList;
  end;

  TBlockType = (BlcTerminatorBgn, BlcTerminatorEnd, BlcProcess, BlcPredProcess,
    BlcData, BlcUpCycleBound, BlcBottomCycleBound, BlcIfSolution,
    BlcCaseSolution, BlcVertLine, BlcHorizLine, BlcLDLine, BlcLULine,
    BlcURDArrowLine, BlcURDLine, BlcLRDLine, BlcLURLine, BlcBottomConnect,
      BlcUpConnect); //URD - Up Right Down

  PBlockList = ^TBlockList;

  TBlockElem = record
    BlockType: TBlockType;
    Row: integer;
    Column: integer;
    Caption: string;
    SubCaption: string;
  end;

  TBlockList = record
    Data: TBlockElem;
    Next: PBlockList;
  end;


var
 // BlockElem: TBlockElem;
  BlockListHead, BlockListLast{, BlockListPt}: PBlockList;

function TknPos(const Substr, Source: string; Offset: integer = 1): integer;
procedure CrtStrList(out Header, LastElem: PStrList);
procedure CrtBlockList(out Header, LastElem: PBlockList);
procedure AddStrList(var LastElem: PStrList; const Data: String);
function AddBlockList(var LastElem: PBlockList; const BlockType: TBlockType;
  const Row, Column: integer; const Caption, SubCaption: string): PBlockList;
function FindMaxColumn(Header: PBlockList): integer;
function IsInStrList(out StrPos, StrLength: integer; const Header: PStrList;
  const Source: string): boolean;
procedure DelStrList(var Header: PStrList);
procedure DelBlockList(var Header: PBlockList);
function ReadAndChangeBlockList(var ElemPointer: PBlockList;
  const LastElemPointer: PBlockList): boolean;
function ReadAndDeleteBlockList(var Header: PBlockList;
  out Data: TBlockElem): boolean;

implementation

uses
  SysUtils;

const
  UnBannedSymb = [';', ' ', '.', '(', ')', '+', '-', '*', '/', ':', '<',
    '>', '='];

function TknPos(const Substr, Source: string; Offset: integer = 1): integer;
// не связано со списками
// глобальное множество UnBannedSymb

var
  PtPos: integer;

begin
  result := 0;
  PtPos := Pos(Substr, Source, Offset);
  while PtPos > 0 do
  begin
    if ((PtPos = 1) or (Source[PtPos - 1] in UnBannedSymb)) and
      (((PtPos + Length(Substr)) > Length(Source)) or
      (Source[PtPos + Length(Substr)] in UnBannedSymb)) then
    begin
      result := PtPos;
      PtPos := 0;
    end
    else
    begin
      Offset := PtPos + Length(Substr);
      PtPos := Pos(Substr, Source, Offset);
    end;
  end;
end;

procedure CrtStrList(out Header, LastElem: PStrList);
begin
  New(Header);
  Header.Data := '';
  Header.Next := nil;
  LastElem := Header;
end;

procedure CrtBlockList(out Header, LastElem: PBlockList);
begin
  New(Header);
  Header.Next := nil;
  LastElem := Header;
end;



procedure AddStrList(var LastElem: PStrList; const Data: String);

var
  TempPointer: PStrList;

begin
  TempPointer := LastElem;
  New(LastElem);
  TempPointer.Next := LastElem;
  LastElem.Data := Data;
  LastElem.Next := nil;
end;

function AddBlockList(var LastElem: PBlockList; const BlockType: TBlockType;
  const Row, Column: integer; const Caption, SubCaption: string): PBlockList;

var
  TempPointer: PBlockList;

begin
  TempPointer := LastElem;
  New(LastElem);
  result := LastElem;
  TempPointer.Next := LastElem;
  LastElem.Data.BlockType := BlockType;
  LastElem.Data.Row := Row;
  LastElem.Data.Column := Column;
  LastElem.Data.Caption := Caption;
  LastElem.Data.SubCaption := SubCaption;
  LastElem.Next := nil;
end;

function FindMaxColumn(Header: PBlockList): integer;
begin
  result := 0;
  while Header <> nil do
  begin
    if Header.Data.Column > result then
    begin
      result := Header.Data.Column;
    end;
    Header := Header.Next;
  end;

end;

function IsInStrList(out StrPos, StrLength: integer; const Header: PStrList;
  const Source: string): boolean;

var
  TempPointer: PStrList;
  PtPos: integer;
  LowSource: string;

begin
  result := false;
  StrPos := 0;
  StrLength := 0;
  TempPointer := Header;
  LowSource := LowerCase(Source);
  while (not result) and (TempPointer.Next <> nil) do
  begin
    TempPointer := TempPointer.Next;
    PtPos := TknPos(TempPointer.Data, LowSource);
    if PtPos > 0 then
    begin
      result := true;
      StrPos := PtPos;
      StrLength := Length(TempPointer.Data);
    end;
  end;

end;

procedure DelStrList(var Header: PStrList);

var
  TempPointer: PStrList;

begin
  repeat
    TempPointer := Header;
    Header := Header.Next;
    Dispose(TempPointer);
  until Header = nil;
end;

procedure DelBlockList(var Header: PBlockList);

var
  TempPointer: PBlockList;

begin
  repeat
    TempPointer := Header;
    Header := Header.Next;
    Dispose(TempPointer);
  until Header = nil;
end;

function ReadAndChangeBlockList(var ElemPointer: PBlockList;
  const LastElemPointer: PBlockList): boolean;
begin
  if (ElemPointer.Next <> nil) and (ElemPointer <> LastElemPointer) then
  begin
    ElemPointer := ElemPointer.Next;
    result := false;
  end
  else
  begin
    result := true;
  end;
end;

function ReadAndDeleteBlockList(var Header: PBlockList;
  out Data: TBlockElem): boolean;

var
  TempPointer: PBlockList;

begin
  if Header.Next <> nil then
  begin
    TempPointer := Header;
    Header := Header.Next;
    Dispose(TempPointer);
    Data := Header.Data;
    result := false;
  end
  else
  begin
    Dispose(Header);
    result := true;
  end;
end;

end.
