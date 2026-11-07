"use strict";
/* Project Ethos fan-room VR. WebXR + WebGL1, no CDN or engine dependency.
   Kenney CC0 .glb props are bundled in ./assets/ . Not an official 2K game. */
(function(){
const $=id=>document.getElementById(id);
const canvas=$("scene"),caption=$("caption"),hint=$("hint"),fps=$("fps"),menu=$("menu"),status=$("diag");
const gl=canvas.getContext("webgl",{antialias:true,alpha:false,depth:true,premultipliedAlpha:false,xrCompatible:true});
if(!gl){status.textContent="WebGL is unavailable. Please use Meta Quest Browser.";return;}
const isTouch=("ontouchstart" in window)&&matchMedia("(pointer:coarse)").matches;
const I=()=>new Float32Array([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]);
function multiply(a,b){const o=new Float32Array(16);for(let c=0;c<4;c++)for(let r=0;r<4;r++)o[c*4+r]=a[r]*b[c*4]+a[4+r]*b[c*4+1]+a[8+r]*b[c*4+2]+a[12+r]*b[c*4+3];return o;}
function tr(x,y,z){const o=I();o[12]=x;o[13]=y;o[14]=z;return o;}
function sc(x,y,z){const o=I();o[0]=x;o[5]=y;o[10]=z;return o;}
function ry(t){const c=Math.cos(t),s=Math.sin(t);return new Float32Array([c,0,-s,0,0,1,0,0,s,0,c,0,0,0,0,1]);}
function rx(t){const c=Math.cos(t),s=Math.sin(t);return new Float32Array([1,0,0,0,0,c,s,0,0,-s,c,0,0,0,0,1]);}
function quat(x,y,z,w){return new Float32Array([1-2*y*y-2*z*z,2*x*y+2*z*w,2*x*z-2*y*w,0,2*x*y-2*z*w,1-2*x*x-2*z*z,2*y*z+2*x*w,0,2*x*z+2*y*w,2*y*z-2*x*w,1-2*x*x-2*y*y,0,0,0,0,1]);}
function perspective(fovy,aspect,n,f){const t=1/Math.tan(fovy/2);return new Float32Array([t/aspect,0,0,0,0,t,0,0,0,0,(f+n)/(n-f),-1,0,0,2*f*n/(n-f),0]);}
function point(m,p){return [m[0]*p[0]+m[4]*p[1]+m[8]*p[2]+m[12],m[1]*p[0]+m[5]*p[1]+m[9]*p[2]+m[13],m[2]*p[0]+m[6]*p[1]+m[10]*p[2]+m[14]];}
function vector(m,p){return [m[0]*p[0]+m[4]*p[1]+m[8]*p[2],m[1]*p[0]+m[5]*p[1]+m[9]*p[2],m[2]*p[0]+m[6]*p[1]+m[10]*p[2]];}
function compile(type,source){const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;}
function program(v,f){const p=gl.createProgram();gl.attachShader(p,compile(gl.VERTEX_SHADER,v));gl.attachShader(p,compile(gl.FRAGMENT_SHADER,f));gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(p));return p;}
const meshP=program(
"attribute vec3 aP,aN,aC;attribute float aE;attribute vec2 aUV;uniform mat4 uP,uV,uM;varying vec3 vC;varying float vD;varying vec2 vUV;void main(){vec4 w=uM*vec4(aP,1.);vec3 n=normalize(mat3(uM)*aN);float sun=max(dot(n,normalize(vec3(-.55,.88,.52))),0.);float lamp=max(dot(n,normalize(vec3(.46,.68,-.52))),0.);float light=.31+.53*sun+.16*lamp;vC=aC*mix(light,1.08,aE);vD=length(w.xyz);vUV=aUV;gl_Position=uP*uV*w;}",
"precision mediump float;varying vec3 vC;varying float vD;varying vec2 vUV;uniform sampler2D uTexMesh;uniform float uHasTex;void main(){float fog=clamp((vD-8.)/12.,0.,.15);vec3 c=vC;if(uHasTex>.5)c*=texture2D(uTexMesh,vUV).rgb;gl_FragColor=vec4(mix(c,vec3(.055,.081,.125),fog),1.);}");
const texP=program(
"attribute vec3 aP;attribute vec2 aUV;uniform mat4 uP,uV,uM;varying vec2 vUV;void main(){vUV=aUV;gl_Position=uP*uV*uM*vec4(aP,1.);}",
"precision mediump float;varying vec2 vUV;uniform sampler2D uTex;void main(){gl_FragColor=texture2D(uTex,vUV);}");
function loc(p,n){return gl.getUniformLocation(p,n);}
const mu={p:loc(meshP,"uP"),v:loc(meshP,"uV"),m:loc(meshP,"uM"),has:loc(meshP,"uHasTex"),tex:loc(meshP,"uTexMesh")},tu={p:loc(texP,"uP"),v:loc(texP,"uV"),m:loc(texP,"uM"),tex:loc(texP,"uTex")};
const attrsMesh=["aP","aN","aC","aE","aUV"].map(n=>gl.getAttribLocation(meshP,n));
const attrsTex=["aP","aUV"].map(n=>gl.getAttribLocation(texP,n));
const posterQuad=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,posterQuad);
gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([
-.5,-.5,0,0,0,.5,-.5,0,1,0,.5,.5,0,1,1,
-.5,-.5,0,0,0,.5,.5,0,1,1,-.5,.5,0,0,1]),gl.STATIC_DRAW);
gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);gl.clearColor(.045,.065,.095,1);
function mesh(data){const b=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,b);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(data),gl.STATIC_DRAW);return {buffer:b,count:data.length/12};}
function meshDraw(g,m,tex){gl.bindBuffer(gl.ARRAY_BUFFER,g.buffer);for(let i=0;i<5;i++){gl.enableVertexAttribArray(attrsMesh[i]);gl.vertexAttribPointer(attrsMesh[i],i===3?1:i===4?2:3,gl.FLOAT,false,48,[0,12,24,36,40][i]);}gl.uniformMatrix4fv(mu.m,false,m);gl.uniform1f(mu.has,tex?1:0);gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,tex||null);gl.uniform1i(mu.tex,0);gl.drawArrays(gl.TRIANGLES,0,g.count);}
function texDraw(t,m){gl.bindBuffer(gl.ARRAY_BUFFER,posterQuad);gl.enableVertexAttribArray(attrsTex[0]);gl.vertexAttribPointer(attrsTex[0],3,gl.FLOAT,false,20,0);gl.enableVertexAttribArray(attrsTex[1]);gl.vertexAttribPointer(attrsTex[1],2,gl.FLOAT,false,20,12);gl.uniformMatrix4fv(tu.m,false,m);gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,t);gl.uniform1i(tu.tex,0);gl.drawArrays(gl.TRIANGLES,0,6);}
const roomV=[];
function box(x,y,z,w,h,d,color,emit=0){
 const a=[x-w/2,y-h/2,z-d/2],b=[x+w/2,y+h/2,z+d/2];
 const faces=[
 [[a[0],b[1],a[2]],[b[0],b[1],a[2]],[b[0],b[1],b[2]],[a[0],b[1],b[2]],[0,1,0]],
 [[a[0],a[1],b[2]],[b[0],a[1],b[2]],[b[0],a[1],a[2]],[a[0],a[1],a[2]],[0,-1,0]],
 [[a[0],a[1],b[2]],[b[0],a[1],b[2]],[b[0],b[1],b[2]],[a[0],b[1],b[2]],[0,0,1]],
 [[b[0],a[1],a[2]],[a[0],a[1],a[2]],[a[0],b[1],a[2]],[b[0],b[1],a[2]],[0,0,-1]],
 [[b[0],a[1],b[2]],[b[0],a[1],a[2]],[b[0],b[1],a[2]],[b[0],b[1],b[2]],[1,0,0]],
 [[a[0],a[1],a[2]],[a[0],a[1],b[2]],[a[0],b[1],b[2]],[a[0],b[1],a[2]],[-1,0,0]]
 ];
 for(const f of faces)for(const i of [0,1,2,0,2,3])roomV.push(...f[i],...f[4],...color,emit,0,0);
}
function buildRoom(){
 box(0,-.09,0,7.7,.18,7.7,[.28,.19,.16]);
 for(let i=0;i<29;i++){const z=-3.68+i*.263;box(0,.016,z,7.58,.035,.240,[i%3===0?.38:.34,i%3===0?.245:.218,.18]);}
 box(0,1.55,-3.83,7.7,3.1,.13,[.21,.267,.32]);
 box(0,1.55,3.83,7.7,3.1,.13,[.17,.225,.277]);
 box(-3.83,1.55,0,.13,3.1,7.7,[.18,.24,.29]);
 box(3.83,1.55,0,.13,3.1,7.7,[.18,.24,.29]);
 box(0,3.13,0,7.7,.13,7.7,[.16,.196,.246]);
 for(let x of [-3.72,3.72]){box(x,.11,0,.10,.22,7.55,[.34,.35,.38]);box(x,2.98,0,.11,.07,7.55,[.31,.35,.39]);}
 for(let z of [-3.72,3.72]){box(0,.11,z,7.55,.22,.10,[.34,.35,.38]);box(0,2.98,z,7.55,.07,.1,[.31,.35,.39]);}
 // Striped back workstation accent
 for(let i=0;i<19;i++)box(-.95+i*.125,1.52,-3.725,.048,2.60,.08,[.145,.195,.235]);
 // window with blinds on right wall
 box(3.71,1.96,.83,.06,1.65,1.95,[.086,.14,.20]);
 box(3.65,1.96,.83,.055,1.52,1.83,[.24,.42,.52]);
 for(let j=0;j<10;j++)box(3.59,1.26+j*.145,.83,.03,.035,1.86,[.52,.58,.59]);
 box(3.56,1.96,-.16,.085,1.72,.045,[.44,.41,.39]);box(3.56,1.96,1.81,.085,1.72,.045,[.44,.41,.39]);
 // Rug and under desk lights
 box(-1.72,.047,.10,2.8,.02,2.45,[.24,.30,.34]);
 for(let i=0;i<8;i++)box(-2.85+i*.33,.061,.10,.045,.004,2.27,[.37,.43,.46]);
 box(.19,.46,-3.14,2.23,.035,.10,[.17,.86,.78],1);
 // Physical door
 box(2.25,1.19,3.72,1.45,2.35,.055,[.27,.29,.32]);
 box(2.90,1.17,3.64,.10,.06,.12,[.85,.73,.45]);
 for(let i=0;i<3;i++)box(2.23,1.78-i*.34,3.655,1.14,.045,.04,[.35,.375,.39]);
 // Ceiling and lamp emissive
 box(.3,3.015,-.6,1.2,.06,.35,[.58,.92,.89],1);
 box(-2.76,2.91,-2.6,.18,.05,.18,[1,.75,.47],1);
 // LED strip shelf highlights
 box(2.92,1.46,-3.51,1.05,.03,.12,[.34,.93,.85],1);
 // Wooden trim on back shelf
 for(let y of [.42,1.08,1.74,2.40])box(2.84,y,-3.37,1.13,.06,.39,[.19,.14,.12]);
 // Low table, trash, shrine
 box(1.85,.39,.40,.98,.10,.78,[.19,.24,.29]);for(let x of [1.44,2.26])for(let z of [.06,.74])box(x,.20,z,.07,.35,.07,[.12,.17,.20]);
 box(2.63,.26,1.84,.41,.51,.42,[.17,.23,.26]);
 box(2.63,.525,1.84,.41,.04,.42,[.37,.49,.50]);
 box(-3.53,1.42,-.78,.32,1.4,1.08,[.16,.24,.27]);
 for(let y of [.78,1.30,1.82,2.10])box(-3.31,y,-.78,.38,.055,1.02,[.32,.25,.18]);
 box(-3.32,1.84,-.80,.1,.18,.11,[.9,.52,.25],1);
 box(-3.32,1.83,-.54,.1,.18,.11,[.9,.52,.25],1);
 // Loose box stacks, cables, empty cups
 box(-.88,.12,2.34,.50,.24,.45,[.30,.245,.16]);
 box(-.92,.30,2.28,.34,.05,.41,[.39,.31,.21]);
 box(2.15,.09,2.80,.31,.18,.28,[.22,.22,.25]);
 for(let i=0;i<4;i++)box(2.52,1.12+i*.05,-3.10,.32,.035,.20,[.22+i*.04,.41-i*.02,.48-i*.03]);
}
buildRoom();const roomG=mesh(roomV);
let assets={},props=[],loaded=0,failed=0;const expected=["beddouble","desk","chairdesk","computerscreen","computerkeyboard","computermouse","bookcaseopen","lamproundfloor","plantsmall2","sidetabledrawers","tablecoffeesquare","loungedesignchair","pizza-box","soda-can","cup-coffee","pizza"];
const placements=[
 ["beddouble",-2.30,.06,-.50,2.20,0],
 ["desk",.32,.04,-2.85,1.95,Math.PI],
 ["chairdesk",.55,.03,-1.47,.77,0],
 ["computerscreen",.35,.82,-2.82,.78,Math.PI],
 ["computerkeyboard",.30,.77,-2.22,.64,Math.PI],
 ["computermouse",.87,.77,-2.20,.12,Math.PI],
 ["bookcaseopen",2.78,.04,-2.75,.86,Math.PI/2],
 ["lamproundfloor",-3.14,.03,-2.62,.38,0],
 ["plantsmall2",2.76,.86,-2.84,.31,0],
 ["sidetabledrawers",-3.22,.05,-1.90,.62,Math.PI/2],
 ["tablecoffeesquare",1.68,.02,1.04,.88,.1],
 ["loungedesignchair",2.92,.04,1.28,.73,Math.PI],
 ["pizza-box",1.86,.45,.46,.55,0],
 ["soda-can",1.65,.48,.32,.13,0],
 ["cup-coffee",.86,.76,-2.63,.17,0],
 ["pizza",1.89,.52,.46,.38,0]
];
function accessor(g,binStart,dv,id,j){
 const a=g.accessors[id],bv=g.bufferViews[a.bufferView];const types={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT4:16};const sizes={5120:1,5121:1,5122:2,5123:2,5125:4,5126:4},count=types[a.type],size=sizes[a.componentType];
 const offset=binStart+(bv.byteOffset||0)+(a.byteOffset||0)+j*(bv.byteStride||count*size);
 const out=[];
 for(let k=0;k<count;k++){const p=offset+k*size;let v=0;switch(a.componentType){case 5120:v=dv.getInt8(p);break;case 5121:v=dv.getUint8(p);break;case 5122:v=dv.getInt16(p,true);break;case 5123:v=dv.getUint16(p,true);break;case 5125:v=dv.getUint32(p,true);break;case 5126:v=dv.getFloat32(p,true);break;}
 out.push(v);}
 return out;
}
async function parseGLB(array){
 const dv=new DataView(array);if(dv.getUint32(0,true)!==0x46546c67)throw Error("Invalid GLB");
 let p=12,g=null,binStart=0;
 while(p<array.byteLength){const n=dv.getUint32(p,true),type=dv.getUint32(p+4,true);p+=8;if(type===0x4e4f534a){g=JSON.parse(new TextDecoder().decode(new Uint8Array(array,p,n)));}else if(type===0x004e4942)binStart=p;p+=n;}
 if(!g||!binStart)throw Error("GLB missing JSON or mesh");
 const parts=[],min=[1e9,1e9,1e9],max=[-1e9,-1e9,-1e9];
 const imageTextures=await Promise.all((g.images||[]).map(async im=>{
  if(im.bufferView===undefined)return null;
  const bv=g.bufferViews[im.bufferView],imgBuffer=new Uint8Array(array,binStart+(bv.byteOffset||0),bv.byteLength);
  try{
   const image=await createImageBitmap(new Blob([imgBuffer],{type:im.mimeType||"image/png"}));
   const t=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,t);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false);
   gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);
   gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);
   gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
   gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);
   gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);image.close();return t;
  }catch(e){console.warn("GLB image decode failed",e);return null;}
 }));
 function traverse(id,parent){
  const n=g.nodes[id],pos=n.translation||[0,0,0],q=n.rotation||[0,0,0,1],sz=n.scale||[1,1,1];
  const matrix=n.matrix?new Float32Array(n.matrix):multiply(multiply(tr(...pos),quat(...q)),sc(...sz));
  const transform=multiply(parent,matrix);
  if(n.mesh!==undefined){for(const primitive of g.meshes[n.mesh].primitives){
   if(primitive.mode!==undefined&&primitive.mode!==4)continue;
   const pm=g.materials?.[primitive.material||0]||{},col=pm.pbrMetallicRoughness?.baseColorFactor||[.8,.8,.8,1];
   const a=primitive.attributes;
   const num=primitive.indices!==undefined?g.accessors[primitive.indices].count:g.accessors[a.POSITION].count;
   const vv=[];
   for(let j=0;j<num;j++){
    const i=primitive.indices===undefined?j:accessor(g,binStart,dv,primitive.indices,j)[0];
    const xyz=point(transform,accessor(g,binStart,dv,a.POSITION,i));
    const normal=a.NORMAL!==undefined?vector(transform,accessor(g,binStart,dv,a.NORMAL,i)):[0,1,0];
    const l=Math.hypot(...normal)||1;
    for(let k=0;k<3;k++){min[k]=Math.min(min[k],xyz[k]);max[k]=Math.max(max[k],xyz[k]);}
    const uv=a.TEXCOORD_0!==undefined?accessor(g,binStart,dv,a.TEXCOORD_0,i):[0,0];vv.push(...xyz,normal[0]/l,normal[1]/l,normal[2]/l,col[0],col[1],col[2],0,uv[0],uv[1]);
   }
   if(vv.length){const texInfo=pm.pbrMetallicRoughness?.baseColorTexture;const texObject=texInfo?g.textures?.[texInfo.index]:null;parts.push({geometry:mesh(vv),texture:texObject?imageTextures[texObject.source]:null});}
  }}
  if(n.children)for(const child of n.children)traverse(child,transform);
 }
 const roots=g.scenes?.[g.scene||0]?.nodes||g.nodes.map((_,i)=>i);
 for(const id of roots)traverse(id,I());
 return {parts,min,max};
}
function place(asset,p){
 const [name,x,y,z,width,rot]=p;const bounds=asset.max.map((n,i)=>n-asset.min[i]);const widthAvailable=Math.max(bounds[0],.001);
 let scale=width/widthAvailable;
 if(name==="lamproundfloor")scale=Math.min(scale,2.8);
 const center=[(asset.min[0]+asset.max[0])*.5,asset.min[1],(asset.min[2]+asset.max[2])*.5];
 const m=multiply(multiply(tr(x,y,z),ry(rot)),multiply(sc(scale,scale,scale),tr(-center[0],-center[1],-center[2])));
 props.push({name,parts:asset.parts,matrix:m});
}
async function loadAssets(){
 const tasks=expected.map(async name=>{
  try{const response=await fetch("assets/"+name+".glb");if(!response.ok)throw Error("HTTP "+response.status);
    const asset=await parseGLB(await response.arrayBuffer());assets[name]=asset;
    for(const p of placements)if(p[0]===name)place(asset,p);
    loaded++;
  }catch(e){failed++;console.warn("Model load failed",name,e);}
  fps.textContent="MODELS "+loaded+"/"+expected.length+(failed?" / "+failed+" FAILED":"");
 });
 await Promise.all(tasks);
 fps.textContent=failed?"MODELS "+loaded+"/"+expected.length+" ("+failed+" FAILED)":"16/16 BUNDLED KENNEY MODELS";
}
const posters=[];
function texture(canvas2d){const t=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,t);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,canvas2d);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR_MIPMAP_LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);gl.generateMipmap(gl.TEXTURE_2D);return t;}
function canvas2D(w=512,h=512){const c=document.createElement("canvas");c.width=w;c.height=h;return [c,c.getContext("2d")];}
function paintPoster(head,sub,color,tag){
 const [c,g]=canvas2D(512,768),grad=g.createLinearGradient(0,0,512,768);
 grad.addColorStop(0,"#17263a");grad.addColorStop(.57,"#0a1524");grad.addColorStop(1,"#142f3d");g.fillStyle=grad;g.fillRect(0,0,512,768);
 g.lineWidth=12;g.strokeStyle="#526b77";g.strokeRect(16,16,480,736);
 g.translate(230,330);g.rotate(-.22);g.fillStyle=color;g.fillRect(-175,-155,350,310);g.fillStyle="#132236";g.fillRect(-110,-95,220,190);g.fillStyle=color;g.fillRect(30,-190,18,385);g.rotate(.22);g.translate(-230,-330);
 g.fillStyle="#f0f6ee";g.font="900 40px system-ui";g.fillText("PROJECT",43,88);g.font="1000 74px system-ui";g.fillStyle=color;g.fillText("ETHOS",37,151);
 g.font="900 75px system-ui";g.fillStyle="#f0f6ee";g.fillText(head,32,618);
 g.font="700 24px system-ui";g.fillStyle="#9eabb8";g.fillText(sub,34,664);g.fillText(tag,34,720);
 return texture(c);
}
function paintScreen(which){
 const [c,g]=canvas2D(512,256);
 g.fillStyle="#0a1a27";g.fillRect(0,0,512,256);g.strokeStyle="#55bcb8";g.lineWidth=5;g.strokeRect(9,9,494,238);
 g.fillStyle="#65ebe2";g.font="800 22px monospace";g.fillText("PROJECT ETHOS // LAUNCHER",25,42);
 g.fillStyle="#8fb9c7";g.font="20px monospace";g.fillText("NETWORK DIAGNOSTICS",25,83);
 g.fillStyle="#ff9c7e";g.font="900 48px system-ui";g.fillText("GAME OFFLINE!",24,152);
 g.fillStyle="#b1d2d6";g.font="18px monospace";g.fillText("PLAY ETHOS > RETRY",26,210);
 return texture(c);
}
let clockCanvas,clockContext,clockTex;
function createClock(){const v=canvas2D(512,256);clockCanvas=v[0];clockContext=v[1];clockTex=texture(clockCanvas);updateClock();}
function updateClock(){
 if(!clockContext)return;const g=clockContext;g.fillStyle="#091923";g.fillRect(0,0,512,256);
 g.lineWidth=6;g.strokeStyle="#67d9cd";g.strokeRect(8,8,496,240);g.fillStyle="#86ffdf";g.font="900 23px monospace";g.fillText("TIME SINCE ETHOS",28,49);
 const ms=Math.max(0,Date.now()-Date.UTC(2024,9,21));const days=Math.floor(ms/86400000);const hours=Math.floor(ms/3600000)%24;const mins=Math.floor(ms/60000)%60;
 g.fillStyle="#f3f7ff";g.font="900 69px monospace";g.fillText(String(days)+"d "+String(hours).padStart(2,"0")+"h",26,139);
 g.fillStyle="#d7b89d";g.font="22px monospace";g.fillText(String(mins).padStart(2,"0")+"m since Oct 2024 reveal",27,180);
 g.fillStyle="#8ca6b8";g.font="16px monospace";g.fillText("FAN-MADE COUNTER // NOT SERVER STATUS",28,221);
 gl.bindTexture(gl.TEXTURE_2D,clockTex);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,clockCanvas);gl.generateMipmap(gl.TEXTURE_2D);
}
function panel(tex,x,y,z,w,h,rot=0){posters.push({texture:tex,matrix:multiply(multiply(tr(x,y,z),ry(rot)),sc(w,h,1))});}
function buildPosters(){
 panel(paintPoster("PRISM","BEND THE LIGHT","#d78dfa","CHAMPION // 04"),-3.716,1.98,-2.30,.92,1.40,Math.PI/2);
 panel(paintPoster("ROJAS","RUN IT BACK","#ff9c72","CHAMPION // 01"),-3.716,1.98,.39,.91,1.37,Math.PI/2);
 panel(paintPoster("ARBOR","NOTHING DIES","#64f6a6","CHAMPION // 03"),-1.92,2.32,-3.745,1.01,1.12,0);
 panel(paintPoster("BREEZE","ONE MORE RUN","#ffce80","CHAMPION // 02"),2.25,2.34,3.748,.83,1.1,Math.PI);
 panel(paintScreen(),.34,1.19,-2.56,.74,.38,0);
 createClock();panel(clockTex,1.90,2.24,-3.734,1.40,.69,0);
}
buildPosters();
const laserBuffer=gl.createBuffer();
const target=[
 {id:"PC",name:"CHECK THE PC",p:[.35,1.23,-2.56],r:.56},
 {id:"CLOCK",name:"INSPECT THE TIMER",p:[1.9,2.20,-3.66],r:.63},
 {id:"BED",name:"LIE DOWN AND COPE",p:[-2.3,.55,-.5],r:1.2},
 {id:"SHRINE",name:"EXAMINE THE SHRINE",p:[-3.35,1.55,-.7],r:.86},
 {id:"PIZZA",name:"INSPECT THE PIZZA",p:[1.86,.56,.46],r:.68},
 {id:"TRASH",name:"LOOK IN THE TRASH",p:[2.63,.4,1.84],r:.55},
 {id:"POSTER",name:"ADMIRE THE POSTER",p:[-3.57,1.94,.38],r:.85},
 {id:"SHELF",name:"EXAMINE THE COLLECTION",p:[2.79,1.43,-2.76],r:.95},
 {id:"DOOR",name:"TRY TO LEAVE",p:[2.25,1.30,3.67],r:.85}
];
const lines={
 PC:["PLAY ETHOS... NETWORK ERROR. Try again?","Still offline on this PC. You have refreshed 1,000 times.","The launcher has become a meditation app."],
 CLOCK:["It's been a while since the October 2024 reveal.","Another minute closer to playing again. Probably."],
 BED:["You've spent more time here than you have in Trials.","The dreams are in third person, for some reason."],
 SHRINE:["A tasteful little shrine to a playtest.","The candles are doing more work than matchmaking."],
 PIZZA:["Pizza from the last playtest. Do not eat.","Some Evolutions have no cure for food poisoning."],
 TRASH:["Discarded patch predictions. All 987 of them.","You find a crumpled note: 'SOON'."],
 POSTER:["PRISM. The character still gets a wall spot.","You've researched the entire roster. Again."],
 SHELF:["The memorabilia has outgrown the furniture.","You called this 'a modest collection'."],
 DOOR:["Outside? But the servers could come back any second.","The door opens to the real world. You decline."]
};
let checks=0,interactionCount={},lastText="",captionUntil=0,sound=null;
function audio(){if(sound)return;try{sound=new (window.AudioContext||window.webkitAudioContext)();const osc=sound.createOscillator(),gain=sound.createGain();osc.type="sine";osc.frequency.value=62;gain.gain.value=.007;osc.connect(gain);gain.connect(sound.destination);osc.start();}catch(e){console.warn(e);}}
function beep(f=520){if(!sound)return;const o=sound.createOscillator(),v=sound.createGain(),now=sound.currentTime;o.type="triangle";o.frequency.setValueAtTime(f,now);o.frequency.exponentialRampToValueAtTime(f*.72,now+.10);v.gain.setValueAtTime(.038,now);v.gain.exponentialRampToValueAtTime(.0001,now+.16);o.connect(v);v.connect(sound.destination);o.start(now);o.stop(now+.18);}
function say(s){lastText=s;caption.textContent=s;caption.classList.add("show");captionUntil=performance.now()+5100;beep(480);hudTextDirty=true;}
function interact(hit){if(!hit){say("Nothing to interact with. The fan room is still very real.");return;}const id=hit.id;interactionCount[id]=(interactionCount[id]||0)+1;
 if(id==="PC"){checks++;say(checks===1?"CHECKING SERVERS... GAME OFFLINE!":checks===2?"STILL OFFLINE. Maybe press it harder?":"CHECK #"+checks+": The launcher remains deeply unimpressed.");}
 else{const a=lines[id];say(a[(interactionCount[id]-1)%a.length]);}
 if(lastSource?.gamepad){const h=lastSource.gamepad.hapticActuators?.[0]||lastSource.gamepad.vibrationActuator;if(h){try{if(h.pulse)h.pulse(.25,70);else if(h.playEffect)h.playEffect("dual-rumble",{duration:70,strongMagnitude:.25,weakMagnitude:.2});}catch(e){}}}
}
function hitRay(origin,dir,distance=3.0){let closest=null,best=distance;
 for(const item of target){const delta=item.p.map((v,i)=>v-origin[i]);const t=delta[0]*dir[0]+delta[1]*dir[1]+delta[2]*dir[2];if(t<0||t>best)continue;const nx=delta[0]-dir[0]*t,ny=delta[1]-dir[1]*t,nz=delta[2]-dir[2]*t;if(nx*nx+ny*ny+nz*nz<item.r*item.r){closest=item;best=t;}}
 return closest;}
const state={x:.18,z:1.91,yaw:0,pitch:-.07,eye:1.68,entered:false,last:performance.now(),snapArmed:true};
let vrSession=null,vrRef=null,refFloor=true,lastSource=null,headPose=null,controllers=[],frameN=0,standalone=I();
const key={},motion={forward:0,strafe:0},touch=$("touch");
function desktopRay(){return {origin:[state.x,state.eye,state.z],dir:[-Math.sin(state.yaw)*Math.cos(state.pitch),Math.sin(state.pitch),-Math.cos(state.yaw)*Math.cos(state.pitch)]};}
function xrRoot(){return multiply(tr(state.x,refFloor?0:state.eye,state.z),ry(state.yaw));}
function gazeXR(){if(!headPose)return null;const m=multiply(xrRoot(),headPose.transform.matrix);return {origin:point(m,[0,0,0]),dir:vector(m,[0,0,-1])};}
function currentRay(){return vrSession?gazeXR():desktopRay();}
function blocked(x,z){if(Math.abs(x)>3.39||Math.abs(z)>3.35)return true;if(x>-3.5&&x<-1.05&&z>-.98&&z<.81)return true;if(x>-.9&&x<1.4&&z<-2.32)return true;if(x>2.0&&z<-2.0)return true;return false;}
function advance(dt,forward,strafe){if(Math.abs(forward)<.07)forward=0;if(Math.abs(strafe)<.07)strafe=0;
 const speed=Math.min(2.0,2.35*dt),a=state.yaw,dx=(-Math.sin(a)*forward+Math.cos(a)*strafe)*speed,dz=(-Math.cos(a)*forward-Math.sin(a)*strafe)*speed;
 if(!blocked(state.x+dx,state.z))state.x+=dx;
 if(!blocked(state.x,state.z+dz))state.z+=dz;
}
function tick(dt,frame){
 if(!state.entered)return;
 if(vrSession&&frame){
  headPose=frame.getViewerPose(vrRef);let f=0,s=0,turn=0;controllers=[];
  for(const input of vrSession.inputSources){
   if(!input.gamepad)continue;const g=input.gamepad,ax=g.axes;
   let sx=ax.length>2?ax[2]:(ax[0]||0),sy=ax.length>3?ax[3]:(ax[1]||0);
   if(Math.abs(sx)<.16)sx=0;if(Math.abs(sy)<.16)sy=0;
   if(input.handedness==="left"){f=-sy;s=sx;}
   if(input.handedness==="right")turn=sx;
   const pp=frame.getPose(input.targetRaySpace,vrRef);
   if(pp){const m=multiply(xrRoot(),pp.transform.matrix);const d=vector(m,[0,0,-1]);controllers.push({m,origin:point(m,[0,0,0]),end:point(m,[0,0,-2]),dir:d});}
  }
  if(Math.abs(turn)>.72&&state.snapArmed){state.yaw+=Math.sign(turn)*Math.PI/6;state.snapArmed=false;}
  if(Math.abs(turn)<.27)state.snapArmed=true;
  if(headPose){const m=headPose.transform.matrix;const local=vector(ry(state.yaw),[-m[8],0,-m[10]]),right=[-local[2],0,local[0]];const len=Math.hypot(local[0],local[2])||1;
    const vx=(local[0]/len)*f+right[0]/len*s,vz=(local[2]/len)*f+right[2]/len*s;
    // advance with absolute heading instead of double-applying yaw
    const dd=dt*1.75;if(!blocked(state.x+vx*dd,state.z))state.x+=vx*dd;if(!blocked(state.x,state.z+vz*dd))state.z+=vz*dd;
  }
 }else{
  advance(dt,(key.KeyW||key.ArrowUp?1:0)-(key.KeyS||key.ArrowDown?1:0)+motion.forward,(key.KeyD?1:0)-(key.KeyA?1:0)+motion.strafe);
 }
 const ray=currentRay();const h=ray&&hitRay(ray.origin,ray.dir,3.0);
 if(!vrSession){hint.textContent=h?"[ E ] "+h.name:"";}else{hint.textContent="";}
 if(captionUntil&&performance.now()>captionUntil){caption.classList.remove("show");captionUntil=0;hudTextDirty=true;}
 frameN++;if(frameN%140===0)updateClock();
}
let hudTextCanvas,hudTex,hudTextDirty=true;
function createHudPanel(){const x=canvas2D(1024,256);hudTextCanvas=x[0];hudTex=texture(x[0]);}
createHudPanel();
function updateHudPanel(){const g=hudTextCanvas.getContext("2d");g.clearRect(0,0,1024,256);
 if(!captionUntil)return;
 g.fillStyle="rgba(5,16,28,.92)";g.fillRect(5,4,1014,248);g.strokeStyle="#62d8cc";g.lineWidth=10;g.strokeRect(8,7,1008,241);
 g.fillStyle="#9fdfda";g.font="800 28px sans-serif";g.fillText("FAN SIMULATOR / INTERACTION",42,64);
 g.fillStyle="#fff";g.font="700 42px sans-serif";
 let words=lastText.split(" "),line="",y=127;
 for(const word of words){const test=line?line+" "+word:word;if(g.measureText(test).width>940){g.fillText(line,42,y);line=word;y+=55;}else line=test;}
 if(line)g.fillText(line,42,y);
 gl.bindTexture(gl.TEXTURE_2D,hudTex);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,hudTextCanvas);gl.generateMipmap(gl.TEXTURE_2D);
 hudTextDirty=false;
}
function draw(proj,view,head){
 gl.useProgram(meshP);gl.uniformMatrix4fv(mu.p,false,proj);gl.uniformMatrix4fv(mu.v,false,view);
 meshDraw(roomG,standalone);
 for(const p of props)for(const part of p.parts)meshDraw(part.geometry,p.matrix,part.texture);
 if(vrSession&&controllers.length){
  const rays=[];for(const ctr of controllers){
   const hit=hitRay(ctr.origin,ctr.dir,3.0);
   const len=hit?Math.min(3,Math.hypot(...hit.p.map((v,i)=>v-ctr.origin[i]))):2.1;
   const end=ctr.origin.map((v,i)=>v+ctr.dir[i]*len);
   for(const p of [ctr.origin,end])rays.push(...p,0,1,0,.28,1,.89,1,0,0);
  }
  gl.bindBuffer(gl.ARRAY_BUFFER,laserBuffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(rays),gl.DYNAMIC_DRAW);
  gl.uniformMatrix4fv(mu.m,false,standalone);gl.uniform1f(mu.has,0);
  for(let i=0;i<5;i++){gl.enableVertexAttribArray(attrsMesh[i]);gl.vertexAttribPointer(attrsMesh[i],i===3?1:i===4?2:3,gl.FLOAT,false,48,[0,12,24,36,40][i]);}
  gl.lineWidth(2);gl.drawArrays(gl.LINES,0,rays.length/12);
 }
 gl.useProgram(texP);gl.uniformMatrix4fv(tu.p,false,proj);gl.uniformMatrix4fv(tu.v,false,view);
 for(const p of posters)texDraw(p.texture,p.matrix);
 if(vrSession&&head&&captionUntil){
  if(hudTextDirty)updateHudPanel();
  const headWorld=multiply(xrRoot(),head.transform.matrix);
  const pos=multiply(multiply(headWorld,tr(0,-.35,-1.15)),sc(.96,.24,1));
  gl.disable(gl.DEPTH_TEST);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);
  texDraw(hudTex,pos);gl.disable(gl.BLEND);gl.enable(gl.DEPTH_TEST);
 }
}
function desktopCamera(){const v=multiply(multiply(rx(-state.pitch),ry(-state.yaw)),tr(-state.x,-state.eye,-state.z));return v;}
function resize(){const d=Math.min(1.55,devicePixelRatio||1);const w=Math.max(1,Math.floor(innerWidth*d)),h=Math.max(1,Math.floor(innerHeight*d));if(canvas.width!==w||canvas.height!==h){canvas.width=w;canvas.height=h;}}
let lastFrame=performance.now();
function desktopFrame(t){requestAnimationFrame(desktopFrame);if(vrSession||!state.entered)return;resize();const dt=Math.min((t-lastFrame)/1000,.06);lastFrame=t;tick(dt,null);
 gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.viewport(0,0,canvas.width,canvas.height);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
 draw(perspective(Math.PI/2.65,canvas.width/canvas.height,.07,45),desktopCamera(),null);
}
requestAnimationFrame(desktopFrame);
function xrFrame(t,frame){if(!vrSession)return;vrSession.requestAnimationFrame(xrFrame);const dt=Math.min((t-lastFrame)/1000,.06);lastFrame=t;tick(dt,frame);
 if(!headPose)return;
 const layer=vrSession.renderState.baseLayer;gl.bindFramebuffer(gl.FRAMEBUFFER,layer.framebuffer);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
 for(const eye of headPose.views){const v=layer.getViewport(eye);gl.viewport(v.x,v.y,v.width,v.height);
  const rootInverse=multiply(ry(-state.yaw),tr(-state.x,refFloor?0:-state.eye,-state.z));
  const eyeView=multiply(eye.transform.inverse.matrix,rootInverse);
  draw(eye.projectionMatrix,eyeView,headPose);
 }
}
function showGame(){state.entered=true;menu.classList.add("closed");if(isTouch&&!vrSession)touch.hidden=false;audio();lastFrame=performance.now();}
$("explore").onclick=()=>{showGame();if(!isTouch&&canvas.requestPointerLock)canvas.requestPointerLock();};
$("servers").onclick=()=>{checks++;status.textContent="CHECK #"+checks+" : THE FAN SIMULATOR'S FAKE LAUNCHER IS STILL OFFLINE.";beep(360);};
async function initVR(){
 if(!navigator.xr||!isSecureContext){$("vr").textContent="VR REQUIRES QUEST BROWSER";$("vr").disabled=true;status.textContent="WebXR unavailable here. Browser mode remains playable.";return;}
 try{
  const ok=await navigator.xr.isSessionSupported("immersive-vr");
  $("vr").disabled=!ok;$("vr").textContent=ok?"ENTER STEREOSCOPIC VR":"OPEN IN META QUEST BROWSER";
  status.textContent=ok?"WEBXR READY: two-eye Quest rendering available.":"WebXR headset not detected. Browser preview is available.";
 }catch(e){status.textContent="WebXR check: "+e.message;$("vr").textContent="VR NOT AVAILABLE HERE";}
}
$("vr").onclick=async()=>{
 try{
  audio();const req=await navigator.xr.requestSession("immersive-vr",{optionalFeatures:["local-floor","bounded-floor"]});
  await gl.makeXRCompatible();
  const layer=new XRWebGLLayer(req,gl,{alpha:false,depth:true,antialias:true});
  req.updateRenderState({baseLayer:layer,depthNear:.07,depthFar:45});
  try{vrRef=await req.requestReferenceSpace("local-floor");refFloor=true;}catch(e){vrRef=await req.requestReferenceSpace("local");refFloor=false;}
  vrSession=req;vrSession.addEventListener("selectstart",ev=>{
   lastSource=ev.inputSource;
   const pose=ev.frame.getPose(ev.inputSource.targetRaySpace,vrRef);
   if(pose){const m=multiply(xrRoot(),pose.transform.matrix);interact(hitRay(point(m,[0,0,0]),vector(m,[0,0,-1]),3.0));}else{
    const ray=gazeXR();interact(ray?hitRay(ray.origin,ray.dir,3):null);
   }
  });
  req.addEventListener("end",()=>{vrSession=null;headPose=null;touch.hidden=isTouch?false:true;menu.classList.remove("closed");state.entered=false;status.textContent="Exited VR. Re-enter whenever ready.";});
  showGame();touch.hidden=true;lastFrame=performance.now();req.requestAnimationFrame(xrFrame);
 }catch(e){status.textContent="VR START ERROR: "+e.message;console.error(e);$("vr").disabled=false;}
};
window.addEventListener("keydown",ev=>{key[ev.code]=true;if(["Space","ArrowUp","ArrowDown","ArrowLeft","ArrowRight"].includes(ev.code))ev.preventDefault();
 if(!vrSession&&state.entered&&(ev.code==="KeyE"||ev.code==="Space")){const a=desktopRay();interact(hitRay(a.origin,a.dir,3));}
 if(!vrSession&&ev.code==="Escape"&&state.entered){/* browser pointer unlock */}
 if(!vrSession&&state.entered&&ev.code==="KeyR"){state.x=.18;state.z=1.91;state.yaw=0;state.pitch=-.07;say("You have reset the fan spiral.");}
});
window.addEventListener("keyup",ev=>key[ev.code]=false);
canvas.addEventListener("click",()=>{if(!state.entered||vrSession)return;
 if(!isTouch&&!document.pointerLockElement&&canvas.requestPointerLock){canvas.requestPointerLock();return;}
 const a=desktopRay();interact(hitRay(a.origin,a.dir,3));});
document.addEventListener("mousemove",e=>{if(!vrSession&&state.entered&&document.pointerLockElement===canvas){state.yaw-=e.movementX*.0022;state.pitch=Math.max(-1.25,Math.min(1.25,state.pitch-e.movementY*.0019));}});
let lookTouch=null,joyTouch=null,joyOrigin=null;
canvas.addEventListener("touchstart",e=>{
 if(!state.entered||vrSession)return;
 for(const t of e.changedTouches){
  if(t.clientX<innerWidth*.43&&joyTouch===null){
   joyTouch=t.identifier;joyOrigin={x:t.clientX,y:t.clientY};
  }else if(lookTouch===null)lookTouch={id:t.identifier,x:t.clientX,y:t.clientY};
 }
},{passive:true});
canvas.addEventListener("touchmove",e=>{
 if(!state.entered||vrSession)return;
 for(const t of e.changedTouches){
  if(t.identifier===joyTouch&&joyOrigin){
   motion.strafe=Math.max(-1,Math.min(1,(t.clientX-joyOrigin.x)/66));
   motion.forward=Math.max(-1,Math.min(1,(joyOrigin.y-t.clientY)/66));
  }else if(lookTouch&&t.identifier===lookTouch.id){
   state.yaw-=(t.clientX-lookTouch.x)*.004;
   state.pitch=Math.max(-1.25,Math.min(1.25,state.pitch-(t.clientY-lookTouch.y)*.003));
   lookTouch={id:t.identifier,x:t.clientX,y:t.clientY};
  }
 }
},{passive:true});
function touchEnd(e){for(const t of e.changedTouches){
 if(t.identifier===joyTouch){joyTouch=null;joyOrigin=null;motion.forward=motion.strafe=0;}
 if(lookTouch&&t.identifier===lookTouch.id)lookTouch=null;
}}
canvas.addEventListener("touchend",touchEnd,{passive:true});
canvas.addEventListener("touchcancel",touchEnd,{passive:true});
$("interact").addEventListener("click",()=>{const ray=desktopRay();interact(hitRay(ray.origin,ray.dir,3.0));});
window.addEventListener("unhandledrejection",e=>{console.warn("Promise error:",e.reason);});
initVR();loadAssets();resize();
})();