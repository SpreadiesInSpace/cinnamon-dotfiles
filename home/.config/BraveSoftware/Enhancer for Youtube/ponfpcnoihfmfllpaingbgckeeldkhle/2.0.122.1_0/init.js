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
setTimeout(function(){if(!document.head.querySelector('link[href*="'+chrome.runtime.getURL("resources/youtube-polymer.css")+'"'))try{chrome.runtime.sendMessage({request:"content-scripts"})}catch(a){}},3E3);