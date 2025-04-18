---
tags:
- programming
- technology
- cloud
- node.js
- javascript
- infrastructure
---
<!-- preview -->
Here's a quick look at how I'm running MAN-Blog in production:

![](../resources/20150310/MAN%20Blog%20in%20production.png)
<!-- /preview -->

### Nginx
Nginx works really well serving static files and acting as a proxy for other services (a node.js app in this case). For MAN Blog I use Nginx to serve all of the static assets and proxy certain requests to the MAN Blog node.js app.

### Node
For running MAN Blog in production, I'm using [forever](https://github.com/foreverjs/forever). Forever will restart the server if it crashes for any reason. It can also watch my app files for changes and restart the server if necessary. I am not using this feature however. To have my node app start on boot I added an entry to the crontab (the server was already setup with crond):

```
@reboot forever start /path/to/my/app.js
```

### Dropbox

When I started to build MAN Blog, one of my goals was simplicity of infrastructure. I mainly wanted to avoid having to setup a database of any kind. I decided to store posts as markdown files (although a bit customized). The question then was how to add new files to the server. At first I thought about using a git repository. But then I would have to either manually pull changes, or figure out a way have the changes automatically pull. Even using a git repo, I was still missing the ability to easily edit my files anywhere and everywhere. Sure, git would work for that but it just seemed a bit cumbersome. Then it occurred to me, why not use Dropbox? I already have the client running on my laptop, I can easily edit files on Dropbox from an iPhone or iPad. I setup the Dropbox linux client and also excluded everything but my 'posts' directory.

