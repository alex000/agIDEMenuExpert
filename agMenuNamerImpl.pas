unit agMenuNamerImpl;

interface

uses
  SysUtils, Classes, Graphics, Controls, Menus, ActnList, Dialogs, Forms,ExtCtrls,
  ToolsAPI;

type
  TDropDownAction = TControlAction;
  TagMenuNamerStandardAction = class(TCustomAction)
  private
    FControlAction: Integer;
  public
    property ControlAction: Integer read FControlAction write FControlAction;
  end;

  TagMenuNamerDropDownAction = class(TDropDownAction)
  private
    FControlAction: Integer;
  public
    property ControlAction: Integer read FControlAction write FControlAction;
  end;

  IagOTAOptionsCallback = interface;

  TagOTAAddPageFunc = procedure (AControl: TControl; PageName: string;
    Expert: IagOTAOptionsCallback) of object;

  IagOTAOptionsCallback = interface
    procedure AddConfigurationPages(AddPageFunc: TagOTAAddPageFunc);
    procedure ConfigurationClosed(AControl: TControl; SaveChanges: Boolean);
  end;

  TagMenuNamerExpert = class (TNotifierObject,IOTAWizard,IOTAMenuWizard)//(TagOTAExpert)
  public
      { IOTANotifier }
    procedure AfterSave; virtual;
    procedure BeforeSave; virtual;
    procedure Destroyed; virtual;
    procedure Modified; virtual;
    { IOTAWizard }
    procedure Execute; virtual;
    function GetIDString: string; virtual;
    function GetName: string; virtual;
    function GetState: TWizardState; virtual;
     {IOTAMenuWizard}
     function GetMenuText: string;

     procedure AfterConstruction; override;
  private
    FUpdateTimer: TTimer;
    FUpdateCount: Integer;
    FVersionCtrlMenu: TMenuItem;
//    FActions: array [TagMenuNamerActionType] of TCustomAction;
//    FIconIndexes: array [TagMenuNamerActionType] of Integer;
    FHideActions: Boolean;
//    FIconType: TIconType;
    FActOnTopSandbox: Boolean;
    FSaveConfirmation: Boolean;
    FDisableActions: Boolean;
//    FOptionsFrame: TagVersionCtrlOptionsFrame;
    FMenuOrganization: TStringList;
//    procedure SetIconType(const Value: TIconType);

    procedure RegisterAction(Action: TCustomAction);
    procedure AssignNames4Tools();
    procedure OnUpdateTimer(Sender: TObject);
    procedure ActionUpdate(Sender: TObject);
    procedure ActionExecute(Sender: TObject);
    procedure IDEActionMenuClick(Sender: TObject);
    procedure SubItemClick(Sender: TObject);
    procedure DropDownMenuPopup(Sender: TObject);
    //procedure IDEVersionCtrlMenuClick(Sender: TObject);
    //procedure RefreshIcons;
    //procedure RefreshMenu;
//    function GetCurrentCache: TagMenuNamerCache;
//    function GetCurrentPlugin: TagMenuNamerPlugin;
    function GetCurrentFileName: string;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure RegisterCommands; //override;
    class function GetNTAServices: INTAServices;
    procedure BaseRegisterCommands; //override;
    procedure UnregisterCommands; //override;
//    procedure AddConfigurationPages(AddPageFunc: TagOTAAddPageFunc); //override;
//    procedure ConfigurationClosed(AControl: TControl; SaveChanges: Boolean); //override;
    function SaveModules(const FileName: string;  const IncludeSubDirectories: Boolean): Boolean;
    property ActOnTopSandbox: Boolean read FActOnTopSandbox write FActOnTopSandbox;
    property DisableActions: Boolean read FDisableActions write FDisableActions;
    property HideActions: Boolean read FHideActions write FHideActions;
    property SaveConfirmation: Boolean read FSaveConfirmation write FSaveConfirmation;
//    property IconType: TIconType read FIconType write SetIconType;
//    property CurrentCache: TagMenuNamerCache read GetCurrentCache;
//    property CurrentPlugin: TagMenuNamerPlugin read GetCurrentPlugin;
    property CurrentFileName: string read GetCurrentFileName;
  end;

// design package entry point
procedure Register;

// expert DLL entry point
function agWizardInit(const BorlandIDEServices: IBorlandIDEServices;
  RegisterProc: TWizardRegisterProc;
  var TerminateProc: TWizardTerminateProc): Boolean; stdcall;

function GetItemIndexA(const Item: string): Integer;
function GetItemIndexB(const Item: string): Integer;
function GetItemName(const Item: string): string;

function CharIsAmpersand(const C: Char): Boolean;

implementation

uses
  Windows, TypInfo, ImgList;

var
  GlobalActionList: TList = nil;
//  GlobalActionSettings: TagOtaSettings = nil;
  GlobalExpertList: TList = nil;
  ConfigurationAction: TAction = nil;
  ConfigurationMenuItem: TMenuItem = nil;

function CharIsAmpersand(const C: Char): Boolean;
begin
  Result := C = '&';
end;

procedure Register;
begin
  try
    RegisterPackageWizard(TagMenuNamerExpert.Create);
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end;
end;

var
  agWizardIndex: Integer = -1;

procedure agWizardTerminate;
begin
  try
//    if agWizardIndex <> -1 then
//      TagOTAExpertBase.GetOTAWizardServices.RemoveWizard(agWizardIndex);
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end;
end;

function agWizardInit(const BorlandIDEServices: IBorlandIDEServices;
    RegisterProc: TWizardRegisterProc;
var TerminateProc: TWizardTerminateProc): Boolean stdcall;
var GetOTAWizardServices:IOTAWizardServices;
begin
  try
    TerminateProc := agWizardTerminate;


   Supports(BorlandIDEServices, IOTAWizardServices, GetOTAWizardServices);

    agWizardIndex := GetOTAWizardServices.AddWizard(TagMenuNamerExpert.Create);

    Result := True;
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
      Result := False;
    end;
  end;
end;

function GetItemIndexA(const Item: string): Integer;
var
  Index: Integer;
begin
  Result := 0;
  for Index := 1 to Length(Item) do
    if not (Item[Index] in ['0','1','2','3','4','5','6','7','8','9']) then
  begin
    Result := StrToInt(Copy(Item, 1, Index - 1));
    Exit;
  end;
  Abort;
end;

function GetItemIndexB(const Item: string): Integer;
var
  Index: Integer;
begin
  Result := -1;
  for Index := Length(Item) downto 1 do
    if not (Item[Index] in ['0','1','2','3','4','5','6','7','8','9']) then
  begin
    if Index < Length(Item) then
      Result := StrToInt(Copy(Item, Index + 1, Length(Item) - Index));
    Exit;
  end;
end;

function GetItemName(const Item: string): string;
var
  Index1, Index2: Integer;
begin
  for Index1 := 1 to Length(Item) do
    if not (Item[Index1] in ['0','1','2','3','4','5','6','7','8','9']) then
  begin
    if Index1 = 1 then
      Abort;
    Break;
  end;

  for Index2 := Length(Item) downto 1 do
    if not (Item[Index2] in ['0','1','2','3','4','5','6','7','8','9']) then
      Break;

  Result := Copy(Item, Index1, Index2 - Index1 + 1);
end;

function MenuOrganizationSort(List: TStringList; Index1, Index2: Integer): Integer;
var
  Item1, Item2: string;
  Index1A, Index1B, Index2A, Index2B: Integer;
begin
  Item1 := List.Strings[Index1];
  Item2 := List.Strings[Index2];
  Index1A := GetItemIndexA(Item1);
  Index1B := GetItemIndexB(Item1);
  Index2A := GetItemIndexA(Item2);
  Index2B := GetItemIndexB(Item2);

  if Index1A < Index2A then
    Result := -1
  else
  if Index1A > Index2A then
    Result := 1
  else
  if Index1B < Index2B then
    Result := -1
  else
  if Index1B > Index2B then
    Result := 1
  else
    Result := 0;
end;


//=== { TagMenuNamerExpert } ===================================================

procedure TagMenuNamerExpert.ActionExecute(Sender: TObject);
var
  Index: Integer;
  AAction: TCustomAction;
//  ControlAction: TagMenuNamerActionType;
//  ControlActionInfo: TagMenuNamerActionInfo;
//  APlugin: TagMenuNamerPlugin;
  AFileName: string;
//  AFileCache: TagMenuNamerCache;
//PluginList: TagMenuNamerPluginList;
begin  {
  try
    AAction := Sender as TCustomAction;
//  ControlAction := ActionToControlAction(AAction);
//  ControlActionInfo := MenuNamerActionInfo(ControlAction);

    if ControlActionInfo.Sandbox then
    begin
      AFileCache := CurrentCache;
      if not Assigned(AFileCache) or ControlActionInfo.AllPlugins then
        Exit;
      if ActOnTopSandbox then
      begin
        for Index := AFileCache.SandboxCount - 1 downto 0 do
          if ControlAction in AFileCache.SandboxActions[Index] then
        begin
          if ControlActionInfo.SaveFile then
            SaveModules(AFileCache.SandBoxes[Index], True);
          AFileCache.Plugin.ExecuteAction(AFileCache.SandBoxes[Index], ControlAction);
          Exit;
        end;
      end
      else
      begin
        for Index := 0 to AFileCache.SandboxCount - 1 do
          if ControlAction in AFileCache.SandboxActions[Index] then
        begin
          if ControlActionInfo.SaveFile then
            SaveModules(AFileCache.SandBoxes[Index], True);
          AFileCache.Plugin.ExecuteAction(AFileCache.SandBoxes[Index], ControlAction);
          Exit;
        end;
      end;
    end
    else
    begin
      AFileName := CurrentFileName;
      if ControlActionInfo.SaveFile then
        SaveModules(AFileName, False);

      if ControlActionInfo.AllPlugins then
      begin
        PluginList := MenuNamerPluginList;
        for Index := 0 to PluginList.Count - 1 do
        begin
          AFileCache := PluginList.GetFileCache(AFileName, PluginList.Plugins[Index]);

          if ControlAction in AFileCache.Actions then
          begin
            AFileCache.Plugin.ExecuteAction(AFileName, ControlAction);
            Exit;
          end;
        end;
      end
      else
      begin
        APlugin := CurrentPlugin;
        if Assigned(APlugin) then
          APlugin.ExecuteAction(AFileName, ControlAction);
      end;
    end;
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end;   }
end;

procedure TagMenuNamerExpert.ActionUpdate(Sender: TObject);
var
  IndexSandbox, IndexPlugin: Integer;
  AAction: TCustomAction;
//ControlAction: TagMenuNamerActionType;
//ControlActionInfo: TagMenuNamerActionInfo;
//AFileCache: TagMenuNamerCache;
  AFileName: string;
//PluginList: TagMenuNamerPluginList;
begin
 {try
    AAction := Sender as TCustomAction;
    ControlAction := ActionToControlAction(AAction);
    ControlActionInfo := MenuNamerActionInfo(ControlAction);
    AFileCache := CurrentCache;

    if HideActions and not ControlActionInfo.AllPlugins then
      AAction.Visible := Assigned(AFileCache) and Assigned(AFileCache.Plugin)
        and (ControlAction in AFileCache.Plugin.SupportedActionTypes)
    else
      AAction.Visible := True;

    if DisableActions then
    begin
      if ControlActionInfo.Sandbox then
      begin
        if ControlActionInfo.AllPlugins then
        begin
          PluginList := MenuNamerPluginList;
          AFileName := CurrentFileName;
          for IndexPlugin := 0 to PluginList.Count - 1 do
          begin
            AFileCache := PluginList.GetFileCache(AFileName, PluginList.Plugins[IndexPlugin]);
            for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
              if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
            begin
              AAction.Enabled := True;
              Exit;
            end;
            AAction.Enabled := False;
            Exit;
          end;
        end
        else // work for all plugin
        begin
          if Assigned(AFileCache) then
          begin
            for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
              if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
            begin
              AAction.Enabled := True;
              Exit;
            end;
            AAction.Enabled := False;
            Exit;
          end
          else
            AAction.Enabled := False;
        end;
        Exit;
      end
      else // file
      begin
        if ControlActionInfo.AllPlugins then
        begin
          PluginList := MenuNamerPluginList;
          AFileName := CurrentFileName;
          for IndexPlugin := 0 to PluginList.Count - 1 do
          begin
            AFileCache := PluginList.GetFileCache(AFileName, PluginList.Plugins[IndexPlugin]);
            if ControlAction in AFileCache.Actions then
            begin
              AAction.Enabled := True;
              Exit;
            end;
          end;
          AAction.Enabled := False;
          Exit;
        end
        else // only the current plugin
        begin
          AFileCache := CurrentCache;
          AAction.Enabled := Assigned(AFileCache) and (ControlAction in AFileCache.Actions);
        end;
      end;
    end
    else
      AAction.Enabled := True;
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end; }
end;

constructor TagMenuNamerExpert.Create;
begin
  FMenuOrganization := TStringList.Create;

  inherited Create();

end;

destructor TagMenuNamerExpert.Destroy;
begin
  inherited Destroy;
  FMenuOrganization.Free;
end;

procedure TagMenuNamerExpert.DropDownMenuPopup(Sender: TObject);
var
  APopupMenu: TPopupMenu;
  AMenuItem: TMenuItem;
//ControlAction: TagMenuNamerActionType;
//ControlActionInfo: TagMenuNamerActionInfo;
//AFileCache: TagMenuNamerCache;
  IndexPlugin, IndexSandbox: Integer;
  AFileName: string;
//PluginList: TagMenuNamerPluginList;
begin
 {try
    APopupMenu := Sender as TPopupMenu;
    ControlAction := TagMenuNamerActionType(APopupMenu.Tag);
    ControlActionInfo := MenuNamerActionInfo(ControlAction);

    APopupMenu.Items.Clear;

    if ControlActionInfo.AllPlugins then
    begin
      PluginList := MenuNamerPluginList;
      AFileName := CurrentFileName;
      for IndexPlugin := 0 to PluginList.Count - 1 do
      begin
        AFileCache := PluginList.GetFileCache(AFileName, PluginList.Plugins[IndexPlugin]);
        for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
          if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
        begin
          AMenuItem := TMenuItem.Create(APopupMenu.Items);
          AMenuItem.Caption := Format('%s | %s', [AFileCache.Plugin.Name, AFileCache.SandBoxes[IndexSandbox]]);
          AMenuItem.Tag := APopupMenu.Tag;
          AMenuItem.OnClick := SubItemClick;
          case IconType of
            itNone:
              AMenuItem.ImageIndex := -1;
            itag:
              AMenuItem.ImageIndex := FIconIndexes[ControlAction];
          end;
          APopupMenu.Items.Add(AMenuItem);
        end;
      end;
    end
    else
    begin
      AFileCache := CurrentCache;
      if Assigned(AFileCache) then
        for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
          if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
      begin
        AMenuItem := TMenuItem.Create(APopupMenu.Items);
        AMenuItem.Caption := AFileCache.SandBoxes[IndexSandbox];
        AMenuItem.Tag := APopupMenu.Tag;
        AMenuItem.OnClick := SubItemClick;
        case IconType of
          itNone:
            AMenuItem.ImageIndex := -1;
          itag:
            AMenuItem.ImageIndex := FIconIndexes[ControlAction];
        end;
        APopupMenu.Items.Add(AMenuItem);
      end;
    end;
  except
    on ExceptionObj: TObject do
    begin
    //  ExpertException(ExceptionObj,0);
    end;
  end; }
end;

class function TagMenuNamerExpert.GetNTAServices : INTAServices;
begin
  Supports(BorlandIDEServices, INTAServices, Result);
  if not Assigned(Result) then
    raise Exception.Create('@RsENoNTAServices');
end;

function TagMenuNamerExpert.GetCurrentFileName: string;
var
  AOTAModule: IOTAModule;
begin
{
  AOTAModule := GetOTAModuleServices.CurrentModule;
  //SC  20/03/2007
  if Assigned(AOTAModule) and Assigned(AOTAModule.CurrentEditor) then
  begin
    Result := AOTAModule.CurrentEditor.FileName;
    Exit;
  end
  //SC  20/03/2007
  else
  if Assigned(AOTAModule) and (AOTAModule.FileSystem = '') then
    Result := AOTAModule.FileName
  else
    Result := ''; }
end;

procedure TagMenuNamerExpert.IDEActionMenuClick(Sender: TObject);
var
  AMenuItem, SubMenuItem: TMenuItem;
//ControlAction: TagMenuNamerActionType;
//ControlActionInfo: TagMenuNamerActionInfo;
  IndexSandbox, IndexPlugin, IndexItem: Integer;
//AFileCache: TagMenuNamerCache;
  AFileName: string;
//PluginList: TagMenuNamerPluginList;
begin
  { try
    AMenuItem := Sender as TMenuItem;
    // do not delete the dummy subitem
    for IndexItem := AMenuItem.Count - 1 downto 1 do
      AMenuItem.Items[IndexItem].Free;
//  ControlAction := TagMenuNamerActionType(AMenuItem.Tag);
//  ControlActionInfo := MenuNamerActionInfo(ControlAction);

  if ControlActionInfo.AllPlugins then
    begin
      PluginList := MenuNamerPluginList;
      for IndexPlugin := 0 to PluginList.Count - 1 do
      begin
        AFileName := CurrentFileName;
        AFileCache := PluginList.GetFileCache(AFileName, PluginList.Plugins[IndexPlugin]);
        for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
          if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
        begin
          SubMenuItem := TMenuItem.Create(AMenuItem);
          SubMenuItem.Caption := Format('%s | %s', [AFileCache.Plugin.Name, AFileCache.SandBoxes[IndexSandbox]]);
          SubMenuItem.Tag := Integer(ControlAction);
          SubMenuItem.OnClick := SubItemClick;
          case IconType of
            itNone:
              SubMenuItem.ImageIndex := -1;
            itag:
              SubMenuItem.ImageIndex := FIconIndexes[ControlAction];
          end;
          AMenuItem.Add(SubMenuItem);
        end;
      end;
    end
    else
    begin
      AFileCache := CurrentCache;

      if Assigned(AFileCache) then
        for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
          if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
      begin
        SubMenuItem := TMenuItem.Create(AMenuItem);
        SubMenuItem.Caption := AFileCache.SandBoxes[IndexSandbox];
        SubMenuItem.Tag := Integer(ControlAction);
        SubMenuItem.OnClick := SubItemClick;
        case IconType of
          itNone:
            SubMenuItem.ImageIndex := -1;
          itag:
            SubMenuItem.ImageIndex := FIconIndexes[ControlAction];
        end;
        AMenuItem.Add(SubMenuItem);
      end;
    end;
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end; }
end;

{procedure TagMenuNamerExpert.IDEVersionCtrlMenuClick(Sender: TObject);
  procedure UpdateMenuItem(const AMenuItem: TMenuItem);
  var
    BMenuItem: TMenuItem;
    IndexMenu, IndexSandbox: Integer;
//  ControlAction: TagMenuNamerActionType;
//  ControlActionInfo: TagMenuNamerActionInfo;
//  AFileCache: TagMenuNamerCache;
    AEnabled: Boolean;
    IndexPlugin: Integer;
    AFileName: string;
//  PluginList: TagMenuNamerPluginList;
  begin
   for IndexMenu := 0 to AMenuItem.Count - 1 do
    begin
      BMenuItem := AMenuItem.Items[IndexMenu];
      if BMenuItem.Tag = -1 then
        UpdateMenuItem(BMenuItem)
      else
      if BMenuItem.Tag >= 0 then
      begin
        ControlAction := TagMenuNamerActionType(BMenuItem.Tag);
        ControlActionInfo := MenuNamerActionInfo(ControlAction);
        if ControlActionInfo.Sandbox then
        begin
          AFileCache := CurrentCache;

          case IconType of
            itNone:
              BMenuItem.ImageIndex := -1;
            itag:
              BMenuItem.ImageIndex := FIconIndexes[ControlAction];
          end;

          if HideActions and not ControlActionInfo.AllPlugins then
            BMenuItem.Visible := Assigned(AFileCache) and Assigned(AFileCache.Plugin)
              and (ControlAction in AFileCache.Plugin.SupportedActionTypes)
          else
            BMenuItem.Visible := True;

          if DisableActions then
          begin
            AEnabled := False;
            if ControlActionInfo.AllPlugins then
            begin
              PluginList := MenuNamerPluginList;
              AFileName := CurrentFileName;
              for IndexPlugin := 0 to PluginList.Count - 1 do
              begin
                AFileCache := PluginList.GetFileCache(AFileName, PluginList.Plugins[IndexPlugin]);
                for IndexSandbox := 0 to AFileCache.SandBoxCount - 1 do
                  if ControlAction in AFileCache.SandBoxActions[IndexSandbox] then
                begin
                  AEnabled := True;
                  Break;
                end;

                if AEnabled then
                  Break;
              end;
            end
            else
            if Assigned(AFileCache) then
            begin
              for IndexSandbox := 0 to AFileCache.SandboxCount - 1 do
                if ControlAction in AFileCache.SandboxActions[IndexSandbox] then
              begin
                AEnabled := True;
                Break;
              end;
            end;
            BMenuItem.Enabled := AEnabled;
          end
          else
            BMenuItem.Enabled := True;
        end;
      end;
    end;
  end;
begin
  try
    UpdateMenuItem(FVersionCtrlMenu);
  except
    on ExceptionObj: TObject do
    begin
     ShowException(ExceptionObj,0);
    end;
  end;
end; }
    {
procedure TagMenuNamerExpert.RefreshIcons;
var
  ControlAction: TagMenuNamerActionType;
begin
  for ControlAction := Low(TagMenuNamerActionType) to High(TagMenuNamerActionType) do
    if Assigned(FActions[ControlAction]) then
  begin
    case IconType of
      // No icon
      itNone :
        FActions[ControlAction].ImageIndex := -1;
      // ag icons
      itag :
        FActions[ControlAction].ImageIndex := FIconIndexes[ControlAction];
    end;
  end;
end;  }
            {
procedure TagMenuNamerExpert.RefreshMenu;
  procedure LoadDefaultMenu;
  var
    Action: TagMenuNamerActionType;
  begin
    FMenuOrganization.Clear;
    for Action := Low(TagMenuNamerActionType) to High(TagMenuNamerActionType) do
      FMenuOrganization.Add(Format('%d%s', [Integer(Action), GetEnumName(TypeInfo(TagMenuNamerActionType), Integer(Action))]));
  end;
var
  Index, IndexA, IndexB, ActionIndex: Integer;
  SubMenuItem, ActionMenuItem, DummyMenuItem: TMenuItem;
  Item, ItemName: string;
  AAction: TCustomAction;
begin
  FVersionCtrlMenu.Clear;

  if FMenuOrganization.Count > 0 then
  try
    FMenuOrganization.CustomSort(MenuOrganizationSort);
  except
    LoadDefaultMenu;
  end
  else
    LoadDefaultMenu;

  SubMenuItem := nil;
  for Index := 0 to FMenuOrganization.Count - 1 do
  begin
    Item := FMenuOrganization.Strings[Index];
    IndexA := GetItemIndexA(Item);
    IndexB := GetItemIndexB(Item);
    ItemName := GetItemName(Item);
    ActionIndex := GetEnumValue(TypeInfo(TagMenuNamerActionType), ItemName);

    if IndexB = -1 then
    begin
      if FVersionCtrlMenu.Count <> IndexA then
        Abort;

      if (ActionIndex = -1) or (ItemName = '-') then
      begin
        SubMenuItem := TMenuItem.Create(FVersionCtrlMenu);
        SubMenuItem.Caption := ItemName;
        SubMenuItem.Tag := -1;
        FVersionCtrlMenu.Add(SubMenuItem);
      end
      else
      begin
        ActionMenuItem := TMenuItem.Create(FVersionCtrlMenu);
        AAction := FActions[TagMenuNamerActionType(ActionIndex)];
        if MenuNamerActionInfo(TagMenuNamerActionType(ActionIndex)).Sandbox then
        begin
          ActionMenuItem.Caption := AAction.Caption;
          ActionMenuItem.ShortCut := AAction.ShortCut;
          ActionMenuItem.ImageIndex := AAction.ImageIndex;
          ActionMenuItem.Tag := ActionIndex;
          ActionMenuItem.OnClick := IDEActionMenuClick;

          // to always have the arrow in the parent menu item
          DummyMenuItem := TMenuItem.Create(ActionMenuItem);
          DummyMenuItem.Visible := False;
          DummyMenuItem.Tag := -2;
          ActionMenuItem.Add(DummyMenuItem);
        end
        else
          ActionMenuItem.Action := AAction;
        FVersionCtrlMenu.Add(ActionMenuItem);
        SubMenuItem := nil;
      end;
    end
    else
    begin
      if (not Assigned(SubMenuItem)) or (SubMenuItem.Count <> IndexB) then
        Abort;
      if (ActionIndex = -1) or (ItemName = '-') then
      begin
        ActionMenuItem := TMenuItem.Create(FVersionCtrlMenu);
        ActionMenuItem.Caption := ItemName;
      end
      else
      begin
        ActionMenuItem := TMenuItem.Create(FVersionCtrlMenu);
        AAction := FActions[TagMenuNamerActionType(ActionIndex)];
        if MenuNamerActionInfo(TagMenuNamerActionType(ActionIndex)).Sandbox then
        begin
          ActionMenuItem.Caption := AAction.Caption;
          ActionMenuItem.ShortCut := AAction.ShortCut;
          ActionMenuItem.ImageIndex := AAction.ImageIndex;
          ActionMenuItem.Tag := ActionIndex;
          ActionMenuItem.OnClick := IDEActionMenuClick;

          // to always have the arrow in the parent menu item
          DummyMenuItem := TMenuItem.Create(ActionMenuItem);
          DummyMenuItem.Visible := False;
          DummyMenuItem.Tag := -2;
          ActionMenuItem.Add(DummyMenuItem);
        end
        else
          ActionMenuItem.Action := AAction;
      end;
      SubMenuItem.Add(ActionMenuItem);
    end;
  end;
end;  }


procedure TagMenuNamerExpert.BaseRegisterCommands;
var
  agIcon: TIcon;
  Category: string;
  Index: Integer;
  IDEMenuItem, ToolsMenuItem: TMenuItem;
  NTAServices: INTAServices;
begin
  NTAServices := GetNTAServices;

  if not Assigned(ConfigurationAction) then
  begin
    Category := '';
    for Index := 0 to NTAServices.ActionList.ActionCount - 1 do
      if CompareText(NTAServices.ActionList.Actions[Index].Name, 'ToolsOptionsCommand') = 0 then
        Category := NTAServices.ActionList.Actions[Index].Category;

    ConfigurationAction := TAction.Create(nil);
    agIcon := TIcon.Create;
    try
      // not ModuleHInstance because the resource is in agBaseExpert.bpl
      agIcon.Handle := LoadIcon(HInstance, 'agCONFIGURE');
      ConfigurationAction.ImageIndex := NTAServices.ImageList.AddIcon(agIcon);
    finally
      agIcon.Free;
    end;
    ConfigurationAction.Caption := 'LoadResString RsagOptions';
    ConfigurationAction.Name := 'agConfigureActionName';
    ConfigurationAction.Category := Category;
    ConfigurationAction.Visible := True;
//    ConfigurationAction.OnUpdate := ConfigurationActionUpdate;
//    ConfigurationAction.OnExecute := ConfigurationActionExecute;

    ConfigurationAction.ActionList := NTAServices.ActionList;
//    RegisterAction(ConfigurationAction);
  end;


  if not Assigned(ConfigurationMenuItem) then
  begin
    IDEMenuItem := NTAServices.MainMenu.Items;
    if not Assigned(IDEMenuItem) then
      raise Exception.Create('@RsENoIDEMenu');
      ShowMessage('BaseRegisterCommands');

    ToolsMenuItem := nil;
    for Index := 0 to IDEMenuItem.Count - 1 do
      if CompareText(IDEMenuItem.Items[Index].Name, 'ToolsMenu') = 0 then
        ToolsMenuItem := IDEMenuItem.Items[Index];
    if not Assigned(ToolsMenuItem) then
      raise Exception.Create('@RsENoToolsMenu');

    ConfigurationMenuItem := TMenuItem.Create(nil);
    ConfigurationMenuItem.Name := 'agConfigureMenuName';
    ConfigurationMenuItem.Action := ConfigurationAction;

    ToolsMenuItem.Insert(0, ConfigurationMenuItem);
  end;

    for Index := 0 to ToolsMenuItem.Count - 1 do
      if ToolsMenuItem.Items[Index].Name = '' then
      begin
        ToolsMenuItem.Items[Index].Name := 'ToolsMenu_Unnamed'+IntToStr(Index);
        ShowMessage('Unnamed'+IntToStr(Index));
      end
  // override to add actions and menu items
end;

procedure TagMenuNamerExpert.RegisterCommands;
var
  IDEMainMenu: TMainMenu;
  IDEToolsItem: TMenuItem;
  IDEImageList: TCustomImageList;
  IDEActionList: TCustomActionList;
  I: Integer;
  AStandardAction: TagMenuNamerStandardAction;
  ADropDownAction: TagMenuNamerDropDownAction;
  AAction: TCustomAction;
  IconTypeStr: string;
//  ControlAction: TagMenuNamerActionType;
//  ControlActionInfo: TagMenuNamerActionInfo;
  NTAServices: INTAServices;
  AIcon: TIcon;
begin
ShowMessage('ETST');
BaseRegisterCommands;
{
//  inherited RegisterCommands;
//  NTAServices := GetNTAServices;

//  Settings.LoadStrings(agVersionCtrlMenuOrganizationName, FMenuOrganization);
//  SaveConfirmation := Settings.LoadBool(agVersionCtrlSaveConfirmationName, True);
//  DisableActions := Settings.LoadBool(agVersionCtrlDisableActionsName, True);
//  HideActions := Settings.LoadBool(agVersionCtrlHideActionsName, False);
//  IconTypeStr := Settings.LoadString(agVersionCtrlIconTypeName, agVersionCtrlIconTypeAutoValue);
//  ActOnTopSandbox := Settings.LoadBool(agVersionCtrlActOnTopSandboxName, False);

  FIconType := itag;
//  if IconTypeStr = agVersionCtrlIconTypeNoIconValue then
//    FIconType := itNone
//  else
//  if IconTypeStr = agVersionCtrlIconTypeagIconValue then
//    FIconType := itag;

  IDEImageList := NTAServices.ImageList;
  AIcon := TIcon.Create;
  try
    for ControlAction := Low(TagMenuNamerActionType) to High(TagMenuNamerActionType) do
    begin
      AIcon.Handle := LoadIcon(HInstance, IconNames[ControlAction]);
      FIconIndexes[ControlAction] := IDEImageList.AddIcon(AIcon);
    end;
  finally
    AIcon.Free;
  end;

  IDEMainMenu := NTAServices.MainMenu;
  IDEToolsItem := nil;
  for I := 0 to IDEMainMenu.Items.Count - 1 do
    if IDEMainMenu.Items[I].Name = 'ToolsMenu' then
  begin
    IDEToolsItem := IDEMainMenu.Items[I];
    Break;
  end;
  if not Assigned(IDEToolsItem) then
    raise Exception.Create('@RsENoToolsMenuItem');

  IDEActionList := NTAServices.ActionList;

  FVersionCtrlMenu := TMenuItem.Create(nil);
  FVersionCtrlMenu.Caption := '@RsVersionCtrlMenuCaption';
  FVersionCtrlMenu.Name := 'agVersionCtrlMenuName';
  FVersionCtrlMenu.OnClick := IDEVersionCtrlMenuClick;
  IDEMainMenu.Items.Insert(IDEToolsItem.MenuIndex + 1, FVersionCtrlMenu);
  if not Assigned(FVersionCtrlMenu.Parent) then
    raise Exception.CreateFmt('@RsSvnMenuItemNotInserted', [FVersionCtrlMenu.Caption]);

  for ControlAction := Low(TagMenuNamerActionType) to High(TagMenuNamerActionType) do
  begin
    ControlActionInfo := MenuNamerActionInfo(ControlAction);

    if ControlActionInfo.Sandbox then
    begin
      ADropDownAction := TagMenuNamerDropDownAction.Create(nil);
      ADropDownAction.ControlAction := ControlAction;
      ADropDownAction.DropdownMenu := TPopupMenu.Create(nil);
      ADropDownAction.DropdownMenu.AutoPopup := True;
      ADropDownAction.DropdownMenu.AutoHotkeys := maManual;
      ADropDownAction.DropdownMenu.Tag := Integer(ControlAction);
      ADropDownAction.DropdownMenu.OnPopup := DropDownMenuPopup;
      AAction := ADropDownAction;
    end
    else
    begin
      AStandardAction := TagMenuNamerStandardAction.Create(nil);
      AStandardAction.ControlAction := ControlAction;
      AAction := AStandardAction;
    end;

    AAction.Caption := LoadResString(ControlActionInfo.Caption);
    AAction.Name := ControlActionInfo.ActionName;
    AAction.Visible := True;
    AAction.ActionList := IDEActionList;
    AAction.OnExecute := ActionExecute;
    AAction.OnUpdate := ActionUpdate;
    AAction.Category := '@RsActionCategory';
//    RegisterAction(AAction);
    FActions[ControlAction] := AAction;
  end;

  RefreshIcons;

  RefreshMenu; }
end;

function TagMenuNamerExpert.SaveModules(const FileName: string;
  const IncludeSubDirectories: Boolean): Boolean;
var
  Module: IOTAModule;
  Index: Integer;
  Save: Boolean;
  OTAModuleServices: IOTAModuleServices;
begin
{  Result := True;
  OTAModuleServices := GetOTAModuleServices;

  for Index := 0 to OTAModuleServices.ModuleCount - 1 do
  begin
    Module := OTAModuleServices.Modules[Index];

    if Module.FileSystem <> '' then
    begin
      if IncludeSubDirectories then
        Save := PathIsChild(Module.FileName, FileName)
      else
        Save := Module.FileName = FileName;

      if Save then
        Module.Save(False, True);
    end;
  end;  }
end;

{procedure TagMenuNamerExpert.SetIconType(const Value: TIconType);
begin
  if Value <> FIconType then
  begin
    FIconType := Value;
    RefreshIcons;
  end;
end;}

procedure TagMenuNamerExpert.SubItemClick(Sender: TObject);
var
//  APlugin: TagMenuNamerPlugin;
  AMenuItem: TMenuItem;
  AAction: TCustomAction;
  Directory, PluginName: string;
  PosSeparator, IndexPlugin: Integer;
//  ControlAction: TagMenuNamerActionType;
//  ControlActionInfo: TagMenuNamerActionInfo;
//  PluginList: TagMenuNamerPluginList;
begin
ShowMessage('SubItemClick');
  {try
    APlugin := CurrentPlugin;
    if Sender is TCustomAction then
    begin
      AAction := TCustomAction(Sender);
      ControlAction := TagMenuNamerActionType(AAction.Tag);
      Directory := AAction.Caption;
    end
    else
    if Sender is TMenuItem then
    begin
      AMenuItem := TMenuItem(Sender);
      ControlAction := TagMenuNamerActionType(AMenuItem.Tag);
      Directory := AMenuItem.Caption;
    end
    else
      Exit;

    ControlActionInfo := MenuNamerActionInfo(ControlAction);
//    Directory := StrRemoveChars(Directory, CharIsAmpersand);

    if ControlActionInfo.AllPlugins then
    begin
      PluginList := MenuNamerPluginList;
      PosSeparator := Pos('|', Directory);
    //  PluginName := StrLeft(Directory, PosSeparator - 2);
//      Directory := StrRight(Directory, Length(Directory) - PosSeparator - 1);
      for IndexPlugin := 0 to PluginList.Count - 1 do
      begin
        APlugin := TagMenuNamerPlugin(PluginList.Plugins[IndexPlugin]);
        if SameText(APlugin.Name, PluginName) then
          Break;
        APlugin := nil;
      end;

      if not Assigned(APlugin) then
        Exit;
    end;

    if ControlActionInfo.SaveFile then
      SaveModules(Directory, True);
    if Assigned(APlugin) then
      APlugin.ExecuteAction(Directory , ControlAction);
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end;  }
end;

procedure TagMenuNamerExpert.UnregisterCommands;
var
//  ControlAction: TagMenuNamerActionType;
  ADropDownAction: TDropDownAction;
begin
//  inherited UnregisterCommands;

 // Settings.SaveStrings(agVersionCtrlMenuOrganizationName, FMenuOrganization);
 // Settings.SaveBool(agVersionCtrlSaveConfirmationName, SaveConfirmation);
 // Settings.SaveBool(agVersionCtrlDisableActionsName, DisableActions);
 // Settings.SaveBool(agVersionCtrlHideActionsName, HideActions);
 // Settings.SaveBool(agVersionCtrlActOnTopSandboxName, ActOnTopSandbox);
//  case FIconType of
//    itNone:
   //   Settings.SaveString(agVersionCtrlIconTypeName, agVersionCtrlIconTypeNoIconValue);
//    itag:
//      Settings.SaveString(agVersionCtrlIconTypeName, agVersionCtrlIconTypeagIconValue);
//  end;

{  for ControlAction := Low(TagMenuNamerActionType) to High(TagMenuNamerActionType) do
  begin
//    UnregisterAction(FActions[ControlAction]);
    if FActions[ControlAction] is TDropDownAction then
    begin
      ADropDownAction := TDropDownAction(FActions[ControlAction]);
      if Assigned(ADropDownAction.DropDownMenu) then
      begin
        ADropDownAction.DropDownMenu.Items.Clear;
        ADropDownAction.DropDownMenu.Free;
        ADropDownAction.DropDownMenu := nil;
      end;
    end;
    FreeAndNil(FActions[ControlAction]);
  end;
  FVersionCtrlMenu.Clear;
  FreeAndNil(FVersionCtrlMenu);}
end;

    { IOTAWizard }
procedure TagMenuNamerExpert.Execute;
begin
end;
function TagMenuNamerExpert.GetIDString: string;
begin
  Result := 'ag.' + ClassName;
end;
    function TagMenuNamerExpert.GetName: string;
begin
  Result := ClassName;
end;
    function TagMenuNamerExpert.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TagMenuNamerExpert.AfterSave;
begin
end;
procedure TagMenuNamerExpert.BeforeSave;
begin
end;
procedure TagMenuNamerExpert.Destroyed;
begin
end;
procedure TagMenuNamerExpert.Modified;
begin
end;

function TagMenuNamerExpert.GetMenuText: string;
begin
  Result := 'ag.' + ClassName;
end;


procedure TagMenuNamerExpert.AfterConstruction;
begin
  inherited AfterConstruction;

 // RegisterCommands;
   AssignNames4Tools;

  FUpdateTimer := TTimer.Create(nil);
  FUpdateTimer.Enabled := True;
  FUpdateTimer.Interval := 5000;
  FUpdateTimer.OnTimer := OnUpdateTimer;

end;

function FindActions(const Name: string): TComponent;
var
  Index: Integer;
  TestAction: TCustomAction;
begin
  Result := nil;
  try
    if Assigned(GlobalActionList) then
      for Index := 0 to GlobalActionList.Count-1 do
      begin
        TestAction := TCustomAction(GlobalActionList.Items[Index]);
        if (CompareText(Name,TestAction.Name) = 0) then
          Result := TestAction;
      end;
  except
    on ExceptionObj: TObject do
    begin
      ShowException(ExceptionObj,0);
    end;
  end;
end;


procedure TagMenuNamerExpert.RegisterAction(Action: TCustomAction);
begin
  if not Assigned(GlobalActionList) then
  begin
    GlobalActionList := TList.Create;
    RegisterFindGlobalComponentProc(FindActions);
  end;

  GlobalActionList.Add(Action);
end;


procedure TagMenuNamerExpert.AssignNames4Tools();
var
  Index: Integer;
  Index2: Integer;
  IDEMenuItem, ToolsMenuItem: TMenuItem;
  NTAServices: INTAServices;
  Category: string;
  NewAction: TAction;
begin
  NTAServices := GetNTAServices;

    IDEMenuItem := NTAServices.MainMenu.Items;
    ToolsMenuItem := nil;
    for Index := 0 to IDEMenuItem.Count - 1 do
      if CompareText(IDEMenuItem.Items[Index].Name, 'ToolsMenu') = 0 then
        ToolsMenuItem := IDEMenuItem.Items[Index];
    if not Assigned(ToolsMenuItem) then
      raise Exception.Create('@RsENoToolsMenu');

    for Index := 0 to ToolsMenuItem.Count - 1 do
      if ToolsMenuItem.Items[Index].Name = '' then
      begin
        ToolsMenuItem.Items[Index].Name := 'ToolsMenu_Unnamed'+IntToStr(Index);
        if not Assigned(ToolsMenuItem.Items[Index].Action) then
        begin
        ///////////
          Category := '';
          for Index2 := 0 to NTAServices.ActionList.ActionCount - 1 do
           if CompareText(NTAServices.ActionList.Actions[Index2].Name, 'ToolsOptionsCommand') = 0 then
            Category := NTAServices.ActionList.Actions[Index2].Category;

    NewAction := TAction.Create(nil);
{    agIcon := TIcon.Create;
    try
      // not ModuleHInstance because the resource is in agBaseExpert.bpl
      agIcon.Handle := LoadIcon(HInstance, 'agCONFIGURE');
      NewAction.ImageIndex := NTAServices.ImageList.AddIcon(agIcon);
    finally
      agIcon.Free;
    end;}
    NewAction.Caption := ToolsMenuItem.Items[Index].Caption;
    NewAction.Name   := 'actn'+ToolsMenuItem.Items[Index].Name;
    NewAction.Category := Category;
    NewAction.Visible := True;
//    NewAction.OnUpdate := ConfigurationActionUpdate;
    NewAction.OnExecute := ToolsMenuItem.Items[Index].OnClick;
    ToolsMenuItem.Items[Index].Action := NewAction;

    RegisterAction(NewAction);
    NewAction.ActionList := NTAServices.ActionList;

        end;
      end;

end;


procedure TagMenuNamerExpert.OnUpdateTimer(Sender: TObject);
begin
  Inc(FUpdateCount);
  if FUpdateCount >= 3 then
    FUpdateTimer.Enabled := False;
  if Application.Terminated then
    Exit;
  AssignNames4Tools;
end;


end.


// http://www.gexperts.org/open-tools-api-faq/
