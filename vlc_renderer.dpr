program vlc_renderer;

uses
  Forms,
  mainunit in 'mainunit.pas' {OptionsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TOptionsForm, OptionsForm);
  Application.Run;
end.
