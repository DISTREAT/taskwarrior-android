# Compiling Taskwarrior for Android

This repository contains scripts to cross-compile Taskwarrior 3 for Android.

## Philosophy

With Taskwarrior's major release v3, many efforts to port Taskwarrior
to Android were halted. Additionally, the rewrite of parts into Rust made
it somewhat tricky to compile, especially since the platform is not a
common place for Taskwarrior.

Therefore, the purpose of this repository is to provide a more accessible
means of integrating Taskwarrior into other open-source projects.

## Compilation

To compile Taskwarrior for Android, a Docker installation is assumed:

```bash
git submodule update --init --recursive
./build.sh arm64-v8a
```

This will generate the build files for `./taskwarrior` under `./taskwarrior/build`.
