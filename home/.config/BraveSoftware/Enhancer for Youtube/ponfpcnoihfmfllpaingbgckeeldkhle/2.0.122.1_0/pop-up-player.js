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
(function(){document.title="Enhancer for YouTube\u2122";var c=document.location.href.split("/pop-up-player/")[1],e=/efyt_playlist/.test(c),a=document.createElement("iframe");a.setAttribute("id","pop-up-player");a.setAttribute("allow","accelerometer;autoplay;encrypted-media;gyroscope;picture-in-picture");a.setAttribute("allowfullscreen","");a.setAttribute("src","https://www.youtube.com/embed/"+c);a.addEventListener("DOMContentLoaded",function(){document.title=a.contentDocument.title});
a.addEventListener("load",function(){a.contentDocument.addEventListener("efyt-get-playlist",function(){chrome.storage.local.get({playlist:{videos:[],index:0,start:0}},function(d){a.contentDocument.defaultView.document.dispatchEvent(new a.contentDocument.defaultView.CustomEvent("efyt-load-playlist",{detail:JSON.stringify({playlist:d.playlist})}));chrome.storage.local.remove("playlist")})});a.contentDocument.addEventListener("efyt-always-on-top",function(){try{chrome.runtime.sendMessage({request:"always-on-top"})}catch(d){}});
var b=a.contentDocument.createElement("script");b.src=chrome.runtime.getURL("resources/youtube-pop-up-player.js?")+new URLSearchParams({platform:window.navigator.platform,efyt_playlist:e});a.contentDocument.head.appendChild(b);b.remove()},{once:!0});document.body.appendChild(a)})();