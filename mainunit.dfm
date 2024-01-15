object OptionsForm: TOptionsForm
  Left = 534
  Top = 130
  Width = 728
  Height = 881
  Caption = 'OptionsForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object LabelDevices: TLabel
    Left = 18
    Top = 18
    Width = 62
    Height = 13
    Caption = 'Device List : '
  end
  object LabelDebugLog: TLabel
    Left = 210
    Top = 18
    Width = 62
    Height = 13
    Caption = 'Debug Log : '
  end
  object Label1: TLabel
    Left = 18
    Top = 406
    Width = 54
    Height = 13
    Caption = 'Media File :'
  end
  object ScanButton: TButton
    Left = 16
    Top = 350
    Width = 75
    Height = 25
    Caption = 'Scan'
    TabOrder = 0
    OnClick = ScanButtonClick
  end
  object SetOPVLCCastDeviceList: TListBox
    Left = 16
    Top = 32
    Width = 181
    Height = 307
    ItemHeight = 13
    TabOrder = 1
  end
  object StopButton: TButton
    Left = 122
    Top = 350
    Width = 75
    Height = 25
    Caption = 'Stop'
    Enabled = False
    TabOrder = 2
    OnClick = StopButtonClick
  end
  object DebugLB: TListBox
    Left = 208
    Top = 32
    Width = 487
    Height = 307
    ItemHeight = 13
    TabOrder = 3
  end
  object MediaFile: TEdit
    Left = 80
    Top = 402
    Width = 455
    Height = 21
    TabOrder = 4
  end
  object PlayButton: TButton
    Left = 620
    Top = 400
    Width = 75
    Height = 25
    Caption = 'Play'
    TabOrder = 5
    OnClick = PlayButtonClick
  end
  object PlayerPanel: TPanel
    Left = 16
    Top = 442
    Width = 680
    Height = 382
    TabOrder = 6
  end
  object BrowseButton: TButton
    Left = 538
    Top = 400
    Width = 75
    Height = 25
    Caption = 'Browse'
    TabOrder = 7
    OnClick = BrowseButtonClick
  end
  object OpenDialog: TOpenDialog
    Filter = 'Media Files|*.mkv;*.mp4;*.avi;*.mpg|All Files|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 658
    Top = 456
  end
end
