extends Control
# Instrument canvas uses a 1280x720 logical frame, matching project stretch settings.
const INK=Color("09191f")
const ICE=Color("cee0dd")
const MUTED=Color("8ea5a4")
const ACCENT=Color("e4ed98")
const CYAN=Color("7fc8c8")
var game
var mode:="foot"
var toast:=""
var toast_left:=0.0
var previous_message:=""
var transition:=0.0
var heading_font: Font
var mono: Font=ThemeDB.fallback_font

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    heading_font=load("res://assets/fonts/BarlowCondensed-SemiBold.ttf") if ResourceLoader.exists("res://assets/fonts/BarlowCondensed-SemiBold.ttf") else mono
    if ResourceLoader.exists("res://assets/fonts/IBMPlexMono-Regular.ttf"):mono=load("res://assets/fonts/IBMPlexMono-Regular.ttf")

func update_view(delta: float=0.0167) -> void:
    if mode!=Session.state.mode:mode=Session.state.mode;transition=1.8
    transition=maxf(0,transition-delta)
    if game.message!=previous_message:
        previous_message=game.message;toast=game.message;toast_left=7
    toast_left=maxf(0,toast_left-delta)
    visible=not game.panel.visible
    queue_redraw()

func word(value: String,x: float,y: float,px: int=16,color: Color=ICE,headline: bool=false) -> void:
    draw_string(heading_font if headline else mono,Vector2(x+1,y+1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,Color(0.02,0.055,0.065,.9))
    draw_string(heading_font if headline else mono,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func plate(x: float,y: float,w: float,h: float) -> void:
    draw_style_box(panel_style(Color(0.025,0.065,0.08,.88)),Rect2(x,y,w,h))
func bar(x: float,y: float,w: float,value: float,color: Color=ACCENT) -> void:
    draw_rect(Rect2(x,y,w,3),Color(.45,.6,.6,.25))
    draw_rect(Rect2(x,y,w*clampf(value,0,1),3),color)
func _draw() -> void:
    if game==null:return
    var s: Dictionary=Session.state
    var color: Color=CYAN if mode=="drone" else ACCENT
    # Fine edge shading protects text without an opaque full-screen overlay.
    for i in range(60):
        var alpha:=.75*pow(1.0-float(i)/60,1.4)
        draw_rect(Rect2(0,i*3,1280,3),Color(.015,.045,.06,alpha))
        draw_rect(Rect2(0,720-i*3,1280,3),Color(.015,.045,.06,alpha))
    word("GRIDRUNNER",32,48,30,ICE,true)
    word("GHOST SIGNAL  /  BLACK CREEK" if s.leg==1 else "GHOST SIGNAL  /  LEG %02d" % s.leg,33,67,11,MUTED)
    var bearing:=fposmod(-rad_to_deg(game.yaw),360)
    for j in range(-4,5):
        var tick:=fposmod(floor(bearing/15)*15+j*15,360)
        var dx:=wrapf(tick-bearing,-180,180)*3
        draw_line(Vector2(640+dx,29),Vector2(640+dx,35),MUTED,1)
        if int(tick)%45==0:
            var cardinal: String={0:"N",90:"E",180:"S",270:"W"}.get(int(tick),str(int(tick)))
            word(cardinal,633+dx,53,13,color)
    draw_colored_polygon(PackedVector2Array([Vector2(635,18),Vector2(645,18),Vector2(640,24)]),color)
    word("%03d°" % int(bearing),621,76,13,ICE)
    word("SCOUT-01 / FPV" if mode=="drone" else "E-DRIVE / ACTIVE" if mode=="bike" else "FIELD / ON FOOT",1050,40,18,color,true)
    word("H  "+str(game.profile().label).to_upper(),1030,60,11,MUTED)
    if mode=="foot":
        word("FIELD STATUS",34,604,12,MUTED)
        word("%03d" % int(s.hp),34,643,36,ICE,true);word("VITAL",92,641,12,MUTED)
        bar(34,655,116,s.hp/100.0)
        var hand: String=s.slice02.equipped.get("hand","")
        word("HAND / "+(str(Session.content.items[hand].name).to_upper() if Session.content.items.has(hand) else "FREE"),180,618,14,ICE)
        word("PACK  %.1f / 40 kg" % Session.mass(s.inv),180,643,13,MUTED)
        bar(180,655,158,Session.mass(s.inv)/40.0,CYAN)
    elif mode=="bike":
        plate(440,547,400,135)
        draw_arc(Vector2(515,618),48,PI*.82,PI*2.18,64,Color(.3,.4,.4,.5),4,true)
        draw_arc(Vector2(515,618),48,PI*.82,PI*.82+PI*1.36*clampf(absf(game.speed)/25,0.001,1),64,ACCENT,4,true)
        word("%02d" % int(absf(game.speed)*3.6),489,632,48,ICE,true);word("KM/H",497,655,11,MUTED)
        word("%d%%" % int(s.battery/2*100),594,590,31,ACCENT,true)
        word("TRACTION",666,589,12,MUTED);bar(594,602,218,s.battery/2)
        word("%.2f kWh" % s.battery,594,624,15,ICE)
        word("EST %.0f km" % (s.battery/0.025),714,624,13,MUTED)
        word("%.1f kW" % game.polish.bike_draw if game.polish else "E-DRIVE",594,650,16,CYAN)
        word("COAST" if absf(game.speed)>1 and not Input.is_physical_key_pressed(KEY_W) else "PEDAL" if s.battery<=0 or Input.is_physical_key_pressed(KEY_P) else "ASSIST",730,650,13,MUTED)
        word("TRAILER  /  %.2f kWh   •   %.2f L" % [s.reserve,s.fuel],34,652,14,ICE)
    elif mode=="drone":
        var link:=maxf(0,100.0-game.drone.position.distance_to(game.bike.position)/4.5)
        plate(32,115,177,101)
        word("AIRCRAFT",46,138,12,CYAN)
        word("%03d%%" % int(s.drone*100),46,174,32,ICE,true)
        word("LINK %d%%" % int(link),122,174,12,MUTED);bar(46,190,148,s.drone,CYAN)
        word("ALT   %05.1f m" % game.drone.position.y,1058,142,15,ICE)
        word("VEL   %05.1f m/s" % game.drone.velocity.length(),1058,171,15,ICE)
        word("HOME  %05.0f m" % game.drone.position.distance_to(game.bike.position),1058,200,15,ICE)
        var yy: float=360+game.pitch*90
        draw_line(Vector2(495,yy),Vector2(550,yy),Color(.7,.9,.9,.6),1)
        draw_line(Vector2(730,yy),Vector2(785,yy),Color(.7,.9,.9,.6),1)
        draw_line(Vector2(550,yy),Vector2(550,yy+7),CYAN,1)
        draw_line(Vector2(730,yy),Vector2(730,yy+7),CYAN,1)
        word("PAYLOAD / "+" + ".join(s.slice02.modules).to_upper(),34,615,15,CYAN)
        word("R scan   X payload   Q recall   Space / Shift altitude",34,643,13,MUTED)
        if s.drone<.2 or link<25:word("RETURN TO OPERATOR",516,490,25,Color("edb578"),true)
        if game.polish:
            var a=game.polish.activities
            word(a.readout(),840,603,19,CYAN,true)
            word("CARRIER  %02d%%" % int(a.reception*100),1020,633,16,ICE)
            bar(1020,644,220,a.reception,CYAN)
    # A small targeting mark shared by all camera profiles.
    draw_circle(Vector2(640,360),2,color)
    var near: Dictionary=game.nearest()
    if not near.is_empty():
        var title: String=near.title
        var width:=minf(780,mono.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+84)
        plate(640-width/2,447,width,40)
        word("E",655-width/2,473,17,ACCENT)
        word(title,684-width/2,473,17,ICE)
    if mode!="drone":
        word(game.objective().get_slice(" · ",0),34,116,20,ACCENT,true)
        var detail: String=game.objective().get_slice(" · ",1)
        word(detail,34,139,13,MUTED)
    if toast_left>0 and not toast.is_empty():
        var shown:=toast if toast.length()<155 else toast.substr(0,152)+"…"
        var first:="";var second:=""
        for part in shown.split(" "):
            if second.is_empty() and mono.get_string_size(first+" "+part,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x<695:first+=(" " if not first.is_empty() else "")+part
            else:second+=(" " if not second.is_empty() else "")+part
        plate(275,162,730,60 if not second.is_empty() else 43)
        draw_line(Vector2(275,162),Vector2(275,222 if not second.is_empty() else 205),color,2)
        word(first,290,184,14,ICE)
        if not second.is_empty():word(second,290,207,14,ICE)
    word("I  PACK     B  MODULES     M  JOURNAL     ESC  MENU",34,700,11,MUTED)
    if transition>0 and not s.slice02.reduced_motion:
        word("SCOUT LINK ESTABLISHED" if mode=="drone" else "TRACTION ONLINE" if mode=="bike" else "FIELD CONTROL",525,530,20,color,true)

static func panel_style(color: Color) -> StyleBoxFlat:
    var style:=StyleBoxFlat.new();style.bg_color=color
    style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=12;style.content_margin_bottom=12
    return style
static func make_theme() -> Theme:
    var theme:=Theme.new();theme.default_font_size=15
    if ResourceLoader.exists("res://assets/fonts/IBMPlexMono-Regular.ttf"):theme.default_font=load("res://assets/fonts/IBMPlexMono-Regular.ttf")
    theme.set_color("font_color","Label",ICE)
    for cls in ["Button","OptionButton"]:
        for state in ["normal","hover","pressed","focus","disabled"]:
            var style:=panel_style(Color("152a30") if state=="normal" else Color("243d43") if state in ["hover","focus"] else Color("101f24"))
            style.border_color=ACCENT if state=="focus" else Color("385156")
            style.border_width_bottom=2 if state=="focus" else 1
            theme.set_stylebox(state,cls,style)
        theme.set_color("font_color",cls,ICE);theme.set_color("font_hover_color",cls,ACCENT)
        theme.set_color("font_disabled_color",cls,MUTED.darkened(.4))
    theme.set_stylebox("panel","ItemList",panel_style(Color("0c1c22")))
    theme.set_stylebox("selected","ItemList",panel_style(Color("304a4d")))
    theme.set_color("font_color","ItemList",ICE)
    theme.set_constant("h_separation","HBoxContainer",18)
    theme.set_constant("separation","VBoxContainer",12)
    return theme
