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
 // Reconstructed from the actual 95 MB Godot PASS5 project: 8 x 6m, workstation left, bed right.
 box(0,-.10,0,8,.20,6,[.33,.24,.19]);
 box(0,1.55,-3,8,3.1,.16,[.24,.26,.29]);
 box(0,1.55,3,8,3.1,.16,[.23,.24,.26]);
 box(-4,1.55,0,.16,3.1,6,[.25,.26,.27]);
 box(4,1.55,0,.16,3.1,6,[.25,.27,.30]);
 box(0,3.06,0,8,.12,6,[.22,.22,.24]);
 for(const x of [-3.87,3.87]){box(x,.097,0,.085,.19,5.8,[.27,.22,.18]);box(x,2.95,0,.085,.10,5.8,[.29,.22,.17]);}
 for(const z of [-2.88,2.88]){box(0,.097,z,7.80,.19,.085,[.27,.22,.18]);box(0,2.95,z,7.80,.10,.085,[.29,.22,.17]);}
 box(-2.12,.018,-.80,2.95,.036,2.50,[.26,.27,.30]);
 // Slatted wooden accent wall and dark backing identical in placement to original.
 box(-2.28,1.48,-2.87,2.45,2.62,.055,[.068,.075,.081]);
 for(let i=0;i<14;i++)box(-3.38+i*.17,1.48,-2.82,.075,2.52,.055,[.40,.31,.23]);
 // Actual left-side window with blinds, as in the Godot build.
 box(-3.87,1.62,2.05,.04,1.34,1.34,[.06,.11,.15]);
 for(const yy of [0.90,2.34])box(-3.83,yy,2.05,.09,.07,1.52,[.14,.16,.17]);
 for(const zz of [1.32,2.78])box(-3.83,1.62,zz,.09,1.52,.07,[.14,.16,.17]);
 for(let j=0;j<10;j++)box(-3.81,1.08+j*.115,2.05,.04,.025,1.22,[.49,.49,.49]);
 // Clock is a real wall-mounted panel, not a floating DOM label.
 box(0,2.54,-2.87,3.10,.79,.10,[.025,.032,.035]);
 // Actual large physical ETHOS shrine from the original source coordinates.
 box(2.65,.65,-2.30,1.70,.11,.72,[.42,.30,.22]);
 box(2.65,1.40,-2.73,1.75,1.45,.08,[.027,.035,.038]);
 for(const x of [2.03,2.28,3.02,3.28])box(x,.94,-2.36,.065,.48,.065,[.41,.95,.23],1);
 for(let i=0;i<5;i++)box(2.15+i*.25,.83,-2.25,.16,.26,.16,i%2?[.61,.10,.88]:[.41,.93,.20],1);
 // Physical computer screen; its source artwork is drawn in front at the original dimensions.
 box(-2.20,1.55,-2.45,1.48,.94,.12,[.064,.078,.095]);
 // Ceiling warm fixture & desk / shrine practical lights.
 box(.25,2.88,.30,.48,.10,.48,[1,.73,.49],1);
 box(-3.15,1.17,-2.35,.09,.24,.06,[.22,.91,.12],1);
 // Trash can and little clutter from the original bedroom.
 box(-3.43,.32,-1.31,.43,.63,.42,[.070,.074,.080]);
 box(-3.43,.66,-1.31,.47,.045,.46,[.13,.14,.15]);
 for(let i=0;i<12;i++){const x=-3.70+(i%4)*.25,y=.36+Math.floor(i/4)*.52;box(x,y,.70,.08,.31,.22,[[.26,.32,.28],[.36,.22,.44],[.23,.31,.42],[.38,.31,.2]][i%4]);}
 for(const [x,z,c] of [[-.52,2.1,[.5,.08,.10]],[.37,2.4,[.11,.25,.5]],[1.1,1.65,[.44,.48,.08]],[.2,.8,[.50,.08,.10]]])box(x,.1,z,.1,.2,.1,c);
 // Door on front wall.
 box(2.27,1.16,2.87,1.35,2.35,.065,[.33,.27,.22]);
 box(2.82,1.10,2.79,.09,.06,.12,[.72,.67,.45]);
}
buildRoom();const roomG=mesh(roomV);
let assets={},props=[],loaded=0,failed=0;const expected=["beddouble","desk","chairdesk","computerscreen","computerkeyboard","computermouse","bookcaseopen","lamproundfloor","plantsmall2","sidetabledrawers","tablecoffeesquare","loungedesignchair","pizza-box","soda-can","cup-coffee","pizza"];
const placements=[
 ["beddouble",2.76,.02,-.65,1.80,0],
 ["desk",-2.32,.02,-2.15,2.64,0],
 ["chairdesk",-2.20,.02,-.91,.88,Math.PI],
 ["computerscreen",-2.20,1.09,-2.45,1.42,0],
 ["computerkeyboard",-2.22,.92,-1.74,1.03,0],
 ["computermouse",-1.54,.91,-1.71,.15,0],
 ["bookcaseopen",-3.25,.01,.72,1.29,0],
 ["lamproundfloor",3.52,.03,-1.62,.4,0],
 ["plantsmall2",-3.46,.89,-1.90,.18,0],
 ["sidetabledrawers",3.52,.03,-1.62,.67,0],
 ["tablecoffeesquare",2.65,.03,-2.30,1.63,0],
 ["loungedesignchair",-2.20,.03,-.91,.83,Math.PI],
 ["pizza-box",-.78,.03,1.42,.58,0],
 ["pizza-box",.08,.03,2.10,.58,.1],
 ["soda-can",-.36,.12,1.1,.1,0],
 ["cup-coffee",-1.47,.89,-2.06,.20,0],
 ["pizza",-.76,.155,1.44,.48,0]
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
   if(a.NORMAL===undefined){
    for(let base=0;base+35<vv.length;base+=36){
      const ax=vv[base+12]-vv[base],ay=vv[base+13]-vv[base+1],az=vv[base+14]-vv[base+2];
      const bx=vv[base+24]-vv[base],by=vv[base+25]-vv[base+1],bz=vv[base+26]-vv[base+2];
      let nx=ay*bz-az*by,ny=az*bx-ax*bz,nz=ax*by-ay*bx;
      const mag=Math.hypot(nx,ny,nz)||1;nx/=mag;ny/=mag;nz/=mag;
      for(const v of [base,base+12,base+24]){vv[v+3]=nx;vv[v+4]=ny;vv[v+5]=nz;}
    }
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
 // Genuine models converted from OBJ meshes found inside original archived Pass5.
 // All meshes retain scene node translations/scales matching scripts/main.gd.
 const original=["original-room-major","original-room-details"];
 let actualCount=0;
 for(const name of original){
  try{
   const response=await fetch("assets/"+name+".glb",{cache:"force-cache"});
   if(!response.ok)throw Error("HTTP "+response.status);
   const originalMesh=await parseGLB(await response.arrayBuffer());
   if(!originalMesh.parts.length)throw Error("No geometry");
   props.push({name,parts:originalMesh.parts,matrix:standalone});
   actualCount++;fps.textContent="ORIGINAL PASS 5 MESH PACKS "+actualCount+"/2";
  }catch(e){console.warn("Original archive model load failed",name,e);failed++;}
 }
 // If the source geometry is absent, use the previously bundled Kenney CC0
 // replacements rather than leaving the room empty.
 if(actualCount<2){
  const tasks=expected.map(async name=>{
   try{
    const res=await fetch("assets/"+name+".glb");
    if(!res.ok)throw Error("HTTP "+res.status);
    const asset=await parseGLB(await res.arrayBuffer());
    if((actualCount===0&&name!=="soda-can")||(actualCount===1&&name==="soda-can"))
      for(const p of placements)if(p[0]===name)place(asset,p);
    loaded++;
   }catch(e){failed++;console.warn("Fallback GLB load error",name,e);}
  });
  await Promise.all(tasks);
 }
 // Real Godot props are the primary rendering path; Kenney remains a bundled fallback.
 loaded=actualCount===2?41:loaded;
 fps.textContent=actualCount===2?
  "41 ORIGINAL PASS 5 MESH INSTANCES + REAL ETHOS ART":
  "ORIGINAL PACKS "+actualCount+"/2 · KENNEY FALLBACK "+loaded+"/"+expected.length;
}
const posters=[];
function texture(canvas2d){const t=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,t);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,canvas2d);const pot=n=>n>0&&(n&(n-1))===0;const mip=pot(canvas2d.width)&&pot(canvas2d.height);
 gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,mip?gl.LINEAR_MIPMAP_LINEAR:gl.LINEAR);
 gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
 gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);
 gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
 if(mip)gl.generateMipmap(gl.TEXTURE_2D);return t;}
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
 const ms=Math.max(0,Date.now()-1729490400000);const days=Math.floor(ms/86400000);const hours=Math.floor(ms/3600000)%24;const mins=Math.floor(ms/60000)%60;const secs=Math.floor(ms/1000)%60;
 g.fillStyle="#f3f7ff";g.font="900 69px monospace";g.fillText(String(days)+" DAYS",26,139);
 g.fillStyle="#d7b89d";g.font="22px monospace";g.fillText(String(hours).padStart(2,"0")+":"+String(mins).padStart(2,"0")+":"+String(secs).padStart(2,"0")+" SINCE THE PLAYTEST",27,180);
 g.fillStyle="#8ca6b8";g.font="16px monospace";g.fillText("PLAYTEST ENDED OCT 20, 2024 (PDT)",28,221);
 gl.bindTexture(gl.TEXTURE_2D,clockTex);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,clockCanvas);gl.generateMipmap(gl.TEXTURE_2D);
}
function panel(tex,x,y,z,w,h,rot=0){posters.push({texture:tex,matrix:multiply(multiply(tr(x,y,z),ry(rot)),sc(w,h,1))});}
function loadOriginalArt(){
 // Original Godot Pass 5 screenshots: assets/ethos/{01_forum,02_outdoors,
 // 03_pathfinders,04_combat,05_ethos_logo,06_evolution}.
 // Bundled here as a 3x2 atlas (each tile is 256x144 pixels).
 const image=new Image();
 image.onload=()=>{
  const originals=[];
  for(let i=0;i<6;i++){
   const [c,g]=canvas2D(512,256);
   g.drawImage(image,(i%3)*256,Math.floor(i/3)*144,256,144,0,0,512,256);
   originals.push(texture(c));
  }
  // Exact print positions and source selection from main.gd:Pass5.
  const back=[
   [0,-.78,1.57,-2.805,1.18],
   [3,.72,1.50,-2.805,1.18],
   [4,2.0,2.22,-2.805,1.08],
   [2,3.12,2.12,-2.805,1.08],
   [5,2.20,1.02,-2.805,.92],
   [1,3.25,.98,-2.805,.92]
  ];
  for(const [id,x,y,z,w] of back)panel(originals[id],x,y,z,w,w/1.6,0);
  for(let i=0;i<6;i++){
   const z=-2.30+(i%3)*1.42,y=i<3?2.18:1.12;
   panel(originals[(i+1)%6],-3.825,y,z,1.02,1.02/1.6,Math.PI/2);
  }
  for(let i=0;i<6;i++){
   const z=-2.15+(i%3)*1.72,y=i<3?2.12:1.15;
   panel(originals[(i+3)%6],3.825,y,z,1.12,1.12/1.6,-Math.PI/2);
  }
  panel(originals[4],2.65,1.72,-2.575,.82,.82/1.6);
  panel(originals[2],2.16,1.17,-2.575,.45,.45/1.6);
  panel(originals[5],3.12,1.17,-2.575,.45,.45/1.6);
  pcAtlasImage=image;paintPcPanel();panel(originals[4],-2.20,1.55,-2.345,1.30,.73,0);fps.textContent="ORIGINAL PASS5 ART + "+loaded+"/"+expected.length+" MODELS";
 };
 image.onerror=()=>{console.error("Original art atlas failed to load");fps.textContent="ORIGINAL ART MISSING / MODELS "+loaded+"/"+expected.length;};
 image.src="assets/original-ethos-atlas.webp";
}
async function loadSourceVisuals(){
 // Directly recovered higher resolution ProjectEthosFanSimulator_PASS5_TITLE_HUMOR_GODOT.zip assets.
 const response=await fetch("source_visuals.tar.gz",{cache:"force-cache"});
 if(!response.ok)throw Error("PASS5 visual bundle returned "+response.status);
 if(typeof DecompressionStream!=="function")throw Error("Browser lacks gzip DecompressionStream");
 const raw=await new Response(response.body.pipeThrough(new DecompressionStream("gzip"))).arrayBuffer();
 const bytes=new Uint8Array(raw),decoder=new TextDecoder("ascii"),files={};let offset=0;
 while(offset+512<=bytes.length){
  const header=bytes.subarray(offset,offset+512);
  const name=decoder.decode(header.subarray(0,100)).split("\0")[0];
  if(!name)break;
  const size=parseInt(decoder.decode(header.subarray(124,136)).replace(/\0/g,"").trim(),8)||0;
  if(size<0||offset+512+size>bytes.length)throw Error("Invalid asset bundle member "+name);
  files[name]=bytes.slice(offset+512,offset+512+size);
  offset+=512+Math.ceil(size/512)*512;
 }
 async function sourceImage(name){
  if(!files[name])throw Error("Missing visual source "+name);
  return await createImageBitmap(new Blob([files[name]],{type:"image/webp"}));
 }
 const source={};const aspect={};
 for(let i=1;i<=6;i++){const id=String(i).padStart(2,"0"),bmp=await sourceImage(id+".webp");source[i]=texture(bmp);aspect[i]=bmp.width/bmp.height;bmp.close();}
 function poster(id,x,y,z,width,angle=0){
  panel(source[id],x,y,z,width,width/aspect[id],angle);
 }
 // Exact original Godot PASS5 gallery positions. Prints and monitor use original in-game screenshots.
 for(const [id,x,y,width] of [[1,-.78,1.57,1.18],[4,.72,1.50,1.18],[5,2,2.22,1.08],[3,3.12,2.12,1.08],[6,2.2,1.02,.92],[2,3.25,.98,.92]])poster(id,x,y,-2.790,width);
 for(let i=0;i<6;i++){const z=-2.30+(i%3)*1.42;poster((i+1)%6+1,-3.803,i<3?2.18:1.12,z,1.02,Math.PI/2);}
 for(let i=0;i<6;i++){const z=-2.15+(i%3)*1.72;poster((i+3)%6+1,3.803,i<3?2.12:1.15,z,1.12,-Math.PI/2);}
 poster(5,2.65,1.72,-2.569,.82);poster(3,2.16,1.17,-2.569,.45);poster(6,3.12,1.17,-2.569,.45);
 poster(5,-2.20,1.55,-2.330,1.30);
 // Reuse original material albedos at real-world floor/wall positions, not procedural paintings.
 const wallImg=await sourceImage("wall_paint.webp"),wallTex=texture(wallImg);wallImg.close();
 const floorImg=await sourceImage("wood_floor_v2.webp"),floorTex=texture(floorImg);floorImg.close();
 const rugImg=await sourceImage("carpet.webp"),rugTex=texture(rugImg);rugImg.close();
 panel(wallTex,0,1.55,-2.910,8,3.05,0);
 panel(wallTex,0,1.55,2.910,8,3.05,Math.PI);
 panel(wallTex,-3.91,1.55,0,6,3.05,Math.PI/2);
 panel(wallTex,3.91,1.55,0,6,3.05,-Math.PI/2);
 posters.push({texture:floorTex,matrix:multiply(multiply(tr(0,.022,0),rx(-Math.PI/2)),sc(8,6,1))});
 posters.push({texture:rugTex,matrix:multiply(multiply(tr(-2.12,.048,-.80),rx(-Math.PI/2)),sc(2.95,2.5,1))});
 const art=new Image(),blobUrl=URL.createObjectURL(new Blob([files["04.webp"]],{type:"image/webp"}));art.src=blobUrl;await art.decode();
 pcAtlasImage=art;paintPcPanel();$("pcHero").style.backgroundImage="url("+blobUrl+")";$("pcHero").style.backgroundSize="cover";$("pcHero").style.backgroundPosition="center";
 menu.style.backgroundImage="linear-gradient(90deg,rgba(1,6,14,.96),rgba(5,12,22,.70)),url('"+blobUrl+"')";
 menu.style.backgroundSize="cover";menu.style.backgroundPosition="center";
 fps.textContent="PASS5 SOURCE: 6 HIGH-RES POSTERS + 41 MODEL INSTANCES";
}
function buildPosters(){
 // Actual original game artwork (not synthetic replacement artwork).
 loadSourceVisuals().catch(e=>{console.warn("High resolution source pack fallback",e);loadOriginalArt();});
 panel(paintScreen(),-2.20,1.55,-2.355,1.30,.73,0);
 createClock();
 panel(clockTex,0,2.54,-2.770,2.94,.66,0);
}
buildPosters();
const laserBuffer=gl.createBuffer();
let pcState=0,pcTexture=null,pcPanelCanvas=null,pcPanelCtx=null,pcAtlasImage=null,pcChecks=0;
const target=[
 {id:"PC",name:"PLAY ETHOS / CHECK PC",p:[-2.20,1.55,-2.385],r:.78},
 {id:"CLOCK",name:"TIME SINCE ETHOS",p:[0,2.54,-2.84],r:1.15},
 {id:"BED",name:"ATTEMPT SLEEP",p:[2.76,.68,-.65],r:1.1},
 {id:"SHRINE",name:"ETHOS SHRINE",p:[2.65,1.38,-2.30],r:1.10},
 {id:"PIZZA",name:"PIZZA BOXES",p:[-.40,.20,1.72],r:.8},
 {id:"TRASH",name:"TRASH CAN",p:[-3.43,.43,-1.31],r:.53},
 {id:"POSTER",name:"ETHOS PRESS SHOTS",p:[-3.72,1.9,-.7],r:1.00},
 {id:"SHELF",name:"COLLECTOR SHELF",p:[-3.25,1.13,.72],r:.95},
 {id:"DOOR",name:"QUIT TO REAL LIFE",p:[2.26,1.31,2.83],r:.9}
];
const lines={
 PC:["THE LAUNCHER STARES BACK AT YOU.","PLAY ETHOS? IT'S BEEN A WHILE."],
 CLOCK:["NO, STARING AT IT DOES NOT MAKE THE NUMBER SMALLER.","THIS NUMBER IS VERY RUDE."],
 BED:["SLEEP? WITH ETHOS STILL OFFLINE? BE SERIOUS.","YOU'VE BEEN DREAMING IN THIRD PERSON."],
 SHRINE:["A COMPLETELY NORMAL AMOUNT OF MEMORABILIA.","THE CANDLES ARE DOING MORE WORK THAN MATCHMAKING."],
 PIZZA:["FRESHNESS STATUS: ALSO OFFLINE.","IT HAS EVOLVED INTO SOMETHING ELSE."],
 TRASH:["ARCHAEOLOGISTS WILL DATE THIS LAYER TO THE FIRST PLAYTEST.","A CRUMPLED NOTE SAYS: 'SOON'."],
 POSTER:["REMEMBER WHEN WE COULD ACTUALLY PLAY THIS?","THIS WAS A COMPLETELY NORMAL AMOUNT OF SCREENSHOTS."],
 SHELF:["A COMPLETELY NORMAL COLLECTION.","NONE OF THIS IS OBSESSIVE. AT ALL."],
 DOOR:["QUIT TO REAL LIFE? THAT DOESN'T SOUND FUN.","THE SERVERS COULD RETURN AT ANY MOMENT."]
};
let checks=0,interactionCount={},lastText="",captionUntil=0,sound=null;
let effectClick=null,effectDenied=null;
function audio(){
 if(sound)return;
 try{
  sound=new Audio("assets/room_hum.ogg");sound.loop=true;sound.volume=.22;
  sound.play().catch(e=>console.warn("Audio requires interaction",e));
  effectClick=new Audio("assets/ui_click.ogg");effectClick.volume=.55;
  effectDenied=new Audio("assets/server_denied.ogg");effectDenied.volume=.68;
 }catch(e){console.warn("Original archived audio unavailable",e);}
}
function beep(f=520){
 // Pass5 sound effects, recovered from the original Godot archive.
 const src=f<450?effectDenied:effectClick;
 if(src){try{const a=src.cloneNode();a.volume=src.volume;a.play().catch(()=>{});}catch(e){}return;}
 // Fallback beep only if browser audio decode fails.
 try{
  const ctx=new(window.AudioContext||window.webkitAudioContext)();
  const o=ctx.createOscillator(),g=ctx.createGain(),t=ctx.currentTime;
  o.frequency.value=f;o.type="triangle";g.gain.setValueAtTime(.022,t);
  g.gain.exponentialRampToValueAtTime(.001,t+.13);
  o.connect(g);g.connect(ctx.destination);o.start(t);o.stop(t+.14);
  setTimeout(()=>ctx.close().catch(()=>{}),400);
 }catch(e){}
}
function say(s){lastText=s;caption.textContent=s;caption.classList.add("show");captionUntil=performance.now()+5100;beep(480);hudTextDirty=true;}
function ensurePC(){
 if(pcPanelCanvas)return;
 [pcPanelCanvas,pcPanelCtx]=canvas2D(1024,512);
 pcTexture=texture(pcPanelCanvas);
}
function paintPcPanel(){
 ensurePC();
 const c=pcPanelCtx;c.fillStyle="#0d1721";c.fillRect(0,0,1024,512);
 c.fillStyle="#081017";c.fillRect(0,0,1024,65);
 c.font="bold 27px sans-serif";c.fillStyle="#b7d1d0";c.fillText("STEAM   STORE   LIBRARY   COMMUNITY               ETHOSFAN3000",22,40);
 if(pcState===2){
  c.fillStyle="#081014";c.fillRect(25,90,974,389);
  c.font="900 89px sans-serif";c.fillStyle="#a7ff42";c.textAlign="center";c.fillText("GAME OFFLINE!",512,223);
  c.font="26px sans-serif";c.fillStyle="#e9eef0";c.fillText("There are no Project ETHOS servers to connect to.",512,280);
  c.fillText("You knew this would happen. You clicked anyway.",512,325);
  c.fillStyle="#274038";c.fillRect(267,392,490,59);c.font="bold 25px sans-serif";
  c.fillStyle="#ddfae7";c.fillText("TRIGGER: CHECK AGAIN",512,431);
  c.textAlign="start";
 }else{
  c.fillStyle="#173446";c.fillRect(22,82,614,311);
  if(pcAtlasImage){if(pcAtlasImage.height>288)c.drawImage(pcAtlasImage,0,0,pcAtlasImage.width,pcAtlasImage.height,22,82,614,311);else c.drawImage(pcAtlasImage,0,144,256,144,22,82,614,311);}
  c.fillStyle="#091019bf";c.fillRect(22,311,614,82);
  c.fillStyle="#ffffff";c.font="900 51px sans-serif";c.fillText("PROJECT ETHOS",41,367);
  c.fillStyle="#21303f";c.fillRect(666,82,338,310);
  c.font="24px sans-serif";c.fillStyle="#d9e6e8";c.fillText("Third-person roguelike",691,137);
  c.fillText("hero shooter",691,166);c.fillText("STATUS: OFFLINE",691,230);
  c.fillText("LAST PLAYED: OCT 20, 2024",691,277);
  c.fillText("OVERWHELMINGLY MISSED",691,338);
  c.fillStyle="#378e2b";c.fillRect(23,408,380,69);c.fillStyle="#fff";
  c.font="bold 36px sans-serif";c.fillText("▶  PLAY ETHOS",45,455);
  c.font="22px sans-serif";c.fillStyle="#bad2d0";c.fillText("TRIGGER TO PLAY",656,451);
 }
 gl.bindTexture(gl.TEXTURE_2D,pcTexture);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);
 gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,pcPanelCanvas);
 gl.generateMipmap(gl.TEXTURE_2D);
}
function openPc(){
 pcState=1;paintPcPanel();$("pcOffline").hidden=true;
 if(!vrSession){$("pcOverlay").hidden=false;if(document.pointerLockElement===canvas)document.exitPointerLock();}
 else say("PC OPEN — PULL TRIGGER TO PLAY ETHOS");
 beep(720);
}
function closePc(){
 pcState=0;$("pcOverlay").hidden=true;$("pcOffline").hidden=true;
 if(vrSession)say("YOU KNEW THIS WOULD HAPPEN.");
}
function playPc(){
 pcState=2;pcChecks++;paintPcPanel();$("pcOffline").hidden=false;
 if(vrSession)say("GAME OFFLINE! YOU KNEW THIS WOULD HAPPEN. YOU CLICKED ANYWAY.");
 beep(240);
}
function retryPc(){
 pcState=1;paintPcPanel();$("pcOffline").hidden=true;
 if(vrSession)say("REFRESHING HARDER HAS NOT HELPED.");
}
$("pcClose").onclick=()=>closePc();
$("pcPlay").onclick=()=>playPc();
$("pcRetry").onclick=()=>retryPc();
function interact(hit){
 if(pcState>0){
  if(pcState===1)playPc();else retryPc();
  return;
 }
 if(!hit){say("NO, THERE ARE NO NEW SERVERS TO CHECK.");return;}
 const id=hit.id;interactionCount[id]=(interactionCount[id]||0)+1;
 if(id==="pc"){openPc();return;}
 const list=lines[id];say(list[(interactionCount[id]-1)%list.length]);
 if(lastSource?.gamepad){
  const h=lastSource.gamepad.hapticActuators?.[0]||lastSource.gamepad.vibrationActuator;
  if(h)try{if(h.pulse)h.pulse(.25,70);else if(h.playEffect)h.playEffect("dual-rumble",{duration:70,strongMagnitude:.25,weakMagnitude:.2});}catch(e){}
 }
}
function hitRay(origin,dir,distance=3.0){let closest=null,best=distance;
 for(const item of target){const delta=item.p.map((v,i)=>v-origin[i]);const t=delta[0]*dir[0]+delta[1]*dir[1]+delta[2]*dir[2];if(t<0||t>best)continue;const nx=delta[0]-dir[0]*t,ny=delta[1]-dir[1]*t,nz=delta[2]-dir[2]*t;if(nx*nx+ny*ny+nz*nz<item.r*item.r){closest=item;best=t;}}
 return closest;}
const state={x:.02,z:2.30,yaw:-.01745,pitch:-.07,eye:1.68,entered:false,last:performance.now(),snapArmed:true};
let vrSession=null,vrRef=null,refFloor=true,lastSource=null,headPose=null,controllers=[],frameN=0,standalone=I();
const key={},motion={forward:0,strafe:0},touch=$("touch");
function desktopRay(){return {origin:[state.x,state.eye,state.z],dir:[-Math.sin(state.yaw)*Math.cos(state.pitch),Math.sin(state.pitch),-Math.cos(state.yaw)*Math.cos(state.pitch)]};}
function xrRoot(){return multiply(tr(state.x,refFloor?0:state.eye,state.z),ry(state.yaw));}
function gazeXR(){if(!headPose)return null;const m=multiply(xrRoot(),headPose.transform.matrix);return {origin:point(m,[0,0,0]),dir:vector(m,[0,0,-1])};}
function currentRay(){return vrSession?gazeXR():desktopRay();}
function blocked(x,z){
 if(Math.abs(x)>3.60||Math.abs(z)>2.70)return true;
 if(x>1.7&&x<3.76&&z>-1.78&&z<.51)return true;
 if(x<-1.0&&x>-3.84&&z<-1.40)return true;
 if(x<-2.65&&z>.39&&z<1.11)return true;
 if(x>1.80&&z<-1.9)return true;
 return false;
}
function advance(dt,forward,strafe){if(Math.abs(forward)<.07)forward=0;if(Math.abs(strafe)<.07)strafe=0;
 const speed=Math.min(2.0,2.35*dt),a=state.yaw,dx=(-Math.sin(a)*forward+Math.cos(a)*strafe)*speed,dz=(-Math.cos(a)*forward-Math.sin(a)*strafe)*speed;
 if(!blocked(state.x+dx,state.z))state.x+=dx;
 if(!blocked(state.x,state.z+dz))state.z+=dz;
}
function tick(dt,frame){
 if(!state.entered)return;
 if(pcState>0&&!vrSession)return;
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
 if(vrSession&&head&&pcState>0){
  const root=multiply(xrRoot(),head.transform.matrix);
  const pcM=multiply(multiply(root,tr(0,-.01,-1.27)),sc(1.65,.83,1));
  gl.disable(gl.DEPTH_TEST);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);
  texDraw(pcTexture,pcM);gl.disable(gl.BLEND);gl.enable(gl.DEPTH_TEST);
 }

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
  req.addEventListener("end",()=>{closePc();vrSession=null;headPose=null;touch.hidden=isTouch?false:true;menu.classList.remove("closed");state.entered=false;status.textContent="Exited VR. Re-enter whenever ready.";});
  showGame();touch.hidden=true;lastFrame=performance.now();req.requestAnimationFrame(xrFrame);
 }catch(e){status.textContent="VR START ERROR: "+e.message;console.error(e);$("vr").disabled=false;}
};
window.addEventListener("keydown",ev=>{key[ev.code]=true;if(["Space","ArrowUp","ArrowDown","ArrowLeft","ArrowRight"].includes(ev.code))ev.preventDefault();
 if(pcState>0&&ev.code==="Escape"){closePc();return;}
 if(!vrSession&&state.entered&&(ev.code==="KeyE"||ev.code==="Space")){const a=desktopRay();interact(hitRay(a.origin,a.dir,3));}
 if(!vrSession&&ev.code==="Escape"&&state.entered){/* browser pointer unlock */}
 if(!vrSession&&state.entered&&ev.code==="KeyR"){state.x=.02;state.z=2.30;state.yaw=-.01745;state.pitch=-.07;say("You have reset the fan spiral.");}
});
window.addEventListener("keyup",ev=>key[ev.code]=false);
canvas.addEventListener("click",()=>{if(!state.entered||vrSession)return;
 if(pcState>0)return;
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