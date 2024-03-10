unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.WebBrowser, System.IOUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet, FMX.Layouts,
  FireDAC.Comp.UI, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
{$IFDEF MSWINDOWS}
  // https://stackoverflow.com/questions/30780843/delphi-twebbrowser-wont-run-javascript-from-localhost
  TBrowserEmulationAdjuster = class
  private
    class function GetExeName(): String; inline;
  public const
    // Quelle: https://msdn.microsoft.com/library/ee330730.aspx, Stand: 2017-04-26
    IE11_default = 11000;
    IE11_Quirks = 11001;
    IE10_force = 10001;
    IE10_default = 10000;
    IE9_Quirks = 9999;
    IE9_default = 9000;
    /// <summary>
    /// Webpages containing standards-based !DOCTYPE directives are displayed in IE7
    /// Standards mode. Default value for applications hosting the WebBrowser Control.
    /// </summary>
    IE7_embedded = 7000;
  public
    class procedure SetBrowserEmulationDWORD(const value: DWORD);
  end;
{$ENDIF}

  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    ShadowEffect4: TShadowEffect;
    WebBrowser1: TWebBrowser;
    Button1: TButton;
    F: TFDConnection;
    FDTable1: TFDTable;
    FDQuery1: TFDQuery;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure WebBrowser1DidStartLoad(ASender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FBeforeConnect(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
{$IFDEF MSWINDOWS}

uses

  Windows, Registry;
{$ENDIF}
// https://stackoverflow.com/questions/30780843/delphi-twebbrowser-wont-run-javascript-from-localhost
{$IFDEF MSWINDOWS}

class function TBrowserEmulationAdjuster.GetExeName(): String;
begin
  Result := TPath.GetFileName(ParamStr(0));
end;

class procedure TBrowserEmulationAdjuster.SetBrowserEmulationDWORD
  (const value: DWORD);
const
  registryPath =
    'Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION';
var
  Registry: TRegistry;
  exeName: String;
begin
  exeName := GetExeName();

  Registry := TRegistry.Create(KEY_SET_VALUE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    Win32Check(Registry.OpenKey(registryPath, True));
    Registry.WriteInteger(exeName, value)
  finally
    Registry.Destroy();
  end;
end;
{$ENDIF}

procedure TForm1.Button1Click(Sender: TObject);
var
  str1, ReplacedStr, ReplacedStr1: string;
  html, bodydiv, outerdiv, css4, css5, css7, css8, css9, titlecss, authorcss,
    contentcss: string;
  content, title, author, dynasty: string;
  i: integer;
begin
  html := '<html><head><meta http-equiv="X-UA-Compatible" content="IE=edge" />'
  +'<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/>'
  +'<style type="text/css">';
  bodydiv := 'body {margin: 0;padding: 0;height: 100%; overflow-x: hidden;display: flex;}';
   outerdiv :=
    '.outer-div {overflow-x: hidden;width:100%;'
   // +'margin-top:10%;'
    +'display: flex;flex-direction: column;height: 100%;'
    + 'align-items: center;' +
    'justify-content: space-between; /* 子元素在主轴上平均分布 */ ' +
    //'padding: 2px; /* 可选：为容器添加一些内边距 */  ' +
    'scrollbar-width: none; /* 隐藏滚动条 */     ' +
    '-ms-overflow-style: none; /* Internet Explorer 和 Edge 的滚动条隐藏 */}' +
    '.outer-div::-webkit-scrollbar {display:none;width: 0;}' +
    '.outer-div > div { '
    //+'margin: 2px;'
    +'flex-shrink: 0; /* 防止子元素在容器空间不足时缩小 */}'
    +'.nonediv{display:flex;height: 100px;}' ;
  titlecss :=
    '.titlecss{text-align: center;white-space: pre-line;overflow-wrap: break-word;display: flex;justify-content: center;'
    + 'width: 80%;color: rgb(116, 0, 0);font-size: 20px;' +
    'font-weight: bold;font-family: 楷体;}';//margin-top: 2px;margin-bottom: 2px;}';

  authorcss :=
    '.author{text-align: center;white-space: pre-line;overflow-wrap: break-word;display: flex;justify-content: center;'
    + 'width: 50%;color: rgb(116, 0, 0);font-size: 18px;' +
    'font-family: 楷体;}';//margin-top: 2px;margin-bottom: 2px;}';
   //4言诗每行12个字符
 // css4 := '.content {width: 10em;max-width: 100%;flex: 1;text-align:center;margin-top: 5px;margin-bottom: 5px;'
   // + 'color: rgb(116, 0, 0);font-size: 22px;font-family: 楷体;}';
   css4 := '.content {width: 10em;max-width: 100%;flex: 1;text-align:center;'
    + 'color: rgb(116, 0, 0);font-size: 22px;font-family: 楷体;}';
  // 五言诗每行12个字符
 // css5 := '.content {width: 12em;max-width: 100%;flex: 1;text-align:center;margin-top: 5px;margin-bottom: 5px;'
  //  + 'color: rgb(116, 0, 0);font-size: 22px;font-family: 楷体;}';
  css5 := '.content {width: 12em;max-width: 100%;flex: 1;text-align:center;'
    + 'color: rgb(116, 0, 0);font-size: 22px;font-family: 楷体;}';
  // +'display: flex;justify-content: center;}';
  // 7言诗每行16个字符
  //css7 := '.content {width: 16em;max-width: 100%;flex: 1;text-align:center;margin-top: 5px;margin-bottom: 5px;'
   // + 'color: rgb(116, 0, 0);font-size: 18px;font-family: 楷体;' + '}';
  css7 := '.content {width: 16em;max-width: 100%;flex: 1;text-align:center;'
    + 'color: rgb(116, 0, 0);font-size: 18px;font-family: 楷体;' + '}';
  // 其他
  //css8 := '.content {width: 80%;max-width: 100%;flex: 1;text-align: left;margin-top: 5px;margin-bottom: 5px;'
   // + 'text-indent: 2em;color: rgb(116, 0, 0);font-size: 16px;font-family: 楷体;'
   // + '}';
   css8 := '.content {width: 80%;max-width: 100%;flex: 1;text-align: left;'
    + 'text-indent: 2em;color: rgb(116, 0, 0);font-size: 16px;font-family: 楷体;'
    + '}';
  FDQuery1.Close;
  FDQuery1.SQL.Clear;
  FDQuery1.SQL.Add('select * from gushiwen where id=''' +
    inttostr(Random(108326) + 1) + '''');
  FDQuery1.Open;

  title := '<div class="titlecss">' + FDQuery1.FieldByName('title')
    .AsString.Trim + ' </div>';
  dynasty := FDQuery1.FieldByName('dynasty').AsString.Trim;
  author := FDQuery1.FieldByName('author').AsString.Trim;

  str1 := FDQuery1.FieldByName('content').AsString;
  author := ' <div class="author"><p>' + '[' + dynasty + '] ' + author +
    '</p> </div>';
  ReplacedStr := StringReplace(str1, '<br/>', '</p><p>',
    [rfReplaceAll, rfIgnoreCase]);

  ReplacedStr := '<div class="content"><p>' + ReplacedStr + '</p></div>';

  content := StringReplace(str1, '<br/>', '',
    [rfReplaceAll, rfIgnoreCase]).Trim;

  if ((length(content.Trim) mod 10) = 0) and
    ((copy(content, 10, 1) = '。') or (copy(content, 10, 1) = '？')) then
  begin
    WebBrowser1.LoadFromStrings(html + bodydiv + outerdiv + css4 + titlecss +
      authorcss + '</style></head><body scroll="no"><div class="outer-div"><div class="nonediv"></div>' +
      title + author + ReplacedStr + '</div></body></html>', 'about:blank');

  end
  else if ((length(content.Trim) mod 12) = 0) and
    ((copy(content, 12, 1) = '。') or (copy(content, 12, 1) = '？')) then
  begin
    WebBrowser1.LoadFromStrings(html + bodydiv + outerdiv + css5 + titlecss +
      authorcss + '</style></head><body scroll="no"><div class="outer-div"><div class="nonediv"></div>' +
      title + author + ReplacedStr + '</div></body></html>', 'about:blank');

  end

  else if ((length(content.Trim) mod 16) = 0) and
    ((copy(content, 16, 1) = '。') or (copy(content, 16, 1) = '？')) then
  begin
    WebBrowser1.LoadFromStrings(html + bodydiv + outerdiv + css7 + titlecss +
      authorcss + '</style></head><body scroll="no"><div class="outer-div"><div class="nonediv"></div>' +
      title + author + ReplacedStr + '</div></body></html>', 'about:blank');
  end
  else

    WebBrowser1.LoadFromStrings(html + bodydiv + outerdiv + css8 + titlecss +
      authorcss + '</style></head><body scroll="no"><div class="outer-div"><div class="nonediv"></div>' +
      title + author + ReplacedStr + '</div></body></html>', 'about:blank');

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  WebBrowser1.LoadFromStrings
    ('<html><head><meta http-equiv="X-UA-Compatible" content="text/html:charset=gb2312" /></head><body></body></html>',
    'about:blank');
  WebBrowser1.EvaluateJavaScript('alert("me");');
end;

procedure TForm1.FBeforeConnect(Sender: TObject);
begin
{$IF DEFINED(iOS) Or DEFINED(ANDROID)}
  F.Params.Values['Database']:= TPath.Combine(TPath.GetDocumentsPath,
    'sctest.s3db');
{$ENDIF }
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  TBrowserEmulationAdjuster.SetBrowserEmulationDWORD
    (TBrowserEmulationAdjuster.IE11_Quirks);
{$ENDIF}
end;

procedure TForm1.WebBrowser1DidStartLoad(ASender: TObject);
begin
  if WebBrowser1.URL.IndexOf('#') > -1 then
  begin
    Label1.Text := WebBrowser1.URL.Split(['#'])[1];
  end;
end;

end.
