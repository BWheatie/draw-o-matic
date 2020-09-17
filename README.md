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

- [x] New icons
- [x] Change pen color
- [x] Clear board
- [x] Save file(super + 's')
- [x] Custom file name during save
- [x] Close App(super + 'q')
- [ ] Pen stroke size
- [ ] Undo
- [ ] Redo
- [ ] Shapes
- [ ] Resizable shapes
- [ ] Text box
- [ ] Resizable text box
- [ ] Animate color picker menu
- [ ] Export image
- [ ] Remote Pairing
- [x] Erasing(eh, sort of. Having an issue with draw order after erasing lines.)

## Known Issues

- Erasing as noted above. Just don't make mistakes.
- As the app will save a file, if you get into an odd state, delete "$FILENAME.bin" from the root of the app directory.

## Contributing

Not really taking code contributions at the moment as I am still figuring out the structre and desired features. That said, if you have feedback or something doesn't work aside from what is noted above, let me know in the issues.
