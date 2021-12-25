cupcake is an app framework for making small and delicious games! (very wip)

At the moment, it's just my personal place to doodle around with game development in zig. Don't expect any sort of usability, documentation, or code quality!

### goals

_web first_
Web pages are easily sharable, work on most devices, and are one of the most constrained platforms for applications. Porting to other platforms later on should be easier.

_small binaries_
Binary size is important for the web because it affects the responsiveness of page loads and bandwidth costs. The application binary should strive to be small and performant.

_simple code_
The best way to end up with a small binary is to focus on simple code. When complexity is necessary, try to move it to compile time or build time.

_minimal dependencies_
External dependencies are one of the biggest contributors to large binary sizes. Replace complex third party libraries with simpler pieces of handwritten code when reasonable.

### build

Right now cupcake only supports building for wasm with webgpu rendering. Build examples by calling `zig build -Dexample=tri`, and you can replace `tri` with any of the example names. Build with optimizations by adding `-Dopt=release` to your command line.

### examples

View the examples on the [website](https://bootradev.github.io).

| example | description |
| --- | --- |
| tri | a simple triangle |
| cube | a spinning cube with vertex color |

### contact
if you have any questions or comments, contact me on the zig discord. i am happy to chat!

-bootra
