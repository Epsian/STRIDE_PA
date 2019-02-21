// scrape.js

var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'techstars.html'

page.open('https://infoweb.newsbank.com/resources/doc/print?p=AWNB&docrefs=news/16CDD2368B7F8310', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});
