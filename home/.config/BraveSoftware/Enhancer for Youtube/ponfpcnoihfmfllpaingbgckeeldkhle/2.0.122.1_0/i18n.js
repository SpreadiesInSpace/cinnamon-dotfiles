/*
##
##  Enhancer for YouTube™
##  =====================
##
##  Author: Maxime RF <https://www.mrfdev.com>
##
##  This file is protected by copyright laws and international copyright
##  treaties, as well as other intellectual property laws and treaties.
##
##  All rights not expressly granted to you are retained by the author.
##  Read the license.txt file for more details.
##
##  © MRFDEV.com - All Rights Reserved
##
*/
(function(c){function v(){c.body.classList.add("overflow-hidden");g.style.display="block";f.style.display="block";f.scrollTop=0;g.classList.add("in");setTimeout(function(){c.body.classList.add("modal-open")},50)}function w(){c.body.classList.remove("modal-open");setTimeout(function(){f.style.display="none";g.classList.add("fade");g.classList.remove("in");setTimeout(function(){g.style.display="none";c.body.classList.remove("overflow-hidden")},300)},300)}var l,p,x="am bn et fil gu kn ml mr sw ta te".split(" "),
q={ca:["color","contrast","controls","sepia","videos"],cs:["stop"],da:"backup hue_rotation loop loop_start stop support sepia variant".split(" "),de:"autoplay backup export import loop_start playlists screenshot sepia stop videos".split(" "),el:["theme"],es:["color","sepia"],es_419:["color","sepia","videos"],fr:["options","support","volume","stop","message"],hr:["autoplay","mini_player","save","video_player"],id:"autoplay backup gaussian_blur reset screenshot sepia stop volume".split(" "),it:"backup loop mini_player playlists reset screenshot sepia volume".split(" "),
ms:["import","sepia"],nl:"autoplay filters support contrast sepia variant volume".split(" "),no:["loop_start","sepia","variant"],pl:["sepia"],pt_BR:["backup","loop","mini_player","playlists","volume"],pt_PT:["backup","volume"],ro:["backup","gaussian_blur","contrast","sepia"],sk:["message"],sl:["sepia"],sr:["sepia"],sv:["loop","support","sepia","variant"],vi:["videos"]},y=c.querySelectorAll("nav a"),r=c.querySelector("nav .donate a"),h=c.querySelector("#locale"),d=c.querySelectorAll("[contenteditable]"),
m=c.querySelector("#generate-code-btn"),g=c.querySelector("#modal-backdrop"),f=c.querySelector("#modal"),z=f.querySelector(".modal-title"),t=f.querySelector(".close-modal"),u=f.querySelector("#code"),A=f.querySelector("#copy-to-clipboard-btn"),n=f.querySelector("#copy-to-clipboard-checkmark");y.forEach(function(b){b.addEventListener("focus",function(){this.parentNode.classList.add("focus")});b.addEventListener("blur",function(){this.parentNode.classList.remove("focus")})});r.addEventListener("click",
function(b){b.preventDefault();chrome.storage.local.get({localecode:chrome.i18n.getMessage("locale_code")},function(a){a=0>"bg ca cs da de el es et fi fr hr hu it lt lv nl pl pt_PT ro sk sl sv".indexOf(a.localecode)?"USD":"EUR";chrome.tabs.create({url:r.dataset.paypal.replace(/currency_code=[A-Z]+/,"currency_code="+a),active:!0})})});h.addEventListener("change",function(){l=h.options[h.selectedIndex].dataset.dir;p=h.options[h.selectedIndex].textContent;if(""===this.value||0<=x.indexOf(this.value)){for(var b=
d.length-1;0<=b;b--)d[b].textContent="",d[b].dir="ltr";m.disabled=""===this.value?!0:!1}else fetch(`_locales/${this.value}/messages.json`).then(function(a){return a.json()}).then(function(a){for(var e=d.length-1,k;0<=e;e--)k=a[d[e].id].message,"en_US"===a.locale_code.message||"en_GB"===a.locale_code.message?d[e].innerText=k:k!==d[e].previousElementSibling.innerText||q[a.locale_code.message]&&0<=q[a.locale_code.message].indexOf(d[e].id)?d[e].innerText=k:d[e].textContent="",d[e].dir=l;m.disabled=!1})});
c.querySelector("#description").addEventListener("keyup",function(){132<this.textContent.length&&(this.textContent=this.textContent.substr(0,132),this.blur())});m.addEventListener("click",function(){var b={},a=c.querySelector("#locale").value;if(""!==a){b.locale_code={message:a};b.locale_dir={message:l};a=0;for(var e;a<d.length;a++)e=d[a].innerText.trim(),""===e&&(e=d[a].previousElementSibling.innerText),b[d[a].id]={message:e};z.textContent=`${p} Translation - Enhancer for YouTube\u2122`;u.value=
JSON.stringify(b).replace(/^\{/,"{\n    ").replace(/":\{"/gm,'": {"').replace(/":"/gm,'": "').replace(/"\},"/gm,'"},\n    "').replace(/\}$/,"\n}");v()}});t.addEventListener("click",function(){w()});A.addEventListener("click",function(b){u.select();c.execCommand("copy");n.classList.add("show")});n.addEventListener("animationend",function(b){"checkmark-scale"===b.animationName&&setTimeout(function(){n.classList.remove("show")},1200)});c.addEventListener("keydown",function(b){27===b.keyCode&&t.click()})})(document);