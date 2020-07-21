# Draw-O-Matic

Just wanted a digital whiteboard. PRs welcome.

## Install
Follow install steps for [Elixir/Erlang](https://www.cogini.com/blog/using-asdf-with-elixir-and-phoenix/) and [Scenic](https://hexdocs.pm/scenic/install_dependencies.html#content)

Fork or clone repo. 

`mix deps.get`
`mix scenic.run`

## Features
Currently supports any input device that can be read as a mouse input by holding the left mouse button and moving to draw. 
If using with a graphing tablet, it is recommended you set your control area to be the size of the viewport. This keeps
pen movements in a correct ratio.

- [x] Clear board
- [x] Save file(super + 's')
- [x] Close App(super + 'q')
- [ ] Export image
- [ ] Remote Pairing