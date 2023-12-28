unit DrawSVG;

interface

procedure DrawFlowchart(const MaxRow, MaxColumn: integer;
  const TempFileName: string);

implementation

uses
  lists, SysUtils, System.IOUtils;

const
  BlockWidth = 100;
  BlockHeight = 60;
  StrokeWidth = 2;
  StrokeClr = 'black';
  BlockFillClr = 'white';
  FontSize = 9;
  LineWidth = 1;

var
  SvgFile: TextFile;
  BlockElem: TBlockElem;

procedure SplitString(const middleX, middleY: integer; const source: string;
  MaxSymb: integer);

const
  SeparateCharArr: array [1 .. 4] of string = ('; ', ' ', '(', ')');
  NoSeparateArr: array [1..3] of string = ('&amp;', '&lt;', '&gt;');

var
  EnterPosArr: array [1 .. 7] of integer;
  PosArrLength, PtPos, ChkPos, i, j, k, Y: integer;
  IsFound: boolean;
  LoclFontSize: integer;
  HighEnterPosArr: integer;

begin
  HighEnterPosArr := 5;
  LoclFontSize := FontSize;
  if Length(source) > MaxSymb * 4 then
  begin
    MaxSymb := Trunc(MaxSymb * 1.22);
    LoclFontSize := FontSize - 2;
    HighEnterPosArr := 6;
    if Length(source) > MaxSymb * 5 then
    begin
      MaxSymb := Trunc(MaxSymb * 1.4);
      LoclFontSize := FontSize - 3;
      HighEnterPosArr := 7;
    end;

  end;

  ChkPos := 1;
  EnterPosArr[Low(EnterPosArr)] := 0;
  for i := Low(EnterPosArr) + 1 to HighEnterPosArr do
  begin
    EnterPosArr[i] := Length(source);
  end;

  j := Low(EnterPosArr) + 1;
  PosArrLength := 1;
  while (j < HighEnterPosArr) and
    (EnterPosArr[j - 1] + MaxSymb < Length(source)) do
  begin
    inc(PosArrLength);
    IsFound := False;
    i := Low(SeparateCharArr);
    while (not IsFound) and (i <= High(SeparateCharArr)) do
    begin
      PtPos := Pos(SeparateCharArr[i], source, ChkPos);
      while (PtPos > 0) and (PtPos < MaxSymb + EnterPosArr[j - 1]) do
      begin
        IsFound := True;
        ChkPos := PtPos + 1;
        if SeparateCharArr[i] = '(' then
        begin
          Dec(PtPos);
        end;
        EnterPosArr[j] := PtPos;
        PtPos := Pos(SeparateCharArr[i], source, ChkPos);
      end;

      inc(i);
    end;
    if not IsFound then
    begin
      EnterPosArr[j] := MaxSymb + EnterPosArr[j - 1];

      //устраняем проблему с переносом половины > < &
      for k := Low(NoSeparateArr) to High(NoSeparateArr) do
      begin
        PtPos := Pos(NoSeparateArr[k], source, EnterPosArr[j] - Length(NoSeparateArr[k]));
        if  PtPos > 0 then
        begin
          if (EnterPosArr[j] - PtPos >= 0) and
            (EnterPosArr[j] - PtPos < Length(NoSeparateArr[k])) then
          begin
            EnterPosArr[j] := PtPos + Length(NoSeparateArr[k]) - 1;
          end;
        end;
      end;

    end;
    inc(j);
  end;

  if EnterPosArr[HighEnterPosArr] - EnterPosArr[HighEnterPosArr - 1] > MaxSymb
  then
  begin
    for i := Low(EnterPosArr) + 1 to HighEnterPosArr - 1 do
    begin
      EnterPosArr[i] := MaxSymb * (i - 1);

      //устраняем проблему с переносом половины > < &
      for j := Low(NoSeparateArr) to High(NoSeparateArr) do
      begin
        PtPos := Pos(NoSeparateArr[j], source, EnterPosArr[i] - Length(NoSeparateArr[j]));
        if  PtPos > 0 then
        begin
          if (EnterPosArr[i] - PtPos >= 0) and
            (EnterPosArr[i] - PtPos < Length(NoSeparateArr[j])) then
          begin
            EnterPosArr[i] := PtPos + Length(NoSeparateArr[j]) - 1;
          end;
        end;
      end;


    end;
  end;

  Y := middleY - ((PosArrLength - 1) * ((LoclFontSize + 1) div 2)) - (LoclFontSize + 1);

  writeln(SvgFile, '  <text x="', middleX, '" y="', Y,
    '" dominant-baseline="middle" text-anchor="middle" font-size="',
    LoclFontSize, '" font-family="Arial">');
  for i := 1 to PosArrLength do
  begin
    writeln(SvgFile, '    <tspan  x="', middleX, '" dy="', LoclFontSize + 1, '"> ',
      Trim(Copy(source, EnterPosArr[i] + 1, EnterPosArr[i + 1] - EnterPosArr[i])
      ), ' </tspan>');
  end;

  writeln(SvgFile, '  </text>');

end;

procedure DrawTerminatorBgn(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '  <path d="M', 30 + BlockX, ' ', 50 + BlockY,
    ' A 20 20 0 0 1 ', 30 + BlockX, ' ', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" fill="', BlockFillClr, '" />');
  writeln(SvgFile, '  <path d="M', 70 + BlockX, ' ', 50 + BlockY,
    ' A 20 20 0 0 0 ', 70 + BlockX, ' ', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" fill="', BlockFillClr, '" />');
  writeln(SvgFile, '  <rect x="', 30 + BlockX, '" y="', 10 + BlockY,
    '" width="40" height="40" fill="', BlockFillClr, '" stroke="', StrokeClr,
    '" stroke-width="0" />');
  writeln(SvgFile, '  <line x1="', 29 + BlockX, '" y1="', 10 + BlockY, '" x2="',
    71 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 29 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    71 + BlockX, '" y2="', 50 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <text x="', 50 + BlockX, '" y="', 15 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial">  Начало  </text>');

  SplitString(50 + BlockX, BlockY + 35, BlockElem.Caption, 20);

end;

procedure DrawTerminatorEnd(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '  <path d="M', 30 + BlockX, ' ', 50 + BlockY,
    ' A 20 20 0 0 1 ', 30 + BlockX, ' ', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" fill="', BlockFillClr, '" />');
  writeln(SvgFile, '  <path d="M', 70 + BlockX, ' ', 50 + BlockY,
    ' A 20 20 0 0 0 ', 70 + BlockX, ' ', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" fill="', BlockFillClr, '" />');
  writeln(SvgFile, '  <rect x="', 30 + BlockX, '" y="', 10 + BlockY,
    '" width="40" height="40" fill="', BlockFillClr, '" stroke="', StrokeClr,
    '" stroke-width="0" />');
  writeln(SvgFile, '  <line x1="', 29 + BlockX, '" y1="', 10 + BlockY, '" x2="',
    71 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 29 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    71 + BlockX, '" y2="', 50 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <text x="', 50 + BlockX, '" y="', 15 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial">  Конец  </text>');

  SplitString(50 + BlockX, BlockY + 35, BlockElem.Caption, 20);

end;

procedure DrawProcess(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '  <rect x="', 10 + BlockX, '" y="', 10 + BlockY,
    '" width="80" height="40" fill="', BlockFillClr, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  SplitString(50 + BlockX, BlockY + 30, BlockElem.Caption, 20);
end;

procedure DrawPredProcess(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '  <rect x="', 10 + BlockX, '" y="', 10 + BlockY,
    '" width="80" height="40" fill="', BlockFillClr, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 20 + BlockX, '" y1="', 10 + BlockY, '" x2="',
    20 + BlockX, '" y2="', 50 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');
  writeln(SvgFile, '  <line x1="', 80 + BlockX, '" y1="', 10 + BlockY, '" x2="',
    80 + BlockX, '" y2="', 50 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', StrokeWidth, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  SplitString(50 + BlockX, BlockY + 30, BlockElem.Caption, 16);
end;

procedure DrawData(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '<path d="M ', 20 + BlockX, ' ', 10 + BlockY, ' L ',
    90 + BlockX, ' ', 10 + BlockY, ' L ', 80 + BlockX, ' ', 50 + BlockY, ' L ',
    10 + BlockX, ' ', 50 + BlockY, ' L ', 20 + BlockX, ' ', 10 + BlockY, ' L ',
    21 + BlockX, ' ', 10 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
    StrokeWidth, '" fill="', BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  SplitString(50 + BlockX, BlockY + 30, BlockElem.Caption, 18);
end;

procedure DrawUpCycleBound(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '<path d="M ', 10 + BlockX, ' ', 50 + BlockY, ' L ',
    90 + BlockX, ' ', 50 + BlockY, ' L ', 90 + BlockX, ' ', 25 + BlockY, ' L ',
    75 + BlockX, ' ', 10 + BlockY, ' L ', 25 + BlockX, ' ', 10 + BlockY, ' L ',
    10 + BlockX, ' ', 25 + BlockY, ' L ', 10 + BlockX, ' ', 50 + BlockY, ' L ',
    11 + BlockX, ' ', 50 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
    StrokeWidth, '" fill="', BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <text x="', 50 + BlockX, '" y="', 15 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial"> ', BlockElem.SubCaption, ' </text>');
  SplitString(50 + BlockX, BlockY + 35, BlockElem.Caption, 20);
end;

procedure DrawBottomCycleBound(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '<path d="M ', 10 + BlockX, ' ', 35 + BlockY, ' L ',
    25 + BlockX, ' ', 50 + BlockY, ' L ', 75 + BlockX, ' ', 50 + BlockY, ' L ',
    90 + BlockX, ' ', 35 + BlockY, ' L ', 90 + BlockX, ' ', 10 + BlockY, ' L ',
    10 + BlockX, ' ', 10 + BlockY, ' L ', 10 + BlockX, ' ', 35 + BlockY, ' L ',
    11 + BlockX, ' ', 36 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
    StrokeWidth, '" fill="', BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <text x="', 50 + BlockX, '" y="', 45 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial"> ', BlockElem.SubCaption, ' </text>');
  SplitString(50 + BlockX, BlockY + 25, BlockElem.Caption, 20);
end;

procedure DrawIfSolution(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '<path d="M ', 50 + BlockX, ' ', 10 + BlockY, ' L ',
    10 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 50 + BlockY, ' L ',
    90 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 10 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', StrokeWidth, '" fill="',
    BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 90 + BlockX, '" y1="', 30 + BlockY, '" x2="',
    100 + BlockX, '" y2="', 30 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  writeln(SvgFile, '  <text x="', 40 + BlockX, '" y="', 55 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial"> Да </text>');
  writeln(SvgFile, '  <text x="', 85 + BlockX, '" y="', 20 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial"> Нет </text>');

  SplitString(50 + BlockX, BlockY + 30, BlockElem.Caption, 16);
end;

procedure DrawCaseSolution(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;
  writeln(SvgFile, '<path d="M ', 50 + BlockX, ' ', 10 + BlockY, ' L ',
    10 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 50 + BlockY, ' L ',
    90 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 10 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', StrokeWidth, '" fill="',
    BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
  // writeln(SvgFile, '<path d="M ', 50 + BlockX, ' ', 50 + BlockY, ' L ',
  // 50 + BlockX, ' ', 59 + BlockY, ' L ', 60 + BlockX, ' ', 59 + BlockY, ' L ',
  // 60 + BlockX, ' ', 60 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
  // LineWidth, '" fill="', BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');

  SplitString(50 + BlockX, BlockY + 30, BlockElem.Caption, 16);
end;

procedure DrawHorizLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '  <line x1="', 0 + BlockX, '" y1="', 30 + BlockY, '" x2="',
    100 + BlockX, '" y2="', 30 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
end;

procedure DrawVertLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');
end;

procedure DrawLDLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<path d="M ', 0 + BlockX, ' ', 30 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 60 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', LineWidth, '" fill="none" />');

  SplitString(50 + BlockX, BlockY + 15, BlockElem.Caption, 20);
end;

procedure DrawLULine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<path d="M ', 0 + BlockX, ' ', 30 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 0 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', LineWidth, '" fill="none" />');
end;

procedure DrawURDArrowLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<path d="M ', 100 + BlockX, ' ', 30 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 60 + BlockY, ' L ',
    50 + BlockX, ' ', 0 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
    LineWidth, '" fill="none" />');
  writeln(SvgFile, '<path d="M ', 55 + BlockX, ' ', 35 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 55 + BlockX, ' ', 25 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', LineWidth, '" fill="none" />');
end;

procedure DrawURDLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  // writeln(SvgFile, '<path d="M ', 100 + BlockX, ' ', 30 + BlockY, ' L ',
  // 50 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 60 + BlockY, ' L ',
  // 50 + BlockX, ' ', 0 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
  // LineWidth, '" fill="none" />');

  writeln(SvgFile, '<path d="M ', 100 + BlockX, ' ', 30 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 60 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 53 + BlockX, ' ', 30 + BlockY, ' L ',
    53 + BlockX, ' ', 0 + BlockY, ' L ', 50 + BlockX, ' ', 0 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', LineWidth, '" fill="none" />');

  SplitString(30 + BlockX, BlockY + 40, BlockElem.Caption, 10);

end;

procedure DrawLRDLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<path d="M ', 0 + BlockX, ' ', 30 + BlockY, ' L ',
    100 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 30 + BlockY, ' L ',
    50 + BlockX, ' ', 60 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
    LineWidth, '" fill="none" />');

  SplitString(50 + BlockX, BlockY + 15, BlockElem.Caption, 20);

end;

procedure DrawLURLine(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<path d="M ', 0 + BlockX, ' ', 30 + BlockY, ' L ',
    100 + BlockX, ' ', 30 + BlockY, ' L ', 50 + BlockX, ' ', 30 + BlockY, ' L ',
    50 + BlockX, ' ', 0 + BlockY, '" stroke="', StrokeClr, '" stroke-width="',
    LineWidth, '" fill="none" />');
  writeln(SvgFile, '<path d="M ', 45 + BlockX, ' ', 25 + BlockY, ' L ',
    50 + BlockX, ' ', 30 + BlockY, ' L ', 55 + BlockX, ' ', 25 + BlockY,
    '" stroke="', StrokeClr, '" stroke-width="', LineWidth, '" fill="none" />');

end;

procedure DrawUpConnect(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<circle cx="', 50 + BlockX, '" cy="', 40 + BlockY,
    '" r="10" stroke="', StrokeClr, '" stroke-width="', StrokeWidth, '" fill="',
    BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 50 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 60 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');

  writeln(SvgFile, '  <text x="', 50 + BlockX, '" y="', 40 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial"> ', BlockElem.Caption, ' </text>');
end;

procedure DrawBottomConnect(const BlockElem: TBlockElem);

var
  BlockX, BlockY: integer;

begin
  BlockY := BlockElem.Row * BlockHeight;
  BlockX := BlockElem.Column * BlockWidth;

  writeln(SvgFile, '<circle cx="', 50 + BlockX, '" cy="', 20 + BlockY,
    '" r="10" stroke="', StrokeClr, '" stroke-width="', StrokeWidth, '" fill="',
    BlockFillClr, '" />');

  writeln(SvgFile, '  <line x1="', 50 + BlockX, '" y1="', 0 + BlockY, '" x2="',
    50 + BlockX, '" y2="', 10 + BlockY, '" stroke="', StrokeClr,
    '" stroke-width="', LineWidth, '" />');

  writeln(SvgFile, '  <text x="', 50 + BlockX, '" y="', 20 + BlockY,
    '" dominant-baseline="middle" text-anchor="middle" font-size="', FontSize,
    '" font-family="Arial"> ', BlockElem.Caption, ' </text>');
end;

procedure CorrectSymb(var source: string);

var
  TkPos, ChkPos: integer;

begin
  ChkPos := 1;
  TkPos := Pos('&', source, ChkPos);
  while TkPos > 0 do
  begin
    Delete(source, TkPos, 1);
    Insert('&amp;', source, TkPos);
    ChkPos := TkPos + 1;
    TkPos := Pos('&', source, ChkPos);
  end;
  ChkPos := 1;
  TkPos := Pos('<', source, ChkPos);
  while TkPos > 0 do
  begin
    Delete(source, TkPos, 1);
    Insert('&lt;', source, TkPos);
    ChkPos := TkPos + 1;
    TkPos := Pos('<', source, ChkPos);
  end;
  ChkPos := 1;
  TkPos := Pos('>', source, ChkPos);
  while TkPos > 0 do
  begin
    Delete(source, TkPos, 1);
    Insert('&gt;', source, TkPos);
    ChkPos := TkPos + 1;
    TkPos := Pos('>', source, ChkPos);
  end;

end;

procedure DrawFlowchart(const MaxRow, MaxColumn: integer;
  const TempFileName: string);

var
  FileAttributes: integer;
  content: string;

begin
  AssignFile(SvgFile, TempFileName);
  if FileExists(TempFileName) then
  begin
    FileSetAttr(PChar(TempFileName), FileGetAttr(TempFileName) and
      not faHidden);
  end;

  rewrite(SvgFile);
  try

    writeln(SvgFile, '<?xml version="1.0" encoding="UTF-8"?>');
    writeln(SvgFile, '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
    writeln(SvgFile, '  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
    writeln(SvgFile, '<svg xmlns="http://www.w3.org/2000/svg" width="',
      MaxColumn * BlockWidth, '" height="', MaxRow * BlockHeight, '">');

    while not ReadAndDeleteBlockList(BlockListHead, BlockElem) do
    begin
      CorrectSymb(BlockElem.Caption);
      case BlockElem.BlockType of
        BlcTerminatorBgn:
          DrawTerminatorBgn(BlockElem);
        BlcTerminatorEnd:
          DrawTerminatorEnd(BlockElem);
        BlcProcess:
          DrawProcess(BlockElem);
        BlcPredProcess:
          DrawPredProcess(BlockElem);
        BlcData:
          DrawData(BlockElem);
        BlcUpCycleBound:
          DrawUpCycleBound(BlockElem);
        BlcBottomCycleBound:
          DrawBottomCycleBound(BlockElem);
        BlcIfSolution:
          DrawIfSolution(BlockElem);
        BlcCaseSolution:
          DrawCaseSolution(BlockElem);

        BlcHorizLine:
          DrawHorizLine(BlockElem);
        BlcVertLine:
          DrawVertLine(BlockElem);
        BlcLDLine:
          DrawLDLine(BlockElem);
        BlcLULine:
          DrawLULine(BlockElem);
        BlcURDArrowLine:
          DrawURDArrowLine(BlockElem);
        BlcURDLine:
          DrawURDLine(BlockElem);
        BlcLRDLine:
          DrawLRDLine(BlockElem);
        BlcLURLine:
          DrawLURLine(BlockElem);

        BlcUpConnect:
          DrawUpConnect(BlockElem);
        BlcBottomConnect:
          DrawBottomConnect(BlockElem);

      end;
    end;

    writeln(SvgFile, '</svg> ');
  finally
    CloseFile(SvgFile);

    content := TFile.ReadAllText(TempFileName, TEncoding.ANSI);
    TFile.WriteAllText(TempFileName, content, TEncoding.UTF8);

    FileAttributes := FileGetAttr(TempFileName);
    if FileAttributes <> -1 then
    begin
      FileAttributes := FileAttributes or faHidden;
      FileSetAttr(TempFileName, FileAttributes);
    end;
  end;

end;

end.
