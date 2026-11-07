// Meta Quest IWER runtime (Meta Platforms). QA-only; NOT shipped to production pages.
// Exact technique follows meta-quest/webxr-first-steps/src/init.js.
import { XRDevice, metaQuest3 } from 'iwer';
const device = new XRDevice(metaQuest3, {ipd:0.064,stereoEnabled:true});
device.installRuntime({forceInstall:true});
window.__questIWER=device;
window.__ethosMetaEmulator={source:"meta-quest/immersive-web-emulation-runtime",profile:"metaQuest3",version:device.version};
