const fs=require('fs');
const sv=(inner)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">${inner}</svg>`;
const F=(seed,amt)=>`<filter id="wob" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.09" numOctaves="2" seed="${seed}"/><feDisplacementMap in="SourceGraphic" scale="${amt}"/></filter>
<filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="${seed+3}"/><feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 .55 -.18"/><feComposite in2="SourceGraphic" operator="in"/></filter>`;
const brushRing=(col,r,w0,w1,start,sweep)=>{const n=80;let o=[],i2=[];for(let i=0;i<=n;i++){const t=i/n,a=start+sweep*t;const w=w0+(w1-w0)*Math.sin(Math.PI*Math.pow(t,.7));o.push([32+(r+w/2)*Math.cos(a),32+(r+w/2)*Math.sin(a)]);i2.push([32+(r-w/2)*Math.cos(a),32+(r-w/2)*Math.sin(a)])}
return `<path d="M${o.map(p=>p.map(v=>v.toFixed(1)).join(' ')).join(' L')} L${i2.reverse().map(p=>p.map(v=>v.toFixed(1)).join(' ')).join(' L')}Z" fill="${col}"/>`};
const sword=(o)=>`<g transform="rotate(${o.rot} 32 32)">
<path d="M32 5 L35.200 12 ${o.nick?'L35.800 26 L34.600 27.200 L35.900 28.600':''} L36.200 41 L27.800 41 L28.400 12 Z" fill="#e3ddd0" stroke="#22140c" stroke-width="${o.lw}" stroke-linejoin="round"/>
<path d="M32 5 L35.200 12 L36.200 41 L32.200 41 Z" fill="#8f9aa3"/>
<path d="M31.200 13 L31 38" stroke="#22140c" stroke-width=".9" opacity=".45" stroke-linecap="round"/>
<path d="M20.500 40.200 C24 42 40 41.200 44.200 39.500 L44.800 43.800 C40 45.800 25 46 20 44.500 Z" fill="#e2a43a" stroke="#22140c" stroke-width="${o.lw}" stroke-linejoin="round"/>
<path d="M29.300 45.300 L34.800 45.300 L34.300 54 L29.800 54 Z" fill="#6a361a" stroke="#22140c" stroke-width="${o.lw}"/>
<path d="M29.500 47.500 L34.600 46.300 M29.600 50.200 L34.500 49 M29.800 52.800 L34.400 51.700" stroke="#22140c" stroke-width=".8" opacity=".7"/>
<path d="M28.800 54 L35.300 54 L34.200 59 L30 59 Z" fill="#e2a43a" stroke="#22140c" stroke-width="${o.lw}" stroke-linejoin="round"/></g>`;
const h4=(o)=>{
const ring=o.closed
 ? `<circle cx="32" cy="32" r="21" fill="none" stroke="#b8571a" stroke-width="9"/><circle cx="32" cy="32" r="21" fill="none" stroke="#f0a630" stroke-width="6"/>${brushRing('#ffe7a3',22.5,0.6,2.4,-1.6,1.9)}`
 : `${brushRing('#b8571a',21,6,11,-2.1,5.9)}${brushRing('#f0a630',21,3.500,7.500,-1.9,5.500)}${brushRing('#ffe7a3',22.500,0.6,2.6,-1.6,1.9)}`;
const blot=o.blots?`<path d="M3 40 C20 34 44 46 61 36 L61 61 L3 61 Z" fill="#3a1f11"/><path d="M8 9 C22 5 40 12 56 7 L56 15 C40 19 22 12 8 17 Z" fill="#5d371e" opacity=".8"/>`:`<path d="M3 38 C22 35 42 41 61 37 L61 61 L3 61 Z" fill="#3f2212"/>`;
return `<defs>${F(21,o.wob)}</defs><rect width="64" height="64" rx="7" fill="#1b120c"/>
<g ${o.wob?'filter="url(#wob)"':''}><rect x="3" y="3" width="58" height="58" rx="5" fill="#4a2a17"/>${blot}
<circle cx="32" cy="32" r="16" fill="#7a4217" opacity=".7"/>${ring}
${sword({rot:o.rot,lw:o.lw,nick:o.nick})}
<rect x="3" y="3" width="58" height="58" rx="5" fill="none" stroke="#d99a34" stroke-width="2.800"/><path d="M6 5 L58 5" stroke="#ffe7a3" stroke-width="1" opacity=".7"/></g>
${o.grain?`<rect width="64" height="64" rx="7" fill="#000" filter="url(#grain)" opacity="${o.grain}"/>`:''}`};
const I={
 'H4_before':   h4({wob:2.2,grain:.6,blots:true, closed:false,rot:-8,lw:1.2,nick:true}),
 'P1_lighter':  h4({wob:1.2,grain:.3,blots:true, closed:false,rot:-8,lw:1.3,nick:true}),
 'P2_tidy':     h4({wob:.8, grain:0, blots:false,closed:false,rot:-8,lw:1.4,nick:true}),
 'P3_full_ring':h4({wob:.8, grain:.2,blots:false,closed:true, rot:-8,lw:1.4,nick:false}),
 'P4_crisp':    h4({wob:0,  grain:0, blots:false,closed:false,rot:-8,lw:1.5,nick:false}),
 'P5_crisp_upright':h4({wob:0,grain:0,blots:false,closed:true,rot:0,lw:1.5,nick:false}),
};
let html=`<body style="margin:0;background:#15151c;font:14px sans-serif;color:#ddd"><div style="display:flex;gap:26px;padding:22px">`;
let n=0;for(const[k,v0] of Object.entries(I)){const uniq=(v,s)=>v.replace(/id="(\w+)"/g,`id="$1${s}"`).replace(/url\(#(\w+)\)/g,`url(#$1${s})`);
fs.writeFileSync(k+'.svg',sv(v0));
html+=`<div style="text-align:center"><div style="width:128px;height:128px">${sv(uniq(v0,'a'+n))}</div><div style="margin:10px 0 6px">${k.replace(/_/g,' ')}</div><div style="display:flex;gap:8px;justify-content:center"><div style="width:32px;height:32px">${sv(uniq(v0,'b'+n))}</div><div style="width:64px;height:64px">${sv(uniq(v0,'c'+n))}</div></div></div>`;n++}
fs.writeFileSync('sheet.html',html+'</div></body>');
