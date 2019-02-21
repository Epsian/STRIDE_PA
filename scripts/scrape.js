var url ='https://infoweb.newsbank.com/resources/doc/print?p=AWNB&docrefs=news/0EB5CDC4B5FAAFDD';
var page = new WebPage();
var fs = require('fs');

page.open(url, function (status) {
        just_wait();
});

function just_wait() {
    setTimeout(function() {
               fs.write('scrape_out/raw/23532.html', page.content, 'w');
            phantom.exit();
    }, 2500);
}

