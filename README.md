# mdx
mdx can run the shell scripts in your markdown files.

mdx is [mdsh](https://github.com/bashup/mdsh) with some pre-defined functions,headers,and variables which make it easier to write a "runnable" markdown file. So, most of code in this repo is copied from [mdsh](https://github.com/bashup/mdsh) ,and you can check mdsh for more details.

## Installation
1. chmod +x

```shell
chmod +x mdx
```

2. Move it to a directory on your PATH
## Examples
Let's say we have a quickstart.md:

~~~markdown
## Start Layotto
Download Layotto:

```shell
git clone https://github.com/mosn/layotto.git
```

Change directory:

```shell
cd cd layotto/cmd/layotto
```

Build:

```shell @if.not.exist layotto
go build
```

Run Layotto:

```shell @background
./layotto start -c ../../configs/config_in_memory.json
```

## Run Demo

```shell
cd ${project_path}/demo/sequencer/in-memory/
 go build -o client
 ./client
```

And you will see:

```bash
runtime client initializing for: 127.0.0.1:34904
Try to get next id.Key:key666 
Next id:next_id:1 
Next id:next_id:2 
Next id:next_id:3 
Next id:next_id:4 
Next id:next_id:5 
Next id:next_id:6 
Next id:next_id:7 
Next id:next_id:8 
Next id:next_id:9 
Next id:next_id:10 
Demo success!
```
~~~

And then run this file:
```shell
mdx quickstart.md
```

It's equivalent to run the command below:

```bash
set \-e 
git clone https://github.com/mosn/layotto.git
cd cd layotto/cmd/layotto
my_arr=(shell @if.not.exist layotto)
if test ! -e ${my_arr[2]}
then go build
fi 

nohup ./layotto start -c ../../configs/config_in_memory.json & 
sleep 2s 
cd ${project_path}/demo/sequencer/in-memory/
go build -o client
./client
```

## Usage
This tool run the script in 
~~~
```shell

```
~~~
blocks.

### @background
If you want to run a command as a background job, you can add an `@background` to the shell tag.

For example:
~~~markdown
Run Layotto:

```shell @background
./layotto start -c ../../configs/config_in_memory.json
```
~~~

It will be compiled to:
```
nohup ./layotto start -c ../../configs/config_in_memory.json &
sleep 2s
```

### @if.not.exist
In some scenarios, you want to "compile the project if there is no compiled binary file".

Then you can use `@if.not.exist xxx`.  The script is only executed when the file `xxx` does NOT EXIST.

For example:

~~~markdown
Build:

```shell @if.not.exist layotto
go build
```
~~~

### @if.exist
`@if.exist xxx` means the script is only executed when the file `xxx` EXISTS.

### cd ${project_path}
The variable ${project_path} is set to the root path where mdx is run.
If you have switched directories many times and want to go back to the beginning, you can:

~~~markdown
```shell
cd ${project_path}
```
~~~

### @catch
By default, any error will stop the execution.

If you want to tolerant errors when running some script, you can add a `@catch`.

For example, see [catch.md](catch.md):
~~~markdown
Here is a typo. We will catch and ignore the error:

```shell @catch
echoo "xxx"
```

Here is the correct one:

```shell
echo "xxx"
```

Here is another command with typo, but we won't catch the error this time, and it will interrupt the execution.

```shell
echoo "This command will interrupt the execution"
```

Here is another correct command.It won't be executed because the above error have already interrupted the execution.

```shell
echo "This command won't be executed"
```
~~~

Run this file and see what will happen:
```shell
mdx catch.md
```
### Ignore some script
If you don't want to run some script blocks, you can use some other "tag" for it.
For example:
~~~markdown
And you will see:

```bash
runtime client initializing for: 127.0.0.1:34904
Try to get next id.Key:key666 
Next id:next_id:1 
Next id:next_id:2 
Next id:next_id:3 
Next id:next_id:4 
Next id:next_id:5 
Next id:next_id:6 
Next id:next_id:7 
Next id:next_id:8 
Next id:next_id:9 
Next id:next_id:10 
Demo success!
```
~~~

The script in `bash` blocks will not be run.

By default, this tool ONLY run the script in 
~~~
```shell
~~~
blocks.

### Hidden script
You can add some hidden script, which can not be seen by the markdown readers but will be run by this tool.
For example, check the [hidden.md](hidden.md) :

~~~markdown
```shell
echo "Hello!"
```

<!--
```shell
echo "This is a hidden script!"
```
-->

```shell
echo "Bye!"
```
~~~

You can run it and see what happened:

```shell
mdx hidden.md
```