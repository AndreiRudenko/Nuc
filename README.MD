![](/resources/logo/nuc_logo.png)  
Nuc is a lightweight cross-platform, 2d game framework.  
Build on top of [Kha](https://github.com/Kode/Kha) framework using [Haxe](https://haxe.org/) language.  

## Installation
```bash
git clone --recursive https://github.com/nuclibs/nuc.git
haxelib dev nuc path/to/nuc
```

#### Commands
- haxelib run nuc init [ -t template ]: *initialize a new project*.
- haxelib run nuc build < target > [ --debug ]:  *build the current project*.
- haxelib run nuc run < target > [ --debug ]:  *build and run the current project*.
- haxelib run nuc server : *launch server for html5 build*.
- haxelib run nuc launch: *launch build*.
- haxelib run nuc collect [--clear, --verbose]: *copy all libraries to project folder*.
- haxelib run nuc clear < target >:  *remove project build files*.
