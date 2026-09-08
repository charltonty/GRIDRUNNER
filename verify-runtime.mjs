import * as experience from './dist/experience.js';
import {CameraManager} from './dist/camera-manager.js';
import * as settlements from './dist/settlements.js';
import * as survival from './dist/survival.js';
// Full module/DOM integration with real Three.js scene objects. WebGL is stubbed;
// this suite does NOT claim GPU, screenshot, pointer-lock or audio listening QA.
import {JSDOM} from 'jsdom';
import fs from 'node:fs';import vm from 'node:vm';import assert from 'node:assert/strict';
import * as Three from './dist/three.js';
import * as drone from './dist/drone-system.js';import * as immersion from './dist/immersion.js';
import * as leg2 from './dist/leg2.js';import * as leg3 from './dist/leg3.js';import * as expedition from './dist/expedition.js';import * as visuals from './dist/visuals.js';import {FieldAudio} from './dist/audio.js';
const dom=new JSDOM(fs.readFileSync('dist/index.html','utf8'),{url:'http://gridrunner.test/'}),w=dom.window;globalThis.devicePixelRatio=1;globalThis.document=w.document;globalThis.window=w;
const context2d=new Proxy({measureText:()=>({width:50}),createLinearGradient:()=>({addColorStop(){}})}, {get:(o,k)=>k in o?o[k]:()=>{}});
w.HTMLCanvasElement.prototype.getContext=()=>context2d;
w.HTMLCanvasElement.prototype.setPointerCapture=()=>{};w.document.exitPointerLock=()=>{};w.HTMLCanvasElement.prototype.requestPointerLock=()=>Promise.resolve();
let frames=0;class NullRenderer{constructor(){this.shadowMap={};this.info={render:{calls:0}};}setPixelRatio(){}setSize(){}render(scene,camera){assert(scene.isScene&&camera.isPerspectiveCamera);frames++;}}
const ctx=vm.createContext({...experience,CameraManager,augmentPOVPanel(){},...settlements,...survival,T:{...Three,WebGLRenderer:NullRenderer},...drone,...immersion,...leg2,...leg3,...expedition,...visuals,FieldAudio,console,performance,Math,Date,JSON,Number,Map,Set,Float32Array,window:w,document:w.document,localStorage:w.localStorage,matchMedia:()=>({matches:false}),devicePixelRatio:1,innerWidth:1280,innerHeight:800,requestAnimationFrame(){},setTimeout(){},URL,Blob,location:{reload(){}},confirm:()=>true});
const source=fs.readFileSync('dist/game.js','utf8').replace(/^import .*;\n/gm,'');
vm.runInContext(source,ctx);const run=code=>vm.runInContext(code,ctx);
const tick=(seconds)=>{for(let i=0;i<seconds*50;i++)run('update(.02)');run('hud();loop(performance.now()+20)');};
assert(w.document.querySelector('#panel').textContent.includes('v7'));
w.document.querySelector('[data-ui=new]').click();assert.equal(run('s.mode'),'bike');run("keys.w=true");tick(2);run('keys={}');assert(run('s.pos.z')<15,'Bike advances');
run("action('drone');keys.w=true;keys[' ']=true");tick(2);run('keys={}');assert.equal(run('s.mode'),'drone');assert(run('s.droneSystem.altitude')>5);const alt=run('s.pos.y');run('keys.shift=true');tick(3);run('keys={}');assert(run('s.pos.y')<alt,'Shift descends');run("action('scan')");assert(run('s.discoveries.length')>0,'Scan tags saved');
run("issueDrone('FOLLOW');keys.w=true");tick(4);run('keys={}');assert.equal(run('s.mode'),'bike');assert.equal(run('s.droneSystem.mode'),'FOLLOW');run("issueDrone('HOLD')");tick(15);assert.equal(run('s.droneSystem.mode'),'HOLD');run("issueDrone('DOCK')");tick(30);assert.equal(run('s.droneSystem.mode'),'DOCK');
assert(run("writeSave('manual1')"));const saved=run('s.discoveries.length');run("s.discoveries=[];restore(getSave('manual1'))");assert.equal(run('s.discoveries.length'),saved);run("open('settings')");assert.equal(w.document.querySelectorAll('[data-setting=graphics] option').length,4);
for(const preset of ['LOW','MEDIUM','HIGH','ULTRA'])run(`settings.graphics='${preset}';applySettings();loop(performance.now()+30)`);
for(const screen of ['start','pause','quick','saves','settings','controls','rig','drones','journal','guide','reference','inventory','map']){run(`open('${screen}')`);assert(!w.document.querySelector('#panel').textContent.includes('undefined'),screen);}
// Fixture positioning tests the real interaction and mission chain without a manual ride.
function at(x,y,z){run(`s.pos.set(${x},${y},${z});s.speed=0;keys={};`);tick(.02);}
run('newExpedition()');at(54,1.7,-94);run('interact();play()');assert(run('s.met'));at(79,1.7,-408);run('interact()');assert(run('s.towerCode'));at(0,1.7,-1435);run('interact()');assert(run('s.won'));run('startLegTwo(false)');assert.equal(run('s.leg'),2);
at(45,1.7,-1810);run('interact();play()');assert(run('s.calMet'));run("issueDrone('MANUAL');s.droneSystem.pos=[118,22,-2380];s.pos.set(118,22,-2380)");tick(.02);run('interact()');assert(run('s.intakeCleared'));run("issueDrone('DOCK')");
at(70,1.7,-2260);run('interact()');assert(run('s.phaseNote'));at(65,1.7,-2355);run("interact();operatePhase('B');operatePhase('A');operatePhase('C');play()");assert(run('s.hydroRestored'));
run('s.battery=45');at(0,1.7,-3020);run('interact();interact()');assert(run('s.leg2Won'));run('startLegThree(false)');assert.equal(run('s.leg'),3);
run("s.engineerBuilt=true;s.droneType='engineer';issueDrone('MANUAL');s.droneSystem.pos=[65,20,-3510];s.pos.set(65,20,-3510)");tick(.02);run('interact()');assert(run('s.securityOff'));run("issueDrone('DOCK')");at(-55,1.7,-3780);run('interact()');assert(run('s.archiveKey'));at(50,1.7,-3980);run('interact();s.dialA=3;s.dialB=1;s.dialC=4;alignAntenna();play()');assert(run('s.antennaAligned'));run('s.battery=60');at(60,1.7,-4310);run('interact()');assert(run('s.capacitorReady'));at(0,1.7,-4590);run("interact();finishLegThree('restore')");assert(run('s.leg3Won'));assert(run("writeSave('manual2')"));run("s.ending='';restore(getSave('manual2'))");assert.equal(run('s.ending'),'restore');
// Existing v6 record missing all new fields migrates; invalid optional data fails.
const legacy=run('snapshot()');delete legacy.state.droneSystem;delete legacy.state.discoveries;expedition.validateSave(legacy);assert.equal(legacy.state.droneSystem.mode,'DOCK');
// Check live scene numbers; shader compilation is deliberately outside this test.
run('scene.updateMatrixWorld(true)');const stats=run('(()=>{let meshes=0,triangles=0;scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count||o.geometry.attributes.position.count)/3*(o.isInstancedMesh?o.count:1);if(o.matrixWorld.elements.some(n=>!Number.isFinite(n)))throw Error("Invalid transform");}});return {meshes,triangles};})()');
console.log('PASS: full startup, actual DOM menus, input-driven bike/drone updates, commands, scan persistence, save/restore, presets, all three real mission chains and final save. Render stub frames:',frames,stats);
// Fieldwork: real DOM events, transactions, mining and persistent depleted state.
run('newExpedition();s.inv.toaster=1;open("supplies")');
w.document.querySelector('[data-field=salvage][data-item=toaster]').click();assert.equal(run('s.inv.toaster'),0);assert.equal(run('s.inv.copper'),1);
run('s.pos.copy(bike.position);open("supplies")');w.document.querySelector('[data-field=store][data-item=copper][data-storage=bike]').click();assert.equal(run('s.field.storage.bike.copper'),1);assert.equal(run('s.inv.copper'),0);
w.document.querySelector('[data-field=retrieve][data-item=copper][data-storage=bike]').click();assert.equal(run('s.inv.copper'),1);
run('s.inv.steel=4;s.inv.rubber=1;s.pos.copy(trailer.position);open("supplies")');w.document.querySelector('[data-field=craft][data-item=pickaxe]').click();assert.equal(run('s.inv.pickaxe'),1);
run('activeField=s.field.world.find(p=>p.kind==="node").id;s.pos.set(s.field.world[5].x,1.7,s.field.world[5].z);open("supplies")');w.document.querySelector('[data-field=mine]').click();tick(4.2);assert.equal(run('s.field.world[5].left'),3);assert.equal(run('fieldJob'),null);
run('s.inv.fuel=1;s.fuel=0;s.pos.copy(trailer.position);open("supplies")');w.document.querySelector('[data-field=refuel]').click();assert.equal(run('s.fuel'),1);assert.equal(run('s.inv.fuel'),0);
assert(run('writeSave("manual1")'));run('s.field.storage.bike={};s.field.world[5].left=4;restore(getSave("manual1"))');assert.equal(run('s.field.world[5].left'),3);
const old=run('snapshot()');delete old.state.field;assert.equal(expedition.validateSave(old).state.field.world.length,144);
run('newExpedition();s.pos.set(54,1.7,-94);s.inv.steel=20');for(let i=0;i<3;i++){run('open("rig")');w.document.querySelector('[data-ui=fuel]').click();}assert.equal(run('s.field.fuelTrades'),2);assert.equal(run('s.inv.steel'),12);
const inaccessible=run('s.field.world.filter(p=>solids.some(b=>Math.abs(p.x-b.x)<b.w+2&&Math.abs(p.z-b.z)<b.d+2)).map(p=>p.id)');console.log('Field sites near solid infrastructure:',inaccessible);
console.log('PASS: DOM salvage, cargo transfer, fabrication, timed mining, fuel pour, finite trade, depletion save/reload and legacy field migration.');
run('open("controls")');const launchSelect=w.document.querySelector('[data-remap=q]');launchSelect.value='z';launchSelect.dispatchEvent(new w.Event('change',{bubbles:true}));assert.equal(run('mappedKey("z")'),'q');assert.equal(run('mappedKey("q")'),'');run('play()');w.dispatchEvent(new w.KeyboardEvent('keydown',{key:'z'}));assert.equal(run('s.mode'),'drone');assert.equal(JSON.parse(w.localStorage.getItem('gridrunner.keys')).q,'z');
console.log('PASS: visible rebind UI, persisted launch mapping, old key disabled and real remapped launch event.');
// Settlements: proximity-gated real interaction, finite barter and save migration.
run('newExpedition();s.pos.set(-123,1.7,-146);s.inv.steel=4');tick(.02);assert.equal(run('nearest.id'),'riggs');run('interact()');assert(w.document.querySelector('#panel').textContent.includes('Riggs'));w.document.querySelector('[data-resident-trade=riggs]').click();assert.equal(run('s.inv.cutters'),1);assert.equal(run('s.inv.steel'),2);assert.equal(run('s.residents.riggs.trades'),1);assert(w.document.querySelector('[data-resident-trade=riggs]').disabled);
assert(run('writeSave("manual1")'));run('s.residents={};restore(getSave("manual1"))');assert.equal(run('s.residents.riggs.trades'),1);run('open("journal")');assert(w.document.querySelector('#panel').textContent.includes('Seized motors'));
const noResidents=run('snapshot()');delete noResidents.state.residents;assert.deepEqual(expedition.validateSave(noResidents).state.residents,{});const badResidents=run('snapshot()');badResidents.state.residents.riggs.trades=999;assert.throws(()=>expedition.validateSave(badResidents));
run('s.pos.set(-126,1.7,-160)');const beforeZ=run('s.pos.z');run('move(0,-1)');assert(run('s.pos.z')<beforeZ,'Open front is walkable');
for(const leg of [1,2,3]){run(`s.leg=${leg};settlementWorld.update(s,0,"LOW")`);assert.equal(run('settlementWorld.groups.filter(p=>p.g.visible&&p.site.leg!==s.leg).length'),0);}
console.log('PASS: resident interaction, finite trade, journal, save/reload/migration, malformed stock rejection, walkable interior and settlement Leg culling.');
run('newExpedition();settings.autosave=false');for(let i=0;i<8;i++){run('changePOV();loop(performance.now()+20)');assert.equal(run('s.mode'),'bike');}run('s.experience.preferred.bike="wide";s.mode="foot";changePOV();loop(performance.now()+20)');assert.equal(run('s.experience.preferred.walking'),'shoulder');assert.equal(run('s.experience.preferred.bike'),'wide');assert(run('walkingBody.visible'));
run('s.mode="bike";issueDrone("MANUAL");s.experience.preferred.drone="chase";loop(performance.now()+20)');assert.equal(run('s.mode'),'drone');assert(run('scoutMesh.visible'));run('issueDrone("FOLLOW");loop(performance.now()+20)');assert.equal(run('s.mode'),'bike');assert.equal(run('s.experience.preferred.bike'),'wide');
assert(run('writeSave("manual1")'));run('s.experience=createExperience();restore(getSave("manual1"))');assert.equal(run('s.experience.preferred.drone'),'chase');assert.equal(run('s.experience.preferred.walking'),'shoulder');const oldPOV=run('snapshot()');delete oldPOV.state.experience;assert.equal(expedition.validateSave(oldPOV).state.experience.preferred.bike,'helmet');
run('open("settings")');assert.equal(w.document.querySelectorAll('[data-pov-state]').length,6);run('settings.reduceMotion=true;loop(performance.now()+20)');assert.equal(run('povCamera.transition'),0);
console.log('PASS: repeated POV cycles, walking body, drone chase/return, independent view persistence, old-save defaults, settings UI and reduced-motion transitions.');
