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
