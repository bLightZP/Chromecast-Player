{.$DEFINE VLCLOG} // Log File in the same path as the EXE file, make sure you have write permissions in that folder before enabling.
//
// Released under the MPL 2.0 license.
//
// Code by Yaron Gur with contributions and support from Robert Jedrzejczyk
//

unit mainunit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, StdCtrls, Menus, ComCtrls, SyncObjs,
  PasLibVlcUnit, PasLibVlcClassUnit, PasLibVlcPlayerUnit, tntclasses;

type
  TOptionsForm = class(TForm)
    ScanButton: TButton;
    SetOPVLCCastDeviceList: TListBox;
    StopButton: TButton;
    LabelDevices: TLabel;
    LabelDebugLog: TLabel;
    DebugLB: TListBox;
    Label1: TLabel;
    MediaFile: TEdit;
    PlayButton: TButton;
    PlayerPanel: TPanel;
    OpenDialog: TOpenDialog;
    BrowseButton: TButton;
    procedure ScanButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PlayButtonClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure BrowseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure VLCPlayerMediaPlayerMediaChanged(Sender: TObject; mrl: string);
    procedure VLCPlayerMediaPlayerNothingSpecial(Sender: TObject);
    procedure VLCPlayerMediaPlayerOpening(Sender: TObject);
    procedure VLCPlayerMediaPlayerBuffering(Sender: TObject; val: Single);
    procedure VLCPlayerMediaPlayerPlaying(Sender: TObject);
    procedure VLCPlayerMediaPlayerPaused(Sender: TObject);
    procedure VLCPlayerMediaPlayerStopped(Sender: TObject);
    procedure VLCPlayerMediaPlayerForward(Sender: TObject);
    procedure VLCPlayerMediaPlayerBackward(Sender: TObject);
    procedure VLCPlayerMediaPlayerEndReached(Sender: TObject);
    procedure VLCPlayerMediaPlayerEncounteredError(Sender: TObject);
    procedure VLCPlayerMediaPlayerTimeChanged(Sender: TObject; time: Int64);
    procedure VLCPlayerMediaPlayerPositionChanged(Sender: TObject; position: Single);
    procedure VLCPlayerMediaPlayerSeekableChanged(Sender: TObject; val: Boolean);
    procedure VLCPlayerMediaPlayerPausableChanged(Sender: TObject; val: Boolean);
    procedure VLCPlayerMediaPlayerTitleChanged(Sender: TObject; title: Integer);
    procedure VLCPlayerMediaPlayerSnapshotTaken(Sender: TObject; fileName: string);
    procedure VLCPlayerMediaPlayerLengthChanged(Sender: TObject; time: Int64);
    procedure VLCPlayerMediaPlayerVideoOutChanged(Sender: TObject; video_out: Integer);
    procedure VLCPlayerMediaPlayerScrambledChanged(Sender: TObject; scrambled: Integer);
    procedure VLCPlayerMediaPlayerCorked(Sender: TObject);
    procedure VLCPlayerMediaPlayerUnCorked(Sender: TObject);
    procedure VLCPlayerMediaPlayerMuted(Sender: TObject);
    procedure VLCPlayerMediaPlayerUnMuted(Sender: TObject);
    procedure VLCPlayerMediaPlayerAudioVolumeChanged(Sender: TObject; volume: Single);
    procedure VLCPlayerMediaPlayerEsAdded(Sender: TObject; i_type: libvlc_track_type_t; i_id: Integer);
    procedure VLCPlayerMediaPlayerEsDeleted(Sender: TObject; i_type: libvlc_track_type_t; i_id: Integer);
    procedure VLCPlayerMediaPlayerEsSelected(Sender: TObject; i_type: libvlc_track_type_t; i_id: Integer);
    procedure VLCPlayerMediaPlayerAudioDevice(Sender: TObject; audio_device: String);
    procedure VLCPlayerMediaPlayerChapterChanged(Sender: TObject; chapter: Integer);
    procedure VLCPlayerRendererDiscoveredItemAdded(Sender: TObject; item: libvlc_renderer_item_t_ptr);
    procedure VLCPlayerRendererDiscoveredItemDeleted(Sender: TObject; item: libvlc_renderer_item_t_ptr);

    function  InitVLCInterface : Integer;
    procedure ClearDeviceList;
    procedure AddDebugMsg(S : Widestring);
  end;

var
  OptionsForm               : TOptionsForm;
  vlcDiscoverer             : libvlc_renderer_discoverer_t_ptr = nil;
  vlcDiscovererEventManager : libvlc_event_manager_t_ptr = nil;
  vlcPlayer                 : TPasLibVlcPlayer = nil;


  function  UTF8StringToWideString(Const S : UTF8String) : WideString;


implementation

{$R *.dfm}

procedure TOptionsForm.AddDebugMsg(S : Widestring);
begin
  DebugLB.Items.Add(S);
  DebugLB.TopIndex := DebugLB.Items.Count-(DebugLB.ClientHeight div DebugLB.ItemHeight);
end;


procedure vlc_renderer_event_hdlr(p_event: libvlc_event_t_ptr; data: Pointer); cdecl;
var
  I : Integer;
  S : WideString;
begin
  OptionsForm.AddDebugMsg('Event: Triggered');

  If data = nil then
  Begin
    OptionsForm.AddDebugMsg('Event: Exit on No Data!');
    exit;
  End;

  with p_event^ do
  begin
    case event_type of
      libvlc_RendererDiscovererItemAdded :
      Begin
        // libvlc_renderer_item_name(item) - Should also work
        OptionsForm.AddDebugMsg('Item added "'+UTF8StringToWideString(PAnsiChar(renderer_discoverer_item_added.item^))+'"');

        OptionsForm.SetOPVLCCastDeviceList.Items.AddObject(UTF8StringToWideString(PAnsiChar(renderer_discoverer_item_added.item^)),libvlc_renderer_item_hold(renderer_discoverer_item_added.item));
      End;
      libvlc_RendererDiscovererItemDeleted :
      Begin
        S := UTF8StringToWideString(PAnsiChar(renderer_discoverer_item_deleted.item^));
        For I := 0 to OptionsForm.SetOPVLCCastDeviceList.Items.Count-1 do
          If OptionsForm.SetOPVLCCastDeviceList.Items[I] = S then
        Begin
          OptionsForm.AddDebugMsg('Item removed "'+S+'"');
          OptionsForm.SetOPVLCCastDeviceList.Items.Delete(I);
          Break;
        End;
      End;
    End;
  end;
end;


procedure TOptionsForm.ClearDeviceList;
var
  I : Integer;
begin
  If SetOPVLCCastDeviceList.Count > 0 then
  Begin
    // Free Device Hold
    For I := 0 to SetOPVLCCastDeviceList.Count-1 do libvlc_renderer_item_release(SetOPVLCCastDeviceList.Items.Objects[I]);
    SetOPVLCCastDeviceList.Clear;
  End;
end;


procedure TOptionsForm.ScanButtonClick(Sender: TObject);
begin
  ScanButton.Enabled := False;

  AddDebugMsg('Starting Device Scanner');

  ClearDeviceList;

  If Assigned(VLCPlayer) then
  Begin
    AddDebugMsg('Log set');

    // Create a new media discoverer for renderer discovery
    vlcDiscoverer := libvlc_renderer_discoverer_new(VLCPlayer.VLC.Handle,'microdns_renderer');

    If Assigned(vlcDiscoverer) then
    begin
      AddDebugMsg('Device Discoverer created at '+IntToHex(Integer(vlcDiscoverer),8));

      vlcDiscovererEventManager := libvlc_renderer_discoverer_event_manager(vlcDiscoverer);

      AddDebugMsg('Device list event manager created at '+IntToHex(Integer(vlcDiscovererEventManager),8));

      // Attach event handlers
      libvlc_event_attach(vlcDiscovererEventManager, libvlc_RendererDiscovererItemAdded  , vlc_renderer_event_hdlr, self);
      libvlc_event_attach(vlcDiscovererEventManager, libvlc_RendererDiscovererItemDeleted, vlc_renderer_event_hdlr, self);

      AddDebugMsg('Events attached to Event Manager');

      // Start discovery
      libvlc_renderer_discoverer_start(vlcDiscoverer);

      StopButton.Enabled := True;
      AddDebugMsg('Device Scanner Started');
    end;
  End;
  If StopButton.Enabled = False then ScanButton.Enabled := True;
end;


procedure TOptionsForm.StopButtonClick(Sender: TObject);
begin
  StopButton.Enabled := False;
  AddDebugMsg('Stopping Device Scanner');

  vlcDiscovererEventManager := nil;

  AddDebugMsg('Interfaces released');

  libvlc_renderer_discoverer_release(vlcDiscoverer);
  vlcDiscoverer := nil;

  ScanButton.Enabled := True;

  AddDebugMsg('Device Discovery stopped');
end;


procedure TOptionsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  If StopButton.Enabled = True then
  Begin
    StopButtonClick(nil);
  End;

  ClearDeviceList;

  If VLCPlayer <> nil then
  Begin
    FreeAndNil(VLCPlayer);
  End;
end;


function UTF8StringToWideString(Const S : UTF8String) : WideString;
var
  iLen :Integer;
  sw   :WideString;
begin
  if Length(S) = 0 then
  Begin
    Result := '';
    Exit;
  End;
  iLen := MultiByteToWideChar(CP_UTF8,0,PAnsiChar(s),-1,nil,0);
  SetLength(sw,iLen);
  MultiByteToWideChar(CP_UTF8,0,PAnsiChar(s),-1,PWideChar(sw),iLen);
  iLen := Pos(#0,sw);
  If iLen > 0 then SetLength(sw,iLen-1);
  Result := sw;
end;


procedure TOptionsForm.PlayButtonClick(Sender: TObject);
var
  p_li: libvlc_instance_t_ptr;
  p_mp: libvlc_media_player_t_ptr;
  p_md: libvlc_media_t_ptr;
  S   : AnsiString;

begin
  If MediaFile.Text <> '' then
  Begin
    // Set casting device if selected
    If (SetOPVLCCastDeviceList.ItemIndex > -1) and (SetOPVLCCastDeviceList.ItemIndex < SetOPVLCCastDeviceList.Count) then
    Begin
      AddDebugMsg('Setting cast device to "'+SetOPVLCCastDeviceList.Items[SetOPVLCCastDeviceList.ItemIndex]+'"');

      // Set
      If libvlc_media_player_set_renderer(VLCPlayer.GetPlayerHandle,SetOPVLCCastDeviceList.Items.Objects[SetOPVLCCastDeviceList.ItemIndex]) = -1 then
        AddDebugMsg('Error setting casting') else
        AddDebugMsg('Casting device set');
    End;

    // Start playing
    VLCPlayer.Play('file:///'+MediaFile.Text);
  End
  Else AddDebugMsg('Pick a media file first');
end;


function TOptionsForm.InitVLCInterface : Integer;
begin
  AddDebugMsg('InitVLCInterface (before)');
  Result := S_OK;
  Try
    VLCPlayer := TPasLibVlcPlayer.Create(OptionsForm);
  Except
    On E : Exception do
    Begin
      AddDebugMsg('Create Exception "'+E.Message+'"');
      Result := E_FAIL;
    End;
  End;

  If Result = S_OK then
  Begin

    AddDebugMsg('VLC: Adding startup options');
    //VLCPlayer.StartOptions.Add('--start-paused');

    // Debug log to file
    {$IFDEF VLCLOG}
    VLCPlayer.StartOptions.Add('--file-logging');
    VLCPlayer.StartOptions.Add('--logfile=.\vlc_debug_log.txt');
    VLCPlayer.StartOptions.Add('--log-verbose=3');
    AddDebugMsg('VLC: Debug log file enabled');
    {$ENDIF}

    With VLCPlayer do
    Begin
      OnMediaPlayerMediaChanged       := OptionsForm.VLCPlayerMediaPlayerMediaChanged;
      OnMediaPlayerNothingSpecial     := OptionsForm.VLCPlayerMediaPlayerNothingSpecial;
      OnMediaPlayerOpening            := OptionsForm.VLCPlayerMediaPlayerOpening;
      OnMediaPlayerBuffering          := OptionsForm.VLCPlayerMediaPlayerBuffering;
      OnMediaPlayerPlaying            := OptionsForm.VLCPlayerMediaPlayerPlaying;
      OnMediaPlayerPaused             := OptionsForm.VLCPlayerMediaPlayerPaused;
      OnMediaPlayerStopped            := OptionsForm.VLCPlayerMediaPlayerStopped;
      OnMediaPlayerForward            := OptionsForm.VLCPlayerMediaPlayerForward;
      OnMediaPlayerBackward           := OptionsForm.VLCPlayerMediaPlayerBackward;
      OnMediaPlayerEndReached         := OptionsForm.VLCPlayerMediaPlayerEndReached;
      OnMediaPlayerEncounteredError   := OptionsForm.VLCPlayerMediaPlayerEncounteredError;
      OnMediaPlayerTimeChanged        := OptionsForm.VLCPlayerMediaPlayerTimeChanged;
      OnMediaPlayerPositionChanged    := OptionsForm.VLCPlayerMediaPlayerPositionChanged;
      OnMediaPlayerSeekableChanged    := OptionsForm.VLCPlayerMediaPlayerSeekableChanged;
      OnMediaPlayerPausableChanged    := OptionsForm.VLCPlayerMediaPlayerPausableChanged;
      OnMediaPlayerTitleChanged       := OptionsForm.VLCPlayerMediaPlayerTitleChanged;
      OnMediaPlayerSnapshotTaken      := OptionsForm.VLCPlayerMediaPlayerSnapshotTaken;
      OnMediaPlayerLengthChanged      := OptionsForm.VLCPlayerMediaPlayerLengthChanged;
      OnMediaPlayerVideoOutChanged    := OptionsForm.VLCPlayerMediaPlayerVideoOutChanged;
      OnMediaPlayerScrambledChanged   := OptionsForm.VLCPlayerMediaPlayerScrambledChanged;
      OnMediaPlayerCorked             := OptionsForm.VLCPlayerMediaPlayerCorked;
      OnMediaPlayerUnCorked           := OptionsForm.VLCPlayerMediaPlayerUnCorked;
      OnMediaPlayerMuted              := OptionsForm.VLCPlayerMediaPlayerMuted;
      OnMediaPlayerUnMuted            := OptionsForm.VLCPlayerMediaPlayerUnMuted;
      OnMediaPlayerAudioVolumeChanged := OptionsForm.VLCPlayerMediaPlayerAudioVolumeChanged;
      OnMediaPlayerEsAdded            := OptionsForm.VLCPlayerMediaPlayerEsAdded;
      OnMediaPlayerEsDeleted          := OptionsForm.VLCPlayerMediaPlayerEsDeleted;
      OnMediaPlayerEsSelected         := OptionsForm.VLCPlayerMediaPlayerEsSelected;
      OnMediaPlayerAudioDevice        := OptionsForm.VLCPlayerMediaPlayerAudioDevice;
      OnMediaPlayerChapterChanged     := OptionsForm.VLCPlayerMediaPlayerChapterChanged;
      OnRendererDiscoveredItemAdded   := OptionsForm.VLCPlayerRendererDiscoveredItemAdded;
      OnRendererDiscoveredItemDeleted := OptionsForm.VLCPlayerRendererDiscoveredItemDeleted;
      MouseEventsHandler              := mehComponent;
    End;

    VLCPlayer.SetBounds(0,0,PlayerPanel.ClientWidth,PlayerPanel.ClientHeight);
    VLCPlayer.Parent := PlayerPanel;
  End;
  If libvlc_dynamic_dll_error <> '' then
  Begin
    AddDebugMsg('VLC DLL Error "'+libvlc_dynamic_dll_error+'"');
    Result := E_FAIL;
  End
  Else AddDebugMsg('VLC DLL no error reported');

  AddDebugMsg('InitVLCInterface (after)');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerMediaChanged(Sender: TObject; mrl: string);
begin
  AddDebugMsg('VLC: MediaPlayerMediaChanged: ' + mrl);
  //Caption := mrl;
end;


procedure TOptionsForm.VLCPlayerMediaPlayerNothingSpecial(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerNothingSpecial');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerOpening(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerOpening');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerBuffering(Sender: TObject; val: Single);
begin
  AddDebugMsg('VLC: MediaPlayerBuffering: ' + IntToStr(Round(val)));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerPlaying(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerPlaying');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerPaused(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerPaused');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerStopped(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerStopped');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerForward(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerForward');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerBackward(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerBackward');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerEndReached(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerEndReached');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerEncounteredError(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerEncounteredError "'+UTF8StringToWideString(libvlc_errmsg)+'"');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerTimeChanged(Sender: TObject; time: Int64);
var
  oldOnChange : TNotifyEvent;
begin
  AddDebugMsg('VLC: MediaPlayerTimeChanged: ' + time2str(time));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerPositionChanged(Sender: TObject; position: Single);
begin
  AddDebugMsg('VLC: MediaPlayerPositionChanged: ' + FloatToStr(position));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerSeekableChanged(Sender: TObject; val: Boolean);
begin
  AddDebugMsg('VLC: MediaPlayerSeekableChanged: ' + IntToStr(Ord(val)));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerPausableChanged(Sender: TObject; val: Boolean);
begin
  AddDebugMsg('VLC: MediaPlayerPausableChanged: ' + IntToStr(Ord(val)));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerTitleChanged(Sender: TObject; title: Integer);
begin
  AddDebugMsg('VLC: MediaPlayerTitleChanged: ' + IntToStr(title));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerSnapshotTaken(Sender: TObject; fileName: string);
begin
  AddDebugMsg('VLC: MediaPlayerSnapshotTaken: ' + fileName);
end;


procedure TOptionsForm.VLCPlayerMediaPlayerLengthChanged(Sender: TObject; time: Int64);
var
  oldOnChange : TNotifyEvent;
begin
  AddDebugMsg('VLC: MediaPlayerLengthChanged: ' + time2str(time));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerVideoOutChanged(Sender: TObject; video_out: Integer);
begin
  AddDebugMsg('VLC: MediaPlayerVideoOutChanged: ' + IntToStr(video_out));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerScrambledChanged(Sender: TObject; scrambled: Integer);
begin
  AddDebugMsg('VLC: MediaPlayerScrambledChanged: ' + IntToStr(scrambled));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerCorked(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerCorked');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerUnCorked(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerUnCorked');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerMuted(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerMuted');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerUnMuted(Sender: TObject);
begin
  AddDebugMsg('VLC: MediaPlayerUnMuted');
end;


procedure TOptionsForm.VLCPlayerMediaPlayerAudioVolumeChanged(Sender: TObject; volume: Single);
var
  newAudioVolume : string;
begin
  AddDebugMsg('VLC: MediaPlayerAudioVolume: ' + FloatToStr(volume));
end;


procedure TOptionsForm.VLCPlayerMediaPlayerEsAdded(Sender: TObject; i_type: libvlc_track_type_t; i_id: Integer);
begin
  case i_type of
    libvlc_track_audio :
    Begin
      AddDebugMsg('VLC: MediaPlayerEsAdded (audio), id = ' + IntToStr(i_id));
    End;
    libvlc_track_video :
    Begin
      AddDebugMsg('VLC: MediaPlayerEsAdded (video), id = ' + IntToStr(i_id));
    End;
    libvlc_track_text  :
    Begin
      AddDebugMsg('VLC: MediaPlayerEsAdded (text),  id = ' + IntToStr(i_id));
    End;
    else // case-else
    Begin
      AddDebugMsg('VLC: MediaPlayerEsAdded (unknown),  id = ' + IntToStr(i_id));
    End;
  end;
end;


procedure TOptionsForm.VLCPlayerMediaPlayerEsDeleted(Sender: TObject; i_type: libvlc_track_type_t; i_id: Integer);
begin
  case i_type of
    libvlc_track_audio : AddDebugMsg('VLC: PlayerEsDeleted (audio), id = ' + IntToStr(i_id));
    libvlc_track_video : AddDebugMsg('VLC: PlayerEsDeleted (video), id = ' + IntToStr(i_id));
    libvlc_track_text  : AddDebugMsg('VLC: PlayerEsDeleted (text),  id = ' + IntToStr(i_id));
    else
      AddDebugMsg('VLC: MediaPlayerEsDeleted (unknown),  id = ' + IntToStr(i_id));
  end;
end;


procedure TOptionsForm.VLCPlayerMediaPlayerEsSelected(Sender: TObject; i_type: libvlc_track_type_t; i_id: Integer);
begin
  case i_type of
    libvlc_track_audio : AddDebugMsg('VLC: PlayerEsSelected (audio), id = ' + IntToStr(i_id));
    libvlc_track_video : AddDebugMsg('VLC: PlayerEsSelected (video), id = ' + IntToStr(i_id));
    libvlc_track_text  : AddDebugMsg('VLC: PlayerEsSelected (text),  id = ' + IntToStr(i_id));
    else                 AddDebugMsg('VLC: MediaPlayerEsSelected (unknown),  id = ' + IntToStr(i_id));
  end;
end;


procedure TOptionsForm.VLCPlayerMediaPlayerAudioDevice(Sender: TObject; audio_device: String);
begin
  AddDebugMsg('VLC: MediaPlayerAudioDevice: ' + audio_device);
end;


procedure TOptionsForm.VLCPlayerMediaPlayerChapterChanged(Sender: TObject; chapter: Integer);
begin
  AddDebugMsg('VLC: MediaPlayerChapterChanged: ' + IntToStr(chapter));
end;


procedure TOptionsForm.VLCPlayerRendererDiscoveredItemAdded(Sender: TObject; item: libvlc_renderer_item_t_ptr);
begin
  AddDebugMsg('VLC: RendererDiscoveredItemAdded');
end;


procedure TOptionsForm.VLCPlayerRendererDiscoveredItemDeleted(Sender: TObject; item: libvlc_renderer_item_t_ptr);
begin
  AddDebugMsg('VLC: RendererDiscoveredItemDeleted');
end;


procedure TOptionsForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  If Key = #27 then
  Begin
    Key := #0;
    Close;
  End;
end;


procedure TOptionsForm.BrowseButtonClick(Sender: TObject);
begin
  If OpenDialog.Execute = True then
    MediaFile.Text := OpenDialog.FileName;
end;


procedure TOptionsForm.FormCreate(Sender: TObject);
begin
  InitVLCInterface;
end;

end.
