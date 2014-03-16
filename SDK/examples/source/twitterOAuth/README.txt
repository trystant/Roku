The twitterOAuth example is an example of doing
OAuth authentication within BrightScript. It is
a twitter channel that displays the tweets for
twitter screen name: RokuPlayer. 

This example also shows using the roImageCanvas to 
display images and text on a blank canvas.

To use the the Oauth singleton in your app, just include 
the oauth.brs, url.brs, and regScreen.brs files in your app.
oauth.brs and url.brs should not need to modified. regScreen.brs 
will be heavily modified to communicate with your OAuth site.

To initialize the Oauth singleton, edit appMain.brs, and
enter the corresponding developer keys from your site:

    m.oa = InitOauth("YouTestAppName", "YourOAuthConsumerKey", "YouOAuthConsumerSecret", "1.0")




