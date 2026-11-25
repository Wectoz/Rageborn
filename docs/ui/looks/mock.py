# Draws browser mock-ups of the settings window from the addon's real texts and data.
# Fonts and icons are stand-ins. usage: python3 docs/ui/looks/mock.py  (writes features.html)
import re,html,hashlib
L=dict(re.findall(r'^L\.(\w+) = "((?:[^"\\]|\\.)*)"', open('Rageborn/Locale.lua').read(), re.M))
MAC=re.findall(r'key = "(\w+)", name = "([^"]+)",\s*body = "((?:[^"\\]|\\.)*)",\s*requires = \{[^}]*\}(?:, spec = \{([^}]*)\})?', open('Rageborn/Macros.lua').read())
B,WELL,CAP,CTL,RULE,QUIET,SEC,INK,RED,REDG="#161112","#0C090A","#211A1B","#2A2021","#4A3536","#8C7B78","#C9B9AD","#EFE6D6","#D8372B","#3A1614"
HEAD="'Palatino Linotype','Book Antiqua',Georgia,serif"; BODY="'Arial Narrow',Arial,sans-serif"
e=html.escape
def at(x,y,w=None,h=None,extra=""): return f'position:absolute;left:{x}px;top:{y}px;'+(f'width:{w}px;' if w else '')+(f'height:{h}px;' if h else '')+extra
def label(x,y,size,col,t,w=None,head=False,nowrap=False): return f'<div style="{at(x,y,w)}font:{size}px {HEAD if head else BODY};color:{col};line-height:1.25;{"white-space:nowrap;overflow:hidden;" if nowrap else ""}">{e(t)}</div>'
def heading(x,y,w,t): return f'<div style="{at(x,y,w,18)}display:flex;align-items:center;gap:12px;font:11px {BODY};letter-spacing:.6px;color:{SEC}">{e(t.upper())}<i style="flex:1;height:1px;background:{RULE}"></i></div>'
def button(x,y,w,t,on=True,under=False): return f'<div style="{at(x,y,w,26)}box-sizing:border-box;border:1px solid {RULE};background:linear-gradient({"#34282a,#221a1b" if on else CAP+","+CAP});color:{INK if on else QUIET};text-align:center;font:13px/24px {BODY};{"box-shadow:inset 0 -2px "+RED+";" if under else ""}">{e(t)}</div>'
def dd(x,y,w,t,on=True): return f'<div style="{at(x,y,w,26)}box-sizing:border-box;border:1px solid {RULE};background:{CTL if on else CAP};padding:0 9px;display:flex;justify-content:space-between;font:13px/24px {BODY};color:{INK if on else QUIET}"><span>{e(t)}</span><span style="color:{SEC};font-size:10px">v</span></div>'
def check(x,y,t,on=True,able=True): return f'<div style="{at(x,y)}display:flex;align-items:center;gap:8px;font:13px/26px {BODY};color:{INK if able else QUIET}"><i style="width:14px;height:14px;box-sizing:border-box;border:1px solid {RULE};background:{RED if on else WELL}"></i>{e(t)}</div>'
def slider(x,y,w,t,v,mx,unit="%",able=True): return f'<div style="{at(x,y,w,32)}opacity:{1 if able else .45}"><div style="display:flex;justify-content:space-between;font:11px {BODY};color:{SEC}"><span>{e(t)}</span><span style="font-size:12px;color:{INK}">{v}{unit}</span></div><div style="position:relative;height:3px;background:{CTL};margin-top:9px"><i style="position:absolute;left:{100*v/mx}%;top:-5px;width:8px;height:13px;background:{INK}"></i></div></div>'
def rule(x,y,w): return f'<div style="{at(x,y,w,1)}background:{RULE}"></div>'
def icon(x,y,s,seed):
    hue=int(hashlib.md5(seed.encode()).hexdigest()[:4],16)%360
    return f'<div style="{at(x,y,s,s)}background:linear-gradient(135deg,hsl({hue},55%,48%),hsl({(hue+40)%360},60%,22%));box-shadow:inset 0 0 0 1px #0008"></div>'
RAIL=[("Procs",["Overpower","Revenge","Execute","Victory Rush","Interrupt","Gore Drinker","Enrage"]),("Reminders",["Battle Shout","Demo Shout: pull"]),("Defensives",["Shield Wall","Last Stand","Racial ability","Berserker Rage: fear"])]
def window(title, sel, kicker, name, body, selAlert=None):
    rail=""; y=0
    for g,items in RAIL:
        rail+=label(8,y+5,11,SEC,g.upper()); y+=22
        for i in items:
            on=i==selAlert
            rail+=f'<div style="{at(0,y,159,24)}{"background:"+RED+";box-shadow:inset 3px 0 "+INK+";" if on else ""}"></div>'+icon(9,y+4,16,i)+label(31,y+4,13,INK,i,126,nowrap=True); y+=24
    def lib(yy,t):
        s=f"background:{RED};box-shadow:inset 3px 0 {INK};" if t==sel else ""
        return f'<div style="{at(8,yy,159,24)}{s}font:13px/24px {BODY};padding-left:8px;box-sizing:border-box">{e(t)}</div>'
    return f'''<div style="margin:16px 20px 6px;font:bold 15px Arial;color:#ddd">{e(title)}</div>
<div style="margin:0 20px;width:860px;height:560px;box-sizing:border-box;background:{B};color:{INK};position:relative;outline:1px solid {RULE};overflow:hidden">
<div style="{at(1,1,858,39)}background:linear-gradient(#7a1c17,#4a100e)"></div>{rule(1,40,858)}
<div style="{at(12,8,24,24)}border-radius:4px;background:radial-gradient(#ffb060,#b0301a)"></div>{label(46,9,18,INK,"Rageborn",head=True)}{label(830,10,16,INK,"x")}
<div style="{at(1,41,178,518)}background:{WELL}"></div><div style="{at(179,41,1,518)}background:{RULE}"></div>
{lib(48,"General")}{rule(12,79,152)}<div style="{at(8,84,159,330)}overflow:hidden">{rail}</div>
{rule(12,417,152)}{label(16,426,11,SEC,"LIBRARY")}{lib(447,"Gallery")}{lib(473,"Macros")}{lib(499,"Consumables")}{lib(525,"Profiles")}
{label(200,53,11,SEC,kicker.upper())}{label(200,67,18,INK,name,head=True)}{body}</div>'''
def scroller(x,y,w,h,inner,content_h,pos=0):
    ln=max(20,h*h/max(content_h,h)); mark=f'<div style="{at(x+w+4,y+(h-ln)*pos/max(1,content_h-h),4,ln)}background:{QUIET}"></div>' if content_h>h else ''
    return f'<div style="{at(x,y,w,h)}overflow:hidden"><div style="position:absolute;left:0;top:{-pos}px;width:{w}px">{inner}</div></div>'+mark
def coins(c): return f"{c//10000}g {c%10000//100}s" if c>=10000 else f"{c//100}s {c%100}c"
# ---------------- Consumables (Forever, Damage)
src=open('Rageborn/Consumables.lua').read(); fz=src[src.index('forever = {'):src.index('    era = {')]; dps=fz[fz.index('dps = {'):fz.index('tank = {')]
PRICE={250351:38500,13452:42000,250350:21000,9206:16500,8846:9200,8839:6100,8925:400,13465:11800,13466:14500,274274:1650000,13468:1500000,13423:21000,13467:19000,8831:7000}
HAVE={13452:4,9206:11,8846:17,274274:1}
inner=""; y=0
for sec in re.finditer(r'\{ "(\w+)", \{\n(.*?)\n            \} \},', dps, re.S):
    inner+=heading(0,y+6,624,L['CONS_SEC_'+sec.group(1)]); y+=30
    for rank,line in enumerate(sec.group(2).split('\n'),1):
        m=re.match(r'\s*\{ (\d+), "([^"]+)", L\.(\w+)(.*)\},',line); sp=re.match(r'\s*\{ spell = (\d+)(.*)\},',line)
        if not (m or sp): continue
        rest=(m.group(4) if m else sp.group(2))
        prof=re.search(r'prof = "(\w+)"',rest); skill=re.search(r'skill = (\d+)',rest); extra=re.search(r'extra = L\.(\w+)',rest)
        mats=re.findall(r'\{ (\d+), (\d+), "([^"]+)" \}',rest)
        iid=int(m.group(1)) if m else 0
        nm=m.group(2) if m else {"20034":"Enchant Weapon - Crusader","23799":"Enchant Weapon - Strength","20030":"Enchant 2H Weapon - Superior Impact"}.get(sp.group(1),"Enchant ...")
        srcline=", ".join(x for x in [(L['PROF_'+prof.group(1)]+(f" ({skill.group(1)})" if skill else "")) if prof else "", L[extra.group(1)] if extra else ""] if x)
        h=24+(16 if srcline else 0)+(18 if mats else 0)
        inner+=label(2,y+4,12,SEC,f"{rank}.")+icon(24,y+2,18,nm)+label(50,y+3,13,INK,nm,212,nowrap=True)
        if m: inner+=label(268,y+4,12,SEC,L[m.group(3)],232,nowrap=True)
        if iid in HAVE: inner+=label(508,y+4,12,INK,f"x{HAVE[iid]}")
        if iid in PRICE: inner+=f'<div style="{at(520,y+4,100)}text-align:right;font:12px {BODY};color:{SEC}">{coins(PRICE[iid])}</div>'
        if srcline: inner+=label(50,y+23,11,QUIET,srcline)
        if mats:
            x=86; inner+=label(50,y+40,11,QUIET,L['CONS_MATS']); tot=0; ok=True
            for mi,(mid,cnt,mn) in enumerate(mats):
                t=f"{cnt}x {mn}"; w=len(t)*6+14
                inner+=label(x,y+39,12,RED if (iid==250351 and mi==0) else INK,t); x+=w
                ok=ok and int(mid) in PRICE; tot+=PRICE.get(int(mid),0)*int(cnt)
            if ok: inner+=f'<div style="{at(420,y+23,200)}text-align:right;font:11px {BODY};color:{QUIET}">{e(L["CONS_MATS_COST"]%coins(tot))}</div>'
        y+=h+2
cons=label(200,100,12,INK,L['CONS_SUBTITLE'],450)+label(200,134,12,SEC,L['CONS_DISCLAIMER'],636)+button(668,98,82,L['CONS_ROLE_dps'],under=True)+button(756,98,82,L['CONS_ROLE_tank'])+scroller(200,172,624,371,inner,y)
# ---------------- Alert page (Gore Drinker: an effect, glow-only switch)
al=label(200,90,12,SEC,L['DESC_goreDrinker'],410,nowrap=True)+check(200,103,L['OPT_ENABLED'])+check(300,103,L['OPT_ON_SCREEN'])
al+=label(200,139,11,SEC,L['OPT_DESIGN'].upper())+label(200,154,13,INK,"Blood Surge  (Legacy)")+button(200,177,124,L['OPT_BROWSE'])
al+=f'<div style="{at(622,54,218,142)}box-sizing:border-box;background:{WELL};border:1px solid {RULE}">{label(10,7,11,SEC,"LIVE PREVIEW")}<img src="../../art/legacy/overpower/overpower_side2.png" style="position:absolute;left:54px;top:28px;height:100px;mix-blend-mode:screen"><img src="../../art/legacy/overpower/overpower_side2.png" style="position:absolute;right:54px;top:28px;height:100px;mix-blend-mode:screen;transform:scaleX(-1)"></div>'
al+=heading(200,212,640,L['OPT_APPEARANCE'])+label(200,245,13,INK,L['OPT_COLOUR'])+f'<div style="{at(252,242,28,20)}background:#d8372b;border:1px solid {QUIET}"></div>'+check(290,239,L['OPT_TINT'],False)+slider(360,236,200,L['OPT_SIZE'],100,200)+slider(590,236,250,L['OPT_OPACITY'],100,100)
al+=slider(200,278,150,L['OPT_SPREAD'],100,200)+dd(360,281,96,L['OPT_SIDE_both'])+check(476,281,L['OPT_ICON'],False)+check(572,281,L['OPT_NAME'],False)+check(668,281,L['OPT_TIMER'])
al+=heading(200,322,640,L['OPT_BEHAVIOUR'])+label(200,347,13,INK,L['OPT_SOUND'])+dd(250,342,180,"Warrior: Execute")+button(438,342,54,L['OPT_PLAY'])+check(513,342,L['OPT_COMBAT_ONLY'],False)
al+=label(200,412,12,QUIET,"(No Button glow section here: Gore Drinker is an effect on you, with nothing to press.)",640)
al+=rule(200,499,640)+button(200,511,122,L['OPT_MOVE'])+button(330,511,120,L['OPT_RESET_POS'])+button(458,511,64,L['OPT_TEST'])
# ---------------- Macros with spec tabs (Fury)
rows=""; y=0
for key,name,body,spec in [m for m in MAC if (not m[3]) or 'fury' in m[3]][:4]:
    lines=body.replace('\\n','\n').split('\n'); vis=sum(-(-len(l)//80) for l in lines); bh=17+15*vis
    rows+=rule(0,y,624)+label(8,y+10,15,INK,"RB "+name,head=True)+label(8,y+34,13,SEC,L['MACRO_'+key],608)+button(540,y+10,76,L['MACRO_CREATE'])
    rows+=f'<div style="{at(8,y+58,608,bh)}box-sizing:border-box;border:1px solid {RULE};background:{WELL};padding:6px 10px;font:12px/15px {BODY};color:{INK};white-space:pre-wrap">{e(chr(10).join(lines)).replace("&lt;charge&gt;","1/2").replace("&lt;shield&gt;","Aegis of Stormwind")}</div>'
    y+=79+bh
mac=label(200,103,13,INK,L['MACRO_SUBTITLE'])+"".join(button(496+i*86,98,80,t,under=(t=="Fury")) for i,t in enumerate([L['MACRO_ALL'],L['PRESET_arms'],L['PRESET_fury'],L['PRESET_prot']]))+scroller(200,140,624,403,rows,y+900)
# ---------------- minimap button
mini=f'''<div style="margin:16px 20px 6px;font:bold 15px Arial;color:#ddd">Minimap button (left click: settings; right click: test mode; drag around the edge)</div>
<div style="margin:0 20px;width:860px;height:150px;position:relative;background:#2c3a2b"><div style="{at(60,15,120,120)}border-radius:50%;background:radial-gradient(#6f8f5a,#3d5433);box-shadow:0 0 0 3px #7a6a3a,0 0 0 5px #2a2412"></div>
<div style="{at(42,96,31,31)}"><div style="{at(4,4,23,23)}border-radius:50%;background:#000"></div><div style="{at(6,6,19,19)}border-radius:50%;background:radial-gradient(#ffb060,#b0301a)"></div><div style="{at(1,1,27,27)}border-radius:50%;box-shadow:0 0 0 2px #c9a24a,0 0 0 3px #4a3a12"></div></div>
<div style="{at(230,40,560)}font:13px/1.5 Arial;color:#ddd">The ring and icon are drawn from the game's own minimap-button art; how well they line up is one of the things only the game can show. A tick box on the General page hides the button.</div></div>'''
page='<body style="margin:0;background:#3b4a3a">'+window("Consumables (Forever, Damage tab; prices and counts are invented examples)","Consumables",L['OPT_LIBRARY'],L['OPT_CONSUMABLES'],cons)+window("An alert page: description line, Show on screen, icons in the left list","",L['GROUP_procs']+"  /  "+L['OPT_ALERT'],"Gore Drinker",al,selAlert="Gore Drinker")+window("Macros with spec tabs (Fury)","Macros",L['OPT_LIBRARY'],L['OPT_MACROS'],mac)+mini+'</body>'
open('docs/ui/looks/features.html','w').write(page)
