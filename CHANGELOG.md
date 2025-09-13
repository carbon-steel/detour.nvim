# Changelog

## v2.0.0

### Added

* Features: Hide/reveal detours and uncover hidden base windows
* Implement `CloseCurrentStack`
* A default title to all detours based on buffer name
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/6f7a718e1ea0d24daff16407b27e460e043ebf6f)
* This changelog
* Added help pages

### Fixed

* Keep cursor out of covered windows
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/0c358da951addace23934db10df59cc609e81db4)
* Check window exists before updating its title
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/6cd2b457e4a5502cdaaf510a3da66d2686d42cc9)
* Fix global statusline detection
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/f452858a3bac44bdabb9f507ba219e3e0af4bc6c)
* Attempt to fix terminal rendering issue
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/b5596b9baa61475fe5164142c7d8ca86d0cf3b37)
* Miscellaneous small fixes
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/eaab89288dd14de8d7cd06a948589b8f439c12ad)
* Make updating title more responsive
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/255fd9555d389d21a3bf790de47a2350b5607bf5)
* Guard title update autocmd
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/0e206f5aacf9f65b2d92cc9098519a7ea3595536)
* Realigned terminal buffers after resize events
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/a7935ce1283a141bcca09d6bdf07c9c1b537bbfb)
* Redid help detour example
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/bf59c29a06b58cd0e9f53b04aad7646204af4479)
* Introduced nesting autocmds
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/42a724730e2351057973e1231016b8918e161e4f)

### Changed

* Increase required Neovim version to `0.11`
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/def7b8c2e7b930c1d9f807f4362e61fb8796f11e)
* Removed behavior that closes detour if its parents are closed.
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/48d6e7031007f4ebda460b99beeecc50ef932bcc)
* Keep window sizing behavior consistent until very small sizes
    - [Commit](https://github.com/carbon-steel/detour.nvim/commit/39b19018711073edb0dd69a790e2ffdb4ebeb50c)
