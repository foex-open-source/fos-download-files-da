## FOS - Download File(s)

![](https://img.shields.io/badge/Plug--in_Type-Dynamic_Action-orange.svg) ![](https://img.shields.io/badge/APEX-19.2-success.svg) ![](https://img.shields.io/badge/APEX-20.1-success.svg) ![](https://img.shields.io/badge/APEX-20.2-success.svg) ![](https://img.shields.io/badge/APEX-21.1-success.svg) ![](https://img.shields.io/badge/APEX-21.2-success.svg) ![](https://img.shields.io/badge/APEX-22.1-success.svg)

Download of database-stored BLOBs and CLOBs with a dynamic action. Multiple files are zipped automatically.
<h4>Free Plug-in under MIT License</h4>
<p>
All FOS plug-ins are released under MIT License, which essentially means it is free for everyone to use, no matter if commercial or private use.
</p>
<h4>Overview</h4>
<p>The <strong>FOS - Download File(s)</strong> dynamic action plug-in enables the downloading of one or multiple database-stored BLOBs or CLOBs. You don't have to worry about setting HTTP headers, converting CLOBs to BLOBs, or zipping the files. It's all done for you. Just specify which files to download via a SQL query, or a more dynamic PL/SQL code block. Multiple files are zipped automatically, but a single file can optionally be zipped as well.</p>
<p>The benefits of downloading a file using a dynamic action include:
<ol>
    <li>You have the flexibility of using SQL to decide what file(s) to download including filtering based on page item values</li>
    <li>You can have further actions defined after the download action for improved workflow</li>
    <li>You can wait for the result of the file to download before continuing your next action</li>
    <li>You do NOT issue a page submit or redirect, which means you can handle errors better i.e. you won't be redirected to an error page</li>
</ol>
</p>
<p><strong>Note:</strong> in "some cases" you may need to change your security setting "Embed in Frames" and set it to either "Allow from same origin" or "Allow" for this action to work correctly in preview mode. This is because the file will be downloaded in a hidden iFrame on the page. If your setting is set to "Deny" you may see a message in the console like: "Load denied by X-Frame-Options". We evaluated a number of techniques to download files and found that this technique has the best performance with larger files.</p>
</p>

## License

MIT

