unit PiconeBarreTache;
//http://www.phidels.com
//Version 2.23 du 23/09/03 : restitution des valeurs des �v�nements d'origine
               //dans le destroy.
               //retrait d'un bug laissant de temps en temps la grande icone
               //visible alors que GrandeIconeVisible �tait � false
// Version 2.24 du 26/09/03 : Rajout de test dans le destroy pour �viter un bug
               //en D5 � la fermeture de d5 ou au retrait du composant
// Version 2.3 du 27/09/03  : Ajout par [SFX]-ZeuS de la d�tection d'un
              //redemarrage de l'Explorer permettant
              // � l'application de remettre son icone dans le Systray
// Version 2.4 du 5/10/03 : Ajout de lapossibilit� de d�finir l'ordre de
              //d�filement des icone (animation de la petite icone)
// Version 2.41 du 14 11 03 : retrait d'un bug qui arrivait lorsque l'on
              //essayait d'affecter un hint sup�rieur � 64 Octets
// Version 2.42 du 16/11/03 : Ajout de la proc�dure RegenerePetiteIcone.
              // et retir� le bug qui faisait que lorsque l'on mettait la fiche
              // � FsStayOnTop, la petite icone disparaissait.
// Version 2.43 du 20/02/04: retir� le fait que l'icone pouvait se d�placer
              //lorsque l'on fait un clic droit dessus.
// Version 2.44 du 10/04/2005 retir� le bug arrivnat si quelqu'un faisait un free
           //du popmenu attach� � ce composant (ajout de la proc�durenotification)

{$IFNDEF VER130} { Delphi 5.0 }
  {$IFNDEF VER90} { Delphi 2.0 }
    {$IFNDEF VER100} { Delphi 3.0 }
      {$IFNDEF VER120} { Delphi 4.0 }
        {$DEFINE VER_D6OuPlus}  //pour pouvoir plus bas dans le code compiler
                                //diff�remment si on est en D6 ou plus
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   Menus, extctrls, ShellAPI;


Const WM_MYMESSAGE=WM_USER+100; // num�ro de message utilis� plus bas.

type ExceptionNumsImageLIstAffiche = class(Exception);

type
  // Seul un objet poss�dant un Handle peut recevoir les messages souris lorsque l'on
  // passe ou clique sur l'icone (affichage du Hint ou du menu pop)
  // C'est le cas d'un TWinControl mais pas d'un TComponent
  // On aurait pu d�river TPiconeBarreTache directement d'un TWinControl
  // et ainsi b�n�ficier par h�ritage d'un Handle
  // mais lorsque l'on pose le composant sur la fiche, un twinControl ne se voit pas (ou presque)
  // C'est le Handle de PourHandle de type TPourHandle qui sera donn� � Windows comme devant recevoir les messages
  // ainsi, A chaque fois que Windows aura un message � emettre caus� par le passage de la souris
  // au dessus de l'icone ou par un clique de souris sur l'icone, la proc�dure TrayMessage sera ainsi d�clench�e.

  TPourHandle =class(TWinControl)
  private
    procedure TrayMessage(var Msg: TMessage); message WM_MYMESSAGE;
    // cette proc�dure sera d�clench�e � chaque fois que Windows envera un message de type WM_MYMESSAGE
  end;

  TPiconeBarreTache = class(TComponent)
  private
    WM_TASKBARCREATED   : Longint; // Messages de cr�ations de la barre des tache
    FMenuPop            : TPopupMenu;
    FReduireSiFin       : Boolean;
    FCacherSiMinimize   : Boolean;
    FGrandeIconeVisible : Boolean;
    FPetiteIconeVisible : Boolean;
    FApplicationCachee  : Boolean;
    FIcone              : TIcon;
    FHint               : string;
    NotifyStruc         : TNotifyIconData; // "structure" de l'ic�ne
    PourHandle          : TPourHandle;// composant de type TWinControl uniquement pour se servir de son Handle
    PetiteIconeAffichee : Boolean;// indique en permanence si la petite icone est affich�e
    DejaLoaded          : Boolean;
    FIconeFileName      : TFileName;//indique si on est d�j� pass� dans la procedure loaded
    TimerGrandeIconeBlink  : TTimer;
    TimerAnimationPetiteIcone : TTimer;
    FIntervalGrandeIconeBlink: Integer;
    FGrandeIconBlink: Boolean;
    FOnMouseUp          : TMouseEvent;
    FOnMouseDown        : TMouseEvent;
    FOnMouseMove        : TMouseMoveEvent;
    FOuvreSiClicGauche  : Boolean;
    FImageList          : TImageList;
    FIntervalAnimation  : Integer;
    FAnimation          : Boolean;
    FNumIconeAfficheImageList: Integer;
    FNumIconeImageList: Integer;
    FOnDblClick: TNotifyEvent;
    FOuvreSiDblClick       : Boolean;
    FMenuSiClicGauche      : Boolean;
    FMenuSiClicDroit       : Boolean;
    FOrdreImageListAffiche  : String;  // contient le n� des images � faire d�filer (ex : 1,2,4,5)
    NbNumOrdreImageListAffiche : Integer; // nombre de n� d'image contenu dans FOrdreImageListAffiche
    NumImageListAffiche    : Integer; // contient le n ieme de FOrdreImageListAffiche correspondant � l'imge affich�
    procedure TimerBigIconeOnTimer(Sender: TObject);
    procedure TimerAnimationPetiteIconeOnTimer(Sender: TObject);
    procedure SetReduireSiFin(const Value: Boolean);
    procedure SetGrandeIconeVisible(const Value: Boolean);
    procedure SetPetiteIconeVisible(const Value: Boolean);
    procedure SetApplicationCachee(const Value: Boolean);
    procedure SetIcone(const Value: TIcon);
    procedure SetHint(const Value: string);
    procedure SetIconeFileName(const Value: TFileName);
    procedure SetIntervalGrandeIconeBlink(const Value: Integer);// interval de temps pour clignotement
    procedure SetGrandeIconBlink(const Value: Boolean);
    procedure SetAnimation(const Value: Boolean);
    procedure SetIntervalAnimation(const Value: Integer);
    procedure SetNumIconeAfficheImageList(const Value: Integer);
    procedure SetNumIconeImageList(const Value: Integer);
    procedure SetOrdreImageListAffiche(const Value: String);
  protected
    PApplicationOldWndProc            : Longint; // Pointer sur Application.WndProc d'origine
    PObjectInstanceApplicationWndProc : Longint;
    FormAOwner:TForm;
    FormOldClose             :TCloseEvent;
    ApplicationOldActivate   :TNotifyEvent;
    ApplicationOldOnMinimize :TNotifyEvent;
    EtatFsStayOnTop:TFormStyle;// pour pouvoir controler quand la fiche change de FormStyle
    procedure LaFormClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplicationActivate(Sender: TObject);
    procedure ApplicationMinimize(Sender: TObject);
    procedure loaded; override;
    procedure ApplicationWndProc(var Message: TMessage);
  public
    procedure CacherApplication;
    procedure MontrerApplication;
    //n� dans la liste de l'icone qui est affich�e. (change au cours de l'animation)
    Property NumIconeAfficheImageList : Integer read FNumIconeAfficheImageList write SetNumIconeAfficheImageList;
    Constructor Create(AOwner:TComponent); override;
    destructor destroy; override;
    procedure RegenerePetiteIcone;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  published
    Property MenuPop:TPopupMenu read FMenuPop write FMenuPop;
    Property ReduireSiFin      : Boolean    read FReduireSiFin       write SetReduireSiFin;
    Property CacherSiMinimize  : Boolean    read FCacherSiMinimize   write FCacherSiMinimize;
    Property PetiteIconeVisible: Boolean    read FPetiteIconeVisible write SetPetiteIconeVisible;
    Property GrandeIconeVisible: Boolean    read FGrandeIconeVisible write SetGrandeIconeVisible;
    Property ApplicationCachee : Boolean    read FApplicationCachee  write SetApplicationCachee;
    Property IconeFileName     : TFileName  read FIconeFileName      write SetIconeFileName;
    Property Icone             : TIcon      read FIcone write SetIcone;
    Property ImageList         : TImageList read FImageList write FImageList;
    property OrdreImageListAffiche : String read FOrdreImageListAffiche write SetOrdreImageListAffiche;
    Property IntervalAnimation :Integer     read FIntervalAnimation write SetIntervalAnimation;
    Property Animation         : Boolean    read FAnimation write SetAnimation;
    //N� de l'icone que l'utilisateur veut voir afficher. Ne change pas au cours de l'animation.
    Property NumIconeImageList : Integer    read FNumIconeImageList write SetNumIconeImageList;
    Property Hint              : string     read FHint  write SetHint;
    Property GrandeIconBlink   : Boolean    read FGrandeIconBlink write SetGrandeIconBlink; // clignotement grande Icone
    Property IntervalGrandeIconeBlink:Integer read FIntervalGrandeIconeBlink write SetIntervalGrandeIconeBlink;
    Property OuvreSiClicGauche : Boolean   read FOuvreSiClicGauche write FOuvreSiClicGauche;
    Property OuvreSiDblClick   : Boolean   read FOuvreSiDblClick  write FOuvreSiDblClick;
    Property MenuSiClicDroit   : Boolean   read FMenuSiClicDroit  write FMenuSiClicDroit;// ouvre menu si clic droit
    Property MenuSiClicGauche  : Boolean   read FMenuSiClicGauche write FMenuSiClicGauche;// ouvre menu si clic gauche
    property OnMouseUp   : TMouseEvent     read FOnMouseUp   write FOnMouseUp;
    property OnMouseDown : TMouseEvent     read FOnMouseDown write FOnMouseDown;
    property OnMouseMove : TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnDblClick  : TNotifyEvent    read FOnDblClick  write FOnDblClick;

  end;

// d�claration pour l'utilisation de l'PAI  FlashWindowEx
FLASHWINFO = record
  cbSize: UINT;
  hwnd: HWND;
  dwFlags: DWORD;
  uCount: UINT;
  dwTimeout: DWORD;
end;



procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Phidels', [TPiconeBarreTache]);
end;

procedure TPiconeBarreTache.Notification(AComponent: TComponent; Operation: TOperation);
begin
      inherited Notification(AComponent, Operation);
      if Operation = opRemove then
      begin
          if AComponent = FMenuPop   then MenuPop   := nil;
          if AComponent = FImageList then ImageList := nil;
      end;
end;

procedure StopFlash;
{ arr�te le clignotement de la grande icone }
{ FlashWindow fonctionne mal en XP mais FlashWindowEx ne fonctionne pas 'd'apr�s l'aide en Win 95}
var pfwi: FLASHWINFO;
    hdll : HMODULE;
    FlashWindowEx: function(var pfwi: FLASHWINFO): BOOL; stdcall;
begin
  hDLL:=LoadLibrary('user32.dll'); // chargement de la dll
  if hDLL<>0 then
  begin
// affectation de la fonction somme de la dll � la fonction somme de notre programme
    @FlashWindowEx:=GetProcAddress(hDLL,'FlashWindowEx');
    if @FlashWindowEx<>nil then
    begin
      pfwi.cbSize:=sizeof(pfwi);
      pfwi.hwnd:=application.handle;
      pfwi.dwFlags:=FLASHW_STOP;
      pfwi.uCount:=0;
      FlashWindowEx(pfwi);
    end
    else FlashWindow(application.handle, False); // Win 95 ne connait pas FlashWindowEx
    FreeLibrary(hDLL);//lib�ration. La Dll n'est plus utilisable
  end
  else FlashWindow(application.handle, False);
end;

Constructor TPiconeBarreTache.Create(AOwner:TComponent);
begin
  FIcone:=TIcon.create;
  PourHandle:=TPourHandle.Create(self);
  PourHandle.Parent:=TWinControl(AOwner); // en r�alit� AOwner est la fiche sur laquelle on a pos� le composant.
  PetiteIconeAffichee:=false;
  DejaLoaded:=false;
  TimerGrandeIconeBlink:=TTimer.Create(Self);
  TimerGrandeIconeBlink.Enabled:=false;
  TimerGrandeIconeBlink.OnTimer:=TimerBigIconeOnTimer;
  TimerAnimationPetiteIcone:= TTimer.Create(Self);
  TimerAnimationPetiteIcone.Enabled:=false;
  TimerAnimationPetiteIcone.OnTimer:=TimerAnimationPetiteIconeOnTimer;
  Inherited;
  if (csDesigning in ComponentState) then // si on est en mode conception
  begin
    FOuvreSiClicGauche  :=True;
    FMenuSiClicDroit    :=True;
    FMenuSiClicGauche   :=False;
    FReduireSiFin       :=False;
    FPetiteIconeVisible :=True;
    FGrandeIconeVisible :=True;
    FApplicationCachee  :=False;
    FOuvreSiDblClick    :=False;
    FCacherSiMinimize   :=False;
    FIntervalGrandeIconeBlink:=1000;//interval pour clignotement grande icone
    FGrandeIconBlink:=False;// Clignotement inactif
    FIntervalAnimation:=1000;
    FImageList:=nil;
    FNumIconeAfficheImageList:=0;
    FAnimation:=False;
  end
  else //si on est pas en mode conception
  begin
    FIcone.Assign(Application.Icon);
    FormAOwner:=TForm(AOwner);// la forme propri�taire de notre composant
    FormOldClose          :=FormAOwner.OnClose; //on m�morise le OnClose d'origine de fa�on � pouvoir le d�clencher lorsqu'on le d�sirera
    FormAOwner.OnClose    :=LaFormClose; // on redirige l'�v�nement OnClose vers LaFormShow
    ApplicationOldActivate:= Application.OnActivate;// on m�morise le OnActivate d'origine
    Application.OnActivate:=ApplicationActivate;// on redirige l'�v�nement OnActivate de l'application
    ApplicationOldOnMinimize:=Application.OnMinimize;// idem mais pour OnMinimize
    Application.OnMinimize:=ApplicationMinimize;

    WM_TASKBARCREATED:=RegisterWindowMessage('TaskbarCreated'); // demande l'enregistement du message de cr�ation de la barre des taches
    PApplicationOldWndProc := GetWindowLong(Application.Handle, GWL_WNDPROC); //On m�morise Application.WndProc


    {$IFDEF VER_D6OuPlus}
      PObjectInstanceApplicationWndProc := LongInt(Classes.MakeObjectInstance(ApplicationWndProc));
    {$ELSE}
      PObjectInstanceApplicationWndProc := LongInt(MakeObjectInstance(ApplicationWndProc));
     {$ENDIF}

    // remplacement de l'ancien WndProc par le notre (ApplicationWndProc)
    SetWindowLong(Application.Handle, GWL_WNDPROC, PObjectInstanceApplicationWndProc);
  end;
end;

procedure TPiconeBarreTache.RegenerePetiteIcone;
{place l'icone dans la barre des t�ches.                                                    }
{est appel� au d�part par la proc�dure loaded et peut �tre appel� lorsque l'icone a disparu }
{ suite � un FsStayOntop de la Form                                                         }
begin
  if not(csDesigning in ComponentState) then // si on est pas en mode conception
  begin
    notifyStruc.cbSize:=SizeOf(NotifyStruc);
    notifyStruc.Wnd:=PourHandle.Handle;
    notifyStruc.uID:=1;
    NotifyStruc.uFlags := NIF_ICON or NIF_TIP or NIF_MESSAGE;
    NotifyStruc.uCallbackMessage := WM_MYMESSAGE;
    // choix de l'icone � afficher
    NotifyStruc.hIcon :=Ficone.Handle;
   // DejaLoaded:=true;
    if PetiteIconeVisible then
    begin
      Shell_NotifyIcon(NIM_ADD,@NotifyStruc);//ajoute la petite ic�ne dans la barre des taches
      PetiteIconeAffichee:=true;
    end;
  end;
end;

procedure TPiconeBarreTache.loaded;
//loaded est appel�e automatiquement par Delphi lorsque tous les cr�ate ont eu lieu
begin
  inherited;
  if not(csDesigning in ComponentState) then
  begin
    EtatFsStayOnTop:=FormAOwner.FormStyle;
    RegenerePetiteIcone;
    DejaLoaded:=true;
    { permet l'affichage de l'icone de la liste qu'a choisi l'utilisateur si la liste existe}
    { ne peut �tre mis dans le create car trop t�t}
    NumIconeAfficheImageList:=FNumIconeImageList;
  end;
end;


procedure TPiconeBarreTache.ApplicationActivate(Sender: TObject);
{on a redirig� l'�v�nement application.onActivate vers cette proc�dure    }
{ car le ShowWindow ci dessous ne peut �tre fait dans le loaded (trop tot)}
begin
  if not(csDesigning in ComponentState) then // si on est en mode ex�cution
  begin
    if assigned(ApplicationOldActivate)then ApplicationOldActivate(Sender);
    if not FGrandeIconeVisible then  ShowWindow(Application.Handle, SW_HIDE); // retirer la grande ic�ne de la barre des t�ches
  end;
end;


procedure TPiconeBarreTache.LaFormClose(Sender: TObject; var Action: TCloseAction);
// proc�dure appel�e � chaque form.close (d�tournement)
begin
  if assigned(FormOldClose)then FormOldClose(Sender,Action);
  if FReduireSiFin then
  begin
    ShowWindow(Application.Handle, SW_HIDE); // retirer la grande ic�ne de la barre des t�ches
    FormAOwner.Visible:=false; //cacher la fiche
    Action:=caNone;
  end;
end;


procedure TPiconeBarreTache.ApplicationWndProc(var Message: TMessage);
begin
// s'il y a eu cr�ation d'une nouvelle taskbarre on recharge la petite icone
  if Longint(Message.Msg) = WM_TASKBARCREATED then RegenerePetiteIcone;//loaded;

///////// il faut reg�n�rer l'icone si on a mis la fiche en FsStayOnTop ////////
  if (Longint(Message.Msg) =WM_WINDOWPOSCHANGING) and  PetiteIconeAffichee
  and  (EtatFsStayOnTop<>FormAOwner.FormStyle) then
  begin
    Shell_NotifyIcon(NIM_DELETE,@NotifyStruc);//retire la petite ic�ne de la barre des taches
      //si on ne le fait pas, on peut se retrouver avec 2 icones dont une qui s'efface lorsque
      //l'on passe la souris dessus;
  end;
// puis on fait suivre le message � l'application.
  Message.Result := CallWindowProc(Pointer(PApplicationOldWndProc), Application.Handle,
                                         Message.Msg, Message.wParam, Message.lParam);
  if (Longint(Message.Msg) =WM_WINDOWPOSCHANGING) and  PetiteIconeAffichee
  and  (EtatFsStayOnTop<>FormAOwner.FormStyle) then
  begin
     RegenerePetiteIcone;// il faut reg�n�rer l'icone si on a mis la fiche en FsStayOnTop
     EtatFsStayOnTop:=FormAOwner.FormStyle;// on m�morise le nouvel �tat afin de pouvoir voir lorsqu'il change
  end;
end;


Destructor TPiconeBarreTache.Destroy;
begin
  if PetiteIconeAffichee then
  begin
    Shell_NotifyIcon(NIM_DELETE,@NotifyStruc);//retire la petite ic�ne de la barre des taches;
    PetiteIconeAffichee:=false;
  end;
  FIcone.Free;  FIcone:=nil;
  // on ne met pas de PourHandle.free car son Owner est la fiche sur laquelle le composant est plac�.
  // ainsi, PourHandle sera d�truit lorsque la fiche le sera.
  if not(csDesigning in ComponentState) then // si on est pas en mode conception
  begin
    if FormAOwner<>nil then FormAOwner.OnClose :=  FormOldClose ;// on restitue les valeurs d'origine
    Application.OnActivate := ApplicationOldActivate ;  // on restitue le OnActivate d'origine
    Application.OnMinimize := ApplicationOldOnMinimize;// idem mais pour OnMinimize

    // avant de d�truire le composant, on "rebranche" le WndProc de l'application comme � l'origine
    if PApplicationOldWndProc<>0 then SetWindowLong(Application.Handle, GWL_WNDPROC, LongInt(PApplicationOldWndProc)); // redonne la main � l'application pour les messages entrant
  {$IFDEF VER_D6OuPlus}
    if PObjectInstanceApplicationWndProc<>0 then classes.FreeObjectInstance(Pointer(PObjectInstanceApplicationWndProc));
  {$ELSE}
    if PObjectInstanceApplicationWndProc<>0 then FreeObjectInstance(Pointer(PObjectInstanceApplicationWndProc));
  {$ENDIF}
    PApplicationOldWndProc := 0;
    PObjectInstanceApplicationWndProc := 0;
  end;
  Inherited ;
end;



procedure TPIconeBarreTache.CacherApplication;
begin
  ShowWindow(Application.Handle, SW_HIDE); // retirer la grande ic�ne de la barre des t�ches
  if Application.MainForm<>nil then
  begin
    Application.MainForm.Visible:=false;
  end
  else Application.ShowMainForm :=false;// en fait le programme est en cours d'ouverture
end;

procedure TPIconeBarreTache.MontrerApplication;
begin
  if Application.MainForm<>nil then
  begin
    Application.Restore;
    Application.MainForm.Visible:=true;
    Application.MainForm.Refresh; 
    SetGrandeIconeVisible(FGrandeIconeVisible);//remet la grande icone visible
              //si la propri�t� GrandeIconeVisible est � true.
    SetForegroundWindow(Application.MainForm.Handle);
  end;
end;

procedure TPiconeBarreTache.ApplicationMinimize(Sender: TObject);
{procedure d�clench�e � chaque fois que l'application se minimize}
{ c'est un d�tournement de application.OnMinimize                }
begin
  if assigned(ApplicationOldOnMinimize) then ApplicationOldOnMinimize(Sender);
  if CacherSiMinimize then ShowWindow(Application.Handle, SW_HIDE); // retirer la grande ic�ne de la barre des t�ches
end;


procedure TPourHandle.TrayMessage(var Msg: TMessage);// message WM_MYMESSAGE;
{cette proc�dure est d�clench�e � chaque fois que la souris est sur l'icone ou
 � chaque fois que l'on clique sur l'icone}
var
  Coordonnes_souris :TPoint;
begin
  GetCursorPos(Coordonnes_souris);//r�cup�ration de la position de la souris
  // d�clenchement des �v�nements souris
  // Owner est en r�alit� le TPIconeBarreTache
  Case Msg.LParam of
     WM_RBUTTONDOWN : if Assigned(TPiconeBarreTache(Owner).FOnMouseDown) then
                        TPiconeBarreTache(Owner).FOnMouseDown(Owner, mbRight,
                        [ssRight] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_LBUTTONDOWN : if Assigned(TPiconeBarreTache(Owner).FOnMouseDown) then
                        TPiconeBarreTache(Owner).FOnMouseDown(Owner, mbLeft,
                        [ssLeft] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_MBUTTONDOWN : if Assigned(TPiconeBarreTache(Owner).FOnMouseDown) then
                        TPiconeBarreTache(Owner).FOnMouseDown(Owner, mbMiddle,
                        [ssMiddle] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_RBUTTONUP   : if Assigned(TPiconeBarreTache(Owner).FOnMouseUp) then
                        TPiconeBarreTache(Owner).FOnMouseUp(Owner, mbRight,
                        [ssRight] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_LBUTTONUP   : if Assigned(TPiconeBarreTache(Owner).FOnMouseUp) then
                        TPiconeBarreTache(Owner).FOnMouseUp(Owner, mbLeft,
                        [ssLeft] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_MBUTTONUP   : if Assigned(TPiconeBarreTache(Owner).FOnMouseUp) then
                        TPiconeBarreTache(Owner).FOnMouseUp(Owner, mbMiddle,
                        [ssMiddle] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_MOUSEMOVE   : if Assigned(TPiconeBarreTache(Owner).FOnMouseMove) then
                        TPiconeBarreTache(Owner).FOnMouseMove(Owner,
                        [ssLeft] , Coordonnes_souris.X, Coordonnes_souris.y);
     WM_LBUTTONDBLCLK : if Assigned(TPiconeBarreTache(Owner).FOnDblClick) then
                        TPiconeBarreTache(Owner).FOnDblClick(Owner);  
  end;
  if (Msg.LParam=WM_LBUTTONDOWN) and (TPiconeBarreTache(Owner).FOuvreSiClicGauche) then TPiconeBarreTache(Owner).ApplicationCachee:=False;
  if (Msg.LParam=WM_LBUTTONDBLCLK) and (TPiconeBarreTache(Owner).FOuvreSiDblClick) then TPiconeBarreTache(Owner).ApplicationCachee:=False;


  if ((Msg.LParam=WM_RBUTTONDOWN) and TPiconeBarreTache(Owner).FMenuSiClicDroit and Assigned(TPiconeBarreTache(Owner).MenuPop))
    or ((Msg.LParam=WM_LBUTTONDOWN) and TPiconeBarreTache(Owner).FMenuSiClicGauche and Assigned(TPiconeBarreTache(Owner).MenuPop))
  then
  begin
      SetForegroundWindow(Application.Handle);
      Application.ProcessMessages;
      TPiconeBarreTache(Owner).MenuPop.Popup(coordonnes_souris.x,coordonnes_souris.y); //affichage du menu  }
  end;
end;


procedure TPiconeBarreTache.SetReduireSiFin(const Value: Boolean);
begin
  FReduireSiFin := Value;
end;

procedure TPiconeBarreTache.SetGrandeIconeVisible(const Value: Boolean);
begin
  FGrandeIconeVisible := Value;
  if not(csDesigning in ComponentState) then // si on est en mode execution
  begin
    if FGrandeIconeVisible then  ShowWindow(Application.Handle, SW_SHOW)// affiche la grande icone de la barre des taches
    else  ShowWindow(Application.Handle, SW_HIDE); // retirer la grande ic�ne de la barre des t�ches
  end;
end;

procedure TPiconeBarreTache.SetPetiteIconeVisible(const Value: Boolean);
begin
  if FPetiteIconeVisible<>Value then // si �a a chang�
  begin
    FPetiteIconeVisible := Value;
    if not(csDesigning in ComponentState)and DejaLoaded then // si on est en mode execution
    begin
      if  FPetiteIconeVisible and not PetiteIconeAffichee then
      begin
        notifyStruc.cbSize:=SizeOf(notifyStruc);
        notifyStruc.Wnd:=PourHandle.Handle;
        notifyStruc.uID:=1;
        NotifyStruc.uFlags := NIF_ICON or NIF_TIP or NIF_MESSAGE;
        NotifyStruc.uCallbackMessage := WM_MYMESSAGE;
        NotifyStruc.hIcon :=  FIcone.Handle;
        Shell_NotifyIcon(NIM_ADD,@NotifyStruc);//ajoute la petite ic�ne dans la barre des taches
        PetiteIconeAffichee:=true;
      end
      else
      begin
        if PetiteIconeAffichee then Shell_NotifyIcon(NIM_DELETE,@NotifyStruc);
        PetiteIconeAffichee:=false;
      end;
    end;//fin si on est en mode ex�cution
  end; // fin si �a a chang�
end;

procedure TPiconeBarreTache.SetApplicationCachee(const Value: Boolean);
{ d�termine si l'application est cach�e ou non }
begin
  FApplicationCachee := Value;
// si on est en mode execution
  if not(csDesigning in ComponentState) then
  begin
    if FApplicationCachee then CacherApplication
    else MontrerApplication;
  end;
end;

procedure TPiconeBarreTache.SetIcone(const Value: TIcon);
begin
  FIcone.Assign(Value);
 if not(csDesigning in ComponentState) then // si on est en mode execution
  begin
    if assigned(Ficone) then NotifyStruc.hIcon :=Ficone.Handle
      else NotifyStruc.hIcon :=application.Icon.Handle;
    if PetiteIconeAffichee then Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);
  end;
end;



procedure TPiconeBarreTache.SetHint(const Value: string);
var j,Len:integer;
begin
  FHint := Value;
  Len := Length(Value);
  if Len>=Length(NotifyStruc.szTip) then Len := Length(NotifyStruc.szTip)-1;
  if not(csDesigning in ComponentState) then // si on est en mode execution
  begin
     for j:=0 to Len-1 do NotifyStruc.szTip[j] := FHint[j+1];
     NotifyStruc.szTip[Len]:=#0;
     if PetiteIconeAffichee then Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);
  end;
end;



procedure TPiconeBarreTache.SetIconeFileName(const Value: TFileName);
  var UneIcone:TIcon;
begin
  FIconeFileName := Value;
  if not(csDesigning in ComponentState) then // si on est en mode execution
  begin
    if FIconeFileName<>'' then
    begin
      UneIcone:=TIcon.Create;
      try
        UneIcone.LoadFromFile(FIconeFileName);
        Icone:=UneIcone;
      Finally
        UneIcone.Free;
      end;
    end;
  end;// fin si on est en mode execution
end;


{=============================================================}
{partie de code concernant le clignotement de la grande icone }
{=============================================================}

procedure TPiconeBarreTache.TimerBigIconeOnTimer(Sender: TObject);
begin
  FlashWindow(application.handle, True);// fait passer d'un �tat � un autre
end;

procedure TPiconeBarreTache.SetIntervalGrandeIconeBlink(
  const Value: Integer);
{d�termine la fr�quence du clignotement}
begin
  FIntervalGrandeIconeBlink := Value;
  TimerGrandeIconeBlink.Interval:= FIntervalGrandeIconeBlink;
end;

procedure TPiconeBarreTache.SetGrandeIconBlink(const Value: Boolean);
{d�termine si la grande icone doit clignoter }
begin
  FGrandeIconBlink := Value;
  if not(csDesigning in ComponentState) then
  begin
     TimerGrandeIconeBlink.Enabled:= FGrandeIconBlink;
     //if not FGrandeIconBlink then FlashWindow(application.handle, False);
     if not FGrandeIconBlink then StopFlash;
  end;
end;




{========================================================}
{partie de code concernant l'animation de la petite icone }
{ et l'affichage � partir de ImageList                   }
{========================================================}

procedure TPiconeBarreTache.SetNumIconeAfficheImageList(const Value: Integer);
{Affiche une icone � partir de ImageList }
  var IconeTemp:Ticon;
begin
  FNumIconeAfficheImageList := Value;
  if assigned(FImageList) then
  begin
    if FNumIconeAfficheImageList in [0..FImageList.count-1] then
    begin
      IconeTemp:=TIcon.create;
      try
        FImageList.GetIcon(FNumIconeAfficheImageList,IconeTemp);
        Icone:=IconeTemp;
      Finally
        IconeTemp.free;
      end;
    end;
  end;
end;


function GaucheNDroite(substr: string; s: string;n:integer): string;
{==============================================================================}
{ renvoie ce qui est � gauche de la droite de la n ieme sous chaine substr     }
{ de la chaine S                                                               }
{ ex : GaucheNDroite('/','c:machin\truc\essai.exe',1) renvoie 'truc'           }
{ Permet d'extraire un � un les �l�ments d'une chaine s�par�s par un s�parateur}
{==============================================================================}
var i:integer;
begin
  S:=S+substr;
  for i:=1 to n do
  begin
    S:=copy(s, pos(substr, s)+length(substr), length(s)-pos(substr, s)+length(substr));
  end;
  result:=copy(s, 1, pos(substr, s)-1);
end;


procedure TPiconeBarreTache.TimerAnimationPetiteIconeOnTimer(
  Sender: TObject);
{g�re l'animation en faisant successivement passer les icones les unes apr�s les autres}
begin
  if assigned(FImageList) then
  begin
    if  NbNumOrdreImageListAffiche=0 then // alors on prend les images de FImageList dans l'ordre o� elles y sont stock�es
    begin
      if FImageList.count<>0 then
      begin
        if FNumIconeAfficheImageList<FImageList.Count-1 then
           NumIconeAfficheImageList:=FNumIconeAfficheImageList+1
        else NumIconeAfficheImageList:=0;
      end;
    end
    else // si NbNumsImageListAffiche est diff�rent de 0 alors on ne prend que les imges d�crites par NumsImageListAffiche

    begin
      if FImageList.count<>0 then
      begin
        // on parcourt chacun leur tour les n� contenu dans  NumsImageListAffiche
        //  NumImageListAffiche contient le rang dans NumsImageListAffiche du n� de l'image contenu dans la liste � afficher
        NumImageListAffiche:=NumImageListAffiche+1;
        if NumImageListAffiche >NbNumOrdreImageListAffiche-1 then NumImageListAffiche:=0;
        NumIconeAfficheImageList:=StrToIntDef(GaucheNDroite(',',OrdreImageListAffiche,NumImageListAffiche),0);
        if NumIconeAfficheImageList>=FImageList.Count-1 then NumIconeAfficheImageList:=FImageList.Count-1;
      end;
    end;
  end;
end;

procedure TPiconeBarreTache.SetAnimation(const Value: Boolean);
{D�termine si l'animation doit se faire ou non}
begin
  FAnimation := Value;
  if not(csDesigning in ComponentState) then
  begin
    TimerAnimationPetiteIcone.Enabled:=FAnimation;
    if not FAnimation then NumIconeAfficheImageList:=NumIconeImageList;// remise � 0 de l'animation
  end;
end;

procedure TPiconeBarreTache.SetIntervalAnimation(const Value: Integer);
{d�termine l'intervale entre deux affichage d'icone pour l'animation}
begin
  FIntervalAnimation := Value;
  TimerAnimationPetiteIcone.Interval:=FIntervalAnimation;
end;

procedure TPiconeBarreTache.SetNumIconeImageList(const Value: Integer);
begin
  FNumIconeImageList := Value;
  if not Animation then NumIconeAfficheImageList:=FNumIconeImageList;
end;

function droite(substr: string; s: string): string;
begin
  if pos(substr,s)=0 then result:='' else
    result:=copy(s, pos(substr, s)+length(substr), length(s)-pos(substr, s)+length(substr));
end;

function NbSousChaine(substr: string; s: string): integer;
{==================================================================================}
{ renvoie le nombre de fois que la sous chaine substr est pr�sente dans la chaine S}
{==================================================================================}
begin
  result:=0;
  while pos(substr,s)<>0 do
  begin
    S:=droite(substr,s);
    inc(result);
  end;
end;


procedure TPiconeBarreTache.SetOrdreImageListAffiche(const Value: String);
var i:integer;
begin
  for i:=1 to Length(Value) do
  begin
    if not (Value[i] in ['0'..'9', ',']) then raise(ExceptionNumsImageLIstAffiche.Create('Erreur dans PiconeBarreTache : Mauvaise entr�e dans NumsImageListAffiche. Mettre les num�ros des images de la liste (ImageList) que vous voulez voir d�filer s�par�s par des virgules'));
  end;
  if Value='' then NbNumOrdreImageListAffiche :=0 else NbNumOrdreImageListAffiche:=NbSousChaine(',',Value)+1;
  FOrdreImageListAffiche := Value;
end;

end.

