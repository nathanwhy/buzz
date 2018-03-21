# buzz

Command-line program to download files

- [x] resume a download
- [x] cookie support
- [x] customize header
- [ ] Proxy


## Install

You need Swift Package Manager installed in your macOS, generally you are prepared if you have the latest Xcode installed.

### Compile from source

```bash
> git clone https://github.com/nathanwhy/buzz.git
> cd buzz
> ./install.sh
```

Buzz should be compiled, tested and installed into the `/usr/local/bin`.

### Homebrew

You may want to install in from Homebrew. But for now it is not supported.

## Get Started

### Download a image

```
buzz https://img9.bcyimg.com/drawer/15294/post/1799t/1f5a87801a0711e898b12b640777720f.jpg 
``` 

### Resume a download

Running buzz with the same arguments, the download progress will resume from the last session.

### Cookies

```
buzz --header "Cookie: value; otherName: value2" http://adcdownload.apple.com/Developer_Tools/Xcode_8.1_beta_2/Xcode_8.1_beta_2.xip
```


## License

MIT
