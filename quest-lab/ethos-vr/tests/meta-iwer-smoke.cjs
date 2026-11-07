'use strict';
// Test is executed in GitHub Actions, not in the Quest production build.
// Uses official Meta IWER 2.8.0 Meta Quest 3 profile.
const fs=require('fs');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:[
  '--no-sandbox','--use-gl=angle','--use-angle=swiftshader',
  '--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader',
  '--disable-dev-shm-usage'
 ]});
 const page=await browser.newPage({viewport:{width:1280,height:720},deviceScaleFactor:1});
 const failures=[];
 page.on('pageerror',e=>failures.push('pageerror: '+e.message));
 page.on('console',m=>{if(m.type()==='error')failures.push('console: '+m.text())});
 page.on('requestfailed',r=>{if(!/favicon\.ico/.test(r.url()))failures.push('request failed: '+r.url()+' '+r.failure()?.errorText)});
 await page.addInitScript({path:'/tmp/ethos-iwer/meta-iwer-bootstrap.bundle.js'});
 const site='http://localhost:8765/quest-lab/ethos-vr/?questqa=1';
 await page.goto(site,{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>window.__ethosMetaEmulator&&document.querySelector('#vr')?.disabled===false,null,{timeout:25000});
 const button=await page.locator('#vr').innerText();
 if(!button.includes('STEREOSCOPIC'))throw Error('Meta emulator VR unavailable: '+button);
 await page.locator('#vr').click();
 try{
  await page.waitForFunction(()=>window.__ETHOS_QUEST_QA?.xrFrames>=12,null,{timeout:30000});
 }catch(e){const diag=await page.evaluate(()=>({qa:window.__ETHOS_QUEST_QA,status:document.querySelector('#diag')?.textContent}));
 throw Error('Meta IWER did not render XR frames: '+JSON.stringify(diag)+' errors='+failures.join('|'));}
 const first=await page.evaluate(()=>structuredClone(window.__ETHOS_QUEST_QA));
 if(first.eyes!==2||first.eyeLabels.join(',')!=='left,right')throw Error('Not stereo: '+JSON.stringify(first));
 if(first.viewportWidths.length!==2||first.viewportWidths.some(x=>x<=0))throw Error('Missing per-eye WebGL viewport: '+JSON.stringify(first));
 if(first.headPosition===null)throw Error('No 6DoF head pose');
 if(first.referenceSpace!=='local-floor'&&first.referenceSpace!=='local')throw Error('Bad reference space');
 if(first.error||first.contextLost)throw Error('WebGL or WebXR session failed: '+JSON.stringify(first));
 const eyeSeparation=Math.hypot(...first.eyeOffsets[1].map((v,i)=>v-first.eyeOffsets[0][i]));
 if(eyeSeparation<0.04||eyeSeparation>0.085)throw Error('IPD outside real stereo range: '+eyeSeparation+' '+JSON.stringify(first.eyeOffsets));
 // Exercise Meta Quest 3 headset tracking, not a fake duplicate camera.
 await page.evaluate(()=>{window.__questIWER.position.x+=.17;window.__questIWER.position.y+=.09;});
 await page.waitForTimeout(750);
 const later=await page.evaluate(()=>structuredClone(window.__ETHOS_QUEST_QA));
 const delta=Math.hypot(...later.headPosition.map((v,i)=>v-first.headPosition[i]));
 if(delta<.1)throw Error('Head movement did not propagate through WebXR viewer pose: delta '+delta);
 if(later.xrFrames<=first.xrFrames)throw Error('XR animation loop stopped');
 if(later.inputProfiles.length<2)throw Error('Meta Quest input sources not connected: '+JSON.stringify(later.inputProfiles));

 // Emulate left thumbstick, right snap-turn and right controller trigger
 // with the actual Meta IWER Touch Plus controller API.
 const beforeControls=await page.evaluate(()=>structuredClone(window.__ETHOS_QUEST_QA));
 await page.evaluate(()=>window.__questIWER.controllers.left.updateAxes('thumbstick',0,-1));
 await page.waitForTimeout(1100);
 await page.evaluate(()=>window.__questIWER.controllers.left.updateAxes('thumbstick',0,0));
 await page.waitForTimeout(250);
 const afterMove=await page.evaluate(()=>structuredClone(window.__ETHOS_QUEST_QA));
 const moved=Math.hypot(afterMove.player[0]-beforeControls.player[0],afterMove.player[1]-beforeControls.player[1]);
 if(moved<.06)throw Error('Quest left-stick locomotion failed: '+moved+' '+JSON.stringify({beforeControls:beforeControls.player,after:afterMove.player}));
 await page.evaluate(()=>window.__questIWER.controllers.right.updateAxes('thumbstick',.92,0));
 await page.waitForTimeout(450);
 await page.evaluate(()=>window.__questIWER.controllers.right.updateAxes('thumbstick',0,0));
 await page.waitForTimeout(250);
 const afterTurn=await page.evaluate(()=>structuredClone(window.__ETHOS_QUEST_QA));
 const snap=Math.abs(afterTurn.player[2]-afterMove.player[2]);
 if(snap<.38||snap>.71)throw Error('Quest right-stick snap turn failed: '+snap);
 await page.evaluate(()=>window.__questIWER.controllers.right.updateButtonValue('trigger',1));
 await page.waitForTimeout(300);
 await page.evaluate(()=>window.__questIWER.controllers.right.updateButtonValue('trigger',0));
 await page.waitForTimeout(300);
 const afterTrigger=await page.evaluate(()=>structuredClone(window.__ETHOS_QUEST_QA));
 if(afterTrigger.selectEvents<=beforeControls.selectEvents)throw Error('Quest Touch Plus trigger did not fire WebXR selectstart: '+JSON.stringify(afterTrigger));
 if(afterTrigger.lastSelectHand!=='right')throw Error('Wrong Quest controller event handedness: '+afterTrigger.lastSelectHand);

 await page.screenshot({path:'/tmp/ethos-iwer/meta-iwer-quest3.png'});
 const summary={profile:"Meta Quest 3",emulator:later.emulator,
  frames:later.xrFrames,eyes:later.eyes,
  ipdMeters:eyeSeparation,headMotionMeters:delta,
  controllers:later.inputProfiles,referenceSpace:later.referenceSpace,
  viewportWidths:later.viewportWidths,
  frameMs:later.frameMs,frameRate:later.frameRate,
  leftStickMeters:moved,rightSnapRadians:snap,triggerEvents:afterTrigger.selectEvents,
  consoleErrors:failures};
 fs.writeFileSync('/tmp/ethos-iwer/meta-iwer-result.json',JSON.stringify(summary,null,2));
 console.log('META QUEST 3 IWER TEST RESULT\n'+JSON.stringify(summary,null,2));
 if(failures.length)throw Error('Browser errors found: '+failures.join('\n'));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
