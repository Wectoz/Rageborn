# Writes Rageborn/Consumables.lua and the Consumables block of Rageborn/Locale.lua.
# Run from the repo root: python3 tools/consumables/gen.py
# Needs each client's data tables as CSV in /tmp/wowf (Forever) and /tmp/wowera (Era), from
# https://wago.tools/db2/<Table>/csv?build=<build>: ItemSparse, SpellName, SpellEffect,
# SkillLine, SkillLineAbility, SpellReagents. Builds used: 1.60.1.71091 and 1.15.9.70576.
# The order of items, their notes and the "from" texts are written by hand below. Forever's
# sources come from community sites read on 2026-11-25 (wow.gg, warcraft.wiki.gg, zockify,
# the Blizzard forums); "unconfirmed" marks a Classic source nobody has verified on Forever.
import csv,re
csv.field_size_limit(10**9)
names={d:{r['ID']:r['Display_lang'] for r in csv.DictReader(open(f'/tmp/{d}/ItemSparse.csv',encoding='utf-8'))} for d in ('wowf','wowera')}
F={
 "dps": [
  ("flask", [(274274,"+30 Stamina; +2% crit in Hyjal zones"),(274275,"+30 Stamina; dodged, parried 2% less in Hyjal"),(274273,"+30 Stamina; +2% hit in Hyjal zones"),(274276,"+30 Stamina; +2% haste in Hyjal zones"),(13510,"+1200 health, 2 hours")]),
  ("elixir", [(250351,"+25 Strength, +2% crit, 30 min"),(13452,"+25 Agility, +2% crit, 30 min"),(250350,"+18 Strength, +18 Agility, 30 min"),(9206,"+25 Strength, 1 hour"),(8410,"+25 Strength, 1 hour"),(13453,"+18 Strength, +18 Stamina, 1 hour"),(12820,"+35 attack power, 20 min"),(246948,"+35 attack power; same buff as Winterfall"),(9187,"+25 Agility, 1 hour; not with Mongoose"),(8412,"+25 Agility, 1 hour")]),
  ("food", [(20452,"+20 Strength"),(250070,"+20 Strength"),(250071,"+20 Strength"),(13934,"+40 attack power"),(13928,"+1% crit"),(250069,"+20 Agility"),(250072,"+20 Agility"),(18045,"+15 Agility"),(13810,"+10 Strength, 10 min")]),
  ("weapon", [(18262,"+2% crit, 30 min"),(12404,"+8 damage, sharp weapons"),(12643,"+8 damage, blunt weapons"),(23122,"+100 attack power against undead")]),
  ("combat", [(13442,"Rage and +60 Strength for 20 sec"),(250943,"+80 attack power for 30 sec"),(250942,"+56 attack power for 30 sec"),(5634,"Immune to stuns and slows for 30 sec"),(20008,"Removes stuns and slows; immune 5 sec"),(3387,"Immune to physical attacks for 6 sec"),(13446,"Restores 1400 health"),(11951,"Restores 800 health"),(10646,"600 fire damage around you"),(14530,"Heals 250 over 8 sec")]),
 ],
 "tank": [
  ("flask", [(13510,"+1200 health, 2 hours"),(274273,"+30 Stamina; +2% hit in Hyjal zones"),(274275,"+30 Stamina; dodged, parried 2% less in Hyjal")]),
  ("elixir", [(20079,"+50 Stamina, 2 hours"),(250329,"+400 health, +500 armor, 30 min"),(250335,"+400 health, 30 min"),(13445,"+450 armor, 1 hour"),(13453,"+18 Strength, +18 Stamina, 1 hour"),(21151,"+15 Stamina, 15 min"),(18269,"+10 Stamina, 15 min"),(250334,"+200 health, 30 min"),(9088,"Attackers may take a disease"),(20004,"20 health every 5 sec, 1 hour")]),
  ("food", [(21023,"+25 Stamina"),(250068,"+20 Stamina"),(20452,"+20 Strength"),(250070,"+20 Strength")]),
  ("weapon", [(18262,"+2% crit, 30 min"),(12404,"+8 damage, sharp weapons"),(12643,"+8 damage, blunt weapons")]),
  ("combat", [(13455,"+2000 armor for 2 min"),(3387,"Immune to physical attacks for 6 sec"),(13446,"Restores 1400 health"),(11951,"Restores 800 health"),(5634,"Immune to stuns and slows for 30 sec"),(20008,"Removes stuns and slows; immune 5 sec"),(13442,"Rage and +60 Strength for 20 sec"),(14530,"Heals 250 over 8 sec")]),
 ]}
E={
 "dps": [
  ("flask", [(13510,"+1200 health, 2 hours")]),
  ("elixir", [(13452,"+25 Agility, +2% crit, 1 hour"),(12451,"+30 Strength, 30 min"),(9206,"+25 Strength, 1 hour; not with Juju Power"),(12460,"+40 attack power, 10 min"),(12820,"+35 attack power, 20 min; not with Juju Might"),(8410,"+25 Strength, 1 hour; Blasted Lands"),(8412,"+25 Agility, 1 hour; Blasted Lands"),(9187,"+25 Agility, 1 hour; not with Mongoose")]),
  ("food", [(20452,"+20 Strength"),(13810,"+10 Strength, 10 min"),(13928,"+10 Agility"),(18045,"+12 Stamina and Spirit")]),
  ("weapon", [(18262,"+2% crit, 30 min"),(12404,"+8 damage, sharp weapons"),(12643,"+8 damage, blunt weapons"),(23122,"+100 attack power against undead")]),
  ("combat", [(13442,"45 to 75 rage and +60 Strength for 20 sec"),(5633,"30 to 60 rage"),(5634,"Immune to stuns and slows for 30 sec"),(3387,"Immune to physical attacks for 6 sec"),(13446,"Restores 1050 to 1750 health"),(11951,"Restores 700 to 900 health"),(10646,"450 to 750 fire damage around you"),(9030,"Removes one harmful effect every 5 sec"),(14530,"Heals 2000 over 8 sec")]),
 ],
 "tank": [
  ("flask", [(13510,"+1200 health, 2 hours")]),
  ("elixir", [(20079,"+50 Stamina and Spirit, 2 hours"),(13445,"+450 armor, 1 hour"),(3825,"+120 health, 1 hour"),(21151,"+15 Stamina, 15 min"),(18269,"+10 Stamina, 15 min"),(9088,"Attackers may take a disease"),(20004,"20 health every 5 sec, 1 hour"),(13452,"+25 Agility, +2% crit, 1 hour")]),
  ("food", [(21023,"+25 Stamina"),(18045,"+12 Stamina and Spirit"),(20452,"+20 Strength")]),
  ("weapon", [(18262,"+2% crit, 30 min"),(12404,"+8 damage, sharp weapons"),(12643,"+8 damage, blunt weapons")]),
  ("combat", [(13455,"+2000 armor for 2 min"),(3387,"Immune to physical attacks for 6 sec"),(13446,"Restores 1050 to 1750 health"),(11951,"Restores 700 to 900 health"),(5634,"Immune to stuns and slows for 30 sec"),(13442,"45 to 75 rage and +60 Strength for 20 sec"),(9030,"Removes one harmful effect every 5 sec"),(14530,"Heals 2000 over 8 sec")]),
 ]}
ENCH={"wowera":{"dps":[20034,23799,20030,20025,20010,20013,25080,13890,20023,13882],
      "tank":[20034,23800,20026,20025,20011,25072,20020,13890,20015,25086,20017]},
 # Forever: its new enchants in; Gloves - Threat, Superior Agility and Cloak - Dodge out (no source in the game yet)
 "wowf":{"dps":[20034,1248668,23799,20025,20010,20013,20023,1328948,13882,1249019],
      "tank":[20034,1248760,23800,20026,20011,1248665,20020,1328948,20015,20017,1249060]}}
ENCH_FROM={1248760:"favor45",1249019:"favor120F",1249060:"favor120F",1328948:"favor180H",1248665:"favor240H"}

PREF=["Alchemy","Cooking","Blacksmithing","Engineering","First Aid"]
# recipe skill where the data has no recipe item (taught by a trainer); standard Classic values,
# used for Forever only where its recipe is unchanged (same "turns yellow" level as Era)
KNOWN={9030:210,9187:240,14530:260,20452:285,12404:250,12643:250,10646:205,9206:245,13445:265}
EXTRA={13510:"CONS_X_lab"}
FROM_ERA={8410:"blasted",8412:"blasted",12451:"eko",12460:"eko",12820:"furbolg",13810:"argent",23122:"argent",18269:"diremaul",21151:"wreckage",20079:"zandalar",11951:"felwood"}
FROM_F={250351:"favor240H",250350:"favor180H",250329:"favor180H",250335:"favor120F",13510:"drakk",12820:"furbolg",13934:"vendor",
 274273:"hyjal",274274:"hyjal",274275:"hyjal",274276:"hyjal",250068:"unknown",250069:"unknown",250070:"unknown",250071:"unknown",250072:"unknown",
 18262:"mc",20079:"zg",8410:"blasted_u",8412:"blasted_u",18269:"diremaul_u",21151:"wreckage_u"}
FROM_TEXT={"favor45":"recipe: 45 Merchant's Favor","favor120F":"recipe: 120 Merchant's Favor (Friendly)","favor180H":"recipe: 180 Merchant's Favor (Honored)","favor240H":"recipe: 240 Merchant's Favor (Honored)",
 "drakk":"recipe from General Drakkisath","vendor":"vendor recipe","hyjal":"recipe source unknown; Death Lotus grows in Mount Hyjal","unknown":"recipe source not known yet",
 "mc":"plans from Molten Core, which isn't open","zg":"from Zul'Gurub, which isn't in Forever yet","blasted_u":"Blasted Lands quest turn-ins (unconfirmed on Forever)","diremaul_u":"Dire Maul North vendor (unconfirmed on Forever)","wreckage_u":"Fishing (unconfirmed on Forever)","blasted":"Blasted Lands quest turn-ins","eko":"Winterspring: E'ko turn-ins","furbolg":"Drops from Winterfall furbolgs","argent":"Argent Dawn quartermaster","diremaul":"Dire Maul North vendor, after a tribute run","wreckage":"Fishing: floating wreckage","zandalar":"Zandalar Tribe: Zandalar Honor Token","felwood":"Felwood: cleansed plants"}
T={}
def tables(d):
    if d in T: return T[d]
    def load(n): return list(csv.DictReader(open(f'/tmp/{d}/{n}.csv',encoding='utf-8')))
    sp=load('ItemSparse'); rec={}
    for r in sp:
        m=re.match(r'(Recipe|Plans|Formula|Schematic|Manual): (.+)',r['Display_lang'])
        if m: rec[re.sub(r'\s+',' ',m.group(2))]=int(r['RequiredSkillRank'])
    sl={r['ID']:r['DisplayName_lang'] for r in load('SkillLine')}
    sla={}
    for r in load('SkillLineAbility'): sla.setdefault(r['Spell'],r)
    made={}
    for r in load('SpellEffect'):
        if r['Effect']=='24' and r.get('EffectItemType','0')!='0': made.setdefault(r['EffectItemType'],[]).append(r['SpellID'])
    rg={}
    for r in load('SpellReagents'):
        rg[r['SpellID']]=[(int(r[f'Reagent_{k}']),int(r[f'ReagentCount_{k}'])) for k in range(8) if int(r[f'Reagent_{k}'])>0]
    sn={r['ID']:re.sub(r'\s+',' ',r['Name_lang']) for r in load('SpellName')}
    T[d]=dict(rec=rec,sl=sl,sla=sla,made=made,rg=rg,sn=sn); return T[d]
yellow={}
def craft(d,i):
    t=tables(d); best=None
    for s in t['made'].get(str(i),[]):
        a=t['sla'].get(s)
        if not a: continue
        prof=t['sl'].get(a['SkillLine'])
        if prof not in PREF: continue
        if best is None or PREF.index(prof)<PREF.index(best[0]): best=(prof,s,int(a['TrivialSkillLineRankLow']))
    if not best: return None
    prof,s,y=best; yellow[(d,i)]=y
    skill=t['rec'].get(names[d][str(i)])
    if skill is None and i in KNOWN and (d=='wowera' or yellow.get(('wowera',i))==y): skill=KNOWN[i]
    return prof.lower().replace(' ',''),skill,t['rg'].get(s,[])
def mats(d,lst): return "{ "+", ".join('{ %d, %d, "%s" }'%(i,c,names[d].get(str(i),'?').replace('"','')) for i,c in lst)+" }"
notes={}
def block(data,tag,src):
    out=""
    for role in ("dps","tank"):
        out+=f"        {role} = {{\n"
        for sec,rows in data[role]:
            out+=f'            {{ "{sec}", {{\n'
            for i,note in rows:
                n=names[src].get(str(i)); assert n,(src,i)
                key=f"CONS_{tag}_{i}"; assert notes.get(key,note)==note,(key,note); notes[key]=note
                extra=""
                c=craft(src,i)
                if c:
                    extra+=f', prof = "{c[0]}"'+(f', skill = {c[1]}' if c[1] else '')
                    if c[2]: extra+=f', mats = {mats(src,c[2])}'
                    if i in EXTRA and src=='wowera': extra+=f', extra = L.{EXTRA[i]}'
                fr=(FROM_ERA if src=='wowera' else FROM_F).get(i)
                if fr: extra+=f', from = L.CONS_FROM_{fr}'
                out+=f'                {{ {i}, "{n}", L.{key}{extra} }},\n'
            out+="            } },\n"
        t=tables(src); rows=[]
        for s in ENCH[src][role]:
            nm=t['sn'][str(s)].replace('Formula: ','')
            skill=t['rec'].get(nm) or (int(t['sla'][str(s)]['TrivialSkillLineRankLow'])-20)
            fr=f', from = L.CONS_FROM_{ENCH_FROM[s]}' if s in ENCH_FROM else ''
            rows.append(f'                {{ spell = {s}, prof = "enchanting", skill = {skill}, mats = {mats(src,t["rg"].get(str(s),[]))}{fr} }},\n')
        out+='            { "enchant", {\n'+''.join(rows)+'            } },\n'
        out+="        },\n"
    return out
era_first=block(E,"E","wowera")      # Era first: Forever borrows its unchanged trainer recipes' levels
lua=open('tools/consumables/head.lua').read().replace('@FOREVER@',block(F,"F","wowf")).replace('@ERA@',era_first)
open('Rageborn/Consumables.lua','w').write(lua)
loc=open('tools/consumables/loc.txt').read()+''.join('L.CONS_FROM_%s = "%s"\n'%kv for kv in FROM_TEXT.items())+''.join('L.%s = "%s"\n'%kv for kv in sorted(notes.items()))
p='Rageborn/Locale.lua'; s=open(p).read(); mark='\n-- Consumables page\n'
if mark in s: s=s[:s.index(mark)]
open(p,'w').write(s+loc)
for t in ('Rageborn.toc','Rageborn_Camelot.toc','Rageborn_Vanilla.toc'):
    s=open('Rageborn/'+t).read()
    if 'Consumables.lua' not in s: open('Rageborn/'+t,'w').write(s.replace('Macros.lua\n','Macros.lua\nConsumables.lua\n'))
print(len(notes))
