unit algorithms;

interface

procedure MakeBlockList(const MaxColumnSize: integer; out MaxColumn: integer;
  const OpenFileName: string);

implementation

uses

  System.SysUtils, lists;

type
  TToken = (TknUnknown, TknBegin, TknDo, TknElse, TknRepeat, TknThen, TknOf);

  TStatement = record
    Str: string;
    LastToken: TToken;
  end;

  TLastStrTokens = record
    Shift: integer;
    Str: string;
  end;

const
  MaxSymbInBLock = 70;

var

  CodeFile: TextFile;
  ProcessStr, WasteCodeString, WasteStatementStr: String;
  Statement: TStatement;
  FuncListHead, FuncListLast, ProcListHead, ProcListLast: PStrList;
  EmptyRow, EmptyColumn, FuncNumb: integer;
  FreeCycleName: char;

function NextString(const CodeFile: TextFile): string;
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ WasteCodeString и
// CodeFile

var
  PPos1, PPos2: integer;

begin
  repeat
    if length(WasteCodeString) < 1 then
    begin
      if EoF(CodeFile) then
      begin
        // ОШИБКА
        raise Exception.Create('Некорректый файл(52)');
      end;
      readln(CodeFile, result);
    end
    else
    begin
      result := WasteCodeString;
      WasteCodeString := '';
    end;
    PPos1 := Pos('{', result);
    while PPos1 > 0 do
    begin
      PPos2 := Pos('}', result);
      if PPos2 > 0 then
      begin
        Delete(result, PPos1, PPos2 - PPos1 + 1);
        insert(' ', result, PPos1);
      end
      else
      begin
        Delete(result, PPos1, length(result) - PPos1 + 1);
        repeat
          if EoF(CodeFile) then
          begin
            // ОШИБКА
            raise Exception.Create('Некорректый файл(77)');
          end;
          readln(CodeFile, WasteCodeString);
          PPos2 := Pos('}', WasteCodeString);
        until PPos2 > 0;
        Delete(WasteCodeString, 1, PPos2);
      end;
      PPos1 := Pos('{', result);
    end;
    PPos1 := Pos('//', result);
    if PPos1 > 0 then
      Delete(result, PPos1, length(result) - PPos1 + 1);
    result := Trim(result);
  until length(result) > 0;

end;

function NextStatement(Const CodeFile: TextFile): TStatement;
// ГЛОБАЛЬНАЯ ПЕРЕМЕННААЯ WasteStatementStr и множество UnBannedSymb

const

  StrTokensArr: array [1 .. 12] of TLastStrTokens = ((Shift: 0; Str: ';'),
    (Shift: 0; Str: ''''), (Shift: 0; Str: '('), (Shift: - 1; Str: 'end'),
    (Shift: 4; Str: 'begin'), (Shift: - 1; Str: 'else'), (Shift: 3;
    Str: 'else'), (Shift: 1; Str: 'do'), (Shift: 5; Str: 'repeat'), (Shift: 3;
    Str: 'then'), (Shift: 1; Str: 'of'), (Shift: 3; Str: 'end.'));

var
  TempStr, TempLowStr: string;
  i, MinI, ChkPos, PtPos, ApostPos, ExstPos, MinPt, TempLength: integer;
  IsFound, IsApostFound: boolean;

begin
  result.Str := '';
  result.LastToken := TknUnknown;
  ChkPos := 1;
  repeat
    if length(WasteStatementStr) < 1 then
      TempStr := NextString(CodeFile)
    else
    begin
      TempStr := WasteStatementStr;
      WasteStatementStr := '';
    end;
    MinPt := MaxInt;
    MinI := 0;
    TempLowStr := LowerCase(TempStr);
    TempLength := length(TempLowStr);
    for i := Low(StrTokensArr) to 3 do
    begin
      if StrTokensArr[i].Shift < 0 then
        ExstPos := 1
      else
        ExstPos := 0;

      PtPos := Pos(StrTokensArr[i].Str, TempLowStr, ChkPos);
      if PtPos > ExstPos then
      begin
        PtPos := PtPos + StrTokensArr[i].Shift;
        if PtPos < MinPt then
        begin
          MinPt := PtPos;
          MinI := i;
        end;
      end;
    end;
    for i := 4 to High(StrTokensArr) do
    begin
      if StrTokensArr[i].Shift < 0 then
        ExstPos := 1
      else
        ExstPos := 0;

      PtPos := TknPos(StrTokensArr[i].Str, TempLowStr, ChkPos);
      if PtPos > ExstPos then
      begin
        PtPos := PtPos + StrTokensArr[i].Shift;
        if PtPos < MinPt then
        begin
          MinPt := PtPos;
          MinI := i;
        end;
      end;
    end;
    if (MinPt < MaxInt) and (MinI <> 2) and (MinI <> 3) then
    begin
      case MinI of
        1: // ;
          begin
            Delete(TempStr, MinPt, 1);
            insert(' ', TempStr, MinPt);
          end;
        5: // begin
          result.LastToken := TknBegin;
        7: // else_
          result.LastToken := TknElse;
        8: // do
          result.LastToken := TknDo;
        9: // repeat
          result.LastToken := TknRepeat;
        10: // then
          result.LastToken := TknThen;
        11: // of
          result.LastToken := TknOf;
      else
      end;
      result.Str := Trim(Copy(TempStr, 1, MinPt));
      Delete(TempStr, 1, MinPt);
      WasteStatementStr := Trim(TempStr);
    end
    else
    begin
      if MinI = 2 then
      begin
        IsFound := false;
        repeat
          PtPos := Pos('''', TempStr, MinPt + 1);
          if (PtPos > 0) and (PtPos <> Pos('''''', TempStr, MinPt + 1)) then
          begin
            WasteStatementStr := Trim(TempStr);
            ChkPos := PtPos + 1;
            IsFound := true
          end
          else
          begin
            if PtPos > 0 then
            begin
              MinPt := PtPos + 2;
            end
            else
            begin
              MinPt := length(TempStr);
              TempStr := TempStr + ' ' + NextString(CodeFile);
            end;
          end;
        until IsFound;

      end
      else
      begin
        if MinI = 3 then
        // не работает с вложенными скобками но повлиять не должно
        begin
          IsFound := false;
          repeat


            ApostPos := Pos('''', TempStr, MinPt + 1);
            PtPos := Pos(')', TempStr, MinPt + 1);
            while (ApostPos > 0) and ((ApostPos < PtPos) or (PtPos = 0)) do
            begin
              MinPt := ApostPos;
              IsApostFound := false;
              repeat
                PtPos := Pos('''', TempStr, MinPt + 1);
                if (PtPos > 0) and (PtPos <> Pos('''''', TempStr, MinPt + 1))
                then
                begin
                  WasteStatementStr := Trim(TempStr);
                  MinPt := PtPos;
                  IsApostFound := true
                end
                else
                begin
                  if PtPos > 0 then
                  begin
                    MinPt := PtPos + 2;
                  end
                  else
                  begin
                    MinPt := length(TempStr);
                    TempStr := TempStr + ' ' + NextString(CodeFile);
                  end;
                end;
              until IsApostFound;
              ApostPos := Pos('''', TempStr, MinPt + 1);
              PtPos := Pos(')', TempStr, MinPt + 1);
            end;



            PtPos := Pos(')', TempStr, MinPt + 1);
            if (PtPos > 0) then
            begin
              WasteStatementStr := Trim(TempStr);
              ChkPos := PtPos + 1;
              IsFound := true
            end
            else
            begin
              MinPt := length(TempStr);
              TempStr := TempStr + ' ' + NextString(CodeFile);
            end;
          until IsFound;
        end
        else
        begin
          WasteStatementStr := Trim(TempStr) + ' ' + NextString(CodeFile);
          ChkPos := TempLength + 1;
        end;
      end;
    end;

  until length(result.Str) > 0;
end;

procedure SeparateFunc(var Source: string);
// ГЛОБАЛЬНАЯ ПЕРЕМЕННАЯ FuncNumb

var
  FuncPos, TempFuncPos, ParenthPos, FuncLength: integer;
  FuncStr, ParenthStr, ResultStr: string;
  ParenthNest: integer;

begin

  while IsInStrList(FuncPos, FuncLength, FuncListHead, Source) do
  begin
    inc(FuncNumb);
    ParenthPos := 0;
    ParenthStr := '';
    TempFuncPos := FuncPos + FuncLength;
    while (Source[TempFuncPos] = ' ') and (TempFuncPos < length(Source)) do
      inc(TempFuncPos);
    if Source[TempFuncPos] = '(' then
    begin
      ParenthPos := TempFuncPos;
      ParenthNest := 1;
      while ParenthNest > 0 do
      begin
        if TempFuncPos >= length(Source) then
          raise Exception.Create('Некорректый файл(вызов функции)(276)');
        inc(TempFuncPos);
        if Source[TempFuncPos] = ')' then
          dec(ParenthNest)
        else if Source[TempFuncPos] = '(' then
          inc(ParenthNest);

      end;
      FuncLength := TempFuncPos - FuncPos + 1;
      ParenthStr := Copy(Source, ParenthPos + 1, TempFuncPos - ParenthPos - 1);
    end;
    FuncStr := Copy(Source, FuncPos, FuncLength);
    Delete(Source, FuncPos, FuncLength);
    ResultStr := 'result' + IntToStr(FuncNumb);
    insert(ResultStr, Source, FuncPos);
    if length(ParenthStr) > 0 then
    begin
      SeparateFunc(ParenthStr);
      Delete(FuncStr, ParenthPos - FuncPos + 2, TempFuncPos - ParenthPos - 1);
      insert(ParenthStr, FuncStr, ParenthPos - FuncPos + 2);
    end;
    AddBlockList(BlockListLast, BlcPredProcess, EmptyRow, EmptyColumn,
      ResultStr + ' := ' + FuncStr, '');
    inc(EmptyRow);

  end;

end;

procedure ProcsStatement(); forward;

procedure OutputProcess(var ProcessStr: string);
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ EmptyRow BlockListLast

begin
  if length(ProcessStr) > 0 then
  begin
    AddBlockList(BlockListLast, BlcProcess, EmptyRow, EmptyColumn,
      ProcessStr, '');
    inc(EmptyRow);
    ProcessStr := '';
  end;
end;

procedure ProcsPreCycle();
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ

var
  PtPos, TempPtPos: integer;
  TempLowStr, UpBoundStr, BottomBoundStr: string;
  CycleName: string;

begin
  TempLowStr := LowerCase(Statement.Str);
  PtPos := TknPos('for', TempLowStr);
  if PtPos > 0 then
  begin // если for
    TempPtPos := TknPos('to', TempLowStr);
    if TempPtPos > 0 then
    begin // если to
      UpBoundStr := Trim(Copy(Statement.Str, PtPos + length('for'),
        TempPtPos - length('for') - PtPos)) + '; ' +
        Trim(Copy(Statement.Str, PtPos + length('for'), Pos(':=', TempLowStr) -
        length('for') - PtPos)) + ' <= ' +
        Trim(Copy(Statement.Str, TempPtPos + length('to'),
        length(Statement.Str) - (TempPtPos + length('to') + 1)));

      BottomBoundStr := 'Inc(' + Trim(Copy(Statement.Str, PtPos + length('for'),
        Pos(':=', TempLowStr) - length('for') - PtPos)) + ')';
    end
    else
    begin
      TempPtPos := TknPos('downto', TempLowStr);
      if TempPtPos > 0 then
      begin // если downto
        UpBoundStr := Trim(Copy(Statement.Str, PtPos + length('for'),
          TempPtPos - length('for') - PtPos)) + '; ' +
          Trim(Copy(Statement.Str, PtPos + length('for'),
          Pos(':=', TempLowStr) - length('for') - PtPos)) + ' >= ' +
          Trim(Copy(Statement.Str, TempPtPos + length('downto'),
          length(Statement.Str) - (TempPtPos + length('downto') + 1)));

        BottomBoundStr := 'Dec(' +
          Trim(Copy(Statement.Str, PtPos + length('for'),
          Pos(':=', TempLowStr) - length('for') - PtPos)) + ')'
      end
      else
      begin
        TempPtPos := TknPos('in', TempLowStr);
        if TempPtPos > 0 then
        begin // если in
          UpBoundStr := Trim(Copy(Statement.Str, PtPos + length('for'),
            length(Statement.Str) - (PtPos + length('for') +
            length('do') - 1)));
          BottomBoundStr := '';
        end
        else
        begin
          raise Exception.Create('Некорректый файл(цикл for)(373)');
          // ошибка
        end;
      end;
    end;
  end
  else
  begin
    PtPos := TknPos('while', TempLowStr);
    if PtPos > 0 then
    begin // если while
      UpBoundStr := Trim(Copy(Statement.Str, PtPos + length('while'),
        length(Statement.Str) - (PtPos + length('while') + length('do') - 1)));
      BottomBoundStr := '';
    end
    else
    begin
      raise Exception.Create('Некорректый файл(цикл с предусловием)(390)');
      // ошибка
    end;
  end;


  if FreeCycleName > 'Z' then
    CycleName := 'N' + IntToStr(Ord(FreeCycleName) - Ord('Z'))
  else
    CycleName := FreeCycleName;

  AddBlockList(BlockListLast, BlcUpCycleBound, EmptyRow, EmptyColumn,
    UpBoundStr, CycleName);
  inc(EmptyRow);
  FreeCycleName := succ(FreeCycleName);
  Statement := NextStatement(CodeFile);
  ProcsStatement();
  OutputProcess(ProcessStr);
  AddBlockList(BlockListLast, BlcBottomCycleBound, EmptyRow, EmptyColumn,
    BottomBoundStr, CycleName);
  inc(EmptyRow);
end;

procedure ProcsPostCycle();
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ

var
  PtPos: integer;
  UpBoundStr, BottomBoundStr: string;
  CycleName: char;

begin
  UpBoundStr := '';
  CycleName := FreeCycleName;
  AddBlockList(BlockListLast, BlcUpCycleBound, EmptyRow, EmptyColumn,
    UpBoundStr, CycleName);
  inc(EmptyRow);
  FreeCycleName := succ(FreeCycleName);
  Statement := NextStatement(CodeFile);
  PtPos := TknPos('until', LowerCase(Statement.Str));
  while PtPos = 0 do
  begin
    ProcsStatement();
    PtPos := TknPos('until', LowerCase(Statement.Str));
  end;
  OutputProcess(ProcessStr);
  PtPos := PtPos + length('until');
  BottomBoundStr := Trim(Copy(Statement.Str, PtPos, length(Statement.Str) -
    PtPos + 1));
  AddBlockList(BlockListLast, BlcBottomCycleBound, EmptyRow, EmptyColumn,
    BottomBoundStr, CycleName);
  Statement := NextStatement(CodeFile);
  inc(EmptyRow);
end;

procedure ProcsIf();
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ

var
  i, PtPos, StartRow, EndRow, StartColumn: integer;
  CaptionStr: string;
  SolutionPt: PBlockList;

begin
  PtPos := TknPos('if', LowerCase(Statement.Str));
  if PtPos > 0 then
  begin
    PtPos := PtPos + length('if');
    CaptionStr := Trim(Copy(Statement.Str, PtPos, length(Statement.Str) - PtPos
      - length('then') + 1));
    SolutionPt := AddBlockList(BlockListLast, BlcIfSolution, EmptyRow,
      EmptyColumn, CaptionStr, '');
    StartRow := EmptyRow;
    StartColumn := EmptyColumn;
    inc(EmptyRow);
    Statement := NextStatement(CodeFile);
    ProcsStatement();
    OutputProcess(ProcessStr);
    EndRow := EmptyRow;
    EmptyRow := StartRow + 1;
    EmptyColumn := FindMaxColumn(SolutionPt) + 1;
    if Statement.LastToken = TknElse then
    begin
      Statement := NextStatement(CodeFile);
      ProcsStatement();
      OutputProcess(ProcessStr);
    end;

    // отрисовка линий
    AddBlockList(BlockListLast, BlcLDLine, StartRow, EmptyColumn, '', '');

    for i := StartColumn + 1 to EmptyColumn - 1 do
      AddBlockList(BlockListLast, BlcHorizLine, StartRow, i, '', '');

    if EndRow > EmptyRow then
    begin
      for i := EmptyRow to EndRow - 1 do
        AddBlockList(BlockListLast, BlcVertLine, i, EmptyColumn, '', '');
      EmptyRow := EndRow;
    end
    else
    begin
      for i := EndRow to EmptyRow - 1 do
        AddBlockList(BlockListLast, BlcVertLine, i, StartColumn, '', '');
    end;

    AddBlockList(BlockListLast, BlcLULine, EmptyRow, EmptyColumn, '', '');
    AddBlockList(BlockListLast, BlcURDArrowLine, EmptyRow, StartColumn, '', '');

    for i := StartColumn + 1 to EmptyColumn - 1 do
      AddBlockList(BlockListLast, BlcHorizLine, EmptyRow, i, '', '');

    EmptyRow := EmptyRow + 1;
    EmptyColumn := StartColumn;

  end
  else
  begin
    raise Exception.Create('Некорректый файл(if)(503)');
    // ОШИБКА
  end;
end;

procedure ProcsCase();

var
  PtPos, StartRow, MaxRow, StartColumn, EndColumn, i, j: integer;
  CaptionStr: string;
  SolutionPt: PBlockList;
  IsElseFound: boolean;
  ColumnSet: set of 0 .. 255;

begin
  PtPos := TknPos('case', LowerCase(Statement.Str));
  if PtPos > 0 then
  begin
    PtPos := PtPos + length('case');
    CaptionStr := Trim(Copy(Statement.Str, PtPos, length(Statement.Str) - PtPos
      - length('of') + 1));
    AddBlockList(BlockListLast, BlcCaseSolution, EmptyRow, EmptyColumn,
      CaptionStr, '');
    inc(EmptyRow);
    Statement := NextStatement(CodeFile);

    PtPos := Pos(':', Statement.Str);
    if PtPos <= 0 then
    begin
      raise Exception.Create('Некорректый файл(case)(532)');
    end;
    CaptionStr := Trim(Copy(Statement.Str, 1, PtPos - 1));
    Delete(Statement.Str, 1, PtPos);
    Statement.Str := Trim(Statement.Str);
    SolutionPt := AddBlockList(BlockListLast, BlcURDLine, EmptyRow, EmptyColumn,
      CaptionStr, '');
    StartRow := EmptyRow;
    StartColumn := EmptyColumn;
    EndColumn := EmptyColumn;
    inc(EmptyRow);
    ProcsStatement();
    OutputProcess(ProcessStr);
    MaxRow := EmptyRow;
    IsElseFound := false;

    while TknPos('end', LowerCase(Statement.Str)) = 0 do
    begin
      if Statement.LastToken = TknElse then
      begin
        IsElseFound := true;
        Statement := NextStatement(CodeFile);
        EmptyRow := StartRow;
        EmptyColumn := FindMaxColumn(SolutionPt) + 1;
        SolutionPt := AddBlockList(BlockListLast, BlcLDLine, EmptyRow,
          EmptyColumn, 'Else', '');
        inc(EmptyRow);
        if TknPos('end', LowerCase(Statement.Str)) = 0 then
        begin
          ProcsStatement();
          OutputProcess(ProcessStr);
        end;
        EndColumn := EmptyColumn;

        if EmptyRow > MaxRow then
        begin
          // циклом добавить линии во всех колонках кроме этой
          for i in ColumnSet do
          begin
            for j := MaxRow to EmptyRow - 1 do
              AddBlockList(BlockListLast, BlcVertLine, j, i, '', '');
          end;
          for j := MaxRow to EmptyRow - 1 do
            AddBlockList(BlockListLast, BlcVertLine, j, StartColumn, '', '');
          MaxRow := EmptyRow;
        end
        else
        begin
          // добавить линии в этой колонкке
          for i := EmptyRow to MaxRow - 1 do
            AddBlockList(BlockListLast, BlcVertLine, i, EmptyColumn, '', '');
        end;

      end
      else
      begin
        EmptyRow := StartRow;
        EmptyColumn := FindMaxColumn(SolutionPt) + 1;

        PtPos := Pos(':', Statement.Str); // должно быть > 0
        if PtPos <= 0 then
        begin
          raise Exception.Create('Некорректый файл(case)(594)');
        end;
        CaptionStr := Trim(Copy(Statement.Str, 1, PtPos - 1));
        Delete(Statement.Str, 1, PtPos);
        Statement.Str := Trim(Statement.Str);
        SolutionPt := AddBlockList(BlockListLast, BlcLRDLine, EmptyRow,
          EmptyColumn, CaptionStr, '');
        inc(EmptyRow);
        ProcsStatement();
        OutputProcess(ProcessStr);

        if EmptyRow > MaxRow then
        begin
          // циклом добавить линии во всех колонках кроме этой
          for i in ColumnSet do
          begin
            for j := MaxRow to EmptyRow - 1 do
              AddBlockList(BlockListLast, BlcVertLine, j, i, '', '');
          end;
          for j := MaxRow to EmptyRow - 1 do
            AddBlockList(BlockListLast, BlcVertLine, j, StartColumn, '', '');
          MaxRow := EmptyRow;
          Include(ColumnSet, EmptyColumn);
        end
        else
        begin
          // добавить линии в этой колонкке
          for i := EmptyRow to MaxRow - 1 do
            AddBlockList(BlockListLast, BlcVertLine, i, EmptyColumn, '', '');
          Include(ColumnSet, EmptyColumn);
        end;

      end;
    end;
    Statement := NextStatement(CodeFile);

    if not IsElseFound then
    begin
      EmptyRow := StartRow;
      EmptyColumn := FindMaxColumn(SolutionPt) + 1;
      AddBlockList(BlockListLast, BlcLDLine, EmptyRow, EmptyColumn, 'Else', '');
      inc(EmptyRow);
      EndColumn := EmptyColumn;

      // добавить линии в этой колонкке
      for i := EmptyRow to MaxRow - 1 do
        AddBlockList(BlockListLast, BlcVertLine, i, EmptyColumn, '', '');
    end;

    AddBlockList(BlockListLast, BlcLULine, MaxRow, EndColumn, '', '');
    AddBlockList(BlockListLast, BlcURDArrowLine, MaxRow, StartColumn, '', '');
    for i := StartColumn + 1 to EndColumn - 1 do
    begin
      if i in ColumnSet then
      begin
        AddBlockList(BlockListLast, BlcLURLine, MaxRow, i, '', '');
      end
      else
      begin
        AddBlockList(BlockListLast, BlcHorizLine, MaxRow, i, '', '');
        AddBlockList(BlockListLast, BlcHorizLine, StartRow, i, '', '');
      end;
    end;

    EmptyRow := MaxRow + 1;
    EmptyColumn := StartColumn;

  end
  else
  begin
    raise Exception.Create('Некорректый файл(case)(663)');
    // ОШИБКА
  end;
end;

procedure ProcsCompStatement();
// ГЛОБАЛЬНАЯ ПЕРЕМЕННААЯ Statement
begin
  while TknPos('end', LowerCase(Statement.Str)) = 0 do
  begin
    ProcsStatement();
  end;
  OutputProcess(ProcessStr);
end;

procedure ProcsStatement();
// ГЛОБАЛЬНАЯ ПЕРЕМЕННАЯ Statement  и множество UnBannedSymb
// и константа MaxSymbInBlock

const
  DataProc: array [1 .. 4] of string = ('writeln', 'readln', 'write', 'read');

var
  PtPos, i, TempLength: integer;
  IsFound: boolean;
  TempLowStr: string;

begin
  SeparateFunc(Statement.Str);
  case Statement.LastToken of
    TknBegin:
      begin
        OutputProcess(ProcessStr);
        Statement := NextStatement(CodeFile);
        ProcsCompStatement();
        Statement := NextStatement(CodeFile);
      end;
    TknDo:
      begin
        OutputProcess(ProcessStr);
        ProcsPreCycle();
      end;
    TknRepeat:
      begin
        OutputProcess(ProcessStr);
        ProcsPostCycle();
      end;
    TknThen:
      begin
        OutputProcess(ProcessStr);
        ProcsIf();
      end;
    TknOf:
      begin
        OutputProcess(ProcessStr);
        ProcsCase();
      end;
    TknUnknown:
      begin
        TempLowStr := LowerCase(Statement.Str);
        IsFound := false;
        TempLength := length(Statement.Str);
        i := Low(DataProc);
        while (not IsFound) and (i <= High(DataProc)) do
        begin
          PtPos := TknPos(DataProc[i], TempLowStr);
          if PtPos > 0 then
          begin
            IsFound := true;
            OutputProcess(ProcessStr);
            AddBlockList(BlockListLast, BlcData, EmptyRow, EmptyColumn,
              Statement.Str, '');
            inc(EmptyRow);
            Statement := NextStatement(CodeFile);
          end;
          inc(i);
        end;
        if not IsFound then
        begin
          if IsInStrList(PtPos { мусор } , i { мусор } , ProcListHead,
            TempLowStr) then
          begin
            OutputProcess(ProcessStr);
            AddBlockList(BlockListLast, BlcPredProcess, EmptyRow, EmptyColumn,
              Statement.Str, '');
            inc(EmptyRow);
            Statement := NextStatement(CodeFile);
          end
          else
          begin
            if TempLength + length(ProcessStr) + 1 < MaxSymbInBLock then
            begin
              if length(ProcessStr) = 0 then
                ProcessStr := Statement.Str
              else
                ProcessStr := ProcessStr + '; ' + Statement.Str;
              Statement := NextStatement(CodeFile);
            end
            else
            begin
              if Length(ProcessStr) = 0 then
                ProcessStr := Statement.Str;
              OutputProcess(ProcessStr);
              ProcessStr := Statement.Str;
              Statement := NextStatement(CodeFile);

            end;
          end;
        end;
      end
  else
    // ОШИБКА
    raise Exception.Create('Некорректый файл(772)');
  end;
  FuncNumb := 0;
end;

procedure MakeSubprogram(const SubpogramName: string);
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ Statement BlockListLast EmptyRow FreeCycleName
var
  PtPos, TempPtPos, TempLength: integer;
  TempLowStr, SubSubprogramName: string;

begin
  while Statement.LastToken <> TknBegin do
  begin
    TempLowStr := LowerCase(Statement.Str);
    PtPos := Pos('procedure', TempLowStr);
    if PtPos > 0 then
    begin
      TempLength := length(TempLowStr);
      PtPos := PtPos + length('procedure');
      while TempLowStr[PtPos] = ' ' do
        inc(PtPos);
      if TempLowStr[PtPos] <> '(' then
      begin
        TempPtPos := PtPos;
        while (TempPtPos <= TempLength) and (TempLowStr[TempPtPos] <> '(') and
          (TempLowStr[TempPtPos] <> ' ') do
        begin
          inc(TempPtPos);
        end;
        AddStrList(ProcListLast, Copy(TempLowStr, PtPos, TempPtPos - PtPos));
        SubSubprogramName := Copy(Statement.Str, PtPos, TempPtPos - PtPos);
        Statement := NextStatement(CodeFile);
        MakeSubprogram(SubSubprogramName);
      end
      else
        Statement := NextStatement(CodeFile);
    end
    else
    begin
      PtPos := Pos('function', TempLowStr);
      if PtPos > 0 then
      begin
        TempLength := length(TempLowStr);
        PtPos := PtPos + length('function');
        while TempLowStr[PtPos] = ' ' do
          inc(PtPos);
        if TempLowStr[PtPos] <> '(' then
        begin
          TempPtPos := PtPos;
          while (TempPtPos <= TempLength) and (TempLowStr[TempPtPos] <> '(') and
            (TempLowStr[TempPtPos] <> ' ') and (TempLowStr[TempPtPos] <> ':') do
          begin
            inc(TempPtPos);
          end;
          AddStrList(FuncListLast, Copy(TempLowStr, PtPos, TempPtPos - PtPos));
          SubSubprogramName := Copy(Statement.Str, PtPos, TempPtPos - PtPos);
          Statement := NextStatement(CodeFile);
          MakeSubprogram(SubSubprogramName);
        end
        else
          Statement := NextStatement(CodeFile);
      end
      else
        Statement := NextStatement(CodeFile);
    end;
  end;
  AddBlockList(BlockListLast, BlcTerminatorBgn, EmptyRow, EmptyColumn,
    SubpogramName, '');
  inc(EmptyRow);
  FreeCycleName := 'A';
  Statement := NextStatement(CodeFile);
  ProcsCompStatement();
  AddBlockList(BlockListLast, BlcTerminatorEnd, EmptyRow, EmptyColumn,
    SubpogramName, '');
  inc(EmptyRow);
end;

procedure CorrectTable(const MaxColumnSize, MaxRow: integer;
  const BlockListHead: PBlockList; var BlockListLast: PBlockList;
  out MaxColumn: integer);

var
  MaxColumnArr: array of integer;
  FirstConnectPt: PBlockList;
  i, OldRow, OldColumn: integer;
  BlockListPt: PBlockList;
  IsRightBlock: boolean;
  FreeConnectName: char;
  FreeConnectStr: string;

begin
  MaxColumn := 0;

  SetLength(MaxColumnArr, MaxRow div (MaxColumnSize - 2) + 2);
  FreeConnectName := 'A';
  for i := Low(MaxColumnArr) to High(MaxColumnArr) do
  begin
    MaxColumnArr[i] := 0;
  end;

  BlockListPt := BlockListHead;
  FirstConnectPt := BlockListLast;
  while not ReadAndChangeBlockList(BlockListPt, FirstConnectPt) do
  begin
    if BlockListPt.Data.Column + 1 > MaxColumnArr
      [BlockListPt.Data.Row div (MaxColumnSize - 2) + 1] then
    begin
      MaxColumnArr[BlockListPt.Data.Row div (MaxColumnSize - 2) + 1] :=
        BlockListPt.Data.Column + 1;
    end;
  end;

  for i := 1 to MaxRow div (MaxColumnSize - 2) + 1 do
  begin
    MaxColumnArr[i] := MaxColumnArr[i] + MaxColumnArr[i - 1];
  end;

  BlockListPt := BlockListHead;
  while not ReadAndChangeBlockList(BlockListPt, FirstConnectPt) do
  begin
    OldRow := BlockListPt.Data.Row;
    OldColumn := BlockListPt.Data.Column;
    BlockListPt.Data.Row := OldRow mod (MaxColumnSize - 2) + 1;
    BlockListPt.Data.Column := MaxColumnArr[OldRow div (MaxColumnSize - 2)] +
      OldColumn;

    if BlockListPt.Data.Column + 1 > MaxColumn then
    begin
      MaxColumn := BlockListPt.Data.Column + 1;
    end;

    IsRightBlock := not((BlockListPt.Data.BlockType = BlcTerminatorEnd) or
      (BlockListPt.Data.BlockType = BlcHorizLine) or
      (BlockListPt.Data.BlockType = BlcLULine) or
      (BlockListPt.Data.BlockType = BlcLURLine));
    if IsRightBlock and (OldRow mod (MaxColumnSize - 2) = MaxColumnSize - 3)
    then
    begin

      if FreeConnectName > 'Z' then
        FreeConnectStr := 'N' + IntToStr(Ord(FreeConnectName) - Ord('Z'))
      else
        FreeConnectStr := FreeConnectName;

      AddBlockList(BlockListLast, BlcBottomConnect, MaxColumnSize - 1,
        BlockListPt.Data.Column, FreeConnectStr, '');
      AddBlockList(BlockListLast, BlcUpConnect, 0,
        MaxColumnArr[(OldRow + 1) div (MaxColumnSize - 2)] + OldColumn,
        FreeConnectStr, '');

      FreeConnectName := succ(FreeConnectName);
    end;
  end;

  MaxColumnArr := nil;
end;

procedure MakeBlockList(const MaxColumnSize: integer; out MaxColumn: integer;
  const OpenFileName: string);

begin

  AssignFile(CodeFile, OpenFileName);
  reset(CodeFile);

  EmptyRow := 0;
  EmptyColumn := 0;
  Statement.Str := '';
  WasteCodeString := '';
  WasteStatementStr := '';
  ProcessStr := '';
  CrtStrList(FuncListHead, FuncListLast);
  CrtStrList(ProcListHead, ProcListLast);
  CrtBlockList(BlockListHead, BlockListLast);
  try
    try
      Statement := NextStatement(CodeFile);
      MakeSubprogram('');
      CorrectTable(MaxColumnSize, EmptyRow, BlockListHead, BlockListLast,
        MaxColumn);
    except
      DelBlockList(BlockListHead);
      Raise;
    end;
  finally
    DelStrList(FuncListHead);
    DelStrList(ProcListHead);
    CloseFile(CodeFile);
  end;

end;

end.
