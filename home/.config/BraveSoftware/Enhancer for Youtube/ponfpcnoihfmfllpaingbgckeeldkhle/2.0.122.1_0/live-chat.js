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
(function(){function h(){var a=[],c;for([c,f]of Object.entries(d.customcolors)){if("--shadow"===c){var b=f.replace("#","");var f=parseInt(b.substring(0,2),16);var l=parseInt(b.substring(2,4),16);b=parseInt(b.substring(4,6),16);f=`0 1px .5px rgba(${f}, ${l}, ${b}, .2)`}a.push(c+":"+f)}return":root{"+a.join(";")+"}"}var k=document.createElement("script");k.src=chrome.runtime.getURL("resources/youtube-live-chat.js?")+new URLSearchParams({resources:chrome.runtime.getURL("resources"),version:chrome.runtime.getManifest().version});
document.documentElement.appendChild(k);k.remove();var e=chrome.runtime.getURL("resources"),g=chrome.runtime.getManifest().version,d={customcolors:{"--main-color":"#00adee","--main-background":"#111111","--second-background":"#181818","--hover-background":"#232323","--main-text":"#eff0f1","--dimmer-text":"#cccccc","--shadow":"#000000"},customcssrules:"",customtheme:!1,darktheme:!1,theme:"default-dark",themevariant:"youtube-deep-dark.css"};chrome.storage.local.get(d,function(a){d=a});chrome.runtime.onMessage.addListener(function(a,
c,b){if("preference-changed"===a.message)switch(c=a.value,a.name){case "customcolors":d.customcolors=c;if(a=document.head.querySelector("#efyt-theme-variables"))a.textContent=h();break;case "customcssrules":d.customcssrules=c;if(a=document.head.querySelector("#efyt-custom-theme"))a.textContent=c,document.head.appendChild(a);break;case "customtheme":d.customtheme=c;a=document.head.querySelector("#efyt-custom-theme");c&&!a?(a=document.createElement("style"),a.type="text/css",a.id="efyt-custom-theme",
a.textContent=d.customcssrules,document.head.appendChild(a)):!c&&a&&document.head.removeChild(a);break;case "darktheme":d.darktheme=c;a=document.head.querySelector("#efyt-theme-variables");b=document.head.querySelector("#efyt-theme");c?"default-dark"===d.theme?(b&&document.head.removeChild(b),a&&document.head.removeChild(a)):"youtube-deep-dark"===d.theme?(a&&!a.hasAttribute("href")&&(document.head.removeChild(a),a=!1),a||(a=document.createElement("link"),a.id="efyt-theme-variables",a.rel="stylesheet",
a.href=e+"/vendor/themes/"+d.themevariant,document.head.appendChild(a)),b||(b=document.createElement("link"),b.id="efyt-theme",b.rel="stylesheet",b.href=e+"/vendor/themes/youtube-deep-dark.material.css?v="+g,document.head.appendChild(b)),d.customtheme&&(a=document.head.querySelector("#efyt-custom-theme"))&&document.head.appendChild(a)):"youtube-deep-dark-custom"===d.theme&&(a&&a.hasAttribute("href")&&(document.head.removeChild(a),a=!1),a||(a=document.createElement("style"),a.type="text/css",a.id=
"efyt-theme-variables",a.textContent=h(),document.head.appendChild(a)),b||(b=document.createElement("link"),b.id="efyt-theme",b.rel="stylesheet",b.href=e+"/vendor/themes/youtube-deep-dark.material.css?v="+g,document.head.appendChild(b)),d.customtheme&&(a=document.head.querySelector("#efyt-custom-theme"))&&document.head.appendChild(a)):(b&&document.head.removeChild(b),a&&document.head.removeChild(a));break;case "theme":d.theme=c;a=document.head.querySelector("#efyt-theme-variables");b=document.head.querySelector("#efyt-theme");
"default-dark"===c?(b&&document.head.removeChild(b),a&&document.head.removeChild(a)):"youtube-deep-dark"===c?(a&&!a.hasAttribute("href")&&(document.head.removeChild(a),a=!1),a||(a=document.createElement("link"),a.id="efyt-theme-variables",a.rel="stylesheet",a.href=e+"/vendor/themes/"+d.themevariant,document.head.appendChild(a)),b||(b=document.createElement("link"),b.id="efyt-theme",b.rel="stylesheet",b.href=e+"/vendor/themes/youtube-deep-dark.material.css?v="+g,document.head.appendChild(b)),d.customtheme&&
(a=document.head.querySelector("#efyt-custom-theme"))&&document.head.appendChild(a)):"youtube-deep-dark-custom"===c&&(a&&a.hasAttribute("href")&&(document.head.removeChild(a),a=!1),a||(a=document.createElement("style"),a.type="text/css",a.id="efyt-theme-variables",a.textContent=h(),document.head.appendChild(a)),b||(b=document.createElement("link"),b.id="efyt-theme",b.rel="stylesheet",b.href=e+"/vendor/themes/youtube-deep-dark.material.css?v="+g,document.head.appendChild(b)),d.customtheme&&(a=document.head.querySelector("#efyt-custom-theme"))&&
document.head.appendChild(a));break;case "themevariant":d.themevariant=c,(a=document.head.querySelector("#efyt-theme-variables"))&&a.hasAttribute("href")&&(a.href=e+"/vendor/themes/"+c)}})})();