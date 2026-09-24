extends "res://editor/restore_browser_ui.gd"
## Rebuild ONLY the two requested screens. No levels, vehicles or legacy theme are touched.
var body_font: Font
var heading_font: Font
const SIZE := Vector2(1672,941)
const MUTED := Color("90968e")

func _initialize() -> void:
	if not "--replace-authored" in OS.get_cmdline_user_args():
		push_error("Explicit --replace-authored required for hangar/research/card scenes")
		quit(2)
		return
	_theme()
	_hangar()
	_research()
	_card()
	print("REFERENCE UI: hangar / research / vehicle card saved")
	quit()

func _theme() -> void:
	gold=Color("efce83")
	ink=Color("080f0ceF")
	body_font=load("res://assets/fonts/Exo2.ttf")
	var bold := FontVariation.new()
	bold.base_font=body_font
	bold.variation_opentype={"wght":700}
	bold.variation_embolden=.65
	heading_font=bold
	theme_resource=Theme.new()
	theme_resource.default_font=body_font
	theme_resource.default_font_size=16
	theme_resource.set_color("font_color","Label",Color("ddded4"))
	for type in ["Button","OptionButton"]:
		theme_resource.set_stylebox("normal",type,_style(Color("0a110edc"),Color("586053")))
		theme_resource.set_stylebox("hover",type,_style(Color("303327f5"),gold))
		var selected := _style(Color("353224f5"),gold)
		selected.set_border_width_all(2)
		selected.shadow_color=Color("e8b95630")
		selected.shadow_size=9
		theme_resource.set_stylebox("pressed",type,selected)
		theme_resource.set_stylebox("focus",type,_style(Color.TRANSPARENT,Color("f6e3ad")))
		theme_resource.set_stylebox("disabled",type,_style(Color("141a17d0"),Color("41493c")))
		theme_resource.set_color("font_color",type,Color("deded3"))
		theme_resource.set_color("font_hover_color",type,gold)
		theme_resource.set_color("font_pressed_color",type,Color("fff0bf"))
		theme_resource.set_color("font_disabled_color",type,Color("777e73"))
	theme_resource.take_over_path("res://scenes/ui/reference_theme.tres")
	ResourceSaver.save(theme_resource,theme_resource.resource_path)

func _label(parent: Node,id: String,text: String,rect: Rect2,font_size := 16,color := Color("ddded4"),center := false) -> Label:
	var label := super._label(parent,id,text,rect,font_size,color,center)
	label.add_theme_font_override("font",heading_font if font_size>=24 else body_font)
	return label

func _button(parent: Node,id: String,text: String,rect: Rect2,primary := false) -> Button:
	var b := Button.new()
	b.text=text
	b.toggle_mode=not primary
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	_at(b,parent,id,rect)
	if primary:
		var gradient := Gradient.new()
		gradient.colors=PackedColorArray([Color("f5d893"),Color("ac8c50")])
		var texture := GradientTexture2D.new()
		texture.gradient=gradient
		texture.fill_from=Vector2(.5,0)
		texture.fill_to=Vector2(.5,1)
		var style := StyleBoxTexture.new()
		style.texture=texture
		b.add_theme_stylebox_override("normal",style)
		b.add_theme_color_override("font_color",Color("151d15"))
		b.add_theme_font_override("font",heading_font)
	return b

func _panel(parent: Node,id: String,rect: Rect2,color := Color("080f0cef")) -> Panel:
	var p := super._panel(parent,id,rect,color)
	p.add_theme_stylebox_override("panel",_style(color,Color("5e614a")))
	return p

func _progress(parent: Node,id: String,rect: Rect2) -> ProgressBar:
	var p := super._progress(parent,id,rect)
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("background",_style(Color("232c27"),Color("414b43")))
	p.add_theme_stylebox_override("fill",_style(gold,gold))
	return p

func icon(parent: Node,kind: String,rect: Rect2,color := Color("c4c8bc")) -> Control:
	var node := Control.new()
	node.set_script(load("res://scripts/ui_symbol.gd"))
	node.set("symbol",kind)
	node.set("tint",color)
	_at(node,parent,"Icon_"+kind,rect)
	return node

func portrait(parent: Node,id: String,rect: Rect2) -> TextureRect:
	var p := TextureRect.new()
	p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_at(p,parent,id,rect)
	return p

func header(d: Node,research_page := false) -> void:
	_panel(d,"Header",Rect2(0,0,1672,84),Color("060d0bed"))
	icon(d,"logo",Rect2(41,15,62,60),gold)
	_label(d,"Logo","СТАЛЬНОЙ РУБЕЖ",Rect2(125,15,357,34),29,Color("e2d0a5"))
	_label(d,"Slogan","Т А К Т И К А .  Б Р О Н Я .  П О Б Е Д А .",Rect2(126,52,356,18),12,Color("bba16a"))
	for i in 3:
		var r: Rect2=[Rect2(500,6,202,74),Rect2(702,6,249,74),Rect2(951,6,220,74)][i]
		var b := _button(d,["HangarTab","Research","Tasks"][i],"     "+["АНГАР","ИССЛЕДОВАНИЯ","ЗАДАЧИ"][i],r)
		b.button_pressed=i==(1 if research_page else 0)
		icon(b,["tank","research","tasks"][i],Rect2(38 if i!=1 else 25,23,28,28),gold if b.button_pressed else Color("c4c8bc"))
		if b.button_pressed: _panel(b,"ActiveLine",Rect2(1,0,r.size.x-2,4),gold).mouse_filter=Control.MOUSE_FILTER_IGNORE
	_label(d,"Silver","◉ 0",Rect2(1244,19,137,30),21,gold,true)
	_label(d,"XP","◆ 0",Rect2(1397,19,100,30),21,gold,true)
	_label(d,"SilverUnit","СЕРЕБРО",Rect2(1255,52,125,18),12,MUTED,true)
	_label(d,"XPUnit","ОПЫТ",Rect2(1400,52,95,18),12,MUTED,true)
	_label(d,"Currency","",Rect2(0,0,1,1)).hide()
	icon(_button(d,"Settings","",Rect2(1518,13,59,60)),"gear",Rect2(18,17,25,25))
	icon(_button(d,"Profile","",Rect2(1597,13,58,60)),"profile",Rect2(17,17,25,25))

func nations(parent: Node,rect: Rect2) -> void:
	for i in 3:
		var w := rect.size.x/3
		var b := _button(parent,"Nation%d"%i,"",Rect2(rect.position+Vector2(i*w,0),Vector2(w,rect.size.y)))
		_label(b,"NationCaption",["СССР","Германия","Франция"][i],Rect2(54,0,w-58,rect.size.y),15)
		icon(b,["star","cross","lily"][i],Rect2(22,15,26,26),Color("cf4e3c") if i==0 else Color("b9bcb2"))

func stats(parent: Node,start: Vector2,width: float,count: int,step: float) -> void:
	for i in count:
		var y := start.y+i*step
		icon(parent,["fire","shield","speed","weight","gear"][i],Rect2(start.x,y+1,29,32),Color("d1513c") if i==0 else Color("bfc6b9"))
		_label(parent,"StatTitle%d"%i,["ОГНЕВАЯ МОЩЬ","ПРОЧНОСТЬ","СКОРОСТЬ","МАССА","ДВИГАТЕЛЬ"][i],Rect2(start.x+49,y,width-159,25),15)
		_label(parent,"StatValue%d"%i,"—",Rect2(start.x+width-110,y,110,25),16).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		_progress(parent,"StatBar%d"%i,Rect2(start.x+49,y+34,width-49,6))

func _hangar() -> void:
	var r := _base("Hangar",SIZE,false)
	var d := r.get_node("Design")
	# Transparent centre reveals the real editable 3D hangar and its tank.
	header(d)
	var left := _panel(d,"VehicleInfo",Rect2(30,110,456,578))
	nations(left,Rect2(5,15,441,51))
	_label(left,"Nation","СРЕДНИЙ ТАНК",Rect2(25,83,330,27),17,MUTED)
	_label(left,"VehicleName","205 «Оплот»",Rect2(25,111,338,48),38)
	var badge := _panel(left,"LevelBadge",Rect2(372,102,56,51),Color("282719c0"))
	_label(badge,"Tier","I",Rect2(0,0,56,32),26,gold,true)
	_label(badge,"LevelText","УРОВЕНЬ",Rect2(0,32,56,15),9,gold,true)
	var desc := _label(left,"Description","",Rect2(25,163,400,61),15,MUTED)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stats(left,Vector2(28,231),397,5,52)
	icon(_button(left,"Armor","     СХЕМА БРОНИ",Rect2(23,513,183,47)),"shield",Rect2(18,13,21,21))
	icon(_button(left,"PassportButton","    ПАСПОРТ ТЕХНИКИ",Rect2(221,513,215,47)),"passport",Rect2(18,13,21,21))
	var right := _panel(d,"Modules",Rect2(1267,124,377,598))
	icon(right,"wrench",Rect2(23,15,28,28),gold)
	_label(right,"ModulesTitle","МОДЕРНИЗАЦИЯ",Rect2(67,15,240,30),18,gold)
	_label(right,"VehicleCode","0-1",Rect2(314,16,47,29),14,MUTED)
	for i in 4:
		var id: String=["gun","armor","engine","tracks"][i]
		var b := _button(right,"Upgrade_"+id,"",Rect2(16+i%2*180,62+floori(i/2.0)*115,168,100))
		icon(b,"shield" if id=="armor" else id,Rect2(14,25,40,40),gold)
		_label(b,"ModuleCaption",["ОРУДИЕ","БРОНЯ","ДВИГАТЕЛЬ","ХОДОВАЯ"][i],Rect2(63,18,101,26),14)
		_label(b,"ModuleRank","УРОВЕНЬ 1",Rect2(63,42,101,22),12,gold)
		_progress(b,"ModuleBar",Rect2(13,80,141,6)).value=20
	var detail := _panel(right,"ModuleDetail",Rect2(16,293,347,229),Color("080e0bab"))
	_label(detail,"ModuleName","ОРУДИЕ",Rect2(14,7,233,34),25,gold)
	_label(detail,"ModuleLevel","УР. 1 / V",Rect2(252,11,84,28),14,gold)
	_label(detail,"ModuleStats","",Rect2(14,50,318,95),16)
	_progress(detail,"ModuleProgress",Rect2(14,155,318,6))
	var hint := _label(detail,"Hint","Повышает огневую мощь и эффективность\nна средней и дальней дистанции.",Rect2(14,176,316,44),13,MUTED)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(right,"UpgradeConfirm","УЛУЧШИТЬ",Rect2(27,530,329,47)).add_theme_color_override("font_color",gold)
	var shelf := ScrollContainer.new()
	shelf.set_script(load("res://scripts/vehicle_shelf.gd"))
	_at(shelf,d,"VehicleScroll",Rect2(69,775,1067,121))
	var cards := HBoxContainer.new()
	cards.name="Vehicles"
	cards.add_theme_constant_override("separation",12)
	shelf.add_child(cards)
	_button(d,"ShelfPrev","‹",Rect2(24,791,33,85)).add_theme_font_size_override("font_size",36)
	_button(d,"ShelfNext","›",Rect2(1149,791,33,85)).add_theme_font_size_override("font_size",36)
	var operation := _panel(d,"Operation",Rect2(1227,758,424,143),Color("0a100ddd"))
	var battle := _button(operation,"Battle","В БОЙ  →",Rect2(14,13,396,116),true)
	battle.add_theme_font_size_override("font_size",38)
	_label(battle,"Mode","КОМАНДНЫЙ БОЙ",Rect2(0,83,396,22),16,Color("302a1b"),true)
	_label(d,"Career","",Rect2(512,909,650,22),12,MUTED,true)
	_button(d,"Help","Управление  ·  помощь",Rect2(28,909,235,23)).add_theme_font_size_override("font_size",12)
	_save(r,"hangar")

func _card() -> void:
	var card := Button.new()
	card.name="VehicleCard"
	card.theme=theme_resource
	card.toggle_mode=true
	card.custom_minimum_size=Vector2(205,118)
	portrait(card,"Portrait",Rect2(12,1,187,94))
	_label(card,"Caption","",Rect2(6,89,193,25),16,Color("ddded4"),true)
	_label(card,"Tier","I",Rect2(13,5,35,24),20,gold)
	icon(card,"star",Rect2(14,72,21,21),Color("d95a44"))
	_save(card,"vehicle_card")

func _research() -> void:
	var r := _base("Research",SIZE,false)
	var d := r.get_node("Design")
	_image(d,"Workshop","res://assets/ui/research-workshop.png",Rect2(Vector2.ZERO,SIZE))
	header(d,true)
	nations(d,Rect2(35,121,512,55))
	for i in 4:
		var b := _button(d,"Filter%d"%i,["ВСЯ ТЕХНИКА","ЛЁГКИЕ","СРЕДНИЕ","ТЯЖЁЛЫЕ / САУ"][i],Rect2(35+i*151,193,151,52))
		b.add_theme_font_size_override("font_size",14)
	_button(d,"OwnedFilter","ВСЕ МАШИНЫ",Rect2(895,193,271,52))
	var tree := _panel(d,"TechTree",Rect2(35,260,1132,478),Color("080f0ccb"))
	for i in 4:
		var column := _panel(tree,"Column%d"%i,Rect2(i*283,0,283,478),Color("090f0b15"))
		_label(column,"Level",["I","II","III","IV"][i],Rect2(0,11,283,30),23,gold if i==0 else Color("dddccf"),true)
		_label(column,"Stage",["Начальные","Развитие","Усиление","Специализация"][i],Rect2(0,40,283,27),16,MUTED,true)
		var card := _button(tree,"Tank%d"%i,"",Rect2(19+i*283,160 if i<2 else 98 if i==2 else 283,237,169))
		portrait(card,"Portrait",Rect2(19,4,210,117))
		_label(card,"Tier",["I","II","III","IV"][i],Rect2(15,8,37,27),21,gold)
		icon(card,"star",Rect2(13,42,23,23),Color("d9533c"))
		_label(card,"State","",Rect2(195,9,28,27),22,gold,true)
		_label(card,"Caption","",Rect2(14,108,216,31),20)
		_label(card,"Price","",Rect2(14,141,216,23),15,gold)
	# Lines describe the actual roster, not the two fictitious extra tanks in the reference.
	for i in 3:
		_label(tree,"Arrow%d"%i,"→",Rect2(257+i*283,218 if i==0 else 159 if i==1 else 321,27,35),29,gold,true)
	var plaque := _panel(d,"BranchPlaque",Rect2(35,814,600,96),Color("080f0cef"))
	icon(plaque,"star",Rect2(23,23,44,44),gold)
	_label(plaque,"BranchTitle","ВЕТКА СССР",Rect2(90,14,455,29),21,gold)
	var branch := _label(plaque,"BranchDescription","",Rect2(90,47,486,43),13,MUTED)
	branch.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var detail := _panel(d,"ResearchDetail",Rect2(1188,110,463,802),Color("080f0cd9"))
	_label(detail,"VehicleName","",Rect2(20,12,346,49),36)
	_label(detail,"Nation","",Rect2(24,69,340,28),16,gold)
	var badge := _panel(detail,"LevelBadge",Rect2(370,19,71,58),Color("292416cf"))
	_label(badge,"Tier","I",Rect2(0,0,71,39),28,gold,true)
	_label(badge,"LevelText","уровень",Rect2(0,38,71,16),11,gold,true)
	portrait(detail,"Preview",Rect2(12,105,440,204))
	_button(detail,"Previous","‹",Rect2(22,174,38,45)).add_theme_font_size_override("font_size",29)
	_button(detail,"Next","›",Rect2(402,174,38,45)).add_theme_font_size_override("font_size",29)
	var desc := _label(detail,"Description","",Rect2(21,305,419,76),15,MUTED)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for i in 3:
		_button(detail,"InfoTab%d"%i,["ХАРАКТЕРИСТИКИ","МОДУЛИ","ОПИСАНИЕ"][i],Rect2(12+i*146,387,146,50)).add_theme_font_size_override("font_size",13)
	var values := Control.new()
	_at(values,detail,"StatContent",Rect2(20,449,418,177))
	stats(values,Vector2.ZERO,418,4,44)
	var info := _label(detail,"InfoContent","",Rect2(27,449,410,178),16)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info.hide()
	var cost := _panel(detail,"Cost",Rect2(20,635,422,144),Color("09100ccc"))
	_label(cost,"CostLabel","СТОИМОСТЬ ИССЛЕДОВАНИЯ",Rect2(13,10,397,26),15,MUTED)
	_label(cost,"ResearchPrice","",Rect2(13,40,397,33),23,gold)
	_button(detail,"Unlock","ИССЛЕДОВАТЬ",Rect2(23,717,416,60),true).add_theme_font_size_override("font_size",24)
	_button(d,"Back","←  В АНГАР",Rect2(938,849,228,48))
	_save(r,"research")
