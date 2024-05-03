# Create a release

  1. Update Changelog in `README.md`
  2. Update version number in script header
  3. Convert `README.md` to help file: `make doc`
  4. Commit current version: `git commit -m 'prepare release vX.Y.Z'`
  5. Tag version: `git tag vX.Y.Z -m 'tag release vX.Y.Z' -s`
  6. Push release to [GitHub]:
    - `git push git@github.com:embear/vim-foldsearch.git`
    - `git push --tags git@github.com:embear/vim-foldsearch.git`
  7. Create a Vimball archive: `make package`
  8. Create a release on [VIM online] and [GitHub]

[GitHub]: https://github.com/embear/vim-foldsearch
[VIM online]: http://www.vim.org/scripts/script.php?script_id=2302
