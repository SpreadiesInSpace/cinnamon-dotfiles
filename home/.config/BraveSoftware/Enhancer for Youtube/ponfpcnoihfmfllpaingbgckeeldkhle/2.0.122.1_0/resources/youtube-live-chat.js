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
(function(a){if(!window.efyt){window.efyt=!0;var h=new URLSearchParams(a.currentScript.src.split("?")[1]),m=h.get("resources");h=h.get("version");var b=JSON.parse(localStorage.getItem("enhancer-for-youtube"))||{};b.customcolors||(b.customcolors={"--main-color":"#00adee","--main-background":"#111111","--second-background":"#181818","--hover-background":"#232323","--main-text":"#eff0f1","--dimmer-text":"#cccccc","--shadow":"#000000"});b.customcssrules||(b.customcssrules="");b.theme||(b.theme=
"default-dark");b.themevariant||(b.themevariant="youtube-deep-dark.css");if(b.darktheme&&"default-dark"!==b.theme){if("youtube-deep-dark"===b.theme){var c=a.createElement("link");c.id="efyt-theme-variables";c.rel="stylesheet";c.href=m+"/vendor/themes/"+b.themevariant}else if("youtube-deep-dark-custom"===b.theme){c=a.createElement("style");c.type="text/css";c.id="efyt-theme-variables";var n=[],k;for([k,d]of Object.entries(b.customcolors)){if("--shadow"===k){var e=d.replace("#","");var d=parseInt(e.substring(0,
2),16);var p=parseInt(e.substring(2,4),16);e=parseInt(e.substring(4,6),16);d=`0 1px .5px rgba(${d}, ${p}, ${e}, .2)`}n.push(k+":"+d)}c.textContent=":root{"+n.join(";")+"}"}var f=a.createElement("link");f.id="efyt-theme";f.rel="stylesheet";f.href=m+"/vendor/themes/youtube-deep-dark.material.css?v="+h;a.head?(a.head.appendChild(c),a.head.appendChild(f)):a.documentElement.addEventListener("load",function l(q){a.head&&(a.documentElement.removeEventListener("load",l,!0),a.head.appendChild(c),a.head.appendChild(f))},
!0)}if(b.customtheme){var g=a.createElement("style");g.type="text/css";g.id="efyt-custom-theme";g.textContent=b.customcssrules;a.head?a.head.appendChild(g):a.documentElement.addEventListener("load",function l(q){a.head&&(a.documentElement.removeEventListener("load",l,!0),a.head.appendChild(g))},!0)}}})(document);