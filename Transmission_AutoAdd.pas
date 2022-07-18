uses Inifile, crt, System.Net, System.IO, System, Transmission.API.RPC, Transmission.API.RPC.Entity;

var
  webclient := new WebClient;

var
  cred := new NetworkCredential;

var
  key: string;
  
  var config := new Inifile.TIniFile('config.conf');

begin
  crt.SetWindowCaption('Transmission auto-add');
  crt.SetWindowSize(50,15);
  crt.SetBufferSize(50, 15);
  while true do
  begin
    TextColor(LightCyan);
    cred.Password := config.ReadString('Credentials', 'pass', '');
    cred.UserName := config.ReadString('Credentials', 'login', '');
    try
      webclient.Credentials := cred;
      webclient.DownloadString('http://' + config.ReadString('IP', 'IP', '') + '/transmission/rpc');
      Writeln('Connected to ' + config.ReadString('IP', 'IP', ''));
    except
      on ex: WebException do
      begin
        if ex.Response is WebResponse then
          begin
        for var i := 0 to ex.Response.Headers.GetValues('X-Transmission-Session-Id').Length - 1 DO
          key := key + ex.Response.Headers.GetValues('X-Transmission-Session-Id')[i];
      end
      else
      begin
        TextColor(LightRed);
        Writeln('IP or port is not valid!');
        Sleep(5000);
        break;
      end;
      end;
    end;
    var df := new DirectoryInfo(Environment.GetEnvironmentVariable('userprofile') + '\Downloads');
    if Directory.GetFiles(Environment.GetEnvironmentVariable('userprofile') + '\Downloads', '*.torrent').Length > 0 then
      foreach var ii in df.GetFiles('*.torrent') do
      begin
        var client := new Transmission.API.RPC.Client('http://' + config.ReadString('IP', 'IP', '') + '/transmission/rpc', key, config.ReadString('Credentials', 'login', ''), config.ReadString('Credentials', 'pass', ''));
        var torrent := new NewTorrent;
        torrent.Metainfo := Convert.ToBase64String(Encoding.Default.GetBytes
        (ReadAllText(Environment.GetEnvironmentVariable('userprofile') + '/Downloads/' + ii.Name)));
        try
          var addtor := client.TorrentAdd(torrent);
          TextColor(LightGreen);
          Writeln('Torrent with name "' + addtor.Name + '" was added!');
        except 
          on trans_ex: Exception do
          begin
            crt.TextColor(LightRed);
            case trans_ex.Message of 
              'duplicate torrent': Writeln('Torrent with name "' + ii.Name + '" already  in Transmission');
              'invalid or corrupt torrent file': Writeln('Torrent with name "' + ii.Name + '" corrupt or invalid!');
            end;
          end;
        end;     
        TextColor(LightGreen);
        if DeleteFile(Environment.GetEnvironmentVariable('userprofile') + '/Downloads/' + ii.Name) then
          Writeln('Local torrent deleted succesfuly!')
        else
        begin
          TextColor(LightRed);
          Writeln('Local torrent was not deleted!');
        end;
      end
    else
        Writeln('Nothing to do...');
    Sleep(5000);
    ClrScr;
  end
end.