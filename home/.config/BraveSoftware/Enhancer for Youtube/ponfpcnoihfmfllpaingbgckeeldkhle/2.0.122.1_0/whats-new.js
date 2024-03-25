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
(function(a){chrome.storage.local.get({localecode:chrome.i18n.getMessage("locale_code")},function(c){var b=0>"bg ca cs da de el es et fi fr hr hu it lt lv nl pl pt_PT ro sk sl sv".indexOf(c.localecode)?"USD":"EUR";a.querySelector(".thanks-buttons").classList.add(b);a.querySelectorAll(".thanks-buttons button").forEach(function(d){d.addEventListener("click",function(){chrome.tabs.create({url:`https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=JYKCHGNJ6PFC4&item_name=Enhancer%20for%20YouTube%E2%84%A2%20%5BChrome%20Extension%5D&no_note=1&no_shipping=1&rm=1&return=https%3A%2F%2Fwww.mrfdev.com%2Fthanks&cancel_return=https%3A%2F%2Fwww.mrfdev.com%2Fdonate&amount=${this.dataset.amount}&currency_code=${b}`,
active:!0})})})});chrome.runtime.sendMessage({request:"pause-videos"})})(document);