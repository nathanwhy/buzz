# buzz

[![Build Status](https://travis-ci.org/nathanwhy/buzz.svg?branch=master)](https://travis-ci.org/nathanwhy/buzz)
[![codecov](https://codecov.io/gh/nathanwhy/buzz/branch/master/graph/badge.svg)](https://codecov.io/gh/nathanwhy/buzz)
![](https://img.shields.io/badge/language-Swift_5-orange.svg)

Command-line program to download files

- [x] Resume a download
- [x] Cookie support
- [x] Customize header
- [ ] Recursive download
- [ ] Output file
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
buzz --header "Cookie: value; otherName: value2" http://something.zip
```

For example,
```
buzz --header "Cookie: ADCDownloadAuth=xxxxxx" http://adcdownload.apple.com/Developer_Tools/Xcode_8.1_beta_2/Xcode_8.1_beta_2.xip
```


## License

MIT
