cupcake is an app framework for making small and delicious games!

well, it will be eventually. at the moment, it's just my personal place to doodle around with game development in zig. don't expect any sort of usability, documentation, or code quality! :)

right now cupcake only supports wasm with webgpu rendering. build examples by calling `zig build -Dexample=tri`, and you can replace `tri` with any of the example names. build with optimizations by adding `-Dopt=release` to your command line.

the goals of cupcake are:
* **web first:** web pages are easily sharable, work on most devices, and are one of the most constrained platforms for applications. porting to other platforms later on should be easier.
* **small binaries:** small binary size is important for the web, since many people have limited bandwidth. the application binary should only include what is needed to run the app.
* **simple code:** the best way to end up with a small binary is to focus on simple code. when necessary complexity arises, try to move it to compile time or build time. 
* **minimal dependencies:** external dependencies are one of the biggest contributors to large binary sizes. replace complex third party libraries with a simpler pieces of handwritten code when possible.  

if you have any questions or comments, contact me on the zig discord. i am happy to chat!

-bootra
