Configurations
==============
<br/>
The configurations are a key part on ASYD. You can put any file or folder inside the "configs" directory
on a deploy, and then upload them using the "def" file of the deploy.

Any configuration file will get parsed looking for variables or conditionals, which gives a lot of
flexibility when deploying and configuring systems. Furthermore, the configuration files inside
configuration folders and subfolder will also get recursively parsed and uploaded.

You can globally override this behavior by appending the "noparse" parameter on the def file when
uploading a config file or config dir (see [Deploys](deploys.md) on the documentation).
You can also specify certain blocks of inside the configuration file that should not get
parsed by using the `<%noparse%>` `<%/noparse%>` tags.

Conditionals can also be used inside the configuration files to define parts of the configuration that should
only be included on a host if certain condition complies. This conditional blocks are defined within the
`<%if condition%>` `<%endif%>` tags (replace "condition" by the condition itself).
Conditionals inside the noparse tags are not evaluated either.

**Important:** Please note each of this special tags for "noparse" and conditionals must be written
on a single line without any other character on the same line to work properly, i.e:

    <%noparse%>
    tags to scape
    <%/noparse%>
    rest of the file

*Please also read the [Variables](variables.md) section of the documentation to see the available variables,
and the [Conditionals](conditionals.md) section for more detailed information about the conditionals usage.*
