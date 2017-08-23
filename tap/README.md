## introduction

A tool for net-debug. Transfer packet from tap-src and tap-dst.
Usually it's used when developing some network Client and Server.

## usage

```
./tap-tap
```

## TODO
- split tun alloc with, `tun_alloc()` and `tun_config()`
- tap to multi-tap. for example:
  ```
  tap_src = tap()
  tap_dst1 = tap()
  tap_dst2 = tap()
  tap_src.recv.connect(tap_dst1)
  tap_src.recv.connect(tap_dst2)

  tap_dst1.recv.connect(tap_src)
  tap_dst2.recv.connect(tap_src)
  ```

